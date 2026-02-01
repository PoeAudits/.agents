---
name: Command Development
description: Use when creating or editing project slash commands (frontmatter, args, file refs, bash, and interactive patterns).
version: 0.3.0
---

# Command Development for Opencode

## What a command is

A slash command is a Markdown file. When a user runs `/command`, the file contents are used as **instructions for the agent**.

Write commands as directives (what the agent must do), not as explanations to the user.

## Where commands live (this repo)

- Commands are **project commands** stored in: `.agents/command/`
- This directory is symlinked to `OpenCodeCommands/` (keep it this way).

Do not use personal/global command locations in this repo.

### What not to do

- Don’t put commands anywhere except `.agents/command/`.
- Don’t configure commands in JSON (for example `OpenCode.json` / `opencode.json`). Commands are files in `.agents/command/`.

## Command file format

Commands are `*.md` files. YAML frontmatter is optional.

Example layout:

```
.agents/command/
├── general/
│   ├── init.md
│   └── commit.md
└── handoff/
    ├── handoff.md
    └── pickup.md
```

## Frontmatter (YAML)

Use the minimum frontmatter needed.

### name

Optional explicit command name.

```yaml
---
name: git-status
description: Summarize git status
---
```

### description

Short text shown in `/help`.

```yaml
---
description: Review a file
---
```

### argument-hint

Documents expected arguments.

```yaml
---
argument-hint: [target] [options]
---
```

### model

Pins a model for the command.

**Guidance (this repo):** do **not** set `model:` unless the user explicitly requests a specific model.

### agent

Routes execution to a specific agent.

**Guidance (this repo):** do **not** set `agent:` unless the user explicitly requests it.

### subtask

Runs the command in an isolated subtask context.

```yaml
---
subtask: true
---
```

## Arguments

- `$ARGUMENTS` = all args as one string
- `$1`, `$2`, ... = positional args

Use “combining arguments” patterns when you need `$1` plus “the rest”.

## File references (`@`)

In this repo, **the user should pass file references as `@path`**, and the command should use the first argument directly.

Example:

```markdown
---
description: Review a file
argument-hint: [@file] [notes]
---

Review $1 for:
- correctness
- readability
- missing tests

Extra context from user: $2
```

Usage:

```
/review-file @src/api/users.ts please focus on auth edge cases
```

Do **not** write `@$1` here (that would double up the `@`).

## Bash interpolation

Commands can embed bash output using:

```markdown
Current branch: !`git branch --show-current`
```

Keep bash snippets fast and non-destructive.

## Tool naming in docs

When referring to tools, use lowercase names (e.g., `read`, `glob`, `grep`, `bash`, `task`).

---

See also:
- `references/frontmatter-reference.md`
- `examples/simple-commands.md`
