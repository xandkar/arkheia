open Batteries
open Printf


type options =
  { mbox_file    : string
  ; list_name    : string
  ; dir_messages : string
  ; dir_index    : string
  ; operation    : string
  ; query        : string
  ; srv_addr     : string
  ; srv_port     : int
  }


let parse_options () =
  let executable = Sys.argv.(0) in
  let usage = executable ^ " -operation [ build_index ]\n" in

  let mbox_file = ref "" in
  let data_dir  = ref "data" in
  let list_name = ref "" in
  let operation = ref "" in
  let query     = ref "" in
  let srv_addr  = ref "127.0.0.1" in
  let srv_port  = ref 8888 in

  let speclist = Arg.align
    [ ("-mbox-file", Arg.Set_string mbox_file, " Path to mbox file.")
    ; ("-data-dir",  Arg.Set_string data_dir,  " Path to root data directory.")
    ; ("-list-name", Arg.Set_string list_name, " Name of the mailing list.")
    ; ("-operation", Arg.Set_string operation, " Operation to perform.")
    ; ("-query",     Arg.Set_string query,     " Search query (if operation is 'search').")
    ; ("-srv-addr",  Arg.Set_string srv_addr,  " Server address.")
    ; ("-srv-port",  Arg.Set_int    srv_port,  " Server port.")
    ]
  in

  Arg.parse speclist (fun _ -> ()) usage;

  match !operation, !query, !mbox_file, !list_name with
  |            "",  _,  _,  _ -> failwith "Please specify an operation to perform."
  |      "search", "",  _,  _ -> failwith "Please specify -query 'search terms' ."
  | "build_index",  _, "",  _ -> failwith "Need path to an mbox file."
  |             _,  _,  _, "" -> failwith "Need name of the mailing list."
  |             _,  _,  _,  _ ->
    let data_dir =
      String.concat "/" [!data_dir; "lists"; !list_name]
    in
    { mbox_file    = !mbox_file
    ; list_name    = !list_name
    ; dir_messages = String.concat "/" [data_dir; "messages"]
    ; dir_index    = String.concat "/" [data_dir; "index"]
    ; operation    = !operation
    ; query        = String.lowercase !query
    ; srv_addr     = !srv_addr
    ; srv_port     = !srv_port
    }


let index_load dir =
  print_endline "LOADING INDEX...";
  let start_time_cpu, start_time_wall = Sys.time (), Unix.gettimeofday () in
  let index = Mldb.Index.load dir in
  let time_cpu, time_wall =
    (Sys.time ()) -. start_time_cpu,
    (Unix.gettimeofday ()) -. start_time_wall
  in
  printf "LOAD TIME,  CPU: %f\n" time_cpu;
  printf "LOAD TIME, WALL: %f\n" time_wall;
  index


let index_search index query =
  let start_time = Sys.time () in
  let results = Mldb.Index.lookup index query in
  let time_to_query = (Sys.time ()) -. start_time in
  printf "LOOKUP TIME: %f\n" time_to_query;
  results


let serve index addr port =
  print_endline "STARTING SERVER";

  let server ic oc =
    let rec serve eof = if eof then () else
      output_string oc "? ";
      flush oc;
      let query, eof = try input_line ic, eof with End_of_file -> "", true in
      let results = match index_search index query with
        | [] -> "No match found."
        | rs -> String.concat "\n" rs
      in
      output_string oc (sprintf "=>\n%s\n\n\n" results);
      flush oc;
      serve eof
    in
    serve false
  in

  let inet_addr = Unix.inet_addr_of_string addr in
  Unix.establish_server server (Unix.ADDR_INET (inet_addr, port))


let main () =
  let opt = parse_options () in

  match opt.operation with
  | "build_index" ->
    let msg_stream = Mldb.Mbox.msg_stream opt.mbox_file in
    Mldb.Index.build opt.dir_index opt.dir_messages msg_stream

  | "serve" ->
    serve (index_load opt.dir_index) opt.srv_addr opt.srv_port

  | "search" ->
    ( match index_search (index_load opt.dir_index) opt.query with
      | [] -> print_endline "No match found."
      | rs -> print_endline (String.concat "\n" rs)
    )

  | other -> failwith ("Invalid operation: " ^ other)


let () = main ()
