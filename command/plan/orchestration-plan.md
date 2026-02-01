---
description: Transform a Planning Brief into an Orchestration Plan
argument-hint: [@planning-brief] [additional instructions]
---

# Planning Brief to Orchestration Plan

## Input

Planning Brief: $1

Additional instructions: $2

Project directory: !`pwd`

## Goal

Transform the Planning Brief into a structured Orchestration Plan with phases, tasks, and delegation structure for the orchestrator agent.

---

## Transformation Process

### Step 1: Analyze the Brief

Before planning, understand:
1. What is the end goal?
2. What are the major components/areas of work?
3. What are the dependencies between components?
4. What can be parallelized?
5. What skills are relevant?

### Step 2: Identify Phases

Break the work into logical phases:
- **Phase 1** is typically setup/foundation
- **Middle phases** are core implementation
- **Final phase** is integration/verification

Each phase should be:
- Cohesive (related work grouped together)
- Sequential when there are dependencies
- Parallelizable when work is independent

### Step 3: Break Phases into Tasks

Each task should be:
- **Atomic enough** to delegate to a single subagent
- **Complete enough** to produce verifiable output
- **Clear enough** that success criteria are obvious

### Step 4: Classify Tasks

For each task, determine:
- **Subagent**: worker (straightforward) vs executor (complex)
- **Dependencies**: what must complete first
- **Parallelizable**: can run alongside other tasks
- **Skills**: relevant coding guidelines or patterns

---

## Orchestration Plan Format

Follow the plan template defined in: @.agents/command/plan/orchestration-plan-template.md

---

## Status Markers

Use these markers consistently throughout the plan:

| Marker | Meaning | When to Use |
|--------|---------|-------------|
| `⏳` | Pending | Not started yet |
| `🔄` | In Progress | Currently being worked on |
| `📝` | Needs Review | Implementation done, awaiting review |
| `🔧` | Needs Fix | Review found issues |
| `📄` | Needs Docs | Review passed, awaiting documentation |
| `✅` | Complete | Fully done including docs |
| `⚠️` | Blocked | Cannot proceed |
| `❌` | Failed | Needs attention |
| `⏸️` | Paused | Interrupted (handoff) |

### Status Flow

```
⏳ Pending
   ↓
🔄 In Progress
   ↓
📝 Needs Review
   ↓
[Review Pass] → 📄 Needs Docs → ✅ Complete
   ↓
[Review Fail] → 🔧 Needs Fix → 🔄 In Progress (loop)
```

---

## Subagent Selection Guidelines

### Use Worker For:
- Configuration files
- Project structure setup
- Simple type definitions
- Straightforward CRUD operations
- Following an existing pattern exactly
- Single-file changes
- Clear, well-specified tasks
- Estimated < 100 lines of change

### Use Executor For:
- Multi-file coordinated changes
- Complex business logic
- New patterns or architecture
- Ambiguous requirements requiring judgment
- Full feature implementations
- Tasks requiring design decisions
- Estimated > 100 lines or uncertain scope

**When in doubt, choose executor.**

---

## Skills Mapping

Map these skills to relevant tasks:

| Domain | Skill | Apply When |
|--------|-------|------------|
| TypeScript | `typescript-coding-guidelines` | Any TypeScript implementation |
| Python | `python-coding-guidelines` | Any Python implementation |
| Go | `go-coding-guidelines` | Any Go implementation |
| Solidity | `solidity-coding-guidelines` | Any Solidity implementation |
| APIs | `api-design-principles` | Creating/modifying APIs |
| Auth | `auth-implementation-patterns` | Authentication/authorization work |
| Errors | `error-handling-patterns` | Error handling implementation |
| SQL | `sql-optimization-patterns` | Database queries |
| Async | `async-python-patterns` / `go-concurrency-patterns` | Concurrent code |

---

## Task Description Guidelines

### Good Task Descriptions

- Describe WHAT needs to be accomplished
- Include relevant context from the brief
- Reference existing patterns/files to follow
- Specify clear success criteria
- Note constraints and boundaries

### Bad Task Descriptions

- Include code implementations
- Specify exact HOW (let subagent decide)
- Vague outcomes ("make it work")
- Missing context
- No success criteria

### Example Good Task

```markdown
### Task 2.1: Implement User Authentication Service

**Subagent:** executor

**Task Description:**
Create the user authentication service that handles login, logout, and token refresh.
The service should use JWT tokens and integrate with the existing user repository.

**Context:**
From the planning brief:
- Must support email/password authentication
- Token expiry: 1 hour for access, 7 days for refresh
- Must not break existing session endpoints (deprecated but still in use)

**References:**
- Existing service pattern: `src/services/product.service.ts`
- User repository: `src/repositories/user.repository.ts`
- JWT config: `src/config/auth.ts`

**Success Criteria:**
- [ ] AuthService class created with login, logout, refreshToken methods
- [ ] JWT tokens generated with correct claims and expiry
- [ ] Integrates with UserRepository for credential validation
- [ ] Error handling for invalid credentials, expired tokens
- [ ] Unit tests for core auth flows

**Required Skills:**
- `typescript-coding-guidelines`
- `auth-implementation-patterns`

**Constraints:**
- Do not modify existing session endpoints
- Use the existing error response format from `src/utils/responses.ts`
- Do not store passwords in logs
```

---

## Handling Complexity

### For Simple Briefs (2-4 tasks)
- May only need 1-2 phases
- Most tasks can be worker-level
- Minimal parallelization needed

### For Moderate Briefs (5-10 tasks)
- 2-3 phases typical
- Mix of worker and executor tasks
- Look for parallelization in setup phase

### For Complex Briefs (10+ tasks)
- 3-5 phases
- Multiple executor tasks
- Critical path analysis important
- More review checkpoints needed
- Consider breaking into multiple plans

---

## Final Checklist

Before outputting the plan, verify:

- [ ] All requirements from the brief are covered by tasks
- [ ] Dependencies between tasks are correctly identified
- [ ] Parallelization opportunities are noted
- [ ] Each task has clear success criteria
- [ ] Skills are mapped to relevant tasks
- [ ] Subagent selection is justified
- [ ] No task includes code implementations
- [ ] Constraints from brief are reflected in relevant tasks
- [ ] Review checkpoints are identified
- [ ] Documentation checkpoints are identified
- [ ] Critical path is clear
- [ ] All phases have status markers (⏳)
- [ ] All tasks have status markers (⏳)
- [ ] Task Summary Table includes status column
- [ ] Execution Status section is present

---

## Handoff Support

Plans are designed for **interruption and continuation**. The structure supports:

### Status Tracking
- Every phase and task has a status marker
- Task Summary Table provides at-a-glance progress
- Execution Status section tracks runtime state

### Completion Notes
Each task has a "Completion Notes" field that the orchestrator fills after completion:
```markdown
**Completion Notes:**
- Implemented in `src/services/auth.service.ts`
- Added 3 test files
- Used existing error pattern from utils
```

### Divergence Tracking
The Execution Status section tracks any deviations:
```markdown
### Divergences from Plan
- Task 2.1: Used Passport.js instead of custom JWT (simpler)
- Task 2.3: Split into 2.3a and 2.3b (too large)
```

### Handoff Ready
When `/handoff` is invoked, the plan already has:
- Clear status on every task
- Completion notes on finished work
- Divergences documented
- Current position identifiable

---

Save the plan to the ~/thoughts/projects directory under the current project's directory.
