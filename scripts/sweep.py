#!/usr/bin/env python3
"""Run tb_kernel for both kernels over a range of input mixes; save a CSV and a plot."""
import argparse
import csv
import re
import statistics
import subprocess

import matplotlib
matplotlib.use("Agg")            # write PNG files without opening a window
import matplotlib.pyplot as plt

SEEDS = [1, 2, 3, 4, 5]
POS_PERCENTS = [0, 10, 25, 50, 75, 90, 100]
PATTERN = re.compile(r"RESULT kernel=(\w+) n=(\d+) pos=(\d+) cycles=(\d+)")


def run(kernel, pos, seed, opts):
    """Run one simulation and return its cycle count."""
    out = subprocess.run(
        ["scripts/sim.sh", "tb_kernel", f"-gKERNEL={kernel}", f"-gN={opts.n}",
         f"-gPOS_PERCENT={pos}", f"-gSEED={seed}",
         f"-gMUL_LATENCY={opts.mul_latency}", f"-gX_PERCENT={opts.x_percent}"],
        capture_output=True, text=True, check=True).stdout
    match = PATTERN.search(out)
    if match is None:
        raise RuntimeError(f"no RESULT line for {kernel} pos={pos} seed={seed}:\n{out}")
    return int(match.group(4))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--n", type=int, default=64, help="loop trip count")
    parser.add_argument("--mul-latency", type=int, default=4, help="multiplier pipeline depth")
    parser.add_argument("--x-percent", type=int, default=100,
                        help="chance the x source offers a value each cycle")
    parser.add_argument("--name", default="sweep", help="base name for the output files")
    opts = parser.parse_args()

    rows = []
    for pos in POS_PERCENTS:
        for kernel in ["dynamic", "static"]:
            cycles = [run(kernel, pos, seed, opts) for seed in SEEDS]
            rows.append({"kernel": kernel, "pos_percent": pos,
                         "mean_cycles": statistics.mean(cycles)})
            print(rows[-1])

    csv_path = f"results/{opts.name}.csv"
    png_path = f"results/{opts.name}.png"
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["kernel", "pos_percent", "mean_cycles"])
        writer.writeheader()
        writer.writerows(rows)

    fig, ax = plt.subplots(figsize=(6, 4))
    for kernel in ["static", "dynamic"]:
        xs = [r["pos_percent"] for r in rows if r["kernel"] == kernel]
        ys = [r["mean_cycles"] for r in rows if r["kernel"] == kernel]
        ax.plot(xs, ys, marker="o", label=kernel)
    ax.set_xlabel("Positive x values (%), i.e. how often the multiply path runs")
    ax.set_ylabel(f"Cycles for N = {opts.n} (mean of {len(SEEDS)} seeds)")
    ax.set_title(f"mul latency {opts.mul_latency}, x offered {opts.x_percent}% of cycles")
    ax.legend()
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(png_path, dpi=150)
    print(f"wrote {csv_path} and {png_path}")


if __name__ == "__main__":
    main()
