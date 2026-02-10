(apply_expression
  function: (_) @_func
  argument:
  (attrset_expression
    (binding_set
      (_)*
      (binding
        attrpath: (attrpath (identifier) @_owner)
        expression: (string_expression (string_fragment) @owner))
      (_)*
      (binding
        attrpath: (attrpath
                    (identifier) @_repo)
        expression: (string_expression (string_fragment) @repo))
      ))
  (#match? @_func "(^|\\.)fetchFromGitHub$")
  (#match? @_owner "owner")
  (#match? @_repo "repo")
  (#set! owner @owner)
  (#set! repo @repo)) @fetchFromGitHub
