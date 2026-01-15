# Advent of FPGA 2025

## My background
I took some SystemVerilog classes at university and designed small apps with it.
We also had OCaml but i barely used it.
Now I learn Hardcaml and try to build small but clean hardware designs.

## Project structure
- src/day01/cpu/ reference solution
- src/day01/hw/ Hardcaml RTL (synthesizable)
- src/day01/tb/ Alcotest + Hardcaml Cyclesim

## Problem recap
- Start position is 50 on a ring of size 100 (positions `0..99`).
- Each input line is like `L68` or `R50`.
- `L` means move left, `R` means move right (always modulo 100).
- After each move, if the position is 0, we increase a counter.
- The output is this counter.

## How the hardware solution works
The hardware reads the input as a ASCII byte stream

**Inputs**
- `valid` + `byte` (8-bit ASCII)
- `last` (1 on the final byte)
- `clock`, `clear`

**Outputs**
- `ready` (module can accept bytes)
- `out_valid` (result is ready)
- `count` (32-bit)

- A small finite state machine with two states:
  - `DIR`: wait for `L` or `R`
  - `DIST`: read digits until newline `\n`
- While reading digits, the design builds the distance (mod 100).
- On newline:
  - update `pos` (mod 100)
  - if `pos == 0` then `count++`
- When `last` is seen, the design sets `out_valid`.

## Part 2 note

Part 2 changes the counting rule: we now count every time the dial passes position 0,
not only when a rotation ends. For example, a single command like `R1000` from position `50`
passes 0 ten times before returning to 50.

On the CPU reference solution this is super fast, because you can compute the number of
with simple modular arithmetic, without simulating every click.

In hardware, I had problems using the same approach so currently I simulate every move:
after parsing a command, the module enters a `ROTATE` state and performs one click per cycle,
updating `pos` and incrementing `count` whenever `pos` becomes `0`. It’s obviously slower for very large
distances because it takes `distance` cycles per command.

## Build and test
```bash
opam install . --deps-only
dune build
dune runtest
```


Feedback is very welcome. I am a total beginner in Hardcaml