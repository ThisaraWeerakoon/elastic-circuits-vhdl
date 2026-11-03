#!/usr/bin/env bash
# Runs every tb/tb_*.vhd testbench. Exits non-zero on the first failure.
set -euo pipefail
for f in tb/tb_*.vhd; do
  name=$(basename "$f" .vhd)
  echo "=== $name ==="
  scripts/sim.sh "$name"
done
echo "=== tb_kernel (static) ==="
scripts/sim.sh tb_kernel -gKERNEL=static
echo "ALL TESTS PASSED"
