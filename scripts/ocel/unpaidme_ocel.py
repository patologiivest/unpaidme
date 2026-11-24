# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "polars>=1.30",
#     "pyarrow>=17",
#     "connectorx>=0.4",
#     "adbc-driver-postgresql",
#     "python-dotenv",
# ]
# ///
"""Export the UNPAIDME event log (trans.events + trans/hist objects) as an OCEL 2.0 log.

Output formats, chosen by the extension of each -o/--output (several may be given):
  *.ocel.zip                      OCEL 2.1 bundled Parquet (recommended: compact, typed, columnar)
  *.json, *.jsonocel (+ .gz)      OCEL 2.0 JSON, validates against ocel2.schema.json

Mapping (see context.md):
  event type      = config.event_names.name; lifecycle/revision/lab_location as event attributes
  object types    = case, container, block, slide, analysis (trans.*), actor, workstation (master.*)
  E2O             = case ('case'), the token if not the case ('block', 'slide', ...),
                    'actor' (actor_ref), 'workstation' (workstation_ref)
  O2O             = container/block/analysis -'part of'-> case, slide -'cut from'-> block,
                    slide -'part of'-> case, case -'responsible actor'-> actor
  object changes  = hist.* versions (SCD-2) become timed attribute values
Patients are never exported.

Connection via PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE (also read from a .env file) or --dsn.

    uv run unpaidme_ocel.py -o histo_jan.ocel.zip --from 2024-01-01 --to 2024-02-01 --division HISTOLOGY
    uv run unpaidme_ocel.py -o sample.json.gz --sample 500 --seed 1 --names all --hash-ids
    uv run unpaidme_ocel.py --dry-run --from 2024-01-01 --to 2025-01-01
    uv run unpaidme_ocel.py -o year.ocel.zip --from 2024-01-01 --to 2025-01-01 --batch-size   # low memory
"""

from __future__ import annotations

import argparse
import datetime as dt
import gzip
import hashlib
import hmac
import json
import os
import sys
import tempfile
import time
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import quote

import polars as pl
import pyarrow as pa
import pyarrow.parquet as pq

# --- vocabulary -------------------------------------------------------------------------------

# config.event_types id -> XES lifecycle:transition (standard extension vocabulary)
LIFECYCLE = {0: "complete", 1: "start", 2: "complete", 3: "suspend", 4: "resume", 5: "ate_abort", 6: "unknown"}
# config.token_types id -> OCEL object type (REPORT=5 / OTHER=6 have no trans table: case link only)
TOKEN_KIND = {0: "case", 1: "container", 2: "block", 3: "slide", 4: "analysis"}
EPOCH = dt.datetime(1970, 1, 1, tzinfo=dt.UTC)
TIME_FMT = "%Y-%m-%dT%H:%M:%S%.3fZ"

# Attribute sources per object type: (attribute, how, lookup)
#   int: plain number    config: config.<lookup> name    master: master name or id (--names)
#   actor: master.actors name or id (--names)    ident: textual LIS identifier (only clear exports)
OBJECTS = {
    "case": ("trans.cases", "hist.cases", ["patho_division", "priority", "requisition_type", "specimen_type",
             "requisitioner", "responsible_actor", "specimen_containers", "lab_id", "requisition_id", "legacy_id"]),
    "container": ("trans.specimen_containers", "hist.specimen_containers",
                  ["case_id", "container_no", "specimen_type", "fixation_method", "legacy_id"]),
    "block": ("trans.blocks", "hist.blocks", ["case_id", "block_no", "block_type", "legacy_id"]),
    "slide": ("trans.slides", "hist.slides", ["case_id", "block_id", "slide_no", "slide_type", "stain_type", "legacy_id"]),
    "analysis": ("trans.analyses", "hist.analyses", ["case_id", "analysis_type", "legacy_id"]),
}
ATTR_SOURCES = {
    "patho_division": ("config", "patho_divisions"),
    "priority": ("config", "case_priority"),
    "requisition_type": ("config", "requisition_types"),
    "block_type": ("config", "block_types"),
    "slide_type": ("config", "slide_types"),
    "specimen_type": ("master", "specimen_types"),
    "requisitioner": ("master", "requisitioners"),
    "fixation_method": ("master", "fixation_methods"),
    "stain_type": ("master", "staining_methods"),
    "analysis_type": ("master", "analysis_methods"),
    "responsible_actor": ("actor", "actors"),
    "specimen_containers": ("int", None),
    "container_no": ("int", None),
    "block_no": ("int", None),
    "slide_no": ("int", None),
    "lab_id": ("ident", None),
    "requisition_id": ("ident", None),
    "legacy_id": ("ident", None),
}
HASH_KIND = {"actors": "actor", "workstations": "workstation"}  # master table -> object type
PARENT_COLS = {"case_id", "block_id"}  # fetched for O2O, not exported as attributes

MASTER_NAME_SQL = {
    "actors": "SELECT id, name FROM master.actors",
    "workstations": "SELECT id, name FROM master.workstations",
    "requisitioners": "SELECT id, name FROM master.requisitioners",
    "specimen_types": """
        SELECT st.id, coalesce(l.code_display_text, l.code) || ': ' || coalesce(p.code_display_text, p.code) AS name
        FROM master.specimen_types st
        LEFT JOIN master.code_values l ON l.id = st.loc_code
        LEFT JOIN master.code_values p ON p.id = st.proc_code""",
    **{t: f"""SELECT m.id, coalesce(cv.code_display_text, cv.code) AS name
              FROM master.{t} m LEFT JOIN master.code_values cv ON cv.id = m.coding"""
       for t in ("staining_methods", "fixation_methods", "analysis_methods")},
}
CONFIG_TABLES = ["event_names", "patho_divisions", "case_priority", "requisition_types", "block_types",
                 "slide_types", "workflow_profiles", "lab_locations", "workstation_types"]


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


# --- database ---------------------------------------------------------------------------------

