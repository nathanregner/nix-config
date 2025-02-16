;; [nfnl-macro]

; (local p (autoload :plenary.busted))
; (fn describe [...] ; (local p (require :plenary.busted))
;   `(p.describe (fn [] ,...)))
;
; (fn it [...] ; (local p (require :plenary.busted))
;   `(p.it (fn [] ,...)))

{: describe : it}

(fn time [...]
  `(let [start# (vim.loop.hrtime)
         result# (do
                   ,...)
         end# (vim.loop.hrtime)]
     (print (.. "Elapsed time: " (/ (- end# start#) 1000000) " msecs"))
     result#))

{: time}
