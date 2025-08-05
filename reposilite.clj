#!/usr/bin/env bb

(ns reposilite
  "http://sagittarius:8083/swagger"
  (:require [babashka.http-client :as http]
            [cheshire.core :as json])
  (:import [java.net URI]))

(defn request
  [opts]
  (http/request (merge opts {:headers (assoc (:headers opts) :Authorization "xBasic YWRtaW46dGFpbHNjYWxl")
                             :client (http/client {:follow-redirects :always})})))

(defn get-settings
  []
  (json/parse-string (:body (request {:uri "https://maven.nregner.net/api/settings/domain/maven"})) true))

(defn put-settings
  [settings]
  (json/parse-string (:body (request {:method :put
                                      :uri "https://maven.nregner.net/api/settings/domain/maven"
                                      :body (json/generate-string settings)}))))

(defn key-by
  [kf coll]
  (zipmap (map kf coll) coll))

(defn with-mirror
  [settings url]
  (let [by-id (key-by :id (:repositories settings))
        id (.getHost (URI. url))
        updated (update by-id id #(merge % {:id id
                                            :visibility "PUBLIC"
                                            :storagePolicy "PRIORITIZE_UPSTREAM_METADATA"
                                            :metadataMaxAge 900
                                            :proxied [{:reference url
                                                       :store true}]}))]
    {:repositories (vals updated)}))

(comment
  (def settings (get-settings))
  (put-settings (with-mirror settings "https://2.nregner.net")))
