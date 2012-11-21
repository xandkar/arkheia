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


module Mbox = struct
  let regexp_from = Str.regexp "^From\ +"


  let is_msg_start l =
    Str.string_match regexp_from l 0


  let read_msg s =
    let rec read msg' = match Stream.peek s with
      | None -> List.rev msg'
      | Some line when is_msg_start line -> List.rev msg'
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

  let bar = String.make 80 '=' in

  Stream.iter
  ( fun msg ->
      print_endline bar;
      List.iter
      (fun m -> print_endline (dump m))
      msg
  )
  mbox


let () = main ()
