; extends

(binding) @pair.inner

(binding_set
  (_) @_start
  .
  (binding)
  .
  (_) @_end
  (#make-range-exclusive! "pair.outer" @_start @_end)
)
