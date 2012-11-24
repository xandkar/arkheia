open Batteries


let illegal_chars : char list =
  [ '`'; '~'; '!'; '@'; '#'; '#'; '$'; '%'; '^'; '&'; '*'; '('; ')'; '='; '+';
    '['; '{'; ']'; '}'; '\\'; '|'; ';'; ':'; '\''; '"'; '<'; '.'; ','; '>';
    '/'; '?'; '-'; '_'
  ]


let replace_illegal_chars s : unit =
  String.iteri (fun i c -> if List.mem c illegal_chars then s.[i] <- ' ') s


let tokenize s : string list =
  replace_illegal_chars s; s
  |> Str.split RegExp.white_spaces_and_newlines
  |> List.filter (fun s -> let len = String.length s in len > 0 && len < 255)


let count_and_positions tokens =
  let hist = Utils.histogram tokens in
  let data = Hashtbl.create 1 in

  List.iteri
  ( fun position token ->
      try
        let (count, ps) = Hashtbl.find data token in
        Hashtbl.replace data token (count, position::ps)

      with Not_found ->
        let count = Hashtbl.find hist token in
        Hashtbl.add data token (count, [position])
  )
  tokens;

  Hashtbl.fold
  ( fun token (count, positions) data' ->
      (token, (count, List.sort compare positions))::data'
  )
  data []
