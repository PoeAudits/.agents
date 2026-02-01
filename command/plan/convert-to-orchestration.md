---
description: Convert a plan to orchestration format
argument-hint: [@plan-file] [context]
---

<!--
USAGE:
  /convert-to-orchestration @path/to/plan.md
  /convert-to-orchestration @IMPLEMENTATION_PLAN.md This is a TypeScript project using PostgreSQL.
  /convert-to-orchestration (then paste plan content inline)

RELATED COMMANDS:
  /handoff - Interrupt and save state for continuation
  /pickup @thoughts/handoffs/file.md - Resume from handoff
-->

# Convert Plan to Orchestration Format

Read the input plan from $1 (or inline content from $ARGUMENTS). Parse it and produce an Orchestration Plan following the template in @command/plan/orchestration-plan-template.md, with an additional **Source Plan** section and **Conversion Notes** section appended.

---

## Step 1: Parse the Input Plan

Identify the plan's structure:
- Major sections or phases
- Individual tasks or action items
- Dependencies (explicit or implied)
- Technical context provided
- Success criteria or acceptance criteria

Common input patterns:

| Pattern | How to Parse |
|---------|--------------|
| `## Phase 1: ...` sections | Direct phase mapping |
| `- [ ] Task` checklists | Individual tasks |
| Numbered lists `1. 2. 3.` | Sequential tasks (may have dependencies) |
| Bullet points with sub-items | Parent = phase/group, children = tasks |
| Prose descriptions | Extract action items as tasks |

---

## Step 2: Identify Implicit Information

Infer what the input plan does not explicitly state:
- **Dependencies**: from task order and content
- **Parallelizability**: which tasks are independent
- **Complexity**: whether tasks need worker or executor
- **Skills**: map to relevant coding guidelines based on technology
- **Success criteria**: extract or infer from task descriptions

---

## Step 3: Restructure into Orchestration Format

Transform the parsed information into:
- Clear phases with goals
- Atomic tasks with proper delegation structure
- Explicit dependencies and parallelization notes
- Skills mapped to each task
- Success criteria for verification

Add a **Source Plan** section immediately after the title:
```markdown
## Source Plan
[Brief note about the original plan format and any transformations made]
```

---

## Step 4: Enhance with Orchestration Metadata

Add information the orchestrator needs:
- Subagent selection (worker vs executor)
- Review checkpoints
- Critical path identification
- Risk points

Append a **Conversion Notes** section at the end:
```markdown
## Conversion Notes

### Additions Made
[What was added that was not in the original plan]

### Assumptions Made
[What was inferred or assumed]

### Clarifications Needed
[Ambiguities that should be resolved before execution]
```

---

## Status Markers

Use these markers consistently:

| Marker | Meaning |
|--------|---------|
| `⏳` | Pending |
| `🔄` | In Progress |
| `📝` | Needs Review |
| `🔧` | Needs Fix |
| `📄` | Needs Docs |
| `✅` | Complete |
| `⚠️` | Blocked |
| `❌` | Failed |
| `⏸️` | Paused (handoff) |

---

## Conversion Rules

### Task Granularity

**Split tasks when:**
- A single item spans multiple files/components
- There are implicit sub-steps that need separate verification
- Different parts could go to different subagents (worker vs executor)

**Merge tasks when:**
- Multiple items are tightly coupled and must be done together
- Splitting would create artificial dependencies
- Items are too small to be meaningful delegation units

### Dependency Inference

Look for:
- **Explicit markers**: "after", "once", "depends on", "requires"
- **Order implications**: Numbered lists often imply sequence
- **Data flow**: Task B uses output of Task A
- **Structural dependencies**: Cannot add routes before the router exists

### Subagent Selection

**Assign worker when:**
- "Create config file", "Add type definitions", "Set up project structure", "Update imports"
- Single-file scope
- "Following the pattern in..."

**Assign executor when:**
- "Implement [feature]", "Design and build", "Refactor"
- Multi-file scope
- "Handle edge cases", ambiguous requirements
- "Integrate with..."

When unclear, prefer executor (conservative).

### Skills Mapping

Detect from task content:

| Keywords/Context | Skill |
|------------------|-------|
| TypeScript, .ts, types, interfaces | `typescript-coding-guidelines` |
| Python, .py, async def | `python-coding-guidelines` |
| Go, .go, goroutine | `go-coding-guidelines` |
| Solidity, .sol, contract | `solidity-coding-guidelines` |
| API, endpoint, REST, GraphQL | `api-design-principles` |
| Auth, login, JWT, session | `auth-implementation-patterns` |
| Error, exception, handling | `error-handling-patterns` |
| SQL, query, database | `sql-optimization-patterns` |

---

## Handling Different Input Formats

### Checkbox Plans
```
Input:  - [ ] Set up database schema / - [ ] Create user model / - [ ] Add auth endpoints
Output: Phase 1: Foundation (tasks 1-2, parallelizable), Phase 2: Features (task 3, depends on Phase 1)
```

### Phased Plans (already structured)
Preserve phase structure. Enhance tasks with delegation metadata.

### Prose Plans
Extract action items from sentences. Structure into phases based on dependencies.

### Numbered Steps
Respect sequence. Identify which steps can be parallelized.

---

## Handling Ambiguity

When the input plan is vague:

1. Make reasonable assumptions and document them in Conversion Notes
2. Flag for clarification if the assumption could significantly impact execution
3. Prefer conservative complexity estimates (use executor when unclear)
4. Add items to the "Clarifications Needed" section

---

## Handoff Support

Ensure converted plans support interruption and continuation:
- Every phase and task must have a status marker (start with `⏳`)
- Include the Task Summary Table with a status column
- Include the Execution Status section from the template
- Each task must have a `**Completion Notes:**` placeholder
