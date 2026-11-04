#!/usr/bin/env bash
# Sweep Dynamatic's generated circuit over the same input mixes as scripts/sweep.py.
#
# Needs a local Dynamatic build. Point DYNAMATIC_DIR at it, e.g.
#   DYNAMATIC_DIR=~/dynamatic-ws/dynamatic bash scripts/dynamatic_sweep.sh
set -u

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DYN=${DYNAMATIC_DIR:-$HOME/dynamatic-ws/dynamatic}

if [[ ! -x "$DYN/bin/dynamatic" ]]; then
  echo "Could not find a Dynamatic build at: $DYN" >&2
  echo "Set DYNAMATIC_DIR to your Dynamatic checkout." >&2
  exit 1
fi

KDIR=$DYN/integration-test/elasticflow
LOGS=$REPO/build/dynamatic-logs
OUT=$REPO/results/dynamatic/dynamatic_sweep_raw.csv
mkdir -p "$KDIR" "$LOGS" "$(dirname "$OUT")"

echo "pos_percent,cycles,result_hex,match" > "$OUT"

for POS in 0 10 25 50 75 90 100; do
  # N and the positive share for this run
  cat > "$KDIR/elasticflow.h" <<EOF
#ifndef ELASTICFLOW_ELASTICFLOW_H
#define ELASTICFLOW_ELASTICFLOW_H
#define N 64
#define POS_PERCENT $POS
typedef int in_int_t;
int elasticflow(in_int_t x[N]);
#endif // ELASTICFLOW_ELASTICFLOW_H
EOF

  # The kernel, plus a deterministic input generator matching tb_kernel's
  # distribution: positive values in {1,2,3}, non-positive in {0,-1,-2,-3}.
  cat > "$KDIR/elasticflow.c" <<'EOF'
#include "elasticflow.h"
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
EOF

  ( cd "$DYN" && printf '%s\n' \
      "set-src integration-test/elasticflow/elasticflow.c" \
      "compile --buffer-algorithm fpga20 --milp-solver cbc" \
      "write-hdl --hdl vhdl" \
      "simulate --simulator ghdl" \
      "exit" | ./bin/dynamatic ) > "$LOGS/run_$POS.log" 2>&1

  REP="$KDIR/out/sim/report.txt"
  CYC=$(grep -oP 'Latency = \K[0-9]+' "$REP" 2>/dev/null | tail -1)
  MATCH=$(grep -q "C and VHDL outputs match" "$REP" 2>/dev/null && echo PASS || echo FAIL)
  HEX=$(sed -n '3p' "$KDIR/out/sim/HDL_OUT/output_out0.dat" 2>/dev/null | tr -d ' ')

  echo "pos=$POS cycles=${CYC:-ERR} match=$MATCH hex=${HEX:-?}"
  echo "$POS,${CYC:-},${HEX:-},$MATCH" >> "$OUT"
done

echo
echo "wrote $OUT"
