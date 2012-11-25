type t


val build : string -> string -> string Stream.t -> unit

val load : string -> t

val lookup : t -> string -> (string * int) list
