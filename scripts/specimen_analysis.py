# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "matplotlib",
#     "numpy",
#     "pandas",
#     "scipy",
#     "seaborn",
#     "adbc-driver-postgresql",
#     "pyarrow",
#     "python-dotenv",
# ]
# ///
"""Specimen type analysis: per histology specimen type, arrival seasonality, yearly volume trend
and block-count distribution fits. Writes a PDF report and a model.json with, per specimen type,
its share of cases (overall and per weekday) and the best-fitting block-count distribution.

Connection via the standard libpq variables PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE
(also read from a .env file).

    uv run specimen_analysis.py --metrics aic=2,ks,rmse --top-k 3
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import warnings
from pathlib import Path

import adbc_driver_postgresql.dbapi
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from dotenv import load_dotenv
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.ticker import MaxNLocator
from scipy import stats

BLOCK_COVERAGE = 0.99  # report the specimen types making up this share of all blocks
LABEL_COVERAGE = 0.75  # front page: show these individually, the rest as "Other"
WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri"]
PAGE_SIZE = (8.27, 11.69)  # A4 portrait

# Discrete families are fitted by MLE within these shape bounds.
DISCRETE = {
    "Poisson": (stats.poisson, {"mu": (0, 200)}),
    "Negative Binomial": (stats.nbinom, {"n": (0.01, 200), "p": (0, 1)}),
    "Geometric": (stats.geom, {"p": (0, 1)}),
    "Log-Series": (stats.logser, {"p": (0, 1)}),
    "Zipf": (stats.zipf, {"a": (1.01, 8)}),
    "Yule-Simon": (stats.yulesimon, {"alpha": (0.05, 20)}),
}
# Continuous families are discretised to per-integer mass; all but Normal have loc fixed at 0.
CONTINUOUS = {
    "Normal": stats.norm,
    "Lognormal": stats.lognorm,
    "Gamma": stats.gamma,
    "Weibull": stats.weibull_min,
    "Exponential": stats.expon,
    "Pareto": stats.pareto,
    "Lomax": stats.lomax,
    "GenPareto": stats.genpareto,
    "Log-logistic": stats.fisk,
}

# Goodness-of-fit metrics, lower is better. Each gets (block counts, fit row).
METRICS = {
    "aic": lambda x, f: 2 * f.n_params - 2 * f.loglik,
    "bic": lambda x, f: np.log(len(x)) * f.n_params - 2 * f.loglik,
    "ks": lambda x, f: stats.kstest(x, f.dist.cdf).statistic,
    "cvm": lambda x, f: stats.cramervonmises(x, f.dist.cdf).statistic,
    "rmse": lambda x, f: np.sqrt(np.mean((_freq(x) - _mass(f.dist, _support(x))) ** 2)),
}

SPECIMEN_TYPES_QUERY = """
select id as specimen_id,
       location_code || ' ' || procedure_code as specimen_code,
       location_desc || ': ' || procedure_desc as specimen_desc
from reports.specimen_types
where patho_division = 'HISTOLOGY'
"""

CASES_QUERY = """
select c.specimen_type as specimen_id,
       r.accessioned_at::date as registration_date,
       count(b.id) as block_count
