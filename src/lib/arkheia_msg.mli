type t =
  { top_from    : string
  ; from        : string
  ; date        : string
  ; subject     : string
  ; in_reply_to : string
  ; references  : string list
  ; id          : string
  ; id_orig     : string
  ; body        : string
  }


val parse : string -> t

val save_as_txt : string -> string -> string -> unit

val save_as_bin : string -> t -> unit
