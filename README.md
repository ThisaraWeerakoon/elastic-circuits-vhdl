# elastic-circuits-vhdl

A learning project. I wanted to understand what a dynamically scheduled
(dataflow) circuit actually looks like at the RTL level, so I built one by hand
in VHDL, then compared it against the circuit Dynamatic generates from the same
C code.

This is not research. It is me working through the ideas in the Dynamatic
papers by implementing them, and writing down what I measured and what I still
do not understand.

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

One loop, one data-dependent branch, and two paths with very different
latencies. That is the smallest kernel I could think of where dynamic
scheduling should visibly beat a fixed schedule.

## How this went, in order

**1. I read "Dynamically Scheduled High-Level Synthesis" (FPGA 2018).**
The idea was clear on paper but I could not picture the hardware. What is a
`fork` actually made of? What does backpressure look like in VHDL? I decided
the only way to find out was to write the components myself.

**2. I built a handshake component library** (`rtl/`): `sink`, `source`,
`const`, `oehb`, `tehb`, `fifo`, `fork`, `join`, `merge`, `mux`, `cond_br`,
`add`, `cmp`, `mul`. Fourteen units, VHDL-2008.

I kept the port names and the general shape the same as
[Dynamatic's VHDL library](https://github.com/EPFL-LAP/dynamatic/tree/main/data/vhdl/handshake)
(`ins`/`ins_valid`/`ins_ready`, `outs`/`outs_valid`/`outs_ready`) and read their
implementations when I got stuck. So these are not independent inventions. They
are my versions of components I was reading, written to make sure I understood
the handshake rules rather than just recognised them.

Each one has a testbench with randomised backpressure, plus a protocol checker
(`tb/handshake_checker.vhd`) that watches a channel and fails the simulation if
`valid` is ever dropped before the token is taken, or if the data changes while
the channel is waiting for `ready`. Having that run on every testbench was the
thing that made me trust the library, because those are exactly the mistakes
that still simulate fine in the easy case and only break under backpressure.

**3. I wired those components into the kernel above** (`rtl/kernel_dynamic.vhd`,
30 instances) and wrote a statically scheduled version for comparison
(`rtl/kernel_static.vhd`). Then I swept the fraction of positive inputs from
0% to 100% and counted cycles.

The dynamic version ranges from 65 to 321 cycles depending on the data. The
static one is 321 every time. That gap is the whole point of the paper, and
seeing it come out of my own simulation is the thing that made it click.

Results: [`results/sweep.png`](results/sweep.png).

I also swept the multiplier latency itself
([`results/sweep_latency_overlay.png`](results/sweep_latency_overlay.png)).
The best case, where no input is positive so the multiplier is never used,
scales with how slow the multiplier is: 2.0× at `MUL_LATENCY = 1`, 4.9× at 4,
16.8× at 16. The worst case, where every input is positive, is a dead heat at
every latency, which is what you would expect since then every iteration takes
the slow path anyway.

The 2.0× at `MUL_LATENCY = 1` is worth being honest about. At that point there
is no fast path and no slow path, so scheduling should not matter at all. The
gap is there because my static FSM spends a separate cycle in `FETCH` before
`COMPUTE`, which the dataflow circuit does not need. That is a weakness of my
baseline, not a win for dynamic scheduling.

**4. Then I wanted to know what Dynamatic would do with the same C code.**
I built the compiler and ran the kernel through it, and compared the generated
circuit with mine, both structurally and on cycle count.

Writeup: [`docs/dynamatic_comparison.md`](docs/dynamatic_comparison.md).

The short version: the curves cross. My circuit is faster when the fast path
dominates, Dynamatic's is faster when the slow path does. Both halves of that
come from one buffer. I put the `s` loop's opaque buffer at the loop header,
where both paths pay for it (II 1 add, II 5 multiply). Dynamatic's MILP put its
opaque buffers on the add branch only, because the multiplier's pipeline
registers already cut the multiply loop (II 2 add, II 4 multiply).

I first put my fast-path advantage down to the memory interface (I stream `x`
in, Dynamatic generates a BRAM and the load sits in the loop). That was wrong.
Moving my buffers to where Dynamatic put them reproduces its IIs exactly with
my streamed input. The interface accounts for only a constant 2 cycles. With
one buffer on the add branch, my circuit gets II 1 and II 4, which is at or
below both original circuits at every input mix.

**5. While reading the FPGA 2020 buffer placement paper I started wondering what
the other algorithms would do**, so I ran the ones my build supports and
compared them.

Writeup: [`docs/buffer_algorithms.md`](docs/buffer_algorithms.md).

`fpga20` was fastest at every data point I tried, for one buffer more than the
correctness-only baseline. `fpl22` was slower and larger, which surprised me
until I dumped the MILP variables and saw that it constrains the `valid` and
`ready` paths while `fpga20` only constrains the data path. I have not read the
FPL 2022 paper yet, so that explanation is my reading of the solver output, not
something I can back up from the paper.

## What I am not claiming

I would rather say this plainly than have it inferred.

- **The static baseline is a hand-written FSM, not a real HLS tool.** It is a
  four-state machine that always waits the full multiplier latency, so it is a
  worst-case schedule by construction. It is a fair illustration of *why* a
  fixed schedule loses on this kernel. It is not evidence that dynamic
  scheduling beats Vitis or any production static HLS flow. I have not run one.
- **My loop headers use `merge`, not `mux` + `control_merge`.** That is only
  safe because at most one token is ever in flight in my circuit. Dynamatic
  uses muxes at loop headers because they stay correct when more than one
  iteration is in flight. Mine would break in that case. This is a real
  limitation of my version, not a simplification I got away with for free.
- **No synthesis.** Every number here is cycle counts from simulation. I have
  not run Vivado, so I have no clock frequency, no area, and no idea whether my
  circuit would actually close timing. Cycles are only half of runtime.
- **The component library is not independent work.** I read Dynamatic's
  implementations while writing mine.
- **The Dynamatic comparison still has a confound.** Different memory
  interfaces, as described above. Moving my buffer showed it is not what
  separates the IIs and that it costs a constant 2 cycles here, but I have not
  removed it. I flag it in the writeup rather than quoting a single speedup
  number.
- **Buffer placement used CBC, not Gurobi.** Gurobi needs a licence I do not
  have. Two of the five algorithms (`costaware`, `mapbuf`) would not run at all
  on CBC, so I could only compare three.

Things I am still unsure about are in
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
  What sent me down the buffer placement comparison. I have read part of this
  one, not all of it.
- [Dynamatic](https://github.com/EPFL-LAP/dynamatic) and its
  [documentation](https://epfl-lap.github.io/dynamatic/).
