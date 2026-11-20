# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "numpy",
#     "pandas",
#     "pyarrow",
#     "scipy",
# ]
# ///
"""Synthetic arrivals: combines a daily arrival count series (arrivals.py) with the specimen type
model (model.json from specimen_analysis.py) into one row per synthetic case:
requisition_id, reg_date, specimen_type, no_blocks.

Each day's arrivals are split over specimen types by the weekday shares in the model, and each
case draws its block count from its specimen type's fitted distribution, restricted to the
block counts observed for that type.

    uv run synthetic_arrivals.py --arrivals arrivals.csv --model model.json --column cnt_hi --seed 1
"""

from __future__ import annotations

import argparse
import json
import uuid
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats


def block_mass(entry: dict) -> tuple[np.ndarray, np.ndarray]:
    """Block counts in the observed support and their probabilities under the fitted distribution."""
    dist = getattr(stats, entry["scipy"])(**entry["params"])
    k = np.arange(entry["support"][0], entry["support"][1] + 1)
    mass = dist.pmf(k) if isinstance(dist.dist, stats.rv_discrete) else dist.cdf(k + 0.5) - dist.cdf(k - 0.5)
    return k, mass / mass.sum()


def synthesize(arrivals: pd.DataFrame, column: str, model: dict, rng: np.random.Generator) -> pd.DataFrame:
    types = list(model)
    overall = np.array([model[t]["frequency"] for t in types])
    by_dow = {d: np.array([model[t]["dow_frequency"][str(d)] for t in types]) for d in range(1, 6)}

    dates, type_idx = [], []
    for day, n in zip(pd.to_datetime(arrivals.reg_date), arrivals[column].astype(int)):
        p = by_dow.get(day.isoweekday(), overall)  # weekends fall back to the overall mix
        counts = rng.multinomial(n, p / p.sum())
        dates.append(np.repeat(day.date(), counts.sum()))
        type_idx.append(np.repeat(np.arange(len(types)), counts))
    out = pd.DataFrame({"reg_date": np.concatenate(dates), "specimen_type": np.concatenate(type_idx)})

    out["no_blocks"] = 0
    for i, t in enumerate(types):
        rows = out.specimen_type == i
        k, mass = block_mass(model[t])
        out.loc[rows, "no_blocks"] = rng.choice(k, size=rows.sum(), p=mass)
    out["specimen_type"] = np.array([int(t) for t in types])[out.specimen_type]
    out.insert(0, "requisition_id", [str(uuid.UUID(bytes=rng.bytes(16), version=4)) for _ in range(len(out))])
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--arrivals", type=Path, default=Path("arrivals.csv"), help="output of arrivals.py")
    parser.add_argument("--model", type=Path, default=Path("model.json"), help="output of specimen_analysis.py")
    parser.add_argument("--column", default="cnt", help="arrival count column: cnt, or cnt_lo/cnt_hi for scenarios")
    parser.add_argument("--seed", type=int)
    parser.add_argument("--output", type=Path, default=Path("synthetic_arrivals.csv"), help=".csv or .parquet")
    args = parser.parse_args()

    read = pd.read_parquet if args.arrivals.suffix.lower() == ".parquet" else pd.read_csv
    arrivals = read(args.arrivals)
    if args.column not in arrivals:
        parser.error(f"{args.arrivals} has no column {args.column!r}, only {', '.join(arrivals.columns)}")
    model = json.loads(args.model.read_text(encoding="utf-8"))

    out = synthesize(arrivals, args.column, model, np.random.default_rng(args.seed))
    if args.output.suffix.lower() == ".parquet":
        out.to_parquet(args.output, index=False)
    else:
        out.to_csv(args.output, index=False)
    print(f"Wrote {len(out):,} synthetic cases with {out.no_blocks.sum():,} blocks, "
          f"{out.reg_date.min()} to {out.reg_date.max()} -> {args.output}")


if __name__ == "__main__":
    main()
