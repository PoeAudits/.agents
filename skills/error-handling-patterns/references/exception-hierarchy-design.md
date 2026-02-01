# Exception hierarchy design

Load this reference when designing custom exception classes or Result-style error types.

## Goals

- Encode recovery decisions in error types, not in string matching.
- Keep the public surface small and stable.

## Pattern

- Create a single base application error type.
- Add small, specific subclasses for user-visible cases.
- Use error codes for machine handling when needed.
