# Error recovery strategies

Load this reference when deciding whether to retry, degrade, or fail fast.

## Decide a strategy per failure mode

- Retry only when the operation is idempotent (or has an idempotency key).
- Add exponential backoff with jitter for transient failures.
- Prefer circuit breakers and bulkheads for shared downstream dependencies.
