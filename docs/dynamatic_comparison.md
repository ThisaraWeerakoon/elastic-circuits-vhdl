# My circuit vs the one Dynamatic generates

Same C kernel, compiled two ways: by hand into `rtl/kernel_dynamic.vhd`, and by
[Dynamatic](https://github.com/EPFL-LAP/dynamatic) v2.0.0.

```c
int kernel(int x[N]) {
  int s = 1;
  for (int i = 0; i < N; i++) {
    if (x[i] > 0) s = s * x[i];
    else          s = s + x[i];
  }
  return s;
}
```

Both use `N = 64`. Dynamatic's timing database picks latency 4 for a 32-bit
multiply, which happens to be the same as this project's `MUL_LATENCY` default,
so the arithmetic is not what differs between them.

## Setting up the Dynamatic side

Dynamatic has no prebuilt binary and the Dockerfile only installs dependencies,
so it has to be built. The LLVM part can be downloaded instead of compiled,
which makes it much lighter than it first looks:

```bash
sudo apt-get install -y clang lld ccache cmake ninja-build python3 graphviz \
                        git curl gzip libreadline-dev libboost-all-dev
git clone --recurse-submodules https://github.com/EPFL-LAP/dynamatic.git
cd dynamatic && ./build.sh --release --use-prebuilt-llvm --enable-cbc
```

`--enable-cbc` builds the CBC solver, which the buffer placement MILP needs.
Gurobi is the default and is better supported, but it needs a licence.

On Ubuntu 24.04 the HDL generation step fails with `status 32512` because
Dynamatic calls `python` and the distro only ships `python3`. `sudo apt install
python-is-python3` fixes it.

Then, from the Dynamatic directory:

```
dynamatic> set-src integration-test/elasticflow/elasticflow.c
dynamatic> compile --buffer-algorithm fpga20 --milp-solver cbc
dynamatic> write-hdl --hdl vhdl
dynamatic> simulate --simulator ghdl
```

The kernel in Dynamatic's integration-test format is in
[`../results/dynamatic/`](../results/dynamatic/) along with everything it
generated.

## Cycle counts

![cycles](../results/dynamatic_comparison.png)

| Positive x (%) | Hand-built | Dynamatic | Hand-built static | Hand-built, buffer moved |
|---:|---:|---:|---:|---:|
| 0   | 65.0  | 131 | 321 | 65.0  |
| 10  | 95.4  | 141 | 321 | 87.8  |
| 25  | 129.8 | 155 | 321 | 113.6 |
| 50  | 185.8 | 191 | 321 | 155.6 |
| 75  | 261.8 | 221 | 321 | 212.6 |
| 90  | 301.0 | 245 | 321 | 242.0 |
| 100 | 321.0 | 259 | 321 | 257.0 |

The first two curves cross at somewhere around 55 to 60 percent positive
inputs, so neither of those circuits is better everywhere. The last column is
my circuit with one buffer moved, which came out of working out why. It is
explained below.

Per-iteration initiation interval, which is where the whole difference lives:

| Path taken | Hand-built | Dynamatic | Hand-built, buffer moved |
|---|---:|---:|---:|
| `s + x[i]` (fast) | 1 | 2 | 1 |
| `s * x[i]` (slow) | 5 | 4 | 4 |

These are not fitted. `cycles = 64 × II + c` reproduces every measurement
exactly, with `c = 1` for mine and `c = 3` for Dynamatic's.

### Where the difference comes from: one buffer on the `s` loop

An earlier version of this writeup said my circuit wins on the fast path
"mostly because of the interface", meaning the load Dynamatic puts inside the
loop. That was wrong. Both differences, the fast path and the slow path, come
from where each circuit puts its opaque buffer on the `s` recurrence.

The `s` loop needs at least one opaque buffer (`oehb`, Dynamatic's
`ONE_SLOT_BREAK_DV`) or its valid path is a combinational loop. Each one on the
loop adds a cycle to it, and with one `s` token in flight the II of a path is
just the latency around it. Transparent buffers (`tehb`, `ONE_SLOT_BREAK_R`)
cut the ready path and add no latency.

I put mine at the loop header, right after `merge_s`, where both paths share it:

```
merge_s → oehb (+1) → tehb → cond_br ─┬→ mul (+4) ─┬→ merge → merge_s      mul: 1 + 4 = 5
                                      └→ add (+0) ─┘                        add: 1 + 0 = 1
```

Dynamatic put none on the shared part and two on the add branch only
(names from `handshake_buffered.mlir`):

```
mux1 → buffer2 (R) → fork2 ─┬→ muli0 (+4) ──────────────────────────────┬→ select0 → cond_br1 → mux1
                            └→ buffer3 (DV, +1) → addi0 → buffer8 (DV, +1) ┘
                                                                       mul: 4    add: 2
```

The multiplier's pipeline registers already cut the valid path of the multiply
loop, so that loop does not need an opaque buffer of its own. Only the adder,
which is combinational, does. My header buffer is there for the add path, and
it charges the multiply path a cycle it does not need. The MILP did not make
that mistake.

### Checking it by moving my buffer

`kernel_dynamic` now has an `ADD_BUFFERS` generic. `0` is the original
placement. `k > 0` removes the header `oehb` and puts `k` of them on the add
branch only. The `tehb` stays at the header because my `mul`'s `ready` is
combinational.

| | Header (original) | 1 on add branch | 2 on add branch | Dynamatic |
|---|---:|---:|---:|---:|
| II fast / slow | 1 / 5 | 1 / 4 | 2 / 4 | 2 / 4 |
| Cycles at 0% positive | 65 | 65 | 129 | 131 |
| Cycles at 100% positive | 321 | 257 | 257 | 259 |

Every run passes `tb_kernel`, which checks the result against the reference
model and runs the protocol checker on the result channel. The default
reproduces `results/sweep.csv` exactly. Full sweeps are in
[`../results/sweep_add_buffer1.csv`](../results/sweep_add_buffer1.csv) and
[`../results/sweep_add_buffer2.csv`](../results/sweep_add_buffer2.csv).

Three things follow from this.

- **Two buffers on the add branch reproduce Dynamatic's IIs exactly, with my
  streamed input.** What is left is a constant 2 cycles (`c = 1` against
  `c = 3`), not a cycle per iteration. So the memory interface costs about 2
  cycles of latency in total here, and the fast-path gap is buffer placement.
  The middle data points differ by more than 2 because each Dynamatic point is
  one dataset and mine are means of 5 seeds, so those are not like-for-like.
- **One buffer on the add branch gives II 1 and 4, which is at or below both
  original circuits at every input mix.** That buffer goes where it is needed
  rather than where it is convenient, and that alone was enough.
- **This is still the result I found most useful, for a slightly different
  reason than I first thought.** The MILP did not find a circuit I could not
  build. It found the right place for a buffer that I had put in the obvious
  place without checking what each loop already had. Doing that across every
  loop in a larger circuit by hand is exactly what I would get wrong.

What I cannot tell is why the MILP put two buffers on the add path rather than
one. The `i` counter loop in Dynamatic's circuit also has two opaque buffers
(`buffer0`, `buffer9`), so it also sits at II 2, and a faster add path would
gain nothing while that loop holds at 2. Timing does not look like the reason,
because the worst data path `fpga20` models is 2.718 ns against a 4 ns target
(see [`buffer_algorithms.md`](buffer_algorithms.md)). See
[open question 3](open-questions.md).

## Structure

| | Hand-built | Dynamatic |
|---|---|---|
| Component instances | 30 | 45 |
| Input `x` | streamed in through a handshake port | BRAM + `mem_controller` + `load` |
| Branch | `cond_br` → `mul`/`add` → `merge` | if-converted to `select` |
| Loop header | 2 × `merge` | 2 × `mux` + 1 × `control_merge` |
| Buffers | 2 hand-placed `oehb`+`tehb` pairs (default) | 11, placed by a MILP |
| Index arithmetic | 32-bit throughout | narrowed to 6 and 7 bits |

Two things Dynamatic does that I did not think to do: it narrows bitwidths, so
the loop counter becomes 6 or 7 bits instead of 32, and it emits a real memory
subsystem instead of assuming someone will hand it a stream.

Its buffers turned out to be the same two primitives I had built.
`ONE_SLOT_BREAK_DV` is an opaque buffer, which is my `oehb.vhd`, and
`ONE_SLOT_BREAK_R` is a transparent one, which is my `tehb.vhd`. That was a
good moment.

The loop header difference is a real limitation on my side rather than a style
choice. `merge` is only safe here because at most one token is in flight.
Dynamatic uses muxes because they stay correct when several iterations overlap.

## The branch disappears before Dynamatic sees it

LLVM if-converts the `if`/`else`. In `clang.opt.ll` the two blocks are gone and
there is a single `select`:

```llvm
%6 = icmp sgt i32 %5, 0
%7 = mul nsw i32 %.012, %5
%8 = add nsw i32 %.012, %5
%.1 = select i1 %6, i32 %7, i32 %8
```

Both operations are issued every iteration. The generated dataflow graph
confirms it: the whole loop body is one basic block with `muli0` and `addi0`
both feeding `select0`.

I expected this to flatten the cycle count to match the static version. It does
not, and the measurements above vary with the input data, so the circuit is
clearly still behaving dynamically.

The generated select carries `antitoken_depth = 1`, and the comment in
Dynamatic's select generator describes it as firing on the chosen input while
recording that it owes a kill for the token that has not arrived yet. That
would account for what I measured.

I want to be careful here though. That explanation comes from a source comment
and from the fact that the numbers move with the data. I have not traced the
protocol in a waveform and I cannot explain the details of how the kill
propagates. It is the part of this project I understand least.

## What this comparison does not settle

- The memory interface difference. Moving my buffer shows it is not what
  separates the IIs, and it accounts for a constant 2 cycles. I still have not
  given my circuit a real memory interface, so whether it would cost more with
  several iterations in flight is not settled.
- No synthesis, so no clock period and no area. Cycles are half of runtime.
- The hand-built numbers are means over 5 seeds. Each Dynamatic point is one
  deterministic dataset, recompiled from scratch, because `fpga20` places
  buffers from a profile of the input data.

Every Dynamatic data point was checked against the C reference by its own GHDL
testbench, and all seven reported `C and VHDL outputs match`.

## Reproducing

```bash
export DYNAMATIC_DIR=~/dynamatic-ws/dynamatic   # your Dynamatic build
bash scripts/dynamatic_sweep.sh
python3 scripts/sweep.py --n 64 --mul-latency 4
python3 scripts/sweep.py --n 64 --add-buffers 1 --name sweep_add_buffer1
python3 scripts/sweep.py --n 64 --add-buffers 2 --name sweep_add_buffer2
python3 scripts/plot_dynamatic_comparison.py
```