class Db:
    def __init__(self, uri: str, engine: str):
        self.uri, self.engine = uri, engine

    def query(self, sql: str) -> pl.DataFrame:
        return self.normalize(pl.read_database_uri(sql, self.uri, engine=self.engine))

    def stream(self, sql: str, batch_size: int):
        """Yields the result in DataFrames of ~batch_size rows. ADBC streams the result (Postgres
        COPY) as Arrow record batches; connectorx would materialise all of it."""
        import adbc_driver_postgresql.dbapi as adbc

        with adbc.connect(self.uri) as conn, conn.cursor() as cur:
            cur.execute(sql)
            buf, n = [], 0
            for rb in cur.fetch_record_batch():  # driver batches: ~16 MB each
                buf.append(rb)
                n += rb.num_rows
                while n >= batch_size:
                    t = pa.Table.from_batches(buf)
                    yield self.normalize(pl.from_arrow(t.slice(0, batch_size)))
                    rest = t.slice(batch_size)
                    buf, n = rest.to_batches(), rest.num_rows
            if buf:
                yield self.normalize(pl.from_arrow(pa.Table.from_batches(buf)))

    @staticmethod
    def normalize(df: pl.DataFrame) -> pl.DataFrame:
        # all timestamps as UTC microseconds (connectorx: ns/UTC, adbc: us/tz-aware)
        return df.with_columns(
            (pl.col(c).dt.replace_time_zone("UTC") if df.schema[c].time_zone is None
             else pl.col(c).dt.convert_time_zone("UTC")).dt.cast_time_unit("us")
            for c in df.columns if isinstance(df.schema[c], pl.Datetime)
        )

    def lookup(self, sql: str) -> dict[int, str]:
        df = self.query(sql)
        return dict(zip(df["id"].to_list(), df["name"].to_list()))


def pg_uri(dsn: str | None) -> str:
    if dsn:
        return dsn
    env = os.environ
    user = quote(env.get("PGUSER", "postgres"), safe="")
    pw = env.get("PGPASSWORD")
    auth = f"{user}:{quote(pw, safe='')}" if pw else user
    return f"postgresql://{auth}@{env.get('PGHOST', 'localhost')}:{env.get('PGPORT', '5432')}/{env.get('PGDATABASE', 'postgres')}"


def sql_ts(t: dt.datetime) -> str:
    return f"'{t.isoformat()}'::timestamptz"


def sql_ints(values) -> str:
    return ", ".join(str(int(v)) for v in values)


