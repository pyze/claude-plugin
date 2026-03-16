#!/usr/bin/env bb

;; Mementum CLI - Git-based memory system
;; Usage:
;;   ./mementum.clj create SYMBOL "slug" "content"
;;   ./mementum.clj recall "query" [depth]
;;   ./mementum.clj list [n]
;;   ./mementum.clj validate "file.md"

(require '[clojure.string :as str]
         '[babashka.process :refer [shell sh]]
         '[babashka.fs :as fs])

(def symbols #{"insight" "pattern" "decision" "meta"})
(def token-limit 200)
(def memories-dir "memories")

;; Fibonacci sequence for depth scaling
(defn fibonacci [n]
  (case n
    0 1
    1 2
    2 3
    3 5
    4 8
    5 13
    6 21
    7 34
    (+ (fibonacci (- n 1)) (fibonacci (- n 2)))))

(defn count-tokens
  "Approximate token count (words + punctuation)"
  [s]
  (count (re-seq #"\S+" s)))

(defn valid-slug? [s]
  (re-matches #"[a-z0-9-]+" s))

(defn valid-symbol? [s]
  (contains? symbols s))

(defn current-date []
  (.format (java.time.LocalDate/now)
           (java.time.format.DateTimeFormatter/ofPattern "yyyy-MM-dd")))

(defn memory-filename [slug symbol]
  (str memories-dir "/" (current-date) "-" slug "-" symbol ".md"))

;; Commands

(defn create-memory [symbol slug content]
  (cond
    (not (valid-symbol? symbol))
    (do (println "Error: Invalid symbol. Must be one of:" (str/join " " symbols))
        (System/exit 1))

    (not (valid-slug? slug))
    (do (println "Error: Invalid slug. Must be kebab-case (lowercase, numbers, hyphens)")
        (System/exit 1))

    (> (count-tokens content) token-limit)
    (do (println "Error: Content exceeds" token-limit "tokens (got" (count-tokens content) ")")
        (System/exit 1))

    :else
    (let [filename (memory-filename slug symbol)]
      (fs/create-dirs memories-dir)
      (spit filename content)
      (shell "git" "add" filename)
      (shell "git" "commit" "-m" (str symbol ": " slug))
      (println "Created:" filename))))

(defn recall-memories [query depth]
  (let [n (fibonacci (or depth 2))]
    (println "=== Recent memories (last" n ") ===")
    (let [{:keys [out]} (sh "git" "log" (str "-n" n) "--pretty=format:%s: %b" "--" memories-dir)]
      (when (seq out)
        (println out)))

    (when (seq query)
      (println "\n=== Semantic matches for:" query "===")
      (let [{:keys [out]} (sh "git" "grep" "-i" "-l" query memories-dir)]
        (if (seq out)
          (doseq [file (str/split-lines out)]
            (println "File:" file)
            (println (slurp file))
            (println "---"))
          (println "No matches found"))))))

(defn list-memories [n]
  (let [files (->> (fs/glob memories-dir "*.md")
                   (filter #(not= (fs/file-name %) "README.md"))
                   (sort-by fs/last-modified-time)
                   reverse
                   (take (or n 10)))]
    (if (seq files)
      (doseq [f files]
        (println (fs/file-name f)))
      (println "No memories found"))))

(defn validate-memory [filename]
  (if (fs/exists? filename)
    (let [content (slurp filename)
          tokens (count-tokens content)
          basename (fs/file-name filename)
          parts (re-matches #"(\d{4}-\d{2}-\d{2})-(.+)-(insight|pattern|decision|meta)\.md" basename)]
      (cond
        (nil? parts)
        (println "Error: Filename doesn't match pattern YYYY-MM-DD-slug-symbol.md")

        (not (valid-slug? (nth parts 2)))
        (println "Error: Invalid slug in filename")

        (> tokens token-limit)
        (println "Error: Content exceeds" token-limit "tokens (got" tokens ")")

        :else
        (println "Valid memory:" basename "(" tokens "tokens)")))
    (println "Error: File not found:" filename)))

;; Main dispatch

(defn -main [& args]
  (let [[cmd & rest-args] args]
    (case cmd
      "create" (let [[symbol slug & content-parts] rest-args]
                 (create-memory symbol slug (str/join " " content-parts)))
      "recall" (let [[query depth] rest-args]
                 (recall-memories (or query "") (some-> depth parse-long)))
      "list"   (list-memories (some-> (first rest-args) parse-long))
      "validate" (validate-memory (first rest-args))
      (do
        (println "Mementum - Git-based memory system")
        (println)
        (println "Usage:")
        (println "  mementum.clj create SYMBOL SLUG CONTENT...")
        (println "  mementum.clj recall [QUERY] [DEPTH]")
        (println "  mementum.clj list [N]")
        (println "  mementum.clj validate FILE")
        (println)
        (println "Symbols:" (str/join " " symbols))
        (println)
        (println "Examples:")
        (println "  ./mementum.clj create insight pyramid-entities '## Pattern\\nAlways normalize...'")
        (println "  ./mementum.clj recall 'pyramid' 3")
        (println "  ./mementum.clj list 5")))))

(apply -main *command-line-args*)
