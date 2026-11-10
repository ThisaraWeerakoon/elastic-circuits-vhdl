# elastic-circuits-vhdl

A learning project. I wanted to understand what a dynamically scheduled
(dataflow) circuit looks like at the RTL level, so I built one by hand in VHDL
and then compared it against the circuit Dynamatic generates from the same C
code.

It's not research, just me working through the ideas in the Dynamatic papers by
implementing them, plus notes on what I measured and what I still don't
understand.

```c
int kernel(int x[N]) {
  int s = 1;
  for (int i = 0; i < N; i++) {
    if (x[i] > 0) s = s * x[i];   // slow path, 4-cycle multiplier
    else          s = s + x[i];   // fast path, 1-cycle adder
  }
  return s;
}
```

It has a single loop with a data-dependent branch, and the two sides of the
branch have very different latencies. It was the smallest kernel I could come
up with where dynamic scheduling should visibly beat a fixed schedule.

## How this went, in order

**1. I read "Dynamically Scheduled High-Level Synthesis" (FPGA 2018).**
The idea made sense on paper, but I couldn't picture the hardware: what a
`fork` is actually made of, or what backpressure looks like in VHDL. So I
decided to write the components myself.

**2. I built a handshake component library** (`rtl/`): `sink`, `source`,
`const`, `oehb`, `tehb`, `fifo`, `fork`, `join`, `merge`, `mux`, `cond_br`,
`add`, `cmp`, `mul`. 14 units in total, written in VHDL-2008.

I kept the port names and the general shape the same as
[Dynamatic's VHDL library](https://github.com/EPFL-LAP/dynamatic/tree/main/data/vhdl/handshake)
(`ins`/`ins_valid`/`ins_ready`, `outs`/`outs_valid`/`outs_ready`) and read their
implementations when I got stuck, so these aren't independent designs. Writing
my own versions was how I checked that I actually understood the handshake
rules.

Each one has a testbench with randomised backpressure, plus a protocol checker
(`tb/handshake_checker.vhd`) that watches a channel and fails the simulation if
`valid` is ever dropped before the token is taken, or if the data changes while
the channel is waiting for `ready`. Running that checker on every testbench is
what made me trust the library. Both of those bugs simulate fine in the easy
case and only show up under backpressure.

**3. I wired those components into the kernel above** (`rtl/kernel_dynamic.vhd`,
30 instances) and wrote a statically scheduled version for comparison
(`rtl/kernel_static.vhd`). Then I swept the fraction of positive inputs from
0% to 100% and counted cycles.

The dynamic version takes between 65 and 321 cycles depending on the data; the
static one takes 321 every time. That gap is basically what the paper is about,
and it only really made sense to me once I saw it in my own simulation.

Results: [`results/sweep.png`](results/sweep.png).

I also swept the multiplier latency itself
([`results/sweep_latency_overlay.png`](results/sweep_latency_overlay.png)).
The best case, where no input is positive so the multiplier is never used,
scales with how slow the multiplier is: 2.0× at `MUL_LATENCY = 1`, 4.9× at 4,
16.8× at 16. The worst case, where every input is positive, is a tie at every
latency, which makes sense since every iteration then takes the slow path.

The 2.0× at `MUL_LATENCY = 1` needs a caveat. At that latency both paths take
one cycle, so scheduling shouldn't matter at all. The gap comes from my static
FSM spending a separate cycle in `FETCH` before `COMPUTE`, which the dataflow
circuit doesn't need. So that number reflects a weakness in my baseline, not
anything dynamic scheduling is doing.

**4. Then I wanted to know what Dynamatic would do with the same C code.**
I built Dynamatic, ran the kernel through it, and compared the generated
circuit with mine, both structurally and in cycle count.

Writeup: [`docs/dynamatic_comparison.md`](docs/dynamatic_comparison.md).

In short, neither circuit wins everywhere. Mine is faster when most inputs take
the fast path, and Dynamatic's is faster when most take the slow path. Both
differences come from where one buffer sits. I put the opaque buffer for the
`s` loop at the loop header, so both paths pay for it (II 1 for add, II 5 for
multiply). Dynamatic's MILP put its opaque buffers only on the add branch,
since the multiplier's pipeline registers already cut the multiply loop (II 2
for add, II 4 for multiply).

