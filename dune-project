(lang dune 3.11)
(name aoc2025)
(generate_opam_files true)

(package
 (name aoc2025)
 (depends
  (ocaml (>= 5.3.0))
  dune
  ocamlfind
  hardcaml
  hardcaml_waveterm
  alcotest))
