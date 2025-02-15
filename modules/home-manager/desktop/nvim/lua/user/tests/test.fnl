(local {: describe : it : before_each : after_each} (require :plenary.busted))
(local c (autoload :nfnl.core))
(local p (autoload :plenary.busted.test))

;; @module "lazy"
;; @type LazySpec
(c.keys vim.g.sexp_filetypes)

(c.merge (c.assoc {} :a :b :c :asdfasdfasdfasdffa) (c.assoc {} :d 1))

(+ 1 2 3)

(describe "test"
  (it "works"
       (fn []
         (error "test")
        (print "test"))))
