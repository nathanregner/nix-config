; extends

(jsx_element) @tag.outer
(jsx_self_closing_element) @tag.outer

(jsx_element
  open_tag: (_) @_start
  close_tag: (_) @_end
  (#make-range-exclusive! "tag.inner" @_start @_end))
