#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[babashka.process :refer [shell]]
         '[clojure.java.io :as io]
         '[clojure.string :as str])

(def rate-limit-file "/tmp/claude-notify-last")
(def rate-limit-seconds 30)

(defn check-rate-limit
  []
  (if (.exists (io/file rate-limit-file))
    (let [last-notify (parse-long (slurp rate-limit-file))
          current-time (quot (System/currentTimeMillis) 1000)
          time-diff (- current-time last-notify)]
      (>= time-diff rate-limit-seconds))
    true))

(defn update-rate-limit!
  []
  (spit rate-limit-file (str (quot (System/currentTimeMillis) 1000))))

(defn check-tmux-focus
  []
  (when (System/getenv "TMUX")
    (try
      (let [result (shell {:out :string :continue true}
                          "tmux display-message -p '#{pane_active}'")
            output (-> result :out str/trim)]
        (= "1" output))
      (catch Exception _ false))))

(defn check-alacritty-focus
  []
  (try
    (let [result (shell {:out :string :continue true}
                        "osascript -e 'tell application \"System Events\" to get name of first application process whose frontmost is true'")
          output (-> result :out str/trim)]
      (= "Alacritty" output))
    (catch Exception _ false)))

(defn get-tmux-info
  []
  (when (System/getenv "TMUX")
    (try
      (let [result (shell {:out :string :continue true}
                          "tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'")]
        (str/trim (:out result)))
      (catch Exception _ "terminal"))
    "terminal"))

(defn send-notification!
  [title message subtitle]
  (try
    (shell {:out :string}
           (format "osascript -e 'display notification \"%s\" with title \"%s\" subtitle \"%s\"'"
                   message title subtitle))
    (catch Exception e
      (println "Failed to send notification:" (.getMessage e)))))

(defn handle-user-prompt-submit
  [session-info]
  (if (check-rate-limit)
    (do
      (send-notification! "Claude Code" "Waiting for your input" (str "Session: " session-info))
      (update-rate-limit!)
      {:systemMessage "Notification sent (unfocused)"})
    {:systemMessage "Notification skipped (rate limited)"}))

(defn handle-permission-request
  [input session-info]
  (let [permission-type (get input "permission_type" "unknown")
        tool-name (get input "tool_name" "")]
    (if (not-empty tool-name)
      (send-notification! "Claude Code Permission" (str "Requesting: " tool-name) session-info)
      (send-notification! "Claude Code Permission" (str "Requesting: " permission-type) session-info))
    {:systemMessage "Permission notification sent"}))

(defn -main
  []
  (let [input (json/parse-string (slurp *in*))
        hook-event (get input "hook_event_name" "unknown")
        tmux-focused? (check-tmux-focus)
        alacritty-focused? (check-alacritty-focus)]

    (if (and (not tmux-focused?) (not alacritty-focused?))
      (let [session-info (get-tmux-info)
            result (case hook-event
                     "UserPromptSubmit" (handle-user-prompt-submit session-info)
                     "PermissionRequest" (handle-permission-request input session-info)
                     {:systemMessage (str "Unknown hook event: " hook-event)})]
        (println (json/generate-string result)))
      (println (json/generate-string {:systemMessage "Notification skipped (terminal focused)"})))))

(-main)

(comment
  (send-notification! "Claude Code Permission" "test" "test"))
