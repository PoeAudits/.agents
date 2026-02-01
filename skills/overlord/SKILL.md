---
name: overlord-v2
description: "System-wide project organization and file structure. Use when needing to understand where projects live, how directories are organized, where to find planning artifacts, how to discover existing projects, or where to place new work."
---

# Overlord — System Organization

Overlord is a project registry that keeps all projects, planning artifacts, and metadata organized. The registry at `~/.config/overlord/registry.yaml` is the source of truth — don't edit it directly, unless explicitly instructed to.

## Directory Layout

```
~/Overlord/                          # All projects
├── projects/
│   ├── web/                         # Frontend, full-stack web apps
│   ├── services/                    # APIs, backends, microservices
│   ├── contracts/                   # Solidity/blockchain
│   ├── ml/                          # Machine learning, data science
│   ├── libs/                        # Reusable libraries
│   └── cli/                         # Command-line tools
├── core/
│   ├── agents/                      # AI agent infrastructure
│   └── tools/                       # Developer tooling (overlord lives here)
└── sandbox/                         # Temporary, experimental, one-off work

~/thoughts/                          # Planning and documentation (separate from code)
├── projects/{name}/                 # Per-project thinking artifacts
│   ├── plans/                       # Implementation plans
│   ├── briefs/                      # Planning briefs
│   ├── sessions/                    # Session logs
│   ├── logs/                        # Execution logs
│   ├── research/                    # Research notes
│   ├── handoffs/                    # Handoff documents
│   ├── reviews/                     # Review notes
│   └── docs/                        # Symlinks to project README.md and AGENTS.md
└── archive/{name}/                  # Thoughts for archived projects

~/.config/overlord/                  # Registry and config (don't edit directly)
├── registry.yaml                    # Project registry (git-tracked, shared)
└── machine.yaml                     # Machine-specific config (gitignored)
```

**Key insight:** Code and thinking artifacts are separated. Code lives under `~/Overlord/`, planning lives under `~/thoughts/`, linked by symlinks in the `docs/` subdirectory. The `thoughts-directory` skill covers thoughts structure in detail.

## Categories

| Category | Path | What goes here |
|----------|------|----------------|
| `web` | `projects/web/` | Frontend apps, full-stack web projects |
| `services` | `projects/services/` | APIs, backends, microservices |
| `contracts` | `projects/contracts/` | Solidity/blockchain projects |
| `ml` | `projects/ml/` | Machine learning, data science |
| `libs` | `projects/libs/` | Reusable libraries |
| `cli` | `projects/cli/` | Command-line tools |
| `core-agents` | `core/agents/` | AI agent infrastructure |
| `core-tools` | `core/tools/` | Developer tooling |
| `sandbox` | `sandbox/` | Temporary, experimental, one-off work |

Use `sandbox` for throwaway experiments or one-time tasks.

## Discovering Projects

```bash
overlord list                        # Active projects (name, category, lang, description)
overlord list --json                 # Machine-readable output
overlord list --all                  # Include archived projects
overlord list --category=web         # Filter by category
overlord list --tag=api              # Filter by tag
overlord info <name>                 # Full details on a specific project
overlord <partial-name>              # Fuzzy match by name or alias
```

## Project Lifecycle

- **Create:** `overlord new <name> --category=<cat>` — creates project directory, git repo, templates (Makefile, README, AGENTS.md, .tmux.local), registry entry, and thoughts directories with symlinks. Language flags: `--go`, `--py`, `--ts`, `--sol` (defaults to base).
- **Register existing:** `overlord add <name> <path>` — add an existing directory to the registry.
- **Archive:** `overlord archive <name>` — moves project and thoughts to archive, marks archived in registry.
- **Restore:** `overlord unarchive <name>` — reverses archive, restores thoughts and symlinks.
- **Remove:** `overlord rm <name>` — remove from registry only. `overlord clear <name>` — remove from registry and delete files.

## Rules

- Don't manually create project directories under `~/Overlord/` — use `overlord new` or `overlord add` so the registry stays in sync.
- Don't edit `~/.config/overlord/registry.yaml` directly unless no CLI command exists for the operation.
- Don't assume a project exists because its directory does — check the registry with `overlord list` or `overlord info`.
- Project paths in the registry are relative to `~/Overlord/` (the base_dir setting).
