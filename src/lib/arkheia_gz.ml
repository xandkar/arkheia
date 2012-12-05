include Gzip


let output_string (oc : out_channel) (s : string) : unit =
  String.iter (fun c -> output_char oc c) s

let output_line (oc : out_channel) (line : string) : unit =
  output_string oc line; output_char oc '\n'


let input_line (ic : in_channel) : string =
  let expected_chars = 100 in
  let buffer = Buffer.create expected_chars in
  let rec input_line = function
    | '\n' -> Buffer.contents buffer
    |   c  -> Buffer.add_char buffer c;
              input_line (input_char ic)
  in
  input_line (input_char ic)


let read_lines path =
  let ic = open_in path in
  let rec read lines' =
    try read ((input_line ic)::lines')
    with End_of_file -> List.rev lines'
  in
  let lines = try read [] with e -> close_in ic; raise e in
  close_in ic;
  lines
