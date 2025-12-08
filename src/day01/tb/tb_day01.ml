module Part1 = Aoc2025_day01_cpu.Part1

let () =
  let open Alcotest in
  run "day01"
    [
      ( "part1",
        [
          test_case "sample" `Quick (fun () ->
              let input = "R50\n" in
              let got = Part1.solve input in
              check int "count" 1 got);

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
              let got = Part1.solve input in
              check int "count" 3 got);
        ] );
    ]
