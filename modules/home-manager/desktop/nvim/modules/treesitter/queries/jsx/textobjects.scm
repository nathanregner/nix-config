; extends

(jsx_element) @tag.outer

(jsx_self_closing_element) @tag.outer

(jsx_element
  open_tag: _
  _* @tag.inner
  close_tag: _
)

(jsx_attribute) @parameter.outer

(jsx_attribute
  (property_identifier)
  (_
    (_) @parameter.inner
  )
)
