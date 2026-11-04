#!/usr/bin/env python3
"""Sweep Dynamatic's buffer-placement algorithms over the same input mixes.

For each (algorithm, positive-share) pair: regenerate the kernel, compile,
write VHDL, simulate with GHDL, and record cycles plus area metrics.

Needs a local Dynamatic build. Point DYNAMATIC_DIR at it, e.g.
    DYNAMATIC_DIR=~/dynamatic-ws/dynamatic python3 scripts/dynamatic_buffer_sweep.py
"""
import csv
import os
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DYN = Path(os.environ.get("DYNAMATIC_DIR",
                          Path.home() / "dynamatic-ws" / "dynamatic"))
KDIR = DYN / "integration-test/elasticflow"
OUT = KDIR / "out"
ALGOS = ["on-merges", "fpga20", "fpl22"]
POS = [0, 10, 25, 50, 75, 90, 100]

KERNEL_C = r'''#include "elasticflow.h"
#include "dynamatic/Integration.h"

int elasticflow(in_int_t x[N]) {
  int s = 1;
  for (int i = 0; i < N; i++) {
    if (x[i] > 0)
      s = s * x[i];
    else
      s = s + x[i];
  }
  return s;
}

int main(void) {
  in_int_t x[N];
  unsigned seed = 1u;
  for (int j = 0; j < N; ++j) {
    seed = seed * 1103515245u + 12345u;
    unsigned pick = (seed >> 16) % 100u;
    seed = seed * 1103515245u + 12345u;
    if (pick < (unsigned)POS_PERCENT)
      x[j] = 1 + (int)((seed >> 16) % 3u);
    else
      x[j] = -(int)((seed >> 16) % 4u);
  }
  CALL_KERNEL(elasticflow, x);
  return 0;
}
'''


def write_kernel(pos):
    (KDIR / "elasticflow.h").write_text(
        "#ifndef ELASTICFLOW_ELASTICFLOW_H\n#define ELASTICFLOW_ELASTICFLOW_H\n"
        f"#define N 64\n#define POS_PERCENT {pos}\n"
        "typedef int in_int_t;\nint elasticflow(in_int_t x[N]);\n#endif\n")
    (KDIR / "elasticflow.c").write_text(KERNEL_C)


def run_flow(algo):
    cmds = ("set-src integration-test/elasticflow/elasticflow.c\n"
            f"compile --buffer-algorithm {algo} --milp-solver cbc\n"
            "write-hdl --hdl vhdl\nsimulate --simulator ghdl\nexit\n")
    subprocess.run([str(DYN / "bin/dynamatic")], input=cmds, text=True,
                   cwd=DYN, capture_output=True)


def area_metrics():
    """Buffer instances, total slots and type breakdown from the generated VHDL."""
    top = (OUT / "hdl/elasticflow.vhd").read_text()
    insts = Counter(re.findall(r"handshake_buffer_\d+", top))
    slots = kinds = 0
    breakdown = Counter()
    for name, count in insts.items():
        head = (OUT / f"hdl/{name}.vhd").read_text().split("\n", 1)[0]
        n = int(re.search(r"'num_slots': (\d+)", head).group(1))
        t = re.search(r"'buffer_type': '([A-Z_]+)'", head).group(1)
        slots += n * count
        breakdown[t] += count
        kinds += 1
    dot = (OUT / "comp/elasticflow.dot").read_text()
    components = len(re.findall(r'"mlir_op"="handshake\.', dot)) \
        - len(re.findall(r'"mlir_op"="handshake\.func"', dot))
    return sum(insts.values()), slots, kinds, breakdown, components


def main():
    if not (DYN / "bin/dynamatic").exists():
        sys.exit(f"Could not find a Dynamatic build at: {DYN}\n"
                 "Set DYNAMATIC_DIR to your Dynamatic checkout.")
    KDIR.mkdir(parents=True, exist_ok=True)
    rows = []
    for algo in ALGOS:
        for pos in POS:
            write_kernel(pos)
            run_flow(algo)
            report = (OUT / "sim/report.txt").read_text()
            cycles = int(re.findall(r"Latency = (\d+) cycles", report)[-1])
            ok = "C and VHDL outputs match" in report
            nbuf, slots, kinds, bd, comps = area_metrics()
            rows.append(dict(algorithm=algo, pos_percent=pos, cycles=cycles,
                             verified="PASS" if ok else "FAIL",
                             buffers=nbuf, buffer_slots=slots,
                             opaque=bd.get("ONE_SLOT_BREAK_DV", 0),
                             transparent=bd.get("ONE_SLOT_BREAK_R", 0),
                             fifo=bd.get("FIFO_BREAK_NONE", 0),
                             components=comps))
            print(f"{algo:>10} pos={pos:>3} cycles={cycles:>4} "
                  f"buffers={nbuf:>2} slots={slots:>2} comps={comps:>2} "
                  f"{'PASS' if ok else 'FAIL'}", flush=True)

    dest = REPO / "results" / "buffer_algorithms.csv"
    with dest.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"\nwrote {dest}")


if __name__ == "__main__":
    main()
