open Hardcaml

module I = struct
  type 'a t = { (* placeholder *)
    dummy : 'a
  } [@@deriving hardcaml]
end

module O = struct
  type 'a t = {
    result : 'a
  } [@@deriving hardcaml]
end

let circuit (_scope : Scope.t) (i : Signal.t I.t) : Signal.t O.t =
  { O.result = i.dummy }  (* placeholder *)
