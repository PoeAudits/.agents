---
name: loop
description: Use when autonomously executing an implementation plan with multiple tasks, running iterative agent loops with fresh context per iteration, or implementing features from a markdown checkbox plan file.
---

# Execution Loop Pattern

Autonomous iterative execution of implementation plans using `dispatch loop`. Each iteration runs with fresh context - state persists via files on disk, not in context window.

## When to Use

- Implementation plan exists with `- [ ]` checkbox tasks
- Tasks are independent enough to implement one per iteration
- Validation command available (`make validate` or equivalent)
- Agent needs autonomous operation without human approval per task

## Plan Preparation

Before running the loop, ensure your plan is properly formatted. Use **loop-format** skill to:
- Convert existing plans to loop-compatible format
- Atomize large tasks into smaller units
- Order tasks by dependency
- Validate checkbox format

```bash
# Format plan before execution
dispatch loop-format IMPLEMENTATION_PLAN.md --backup

# Or format as part of loop
dispatch loop claude --prompt PROMPT.md --plan PLAN.md --format-first
```

## Command Reference

```bash
dispatch loop <agent> --prompt <file-or-string> --plan <file-or-string> [options]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--prompt` | required | Prompt file path or string |
| `--plan` | - | Implementation plan file path |
| `--validate` | `make validate` | Validation command (tests, lint) |
| `--knowledge` | `thoughts/logs/KNOWLEDGE.md` | File to log learnings on failure |
| `--log` | `.dispatch/loop.log` | Iteration log file |
| `--max-iterations` | 100 | Maximum iterations before stopping |
| `--timeout` | 600 | Per-iteration timeout in seconds |
| `--cwd` | current | Working directory |

## Plan File Format

Use markdown checkboxes. Loop selects FIRST unchecked task (order = dependency order):

```markdown
# Implementation Plan

## Phase 1: Foundation
- [x] Set up project structure
- [ ] Add database schema         <- Loop picks this (first unchecked)
- [ ] Implement data models

## Phase 2: Features  
- [ ] Add user authentication
- [ ] Add API endpoints
```

**Completion markers:**
- `- [ ]` = incomplete (will be selected)
- `- [x]` = complete (skipped)

Loop terminates when all checkboxes are checked.

## Prompt File Structure

Your prompt file should contain project-specific instructions. The loop automatically injects standard execution instructions that tell the agent to:

1. Read the plan and select the first `- [ ]` task
2. Implement the task completely (no stubs)
3. Run validation command
4. If passing: mark task `- [x]`, commit with `git add <files>`
5. If failing: document in knowledge file, do NOT commit

Example `PROMPT_build.md`:

```markdown
You are implementing features for the dispatch CLI library.

## Project Context
- Language: TypeScript with Bun runtime
- Test command: `bun test`
- Lint command: `bun lint`

## Codebase Patterns
- Patterns go in src/patterns/
- CLI commands go in src/cli/
- Types are colocated with implementation

## Implementation Notes
- Use existing patterns as reference
- Follow TypeScript coding guidelines
- Add tests for new functionality
```

## Execution Flow

```
┌─────────────────────────────────────────────────┐
│                  ITERATION N                     │
├─────────────────────────────────────────────────┤
│ 1. Read prompt file (fresh each iteration)      │
│ 2. Check plan - any `- [ ]` remaining?          │
│    └─ No → CONVERGED, exit loop                 │
│ 3. Inject loop instructions into prompt         │
│ 4. Dispatch to agent (fresh context)            │
│ 5. Agent: selects first `- [ ]` task            │
│ 6. Agent: implements task                       │
│ 7. Agent: runs validation                       │
│ 8. Agent: updates plan, commits (if passing)    │
│ 9. Log iteration outcome                        │
│ 10. Loop continues → ITERATION N+1             │
└─────────────────────────────────────────────────┘
```

## Usage Examples

### Basic Execution
```bash
dispatch loop claude --prompt PROMPT_build.md --plan IMPLEMENTATION_PLAN.md
```

### With Custom Validation
```bash
dispatch loop claude \
  --prompt PROMPT_build.md \
  --plan IMPLEMENTATION_PLAN.md \
  --validate "bun test && bun lint && bun typecheck"
```

### With All Options
```bash
dispatch loop claude \
  --prompt PROMPT_build.md \
  --plan IMPLEMENTATION_PLAN.md \
  --validate "make validate" \
  --knowledge thoughts/logs/KNOWLEDGE.md \
  --log .dispatch/loop.log \
  --max-iterations 50 \
  --timeout 600 \
  --cwd ./my-project
```

### String Prompt (No File)
```bash
dispatch loop claude \
  --prompt "Implement the next task from the plan" \
  --plan ./IMPLEMENTATION_PLAN.md
```

## Workflow Integration

Use in YAML workflows:

```yaml
name: autonomous-build
steps:
  - name: execute
    loop:
      agent: claude
      prompt: PROMPT_build.md
      plan: IMPLEMENTATION_PLAN.md
      validate: make validate
      maxIterations: 50
```

## Agent Configuration

For autonomous operation, configure agent to skip permission prompts.

**OpenCode** - in project config:
```json
{
  "permission": "allow"
}
```

**Agent TOML config:**
```toml
[agents.claude]
start = "opencode run -m firmware/claude-sonnet-4-5-2025092 --format json"
continue = "opencode run -m firmware/claude-sonnet-4-5-2025092 --format json -c"
format = "jsonl"
```

## Output Structure

```json
{
  "success": true,
  "pattern": "loop",
  "sessionId": "dispatch-xxx",
  "converged": true,
  "convergenceReason": "plan_complete",
  "iterationCount": 12,
  "iterations": [
    {
      "iteration": 1,
      "timestamp": "2025-01-19T15:00:00Z",
      "outcome": "success",
      "durationMs": 45000,
      "tasksRemaining": 11
    }
  ],
  "durationMs": 540000
}
```

**Convergence reasons:**
- `plan_complete` - All tasks checked off
- `max_iterations` - Hit iteration limit
- `error` - Unrecoverable error

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Tasks not in dependency order | Earlier tasks should not depend on later tasks |
| No validation command | Add `make validate` target or use `--validate` flag |
| Agent lacks autonomous permissions | Set `"permission": "allow"` in OpenCode config |
| Plan uses non-standard checkboxes | Use exactly `- [ ]` and `- [x]` format |
| Committing with `git add .` | Prompt instructs `git add <files>` - don't override |
| Knowledge file directory missing | Create `thoughts/logs/` before running |

## Best Practices

1. **Run validation locally first** - Ensure `make validate` passes before starting loop
2. **Review plan task order** - Dependencies flow top-to-bottom
3. **Start with small iterations** - Use `--max-iterations 5` initially to verify behavior
4. **Monitor early iterations** - Watch first few to catch prompt issues
5. **Keep tasks atomic** - One feature/fix per checkbox, not "implement everything"
6. **Include rollback plan** - `git reset --hard` reverts uncommitted changes

