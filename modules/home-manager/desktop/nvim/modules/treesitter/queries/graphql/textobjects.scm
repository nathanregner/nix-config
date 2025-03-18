; parameters
(variable_definition) @parameter.outer

; FIXME: swap not working
; FIXME: da a, b[, c]
(variable_definition
  .
  (variable) @_start
  .
  [((type) @_end . (comma)?)
   ((type) @_end . (directives) @_end . (comma)?)]
  .
  (#make-range! "parameter.inner" @_start @_end))

; arguments
(arguments
  (argument) @parameter.inner
  .
  (comma)? @_end
  (#make-range! "parameter.outer" @parameter.inner @_end))
