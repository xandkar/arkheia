open Batteries


module GZ     = Mldb_gz
module Msg    = Mldb_msg
module RegExp = Mldb_regexp
module Utils  = Mldb_utils


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


let build dir_index dir_messages msg_stream : unit =
  let write_word_data msg_id (word, (count, positions)) =
    let positions = String.concat "," (List.map string_of_int positions) in
    let data = (Printf.sprintf "%s|%d|%s\n" msg_id count positions) in

    let dir = Filename.concat dir_index (string_of_char word.[0]) in
    Utils.mkpath dir;

    let word_file = Filename.concat dir (word ^ ".csv.gz") in
    let modes = [Open_append; Open_creat; Open_text] in
    let perms = 0o666 in

    let oc = Pervasives.open_out_gen modes perms word_file in
    let oc_gz = GZ.open_out_chan oc in

    GZ.output_string oc_gz data;

    GZ.close_out oc_gz;
    Pervasives.close_out oc
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
