; extends

(
  (line_comment) @injection.language
  . ; this is to make sure only adjacent comments are accounted for the injections
  [
    (string_literal (multiline_string_fragment) @injection.content)
    (string_literal (string_fragment) @injection.content)
  ]
  (#gsub! @injection.language "// %s*([%w%p]+)%s*" "%1")
  (#set! injection.combined)
)

(
  (block_comment) @injection.language
  . ; this is to make sure only adjacent comments are accounted for the injections
  [
    (string_literal (multiline_string_fragment) @injection.content)
    (string_literal (string_fragment) @injection.content)
  ]
  (#gsub! @injection.language "/%*%s*([%w%p]+)%s*%*/" "%1")
  (#set! injection.combined)
)
