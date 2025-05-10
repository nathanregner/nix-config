(ns update-pkgs
  (:require [babashka.fs :as fs]
            [babashka.process :refer [shell]]
            [cheshire.core :as json]
            [clojure.string :as str]
            [taoensso.timbre :as timbre]))

(defn git-root
  []
  (-> (:out (shell {:out :string} "git rev-parse --show-toplevel"))
      (str/trim)))

(defn list-targets
  []
  (-> (shell {:out :string}
             "nix" "build"
             ".#update-pkgs.passthru.targets"
             "--no-link"
             "--print-out-paths")
      :out (str/trim)
      (slurp)
      (json/parse-string-strict)))

(defn get-update-script
  [targets attr]
  (let [{:strs [name pname oldVersion updateScript]} (or (get targets attr) (throw (ex-info "Attr not found" {:targets (keys targets)})))]
    {:script updateScript
     :env {:UPDATE_NIX_NAME name
           :UPDATE_NIX_PNAME pname
           :UPDATE_NIX_OLD_VERSION oldVersion
           :UPDATE_NIX_ATTR_PATH attr}}))

(defn run-script
  [{[script & args] :script :keys [env]}]
  (timbre/info "Updating " (:UPDATE_NIX_NAME env) "...")
  ; (fs/with-temp-dir [dir {}]
  (let [dir (git-root)]
    ; (shell "git worktree add" dir)
    ; (let [temp-script (fs/path (fs/file dir) (fs/file-name script))]
    ; (fs/copy script temp-script {:replace-existing true})
    ; )
    (:out (apply shell {:extra-env env
                        :dir dir
                        :out :string}
                 (conj args script)))))

(defn -main
  [[attr]]
  (let [targets (list-targets)
        errors (->> (or (some-> attr (vector))
                        (keys targets))
                    (mapv #(try (run-script (get-update-script targets %))
                                (catch Exception e
                                  (timbre/error attr e)
                                  e))))]
    (when (some #(instance? Exception %) errors)
      (System/exit 1))))

(when (= *file* (System/getProperty "babashka.file"))
  (-main *command-line-args*))

(comment
  (timbre/error "asdfasdfasd" (ex-info "asdf" {}))
  (-main [])
  @(def targets (dissoc (list-targets)
                        "linux-orangepi-6_1-rk35xx"))
  (map (comp run-script (partial get-update-script targets))
       (keys targets))
  @(def update-script (get-update-script (list-targets) "pin-github-action"))
  @(def update-script (get-update-script (list-targets) "linux-orangepi-6_1-rk35xx"))
  (fs/file-name (first (:script update-script)))
  (-main ["node-exporter-full"])
  (run-script update-script))
