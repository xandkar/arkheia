module GZ     = Mldb_gz
module RegExp = Mldb_regexp


let is_msg_start l =
  Str.string_match RegExp.top_from l 0


let read_msg s =
  let rec read msg' = match Stream.peek s with
    | None -> String.concat "\n" (List.rev msg')
    | Some line when is_msg_start line -> String.concat "\n" (List.rev msg')
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
