open Batteries


module RegExp = struct
  let header_tag = Str.regexp "^[a-zA-Z-_]+: "
  let header_data = Str.regexp "^[ \t]+"
  let top_from =
    let space = " +" in
    let from = "^From" in
    let username = ".+" in
    let weekday = "[A-Z][a-z][a-z]" in
    let month = "[A-Z][a-z][a-z]" in
    let day = "[0-9]+" in
    let time = "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]" in
    let year = "[0-9][0-9][0-9][0-9]$" in
    Str.regexp
    ( String.concat space
      [ from
      ; username
      ; weekday
      ; month
      ; day
      ; time
      ; year
      ]
    )
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
  type headers =
    { top_from    : string
    ; from        : string
    ; date        : string
    ; subject     : string
    ; in_reply_to : string
    ; references  : string
    ; message_id  : string
    }

  type t =
    { headers : headers
    ; body    : string list
    }

  type section =
    Header | Body

  let is_head_tag l = Str.string_match RegExp.header_tag l 0
  let is_head_dat l = Str.string_match RegExp.header_data l 0

  let parse (lines : string list) : t =
    let pack_headers hs =
      let rec pack ht = function
        |                          [] -> ht
        | ("top_from",      data)::hs -> pack {ht with top_from    = data} hs
        | ("From: ",        data)::hs -> pack {ht with from        = data} hs
        | ("Date: ",        data)::hs -> pack {ht with date        = data} hs
        | ("Subject: ",     data)::hs -> pack {ht with subject     = data} hs
        | ("In-Reply-To: ", data)::hs -> pack {ht with in_reply_to = data} hs
        | ("References: ",  data)::hs -> pack {ht with references  = data} hs
        | ("Message-ID: ",  data)::hs -> pack {ht with message_id  = data} hs
        |                       h::hs -> print_endline (dump h); assert false
      in
      let ht =
        { top_from    = ""
        ; from        = ""
        ; date        = ""
        ; subject     = ""
        ; in_reply_to = ""
        ; references  = ""
        ; message_id  = ""
        }
      in
      pack ht hs
    in
    let parse_header h =
      if (Str.string_match RegExp.top_from h 0) then
        "top_from", h
      else
        match Str.full_split RegExp.header_tag h with
        | [Str.Delim tag; Str.Text data] -> tag, data
        | _ -> print_endline h; assert false
    in
    let rec parse h hs bs = function
      | Header, [] | Body, [] -> {headers=pack_headers hs; body=List.rev bs}
      | Header, ""::ls -> parse "" ((parse_header h)::hs) bs (Body, ls)
      | Header,  l::ls when is_head_tag l -> parse l ((parse_header h)::hs) bs (Header, ls)
      | Header,  l::ls when is_head_dat l -> parse (h^l) hs bs (Header, ls)
      | Header,  l::ls -> assert false
      | Body,    l::ls -> parse h hs (l::bs) (Body, ls)
    in
    let h, lines = match lines with l::ls -> l, ls | _ -> assert false in
    parse h [] [] (Header, lines)
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
      print_endline (dump msg.Msg.headers);

      print_endline bar_minor;
      print_endline "| BODY";
      print_endline bar_minor;
      List.iter print_endline msg.Msg.body;

      print_newline ()
  )
  mbox


let () = main ()
