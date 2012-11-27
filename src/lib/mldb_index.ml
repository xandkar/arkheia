open Batteries


module GZ     = Mldb_gz
module Msg    = Mldb_msg
module RegExp = Mldb_regexp
module Utils  = Mldb_utils


type t =
  (string, (string * int * int list) list) Map.t


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
  |> List.map String.lowercase


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
      (token, (count, List.sort positions))::data'
  )
  data []


let build dir_index dir_messages msg_stream : unit =
  let write_word_data msg_id (word, (count, positions)) =
    let positions = String.concat "," (List.map string_of_int positions) in
    let data = (Printf.sprintf "%s|%d|%s\n" msg_id count positions) in

    let dir = Filename.concat dir_index (string_of_char word.[0]) in
    Utils.mkpath dir;

    let word_file = Filename.concat dir (word ^ ".csv") in
    let modes = [Open_append; Open_creat; Open_binary] in
    let perms = 0o666 in

    let oc = open_out_gen modes perms word_file in
    output_string oc data;
    close_out oc
  in

  let process_message msg_txt =
    let msg = Msg.parse msg_txt in
    Msg.save dir_messages msg_txt msg.Msg.id;
    let words = (count_and_positions (tokenize msg.Msg.body)) in
    List.iter (write_word_data msg.Msg.id) words;
  in

  Utils.mkpath dir_messages;
  Utils.mkpath dir_index;

  Stream.iter process_message msg_stream


let load (dir : string) : t =
  let paths =
    List.flatten
    ( Array.fold_left
      ( fun acc d ->
          ( Array.fold_left
            ( fun acc file -> (Filename.concat (Filename.concat dir d) file)::acc
            ) [] (Sys.readdir (Filename.concat dir d))
          )::acc
      ) [] (Sys.readdir dir)
    )
  in

  let rec read index = function
    | [] -> index
    | p::ps ->
      let word = Filename.chop_suffix (Filename.basename p) ".csv" in
      let read_line l =
        try
          Scanf.sscanf l "%s@|%d|%s@\n"
          ( fun a b c ->
              let msg_id = a in
              let frequency = b in
              let positions = (List.map int_of_string (Str.split RegExp.comma c)) in
              msg_id, frequency, positions
          )
        with Scanf.Scan_failure e -> print_endline (dump e); assert false
      in
      let data = List.map read_line (Utils.lines_of p) in
      read (Map.add word data index) ps
  in
  read Map.empty paths


let lookup (index : t) (query : string) : string list =
  try
    let words = Str.split RegExp.white_spaces query in
    let msg_lists = List.map (fun w -> Map.find w index) words in
    let msg_sets = List.map (List.map (Tuple.Tuple3.first) |- Set.of_list) msg_lists in

    match msg_sets with
    | s::ss ->
      List.fold_left Set.intersect s ss |> Set.enum |> List.of_enum
    | _ ->
      assert false

  with Not_found ->
    []
