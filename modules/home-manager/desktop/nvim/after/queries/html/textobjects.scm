; extends

(element) @tag.outer

(element
  (start_tag)
  .
  (_) @_start
  (_)? @_end
  .
  (end_tag)
  (#make-range! "tag.inner" @_start @_end))

(element
  (self_closing_tag
    (tag_name)
    .
    (_) @_start
    (_)? @_end
    .
    (#make-range! "tag.inner" @_start @_end)))
