let spaces_lead = Str.regexp "^ +"
let spaces_trail = Str.regexp " +$"
let white_spaces = Str.regexp "[ \t]+"
let white_spaces_and_newlines = Str.regexp "[\n \t]+"
let newline = Str.regexp "\n"

let not_indexable_chars = Str.regexp "[>/]+"

let top_from =
  let from = "^From" in
  let username = ".+" in
  let weekday = "[A-Z][a-z][a-z]" in
  let month = "[A-Z][a-z][a-z]" in
  let day = "[0-9]+" in
  let time = "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]" in
  let year = "[0-9][0-9][0-9][0-9]$" in
  Str.regexp
  ( String.concat " +"
    [ from
    ; username
    ; weekday
    ; month
    ; day
    ; time
    ; year
    ]
  )

let header_tag = Str.regexp "^[a-zA-Z-_]+: "
let header_data = Str.regexp "^[ \t]+"

let angle_bracket_open_lead = Str.regexp "^<"
let angle_bracket_close_trail = Str.regexp ">$"
let between_angle_bracketed_items = Str.regexp ">[ \t\n]+<"

let comma = Str.regexp ","
