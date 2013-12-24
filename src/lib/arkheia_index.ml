module GZ     = Arkheia_gz
module Msg    = Arkheia_msg
module RegExp = Arkheia_regexp
module Utils  = Arkheia_utils


type t =
  (string, (string * int * int list) list) Hashtbl.t


let fst_of_triple = function
  | fst, _, _ -> fst


let illegal_chars : char list =
  [ '`'; '~'; '!'; '@'; '#'; '#'; '$'; '%'; '^'; '&'; '*'; '('; ')'; '='; '+';
    '['; '{'; ']'; '}'; '\\'; '|'; ';'; ':'; '\''; '"'; '<'; '.'; ','; '>';
    '/'; '?'; '-'; '_'
  ]


let replace_illegal_chars s : unit =
  String.iteri (fun i c -> if List.mem c illegal_chars then s.[i] <- ' ') s


let tokenize s : string list =
  let is_valid_length token =
    let file_ext_len = 4 in
    let max_filename_len = 150 in
    let max_token_length = max_filename_len - file_ext_len in

    let length = String.length token in
    length > 0 && length < max_token_length
  in
  replace_illegal_chars s;
  s
  |> Str.split RegExp.white_spaces_and_newlines
  |> List.filter is_valid_length
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
      (token, (count, List.sort compare positions))::data'
  )
  data []


let load (dir : string) : t =
  try
    let ic = open_in_bin (Filename.concat dir "index.dat") in
    let index = (Marshal.from_channel ic : t) in
    close_in ic;
    index
  with Sys_error _ ->
    Hashtbl.create 1


let build dir_index dir_messages msg_stream : unit =
  let write_word_data index msg_id (word, (count, positions)) =
    let data = msg_id, count, positions in

    try
      let old_data = Hashtbl.find index word in
      Hashtbl.replace index word (data::old_data)

    with Not_found ->
      Hashtbl.add index word [data]
  in

  let process_message index msg_txt =
    let msg = Msg.parse msg_txt in
    if Msg.is_unique dir_messages msg.Msg.id then
      begin
        Msg.save_as_bin dir_messages msg;
        let words = (count_and_positions (tokenize msg.Msg.body)) in
        List.iter (write_word_data index msg.Msg.id) words
      end
    else
      print_endline "Document aready exists, skipping."
  in

  Utils.mkpath dir_messages;
  Utils.mkpath dir_index;

  let index = load dir_index in
  Stream.iter (process_message index) msg_stream;

  let index_file = Filename.concat dir_index "index.dat" in
  let oc = open_out_bin index_file in
  Marshal.to_channel oc index [];
  close_out oc



module StrSet =
struct
  include (Set.Make (String))

  let of_list (l : string list) : t =
    List.fold_left (fun set e -> add e set) empty l
end

let lookup (index : t) (query : string) : string list =
  let ( |- ) f g x = g (f x) in
  try
    let words = Str.split RegExp.white_spaces query in
    let msg_lists = List.map (fun w -> Hashtbl.find index w) words in
    let msg_sets = List.map ((List.map fst_of_triple) |- StrSet.of_list) msg_lists in

    match msg_sets with
    | s::ss ->
      List.fold_left StrSet.inter s ss |> StrSet.elements
    | _ ->
      assert false

  with Not_found ->
    []
