# Simple Command Examples

All examples are **instructions for the agent** (not user-facing descriptions).

## Example 1: Review a file (user passes `@path`)

**File:** `.agents/command/general/review-file.md`

```markdown
---
name: review-file
description: Review a file
argument-hint: [@file] [notes]
---

Review $1 for:
- correctness
- readability
- missing tests

User notes: $2
```

Usage:

```
/review-file @src/api/users.ts focus on auth edge cases
```

## Example 2: Summarize repo status (bash interpolation)

**File:** `.agents/command/general/git-status.md`

```markdown
---
name: git-status
description: Summarize git status
---

Branch: !`git branch --show-current`
Status: !`git status --short`
Recent commits: !`git log --oneline -5`

Summarize what changed and suggest next steps.
```

Usage:

```
/git-status
```

## Example 3: Interactive confirmation (question tool)

**File:** `.agents/command/general/confirm.md`

```markdown
---
name: confirm
description: Ask for confirmation
argument-hint: [action]
---

Action to confirm: $ARGUMENTS

Use the question tool to ask:
- header: Confirm
- question: "Proceed with: $ARGUMENTS?"
- options:
  - Yes
  - No

If "No", stop.
If "Yes", continue with the requested action.
```