def sql_str(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


# --- selection --------------------------------------------------------------------------------

@dataclass
class Selection:
    start: dt.datetime | None = None
    end: dt.datetime | None = None
    window: str = "case"
    divisions: list[int] = field(default_factory=list)
    priorities: list[int] = field(default_factory=list)
    profiles: list[int] = field(default_factory=list)
    specimen_types: list[int] = field(default_factory=list)
    case_ids: list[int] = field(default_factory=list)
    event_names: list[int] = field(default_factory=list)
    exclude_event_names: list[int] = field(default_factory=list)
    labs: list[int] = field(default_factory=list)
    max_revision: int | None = None
    sample: int | None = None
    seed: int = 0

    def time_cond(self, alias: str) -> list[str]:
        c = []
        if self.start:
            c.append(f"{alias}.happened_at >= {sql_ts(self.start)}")
        if self.end:
            c.append(f"{alias}.happened_at < {sql_ts(self.end)}")
        return c

    def case_cte(self) -> str | None:
        """SQL yielding the selected case_ids, or None when all cases are selected."""
        sets = []
        if self.case_ids:
            sets.append(f"SELECT unnest(ARRAY[{sql_ints(self.case_ids)}]::int8[]) AS case_id")
        conds = []
        if self.divisions:
            conds.append(f"c.patho_division IN ({sql_ints(self.divisions)})")
        if self.priorities:
            conds.append(f"c.priority IN ({sql_ints(self.priorities)})")
        if self.specimen_types:
            conds.append(f"c.specimen_type IN ({sql_ints(self.specimen_types)})")
        if self.profiles:
            conds.append(f"EXISTS (SELECT 1 FROM trans.case_profiles p WHERE p.case_id = c.id "
                         f"AND p.case_profile IN ({sql_ints(self.profiles)}))")
        if conds:
            sets.append("SELECT c.id AS case_id FROM trans.cases c WHERE " + " AND ".join(conds))
        if self.start or self.end:
            where = " AND ".join(self.time_cond("e"))
            if self.window == "case" and self.start:
                # cases whose FIRST event lies in the window; all their events are exported
                sets.append(f"SELECT e.case_id FROM trans.events e WHERE {where} GROUP BY e.case_id "
                            f"HAVING NOT EXISTS (SELECT 1 FROM trans.events p WHERE p.case_id = e.case_id "
                            f"AND p.happened_at < {sql_ts(self.start)})")
            else:
                sets.append(f"SELECT DISTINCT e.case_id FROM trans.events e WHERE {where}")
        if self.sample:
            base = " INTERSECT ".join(f"({s})" for s in sets) if sets else "SELECT DISTINCT case_id FROM trans.events"
            # deterministic pseudo-random sample: identical for identical --seed, across queries
            return (f"SELECT case_id FROM ({base}) s ORDER BY md5(case_id::text || ':{int(self.seed)}') "
                    f"LIMIT {int(self.sample)}")
        return " INTERSECT ".join(f"({s})" for s in sets) if sets else None

    def event_conds(self) -> list[str]:
        c = self.time_cond("e") if self.window == "event" else []
        if self.event_names:
            c.append(f"e.event_name IN ({sql_ints(self.event_names)})")
        if self.exclude_event_names:
            c.append(f"e.event_name NOT IN ({sql_ints(self.exclude_event_names)})")
        if self.labs:
            c.append(f"e.lab_ref IN ({sql_ints(self.labs)})")
        if self.max_revision is not None:
            c.append(f"e.revision <= {int(self.max_revision)}")
        return c


def with_cases(cte: str | None, sql: str, col: str = "case_id") -> str:
    """Prefix `sql` (which must alias its table `t`) with the case selection."""
    if cte is None:
        return sql
    return f"WITH sel AS ({cte}) {sql} {'AND' if ' WHERE ' in sql else 'WHERE'} t.{col} IN (SELECT case_id FROM sel)"


# --- identifiers and names --------------------------------------------------------------------

class Ids:
    """Exported identifiers. Database ids appear as-is, or keyed-hashed with --hash-ids so the
    export carries no UNPAIDME ids (a plain hash of small integers is trivially reversible)."""

    def __init__(self, salt: str | None):
        self.key = salt.encode() if salt else None

    def _h(self, kind: str, v) -> str:
        assert self.key is not None
        return hmac.new(self.key, f"{kind}:{v}".encode(), hashlib.sha256).hexdigest()[:16]

    def ref(self, kind: str, s: pl.Series) -> pl.Series:
        """A database id used as a value: Int64, or hashed string."""
        if self.key is None:
            return s.cast(pl.Int64)
        uniq = s.drop_nulls().unique().to_list()
        return s.replace_strict(uniq, [self._h(kind, v) for v in uniq], default=None, return_dtype=pl.String)

    def obj(self, kind: str, s: pl.Series) -> pl.Series:
        """An OCEL object id: '<type>:<id>' (unique across object types, as OCEL requires)."""
        return (f"{kind}:" + self.ref(kind, s).cast(pl.String)).alias(s.name)


@dataclass
class Names:
    mode: str                                  # none | actor | all
    ids: Ids
    config: dict[str, dict[int, str]]
    master: dict[str, dict[int, str]]
    hashed: bool

    def clear(self, how: str) -> bool:
        return how == "config" or (how == "master" and self.mode in ("none", "actor")) or \
            (how == "actor" and self.mode == "none")

    def resolve(self, s: pl.Series, how: str, table: str | None) -> pl.Series | None:
        """Exported value of a raw column; None if the column must not be exported."""
        if how == "int":
            return s.cast(pl.Int64)
        if how == "ident":  # LIS identifiers re-identify cases: only in fully clear exports
            return s.cast(pl.String) if self.mode == "none" and not self.hashed else None
        if self.clear(how):
            names = self.config[table] if how == "config" else self.master[table]
            return s.replace_strict(names, default=s.cast(pl.String), return_dtype=pl.String)
        # same hash namespace as the object ids, so e.g. responsible_actor joins to actor objects
        return self.ids.ref(HASH_KIND.get(table, table), s)


# --- extraction -------------------------------------------------------------------------------

def existing_tables(db: Db) -> set[str]:
    df = db.query("SELECT table_schema || '.' || table_name AS t FROM information_schema.tables "
                  "WHERE table_schema IN ('trans', 'hist')")
    return set(df["t"].to_list())


@dataclass
class ObjectType:
    name: str
    initial: pl.DataFrame          # ocel_id + attributes (values valid from 1970-01-01)
    changes: pl.DataFrame          # ocel_id, ocel_time, ocel_changed_field + attributes (one set per row)
    attrs: list[str]


def versioned(name: str, cur: pl.DataFrame, hist: pl.DataFrame | None, attrs: list[str],
              names: Names) -> tuple[ObjectType, pl.DataFrame]:
    """Stack hist versions and the current trans row per id, resolve values, and diff consecutive
    versions into object changes. Returns the object type and the latest raw row per id (for O2O)."""
    cols = ["id", *attrs]
    if hist is not None and hist.height:
        t_cur = hist.group_by("id").agg(pl.max_horizontal("valid_from", "valid_until").max().alias("_t"))
        stack = pl.concat([
            hist.select(*cols, pl.col("valid_from").alias("_t")),
            cur.select(cols).join(t_cur, on="id", how="left"),
        ], how="vertical_relaxed").sort("id", "_t", nulls_last=False)
    else:
        stack = cur.select(cols).with_columns(pl.lit(None, pl.Datetime("us", "UTC")).alias("_t"))
    latest_raw = stack.unique("id", keep="last", maintain_order=True)

    out = {"ocel_id": names.ids.obj(name, stack["id"]), "_t": stack["_t"]}
    exported = []
    for a in attrs:
        if a in PARENT_COLS:
            continue
        how, table = ATTR_SOURCES[a]
        v = names.resolve(stack[a], how, table)
        if v is not None:
            out[a] = v.alias(a)
            exported.append(a)
    st = pl.DataFrame(out)

    first = pl.int_range(pl.len()).over("ocel_id") == 0
    initial = st.filter(first).drop("_t")
    changes = [
        st.filter(~first & pl.col(a).is_not_null() & pl.col(a).ne_missing(pl.col(a).shift().over("ocel_id")))
          .select("ocel_id", pl.col("_t").alias("ocel_time"), pl.lit(a).alias("ocel_changed_field"), a)
        for a in exported
    ]
    ch = pl.concat(changes, how="diagonal_relaxed") if changes else pl.DataFrame()
    ch = align_changes(ch, initial, exported)
    return ObjectType(name, initial, ch, exported), latest_raw


def align_changes(ch: pl.DataFrame, initial: pl.DataFrame, attrs: list[str]) -> pl.DataFrame:
    base = {"ocel_id": pl.String, "ocel_time": pl.Datetime("us", "UTC"), "ocel_changed_field": pl.String}
    schema = {**base, **{a: initial.schema[a] for a in attrs}}
    if ch.is_empty():
        return pl.DataFrame(schema=schema)
    return ch.select(pl.col(c).cast(t) if c in ch.columns else pl.lit(None, t).alias(c) for c, t in schema.items())


def load_objects(db: Db, cte: str | None, names: Names, history: bool, tables: set[str]):
    types, latest = {}, {}
    for name, (trans_t, hist_t, attrs) in OBJECTS.items():
        key = "id" if name == "case" else "case_id"
        cols = ", ".join(["t.id", *(f"t.{a}" for a in attrs)])
        cur = db.query(with_cases(cte, f"SELECT {cols} FROM {trans_t} t", key))
        hist = None
        if history and hist_t in tables:
            hist = db.query(with_cases(cte, f"SELECT {cols}, t.valid_from, t.valid_until FROM {hist_t} t", key))
        ot, raw = versioned(name, cur, hist, attrs, names)
        types[name], latest[name] = ot, raw
    # case workflow profiles (multi-valued, current only) as one ';'-joined attribute
    prof = db.query(with_cases(cte, "SELECT t.case_id AS id, t.case_profile FROM trans.case_profiles t"))
    if prof.height:
        prof = prof.with_columns(pl.col("case_profile").replace_strict(
            names.config["workflow_profiles"], default=pl.col("case_profile").cast(pl.String), return_dtype=pl.String))
        prof = prof.sort("id", "case_profile").group_by("id", maintain_order=True).agg(
            pl.col("case_profile").str.join(";").alias("workflow_profiles"))
        prof = prof.with_columns(names.ids.obj("case", prof["id"]).alias("ocel_id")).drop("id")
        c = types["case"]
        c.initial = c.initial.join(prof, on="ocel_id", how="left")
        c.attrs.append("workflow_profiles")
        c.changes = c.changes.with_columns(pl.lit(None, pl.String).alias("workflow_profiles"))
    return types, latest


# --- OCEL assembly ----------------------------------------------------------------------------

@dataclass
class Ocel:
    events: pl.DataFrame           # ocel_id, ocel_type, ocel_time + event attributes
    event_attrs: list[str]
    objects: dict[str, ObjectType]
    e2o: pl.DataFrame              # ocel_event_id, ocel_object_id, ocel_qualifier
    o2o: pl.DataFrame              # ocel_source_id, ocel_target_id, ocel_qualifier
    stats: dict = field(default_factory=dict)


DEFAULT_BATCH = 100_000  # events per batch for --batch-size
EVENT_ATTRS = {"lifecycle": "string", "revision": "integer", "lab_location": "string"}


def event_sql(sel: Selection, cte: str | None, salt: str) -> str:
    """trans.events of the selection with a stable id: md5 over all columns (+ salt), so exact
    duplicate rows share an id and are dropped."""
    key = ("concat_ws('|', " + sql_str(salt) + ", e.event_name, e.event_type, "
           "to_char(e.happened_at AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS.US'), e.case_id, e.token_id, "
           "e.token_type, e.revision, coalesce(e.actor_ref::text, ''), coalesce(e.workstation_ref::text, ''), "
           "coalesce(e.lab_ref::text, ''))")
    sql = (f"SELECT 'ev:' || left(md5({key}), 16) AS ocel_id, e.event_name, e.event_type, e.happened_at, "
           f"e.case_id, e.token_id, e.token_type, e.revision, e.actor_ref, e.workstation_ref, e.lab_ref "
           f"FROM trans.events e")
    if cte is not None:
        sql = f"WITH sel AS ({cte}) {sql} JOIN sel ON sel.case_id = e.case_id"
    conds = sel.event_conds()
    if conds:
        sql += " WHERE " + " AND ".join(conds)
    return sql


def transform_events(ev: pl.DataFrame, names: Names) -> pl.DataFrame:
    return ev.select(
        "ocel_id",
        pl.col("event_name").replace_strict(names.config["event_names"],
                                            default=jfmt("event_{}", pl.col("event_name").cast(pl.String)),
                                            return_dtype=pl.String).alias("ocel_type"),
        pl.col("happened_at").alias("ocel_time"),
        pl.col("event_type").replace_strict(LIFECYCLE, default="unknown", return_dtype=pl.String).alias("lifecycle"),
        pl.col("revision").cast(pl.Int64),
        pl.col("lab_ref").replace_strict(names.config["lab_locations"], default=pl.col("lab_ref").cast(pl.String),
                                         return_dtype=pl.String).alias("lab_location"),
    )


def make_e2o(ev: pl.DataFrame, ids: Ids) -> pl.DataFrame:
    def rel(df: pl.DataFrame, col: str, kind: str) -> pl.DataFrame:
        return df.select(pl.col("ocel_id").alias("ocel_event_id"),
                         ids.obj(kind, df[col]).alias("ocel_object_id"), pl.lit(kind).alias("ocel_qualifier"))

    rels = [rel(ev, "case_id", "case")]
    rels += [rel(ev.filter(pl.col("token_type") == tt), "token_id", kind)
             for tt, kind in TOKEN_KIND.items() if kind != "case"]
    rels += [rel(ev.filter(pl.col(col).is_not_null()), col, kind)
             for col, kind in (("actor_ref", "actor"), ("workstation_ref", "workstation"))]
    return pl.concat(rels).unique(maintain_order=True)


def finish_objects(db: Db, names: Names, types: dict[str, ObjectType], latest: dict[str, pl.DataFrame],
                   obj_refs: pl.Series, actor_refs: pl.Series, ws_refs: pl.Series, stats: dict) -> pl.DataFrame:
    """O2O, actor/workstation objects and stubs. *_refs: ids referenced by the events."""
    ids = names.ids
    o2o_parts = []

    def link(kind: str, df: pl.DataFrame, col: str, target: str, q: str):
        d = df.filter(pl.col(col).is_not_null())
        o2o_parts.append(pl.DataFrame({"ocel_source_id": ids.obj(kind, d["id"]),
                                       "ocel_target_id": ids.obj(target, d[col]), "ocel_qualifier": q}))

    for kind in ("container", "block", "analysis"):
        link(kind, latest[kind], "case_id", "case", "part of")
    link("slide", latest["slide"], "block_id", "block", "cut from")
    link("slide", latest["slide"], "case_id", "case", "part of")
    link("case", latest["case"], "responsible_actor", "actor", "responsible actor")
    o2o = pl.concat(o2o_parts).unique(maintain_order=True)

    # resources as objects
    actor_ids = pl.concat([actor_refs.drop_nulls().cast(pl.Int64),
                           latest["case"]["responsible_actor"].drop_nulls().cast(pl.Int64)]).unique().sort()
    types["actor"] = resource("actor", actor_ids, names, {"name": ("actor", "actors")}, db)
    ws_ids = ws_refs.drop_nulls().cast(pl.Int64).unique().sort()
    types["workstation"] = resource("workstation", ws_ids, names, {"name": ("master", "workstations")}, db)

    # stub objects for references to rows that are missing in trans/hist (e.g. deleted blocks)
    known = pl.concat([t.initial["ocel_id"] for t in types.values()])
    refs = pl.concat([obj_refs, o2o["ocel_source_id"], o2o["ocel_target_id"]]).unique()
    missing = refs.filter(~refs.is_in(known.implode()))
    if missing.len():
        kinds = missing.str.split_exact(":", 1).struct.field("field_0")
        for kind in kinds.unique().to_list():
            add = missing.filter(kinds == kind)
            t = types[kind]
            t.initial = pl.concat([t.initial, pl.DataFrame({"ocel_id": add})], how="diagonal_relaxed")
            stats[f"stub objects ({kind}, missing in trans/hist)"] = add.len()
    stats["o2o relations"] = o2o.height
    for k, t in types.items():
        stats[f"objects: {k}"] = t.initial.height
        if t.changes.height:
            stats[f"object changes: {k}"] = t.changes.height
    return o2o


def build(db: Db, sel: Selection, names: Names, history: bool, salt: str) -> Ocel:
    """Everything in memory (needed for JSON)."""
    t0 = time.time()
    cte = sel.case_cte()
    ev = db.query(event_sql(sel, cte, salt))
    n_raw = ev.height
    ev = ev.unique("ocel_id", keep="first")
    stats = {"events (raw rows)": n_raw, "exact duplicates dropped": n_raw - ev.height}
    log(f"  events loaded: {ev.height:,} ({time.time() - t0:.1f}s)")
    events = transform_events(ev, names).sort("ocel_time", "ocel_id")
    e2o = make_e2o(ev, names.ids)
    stats["events on REPORT/OTHER tokens (case link only)"] = ev.filter(pl.col("token_type") >= 5).height

    types, latest = load_objects(db, cte, names, history, existing_tables(db))
    log(f"  objects loaded ({time.time() - t0:.1f}s)")
    o2o = finish_objects(db, names, types, latest, e2o["ocel_object_id"], ev["actor_ref"], ev["workstation_ref"], stats)
    stats.update({"events": events.height, "e2o relations": e2o.height})
    return Ocel(events, list(EVENT_ATTRS), types, e2o, o2o, stats)


def build_batched(db: Db, sel: Selection, names: Names, history: bool, salt: str, batch_size: int,
                  sink: BundleWriter | None) -> dict:
    """Streams the events in batches of ~batch_size rows straight into the bundle's Parquet files.
    Memory is bounded by the batch size and the number of objects, not the number of events.
    Postgres removes exact duplicates and sorts by time, so the event files compress like the
    in-memory ones, and each event's E2O rows stay adjacent (run-length encoding of the ids)."""
    t0 = time.time()
    cte = sel.case_cte()
    sql = event_sql(sel, cte, salt)
    n_raw = db.query(f"SELECT count(*) AS n FROM ({sql}) x")["n"][0]
    stats = {"events (raw rows)": n_raw}

    # objects first: they are needed in full anyway (history diff), events only once
    types, latest = load_objects(db, cte, names, history, existing_tables(db))
    log(f"  objects loaded ({time.time() - t0:.1f}s)")

    n_ev = n_e2o = n_other = 0
    obj_refs, actor_refs, ws_refs = [], [], []
    for i, ev in enumerate(db.stream(f"SELECT DISTINCT * FROM ({sql}) x ORDER BY happened_at, ocel_id", batch_size)):
        e2o = make_e2o(ev, names.ids).sort("ocel_event_id", "ocel_qualifier")
        if sink is not None:
            sink.events(transform_events(ev, names))
            sink.e2o(e2o)
        n_ev, n_e2o = n_ev + ev.height, n_e2o + e2o.height
        n_other += ev.filter(pl.col("token_type") >= 5).height
        obj_refs.append(e2o["ocel_object_id"].unique())
        actor_refs.append(ev["actor_ref"].drop_nulls().unique())
        ws_refs.append(ev["workstation_ref"].drop_nulls().unique())
        log(f"  batch {i + 1}: {n_ev:,} / {n_raw:,} rows ({time.time() - t0:.1f}s)")

    def cat(parts: list[pl.Series], dtype) -> pl.Series:
        return pl.concat(parts).unique() if parts else pl.Series([], dtype=dtype)

    stats.update({"exact duplicates dropped": n_raw - n_ev,
                  "events on REPORT/OTHER tokens (case link only)": n_other})
    o2o = finish_objects(db, names, types, latest, cat(obj_refs, pl.String), cat(actor_refs, pl.Int64),
                         cat(ws_refs, pl.Int64), stats)
    stats.update({"events": n_ev, "e2o relations": n_e2o})
    if sink is not None:
        sink.objects(types)
        sink.o2o(o2o)
    return stats


def resource(kind: str, raw_ids: pl.Series, names: Names, attrs: dict, db: Db) -> ObjectType:
    data = {"ocel_id": names.ids.obj(kind, raw_ids)}
    for a, (how, table) in attrs.items():
        v = names.resolve(raw_ids, how, table)
        if v is not None and names.clear(how):
            data[a] = v
    if kind == "workstation" and raw_ids.len():
        meta = db.query(f"SELECT id, workstation_type, lab_location FROM master.workstations "
                        f"WHERE id IN ({sql_ints(raw_ids.to_list())})")
        meta = pl.DataFrame({"id": raw_ids}).join(meta, on="id", how="left")
        data["workstation_type"] = meta["workstation_type"].replace_strict(
            names.config["workstation_types"], default=None, return_dtype=pl.String)
        data["lab_location"] = meta["lab_location"].replace_strict(
            names.config["lab_locations"], default=None, return_dtype=pl.String)
    initial = pl.DataFrame(data) if raw_ids.len() else pl.DataFrame(schema={k: pl.String for k in data})
    attrs_out = [c for c in initial.columns if c != "ocel_id"]
    return ObjectType(kind, initial, align_changes(pl.DataFrame(), initial, attrs_out), attrs_out)


# --- writers ----------------------------------------------------------------------------------

def ocel_type(dtype: pl.DataType) -> str:
    if dtype.is_integer():
        return "integer"
    if dtype.is_float():
        return "float"
    if dtype == pl.Boolean:
        return "boolean"
    if isinstance(dtype, pl.Datetime):
        return "time"
    return "string"


ARROW = {"string": pa.string(), "integer": pa.int64(), "float": pa.float64(), "boolean": pa.bool_(),
         "time": pa.timestamp("us", tz="UTC")}


def to_arrow(df: pl.DataFrame, fixed: dict[str, str], attrs: dict[str, str]) -> pa.Table:
    """pm4py's bundle reader checks exact Arrow types and that fixed columns are non-nullable."""
    schema = pa.schema([pa.field(c, ARROW[t], nullable=False) for c, t in fixed.items()] +
                       [pa.field(c, ARROW[t], nullable=True) for c, t in attrs.items()])
    cols = [*fixed, *attrs]
    df = df.select(pl.col(c).cast(pl.String) if (fixed | attrs)[c] == "string" else pl.col(c) for c in cols)
    return df.to_arrow().cast(schema)


def pct(name: str) -> str:
    safe = set(b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")
    return "".join(chr(b) if b in safe else f"%{b:02X}" for b in name.encode())


def attr_types(df: pl.DataFrame, attrs: list[str]) -> dict[str, str]:
    return {a: ocel_type(df.schema[a]) for a in attrs}


class BundleWriter:
    """Writes the bundle layout into a directory, appending event / E2O batches to open Parquet
    files, and zips it at the end (a zip can only have one entry open for writing at a time)."""

    EV_FIXED = {"ocel_id": "string", "ocel_time": "time"}
    REL = {"ocel_qualifier": "string"}
    E2O_FIXED = {"ocel_event_id": "string", "ocel_object_id": "string", **REL}
    O2O_FIXED = {"ocel_source_id": "string", "ocel_target_id": "string", **REL}

    def __init__(self, root: Path):
        self.root = root
        self.writers: dict[str, pq.ParquetWriter] = {}
        self.meta = {"ocelVersion": "2.0", "bundleFormatVersion": "1.0", "storageFormat": "parquet",
                     "eventTypes": {}, "objectTypes": {},
                     "relations": {"e2o": "relations/e2o.parquet", "o2o": "relations/o2o.parquet"}}

    def _append(self, rel: str, table: pa.Table) -> None:
        if rel not in self.writers:
            (self.root / rel).parent.mkdir(parents=True, exist_ok=True)
            self.writers[rel] = pq.ParquetWriter(self.root / rel, table.schema, compression="zstd")
        self.writers[rel].write_table(table)

    def events(self, df: pl.DataFrame) -> None:
        for (etype,), part in df.partition_by("ocel_type", as_dict=True, maintain_order=True).items():
            f = f"events/event_{pct(etype)}.parquet"
            self._append(f, to_arrow(part, self.EV_FIXED, EVENT_ATTRS))
            self.meta["eventTypes"].setdefault(
                etype, {"file": f, "attributes": [{"name": a, "type": t} for a, t in EVENT_ATTRS.items()]})

    def e2o(self, df: pl.DataFrame) -> None:
        """Rows of one event must be adjacent (e.g. sorted by event id): dictionary + run-length
        encoding then compress the high-entropy event ids well."""
        self._append("relations/e2o.parquet", to_arrow(df, self.E2O_FIXED, {}))

    def o2o(self, df: pl.DataFrame) -> None:
        self._append("relations/o2o.parquet", to_arrow(df.sort("ocel_source_id", "ocel_qualifier"), self.O2O_FIXED, {}))

    def objects(self, types: dict[str, ObjectType]) -> None:
        for name, t in types.items():
            ty = attr_types(t.initial, t.attrs)
            f, cf = f"objects/object_{pct(name)}.parquet", f"object_changes/object_changes_{pct(name)}.parquet"
            self._append(f, to_arrow(t.initial, {"ocel_id": "string"}, ty))
            self._append(cf, to_arrow(t.changes, {"ocel_id": "string", "ocel_time": "time", "ocel_changed_field": "string"}, ty))
            self.meta["objectTypes"][name] = {"file": f, "changesFile": cf,
                                              "attributes": [{"name": a, "type": v} for a, v in ty.items()]}

    def close(self, paths: list[Path]) -> None:
        empty = pl.DataFrame(schema={c: pl.String for c in self.E2O_FIXED})
        if "relations/e2o.parquet" not in self.writers:  # declared tables must exist, even if empty
            self.e2o(empty)
        for w in self.writers.values():
            w.close()
        (self.root / "ocel-meta.json").write_text(json.dumps(self.meta, indent=2, ensure_ascii=False), encoding="utf-8")
        files = sorted(p for p in self.root.rglob("*") if p.is_file())
        for path in paths:
            with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_STORED) as zf:  # Parquet is compressed
                for p in files:
                    zf.write(p, p.relative_to(self.root).as_posix())


def write_bundle(o: Ocel, path: Path) -> None:
    with tempfile.TemporaryDirectory(dir=path.parent, prefix=".ocel-bundle-") as tmp:
        w = BundleWriter(Path(tmp))
        w.events(o.events)
        w.e2o(o.e2o.sort("ocel_event_id", "ocel_qualifier"))
        w.objects(o.objects)
        w.o2o(o.o2o)
        w.close([path])


def jfmt(template: str, *exprs: pl.Expr) -> pl.Expr:
    """Like pl.format, but literal braces are allowed (pl.format reads '{name}' as a column)."""
    lits = template.split("{}")
    assert len(lits) == len(exprs) + 1, template
    parts: list[pl.Expr] = []
    for lit, e in zip(lits, [*exprs, None]):
        if lit:
            parts.append(pl.lit(lit))
        if e is not None:
            parts.append(e)
    return pl.concat_str(parts)


def jval(e: pl.Expr) -> pl.Expr:
    """JSON literal of each value (strings quoted and escaped) via polars' JSON encoder."""
    return pl.struct(e.alias("v")).struct.json_encode().str.slice(5).str.strip_suffix("}")


def jattr(name: str, e: pl.Expr, dtype: pl.DataType) -> pl.Expr:
    v = e.dt.to_string(TIME_FMT) if isinstance(dtype, pl.Datetime) else e
    return pl.when(e.is_not_null()).then(jfmt('{"name":{},"value":{}}', pl.lit(json.dumps(name)), jval(v)))


def write_json(o: Ocel, path: Path, chunk: int = 200_000) -> None:
    ev_types = attr_types(o.events, o.event_attrs)
    decl = lambda types: [{"name": a, "type": t} for a, t in types.items()]  # noqa: E731
    header = {
        "objectTypes": [{"name": n, "attributes": decl(attr_types(t.initial, t.attrs))} for n, t in o.objects.items()],
        "eventTypes": [{"name": n, "attributes": decl(ev_types)} for n in o.events["ocel_type"].unique().sort()],
    }
    rel = lambda src, dst: jfmt('{"objectId":{},"qualifier":{}}', jval(pl.col(dst)), jval(pl.col("ocel_qualifier")))  # noqa: E731

    # events: one JSON object per row, built column-wise
    e_rel = o.e2o.group_by("ocel_event_id").agg(rel(None, "ocel_object_id").str.join(",").alias("_r"))
    ev = o.events.join(e_rel, left_on="ocel_id", right_on="ocel_event_id", how="left")
    e_attrs = pl.concat_list([jattr(a, pl.col(a), ev.schema[a]) for a in o.event_attrs]).list.drop_nulls().list.join(",")
    ev_json = ev.select(jfmt('{"id":{},"type":{},"time":"{}","attributes":[{}],"relationships":[{}]}',
                                  jval(pl.col("ocel_id")), jval(pl.col("ocel_type")), pl.col("ocel_time").dt.to_string(TIME_FMT),
                                  e_attrs, pl.col("_r").fill_null(""))).to_series()

    # objects: initial values at the epoch, then hist changes in time order
    o_rel = o.o2o.group_by("ocel_source_id").agg(rel(None, "ocel_target_id").str.join(",").alias("_r"))
    epoch = '"' + EPOCH.strftime("%Y-%m-%dT%H:%M:%SZ") + '"'
    obj_json = []
    for name, t in o.objects.items():
        frags = []
        for a in t.attrs:
            dtype = t.initial.schema[a]
            v = (lambda e: e.dt.to_string(TIME_FMT)) if isinstance(dtype, pl.Datetime) else (lambda e: e)
            ch = t.changes.filter(pl.col("ocel_changed_field") == a)
            # pm4py reads the first entry per name as the initial value: an attribute that only gets
            # a value later needs an explicit null at the epoch, or that value would be back-dated
            frags.append(t.initial.filter(pl.col(a).is_not_null() | pl.col("ocel_id").is_in(ch["ocel_id"].implode())).select(
                "ocel_id", pl.lit(EPOCH).cast(pl.Datetime("us", "UTC")).alias("_t"),
                jfmt('{"name":{},"time":{},"value":{}}', pl.lit(json.dumps(a)), pl.lit(epoch),
                     jval(v(pl.col(a))).fill_null("null")).alias("_f")))
            frags.append(ch.select(
                "ocel_id", pl.col("ocel_time").alias("_t"),
                jfmt('{"name":{},"time":"{}","value":{}}', pl.lit(json.dumps(a)),
                          pl.col("ocel_time").dt.to_string(TIME_FMT), jval(v(pl.col(a)))).alias("_f")))
        attrs = (pl.concat(frags).sort("ocel_id", "_t").group_by("ocel_id", maintain_order=True)
                 .agg(pl.col("_f").str.join(",").alias("_a")) if frags else pl.DataFrame(schema={"ocel_id": pl.String, "_a": pl.String}))
        ob = (t.initial.select("ocel_id").join(attrs, on="ocel_id", how="left")
              .join(o_rel, left_on="ocel_id", right_on="ocel_source_id", how="left"))
        obj_json.append(ob.select(jfmt('{"id":{},"type":{},"attributes":[{}],"relationships":[{}]}',
                                            jval(pl.col("ocel_id")), pl.lit(json.dumps(name)),
                                            pl.col("_a").fill_null(""), pl.col("_r").fill_null(""))).to_series())
    obj_series = pl.concat(obj_json)

    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "wt", encoding="utf-8") as f:
        f.write('{"objectTypes":' + json.dumps(header["objectTypes"], ensure_ascii=False))
        f.write(',\n"eventTypes":' + json.dumps(header["eventTypes"], ensure_ascii=False))
        for key, s in (("objects", obj_series), ("events", ev_json)):
            f.write(f',\n"{key}":[\n')
            for i in range(0, s.len(), chunk):
                if i:
                    f.write(",\n")
                f.write(",\n".join(s.slice(i, chunk).to_list()))
            f.write("\n]")
        f.write("}\n")