At first I thought my fast-path advantage came from the memory interface (I
stream `x` in, while Dynamatic generates a BRAM and the load sits inside the
loop). That turned out to be wrong. When I moved my buffers to where Dynamatic
put them, I got exactly its IIs even with my streamed input, and the interface
only adds a constant 2 cycles. With a single buffer on the add branch, my
circuit gets II 1 and II 4, which is at or below both original circuits at
every input mix.

**5. While reading the FPGA 2020 buffer placement paper, I got curious about
Dynamatic's other buffer placement algorithms.** So I ran the ones my build
supports and compared them.

Writeup: [`docs/buffer_algorithms.md`](docs/buffer_algorithms.md).

`fpga20` was the fastest at every data point I tried, and used one more buffer
than the correctness-only baseline. `fpl22` was both slower and larger. That
surprised me until I dumped the MILP variables and saw that it constrains the
`valid` and `ready` paths, while `fpga20` only constrains the data path. I
haven't read the FPL 2022 paper yet, so that explanation comes from looking at
the solver output, not from the paper.

## Limitations

- **The static baseline is a hand-written FSM, not output from a real HLS
  tool.** It's a four-state machine that always waits the full multiplier
  latency, so it's a worst-case schedule by design. It shows why a fixed
  schedule loses on this kernel, but it says nothing about how dynamic
  scheduling compares to Vitis or any other production static HLS flow. I
  haven't run one.
- **My loop headers use `merge`, not `mux` + `control_merge`.** This only works
  because my circuit never has more than one token in flight. Dynamatic uses
  muxes at loop headers because they stay correct when several iterations are
  in flight at once. Mine would break in that case.
- **No synthesis.** Every number here is a cycle count from simulation. I
  haven't run Vivado, so I don't have clock frequency or area numbers, and I
  don't know whether the circuit would close timing. Without a clock frequency,
  cycle counts don't tell you the actual runtime.
- **The component library isn't independent work.** As mentioned above, I read
  Dynamatic's implementations while writing mine.
- **The Dynamatic comparison still has a confound:** the two circuits use
  different memory interfaces. Moving my buffer showed that the interface isn't
  what separates the IIs and only costs a constant 2 cycles here, but I haven't
  removed the difference. Because of that, the writeup doesn't quote a single
  speedup number.
- **Buffer placement used CBC, not Gurobi.** Gurobi needs a licence I don't
  have. Two of the five algorithms (`costaware`, `mapbuf`) wouldn't run on CBC
  at all, so I could only compare three.

Things I'm still unsure about are listed in
[`docs/open-questions.md`](docs/open-questions.md).

## Layout

```
rtl/              handshake component library + the two kernels
tb/               testbenches, random-backpressure source, protocol checker
scripts/          simulation, sweeps, plotting
docs/             the two comparison writeups and open questions
results/          CSVs and figures, including everything Dynamatic generated
learn/            small exercises from while I was learning VHDL
```

## Running it

Needs GHDL and Python with matplotlib.

```bash
./scripts/run_all.sh                       # compile + run every testbench
python3 scripts/sweep.py --n 64            # hand-built dynamic vs static sweep
```

The Dynamatic side needs a local Dynamatic build; the steps are at the top of
[`docs/dynamatic_comparison.md`](docs/dynamatic_comparison.md).

## Reading

- L. Josipović, R. Ghosal, P. Ienne, *Dynamically Scheduled High-Level
  Synthesis*, FPGA 2018, pp. 127–136.
  [10.1145/3174243.3174264](https://doi.org/10.1145/3174243.3174264).
  The paper this project started from.
- L. Josipović, S. Sheikhha, A. Guerrieri, P. Ienne, J. Cortadella, *Buffer
  Placement and Sizing for High-Performance Dataflow Circuits*, FPGA 2020,
  pp. 186–196.
  [10.1145/3373087.3375314](https://doi.org/10.1145/3373087.3375314).
  This is what got me into the buffer placement comparison. I've only read part
  of it so far.
- [Dynamatic](https://github.com/EPFL-LAP/dynamatic) and its
  [documentation](https://epfl-lap.github.io/dynamatic/).
