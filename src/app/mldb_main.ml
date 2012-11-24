open Batteries
open Printf


module M = Mldb


type options =
  { mbox_file    : string
  ; list_name    : string
  ; dir_messages : string
  ; dir_index    : string
  }


let parse_options () =
  let usage = "" in
  let mbox_file = ref "" in
  let data_dir  = ref "data" in
  let list_name = ref "" in

  let speclist = Arg.align
    [ ("-mbox-file", Arg.Set_string mbox_file, " Path to mbox file.")
    ; ("-list-name", Arg.Set_string list_name, " Name of the mailing list.")
    ]
  in

  Arg.parse speclist (fun _ -> ()) usage;

  if !mbox_file = "" then
    failwith "Need path to an mbox file."

  else if !list_name = "" then
    failwith "Need name of the mailing list."

  else
    let data_dir =
      String.concat "/" [!data_dir; "lists"; !list_name]
    in
    { mbox_file    = !mbox_file
    ; list_name    = !list_name
    ; dir_messages = String.concat "/" [data_dir; "messages"]
    ; dir_index    = String.concat "/" [data_dir; "index"]
    }


let main () =
  let opt = parse_options () in
  let msg_stream = M.Mbox.msg_stream opt.mbox_file in

  M.Index.build opt.dir_index opt.dir_messages msg_stream


let () = main ()
