open Batteries


module RegExp = Arkheia_regexp


exception Mkdir_failure of int * string


let mkpath path : unit =
  match Sys.command ("mkdir -p " ^ path) with
  | 0 -> ()
  | n -> raise (Mkdir_failure (n, path))


let histogram lst =
  let hist = Hashtbl.create 1 in
  List.iter
  ( fun e ->
      try let i = Hashtbl.find hist e in Hashtbl.replace hist e (i + 1)
      with Not_found -> Hashtbl.add hist e 1
  )
  lst;
  hist


let strip s = s
  |> Str.replace_first RegExp.spaces_lead ""
  |> Str.replace_first RegExp.spaces_trail ""


let lines_of (path : string) : string list =
  let ic = open_in path in
  let rec read ls' =
    try read ((input_line ic)::ls')
    with End_of_file -> List.rev ls'
  in
  let lines = try read [] with e -> close_in ic; raise e in
  close_in ic;
  lines


let hash_of_string s =
  Digest.to_hex (Digest.string s)
