# Arrival simulation scripts

Python scripts to simulate future case arrivals, based on historical data:

- `arrivals.py` creates a _case arrival model_ based on historic data
- `specimen_analysis.py` analysis the case' specimen types that exists to create a model (weekly arrival pattern and block distribution)
- `synthetic_arrivals` turn the results from the above scripts into "synthetic cases"

## Setup

### Database connection

`arrivals.py` and `specimen_analysis.py` connect with the standard libpq variables:

```dotenv
PGHOST=localhost
PGPORT=5432
PGUSER=postgres
PGPASSWORD=password
PGDATABASE=unpaidme
```

### With uv (recommended)

Each script declares its Python version and dependencies inline (followin PEP 723).
Our recommended approach is to run them using [uv](https://docs.astral.sh/uv/), which requires no further setup than uv itself.
It install the required Python interpreter together with the dependencies, the firsst time the script is run:

```bash
uv run arrivals.py --help
```

### Without uv (plain venv)

If you do not want to use `uv`, you can use Python with "plain" virtual environments.
We require **Python 3.12** or newer.

```bash
python3.12 -m venv .venv
source .venv/bin/activate          # on Windows: .venv\Scripts\activate
python -m ensurepip
python -m pip install -r requirements.txt
python arrivals.py --help
```

Below, replace `uv run` with `python` when using the venv.


## Usage

The typical usage for this script, would be to first perform an "arrival" analysis, then a "specimen type" analysis,
and finally, combine the results to simulate arrivals of synthetic cases.

```bash
uv run arrivals.py --now 2026-09-01 --horizon 2027-12-31 --split 2025-01-01
uv run specimen_analysis.py
uv run synthetic_arrivals.py 
```

## `arrivals.py`

Fits a negative-binomial GLM to daily histology case arrivals (trend, weekday, yearly Fourier
seasonality, public and school holidays), optionally validates it on train/test splits, and
simulates daily counts from `--now` (inclusive) to `--horizon`.

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `--data FILE` | database | CSV/Parquet/JSON with a `reg_date` column, either one row per case or aggregated with a `cnt` column |
| `--min-date DATE` | first arrival | ignore arrivals before this date |
| `--now DATE` | last arrival (excluded, it may be incomplete) | end of training data and first simulated day |
| `--horizon DATE` | one year after `--now` | last simulated day |
| `--split DATE` | none | validate with a train/test split at this date; repeat for rolling-origin cross-validation |
| `--scenarios` | off | add pessimistic/optimistic columns `cnt_lo` / `cnt_hi` |
| `--interval P` | `0.8` | central probability between `cnt_lo` and `cnt_hi` |
| `--country CODE` | `NO` | ISO country code for public holidays |
| `--school-weeks W,W,…` | `9,25,…,30,41` | ISO weeks with school holidays |
| `--harmonics N` | `10` | number of yearly Fourier terms |
| `--weekends` | off | model and simulate Saturdays and Sundays too |
| `--seed N` | random | random seed for reproducible simulations |
| `--output FILE` | `arrivals.csv` | `.csv` or `.parquet`; columns `reg_date`, `cnt` (+ `cnt_lo`, `cnt_hi`) |
| `--report FILE` | none | write validation and forecast plots to this PDF |

## `specimen_analysis.py`

Per histology specimen type: arrival seasonality heatmap, yearly volume trend, and a fit of the
blocks-per-case distribution against a set of discrete and (discretised) continuous families.
Only specimen types that together account for 99 % of all blocks and have at least `--min-cases`
cases are reported.

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `--metrics M[=W],…` | `aic,bic,ks,cvm,rmse` (equal weights) | goodness-of-fit metrics used to rank fits, with optional weights, e.g. `aic=2,ks`. The best fit has the lowest weighted mean percentile rank |
| `--top-k N` | `3` | number of best fits plotted and tabled per specimen type |
| `--min-cases N` | `30` | skip specimen types with fewer cases |
| `--pseudo-count X` | `250` | weekday shares are shrunk toward the overall share by this many cases' worth; higher means smoother |
| `--output FILE` | `specimen_analysis_report.pdf` | PDF report |
| `--model-json FILE` | `specimen_model.json` | specimen model: per specimen type id, its case share (overall and per ISO weekday) and best-fitting block-count distribution |

## `synthetic_arrivals.py`

Splits each day's simulated arrivals over specimen types using the weekday shares from the
specimen model, and draws each case's block count from its type's fitted distribution (restricted
to the block counts observed for that type). Output columns: `requisition_id`, `reg_date`,
`specimen_type`, `no_blocks`.

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `--arrivals FILE` | `arrivals.csv` | output of `arrivals.py` (`.csv` or `.parquet`) |
| `--model FILE` | `specimen_model.json` | output of `specimen_analysis.py` |
| `--column NAME` | `cnt` | arrival count column: `cnt`, or `cnt_lo` / `cnt_hi` for scenarios |
| `--seed N` | random | random seed |
| `--output FILE` | `synthetic_arrivals.csv` | `.csv` or `.parquet` |

## TODOs

- [ ] presentation and layout in the `specimen_types.pdf` report can be improved
- [ ] use the linear regression model per specimen type to incorporate that trend into the arrival generator
- [ ] alternatively use KDE for fitting the "block distribution model" per specimen type
- [ ] include prophet as an option for the arrival-generator (find out whehter there are feature flags in python because the dependency is heavy)
