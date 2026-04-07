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


# TODO: more stdout during execution since it can run for a while 
# TODO: Add a final frequency table indexed by week of year and day of week
# TODO: get rid of the error message '/site-packages/scipy/stats/_hypotests.py:445: RuntimeWarning: invalid value encountered in dividez = -_Ak(k, x[cond]) / (xp.pi * gamma_kp1)


from __future__ import annotations

import datetime as dt
import json
from dataclasses import dataclass
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from matplotlib.axes import Axes
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.figure import Figure
from scipy import optimize, stats
from dotenv import load_dotenv
import adbc_driver_postgresql.dbapi
import os


MIN_CASES_PER_SPECIMEN = 30
TOP_K_DISTRIBUTIONS = 3
CUTOFF_LABEL_PCT = 0.75
OUTPUT_PDF = Path("specimen_analysis_report.pdf")
MODEL_JSON = Path("model.json")
PAGE_SIZE = (8.27, 11.69)  # A4 portrait


@dataclass(frozen=True)
class FitResult:
    name: str
    params: dict[str, float]
    log_likelihood: float
    aic: float
    bic: float
    ks_stat: float
    ks_pvalue: float
    cvm_stat: float
    rmse_freq: float
    composite_rank_score: float


_SPECIMEN_TYPE_OVERVIEW_QUERY = """
select s.id,
s.location_code || ' ' || s.procedure_code as specimen_type,
s.location_desc || ': ' || s.procedure_desc as specimen_desc,
count(distinct c.id) as case_count,
count(b.id) as block_count
from reports.specimen_types s
inner join trans.cases c on s.id = c.specimen_type 
inner join trans.blocks b on b.case_id = c.id
where s.patho_division = 'HISTOLOGY'
group by s.id, s.location_code, s.procedure_code, s.location_desc, s.procedure_desc
order by block_count desc
"""

def _connect_to_db() -> adbc_driver_postgresql.dbapi.Connection:
    load_dotenv() 
    if "PGHOST" not in os.environ or "PGUSER" not in os.environ or "PGPASSWORD" not in os.environ or "PGDATABASE" not in os.environ:
        raise KeyError("Could not find Postgres configuration/credentials in the environment!")
    db_uri = f"postgresql://{os.environ['PGUSER']}:{os.environ['PGPASSWORD']}@{os.environ['PGHOST']}:5432/{os.environ['PGDATABASE']}"
    connection = adbc_driver_postgresql.dbapi.connect(db_uri)
    return connection


def _load_specimen_types(connection: adbc_driver_postgresql.dbapi.Connection) -> pd.DataFrame:
    # Load from database
    df = pd.read_sql_query(_SPECIMEN_TYPE_OVERVIEW_QUERY, connection)

    # Data cleaning / consolidation
    df["block_count"] = pd.to_numeric(df["block_count"], errors="coerce")
    df["case_count"] = pd.to_numeric(df["case_count"], errors="coerce")
    df = df.dropna(subset=["block_count", "case_count"])
    df = df[df["case_count"] >= 0]#.copy()
    df = df[df["block_count"] >= 0]#.copy()
    df["block_count"] = np.round(df["block_count"]).astype(int)
    df["case_count"] = np.round(df["case_count"]).astype(int)
    df["specimen_type"] = df["specimen_type"].astype(str)
    df["specimen_desc"] = df["specimen_desc"].astype(str)

    sizes = df['block_count'] / df['block_count'].sum()
    cum_sizes = sizes.to_numpy().astype('float').cumsum()
    report_cutoff = int(np.where(cum_sizes > 0.99)[0][0])

    return df.head(report_cutoff)


def _load_cases(specmn_type: int, connection: adbc_driver_postgresql.dbapi.Connection) -> pd.DataFrame:
    query = f"""
select 
c.id as case_id,
c.specimen_type,
r.accessioned_at::date as registration_date,
count(b.id) as block_count
from trans.cases c 
inner join trans.blocks b on b.case_id = c.id
inner join reports.case_lifecycle r on r.id = c.id
where 
c.specimen_type = {specmn_type}
group by c.id, r.accessioned_at::date 
    """
    df = pd.read_sql_query(query, connection)
    df["registration_date"] = pd.to_datetime(df["registration_date"], errors="coerce")
    df["block_count"] = pd.to_numeric(df["block_count"], errors="coerce")
    df = df.dropna(subset=["registration_date", "block_count"])
    df = df[df["block_count"] >= 0]#.copy()
    df["block_count"] = np.round(df["block_count"]).astype(int)
    df["year"] = df["registration_date"].dt.year
    iso = df["registration_date"].dt.isocalendar()
    df["week_of_year"] = iso.week.astype(int)
    df["day_of_week"] = df["registration_date"].dt.dayofweek.astype(int)
    df["year_month"] = df["registration_date"].dt.to_period("M").dt.to_timestamp()
    return df


