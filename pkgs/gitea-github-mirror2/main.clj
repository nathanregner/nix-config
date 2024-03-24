(defn -main []
  (println "Hello, World!"))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))
