; https://github.com/bennypowers/template-literal-comments.nvim/blob/main/queries/ecma/injections.scm
; ((comment) @tlc.language
;            (#lua-match? @tlc.language "/%*%s*(%w+)%s*%*/")
;            (#set-template-literal-lang-from-comment! @tlc.language @injection.content)
;            (template_string) @injection.content
;            (#offset! @injection.content 0 1 0 -1))
