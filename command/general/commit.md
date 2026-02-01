---
description: Create atomic commits for session changes
argument-hint: [notes]
---

# Commit Changes

User notes: $ARGUMENTS

## Status

Unstaged changes:
!`git status -s`

If there are no changes to commit, inform the user and stop.

## Commit Types

| Prefix     | Use for                                      |
|------------|----------------------------------------------|
| feat:      | New features                                 |
| fix:       | Bug fixes or behavioral adjustments          |
| refactor:  | Internal restructuring, no behavior change   |
| chore:     | Tidying, deps, minor non-functional changes  |
| docs:      | Documentation and thoughts updates           |
| ci:        | CI/CD pipeline changes                       |

Note: `chore:`, `docs:`, and `ci:` are filtered from release changelogs.

## Process

1. **Analyze changes:**
   - Review conversation history for what was accomplished
   - Use the status output above to identify changed files
   - Use `git diff` on specific files only if you lack context
   - Group related files into logical atomic commits

2. **Draft commit plan:**
   - Select the appropriate prefix from the table above
   - Write messages in imperative mood focusing on *why*, not just *what*
   - Format: `type: description`

3. **Confirm with user:**

   Use the question tool:
   - header: "Commit plan"
   - question: "I plan to create [N] commit(s) with the changes listed above. How should I proceed?"
   - options:
     - Proceed (Create the commits as planned)
     - Edit (Let me adjust the plan first)
     - Cancel (Do not commit anything)

   If "Edit": ask what to change, revise, and re-confirm.
   If "Cancel": stop.

4. **Execute:**
   - `git add` with specific file paths (never `-A` or `.`)
   - Create commits with planned messages
   - Show result: `git log --oneline -n [N]`
