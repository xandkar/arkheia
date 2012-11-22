open Batteries


module RegExp = struct
  let space = Str.regexp " +"
  let space_leading = Str.regexp "^ +"
  let space_trailing = Str.regexp " +$"

  let top_from =
    let from = "^From" in
    let username = ".+" in
    let weekday = "[A-Z][a-z][a-z]" in
    let month = "[A-Z][a-z][a-z]" in
    let day = "[0-9]+" in
    let time = "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]" in
    let year = "[0-9][0-9][0-9][0-9]$" in
    Str.regexp
    ( String.concat " +"
      [ from
      ; username
      ; weekday
      ; month
      ; day
      ; time
      ; year
      ]
    )

  let header_tag = Str.regexp "^[a-zA-Z-_]+: "
  let header_data = Str.regexp "^[ \t]+"
end


module Str = struct include Str
  let strip s = s
    |> replace_first RegExp.space_leading ""
    |> replace_first RegExp.space_trailing ""
end


module GZ = struct include Gzip
  let output_line (oc : out_channel) (line : string) : unit =
    String.iteri (fun _ c -> output_char oc c) line;
    output_char oc '\n'


  let input_line (ic : in_channel) : string =
    let expected_chars = 100 in
    let buffer = Buffer.create expected_chars in
    let rec input_line = function
      | '\n' -> Buffer.contents buffer
      |   c  -> Buffer.add_char buffer c;
                input_line (input_char ic)
    in
    input_line (input_char ic)
end


module Msg = struct
  type header =
    string * string

  type t =
    { headers : header list
    ; body    : string list
    }

  type section =
    Headers | Body

  let is_head_tag l = Str.string_match RegExp.header_tag l 0
  let is_head_dat l = Str.string_match RegExp.header_data l 0

  let parse (lines : string list) : t =
    let validate hs =
      let clean_id id =
        try Scanf.sscanf id "<%s@>" (fun id -> id)
        with e -> print_endline id; print_endline (dump e); assert false
      in
      let rec validate hs' = function
        |                                [] -> hs'
        | (("TOP_FROM",     data) as h)::hs -> validate (h::hs') hs
        | (("From:",        data) as h)::hs -> validate (h::hs') hs
        | (("Date:",        data) as h)::hs -> validate (h::hs') hs
        | (("Subject:",     data) as h)::hs -> validate (h::hs') hs
        | (("In-Reply-To:", data) as h)::hs -> validate (h::hs') hs
        | (("References:",  data) as h)::hs -> validate (h::hs') hs
        | ("Message-ID:"  as t, d)::hs -> validate ((t, clean_id  d)::hs') hs

        | h::_ -> print_endline (dump h); assert false
      in
      validate [] hs
    in
    let parse_header h =
      if (Str.string_match RegExp.top_from h 0) then
        "TOP_FROM", h
      else
        match Str.full_split RegExp.header_tag h with
        | [Str.Delim tag; Str.Text data] -> Str.strip tag, Str.strip data
        | _ -> print_endline h; assert false
    in
    let rec parse h hs bs = function
      | Headers, [] | Body, [] -> {headers=validate hs; body=List.rev bs}
      | Headers, ""::ls -> parse "" ((parse_header h)::hs) bs (Body, ls)
      | Headers,  l::ls when is_head_tag l -> parse l ((parse_header h)::hs) bs (Headers, ls)
      | Headers,  l::ls when is_head_dat l -> parse (h^l) hs bs (Headers, ls)
      | Headers,  l::ls -> assert false
      | Body,    l::ls -> parse h hs (l::bs) (Body, ls)
    in
    let h, lines = match lines with
      | h::lines -> h, lines
      | _ -> print_endline (dump lines); assert false
    in
    parse h [] [] (Headers, lines)
end


module Mbox = struct
  let is_msg_start l =
    Str.string_match RegExp.top_from l 0


  let read_msg s =
    let rec read msg' = match Stream.peek s with
      | None -> Msg.parse (List.rev msg')
      | Some line when is_msg_start line -> Msg.parse (List.rev msg')
      | Some line -> Stream.junk s; read (line::msg')
    in
    match Stream.peek s with
    | None -> Stream.junk s; None
    | Some line when is_msg_start line -> Stream.junk s; Some (read [line])
    | Some _ -> assert false


  let msg_stream filename =
    let line_stream =
      if Filename.check_suffix filename ".gz" then
        let ic = GZ.open_in filename in
        Stream.from
        (fun _ -> try Some (GZ.input_line ic) with _ -> GZ.close_in ic; None)

      else
        let ic = open_in filename in
        Stream.from
        (fun _ -> try Some (input_line ic) with _ -> close_in ic; None)
    in
    Stream.from (fun _ -> read_msg line_stream)
end


module Options = struct
  type t =
    { mbox_file : string
    }


  let parse () =
    let usage = "" in
    let mbox_file = ref "" in
    let speclist = Arg.align
      [ ("-mbox-file", Arg.Set_string mbox_file, " Path to mbox file.")
      ]
    in
    Arg.parse speclist (fun _ -> ()) usage;

    if !mbox_file = "" then
      failwith "Need path to an mbox file."
    else
      { mbox_file = !mbox_file
      }
end


let main () =
  let o = Options.parse () in
  let mbox = Mbox.msg_stream o.Options.mbox_file in

  let bar_major = String.make 80 '=' in
  let bar_minor = String.make 80 '-' in

  Stream.iter
  ( fun msg ->
      print_endline bar_major;
      print_endline "| MSG";
      print_endline bar_major;

      print_endline bar_minor;
      print_endline "| HEADERS";
      print_endline bar_minor;
      List.iter (dump |- print_endline) msg.Msg.headers;

      print_endline bar_minor;
      print_endline "| BODY";
      print_endline bar_minor;
      List.iter print_endline msg.Msg.body;

      print_newline ()
  )
  mbox


let () = main ()
