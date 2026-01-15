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

let create (i : _ I.t) : _ O.t =
  let open Signal in
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let spec_pos = Reg_spec.override spec ~clear_to:(of_int ~width:7 50) in

  (* state: 0=DIR, 1=DIST, 2=ROTATE *)
  let state = wire 2 in
  let dir_right = wire 1 in
  let dist = wire 32 in
  let remaining = wire 32 in
  let pos = wire 7 in
  let count = wire 32 in
  let eos_seen = wire 1 in
  let done_ = wire 1 in

  let in_dir = state ==:. 0 in
  let in_dist = state ==:. 1 in
  let in_rot = state ==:. 2 in

  let ready = (~:done_) &: (~:in_rot) in
  let accept = i.valid &: ready in

  let c_L = of_char 'L' in
  let c_R = of_char 'R' in
  let c_nl = of_char '\n' in
  let c_cr = of_char '\r' in
  let c_0 = of_char '0' in
  let c_9 = of_char '9' in

  let is_L = i.byte ==: c_L in
  let is_R = i.byte ==: c_R in
  let is_nl = i.byte ==: c_nl in
  let is_cr = i.byte ==: c_cr in
  let is_digit = (i.byte >=: c_0) &: (i.byte <=: c_9) in

  let start_cmd = in_dir &: accept &: (is_L |: is_R) in

  let do_digit = in_dist &: accept &: is_digit in
  let digit_val = uresize (i.byte -:. (Char.code '0')) 32 in
  let dist_times10 = (sll dist 3) +: (sll dist 1) in
  let dist_next = dist_times10 +: digit_val in

  let do_commit = in_dist &: accept &: is_nl in

  let rot_active = in_rot &: (remaining <>:. 0) in
  let rot_last = in_rot &: (remaining ==:. 1) in

  let pos_inc =
    mux2 (pos ==:. 99) (of_int ~width:7 0) (pos +:. 1)
  in
  let pos_dec =
    mux2 (pos ==:. 0) (of_int ~width:7 99) (pos -:. 1)
  in
  let pos_step = mux2 dir_right pos_inc pos_dec in
  let count_step = mux2 (pos_step ==:. 0) (count +:. 1) count in

  let remaining_step = remaining -:. 1 in

  let eos_seen_d = eos_seen |: (accept &: i.last) in

  let set_done = eos_seen &: in_dir &: (~:(i.valid)) in

  let done_d = done_ |: set_done in

  let state_d =
    mux2 start_cmd (of_int ~width:2 1)
      (mux2 do_commit (of_int ~width:2 2)
         (mux2 rot_last (of_int ~width:2 0) state))
  in

  let dir_d = mux2 start_cmd is_R dir_right in

  let dist_d =
    mux2 start_cmd (zero 32)
      (mux2 do_digit dist_next
         (mux2 is_cr dist dist))
  in

  let remaining_d =
    mux2 do_commit dist
      (mux2 rot_active remaining_step remaining)
  in

  let pos_d = mux2 rot_active pos_step pos in

  let count_d = mux2 rot_active count_step count in

  state <== reg spec ~enable:vdd state_d;
  dir_right <== reg spec ~enable:vdd dir_d;
  dist <== reg spec ~enable:vdd dist_d;
  remaining <== reg spec ~enable:vdd remaining_d;
  pos <== reg spec_pos ~enable:vdd pos_d;
  count <== reg spec ~enable:vdd count_d;
  eos_seen <== reg spec ~enable:vdd eos_seen_d;
  done_ <== reg spec ~enable:vdd done_d;

  { O.ready; out_valid = done_; count }
