type out_channel

type in_channel


val open_out_chan : ?level:int -> Pervasives.out_channel -> out_channel

val open_out : ?level:int -> string -> out_channel

val open_in : string -> in_channel

val close_out : out_channel -> unit

val close_in : in_channel -> unit

val output_string : out_channel -> string -> unit

val output_line : out_channel -> string -> unit

val input_line : in_channel -> string
