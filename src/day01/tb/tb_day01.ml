module Cpu = Aoc2025_day01_cpu.Part1
module Hw = Aoc2025_day01_hw.Part1_hw

module Sim = Hardcaml.Cyclesim.With_interface (Hw.I) (Hw.O)

let simulate_hw_count (input : string) : int =
  let sim = Sim.create Hw.create in
  let i = Hardcaml.Cyclesim.inputs sim in
  let o = Hardcaml.Cyclesim.outputs sim in

  i.clear := Hardcaml.Bits.vdd;
  i.valid := Hardcaml.Bits.gnd;
  i.last := Hardcaml.Bits.gnd;
  i.byte := Hardcaml.Bits.of_int ~width:8 0;
  Hardcaml.Cyclesim.cycle sim;
  i.clear := Hardcaml.Bits.gnd;

  let bytes = Bytes.of_string input in
  for idx = 0 to Bytes.length bytes - 1 do
    i.valid := Hardcaml.Bits.vdd;
    i.byte := Hardcaml.Bits.of_int ~width:8 (Char.code (Bytes.get bytes idx));
    i.last := if idx = Bytes.length bytes - 1 then Hardcaml.Bits.vdd else Hardcaml.Bits.gnd;
    Hardcaml.Cyclesim.cycle sim
  done;

  i.valid := Hardcaml.Bits.gnd;
  i.last := Hardcaml.Bits.gnd;

  let rec wait n =
    if n > 10_000 then failwith "timeout waiting for out_valid";
    if Hardcaml.Bits.to_int !(o.out_valid) <> 0
    then Hardcaml.Bits.to_int !(o.count)
    else (Hardcaml.Cyclesim.cycle sim; wait (n + 1))
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
              check int "cpu" 1 (Cpu.solve input);
              check int "hw" 1 (simulate_hw_count input));

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
              check int "cpu" 3 (Cpu.solve input);
              check int "hw" 3 (simulate_hw_count input));
        ] );
    ]
