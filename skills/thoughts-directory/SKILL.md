---
name: thoughts-directory
description: Global thoughts directory structure for planning and documentation across all projects. Use when working with ~/thoughts, creating plans, writing logs, or understanding how project thoughts are organized. Triggers on thoughts directory paths, plan files, execution logs, or questions about where to put planning artifacts.
---

# Global Thoughts Directory

The global thoughts directory (`~/thoughts/`) is the persistent knowledge base for the AI-first multi-machine development infrastructure. It stores planning artifacts, research, execution logs, and documentation for all projects managed by Overlord. Content persists across sessions, machines, and agents -- it is the shared memory layer that enables continuity when work is picked up later, from a different device, or by a different agent.

All content is **project-centric**: every artifact belongs under `~/thoughts/projects/{project}/`. The Overlord registry (`~/.config/overlord/registry.yaml`) defines `thoughts_dir: ~/thoughts` and manages the lifecycle of project thought directories.

## Structure

```
~/thoughts/
└── projects/
    └── {project}/
        ├── plans/        # Implementation plans
        ├── logs/         # Execution logs
        ├── docs/         # Symlinks to project README.md, AGENTS.md
        ├── research/     # Research and references
        ├── sessions/     # Session notes
        ├── handoffs/     # Handoff context for resuming work
        ├── reviews/      # Code review notes
        └── briefs/       # Planning briefs from exploration
```

## Directory Purposes

### `plans/`

Implementation plans and orchestration documents. Created **before** starting implementation work.

- **Format**: `{plan-name}.md` (e.g., `auth-refactor.md`, `api-v2-migration.md`)
- **Content**: Phases, tasks with checkboxes, success criteria, execution status
- **When to create**: When work involves multiple steps, files, or phases. Not needed for single-file fixes.

### `logs/`

Execution records documenting what was done. Created **during or after** execution.

- **Format**: `YYYY-MM-DD_{subject}.md` (e.g., `2026-01-15_fix-auth-bug.md`)
- **Content**: Actions taken, deviations from plan, issues encountered, decisions made
- **When to create**: After completing significant work, especially if it deviated from a plan or involved non-obvious decisions.

### `docs/`

Symlinks to project documentation for cross-project discovery.

- `README.md` -> `{project-path}/README.md`
- `AGENTS.md` -> `{project-path}/AGENTS.md`

**Cross-project use case**: These symlinks allow agents to read about other projects without navigating the full `~/Overlord/` filesystem. When working on a project that depends on a local library or tool, read the dependency's docs via:

```bash
# Learn about a local library your project uses
cat ~/thoughts/projects/offchain-lib/docs/README.md
cat ~/thoughts/projects/offchain-lib/docs/AGENTS.md

# Discover what a tool does before using it
cat ~/thoughts/projects/overlord-v2/docs/AGENTS.md
```

This is particularly useful when a project uses a local library (under `~/Overlord/projects/libs/`) or a core tool (under `~/Overlord/core/tools/`) and the agent needs to understand its API, patterns, or conventions.

### `research/`

Background research, references, and exploration notes.

- **Format**: `{topic}.md` or `YYYY-MM-DD_{topic}.md` (e.g., `auth-libraries.md`)
- **Content**: Library comparisons, API research, architecture exploration, trade-off analysis
- **When to create**: During discovery and planning phases, or when evaluating options that should be preserved for future reference.

### `sessions/`

Session-specific notes and context.

- **Format**: `YYYY-MM-DD_{topic}.md` (e.g., `2026-01-15_planning.md`)
- **Content**: Session context, decisions made, progress notes
- **When to create**: During long or complex sessions where capturing intermediate context is useful.

### `handoffs/`

Handoff context for resuming work.

- **Format**: Managed by `opencode handoff` command (auto-generated)
- **Content**: Current state, next steps, blockers, relevant file paths
- **When to create**: When pausing work that will be resumed later, especially across sessions or by different agents.

### `reviews/`

Code review notes and feedback.

