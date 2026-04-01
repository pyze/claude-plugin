---
name: error-handling-patterns
description: Design error handling with fail-fast philosophy, Truss assertions, and Telemere structured logging. Use when implementing validation, deciding between fail-fast vs fallback, adding security-critical checks, or structured error logging.
---

# Error Handling Patterns Skill

Implement explicit, fail-fast error handling that makes problems visible during development, not in production. Uses two complementary libraries:

| Library | Role | Require |
|---------|------|---------|
| **Truss** | Fail-fast assertions at boundaries | `[taoensso.truss :refer [have have!]]` |
| **Telemere** | Structured logging/signals | `[taoensso.telemere :as t]` |

## When to Use This Skill

**Use THIS skill if:**
- Designing error handling for new features
- Deciding between fail-fast vs fallback logic
- Writing validation or security-critical code
- Using Truss for assertion-based error handling
- Logging errors with Telemere structured signals
- Debugging configuration or initialization errors
- Gathering context with `with-ctx+`
- Handling exceptions in try/catch blocks
- Deciding what to log vs send to clients
- Classifying retryable vs non-retryable errors

---

## Decision Tree: Which Tool?

```
┌─ Is this a boundary check (function entry, system init)?
│   └─ YES → Truss `(have pred? value)` — assertion, returns value
│
├─ Is this parsing untrusted/user input (EDN, JSON)?
│   └─ YES → try/catch with Telemere warn signal
│
├─ Is this a catch block that logs and rethrows?
│   └─ YES → Telemere `(t/log! {:level :error :error e} [msg data])`
│
├─ Is this a catch block that returns a fallback value?
│   └─ YES → Telemere warn signal + return fallback
│
└─ Is this operational logging (info, debug)?
    └─ YES → `(t/log! :info [msg])`
```

## Core Philosophy: Fail-Fast Over Fallback Logic

**Error strategy hierarchy**: `fail fast > fallback > backward compatibility`

| Strategy | Priority | When to Use |
|----------|----------|-------------|
| **Fail fast** | Highest | Default choice. Make errors visible during development. |
| **Fallback** | Medium | Only when fail-fast isn't possible and graceful degradation is needed. |
| **Backward compatibility** | Lowest | Avoid. Don't maintain deprecated code paths "just in case". |

**CRITICAL POLICY**: Prefer explicit failure over silent fallback behavior.

### Fail-Fast Principle

```clojure
;; BAD - Silent fallback
(defn get-api-key []
  (or (System/getenv "API_KEY")
      (if dev-mode? "mock-key" nil)))  ;; Silent mock fallback!
;; Problem: Developers think they're testing real API, but using mock

;; GOOD - Explicit failure
(defn get-api-key []
  (or (System/getenv "API_KEY")
      (throw (ex-info "Missing API_KEY environment variable"
                      {:type :config/missing-api-key}))))
;; Clear: Initialization fails if key is missing, no ambiguity
```

### Fix the Source, Don't Route Around It

When data is missing, the correct response is almost always to make the data present — not to add a conditional fallback.

| Instead of (fallback) | Use (fix the source) |
|----------------------|---------------------|
| `(or name "Anonymous")` | `(have string? name)` — ensure name is always provided |
| `(get config :key default-val)` | `(have some? (get config :key))` — ensure config has the key |
| `(when-not x (create-default))` | `(have some? x)` — ensure x is provided by caller |
| `(if (nil? db) (mock-db) ...)` | `(have some? db)` — ensure db is initialized |
| `(try (op) (catch _ default))` | `(op)` — let it fail; fix why it fails |

**The test**: If you're about to write `or`, `when-not`, `if-not`, or `try/catch` to handle missing data, ask: *should this data be present?* If yes, make it present and assert with `have`. Only use defaults for genuinely optional, user-facing values.

### When System Should Fail

- **Missing required configuration** (API keys, database URLs)
- **Invalid authentication state** (expired tokens, wrong credentials)
- **Type mismatches** (expecting string, got nil)
- **Constraint violations** (unique key already exists)
- **Required resources unavailable** (database down, service timeout)

### When Fallback Logic Is Acceptable

Fallback logic is appropriate ONLY when ALL of these conditions are met:

