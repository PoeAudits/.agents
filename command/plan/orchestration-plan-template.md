# Orchestration Plan: [Project/Feature Name]

## Overview

**Objective:** [1-2 sentence goal from the brief]

**Phases:** [number] phases, [number] total tasks

**Estimated Complexity:** Simple | Moderate | Complex

**Key Skills Required:**
- `skill-name` - [where it applies]
- `skill-name` - [where it applies]

---

## Phase 1: [Phase Name] ⏳

**Status:** ⏳ Pending
**Goal:** [What this phase accomplishes]

**Dependencies:** None | [Previous phase]

**Parallel Execution:** [Which tasks can run in parallel]

### Task 1.1: [Task Name] ⏳

**Status:** ⏳ Pending
**Subagent:** worker | executor

**Task Description:**
[Clear description of what needs to be done - NO code implementations]

**Context:**
[Relevant context from the planning brief - requirements, decisions, constraints that apply to this task]

**References:**
- [Files to examine]
- [Patterns to follow]
- [Related components]

**Success Criteria:**
- [ ] [Specific, verifiable outcome]
- [ ] [Another outcome]

**Required Skills:**
- `skill-name`

**Constraints:**
- [What NOT to do]
- [Boundaries to respect]

**Completion Notes:** _(filled by orchestrator after completion)_

---

### Task 1.2: [Task Name] ⏳

**Status:** ⏳ Pending
[Same structure...]

---

## Phase 2: [Phase Name] ⏳

**Status:** ⏳ Pending
**Goal:** [What this phase accomplishes]

**Dependencies:** Phase 1

[Tasks...]

---

## Execution Notes

### Parallelization Opportunities
- Tasks [X, Y, Z] in Phase N can run in parallel
- [Explanation of why they're independent]

### Critical Path
[Which tasks are on the critical path and block other work]

### Risk Points
[Tasks that are higher risk or may need iteration]

### Review Checkpoints
[When the reviewer should be dispatched]
- After Phase 1 completion
- After each task in Phase 2 (complex phase)
- Final review after Phase N

### Documentation Checkpoints
[When the documenter should be dispatched]
- After Phase 1 review passes
- After Phase 2 review passes
- After final phase review passes

---

## Task Summary Table

| Phase | Task | Subagent | Dependencies | Parallel? | Status |
|-------|------|----------|--------------|-----------|--------|
| 1 | 1.1 Setup project structure | worker | none | no | ⏳ |
| 1 | 1.2 Create base types | worker | none | yes (with 1.1) | ⏳ |
| 2 | 2.1 Implement auth service | executor | 1.1, 1.2 | no | ⏳ |
| ... | ... | ... | ... | ... | ⏳ |

---

## Execution Status

_This section is updated by the orchestrator during execution._

**Last Updated:** [not started]
**Current Phase:** -
**Current Task:** -

### Progress
- Phases complete: 0 of [N]
- Tasks complete: 0 of [N]

### Divergences from Plan
_(none yet)_

### Handoff History
_(none)_
