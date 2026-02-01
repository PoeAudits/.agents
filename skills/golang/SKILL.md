---
name: golang
description: Golang development skills including concurrency, testing, backend development, and diagnostics. This skill should be used when "writing Go code", "implementing concurrency patterns", "testing Go applications", or "building Go backend services".
---

# Golang Skills

A collection of skills for Go development. Each skill focuses on a specific aspect of building production-grade Go applications.

## Activation Triggers

- Writing any Go code
- Implementing concurrent systems with goroutines and channels
- Testing Go applications with unit tests, benchmarks, or fuzz tests
- Building web servers, REST APIs, or microservices
- Diagnosing performance issues, memory leaks, or goroutine leaks
- Tuning garbage collector performance
- Optimizing memory usage and heap allocations

## Quick Routing

**Writing any Go code?** → `go-coding-guidelines` (read first)

**Building concurrent systems, worker pools, or pipelines?** → `go-concurrency-patterns`

**Writing unit tests, benchmarks, or integration tests?** → `go-testing`

**Building HTTP servers, REST APIs, or microservices?** → `go-backend-development`

**Diagnosing performance issues, memory leaks, or debugging?** → `go-diagnostics`

**Tuning GC performance or optimizing memory footprint?** → `go-garbage-collector`

**Writing fuzz tests or finding security vulnerabilities?** → `go-fuzzing`

## Skill Map

| Skill | Covers |
|-------|--------|
| [go-coding-guidelines](references/go-coding-guidelines/SKILL.md) | Must be read if not already read before writing any Go code. |
| [go-concurrency-patterns](references/go-concurrency-patterns/SKILL.md) | Master Go concurrency with goroutines, channels, sync primitives, and context. Use when building concurrent Go applications, implementing worker pools, pipelines, or debugging race conditions. |
| [go-testing](references/go-testing/SKILL.md) | Write effective Go tests using table-driven patterns, test helpers, benchmarks, HTTP handler testing, and integration test strategies. Use when writing unit tests, benchmarks, mocking dependencies, or setting up test infrastructure in Go projects. |
| [go-backend-development](references/golang-backend-development/SKILL.md) | Build production-grade Go web servers, REST APIs, database integration, middleware, and microservices. Use when developing HTTP services, implementing middleware patterns, integrating databases, or building microservices architectures. |
| [go-diagnostics](references/go-diagnostics/SKILL.md) | Master Go diagnostics including profiling (CPU, memory, goroutine), tracing, debugging with Delve, and runtime statistics. Use when diagnosing performance issues, memory leaks, goroutine leaks, analyzing latency, debugging Go applications, or understanding runtime behavior. |
| [go-garbage-collector](references/go-garbage-collector/SKILL.md) | Master Go garbage collector tuning with GOGC, GOMEMLIMIT, profiling, and heap optimization. Use when debugging GC performance issues, reducing memory usage, tuning GC frequency, analyzing heap allocations, or optimizing Go application memory footprint. |
| [go-fuzzing](references/go-fuzzing/SKILL.md) | Write and run Go fuzz tests for automated bug detection and security vulnerability discovery. Use when writing fuzz tests, using FuzzXxx functions, running `go test -fuzz`, managing fuzz corpus, or debugging fuzz test failures. |