1. **Recovery is meaningful** - The fallback provides real value, not just silence
2. **User expects it** - Feature explicitly designed for graceful degradation
3. **Logged/monitored** - Every fallback execution is visible in telemetry
4. **Bounded** - Fallback doesn't cascade or hide deeper issues

**Acceptable fallback scenarios**:
- **Optional features** (caching with cache miss fallback)
- **Graceful degradation** (reduced feature set with poor connectivity)
- **Safe defaults** (use system font if custom font fails to load)

### Fallback Decision Tree

```
┌─ Can operation be retried?
│   └─ YES → Retry with backoff (not fallback)
│
├─ Is failure expected in normal operation?
│   └─ YES → Design explicit fallback (e.g., optional feature, network resilience)
│
├─ Is failure a configuration/setup issue?
│   └─ YES → FAIL FAST (no fallback)
│
└─ Unknown/unexpected failure?
    └─ FAIL FAST (no fallback)
```

---

## Truss Assertions at Boundaries

Taoensso Truss provides inline assertions that return the checked value. Use at function entry points and system boundaries.

### Basic Pattern

`(have pred? value)` — returns `value` if `(pred? value)` is truthy, throws otherwise.

```clojure
(require '[taoensso.truss :refer [have have!]])

;; Returns the value on success — use inline in let bindings or function args
(have string? doc-id)       ;; Returns doc-id
(have map? entity)          ;; Returns entity
(have pos-int? port)        ;; Returns port

;; Custom predicates
(have #(or (keyword? %) (string? %)) var-ref)
```

### Where to Assert

| Boundary | Examples | Pattern |
|----------|----------|---------|
| **System init** | Integrant init-key | `(have string? project-id)`, `(have pos-int? port)` |
| **Store operations** | Database add/pull/remove | `(have map? entity)`, `(have vector? ident)` |
| **Factory functions** | make-*-resolver, create-* | `(have string? id)`, `(have map? config)` |
| **Pipeline entry** | Data processing pipelines | `(have map? input)`, `(have coll? items)` |
| **Environment construction** | Service initialization | `(have map? config)`, `(have string? url)` |

### `have` vs `have!`

- **`have`** — elidable in production builds. Use for internal boundaries.
- **`have!`** — never elided. Use for security-critical checks (auth tokens, API keys).

### Contextual Assertions

```clojure
(require '[taoensso.truss :as truss])

;; Add context for better error messages
(truss/with-ctx+ {:handler 'user/process-request :step :validation}
  (have string? input-text)
  (have pos-int? item-count))
;; Failure includes context: {:handler ..., :step ...}
```

---

## Telemere Structured Logging

Telemere replaces `println`, `js/console`, and ad-hoc logging with structured signals. Works in both CLJ and CLJS (.cljc files).

### Basic Logging

```clojure
(require '[taoensso.telemere :as t])

;; Simple log — level + message vector
(t/log! :info ["Server started" {:port port}])
(t/log! :warn ["Unexpected state" {:key k :value v}])

;; Debug-level tracing for data flow (silent by default)
(t/log! :debug ["resolver path:" path "| columns:" (keys first-row)])
;; Enable: (t/set-min-level! nil "my.app.*" :debug)
```

### Error Logging with Exception Attachment

Attach exceptions to Telemere signals using the `:error` key in the opts map. This preserves the full stack trace as structured data.

```clojure
;; BAD — exception converted to string, stack trace lost
(t/log! :error (str "Operation failed: " (ex-message e)))

;; GOOD — exception attached as structured data
(t/log! {:level :error :error e}
        ["Resolver error" {:op op-name :path path}])
```

### Testing Telemere Signals

Use `t/with-signals` to capture signals in tests:

```clojure
(require '[taoensso.telemere :as t])

(let [{:keys [value signals]} (t/with-signals (some-fn-that-logs))]
  ;; value = return value of the body
  ;; signals = vector of captured Telemere signal maps
  (is (= 1 (count signals)))
  (is (= :warn (:level (first signals)))))
```

---

## Safe EDN Parsing Pattern

For parsing EDN from user input or untrusted sources, use a safe parsing wrapper:

```clojure
(defn try-parse-edn
  "Parse EDN from string, returning nil on failure. Logs warning for non-blank invalid input."
  [s]
  (when-not (str/blank? s)
    (try
      (clojure.edn/read-string s)
      (catch #?(:clj Exception :cljs :default) e
        (t/log! :warn ["EDN parse failed" {:input s :error (ex-message e)}])
        nil))))
```

