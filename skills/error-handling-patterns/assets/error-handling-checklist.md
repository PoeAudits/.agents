# Error handling checklist

- Include context in errors (inputs, ids, operation name).
- Preserve the original exception/cause.
- Avoid double-logging the same error.
- Return actionable, user-facing messages when appropriate.
