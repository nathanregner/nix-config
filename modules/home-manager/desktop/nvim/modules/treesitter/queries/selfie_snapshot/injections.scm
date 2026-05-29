((block
  (header (filename) @injection.language)
  (content) @injection.content)
 (#gsub! @injection.language ".*%.(%w+)$" "%1")
 (#set! injection.combined))
