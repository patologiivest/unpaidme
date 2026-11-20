# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "holidays",
#     "matplotlib",
#     "numpy",
#     "pandas",
#     "scipy",
#     "statsmodels",
#     "adbc-driver-postgresql",
#     "pyarrow",
#     "python-dotenv",
# ]
# ///
"""Daily histology case arrivals: fits a negative-binomial GLM (trend, weekday, Fourier
seasonality, holiday effects), optionally validates it on train/test splits, and simulates
arrivals from --now (inclusive) to --horizon. Output columns: reg_date, cnt and, with
--scenarios, the pessimistic/optimistic per-day quantiles cnt_lo and cnt_hi.

Data comes from --data (CSV/Parquet/JSON with a reg_date column, one row per case or
already aggregated with a cnt column) or from the database via the libpq variables PGHOST,
PGPORT, PGUSER, PGPASSWORD, PGDATABASE (also read from a .env file).

    uv run arrivals.py --now 2026-09-01 --horizon 2027-12-31 --split 2025-03-01 --split 2025-09-01 --scenarios
"""

from __future__ import annotations

import argparse
import datetime as dt
import warnings
from dataclasses import dataclass
from pathlib import Path

import holidays
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
from dateutil.easter import easter
from matplotlib.backends.backend_pdf import PdfPages
from scipy import stats

ARRIVALS_QUERY = """
select r.accessioned_at::date as reg_date
from trans.cases c
join reports.case_lifecycle r on r.case_id = c.id
join reports.specimen_types s on s.id = c.specimen_type
where s.patho_division = 'HISTOLOGY' and r.accessioned_at is not null
"""

HOLIDAY_EFFECTS = ["before_hol_2", "before_hol_1", "after_hol_1", "after_hol_2"]


@dataclass
class Calendar:
    """Which days are modelled and with which regressors."""

    country: str
    school_weeks: list[int]  # ISO weeks with school holidays; Easter week is added per year
    harmonics: int  # number of yearly Fourier terms
    weekends: bool
    origin: pd.Timestamp  # t = 0, in years

    def features(self, start: dt.date, end: dt.date) -> pd.DataFrame:
        """Modelled days in [start, end) with regressors. Public holidays have no arrivals and are dropped."""
        d = pd.Series(pd.date_range(start, end, freq="D", inclusive="left"), name="reg_date")
        years = range(d.dt.year.min() - 1, d.dt.year.max() + 2) if len(d) else []
        hol = pd.DatetimeIndex(sorted(holidays.country_holidays(self.country, years=years)))
        easter_week = {y: (easter(y) - dt.timedelta(days=2)).isocalendar().week for y in years}
        woy = d.dt.isocalendar().week.astype(int)
        doy = d.dt.day_of_year

        df = pd.DataFrame({
            "reg_date": d,
            "dow": d.dt.day_of_week,  # 0 = Monday
            "t": (d - self.origin).dt.days / 365.25,
            "before_hol_2": d.isin(hol - pd.Timedelta(days=2)),
            "before_hol_1": d.isin(hol - pd.Timedelta(days=1)),
            "after_hol_1": d.isin(hol + pd.Timedelta(days=1)),
            "after_hol_2": d.isin(hol + pd.Timedelta(days=2)),
            "school_holiday": woy.isin(self.school_weeks) | (woy == d.dt.year.map(easter_week)),
            "xmas_season": ((d.dt.month == 12) & (d.dt.day >= 23)) | ((d.dt.month == 1) & (d.dt.day <= 2)),
        })
        for k in range(1, self.harmonics + 1):
            df[f"s{k}"] = np.sin(2 * np.pi * k * doy / 365.25)
            df[f"c{k}"] = np.cos(2 * np.pi * k * doy / 365.25)
        keep = ~d.isin(hol) & (self.weekends | (df.dow < 5))
        return df[keep].reset_index(drop=True)

    @property
    def formula(self) -> str:
        fourier = [f"{sc}{k}" for k in range(1, self.harmonics + 1) for sc in "sc"]
        return "cnt ~ " + " + ".join(["t", "C(dow)", *fourier, *HOLIDAY_EFFECTS, "school_holiday", "xmas_season"])


