open Batteries
open Printf


module GZ     = Arkheia_gz
module RegExp = Arkheia_regexp
module Utils  = Arkheia_utils


type t =
  { top_from    : string
  ; from        : string
  ; date        : string
  ; subject     : string
  ; in_reply_to : string
  ; references  : string list
  ; id          : string
  ; id_orig     : string
  ; body        : string
  }

type section =
  Headers | Body


let is_head_tag  l = Str.string_match RegExp.header_tag  l 0
let is_head_data l = Str.string_match RegExp.header_data l 0


let parse_msg_id id =
  try Scanf.sscanf id "<%s@>" (fun id -> id)
  with e -> print_endline id; print_endline (dump e); assert false


let parse_msg_ids data = data
  |> Str.replace_first RegExp.angle_bracket_open_lead ""
  |> Str.replace_first RegExp.angle_bracket_close_trail ""
  |> Str.split RegExp.between_angle_bracketed_items
  |> List.map (Str.global_replace RegExp.white_spaces "")


let parse (msg_txt : string) : t =
  let parse_header h =
    if (Str.string_match RegExp.top_from h 0) then
      "TOP_FROM", h
    else
      match Str.full_split RegExp.header_tag h with
      | [Str.Delim tag]                -> Utils.strip tag, ""
      | [Str.Delim tag; Str.Text data] -> Utils.strip tag, Utils.strip data
      | _ -> print_endline (dump h); assert false
  in

  let pack_msg hs bs =
    let rec pack msg = function
      | [] -> msg

      | ("TOP_FROM"    , data)::hs -> pack {msg with top_from    = data} hs
      | ("From:"       , data)::hs -> pack {msg with from        = data} hs
      | ("Date:"       , data)::hs -> pack {msg with date        = data} hs
      | ("Subject:"    , data)::hs -> pack {msg with subject     = data} hs
      | ("In-Reply-To:", data)::hs -> pack {msg with in_reply_to = data} hs

      | ("References:" , data)::hs ->
        let references = List.map Utils.hash_of_string (parse_msg_ids data) in
        pack {msg with references = references} hs

      | ("Message-ID:" , data)::hs ->
        let id_orig = parse_msg_id data in
        let id = Utils.hash_of_string id_orig in
        pack {msg with id = id; id_orig = id_orig} hs

      | _ -> assert false
    in
    let msg =
      { top_from    = ""
      ; from        = ""
      ; date        = ""
      ; subject     = ""
      ; in_reply_to = ""
      ; references  = []
      ; id          = ""
      ; id_orig     = ""
      ; body        = String.concat "\n" bs
      }
    in
    pack msg hs
  in

  let rec parse h hs' bs' = function
    | Headers, [] | Body, [] -> pack_msg hs' (List.rev bs')

    | Headers, ""::ls ->
      parse "" ((parse_header h)::hs') bs' (Body, ls)

    | Headers, l::ls when is_head_tag l ->
      parse l ((parse_header h)::hs') bs' (Headers, ls)

    | Headers, l::ls when is_head_data l ->
      parse (h ^ l) hs' bs' (Headers, ls)

    | Headers, l::ls -> assert false

    | Body, l::ls -> parse h hs' (l::bs') (Body, ls)
  in

  let h, msg_lines = match (Str.split RegExp.newline msg_txt)with
    | h::msg_lines -> h, msg_lines
    | _ -> print_endline msg_txt; assert false
  in
  parse h [] [] (Headers, msg_lines)


let bar_major = let bar = String.make 80 '=' in bar.[0] <- '+'; bar
let bar_minor = let bar = String.make 80 '-' in bar.[0] <- '+'; bar


let print msg =
  let section bar s = String.concat "\n" [bar; s; bar] in
  let indent_ref = "    " in

  print_endline
  ( String.concat "\n"
    [ section bar_major "| MESSAGE"
    ; section bar_minor "| HEADERS"
    ; sprintf "TOP_FROM:    %s" msg.top_from
    ; sprintf "FROM:        %s" msg.from
    ; sprintf "DATE:        %s" msg.date
    ; sprintf "SUBJECT:     %s" msg.subject
    ; sprintf "IN_REPLY_TO: %s" msg.in_reply_to
    ; sprintf "MESSAGE_ID:  %s" msg.id
    ; "REFERENCES:"
    ; String.concat "\n" (List.map (sprintf "%s%s" indent_ref) msg.references)
    ; section bar_minor "| BODY"
    ; msg.body
    ]
  );
  print_newline ()


let assert_unique path =
  if Sys.file_exists path then
    begin
      printf "FILE EXISTS: %s\n%!" path;
      assert false
    end
  else
    ()


let save_as_txt dir txt id =
  let file_ext = ".eml.gz" in
  let file_name = id ^ file_ext in
  let file_path = Filename.concat dir file_name in

  assert_unique file_path;

  let oc = GZ.open_out file_path in
  begin
    try GZ.output_string oc txt
    with e -> GZ.close_out oc; raise e
  end;
  GZ.close_out oc


let save_as_bin dir (msg : t) =
  let file_ext = ".dat" in
  let file_name = msg.id ^ file_ext in
  let file_path = Filename.concat dir file_name in

  assert_unique file_path;

  let oc = open_out_bin file_path in
  begin
    try Marshal.to_channel oc msg []
    with e -> close_out oc; raise e
  end;
  close_out oc
