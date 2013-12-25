module Hashtbl = MoreLabels.Hashtbl
module List    = ListLabels

module GZ     = Arkheia_gz
module Msg    = Arkheia_msg
module RegExp = Arkheia_regexp
module Utils  = Arkheia_utils


type location =
  { msg_id    : string
  ; count     : int
  ; positions : int list
  }

type word = string

type t =
  (word, location list) Hashtbl.t


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
  |> List.filter ~f:is_valid_length
  |> List.map ~f:String.lowercase


let count_and_positions tokens =
  let hist = Utils.histogram tokens in
  let table = Hashtbl.create 1 in

  List.iteri ~f:(
    fun position token ->
      try
        let (count, ps) = Hashtbl.find table token in
        Hashtbl.replace table ~key:token ~data:(count, position::ps)

      with Not_found ->
        let count = Hashtbl.find hist token in
        Hashtbl.add table ~key:token ~data:(count, [position])
  )
  tokens;

  Hashtbl.fold table ~init:[] ~f:(
    fun ~key:token ~data:(count, positions) acc ->
      (token, (count, List.sort ~cmp:compare positions)) :: acc
  )


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
    let location = {msg_id; count; positions} in

    try
      let locations = location :: (Hashtbl.find index word) in
      Hashtbl.replace index ~key:word ~data:locations

    with Not_found ->
      Hashtbl.add index word [location]
  in

  let process_message index msg_txt =
    let msg = Msg.parse msg_txt in
    if Msg.is_unique dir_messages msg.Msg.id then
      begin
        Msg.save_as_bin dir_messages msg;
        let words = (count_and_positions (tokenize msg.Msg.body)) in
        List.iter ~f:(write_word_data index msg.Msg.id) words
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
    List.fold_left l ~init:empty ~f:(fun set e -> add e set)
end

let lookup (index : t) (query : string) : string list =
  try
    let words = Str.split RegExp.white_spaces query in
    let locations_list = List.map ~f:(fun w -> Hashtbl.find index w) words in
    let msg_ids_sets =
      List.map locations_list ~f:(
        fun locations ->
          let msg_ids = List.map locations ~f:(fun l -> l.msg_id) in
          StrSet.of_list msg_ids
      )
    in
    match msg_ids_sets with
    | s::ss ->
      List.fold_left ~f:StrSet.inter ~init:s ss |> StrSet.elements
    | _ ->
      assert false
  with Not_found ->
    []
