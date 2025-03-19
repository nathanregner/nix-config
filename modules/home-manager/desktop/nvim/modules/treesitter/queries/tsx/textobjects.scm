; extends

((jsx_element
   open_tag: (_) @tag.outer.start
   close_tag: (_) @tag.outer.end) @tag.outer
 (#set! "start" @tag.outer.start)
 (#set! "end" @tag.outer.end))

(jsx_self_closing_element) @tag.outer

(jsx_element
  open_tag: (_) @_start
  close_tag: (_) @_end
  (#make-range-exclusive! "tag.inner" @_start @_end))