def fit(counts: pd.Series, start: dt.date, end: dt.date, cal: Calendar):
    """NB GLM on the modelled days in [start, end); days without arrivals count as 0."""
    df = cal.features(start, end)
    df["cnt"] = df.reg_date.map(counts).fillna(0)
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")  # convergence chatter from the NB optimiser
        return smf.negativebinomial(cal.formula, data=df).fit(disp=0, maxiter=200)


def predict(model, start: dt.date, end: dt.date, cal: Calendar) -> pd.DataFrame:
    """Per-day predictive NB distribution (mean mu, scipy parameters n and p) on [start, end)."""
    df = cal.features(start, end)
    df["mu"] = model.predict(df, which="mean")
    df["n"] = 1 / model.params["alpha"]
    df["p"] = df.n / (df.n + df.mu)
    return df


def validate(counts: pd.Series, min_date: dt.date, splits: list[dt.date], now: dt.date, cal: Calendar,
             interval: float, pdf: PdfPages | None) -> pd.DataFrame:
    """Rolling origin: train on [min_date, split), test on [split, next split or now)."""
    rows = []
    for split, test_end in zip(splits, [*splits[1:], now]):
        val = predict(fit(counts, min_date, split, cal), split, test_end, cal)
        val["cnt"] = val.reg_date.map(counts).fillna(0)
        lo, hi = quantiles(val, interval)
        err = val.cnt - val.mu
        rows.append({"train": f"{min_date} – {split - dt.timedelta(days=1)}",
                     "test": f"{split} – {test_end - dt.timedelta(days=1)}", "days": len(val),
                     "MAE": err.abs().mean(), "bias": err.mean(),
                     "coverage": ((val.cnt >= lo) & (val.cnt <= hi)).mean(),
                     "logscore": stats.nbinom.logpmf(val.cnt, val.n, val.p).mean()})
        if pdf:
            pdf.savefig(validation_page(val, lo, hi, err, interval, rows[-1]))
            plt.close()
    return pd.DataFrame(rows)


def quantiles(pred: pd.DataFrame, interval: float) -> tuple[np.ndarray, np.ndarray]:
    tail = (1 - interval) / 2
    return stats.nbinom.ppf(tail, pred.n, pred.p), stats.nbinom.ppf(1 - tail, pred.n, pred.p)


def simulate(pred: pd.DataFrame, rng: np.random.Generator, scenarios: bool, interval: float) -> pd.DataFrame:
    out = pd.DataFrame({"reg_date": pred.reg_date.dt.date,
                        "cnt": stats.nbinom.rvs(pred.n, pred.p, random_state=rng)})
    if scenarios:
        lo, hi = quantiles(pred, interval)
        out["cnt_lo"], out["cnt_hi"] = lo.astype(int), hi.astype(int)
    return out


def validation_page(val: pd.DataFrame, lo, hi, err: pd.Series, interval: float, metrics: dict):
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(11.69, 8.27), sharex=True, layout="constrained")
    fig.suptitle(f"Validation, train {metrics['train']}, test {metrics['test']} | MAE={metrics['MAE']:.1f} "
                 f"bias={metrics['bias']:.1f} coverage={metrics['coverage']:.0%}", fontweight="bold")
    ax1.fill_between(val.reg_date, lo, hi, alpha=0.3, label=f"{interval:.0%} interval")
    ax1.plot(val.reg_date, val.mu, label="predicted mean")
    ax1.scatter(val.reg_date, val.cnt, s=8, color="k", label="actual")
    ax1.set_ylabel("cases/day")
    ax1.legend()
    ax2.plot(val.reg_date, err.rolling(20, min_periods=1).mean())  # ~4 working weeks
    ax2.axhline(0, color="grey", lw=1)
    ax2.set_ylabel("rolling mean error (20 days)")
    return fig


def forecast_page(counts: pd.Series, sim: pd.DataFrame, pred: pd.DataFrame, interval: float, now: dt.date):
    fig, ax = plt.subplots(figsize=(11.69, 8.27), layout="constrained")
    fig.suptitle(f"Simulated arrivals from {now}", fontweight="bold")
    hist = counts[counts.index >= pd.Timestamp(now) - pd.DateOffset(years=1)]
    lo, hi = quantiles(pred, interval)
    ax.scatter(hist.index, hist.values, s=8, color="k", label="history")
    ax.fill_between(pred.reg_date, lo, hi, alpha=0.3, label=f"{interval:.0%} interval")
    ax.plot(pred.reg_date, pred.mu, label="predicted mean")
    ax.scatter(pred.reg_date, sim.cnt, s=8, label="simulated")
    ax.set_ylabel("cases/day")
    ax.legend()
    return fig


