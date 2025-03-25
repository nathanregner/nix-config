; extends

(element) @tag.outer

(element
  (start_tag) @_start
  (end_tag) @_end
  (#make-range-exclusive! "tag.inner" @_start @_end))

