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
- Start position is `50` on a ring of size `100` (positions `0..99`).
- Each input line is like `L68` or `R50`.
- `L` means move left, `R` means move right (always modulo 100).
- After each move, if the position is `0`, we increase a counter.
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

## Build and test
```bash
opam install . --deps-only
dune build
dune runtest
```


Feedback is very welcome. I am a total beginner in Hardcaml