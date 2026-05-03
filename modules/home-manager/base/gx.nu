#!/usr/bin/env nu

let sel = $in | str trim
let open_cmd = if (which xdg-open | is-not-empty) { "xdg-open" } else { "open" }

if ($sel =~ '^https?://|^www\.') {
  ^$open_cmd $sel
} else if ($sel | path exists) {
  ^$open_cmd $sel
} else {
  let query = $sel | url encode
  ^$open_cmd $"https://www.google.com/search?q=($query)"
}
