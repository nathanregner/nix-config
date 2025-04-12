(require '[babashka.process :refer [shell]])
(require '[babashka.fs :as fs])
(require '[clojure.string :as str])
(require '[cheshire.core :as json])

(defn git-root
  []
  (-> (:out (shell {:out :string} "git rev-parse --show-toplevel"))
      (str/trim)))

(defn eval-update-script
  [attr]
  (let [targets (->> (shell {:out :string}
                            "nix" "build"
                            "--no-link"
                            "--print-out-paths"
                            ".#update-pkgs.passthru.targets")
                     :out
                     (str/trim)
                     (slurp)
                     (json/parse-string-strict))
        {:strs [name pname oldVersion updateScript]}
        (or (get targets attr) (throw (ex-info (str "Attr not found: \"" attr "\"") targets)))]
    {:script updateScript
     :env {:UPDATE_NIX_NAME name
           :UPDATE_NIX_PNAME pname
           :UPDATE_NIX_OLD_VERSION oldVersion
           :UPDATE_NIX_ATTR_PATH attr}}))

(defn nix-build
  [{[executable] :script}]
  (shell "nix" "build" "--no-link" executable))

(defn run-script
  [{:keys [env] [cmd & args] :script}]
  ; (fs/copy cmd (fs/file-name cmd) {:replace-existing true})
  (apply shell {:extra-env env
                :out :string
                :err :string
                :dir (git-root)}
         "bash"
         "-c"
         (str "./" (fs/file-name cmd)) args))

(defn -main
  [[attr]]
  (let [attr (or attr (throw (ex-info "Must provide an attr to update" {})))
        update-script (eval-update-script attr)]
    ; (nix-build update-script)
    (run-script update-script)))

(when (= *file* (System/getProperty "babashka.file"))
  (-main *command-line-args*))

(comment
  (-main "blink-cmp")
  @(def update-script (eval-update-script "preprocess_cancellation"))
  (:script update-script)
  (run-script update-script)
  (nix-build update-script))
