; extends

(
  (line_comment) @injection.language
  . ; this is to make sure only adjacent comments are accounted for the injections
  [
    (raw_string_literal (string_content) @injection.content)
    (string_literal) @injection.content
  ]
  (#gsub! @injection.language "// %s*([%w%p]+)%s*" "%1")
  (#set! injection.combined)
)

(
  (block_comment) @injection.language
  . ; this is to make sure only adjacent comments are accounted for the injections
  [
    (raw_string_literal (string_content) @injection.content)
    (string_literal) @injection.content
  ]
  (#gsub! @injection.language "/%*%s*([%w%p]+)%s*%*/" "%1")
  (#set! injection.combined)
)
