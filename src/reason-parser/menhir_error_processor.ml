(* This file is an executable run at build time to generate a file called
  _build/default/src/reason-parser/reason_parser_explain_raw.ml

  That generated file pattern-matches on the error codes that are related to
  e.g. accidentally using a reserved keyword as an identifier. Once we get those
  error codes, the file reason_parser_explain.ml is run (at parsing time, aka
  when you run refmt) and provides a more helpful message for these categories
  of errors, than the default "<syntax error>".

  Why can't we just check in reason_parser_explain_raw.ml and avoid this build-
  time file generation? Because the error code are dependent on the logic
  generated by the Menhir parser, and that logic changes when we modify the
  parser. Aka, each time we modify the reason_parser, we need to regenerate the
  potentially changed error code
*)

open MenhirSdk

module G = Cmly_read.Read(struct let filename = Sys.argv.(1) end)
open G

let print fmt = Printf.ksprintf print_endline fmt

(* We want to detect any state where an identifier is admissible.
   That way, we can assume that if a keyword is used and rejceted, the user was
   intending to put an identifier. *)
let states_transitioning_on pred =
  let keep_state lr1 =
    (* There are two kind of transitions (leading to SHIFT or REDUCE), detect
       those who accept identifiers *)
    List.exists (fun (term, _) -> pred (T term)) (Lr1.reductions lr1 [@alert "-deprecated"]) ||
    List.exists (fun (sym, _) -> pred sym) (Lr1.transitions lr1)
  in
  (* Now we filter the list of all states and keep the interesting ones *)
  G.Lr1.fold (fun lr1 acc -> if keep_state lr1 then lr1 :: acc else acc) []

let print_transitions_on name pred =
  (* Produce a function that will be linked into the reason parser to recognize
     states at runtime.
     TODO: a more compact encoding could be used, for now we don't care and
     just pattern matches on states.
  *)
  print "let transitions_on_%s = function" name;
  begin match states_transitioning_on pred with
    | [] -> prerr_endline ("no states matches " ^ name ^ " predicate");
    | states ->
      List.iter (fun lr1 -> print "  | %d" (Lr1.to_int lr1)) states;
      print "      -> true"
  end;
  print "  | _ -> false\n"

let terminal_find name =
  match
    Terminal.fold
      (fun t default -> if Terminal.name t = name then Some t else default)
      None
  with
  | Some term -> term
  | None -> failwith ("Unkown terminal " ^ name)

let () =
  List.iter
    (fun term ->
       let symbol = T (terminal_find term) in
       let name = (String.lowercase_ascii term) [@ocaml.warning "-3"] in
       print_transitions_on name ((=) symbol))
    [ "LIDENT"; "UIDENT"; "SEMI"; "RBRACKET"; "RPAREN"; "RBRACE" ]
