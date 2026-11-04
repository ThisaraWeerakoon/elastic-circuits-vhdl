#!/usr/bin/env python3
"""Cycles and buffer cost for Dynamatic's buffer-placement algorithms."""
import csv
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Categorical slots 1-3 of the validated reference palette (light mode).
# fpga20 keeps the orange it has in docs/dynamatic_comparison.md.
COLOR = {"on-merges": "#2a78d6", "fpga20": "#eb6834", "fpl22": "#1baf7a"}
ORDER = ["on-merges", "fpga20", "fpl22"]
INK, INK_2, SURFACE = "#0b0b0b", "#52514e", "#fcfcfb"

rows = list(csv.DictReader(open("results/buffer_algorithms.csv")))
cyc = defaultdict(dict)
bufs = {}
for r in rows:
    cyc[r["algorithm"]][int(r["pos_percent"])] = int(r["cycles"])
    bufs[r["algorithm"]] = int(r["buffers"])

fig, (ax, bx) = plt.subplots(1, 2, figsize=(11, 4.4),
                             gridspec_kw={"width_ratios": [2.1, 1]})
fig.patch.set_facecolor(SURFACE)

# --- Left: cycles vs input mix -------------------------------------------
ax.set_facecolor(SURFACE)
for algo in ORDER:
    xs = sorted(cyc[algo])
    ys = [cyc[algo][x] for x in xs]
    ax.plot(xs, ys, color=COLOR[algo], linewidth=2, marker="o", markersize=5,
            markeredgecolor=SURFACE, markeredgewidth=1.5, label=algo, zorder=3)
    ax.annotate(algo, xy=(xs[-1], ys[-1]), xytext=(6, 0),
                textcoords="offset points", va="center",
                fontsize=9, color=INK_2)
ax.set_xlabel("Positive x values (%) — how often the multiply path runs",
              fontsize=9.5, color=INK_2)
ax.set_ylabel("Cycles to finish (N = 64)", fontsize=9.5, color=INK_2)
ax.set_title("Cycles", fontsize=11, color=INK, pad=10, loc="left")
ax.set_xlim(-3, 126)
ax.set_ylim(0, 410)
ax.legend(frameon=False, fontsize=9, labelcolor=INK_2, loc="upper left")

# --- Right: buffer cost ---------------------------------------------------
bx.set_facecolor(SURFACE)
vals = [bufs[a] for a in ORDER]
bars = bx.bar(ORDER, vals, color=[COLOR[a] for a in ORDER], width=0.6, zorder=3)
for bar, v in zip(bars, vals):
    bx.annotate(str(v), xy=(bar.get_x() + bar.get_width() / 2, v),
                xytext=(0, 4), textcoords="offset points",
                ha="center", fontsize=10, color=INK_2)
bx.set_ylabel("Buffers placed", fontsize=9.5, color=INK_2)
bx.set_title("Buffer cost", fontsize=11, color=INK, pad=10, loc="left")
bx.set_ylim(0, 18)

for a in (ax, bx):
    a.grid(True, axis="y", color="#0b0b0b", alpha=0.07, linewidth=0.8)
    a.set_axisbelow(True)
    for side in ("top", "right"):
        a.spines[side].set_visible(False)
    for side in ("left", "bottom"):
        a.spines[side].set_color("#d6d5d0")
    a.tick_params(colors=INK_2, labelsize=9)

fig.suptitle("Dynamatic buffer-placement algorithms on the same kernel",
             fontsize=12.5, color=INK, x=0.012, ha="left", y=0.98)
fig.tight_layout(rect=[0, 0, 1, 0.94])
fig.savefig("results/buffer_algorithms.png", dpi=160, facecolor=SURFACE)
print("wrote results/buffer_algorithms.png")