- **Format**: `YYYY-MM-DD_{subject}.md` or `{pr-number}.md` (e.g., `pr-123.md`)
- **Content**: Review comments, feedback, improvement suggestions
- **When to create**: During code review processes.

### `briefs/`

Planning briefs from exploration and Q&A.

- **Format**: `{feature-name}.md` or `YYYY-MM-DD_{topic}.md` (e.g., `dark-mode.md`)
- **Content**: Requirements, constraints, design decisions gathered during planning sessions
- **When to create**: After feature planning discussions, before implementation begins.

## When to Use Thoughts

### Before starting implementation

1. **Check for existing plans**: `ls ~/thoughts/projects/{project}/plans/` -- a plan may already exist for the work.
2. **Check for research**: `ls ~/thoughts/projects/{project}/research/` -- prior exploration may inform decisions.
3. **Check for briefs**: `ls ~/thoughts/projects/{project}/briefs/` -- requirements may already be captured.
4. **Read handoffs**: `ls ~/thoughts/projects/{project}/handoffs/` -- if resuming prior work.

### During work

- **Write a plan** if the task involves multiple steps or phases and no plan exists yet.
- **Update plan status** as phases/tasks are completed (check off items, note deviations).
- **Write research notes** if evaluating libraries, APIs, or design options worth preserving.

### After completing work

- **Write an execution log** for significant work, especially if it involved non-obvious decisions or deviated from a plan.
- **Write a handoff** if pausing work that will be resumed later.

### Cross-project discovery

- **Read docs/ symlinks** to learn about local dependencies, libraries, or tools your project uses.
- **Browse other projects' plans/research** when their work is relevant to yours.

## Registry Integration

The Overlord registry manages thoughts directories automatically:

- **`overlord new <name>`** -- Creates project + all 8 thoughts subdirectories + doc symlinks
- **`overlord add <name> <path>`** -- Registers existing project + creates thoughts directories
- **`overlord archive <name>`** -- Moves project to `~/Overlord/archive/` and thoughts to `~/thoughts/archive/{project}/`
- **`overlord unarchive <name>`** -- Restores project and thoughts from archive, updates symlinks

Active projects live under `~/thoughts/projects/{project}/`. Archived projects move to `~/thoughts/archive/{project}/` with the same subdirectory structure.

## File Naming Conventions

| Directory | Pattern | Example |
|-----------|---------|---------|
| plans | `{descriptive-name}.md` | `api-v2-migration.md` |
| logs | `YYYY-MM-DD_{subject}.md` | `2026-01-15_fix-auth-bug.md` |
| docs | `{doc-name}.md` (symlink) | `README.md`, `AGENTS.md` |
| research | `{topic}.md` or `YYYY-MM-DD_{topic}.md` | `auth-libraries.md` |
| sessions | `YYYY-MM-DD_{topic}.md` | `2026-01-15_planning.md` |
| handoffs | Auto-generated | Managed by `opencode handoff` |
| reviews | `YYYY-MM-DD_{subject}.md` or `{pr-number}.md` | `pr-123.md` |
| briefs | `{feature-name}.md` or `YYYY-MM-DD_{topic}.md` | `dark-mode.md` |

## Known Limitations

- **No lifecycle management**: Thoughts accumulate with no automated archival, pruning, or size limits. Old plans and logs persist indefinitely.
- **Symlink fragility**: Doc symlinks (`docs/README.md` etc.) can break when projects are moved, renamed, or archived outside of Overlord commands. Broken symlinks accumulate silently.
- **No validation**: There is no automated check that symlinks resolve or that thoughts directories stay consistent with the registry.

## Key Principles

1. **Registry is truth** -- Project state in the Overlord registry determines whether thoughts live under `projects/` or `archive/`.
2. **Project-centric** -- All artifacts belong under `~/thoughts/projects/{project}/`. No top-level loose files.
3. **Cross-project discovery** -- Doc symlinks are the primary mechanism for agents to learn about other projects in the system.
4. **Check before creating** -- Always check for existing plans, research, and briefs before starting new work.
5. **Write for future agents** -- Logs, handoffs, and research are written for the next agent or session that picks up the work, not just for the current moment.
