open Batteries
open Printf


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

  Utils.mkpath opt.dir_messages;
  Utils.mkpath opt.dir_index;

  Stream.iter
  ( fun msg_txt ->
    let msg = Msg.parse msg_txt in
    Msg.save opt.dir_messages msg_txt msg.Msg.id;

    let tokens = Index.count_and_positions (Index.tokenize msg.Msg.body) in

    List.iter
    ( fun (word, (count, positions)) ->
        let positions = String.concat "," (List.map string_of_int positions) in
        let data = (sprintf "%s|%d|%s\n" msg.Msg.id count positions) in

        let dir = Filename.concat opt.dir_index (string_of_char word.[0]) in
        Utils.mkpath dir;
        let word_file = Filename.concat dir (word ^ ".csv.gz") in
        let modes = [Open_append; Open_creat; Open_text] in
        let perms = 0o666 in

        let oc = Pervasives.open_out_gen modes perms word_file in
        let oc_gz = GZ.open_out_chan oc in

        GZ.output_string oc_gz data;

        GZ.close_out oc_gz;
        Pervasives.close_out oc
    )
    tokens;

    print_endline (dump tokens);
    print_newline ();
    print_newline ()
  )
  (Mbox.msg_stream opt.mbox_file)


let () = main ()