def _safe_log(values: np.ndarray, eps: float = 1e-12) -> np.ndarray:
    return np.log(np.clip(values, eps, None))


def _continuous_mass(dist: stats.rv_continuous, x: np.ndarray, params: tuple[float, ...]) -> np.ndarray:
    k = x.astype(float)
    upper = dist.cdf(k + 0.5, *params)
    lower = dist.cdf(np.clip(k - 0.5, 0, None), *params)
    return np.clip(upper - lower, 1e-12, None)


def _discrete_mass(dist: stats.rv_discrete, x: np.ndarray, params: tuple[float, ...]) -> np.ndarray:
    return np.clip(dist.pmf(x, *params), 1e-12, None)


def _mle_shape_1param(
    data: np.ndarray,
    pmf_fn,
    bounds: tuple[float, float],
) -> float | None:
    def nll(theta: float) -> float:
        p = np.clip(pmf_fn(data, theta), 1e-12, None)
        return float(-np.sum(np.log(p)))

    try:
        result = optimize.minimize_scalar(nll, bounds=bounds, method="bounded")
    except Exception:
        return None
    if not result.success:
        return None
    return float(result.x)


def _fit_distributions(block_counts: np.ndarray) -> list[FitResult]:
    x = np.asarray(block_counts, dtype=int)
    if x.size < 10:
        return []

    n = x.size
    mean = x.mean()
    var = x.var(ddof=1) if n > 1 else 0.0
    empirical_k = np.arange(x.min(), x.max() + 1)
    empirical_freq = np.bincount(x - x.min(), minlength=len(empirical_k)).astype(float)
    empirical_freq /= empirical_freq.sum()

    fits_raw: list[dict[str, float | str | dict[str, float]]] = []

    def evaluate(
        name: str,
        mass_at_x: np.ndarray,
        mass_on_k: np.ndarray,
        cdf_callable,
        params: dict[str, float],
        param_count: int,
    ) -> None:
        log_likelihood = float(np.sum(_safe_log(mass_at_x)))
        aic = 2 * param_count - 2 * log_likelihood
        bic = np.log(n) * param_count - 2 * log_likelihood

        try:
            ks = stats.kstest(x, cdf_callable)
            ks_stat, ks_pvalue = float(ks.statistic), float(ks.pvalue)
        except Exception:
            ks_stat, ks_pvalue = np.nan, np.nan

        try:
            cvm = stats.cramervonmises(x, cdf_callable)
            cvm_stat = float(cvm.statistic)
        except Exception:
            cvm_stat = np.nan

        model_freq = np.clip(mass_on_k, 1e-12, None)
        model_freq /= model_freq.sum()
        rmse_freq = float(np.sqrt(np.mean((empirical_freq - model_freq) ** 2)))

        fits_raw.append(
            {
                "name": name,
                "params": params,
                "log_likelihood": log_likelihood,
                "aic": float(aic),
                "bic": float(bic),
                "ks_stat": ks_stat,
                "ks_pvalue": ks_pvalue,
                "cvm_stat": cvm_stat,
                "rmse_freq": rmse_freq,
            }
        )

    # Discrete: Poisson
    if mean > 0:
        p_mass_x = _discrete_mass(stats.poisson, x, (mean,))
        p_mass_k = _discrete_mass(stats.poisson, empirical_k, (mean,))
        evaluate(
            "Poisson",
            p_mass_x,
            p_mass_k,
            lambda v: stats.poisson.cdf(v, mean),
            {"mu": float(mean)},
            1,
        )

    # Discrete: Negative Binomial (method-of-moments, valid for overdispersion)
    if var > mean and mean > 0:
        r = mean * mean / (var - mean)
        p = r / (r + mean)
        nb_mass_x = _discrete_mass(stats.nbinom, x, (r, p))
        nb_mass_k = _discrete_mass(stats.nbinom, empirical_k, (r, p))
        evaluate(
            "Negative Binomial",
            nb_mass_x,
            nb_mass_k,
            lambda v: stats.nbinom.cdf(v, r, p),
            {"n": float(r), "p": float(p)},
            2,
        )

    # Discrete: Geometric (support shifted to start at 1)
    x_geo = x[x >= 1]
    if x_geo.size >= 10:
        p_geo = 1.0 / x_geo.mean()
        p_geo = float(np.clip(p_geo, 1e-6, 1 - 1e-6))
        g_mass_x = _discrete_mass(stats.geom, x, (p_geo,))
        g_mass_k = _discrete_mass(stats.geom, empirical_k, (p_geo,))
        evaluate(
            "Geometric",
            g_mass_x,
            g_mass_k,
            lambda v: stats.geom.cdf(v, p_geo),
            {"p": p_geo},
            1,
        )

    # Discrete heavy-tail families (power-law / long-tail).
    x_pos = x[x >= 1]
    if x_pos.size >= 10:
        p_logser = _mle_shape_1param(
            x_pos,
            lambda vals, p: stats.logser.pmf(vals, p),
            bounds=(1e-6, 1 - 1e-6),
        )
        if p_logser is not None:
            ls_mass_x = _discrete_mass(stats.logser, x, (p_logser,))
            ls_mass_k = _discrete_mass(stats.logser, empirical_k, (p_logser,))
            evaluate(
                "Log-Series",
                ls_mass_x,
                ls_mass_k,
                lambda v: stats.logser.cdf(v, p_logser),
                {"p": p_logser},
                1,
            )

        a_zipf = _mle_shape_1param(
            x_pos,
            lambda vals, a: stats.zipf.pmf(vals, a),
            bounds=(1.01, 8.0),
        )
        if a_zipf is not None:
            z_mass_x = _discrete_mass(stats.zipf, x, (a_zipf,))
            z_mass_k = _discrete_mass(stats.zipf, empirical_k, (a_zipf,))
            evaluate(
                "Zipf (Power-law)",
                z_mass_x,
                z_mass_k,
                lambda v: stats.zipf.cdf(v, a_zipf),
                {"a": a_zipf},
                1,
            )

        rho_yule = _mle_shape_1param(
            x_pos,
            lambda vals, rho: stats.yulesimon.pmf(vals, rho),
            bounds=(0.05, 20.0),
        )
        if rho_yule is not None:
            y_mass_x = _discrete_mass(stats.yulesimon, x, (rho_yule,))
            y_mass_k = _discrete_mass(stats.yulesimon, empirical_k, (rho_yule,))
            evaluate(
                "Yule-Simon",
                y_mass_x,
                y_mass_k,
                lambda v: stats.yulesimon.cdf(v, rho_yule),
                {"rho": rho_yule},
                1,
            )

    # Continuous families converted to per-integer mass.
    continuous_candidates: list[tuple[str, stats.rv_continuous]] = [
        ("Normal", stats.norm),
        ("Lognormal", stats.lognorm),
        ("Gamma", stats.gamma),
        ("Weibull", stats.weibull_min),
        ("Exponential", stats.expon),
    ]
    x_pos = x[x > 0]
    for name, dist in continuous_candidates:
        if x_pos.size < 10:
            continue
        try:
            if name in {"Lognormal", "Gamma", "Weibull", "Exponential"}:
                params_tuple = dist.fit(x_pos, floc=0)
            else:
                params_tuple = dist.fit(x)
            c_mass_x = _continuous_mass(dist, x, params_tuple)
            c_mass_k = _continuous_mass(dist, empirical_k, params_tuple)
            param_names = dist.shapes.split(", ") if dist.shapes else []
            named_params = {
                **{k: float(v) for k, v in zip(param_names, params_tuple[:-2], strict=False)},
                "loc": float(params_tuple[-2]),
                "scale": float(params_tuple[-1]),
            }
            evaluate(
                name,
                c_mass_x,
                c_mass_k,
                lambda v, d=dist, p=params_tuple: d.cdf(v, *p),
                named_params,
                len(params_tuple),
            )
        except Exception:
            continue

    extra_continuous: list[tuple[str, stats.rv_continuous]] = [
        ("Pareto", stats.pareto),
        ("Lomax", stats.lomax),
        ("GenPareto", stats.genpareto),
        ("Log-logistic", stats.fisk),
    ]
    for name, dist in extra_continuous:
        if x_pos.size < 10:
            continue
        try:
            params_tuple = dist.fit(x_pos, floc=0)
            c_mass_x = _continuous_mass(dist, x, params_tuple)
            c_mass_k = _continuous_mass(dist, empirical_k, params_tuple)
            param_names = dist.shapes.split(", ") if dist.shapes else []
            named_params = {
                **{k: float(v) for k, v in zip(param_names, params_tuple[:-2], strict=False)},
                "loc": float(params_tuple[-2]),
                "scale": float(params_tuple[-1]),
            }
            evaluate(
                name,
                c_mass_x,
                c_mass_k,
                lambda v, d=dist, p=params_tuple: d.cdf(v, *p),
                named_params,
                len(params_tuple),
            )
        except Exception:
            continue

    if not fits_raw:
        return []

    rank_columns = ["aic", "bic", "ks_stat", "cvm_stat", "rmse_freq"]
    score_df = pd.DataFrame(fits_raw)
    for col in rank_columns:
        # Percentile rank is robust and comparable across heterogeneous scales.
        score_df[f"rank_{col}"] = score_df[col].rank(method="average", pct=True)
    score_df["composite_rank_score"] = score_df[[f"rank_{c}" for c in rank_columns]].mean(axis=1)
    score_df = score_df.sort_values("composite_rank_score", ascending=True).reset_index(drop=True)

    results: list[FitResult] = []
    for rec in score_df.to_dict(orient="records"):
        results.append(
            FitResult(
                name=str(rec["name"]),
                params=dict(rec["params"]),
                log_likelihood=float(rec["log_likelihood"]),
                aic=float(rec["aic"]),
                bic=float(rec["bic"]),
                ks_stat=float(rec["ks_stat"]),
                ks_pvalue=float(rec["ks_pvalue"]),
                cvm_stat=float(rec["cvm_stat"]),
                rmse_freq=float(rec["rmse_freq"]),
                composite_rank_score=float(rec["composite_rank_score"]),
            )
        )
    return results


