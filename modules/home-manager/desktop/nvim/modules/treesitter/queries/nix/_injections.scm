; extends

; ((apply_expression
;   function: (apply_expression
;     function: (apply_expression
;       function: (_) @_func))
;   argument: [
;     (string_expression
;       ((string_fragment) @injection.content
;         (#set! injection.language "python")))
;     (indented_string_expression
;       ((string_fragment) @injection.content
;         (#set! injection.language "python")))
;   ])
;   (#match? @_func "(^|\\.)write(PyPy|Python)[23](Bin)?$")
;   (#set! injection.combined))