def load_counts(data: Path | None) -> pd.Series:
    """Daily case counts indexed by date."""
    if data is None:
        import adbc_driver_postgresql.dbapi
        from dotenv import load_dotenv

        load_dotenv()
        with adbc_driver_postgresql.dbapi.connect("postgresql://") as conn:  # libpq reads the PG* env vars
            df = pd.read_sql_query(ARRIVALS_QUERY, conn)
    else:
        readers = {".csv": pd.read_csv, ".parquet": pd.read_parquet, ".json": pd.read_json}
        df = readers[data.suffix.lower()](data)
    df["reg_date"] = pd.to_datetime(df.reg_date).dt.normalize()
    if "cnt" in df:
        return df.groupby("reg_date").cnt.sum()
    return df.groupby("reg_date").size()


def write_frame(df: pd.DataFrame, path: Path) -> None:
    if path.suffix.lower() == ".parquet":
        df.to_parquet(path, index=False)
    else:
        df.to_csv(path, index=False)


def main() -> None:
    date = dt.date.fromisoformat
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", type=Path, help="arrivals file (default: read from the database)")
    parser.add_argument("--min-date", type=date, help="ignore arrivals before this date (default: first arrival)")
    parser.add_argument("--now", type=date, help="end of training data, start of simulation (default: last arrival, "
                        "which is excluded as it may be incomplete)")
    parser.add_argument("--horizon", type=date, help="last simulated day (default: one year after --now)")
    parser.add_argument("--split", type=date, action="append", default=[],
                        help="validate with a train/test split at this date; repeat for rolling-origin cross-validation")
    parser.add_argument("--scenarios", action="store_true", help="add pessimistic/optimistic columns cnt_lo/cnt_hi")
    parser.add_argument("--interval", type=float, default=0.8, help="central probability between cnt_lo and cnt_hi")
    parser.add_argument("--country", default="NO", help="ISO country code for public holidays")
    parser.add_argument("--school-weeks", type=lambda s: [int(w) for w in s.split(",")],
                        default=[9, 25, 26, 27, 28, 29, 30, 41], help="ISO weeks with school holidays (Norway)")
    parser.add_argument("--harmonics", type=int, default=10, help="yearly Fourier terms")
    parser.add_argument("--weekends", action="store_true", help="model and simulate Saturdays and Sundays too")
    parser.add_argument("--seed", type=int)
    parser.add_argument("--output", type=Path, default=Path("arrivals.csv"), help=".csv or .parquet")
    parser.add_argument("--report", type=Path, help="write validation and forecast plots to this PDF")
    args = parser.parse_args()

    counts = load_counts(args.data)
    min_date = args.min_date or counts.index.min().date()
    now = args.now or counts.index.max().date()
    horizon = args.horizon or now.replace(year=now.year + 1)
    counts = counts[(counts.index >= pd.Timestamp(min_date)) & (counts.index < pd.Timestamp(now))]
    splits = sorted(args.split)
    if any(not min_date < s < now for s in splits):
        parser.error(f"--split dates must lie between {min_date} and {now}")
    print(f"Training on {counts.sum():,} cases, {min_date} to {now - dt.timedelta(days=1)}", flush=True)

    cal = Calendar(args.country, args.school_weeks, args.harmonics, args.weekends, pd.Timestamp(min_date))
    rng = np.random.default_rng(args.seed)
    pdf = PdfPages(args.report) if args.report else None
    try:
        if splits:
            scores = validate(counts, min_date, splits, now, cal, args.interval, pdf)
            print(scores.to_string(index=False, float_format="{:.3f}".format), flush=True)
        model = fit(counts, min_date, now, cal)
        pred = predict(model, now, horizon + dt.timedelta(days=1), cal)
        sim = simulate(pred, rng, args.scenarios, args.interval)
        if pdf:
            pdf.savefig(forecast_page(counts, sim, pred, args.interval, now))
            plt.close()
    finally:
        if pdf:
            pdf.close()

    write_frame(sim, args.output)
    print(f"Simulated {sim.cnt.sum():,} cases on {len(sim)} days, {now} to {horizon} -> {args.output}")


if __name__ == "__main__":
    main()
