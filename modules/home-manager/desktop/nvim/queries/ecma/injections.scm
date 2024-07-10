; ; https://github.com/bennypowers/template-literal-comments.nvim/blob/main/queries/ecma/injections.scm
; ((comment) @tlc.language
;            (#lua-match? @tlc.language "/%*%s*(%w+)%s*%*/")
;            (template_string) @injection.content
;            (#offset! @injection.content 0 1 0 -1)
;            (#set-template-literal-lang-from-comment! @tlc.language @injection.content))


((comment) @injection.language
  (#lua-match? @injection.language "/%*%s*(%w+)%s*%*/")
  (template_string) @injection.content
  (#offset! @injection.content 0 1 0 -1)
  (#gsub! @injection.language "/%*%s*(%w+)%s*%*/" "%1")
  (#set! injection.combined))

