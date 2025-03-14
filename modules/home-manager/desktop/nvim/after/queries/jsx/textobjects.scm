; extends

(jsx_element) @tag.outer
(jsx_self_closing_element) @tag.outer

; FIXME: doesn't work on empty tags
((jsx_element
   open_tag: (_)
   .
   (_) @_start
   (_)? @_end
   .
   close_tag: (_))
  (#make-range! "tag.inner" @_start @_end))
