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
  (let [{:strs [name pname oldVersion updateScript]}
        (->> (str ".#githubActions.nixUpdate.pkgs." attr)
             (shell {:out :string} "nix" "eval" "--json")
             :out
             (json/parse-string-strict))]
    {:script updateScript
     :env {:UPDATE_NIX_NAME name
           :UPDATE_NIX_PNAME pname
           :UPDATE_NIX_OLD_VERSION oldVersion
           :UPDATE_NIX_ATTR_PATH attr}}))

(defn nix-build
  [{[executable] :script}]
  (shell "nix" "build" "--no-link" executable))

(defn with-args
  [script]
  (if (= (fs/file-name (first script)) "nix-update")
    (conj script "--flake" "--commit")
    script))

(defn run-script
  [{:keys [script env]}]
  (:out (apply shell {:extra-env env
                      :dir (git-root)}
               (with-args script))))

(defn -main
  [[attr]]
  (let [update-script (eval-update-script attr)]
    (nix-build update-script)
    (run-script update-script)))

(when (= *file* (System/getProperty "babashka.file"))
  (-main *command-line-args*))

(comment
  (-main "blink-cmp")
  (def update-script (eval-update-script "blink-cmp"))
  (with-args (:script update-script))
  (run-script update-script)
  (nix-build update-script))
