; extends

; ((comment) @tlc.language
;            (#lua-match? @tlc.language "/%*%s*(%w+)%s*%*/")
;            (template_string) @injection.content
;            (#offset! @injection.content 0 1 0 -1)
;            (#set-template-literal-lang-from-comment! @tlc.language @injection.content))

; ((command
;    name: (command_name (word) @_name)
;    argument: (string (string_content) @injection.content)
;    (#eq? @_name "jq")
;    (#set! injection.language "jq")))

; jq --args 'filter'
((command
  name: (command_name) @_command
  argument: [
    (string) @injection.content
    (concatenation
      (string) @injection.content)
    (raw_string) @injection.content
    (concatenation
      (raw_string) @injection.content)
  ])
  (#eq? @_command "jq")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "jq"))

  ; (redirected_statement ; [2, 0] - [4, 3]
  ;   body: (command ; [2, 0] - [2, 14]
  ;     name: (command_name ; [2, 0] - [2, 2]
  ;       (word)) ; [2, 0] - [2, 2]
  ;     argument: (word) ; [2, 3] - [2, 11]
  ;     argument: (word)) ; [2, 12] - [2, 14]
  ;   redirect: (heredoc_redirect ; [2, 15] - [4, 3]
  ;     (heredoc_start) ; [2, 17] - [2, 20]
  ;     (heredoc_body) ; [3, 0] - [4, 0]
  ;     (heredoc_end)))) ; [4, 0] - [4, 3]

