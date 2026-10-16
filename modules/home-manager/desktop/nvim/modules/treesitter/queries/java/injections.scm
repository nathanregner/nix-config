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

(
  (annotation
    name: (_) @_name
    arguments: (annotation_argument_list
      (string_literal
        (_) @injection.content
      )
    )
  )
  (#match? @_name "NativeQuery|Formula")
  (#set! injection.language "sql")
)

; Markdown doc comments https://openjdk.org/jeps/467
((markdown_comment) @injection.content
  (#set! injection.language "markdown")
  (#set! injection.strip-prefix "///"))

; Block and inline tags (@param, {@link}, ...) that Markdown doesn't know about. The javadoc
; grammar expects the `///` prefix.
((markdown_comment) @injection.content
  (#set! injection.language "javadoc"))
