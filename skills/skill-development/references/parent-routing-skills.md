# Parent Routing Skills

When a domain has multiple related sub-skills (e.g., a "golang" skill with sub-skills for testing, concurrency, diagnostics), organize them as a **parent routing skill** — a lightweight SKILL.md that routes the agent to the correct sub-skill based on the user's task.

## Directory Structure

Sub-skills live inside the parent's `references/` directory. This follows the standard skill anatomy — the parent directory contains only `SKILL.md` and its bundled resources (`references/`, `scripts/`, `assets/`). Each sub-skill is a full skill with its own SKILL.md and optional bundled resources.

```
parent-skill/
├── SKILL.md                          (routing skill)
└── references/
    ├── sub-skill-one/
    │   ├── SKILL.md
    │   └── references/
    │       └── detailed-guide.md
    ├── sub-skill-two/
    │   ├── SKILL.md
    │   └── scripts/
    │       └── utility.sh
    └── sub-skill-three/
        └── SKILL.md
```

**Why `references/`:** Sub-skills are reference material loaded on demand — exactly what the `references/` directory is for. The parent SKILL.md routes the agent to the correct sub-skill, and the agent loads only what it needs. This keeps the parent directory clean (`SKILL.md` + `references/` only) and follows the standard skill anatomy.

**Discovery:** Opencode discovers skills by recursively finding `SKILL.md` files, so sub-skills inside `references/` are automatically discoverable and independently loadable.

## Parent SKILL.md Format

The parent SKILL.md is a proper skill that follows the standard anatomy. Its purpose is routing — helping the agent quickly identify which sub-skill to load without reading all sub-skill descriptions.

### Template

```markdown
---
name: <parent-skill-name>
description: <domain> skills including <key areas>. This skill should be used when "<trigger phrase 1>", "<trigger phrase 2>", or "<trigger phrase 3>".
---

# <Domain> Skills

A collection of skills for <domain> development. Each skill focuses on a specific aspect of <domain>.

## Activation Triggers

- <Task or question that should activate this skill>
- <Another task or question>
- <Be specific about user intents>

## Quick Routing

**<Problem or question>?** → `<sub-skill-name>`

**<Problem or question>?** → `<sub-skill-name>` + `<other-sub-skill-name>`

**<Problem or question>?** → `<sub-skill-name>`

## Skill Map

| Skill | Covers |
|-------|--------|
| [<sub-skill-name>](references/<sub-skill-name>/SKILL.md) | <Brief description of what this sub-skill covers> |
| [<sub-skill-name>](references/<sub-skill-name>/SKILL.md) | <Brief description> |
```

### Section Breakdown

#### Frontmatter
Follow the standard skill frontmatter format. The description should cover the entire domain with trigger phrases that span all sub-skills.

#### Activation Triggers
Bullet list of user tasks or questions that should cause this parent skill to load. These should be broad enough to cover the full domain, not just one sub-skill.

#### Quick Routing
The core value of a parent routing skill. Maps user problems/questions to specific sub-skills using this format:

```
**<User's problem stated as a question>?** → `<sub-skill-name>`
```

Guidelines for quick routing entries:
- Frame each entry as a question the user might have
- Point to one or two sub-skills maximum per entry
- If a coding-guidelines sub-skill exists, list it first with "(read first)" annotation
- Group entries logically (e.g., all testing-related entries together)
- Cover every sub-skill in at least one routing entry

#### Skill Map
Table with relative links to each sub-skill's SKILL.md (using `references/<sub-skill-name>/SKILL.md` paths). The "Covers" column should be a brief summary (one line) derived from the sub-skill's frontmatter description.

## Complete Example

This example shows a properly structured parent routing skill:

```markdown
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

## Quick Routing

**Writing any Go code?** → `go-coding-guidelines` (read first)

**Building concurrent systems or worker pools?** → `go-concurrency-patterns`

**Writing tests or benchmarks?** → `go-testing`

**Building HTTP servers or APIs?** → `go-backend-development`

**Diagnosing performance or memory issues?** → `go-diagnostics`

**Tuning GC or optimizing memory?** → `go-garbage-collector`

**Writing fuzz tests?** → `go-fuzzing`

## Skill Map

| Skill | Covers |
|-------|--------|
| [go-coding-guidelines](references/go-coding-guidelines/SKILL.md) | Naming, interfaces, error handling, idioms, anti-patterns |
| [go-concurrency-patterns](references/go-concurrency-patterns/SKILL.md) | Goroutines, channels, sync primitives, worker pools |
| [go-testing](references/go-testing/SKILL.md) | Table-driven tests, benchmarks, HTTP testing, mocking |
| [go-backend-development](references/go-backend-development/SKILL.md) | Web servers, REST APIs, database integration, microservices |
| [go-diagnostics](references/go-diagnostics/SKILL.md) | CPU/memory profiling, tracing, Delve, runtime stats |
| [go-garbage-collector](references/go-garbage-collector/SKILL.md) | GOGC, GOMEMLIMIT, heap optimization |
| [go-fuzzing](references/go-fuzzing/SKILL.md) | FuzzXxx functions, corpus management, bug detection |
```

## Design Principles

### Keep the parent lean
The parent SKILL.md should be ~200-400 words. It exists to route, not to teach. All domain knowledge belongs in the sub-skills.

### Every sub-skill is independently discoverable
Sub-skills have their own frontmatter with name, description, and trigger phrases. Opencode can load them directly without going through the parent. The parent routing skill adds convenience, not dependency.

### Sub-skills follow the standard anatomy
Each sub-skill is a normal skill — SKILL.md with optional references/, scripts/, assets/. Being nested inside the parent's `references/` directory does not change their structure.

### When to use parent routing skills
- A domain has 2+ related skills that share a common theme
- Users frequently need help choosing the right skill for their task
- The skills form a logical collection (e.g., all Go skills, all frontend skills)

### When NOT to use parent routing skills
- A single standalone skill (just use a normal skill)
- Skills that are unrelated but happen to share a keyword
- Wrapping a single sub-skill (unnecessary indirection)

## Validation Checklist

For parent routing skills, verify:

- [ ] Parent SKILL.md has valid frontmatter with domain-wide trigger phrases
- [ ] Activation triggers cover the full domain
- [ ] Every sub-skill appears in at least one Quick Routing entry
- [ ] Every sub-skill has a row in the Skill Map table
- [ ] Relative links in Skill Map point to correct paths (`references/<sub-skill-name>/SKILL.md`)
- [ ] Parent body is lean (~200-400 words)
- [ ] Sub-skills live inside the parent's `references/` directory
- [ ] Each sub-skill has its own valid SKILL.md with frontmatter
- [ ] No domain knowledge duplicated between parent and sub-skills
