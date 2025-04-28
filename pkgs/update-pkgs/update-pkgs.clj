(require '[babashka.process :refer [shell]])
(require '[clojure.string :as str])
(require '[cheshire.core :as json])

(defn git-root
  []
  (-> (:out (shell {:out :string} "git rev-parse --show-toplevel"))
      (str/trim)))

(defn eval-update-script
  [attr]
  (let [targets (-> (shell {:out :string}
                           "nix" "build"
                           ".#update-pkgs.passthru.targets"
                           "--no-link"
                           "--print-out-paths")
                    :out (str/trim)
                    (slurp)
                    (json/parse-string-strict))
        {:strs [name pname oldVersion updateScript]} (or (get targets attr) (throw (ex-info "Attr not found" targets)))]
    {:script updateScript
     :env {:UPDATE_NIX_NAME name
           :UPDATE_NIX_PNAME pname
           :UPDATE_NIX_OLD_VERSION oldVersion
           :UPDATE_NIX_ATTR_PATH attr}}))

(defn run-script
  [{:keys [script env]}]
  (:out (apply shell {:extra-env env
                      :dir (git-root)}
               script)))

(defn -main
  [[attr]]
  (let [update-script (eval-update-script attr)]
    (run-script update-script)))

(when (= *file* (System/getProperty "babashka.file"))
  (-main *command-line-args*))

(comment
  (-main "linux-orangepi-6_6-rk35xx")
  @(def update-script (eval-update-script "linux-orangepi-6_1-rk35xx"))
  (run-script update-script))