def _plot_seasonality_heatmap(ax: Axes, dfi: pd.DataFrame) -> None:
    dow_week = dfi.groupby(["day_of_week", "week_of_year"], as_index=False).size()
    heat = dow_week.pivot(index="day_of_week", columns="week_of_year", values="size").fillna(0)
    heat = heat.reindex(index=np.arange(0, 5), fill_value=0)

    sns.heatmap(
        heat,
        ax=ax,
        cbar=False,
        #cmap="YlOrRd",
        #cbar_kws={"label": "Case arrivals"},
        #linewidths=0.2,
        #linecolor="white",
    )
    ax.set_title(f"Arrivals Heatmap During the Year", fontsize=12, pad=10)
    ax.set_xlabel("Week Number of Year")
    ax.set_ylabel("Day of Week")
    ax.set_yticklabels(
        ["Mon", "Tue", "Wed", "Thu", "Fri"],
        rotation=0,
    )


def _plot_trend(ax: Axes, dfi: pd.DataFrame) -> None:
    monthly = dfi.groupby("year_month", as_index=False).size().rename(columns={"size": "cases"})
    monthly = monthly.sort_values("year_month").reset_index(drop=True)
    monthly["rolling_12m"] = monthly["cases"].rolling(window=12, min_periods=3).mean()

    sns.lineplot(data=monthly, x="year_month", y="cases", ax=ax, label="Monthly cases", linewidth=1.5)
    sns.lineplot(
        data=monthly,
        x="year_month",
        y="rolling_12m",
        ax=ax,
        label="12M rolling mean",
        linewidth=2.2,
        color="black",
    )
    ax.set_title("Historical Development")
    ax.set_xlabel("Month")
    ax.set_ylabel("Cases")
    ax.grid(alpha=0.25)


