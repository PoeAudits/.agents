---
name: agent-development
description: This skill should be used when the user asks to "create an agent", "add an agent", "write a subagent", "agent frontmatter", "when to use description", "agent examples", or needs guidance on agent structure, system prompts, triggering conditions, permissions, and best practices for Opencode.
---

# Agent Development for Opencode

## Overview

Agents are Markdown files with YAML frontmatter plus a system prompt body.

**Key rules (most important):**
- The **filename** becomes the agent name (e.g., `code-reviewer.md` → `@code-reviewer`). `description` is **plain text** and drives **triggering**.
- `mode` must be **explicit**: `primary` or `subagent` (do not use `all`).
- **Subagents must set `model` explicitly** (never inherit from the parent).
- **Primary agents should omit `model`**.
- Use `permission`, not `tools` (the `tools:` frontmatter key is deprecated).
- Agents should be invoked via `@agent-name`.

## Agent File Structure

### Primary agent (user-invoked)

```markdown
---
description: Use this agent when [triggering conditions].
mode: primary
permission:
  # allow/ask/deny per tool (optional)
  bash: ask
---

You are [role] specializing in [domain].

**Your Core Responsibilities:**
1. ...
2. ...

**Output Format:**
- ...
```

### Subagent (invoked by another agent)

```markdown
---
description: Use this agent when [triggering conditions].
mode: subagent
model: anthropic/claude-sonnet-4-5
permission:
  write: deny
  edit: deny
  bash: deny
---

You are [role] specializing in [domain].

**Your Core Responsibilities:**
1. ...
2. ...

**Output Format:**
- ...
```

## Frontmatter Fields

### description (required)

Defines when Opencode should trigger this agent.

**Rules:**
- Plain text only (no XML tags)
- Start with “Use when…” / “Use this agent when…”
- Include a small set of distinctive phrases users say

**Example:**
```
Use when the user asks to review code changes for quality or security. Triggers on phrases like “review my code”, “code review”, or “check my changes”.
```

### mode (required)

Controls invocation.

**Allowed values:**
- `primary` — invoked directly by the user (e.g., `@code-reviewer`)
- `subagent` — invoked by another agent/orchestrator

### model (required for subagents; omit for primary)

Subagents must set `model` explicitly (never inherit from the parent). Primary agents should omit `model`.

**Suggested mapping (pick based on complexity):**
- `anthropic/claude-haiku-4-5` — simple/fast tasks
- `anthropic/claude-sonnet-4-5` — default/general tasks
- `anthropic/claude-opus-4-5` — complex/ambiguous tasks

### permission (optional)

Controls tool access using `allow`, `ask`, or `deny`.

```yaml
permission:
  bash: ask
  write: deny
```

**Common tool keys:**
- `read`, `write`, `edit`, `grep`, `glob`, `bash`, `task`, `skill`, `webfetch`, `websearch`, `codesearch`

Scope bash permissions by command:

```yaml
permission:
  bash:
    "*": ask
    "git status": allow
    "git diff": allow
```

### temperature (optional)

Controls randomness.

```yaml
temperature: 0.3
```

**Guidelines:**
- Prefer ~`0.2–0.6` for most agents
- Avoid `0.0` and `1.0` unless there is a strong reason
- Practical range: `0.1–0.9`

## System Prompt Design

The markdown body becomes the agent's system prompt. Write in second person.

**Recommended structure:**
```markdown
You are [specific role] specializing in [domain].

**Your Core Responsibilities:**
1. ...
2. ...

**Quality Standards:**
- ...

**Output Format:**
- ...
```

**Size guidance:** keep agent files under ~500 lines.

## Creating Agents (manual-first)

1. Choose agent filename (1–64 chars, lowercase letters/numbers/hyphens).
2. Write a precise `description` (triggering conditions + a few phrases).
3. Set `mode` explicitly:
   - `primary` (omit `model`)
   - `subagent` (include `model` explicitly)
4. Set `permission` using least privilege.
5. Write a focused system prompt with clear responsibilities and output format.
6. Validate with `scripts/validate-agent.sh`.

## Agent Organization

### Project agents

```
project/
└── .opencode/
    └── agents/
        ├── reviewer.md
        └── generator/
            └── agent.md
```

### Global agents

Place agents in `~/.config/opencode/agents/`.

## Additional Resources

- `references/system-prompt-design.md`
- `references/triggering-examples.md`
- `examples/complete-agent-examples.md`
- `scripts/validate-agent.sh`
