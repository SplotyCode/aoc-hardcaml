open Hardcaml

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; valid : 'a
    ; byte : 'a [@bits 8]
    ; last : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t =
    { ready : 'a
    ; out_valid : 'a
    ; count : 'a [@bits 32]
    }
  [@@deriving sexp_of, hardcaml]
end

(* mod 100 for values 0..999 (we ensure that we mod the input below) *)
let mod100_0_999 (x : Signal.t) : Signal.t =
  let open Signal in
  let rec aux k acc =
    if k = 0 then acc
    else
      let thr = k * 100 in
      let acc = mux2 (acc >=:. thr) (acc -:. thr) acc in
      aux (k - 1) acc
  in
  aux 9 x

let add_mod100 (pos7 : Signal.t) (dist7 : Signal.t) : Signal.t =
  let open Signal in
  let sum8 = uresize pos7 8 +: uresize dist7 8 in
  let sum8 = mux2 (sum8 >=:. 100) (sum8 -:. 100) sum8 in
  uresize sum8 7

let sub_mod100 (pos7 : Signal.t) (dist7 : Signal.t) : Signal.t =
  let open Signal in
  let pos9 = uresize pos7 9 in
  let dist9 = uresize dist7 9 in
  mux2
    (pos9 >=: dist9)
    (uresize (pos9 -: dist9) 7)
    (uresize ((pos9 +:. 100) -: dist9) 7)

let create (i : _ I.t) : _ O.t =
  let open Signal in
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let spec_pos = Reg_spec.override spec ~clear_to:(of_int ~width:7 50) in

  let state = wire 2 in
  let dir_right = wire 1 in (* 1 => 'R', 0 => 'L' *)
  let acc = wire 7 in
  let pos = wire 7 in
  let count = wire 32 in
  let done_ = wire 1 in

  let ready = ~:done_ in
  let accept = i.valid &: ready in

  let c_L = of_char 'L' in
  let c_R = of_char 'R' in
  let c_nl = of_char '\n' in
  let c_cr = of_char '\r' in
  let c_0 = of_char '0' in
  let c_9 = of_char '9' in

  let is_dir = state ==:. 0 in
  let is_dist = state ==:. 1 in

  let is_L = i.byte ==: c_L in
  let is_R = i.byte ==: c_R in
  let is_nl = i.byte ==: c_nl in
  let is_cr = i.byte ==: c_cr in
  let is_digit = (i.byte >=: c_0) &: (i.byte <=: c_9) in

  let start_cmd = is_dir &: (is_L |: is_R) in

  let do_digit = is_dist &: is_digit in
  let digit10 = uresize (i.byte -:. (Char.code '0')) 10 in
  let acc10 = uresize acc 10 in
  let acc_times10 = sll acc10 3 +: sll acc10 1 in
  let acc_raw = acc_times10 +: digit10 in (* 0..999 *)
  let acc_next = uresize (mod100_0_999 acc_raw) 7 in

  let do_commit = is_dist &: is_nl in
  let pos_after = mux2 dir_right (add_mod100 pos acc) (sub_mod100 pos acc) in
  let count_after = mux2 (pos_after ==:. 0) (count +:. 1) count in

  let state_d =
    mux2 start_cmd (of_int ~width:2 1)
      (mux2 do_commit (of_int ~width:2 0) state)
  in
  let dir_d = mux2 start_cmd is_R dir_right in
  let acc_d =
    mux2 start_cmd (zero 7)
      (mux2 do_digit acc_next
         (mux2 do_commit (zero 7)
            (mux2 is_cr (zero 7) acc)))
  in
  let pos_d = mux2 do_commit pos_after pos in
  let count_d = mux2 do_commit count_after count in
  let done_d = mux2 i.last vdd done_ in

  state <== reg spec ~enable:accept state_d;
  dir_right <== reg spec ~enable:accept dir_d;
  acc <== reg spec ~enable:accept acc_d;
  pos <== reg spec_pos ~enable:accept pos_d;
  count <== reg spec ~enable:accept count_d;
  done_ <== reg spec ~enable:accept done_d;

  { O.ready; out_valid = done_; count }
