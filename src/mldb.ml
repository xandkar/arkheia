open Batteries


module GZ = struct include Gzip
  let output_line (oc : out_channel) (line : string) : unit =
    String.iteri (fun _ c -> output_char oc c) line;
    output_char oc '\n'


  let input_line (ic : in_channel) : string =
    let expected_chars = 210 in  (* Average number of chars per log line *)
    let buffer = Buffer.create expected_chars in
    let rec input_line = function
      | '\n' -> Buffer.contents buffer
      |   c  -> Buffer.add_char buffer c;
                input_line (input_char ic)
    in
    input_line (input_char ic)
end


module Msg = struct
  type t =
    { headers : string list
    ; body    : string list
    }

  type section =
    Header | Body

  let regexp_head_tag = Str.regexp "^[a-zA-Z-_]+: "
  let regexp_head_dat = Str.regexp "^[ \t]+"

  let is_head_tag l = Str.string_match regexp_head_tag l 0
  let is_head_dat l = Str.string_match regexp_head_dat l 0

  let parse (lines : string list) : t =
    let rec parse h hs bs = function
      | Header, [] | Body, [] -> {headers = List.rev hs; body = List.rev bs}
      | Header,  ""::ls                    -> parse "" (h::hs) bs (Body, ls)
      | Header,   l::ls when is_head_tag l -> parse l (h::hs) bs (Header, ls)
      | Header,   l::ls when is_head_dat l -> parse (h^l) hs bs (Header, ls)
      | Header,   l::ls -> assert false
      | Body,     l::ls -> parse h hs (l::bs) (Body, ls)
    in
    let h, lines = match lines with l::ls -> l, ls | _ -> assert false in
    parse h [] [] (Header, lines)
end


module Mbox = struct
  let regexp_from =
    let space = " +" in
    let weekday = "[A-Z][a-z][a-z]" in
    let month = "[A-Z][a-z][a-z]" in
    let day = "[0-9]+" in
    let time = "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]" in
    let year = "[0-9][0-9][0-9][0-9]$" in
    Str.regexp
    ( String.concat space
      [ "^From .+"
      ; weekday
      ; month
      ; day
      ; time
      ; year
      ]
    )


  let is_msg_start l =
    Str.string_match regexp_from l 0


  let read_msg s =
    let rec read msg' = match Stream.peek s with
      | None -> Msg.parse (List.rev msg')
      | Some line when is_msg_start line -> Msg.parse (List.rev msg')
      | Some line -> Stream.junk s; read (line::msg')
    in
    match Stream.peek s with
    | None -> None
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
      List.iter (fun h -> print_endline h) msg.Msg.headers;

      print_endline bar_minor;
      print_endline "| BODY";
      print_endline bar_minor;
      List.iter print_endline msg.Msg.body;

      print_newline ()
  )
  mbox


let () = main ()