from trans.cases c
join trans.blocks b on b.case_id = c.id
join reports.case_lifecycle r on r.case_id = c.id
where r.accessioned_at is not null
group by c.id, c.specimen_type, r.accessioned_at::date
"""


def _support(x: np.ndarray) -> np.ndarray:
    return np.arange(x.min(), x.max() + 1)


def _freq(x: np.ndarray) -> np.ndarray:
    return np.bincount(x - x.min()) / len(x)


def _mass(dist, k: np.ndarray) -> np.ndarray:
    if isinstance(dist.dist, stats.rv_discrete):
        return dist.pmf(k)
    return dist.cdf(k + 0.5) - dist.cdf(k - 0.5)


def fit_distributions(x: np.ndarray, weights: dict[str, float]) -> pd.DataFrame:
    """All candidate fits with their metrics and weighted percentile-rank score, best first."""
    rows = []
    with warnings.catch_warnings():  # optimisers and CvM emit RuntimeWarnings on bad candidates
        warnings.simplefilter("ignore", RuntimeWarning)
        for name, (dist, bounds) in DISCRETE.items():
            params = stats.fit(dist, x, bounds).params._asdict()
            params.pop("loc")
            rows.append((name, dist(**params), params))
        for name, dist in CONTINUOUS.items():
            try:
                values = dist.fit(x) if dist is stats.norm else dist.fit(x, floc=0)
            except Exception:
                continue
            names = (dist.shapes.split(", ") if dist.shapes else []) + ["loc", "scale"]
            rows.append((name, dist(*values), {n: float(v) for n, v in zip(names, values)}))

        fits = pd.DataFrame(rows, columns=["name", "dist", "params"])
        fits["n_params"] = fits.params.map(len)
        fits["loglik"] = [np.log(np.clip(_mass(d, x), 1e-12, None)).sum() for d in fits.dist]
        for m in METRICS:
            fits[m] = [METRICS[m](x, f) for f in fits.itertuples()]

    ranks = sum(w * fits[m].rank(pct=True) for m, w in weights.items())
    fits["score"] = ranks / sum(weights.values())
    return fits.sort_values("score", ignore_index=True)


def specimen_page(cases: pd.DataFrame, title: str, fits: pd.DataFrame, top_k: int, metrics: list[str],
                  full_years: list[int]):
    fig, axs = plt.subplot_mosaic([["heat", "trend"], ["blocks", "blocks"], ["table", "table"]], figsize=PAGE_SIZE,
                                  width_ratios=[7, 3], height_ratios=[1, 1.5, 0.6], layout="constrained")
    ax_heat, ax_trend, ax_blocks, ax_table = axs["heat"], axs["trend"], axs["blocks"], axs["table"]
    fig.suptitle(f"{title} | Cases={len(cases)}", fontweight="bold")
    date = cases.registration_date

    heat = pd.crosstab(date.dt.day_of_week, date.dt.isocalendar().week).reindex(index=range(5), columns=range(1, 54),
                                                                                fill_value=0)
    sns.heatmap(heat, ax=ax_heat, yticklabels=WEEKDAYS, xticklabels=4)
    ax_heat.set(title="Arrivals during the year", xlabel="Week of year", ylabel="Day of week")

    yearly = date.dt.year.value_counts().reindex(full_years, fill_value=0).rename_axis("year").reset_index(name="cases")
    if len(yearly) > 1:
        sns.regplot(yearly, x="year", y="cases", ax=ax_trend)
    ax_trend.xaxis.set_major_locator(MaxNLocator(integer=True))
    ax_trend.set(title="Cases per full year", xlabel="Year", ylabel="Cases")

    x = cases.block_count.to_numpy()
    top = fits.head(top_k)
    curves = pd.concat(pd.DataFrame({"k": _support(x), "p": _mass(f.dist, _support(x)), "model": f.name})
                       for f in top.itertuples())
    sns.histplot(x=x, discrete=True, stat="probability", ax=ax_blocks)
    sns.lineplot(curves, x="k", y="p", hue="model", marker="o", ax=ax_blocks,
                 palette=sns.color_palette()[1:top_k + 1])
    ax_blocks.set(title="Block count distribution and best-fit models", xlabel="Block count", ylabel="Probability")

    table = top[["name", *metrics, "score"]].assign(
        params=top.params.map(lambda p: ", ".join(f"{k}={v:.3g}" for k, v in p.items())))
    ax_table.axis("off")
    tbl = ax_table.table(cellText=table.map(lambda v: f"{v:.3g}" if isinstance(v, float) else v).values,
                         colLabels=table.columns, loc="center")
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(9)
    tbl.auto_set_column_width(range(len(table.columns)))
    return fig


def front_page(overview: pd.DataFrame):
    share = overview.block_count / overview.block_count.sum()
    shown = overview.assign(share=share)[share.cumsum() - share < LABEL_COVERAGE]
    shown = pd.concat([shown, pd.DataFrame({"specimen_code": ["Other"], "share": [1 - shown.share.sum()]})])
    fig, ax = plt.subplots(figsize=PAGE_SIZE, layout="constrained")
    ax.pie(shown.share, labels=shown.specimen_code, autopct="%.1f%%", startangle=90, counterclock=False,
           colors=[*sns.color_palette(n_colors=len(shown) - 1), "lightgray"], wedgeprops={"edgecolor": "white"})
    ax.set_title("Share of blocks per specimen type")
    fig.suptitle("Specimen Type Analysis", fontweight="bold")
    return fig


def weekday_shares(cases: pd.DataFrame, pseudo_count: float) -> tuple[pd.Series, pd.DataFrame]:
    """Overall case share per specimen type, and per-weekday shares shrunk toward it (columns sum to 1)."""
    ct = pd.crosstab(cases.specimen_id, cases.registration_date.dt.day_of_week).reindex(columns=range(5), fill_value=0)
    overall = cases.specimen_id.value_counts(normalize=True).reindex(ct.index)
    return overall, ct.add(pseudo_count * overall, axis=0) / (ct.sum(axis=0) + pseudo_count)


def shares_page(shares: pd.DataFrame, labels: pd.Series, pseudo_count: float):
    fig, ax = plt.subplots(figsize=PAGE_SIZE, layout="constrained")
    sns.heatmap(shares.set_axis(labels[shares.index], axis=0).set_axis(WEEKDAYS, axis=1), ax=ax, annot=True,
                fmt=".1%", cbar=False, annot_kws={"fontsize": 7})
    ax.set(title=f"Share of cases per weekday (shrunk toward the overall share, pseudo-count {pseudo_count:g})",
           xlabel="Day of week", ylabel="Specimen type")
    return fig


def build_report(types: pd.DataFrame, cases: pd.DataFrame, output: Path, min_cases: int, top_k: int,
                 weights: dict[str, float], pseudo_count: float) -> dict:
    overview = (cases.groupby("specimen_id").agg(case_count=("block_count", "size"), block_count=("block_count", "sum"))
                .join(types.set_index("specimen_id"), how="inner")
                .sort_values("block_count", ascending=False))
    share = overview.block_count / overview.block_count.sum()
    reported = overview[(share.cumsum() - share < BLOCK_COVERAGE) & (overview.case_count >= min_cases)]
    if reported.empty:
        raise ValueError(f"No specimen type has at least {min_cases} cases.")
    print(f"Reporting {len(reported)} specimen types: {reported.case_count.sum():,} cases, "
          f"{reported.block_count.sum():,} blocks ({reported.block_count.sum() / overview.block_count.sum():.1%} of blocks)",
          flush=True)

    reported_cases = cases[cases.specimen_id.isin(reported.index)]
    overall, shares = weekday_shares(reported_cases, pseudo_count)
    first, last = cases.registration_date.min(), cases.registration_date.max()
    full_years = [y for y in range(first.year, last.year + 1)
                  if first <= pd.Timestamp(y, 1, 7) and last >= pd.Timestamp(y, 12, 24)]
    sns.set_theme()
    registry = {}
    with PdfPages(output, metadata={"Title": "Specimen Type Analysis", "CreationDate": dt.datetime.now()}) as pdf:
        pdf.savefig(front_page(overview))
        plt.close()
        for i, (sid, row) in enumerate(reported.iterrows(), start=1):
            dfi = cases[cases.specimen_id == sid]
            fits = fit_distributions(dfi.block_count.to_numpy(), weights)
            pdf.savefig(specimen_page(dfi, f"{row.specimen_code}: {row.specimen_desc} (id: {sid})", fits, top_k,
                                      list(weights), full_years))
            plt.close()
            best = fits.iloc[0]
            registry[str(sid)] = {
                "name": row.specimen_code,
                "frequency": float(overall[sid]),
                "dow_frequency": {str(d + 1): float(shares.at[sid, d]) for d in range(5)},  # ISO weekday, Mon = 1
                "distribution": best["name"],
                "scipy": best.dist.dist.name,
                "params": best.params,
                "support": [int(dfi.block_count.min()), int(dfi.block_count.max())],
            }
            print(f"Processed {row.specimen_code} ({i}/{len(reported)}): best fit {best['name']}", flush=True)
        pdf.savefig(shares_page(shares.loc[reported.index], reported.specimen_code, pseudo_count))
        plt.close()
    return registry


def parse_metrics(spec: str) -> dict[str, float]:
    """'aic=2,ks' -> {'aic': 2.0, 'ks': 1.0}"""
    weights = {}
    for item in spec.split(","):
        name, _, w = item.strip().partition("=")
        if name not in METRICS:
            raise argparse.ArgumentTypeError(f"unknown metric {name!r}, choose from {', '.join(METRICS)}")
        weights[name] = float(w or 1)
    return weights


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--metrics", type=parse_metrics, default=",".join(METRICS),
                        help=f"ranking metrics with optional weights, e.g. aic=2,ks (default: all of {', '.join(METRICS)})")
    parser.add_argument("--top-k", type=int, default=3, help="fits shown per specimen type")
    parser.add_argument("--min-cases", type=int, default=30, help="skip specimen types with fewer cases")
    parser.add_argument("--pseudo-count", type=float, default=250,
                        help="weekday shares: how many cases' worth to pull toward the overall share")
    parser.add_argument("--output", type=Path, default=Path("specimen_analysis_report.pdf"))
    parser.add_argument("--model-json", type=Path, default=Path("model.json"))
    args = parser.parse_args()

    load_dotenv()
    print("Loading cases ...", flush=True)
    with adbc_driver_postgresql.dbapi.connect("postgresql://") as conn:  # libpq reads the PG* env vars
        types = pd.read_sql_query(SPECIMEN_TYPES_QUERY, conn)
        cases = pd.read_sql_query(CASES_QUERY, conn)
    cases["registration_date"] = pd.to_datetime(cases.registration_date)
    print(f"Loaded {len(cases):,} cases with {cases.block_count.sum():,} blocks, "
          f"{cases.specimen_id.nunique()} specimen types, accessioned "
          f"{cases.registration_date.min():%Y-%m-%d} to {cases.registration_date.max():%Y-%m-%d}", flush=True)

    registry = build_report(types, cases, args.output, args.min_cases, args.top_k, args.metrics,
                            args.pseudo_count)
    args.model_json.write_text(json.dumps(registry, indent=2, sort_keys=True), encoding="utf-8")


if __name__ == "__main__":
    main()