def output_kind(p: Path) -> str:
    n = p.name.lower()
    if n.endswith(".ocel.zip"):
        return "bundle"
    if n.endswith((".json", ".jsonocel", ".json.gz", ".jsonocel.gz")):
        return "json"
    raise SystemExit(f"unsupported output extension: {p.name} (use .ocel.zip, .json[.gz] or .jsonocel[.gz])")


# --- CLI --------------------------------------------------------------------------------------

def parse_time(s: str) -> dt.datetime:
    t = dt.datetime.fromisoformat(s)
    return t.replace(tzinfo=dt.UTC) if t.tzinfo is None else t


def csv_list(s: str) -> list[str]:
    return [x.strip() for x in s.split(",") if x.strip()]


def resolve_enum(values: list[str], table: dict[int, str], what: str) -> list[int]:
    by_name = {v.lower(): k for k, v in table.items()}
    out = []
    for v in values:
        if v.lstrip("-").isdigit():
            out.append(int(v))
        elif v.lower() in by_name:
            out.append(by_name[v.lower()])
        else:
            raise SystemExit(f"unknown {what} '{v}'; known: {', '.join(sorted(table.values()))}")
    return out


def main() -> None:
    from dotenv import load_dotenv

    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--output", type=Path, action="append", default=[], help="output file (repeatable)")
    ap.add_argument("--dry-run", action="store_true", help="extract and report counts, write nothing")
    g = ap.add_argument_group("selection")
    g.add_argument("--from", dest="start", type=parse_time, help="ISO date/time, inclusive (naive = UTC)")
    g.add_argument("--to", dest="end", type=parse_time, help="ISO date/time, exclusive (naive = UTC)")
    g.add_argument("--window", choices=["case", "event"], default="case",
                   help="case: cases whose first event is in [from, to), with ALL their events (default); "
                        "event: only events in [from, to)")
    g.add_argument("--division", type=csv_list, default=[], help="patho divisions, names or ids, e.g. HISTOLOGY,CYTOLOGY")
    g.add_argument("--priority", type=csv_list, default=[], help="case priorities, names or ids")
    g.add_argument("--profile", type=csv_list, default=[], help="workflow profiles, names or ids (any match)")
    g.add_argument("--specimen-type", type=csv_list, default=[], help="master.specimen_types ids")
    g.add_argument("--case-id", type=csv_list, default=[], help="trans.cases ids")
    g.add_argument("--event", type=csv_list, default=[], help="only these event names (names or ids)")
    g.add_argument("--exclude-event", type=csv_list, default=[], help="drop these event names (names or ids)")
    g.add_argument("--lab", type=csv_list, default=[], help="only events at these lab locations (names or ids)")
    g.add_argument("--max-revision", type=int, help="drop events with a higher revision (1 = originals only)")
    g.add_argument("--sample", type=int, help="random sample of N of the selected cases")
    g.add_argument("--seed", type=int, default=0, help="seed for --sample (deterministic)")
    p = ap.add_argument_group("privacy")
    p.add_argument("--names", choices=["none", "actor", "all"], default="actor",
                   help="which master references become ids: none = all names in clear; actor = actor ids, "
                        "other master data by name (default); all = ids for all master data "
                        "(config vocabulary, e.g. HISTOLOGY, always stays readable)")
    p.add_argument("--hash-ids", action="store_true",
                   help="replace every exported database id by a keyed hash (needs --salt or UNPAIDME_OCEL_SALT); "
                        "also drops lab_id/requisition_id/legacy_id")
    p.add_argument("--salt", help="secret key for --hash-ids (prefer the UNPAIDME_OCEL_SALT env var)")
    x = ap.add_argument_group("source")
    x.add_argument("--no-history", action="store_true", help="ignore hist.* (no object attribute changes)")
    x.add_argument("--dsn", help="postgresql://... (default: PG* environment variables / .env)")
    x.add_argument("--engine", choices=["connectorx", "adbc"], default="connectorx",
                   help="driver for the in-memory queries (batched event reads always use ADBC)")
    x.add_argument("--batch-size", type=int, nargs="?", const=DEFAULT_BATCH, metavar="N",
                   help=f"stream the events from the database in batches of ~N rows directly into the "
                        f"Parquet files, so memory depends on N and the number of objects instead of the "
                        f"number of events. Only for .ocel.zip outputs. Recommended: {DEFAULT_BATCH} (used for a "
                        f"bare --batch-size): ~1.3 KB per batch row, i.e. ~0.15 GB on top of the objects, and "
                        f"the best compression in tests; much smaller batches give more Parquet row groups "
                        f"(slightly larger files), larger ones only cost memory")
    args = ap.parse_args()

    if not args.output and not args.dry_run:
        ap.error("give at least one -o/--output, or --dry-run")
    kinds = {p: output_kind(p) for p in args.output}
    if args.batch_size is not None:
        if args.batch_size < 1:
            ap.error("--batch-size must be positive")
        if any(k != "bundle" for k in kinds.values()):
            ap.error("--batch-size only supports .ocel.zip outputs (JSON is still written in memory)")
    load_dotenv()
    salt = args.salt or os.environ.get("UNPAIDME_OCEL_SALT")
    if args.hash_ids and not salt:
        ap.error("--hash-ids needs a secret: --salt or UNPAIDME_OCEL_SALT")

    db = Db(pg_uri(args.dsn), args.engine)
    config = {t: db.lookup(f"SELECT id, name FROM config.{t}") for t in CONFIG_TABLES}
    sel = Selection(
        start=args.start, end=args.end, window=args.window,
        divisions=resolve_enum(args.division, config["patho_divisions"], "division"),
        priorities=resolve_enum(args.priority, config["case_priority"], "priority"),
        profiles=resolve_enum(args.profile, config["workflow_profiles"], "workflow profile"),
        specimen_types=[int(v) for v in args.specimen_type],
        case_ids=[int(v) for v in args.case_id],
        event_names=resolve_enum(args.event, config["event_names"], "event name"),
        exclude_event_names=resolve_enum(args.exclude_event, config["event_names"], "event name"),
        labs=resolve_enum(args.lab, config["lab_locations"], "lab location"),
        max_revision=args.max_revision, sample=args.sample, seed=args.seed,
    )
    ids = Ids(salt if args.hash_ids else None)
    need = {"none": MASTER_NAME_SQL, "actor": {k: v for k, v in MASTER_NAME_SQL.items() if k != "actors"},
            "all": {}}[args.names]
    names = Names(args.names, ids, config, {t: db.lookup(s) for t, s in need.items()}, args.hash_ids)

    t0 = time.time()
    log("extracting ...")
    if args.batch_size is not None:
        run_batched(db, sel, names, args, salt if args.hash_ids else "", list(kinds), t0)
        return
    o = build(db, sel, names, not args.no_history, salt if args.hash_ids else "")
    for k, v in o.stats.items():
        log(f"  {k:<48} {v:>12,}")
    if o.events.is_empty():
        log("warning: selection contains no events")
    for path, kind in kinds.items():
        if args.dry_run:
            break
        t1 = time.time()
        (write_bundle if kind == "bundle" else write_json)(o, path)
        log(f"wrote {path} ({path.stat().st_size / 1e6:,.1f} MB, {time.time() - t1:.1f}s)")
    log(f"done in {time.time() - t0:.1f}s")


def run_batched(db: Db, sel: Selection, names: Names, args, salt: str, paths: list[Path], t0: float) -> None:
    with tempfile.TemporaryDirectory(dir=paths[0].parent if paths else None, prefix=".ocel-bundle-") as tmp:
        sink = None if args.dry_run else BundleWriter(Path(tmp))
        stats = build_batched(db, sel, names, not args.no_history, salt, args.batch_size, sink)
        for k, v in stats.items():
            log(f"  {k:<48} {v:>12,}")
        if not stats["events"]:
            log("warning: selection contains no events")
        if sink is not None:
            t1 = time.time()
            sink.close(paths)
            for path in paths:
                log(f"wrote {path} ({path.stat().st_size / 1e6:,.1f} MB, {time.time() - t1:.1f}s)")
    log(f"done in {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
