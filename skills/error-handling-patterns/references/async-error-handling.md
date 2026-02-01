# Async error handling

Load this reference when errors occur in concurrent systems or async code paths.

## Patterns

- Collect and surface errors from background tasks; avoid silent failures.
- Cancel related work on first fatal error when the operation is all-or-nothing.
- Preserve root causes by wrapping (not replacing) errors.
