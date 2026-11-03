#!/usr/bin/env bash
# Usage: scripts/sim.sh <testbench_name> [run options, e.g. -gN=20]
# Compiles everything in rtl/ and tb/, then runs one testbench.
set -euo pipefail
shopt -s nullglob
TB="$1"; shift
FLAGS="--std=08 --workdir=build"
mkdir -p build
ghdl -i $FLAGS rtl/*.vhd tb/*.vhd
ghdl -m $FLAGS "$TB"
ghdl -r $FLAGS "$TB" --wave="build/$TB.ghw" --assert-level=error --ieee-asserts=disable "$@"
