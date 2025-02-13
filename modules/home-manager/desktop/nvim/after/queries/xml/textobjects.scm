; extends

(element) @tag.outer

(element
  (content) @tag.innner)

(element
  (EmptyElemTag
    .
    (Name)
    .
    (_) @_start
    (_)? @_end
    .
    (#make-range! "tag.inner" @_start @_end)))
