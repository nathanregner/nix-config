; extends

(
  (comment (comment_content) @injection.language)
  . ; this is to make sure only adjacent comments are accounted for the injections
  (string (string_content) @injection.content)
  (#gsub! @injection.language "%s*([%w%p]+)%s*" "%1")
  (#set! injection.combined)
)
