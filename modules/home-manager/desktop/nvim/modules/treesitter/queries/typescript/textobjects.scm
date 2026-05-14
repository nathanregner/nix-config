; extends

; type parameters - second and following (include preceding comma)
(type_parameters
  "," @parameter.outer
  .
  (type_parameter) @parameter.inner @parameter.outer)

; type parameters - first (include trailing comma if present)
(type_parameters
  .
  (type_parameter) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)
