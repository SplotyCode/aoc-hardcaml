let mod100 (x : int) : int =
  let r = x mod 100 in
  if r < 0 then r + 100 else r

let hits_zero (pos : int) (dir : char) (d : int) : int =
  let direction =
    match dir with
    | 'R' -> (100 - pos) mod 100
    | 'L' -> pos
    | _ -> failwith "bad dir"
  in
  let first = if direction = 0 then 100 else direction in
  if d < first then 0 else 1 + ((d - first) / 100)

let solve (input : string) : int =
  let pos = ref 50 in
  let count = ref 0 in
  input
  |> String.split_on_char '\n'
  |> List.iter (fun line ->
       let line = String.trim line in
       if line <> "" then begin
         let dir = line.[0] in
         let distance =
           int_of_string (String.sub line 1 (String.length line - 1))
         in
         count := !count + hits_zero !pos dir distance;
         pos :=
           (match dir with
            | 'L' -> mod100 (!pos - distance)
            | 'R' -> mod100 (!pos + distance)
            | _ -> failwith ("Unknown direction in " ^ line))
       end);
  !count
