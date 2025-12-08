let mod100 (x : int) : int =
  let r = x mod 100 in
  if r < 0 then r + 100 else r

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
         pos :=
           (match dir with
            | 'L' -> mod100 (!pos - distance)
            | 'R' -> mod100 (!pos + distance)
            | _ -> failwith ("Unknown direction in " ^ line));
         if !pos = 0 then incr count
       end);
  !count
