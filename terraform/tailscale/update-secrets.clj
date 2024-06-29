#!/usr/bin/env bb

(require '[babashka.process :refer [shell]])
(require '[cheshire.core :as json])
(require '[clojure.string :as str])
(require '[clojure.java.io :as io])

(def script-root (.getParentFile (io/file *file*)))

(defn git-root
  []
  (-> (:out (shell {:out :string
                    :dir script-root} "git rev-parse --show-toplevel"))
      (str/trim)))

(defn terraform-output
  []
  (as-> (:out (shell {:out :string
                      :dir script-root} "terraform output -json")) $
    (json/parse-string $ true)
    (reduce-kv (fn [acc k {:keys [value]}] (assoc acc k value)) {} $)))

(defn sops-set
  [path value]
  (->> (str "sops --set '"
            (str/join (map (comp json/generate-string vector) path))
            " "
            (json/generate-string value)
            "' modules/nixos/server/services/secrets.yaml")
       (shell {:dir (git-root)})))

(defn -main
  []
  (sops-set [:tailscale] (terraform-output)))

(when (= *file* (System/getProperty "babashka.file"))
  (-main))

(comment
  (-main))
