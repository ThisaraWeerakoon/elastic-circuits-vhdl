#!/usr/bin/env python3
"""Overlay cycle counts: hand-built dynamic vs Dynamatic-generated vs hand-built static."""
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Categorical slots 1-3 of the validated reference palette (light mode).
BLUE, ORANGE, AQUA = "#2a78d6", "#eb6834", "#1baf7a"
INK, INK_2, SURFACE = "#0b0b0b", "#52514e", "#fcfcfb"

rows = list(csv.DictReader(open("results/dynamatic_comparison.csv")))
xs = [int(r["pos_percent"]) for r in rows]
# (label, values, color, line style, direct-label anchor index, y-offset in points)
series = [
    ("Hand-built (dynamic)", [float(r["hand_dynamic"]) for r in rows], BLUE,   "-",  -1, -11),
    ("Dynamatic",            [float(r["dynamatic"])    for r in rows], ORANGE, "-",  -1,   7),
    ("Hand-built (static)",  [float(r["hand_static"])  for r in rows], AQUA,   "-",   2,  10),
    # Ends 2 cycles below Dynamatic, so the two labels are pushed apart.
    ("Hand-built, buffer moved",
     [float(r["hand_dynamic_add_buffer1"]) for r in rows],             BLUE,   "--", -1,  -8),
]

fig, ax = plt.subplots(figsize=(7.2, 4.6))
fig.patch.set_facecolor(SURFACE)
ax.set_facecolor(SURFACE)

for label, ys, color, style, idx, dy in series:
    ax.plot(xs, ys, color=color, linewidth=2, linestyle=style, marker="o", markersize=5,
            markeredgecolor=SURFACE, markeredgewidth=1.5, label=label, zorder=3)
    # Direct label (relief rule: identity never color-alone). Anchors are
    # staggered because the two hand-built series meet at 321 cycles.
    ha = "left" if idx == -1 else "center"
    ax.annotate(label, xy=(xs[idx], ys[idx]), xytext=(6 if idx == -1 else 0, dy),
                textcoords="offset points", va="center", ha=ha,
                fontsize=9, color=INK_2)

# Crossover marker: where Dynamatic overtakes the hand-built circuit.
ax.axvspan(50, 75, color="#0b0b0b", alpha=0.04, zorder=0)
ax.annotate("solid curves cross here", xy=(62.5, 30), ha="center", fontsize=8.5,
            color=INK_2, style="italic")

ax.set_xlabel("Positive x values (%) — how often the slow multiply path runs",
              fontsize=9.5, color=INK_2)
ax.set_ylabel("Cycles to finish (N = 64)", fontsize=9.5, color=INK_2)
ax.set_title("Hand-built dataflow circuit vs. Dynamatic-generated circuit",
             fontsize=12, color=INK, pad=12, loc="left")

ax.grid(True, color="#0b0b0b", alpha=0.07, linewidth=0.8)
ax.set_axisbelow(True)
for side in ("top", "right"):
    ax.spines[side].set_visible(False)
for side in ("left", "bottom"):
    ax.spines[side].set_color("#d6d5d0")
ax.tick_params(colors=INK_2, labelsize=9)
ax.set_xlim(-3, 133)
ax.set_ylim(0, 345)
ax.legend(frameon=False, fontsize=9, labelcolor=INK_2,
          loc="lower right", bbox_to_anchor=(1.0, 0.08), handlelength=3)

fig.tight_layout()
fig.savefig("results/dynamatic_comparison.png", dpi=160, facecolor=SURFACE)
print("wrote results/dynamatic_comparison.png")
