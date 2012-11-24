type t =
  { top_from    : string
  ; from        : string
  ; date        : string
  ; subject     : string
  ; in_reply_to : string
  ; references  : string list
  ; id          : string
  ; body        : string
  }


val parse : string -> t

val save : string -> string -> string -> unit
