; extends

(jsx_element) @tag.outer
(jsx_self_closing_element) @tag.outer

(jsx_element
  open_tag: (_)
  .
  (_) @_start
  (_)? @_end
  .
  close_tag: (_)
  (#make-range! "tag.inner" @_start @_end))

(jsx_self_closing_element
  name: (_)
  .
  (_) @_start
  (_)? @_end
  .
  (#make-range! "tag.inner" @_start @_end))
