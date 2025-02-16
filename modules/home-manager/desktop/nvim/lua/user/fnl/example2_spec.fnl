(local {: autoload} (require :nfnl.module))
; (local p (autoload :plenary.busted))
(local {: describe : it} (require :plenary.busted))
(local h (autoload :nvim-test.helpers))
; (import-macros {: describe : it} :tests.init-macros)
; (import-macros {: time} :tests.busted_macros)

(local c (autoload :nfnl.core))

(c.keys vim.g.sexp_filetypes)

(c.merge (c.assoc {} :a :b :c :asdfasdfasdfasdffa) (c.assoc {} :d 1))

(comment vim.v.lpath
  (c.keys (require :nvim-test.helpers)))

; (describe :test (it "another test" (print :test)))

(+ 1 2 3)
