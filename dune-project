(lang dune 3.11)
(name aoc2025)
(generate_opam_files true)

(license "MIT")
(authors "David")
(maintainers "David")

(package
 (name aoc2025)
 (depends
  (ocaml (>= 5.3.0))
  dune
  ocamlfind
  hardcaml
  ppx_hardcaml
  hardcaml_waveterm
  ppx_jane
  alcotest))
