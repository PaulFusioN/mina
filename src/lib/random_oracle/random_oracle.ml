open Core
module Input = Random_oracle_make.Input
module State = Array

include Random_oracle_make.Make
          (Crypto_params.Runners.Tick)
          (struct
            let alpha = Random_oracle_make.N11
          end)
          (Sponge_params.Tick)

let%test_unit "iterativeness" =
  let open Tick0.Tick0 in
  let x1 = Field.random () in
  let x2 = Field.random () in
  let x3 = Field.random () in
  let x4 = Field.random () in
  let s_full = update ~state:initial_state [|x1; x2; x3; x4|] in
  let s_it =
    update ~state:(update ~state:initial_state [|x1; x2|]) [|x3; x4|]
  in
  [%test_eq: Field.t array] s_full s_it

let%test_unit "sponge checked-unchecked" =
  let module T = Tick0.Tick0 in
  let x = T.Field.random () in
  let y = T.Field.random () in
  T.Test.test_equal ~equal:T.Field.equal ~sexp_of_t:T.Field.sexp_of_t
    T.Typ.(field * field)
    T.Typ.field
    (fun (x, y) ->
      Crypto_params.Runners.Tick.make_checked (fun () -> Checked.hash [|x; y|])
      )
    (fun (x, y) -> hash [|x; y|])
    (x, y)
