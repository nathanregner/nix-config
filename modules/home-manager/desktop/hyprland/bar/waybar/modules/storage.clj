(require '[babashka.process :refer [shell]])
(require '[clojure.string :as str])
(require '[cheshire.core :as json])

(defn df
  []
  (let [[filesystem size used avail use% mounted]
        (-> (:out (shell {:out :string} "df -h -P -l /"))
            (str/split-lines)
            (last)
            (str/split #" +"))]
    {:filesystem filesystem
     :size size
     :used used
     :avail avail
     :use% (Integer/parseInt (second (re-matches #"(.*)%" use%)))
     :mounted mounted}))

(defn format-json
  [{:keys [filesystem size used avail use% mounted]}]
  {:text avail
   :percentage use%
   :class (condp <= use%
            90 "critical"
            80 "warning"
            "")
   :tooltip (str "Filesystem: " filesystem "\n"
                 "Size: " size "\n"
                 "Used: " used "\n"
                 "Available: " avail "\n"
                 "Use: " use% "%\n"
                 "Mounted On: " mounted)})

(defn -main
  []
  (println (json/generate-string (format-json (df)))))

(when (= *file* (System/getProperty "babashka.file"))
  (-main))

(comment
  (-main)
  (format-json (df)))
