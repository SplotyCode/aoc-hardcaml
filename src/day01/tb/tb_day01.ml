module Cpu1 = Aoc2025_day01_cpu.Part1
module Hw1 = Aoc2025_day01_hw.Part1_hw

module Cpu2 = Aoc2025_day01_cpu.Part2
module Hw2 = Aoc2025_day01_hw.Part2_hw

let reset_1cycle (cycle : unit -> unit) (i_clear : Hardcaml.Bits.t ref) =
  i_clear := Hardcaml.Bits.vdd;
  cycle ();
  i_clear := Hardcaml.Bits.gnd

let sim_part1 (input : string) : int =
  let module Sim = Hardcaml.Cyclesim.With_interface (Hw1.I) (Hw1.O) in
  let sim = Sim.create Hw1.create in
  let i = Hardcaml.Cyclesim.inputs sim in
  let o = Hardcaml.Cyclesim.outputs sim in
  let cycle () = Hardcaml.Cyclesim.cycle sim in

  i.valid := Hardcaml.Bits.gnd;
  i.last := Hardcaml.Bits.gnd;
  i.byte := Hardcaml.Bits.of_int ~width:8 0;

  reset_1cycle cycle i.clear;

  let bytes = Bytes.of_string input in
  let len = Bytes.length bytes in
  for idx = 0 to len - 1 do
    while Hardcaml.Bits.to_int !(o.ready) = 0 do
      i.valid := Hardcaml.Bits.gnd;
      i.last := Hardcaml.Bits.gnd;
      cycle ()
    done;

    i.valid := Hardcaml.Bits.vdd;
    i.byte := Hardcaml.Bits.of_int ~width:8 (Char.code (Bytes.get bytes idx));
    i.last := if idx = len - 1 then Hardcaml.Bits.vdd else Hardcaml.Bits.gnd;
    cycle ();

    i.valid := Hardcaml.Bits.gnd;
    i.last := Hardcaml.Bits.gnd
  done;

  let rec wait n =
    if n > 200_000 then failwith "timeout waiting for out_valid (part1)";
    if Hardcaml.Bits.to_int !(o.out_valid) <> 0
    then Hardcaml.Bits.to_int !(o.count)
    else (cycle (); wait (n + 1))
  in
  wait 0

let sim_part2 (input : string) : int =
  let module Sim = Hardcaml.Cyclesim.With_interface (Hw2.I) (Hw2.O) in
  let sim = Sim.create Hw2.create in
  let i = Hardcaml.Cyclesim.inputs sim in
  let o = Hardcaml.Cyclesim.outputs sim in
  let cycle () = Hardcaml.Cyclesim.cycle sim in

  i.valid := Hardcaml.Bits.gnd;
  i.last := Hardcaml.Bits.gnd;
  i.byte := Hardcaml.Bits.of_int ~width:8 0;

  reset_1cycle cycle i.clear;

  let bytes = Bytes.of_string input in
  let len = Bytes.length bytes in
  for idx = 0 to len - 1 do
    while Hardcaml.Bits.to_int !(o.ready) = 0 do
      i.valid := Hardcaml.Bits.gnd;
      i.last := Hardcaml.Bits.gnd;
      cycle ()
    done;

    i.valid := Hardcaml.Bits.vdd;
    i.byte := Hardcaml.Bits.of_int ~width:8 (Char.code (Bytes.get bytes idx));
    i.last := if idx = len - 1 then Hardcaml.Bits.vdd else Hardcaml.Bits.gnd;
    cycle ();

    i.valid := Hardcaml.Bits.gnd;
    i.last := Hardcaml.Bits.gnd
  done;

  let rec wait n =
    if n > 400_000 then failwith "timeout waiting for out_valid (part2)";
    if Hardcaml.Bits.to_int !(o.out_valid) <> 0
    then Hardcaml.Bits.to_int !(o.count)
    else (cycle (); wait (n + 1))
  in
  wait 0

let () =
  let open Alcotest in
  run "day01"
    [
      ( "part1",
        [
          test_case "sample" `Quick (fun () ->
              let input = "R50\n" in
              check int "cpu" 1 (Cpu1.solve input);
              check int "hw" 1 (sim_part1 input));

          test_case "given-case" `Quick (fun () ->
              let input =
                "L68\n\
                 L30\n\
                 R48\n\
                 L5\n\
                 R60\n\
                 L55\n\
                 L1\n\
                 L99\n\
                 R14\n\
                 L82\n"
              in
              check int "cpu" 3 (Cpu1.solve input);
              check int "hw" 3 (sim_part1 input));
        ] );

      ( "part2",
        [
          test_case "given-case" `Quick (fun () ->
              let input =
                "L68\n\
                 L30\n\
                 R48\n\
                 L5\n\
                 R60\n\
                 L55\n\
                 L1\n\
                 L99\n\
                 R14\n\
                 L82\n"
              in
              check int "cpu" 6 (Cpu2.solve input);
              check int "hw" 6 (sim_part2 input));

          test_case "R1000 from 50 hits 0 ten times" `Quick (fun () ->
              let input = "R1000\n" in
              check int "cpu" 10 (Cpu2.solve input);
              check int "hw" 10 (sim_part2 input));
        ] );
    ]