**When to use:** Any site that calls `edn/read-string` on data that might be malformed (HTML attributes, user queries, config strings). Replaces inline try/catch blocks.

**When NOT to use:** Sites where parsing failure indicates a real bug (not user input). Those should fail fast.

---

## Exception Handling

**CRITICAL**: Never lose exception context. Always log server-side before sending to clients.

### Core Rules

| Rule | Description |
|------|-------------|
| **Never lose context** | Always chain exceptions: `(ex-info msg data cause)` |
| **Never swallow** | Every exception must be logged or rethrown |
| **Always log server-side** | Full exception to logs, safe message to client |
| **Classify errors** | Retryable (rate limit, timeout) vs non-retryable (auth, validation) |

### Catch-Log-Rethrow Pattern

```clojure
(catch #?(:clj Exception :cljs :default) e
  ;; Attach exception as structured data, then rethrow
  (t/log! {:level :error :error e}
          ["Operation failed" {:op op-name :context ctx}])
  (throw e))
```

### Catch-and-Return Pattern

```clojure
(try
  {:success true :result (operation-fn)}
  (catch #?(:clj Exception :cljs :default) e
    (t/log! {:level :error :error e} ["Operation failed" context])
    {:success false :error (ex-message e)}))
```

### Exception Chaining (Preserve Cause)

```clojure
;; BAD - Cause lost!
(catch Exception e
  (throw (ex-info "Failed" {:type :error})))

;; GOOD - Cause preserved
(catch Exception e
  (throw (ex-info "Failed" {:type :error} e)))  ; e is the cause!
```

For detailed patterns including retryable error classification and async exception handling, see [EXCEPTION_HANDLING.md](./EXCEPTION_HANDLING.md).

---

## Error Response Structure

When errors occur, provide clear, actionable information:

```clojure
;; Standard error response format (EDN) - validation error
{:success false
 :error {:type :validation/invalid-email
         :message "Email must be a valid email address"
         :field :email}}

;; Security error response (don't expose details)
{:success false
 :error {:type :auth/unauthorized
         :message "Invalid credentials"}}
;; Note: Never expose internal details (stack traces, DB errors) to clients
```

---

## Error Handling Checklist

When implementing error handling, verify:

- [ ] **Fail-fast**: Invalid state causes immediate failure, not silent fallback
- [ ] **Clear errors**: Error messages explain what went wrong
- [ ] **Context**: Errors include enough info to debug the issue
- [ ] **Security**: No sensitive data in error messages to clients
- [ ] **Type-safe**: Input validation happens at system boundaries
- [ ] **Logging**: Errors are logged for debugging
- [ ] **Testing**: Error cases are tested (happy path + error paths)
- [ ] **Cause chained**: Exceptions preserve cause via `(ex-info msg data cause)`
- [ ] **Server-side logged**: Full exception logged before sending to client
- [ ] **Retryable classified**: Transient errors (timeout, rate limit) distinguished from permanent ones

---

## Additional Resources

For detailed patterns and specialized topics:

- [EXCEPTION_HANDLING.md](./EXCEPTION_HANDLING.md) - Exception chaining, logging, retryable errors, async handling
- [TRUSS_PATTERNS.md](./TRUSS_PATTERNS.md) - Advanced Truss assertion patterns and complex predicates
- [ANTI_PATTERNS.md](./ANTI_PATTERNS.md) - Common mistakes to avoid in error handling
- [INTEGRANT_CONFIG.md](./INTEGRANT_CONFIG.md) - Integrant configuration gotchas and debugging

---

## Summary

**Key principles**:
1. **Fail-fast**: Make problems visible immediately — `(have pred? value)` at boundaries
2. **Structured logging**: Telemere signals with `:error` attachment — `(t/log! {:level :error :error e} [msg data])`
3. **User input parsing**: Safe EDN parsing with try/catch and warn signal
4. **Security-critical**: Use `have!` for assertions that must always run
5. **Never lose context**: Always chain exceptions with cause — `(ex-info msg data e)`
6. **Always log server-side**: Full exception to logs, safe message to client
7. **Test signals**: `t/with-signals` captures Telemere signals in tests

**Result**: Errors are caught early, systems are debuggable, full context is preserved for investigation, and configuration problems surface during development, not in production.
