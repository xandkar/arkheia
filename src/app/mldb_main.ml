open Batteries
open Printf


module M = Mldb


type options =
  { mbox_file    : string
  ; list_name    : string
  ; dir_messages : string
  ; dir_index    : string
  ; operation    : string
  ; query        : string
  }


let parse_options () =
  let executable = Sys.argv.(0) in
  let usage = executable ^ " -operation [ build_index ]\n" in

  let mbox_file = ref "" in
  let data_dir  = ref "data" in
  let list_name = ref "" in
  let operation = ref "" in
  let query     = ref "" in

  let speclist = Arg.align
    [ ("-mbox-file", Arg.Set_string mbox_file, " Path to mbox file.")
    ; ("-list-name", Arg.Set_string list_name, " Name of the mailing list.")
    ; ("-operation", Arg.Set_string operation, " Operation to perform.")
    ; ("-query",     Arg.Set_string query,     " Search query (if operation is 'search').")
    ]
  in

  Arg.parse speclist (fun _ -> ()) usage;

  if !operation = "" then
    failwith "Please specify an operation to perform."

  else if !operation = "search" && !query = "" then
    failwith "Please specify -query 'search terms' ."

  else if !mbox_file = "" then
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
    ; operation    = !operation
    ; query        = String.lowercase !query
    }


let main () =
  let opt = parse_options () in

  match opt.operation with
  | "build_index" ->
    let msg_stream = M.Mbox.msg_stream opt.mbox_file in
    M.Index.build opt.dir_index opt.dir_messages msg_stream

  | "search" ->
    let index = M.Index.load opt.dir_index in
    let query = List.hd (Str.split M.RegExp.white_spaces opt.query) in
    let results = M.Index.lookup index query in
    print_endline (dump results)

  | other -> failwith ("Invalid operation: " ^ other)


let () = main ()
