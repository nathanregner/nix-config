; extends

; Map literals - show map keys in context
(map_lit) @context

; List literals - for function calls and special forms
(list_lit) @context

; Vector literals
(vec_lit) @context

; Set literals
(set_lit) @context

; ; Fold def* forms (defn, def, defmacro, defmethod, defmulti, defprotocol, etc.)
; ((list_lit
;   (sym_lit) @_def_keyword
;   (#match? @_def_keyword "^def")) @fold)