def _model_mass_on_k(fit: FitResult, k: np.ndarray) -> np.ndarray:
    if fit.name == "Poisson":
        return _discrete_mass(stats.poisson, k, (fit.params["mu"],))
    if fit.name == "Negative Binomial":
        return _discrete_mass(stats.nbinom, k, (fit.params["n"], fit.params["p"]))
    if fit.name == "Geometric":
        return _discrete_mass(stats.geom, k, (fit.params["p"],))
    if fit.name == "Log-Series":
        return _discrete_mass(stats.logser, k, (fit.params["p"],))
    if fit.name == "Zipf (Power-law)":
        return _discrete_mass(stats.zipf, k, (fit.params["a"],))
    if fit.name == "Yule-Simon":
        return _discrete_mass(stats.yulesimon, k, (fit.params["rho"],))

    dist_map: dict[str, stats.rv_continuous] = {
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
    dist = dist_map[fit.name]
    if dist.shapes:
        shape_names = dist.shapes.split(", ")
        shape_vals = tuple(fit.params[name] for name in shape_names)
    else:
        shape_vals = ()
    params = (*shape_vals, fit.params["loc"], fit.params["scale"])
    return _continuous_mass(dist, k, params)


def _fmt_fit_row(idx: int, fit: FitResult) -> str:
    params_txt = ", ".join(f"{k}={v:.4g}" for k, v in fit.params.items())
    return (
        f"{idx}. {fit.name} | AIC={fit.aic:.1f}, BIC={fit.bic:.1f}, "
        f"KS={fit.ks_stat:.3f}, CvM={fit.cvm_stat:.3f}, RMSE={fit.rmse_freq:.4f}\n"
        f"   params: {params_txt}"
    )


def _plot_block_distribution(
    ax: Axes,
    dfi: pd.DataFrame,
    top_fits: list[FitResult],
    top_k: int,
) -> list[str]:
    x = dfi["block_count"].to_numpy(dtype=int)
    bins = np.arange(x.min() - 0.5, x.max() + 1.5, 1)

    sns.histplot(x=x, bins=bins, stat="probability", kde=False, ax=ax, color="#4C78A8", alpha=0.4)

    k = np.arange(x.min(), x.max() + 1)
    for fit in top_fits[:top_k]:
        mass = _model_mass_on_k(fit, k)
        mass = np.clip(mass, 1e-12, None)
        mass /= mass.sum()
        ax.plot(k, mass, marker="o", linewidth=1.8, markersize=3.8, label=fit.name)

    ax.set_title("Block Count Distribution and Best-Fit Models")
    ax.set_xlabel("Block count")
    ax.set_ylabel("Probability")
    ax.grid(alpha=0.2)
    ax.legend(loc="upper right", fontsize=8)

    report_lines = ["Top fits (composite ranking):"]
    for i, fit in enumerate(top_fits[:top_k], start=1):
        report_lines.append(_fmt_fit_row(i, fit))
    return report_lines


def _plot_fit_summary(ax: Axes, lines: list[str]) -> None:
    ax.axis("off")
    ax.text(
        0.01,
        0.98,
        "\n".join(lines),
        transform=ax.transAxes,
        va="top",
        ha="left",
        fontsize=8.5,
        family="monospace",
        bbox={"facecolor": "#F8F8F8", "edgecolor": "#DDDDDD", "boxstyle": "round,pad=0.4"},
    )


def _build_single_page(
    dfi: pd.DataFrame,
    specimen_id: int,
    specimen_name: str, 
    model_registry: dict[str, dict[str, object]],
    top_k: int,
) -> Figure:
    fits = _fit_distributions(dfi["block_count"].to_numpy(dtype=int))

    best_fit = fits[0]
    model_registry[str(specimen_id)]["distribution"] = best_fit.name
    model_registry[str(specimen_id)]["params"] = best_fit.params

    fig = plt.figure(figsize=PAGE_SIZE)
    grid = fig.add_gridspec(nrows=4, ncols=1, height_ratios=[1.0, 1.0, 1.5, 0.9])
    ax_heat = fig.add_subplot(grid[0, 0])
    ax_trend = fig.add_subplot(grid[1, 0])
    ax_block = fig.add_subplot(grid[2, 0])
    ax_fit_text = fig.add_subplot(grid[3, 0])

    _plot_seasonality_heatmap(ax_heat, dfi)
    _plot_trend(ax_trend, dfi)

    if fits:
        lines = _plot_block_distribution(ax_block, dfi, fits, top_k=top_k)
        _plot_fit_summary(ax_fit_text, lines)
    else:
        sns.histplot(data=dfi, x="block_count", bins=20, ax=ax_block, color="#4C78A8", alpha=0.5)
        ax_block.set_title("Block Count Distribution")
        _plot_fit_summary(
            ax_fit_text,
            ["Top fits (composite ranking):", "Insufficient sample size for robust distribution fitting."],
        )

    n_cases = len(dfi)
    fig.suptitle(
        f"{specimen_name} (id: {specimen_id}) | Cases={n_cases}",
        fontsize=13,
        fontweight="bold",
        y=0.995,
    )
    fig.tight_layout(rect=(0.02, 0.02, 0.98, 0.98))
    return fig


def _init_model_registry(df: pd.DataFrame) -> dict[str, dict[str, object]]:
    registry: dict[str, dict[str, object]] = {}
    all_blocks = np.sum(df['block_count'])
    df['block_count_freq'] = df['block_count'] / all_blocks
    for row in df.itertuples(index=False):
        specimen_type = str(row.id)
        registry[specimen_type] = {
            "frequency": row.block_count_freq,
            "name": str(row.specimen_type)
        }
    return registry



def _build_front_page(specimen_types: pd.DataFrame) -> Figure:
    fig = plt.figure(figsize=PAGE_SIZE)
    #grid = fig.add_gridspec(nrows=4, ncols=1, height_ratios=[1.0, 1.0, 1.5, 0.9])
    #ax_heat = fig.add_subplot(grid[0, 0])
    #ax_trend = fig.add_subplot(grid[1, 0])
    #ax_block = fig.add_subplot(grid[2, 0])
    #ax_fit_text = fig.add_subplot(grid[3, 0])
    ax = fig.add_subplot()
    all_blocks = specimen_types['block_count'].sum()
    sizes = specimen_types['block_count'] / all_blocks
    cum_sizes = sizes.to_numpy().astype('float').cumsum()
    label_cutoff = int(np.where(cum_sizes > CUTOFF_LABEL_PCT)[0][0])
    labels = specimen_types['specimen_type']
    trunc_labels = np.concat([labels[:label_cutoff], np.repeat('', len(sizes)-label_cutoff)])
    ax.pie(sizes.to_numpy().astype('float'), labels=trunc_labels, rotatelabels=True)
    fig.suptitle(
        "Specimen Type Analysis",
        fontsize=15,
        fontweight="bold",
    )
    fig.tight_layout(rect=(0.1, 0.1, 0.98, 0.98))
    return fig


def build_report(
    conn: adbc_driver_postgresql.dbapi.Connection,
    specimen_types: pd.DataFrame,
    output: Path,
    min_cases: int,
    top_k_distributions: int,
) -> dict[str, dict[str, object]]:
    sns.set_theme(style="whitegrid", context="notebook")

    model_registry = _init_model_registry(specimen_types)

    
    if specimen_types.empty:
        raise ValueError(
            f"No specimen type meets min-cases={min_cases}. "
            "Lower the threshold or provide more data."
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    with PdfPages(output) as pdf:
        meta = pdf.infodict()
        meta["Title"] = "Specimen Type Analysis"
        meta["Author"] = "specimen_analysis.py"
        meta["CreationDate"] = dt.datetime.now()

        fig = _build_front_page(specimen_types)
        pdf.savefig(fig)
        plt.close(fig)

        total_count = len(specimen_types)
        current_count = 0

        for row in specimen_types.itertuples(index=False):
            current_count += 1
            specimen_name = str(row.specimen_type) + ": " + str(row.specimen_desc)
            specimen_id = int(row.id)
            cases = _load_cases(specimen_id, conn)
            fig = _build_single_page(dfi=cases, specimen_id=specimen_id, specimen_name=specimen_name, model_registry=model_registry, top_k=top_k_distributions)
            pdf.savefig(fig)
            plt.close(fig)
            print(f"Processed {row.specimen_type} ( {current_count} / {total_count}).")

        # TODO: final frequency report

    return model_registry


def write_model_json(model_registry: dict[str, dict[str, object]], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(model_registry, f, indent=2, sort_keys=True)


def main() -> None:
    connection = _connect_to_db()

    try:
        specimen_types = _load_specimen_types(connection)

        # Standardize expected column names used by downstream plotting/report code.
        model_registry = build_report(
            conn=connection,
            specimen_types=specimen_types,
            output=OUTPUT_PDF,
            min_cases=MIN_CASES_PER_SPECIMEN,
            top_k_distributions=TOP_K_DISTRIBUTIONS,
        )
        write_model_json(model_registry=model_registry, output_path=MODEL_JSON)
    finally:
        connection.close()


if __name__ == "__main__":
    main()
