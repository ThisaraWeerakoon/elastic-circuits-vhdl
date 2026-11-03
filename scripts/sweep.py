#!/usr/bin/env python3
"""Run tb_kernel for both kernels over a range of input mixes; save a CSV and a plot."""
import csv
import re
import statistics
import subprocess

import matplotlib
matplotlib.use("Agg")            # write PNG files without opening a window
import matplotlib.pyplot as plt

N = 64
SEEDS = [1, 2, 3, 4, 5]
POS_PERCENTS = [0, 10, 25, 50, 75, 90, 100]
PATTERN = re.compile(r"RESULT kernel=(\w+) n=(\d+) pos=(\d+) cycles=(\d+)")


def run(kernel, pos, seed):
    """Run one simulation and return its cycle count."""
    out = subprocess.run(
        ["scripts/sim.sh", "tb_kernel", f"-gKERNEL={kernel}", f"-gN={N}",
         f"-gPOS_PERCENT={pos}", f"-gSEED={seed}"],
        capture_output=True, text=True, check=True).stdout
    match = PATTERN.search(out)
    if match is None:
        raise RuntimeError(f"no RESULT line for {kernel} pos={pos} seed={seed}:\n{out}")
    return int(match.group(4))


rows = []
for pos in POS_PERCENTS:
    for kernel in ["dynamic", "static"]:
        cycles = [run(kernel, pos, seed) for seed in SEEDS]
        rows.append({"kernel": kernel, "pos_percent": pos,
                     "mean_cycles": statistics.mean(cycles)})
        print(rows[-1])

with open("results/sweep.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["kernel", "pos_percent", "mean_cycles"])
    writer.writeheader()
    writer.writerows(rows)

fig, ax = plt.subplots(figsize=(6, 4))
for kernel in ["static", "dynamic"]:
    xs = [r["pos_percent"] for r in rows if r["kernel"] == kernel]
    ys = [r["mean_cycles"] for r in rows if r["kernel"] == kernel]
    ax.plot(xs, ys, marker="o", label=kernel)
ax.set_xlabel("Positive x values (%), i.e. how often the multiply path runs")
ax.set_ylabel(f"Cycles for N = {N} (mean of {len(SEEDS)} seeds)")
ax.set_title("The dynamic kernel adapts to the data")
ax.legend()
ax.grid(alpha=0.3)
fig.tight_layout()
fig.savefig("results/cycles_vs_pos.png", dpi=150)
print("wrote results/sweep.csv and results/cycles_vs_pos.png")
