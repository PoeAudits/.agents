---
name: thoughts-directory
description: Read before interacting with the thoughts directory.
---

# Thoughts Directory Structure

The `thoughts/` directory is the project's workspace for planning, executing, and archiving software engineering tasks.

## Directory Layout

```
thoughts/
├── tickets/        # Task definitions (bug, feature, debt)
├── research/       # Codebase and documentation research
├── plans/          # Implementation plans with phases
├── proposals/      # Spec-driven change proposals
├── specs/          # Canonical system specifications
├── logs/           # Execution logs (auto-generated)
├── reviews/        # Validation reports (optional)
└── archive/        # Completed work (final resting place)
```

## When to Use Each Subdirectory

### `/tickets`
**Contains:** Bug reports, feature requests, and technical debt items  
**Created by:** `/ticket`, `/ticket-quick` commands  
**When to use:** Documenting work that needs tracking or when requirements are unclear

- Use `bug_*` prefix for bug reports
- Use `feature_*` prefix for new capabilities
- Use `debt_*` prefix for refactoring/cleanup

**Don't use if:** Change is trivial and obvious (direct to planning)

### `/research`
**Contains:** Codebase findings, documentation research, architectural insights  
**Created by:** `/research`, `/documentation` commands  
**When to use:** Complex tasks requiring deep understanding before planning

- Spawns agents (codebase-locator, codebase-analyzer, etc.) to gather context
- File format: `YYYY-MM-DD_<topic>.md`
- Links back to tickets for traceability

**Optional phase** — skip for simple, well-understood changes

### `/plans`
**Contains:** Implementation plans with specific changes, phases, and success criteria  
**Created by:** `/plan`, `/plan-quick` commands  
**Format differences:**
- **Quick plans:** Simple "current state → new state" format
- **Full plans:** Multi-phase implementation with automated & manual verification

**Every task needs a plan** before execution

### `/proposals` (Spec Flow Only)
**Contains:** Change proposals with requirements deltas  
**Created by:** `/spec-propose` command  
**Structure:**
```
proposals/[change-id]/
├── proposal.md    # Why and what changes
├── deltas.md      # ADDED/MODIFIED/REMOVED requirements
├── design.md      # Technical decisions (optional)
└── tasks.md       # Implementation checklist
```

**When to use:** Adding features, breaking changes, or changes affecting specs

### `/specs`
**Contains:** Canonical system requirements and behaviors  
**Single file:** `SPEC.md` (source of truth)  
**When to use:** Spec Flow only — deltas merge into SPEC.md after execution  
**Updated by:** `/spec-merge` command

### `/logs`
**Contains:** Execution records showing what was actually done  
**Created by:** `/execute`, `/spec-execute` commands (auto-generated)  
**File format:** `YYYY-MM-DD_<subject>.md`  
**Purpose:** Document deviations from plan, issues encountered, verification results

**Every execution creates a log** that links back to plan/proposal

### `/reviews`
**Contains:** Validation reports confirming implementation matches plan  
**Created by:** `/review`, `/spec-review` commands  
**File format:** `YYYY-MM-DD_<plan>-review.md`  
**When to use:** Complex changes or before merging to main

**Optional phase** — skip for straightforward changes with good test coverage

### `/archive`
**Contains:** Completed work organized by date and change ID  
**Directory structure:**
```
archive/
└── YYYY-MM-DD_<slug>/
    ├── ticket.md
    ├── plan.md
    ├── research.md (if exists)
    ├── log.md
    └── review.md (if exists)
```

**When to use:** After committing, move completed work here for history  
**Command:** `/archive`

## File Naming Conventions in thoughts directory

- **Tickets:** `<type>_<subject>.md` (e.g., `bug_login_error.md`)
- **Research:** `YYYY-MM-DD_<topic>.md` (e.g., `2025-01-15_auth_implementation.md`)
- **Plans:** `<subject>.md` or `<change-id>.md` (e.g., `add_dark_mode.md`)
- **Logs:** `YYYY-MM-DD_<subject>.md` (e.g., `2025-01-15_fix_button_text.md`)
- **Reviews:** `YYYY-MM-DD_<plan>-review.md` (e.g., `2025-01-15_add_dark_mode-review.md`)
- **Archives:** Create subdirectory `YYYY-MM-DD_<slug>/` containing all related files

## Key Principles

1. **Linearity:** Work flows forward through phases; each phase creates artifacts for the next
2. **Traceability:** Every file links back (ticket → plan → log → archive)
3. **Status tracking:** Update frontmatter `status` field as you progress
4. **Specs as truth:** Spec Flow maintains `SPEC.md` as canonical requirements
5. **Optional phases:** Research and review can be skipped for simple work
6. **Archive everything:** Completed work moves to archive for historical reference


