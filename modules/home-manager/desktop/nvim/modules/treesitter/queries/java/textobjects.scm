; extends

; annotation parameters - second and following (include preceding comma)
(annotation_argument_list
  "," @parameter.outer
  .
  (element_value_pair) @parameter.inner @parameter.outer)

; annotation parameters - first (include trailing comma if present)
(annotation_argument_list
  .
  (element_value_pair) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)
