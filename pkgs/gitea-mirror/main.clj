(require '[babashka.process :refer [shell]]
         '[babashka.http-client :as http]
         '[babashka.fs :as fs]
         '[clojure.string :as str]
         '[clojure.set :as set]
         '[cheshire.core :as json])

(defn parse-json [s] (json/parse-string s true))

(defn key-by
  [f coll]
  (zipmap (map f coll) coll))

(defn list-github-repos
  "https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-the-authenticated-user"
  [page]
  (->> {:headers {:Authorization (str "Bearer " (System/getenv "GITHUB_TOKEN"))}
        :query-params {:page page
                       :per_page 100
                       :type "owner"}}
       (http/get "https://api.github.com/user/repos")
       :body
       (parse-json)))

(defn list-gitea-repos
  [page]
  (->> {:headers {:Authorization (str "Bearer " (System/getenv "GITEA_TOKEN"))}
        :query-params {:page page}}
       (http/get "https://git.nregner.net/api/v1/user/repos")
       :body
       (parse-json)))

(defn migrate-repo
  "https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-the-authenticated-user"
  [{:keys [full_name]}]
  (->> {:headers {:Authorization (str "Bearer " (System/getenv "GITEA_TOKEN"))}
        :body (json/generate-string {:repo_name full_name
                                     :mirror true
                                     :private true})}
       (http/post "https://git.nregner.net/api/v1/repos/migrate")
       :body
       (parse-json)))

(defn lazy-page
  ([f] (lazy-page f 0))
  ([f n]
   (let [page (f n)]
     (lazy-cat page (when-not (empty? page)
                      (lazy-page f (inc n)))))))

(defn warn-non-mirror
  [github-repos gitea-repos]
  (for [non-mirror (->> (set (keys gitea-repos))
                        (set/intersection (set (keys github-repos)))
                        (map gitea-repos)
                        (remove :mirror))]
    (println "WARN:" non-mirror "is not a mirror")))

(defn -main
  [[attr]])

(when (= *file* (System/getProperty "babashka.file"))
  (-main *command-line-args*))

(comment
  (def gitea-repos (key-by (comp keyword :name) (lazy-page list-gitea-repos)))
  (def github-repos (->> (lazy-page list-github-repos)
                         (remove :fork)
                         (map #(select-keys % [:full_name :name :fork]))
                         (key-by (comp keyword :name))))
  (warn-non-mirror github-repos gitea-repos)
  (set/difference (set (keys github-repos))
                  (set (keys gitea-repos)))
  (-main "blink-cmp"))
