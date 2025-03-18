; extends

; ((comment) @tlc.language
;            (#lua-match? @tlc.language "/%*%s*(%w+)%s*%*/")
;            (template_string) @injection.content
;            (#offset! @injection.content 0 1 0 -1)
;            (#set-template-literal-lang-from-comment! @tlc.language @injection.content))

((comment) @_gql_comment
  (#eq? @_gql_comment "/* GraphQL */")
  (template_string (string_fragment) @injection.content)
  (#set! injection.language "graphql"))

