# Open questions

Things I noticed while doing this and could not resolve, or did not have the
tools to check. Roughly in the order they bother me.

## 1. I cannot separate scheduling quality from the interface difference

My circuit takes `x` as a stream through a handshake port. Dynamatic generates
a BRAM plus a memory controller, and the load ends up inside the loop. That
costs it roughly one cycle per iteration on the fast path.

So when my circuit wins at low positive-input rates, I do not know how much of
that is scheduling and how much is just "I was handed the data and it had to go
and fetch it". My guess is almost all of it is the interface, because the gap
is almost exactly one cycle per iteration, but I have not proved that.

To actually separate them I would have to either give my circuit a real memory
interface, or get Dynamatic to treat `x` as a stream argument. I did not find a
clean way to do the second one.

## 2. I have no timing numbers, so half of the comparison is missing

Everything in this repo is cycle counts. Runtime is cycles times clock period
and I have measured one of those two factors.

This matters most for the buffer placement comparison. `fpga20` wins on cycles,
but when I dumped the MILP variables it turned out it does not model the
`valid` and `ready` paths at all, only the data path. `fpl22` does model them
and spends four extra buffers keeping them under the target period. So it is
entirely possible that `fpga20` produces a circuit that cannot run at 250 MHz
and `fpl22` produces one that can, in which case my ranking is backwards.

I would need Vivado to find out. I have not run it.

## 3. Why is Dynamatic's fast path II = 2 and not 1?

I attribute it to the load being in the loop, which lines up with the numbers,
but I have not traced a waveform to confirm which channel is actually the
limiter. It could also be the `control_merge`, or a buffer the MILP placed for
a reason I have not worked out.

## 4. The branch is compiled away but the circuit still behaves dynamically

LLVM if-converts the `if`/`else` into a `select` before Dynamatic sees it. Both
the multiply and the add are issued every iteration. By rights the cycle count
should then be flat, like the static version. It is not.

Reading the generated `select` unit, it has `antitoken_depth = 1`, and the
comment in Dynamatic's generator says it fires on the chosen input and records
that it still owes a kill for the other one. That would explain the behaviour.

But that explanation comes from a source comment plus the fact that the
measured numbers vary with the data. I have not traced the protocol in a
waveform and I do not know the details of how the kill propagates, or what
happens when the killed token is itself the result of a long chain. This is the
part of the project I understand least and it is probably the most interesting
part.

## 5. Is my per-data-point recompilation making the comparison unfair?

`fpga20` is profile driven. It runs the kernel, collects edge frequencies, and
places buffers for that profile. My sweep recompiles for every input mix, so
each point is optimised for the data it is then measured on.

That is a reasonable thing to measure, but it is not the same as compiling once
and running a varied workload, which is closer to how you would actually use
the tool. I do not know how much the two differ here. Compiling once at 50% and
sweeping the data without recompiling would answer it.

## 6. Does the one-token-in-flight restriction cost me anything on this kernel?

My loop headers use `merge`, which is only correct because at most one token is
ever in flight. Dynamatic uses `mux` plus `control_merge`, which stays correct
with several iterations in flight.

For this kernel the `s` recurrence is serial anyway, since each iteration needs
the previous `s`, so I suspect the restriction costs nothing here and would
cost a lot on a kernel without a loop-carried dependency. The index computation
could in principle run ahead of the data path, and Dynamatic's circuit keeps
those on separate muxes, so it may already be doing that. I have not measured
whether it does.

## 7. Would Gurobi change the buffer placement results?

I used CBC because Gurobi needs a licence. `costaware` would not run at all
(it needs quadratic constraints) and `mapbuf` crashed in Dynamatic's CBC path,
so I could only compare three of the five algorithms.

For the three that did run, I do not know whether Gurobi would find the same
placements faster, or better placements. The MILPs here are small, so I would
guess the same, but that is a guess.

## 8. None of this says anything about scale

One loop, one branch, 64 iterations, no nested control flow, no memory
dependencies worth speaking of. The kernel was chosen to make dynamic
scheduling look good and it does. I have no evidence about anything larger.
