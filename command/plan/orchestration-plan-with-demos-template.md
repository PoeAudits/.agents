# Orchestration Plan: [Project/Feature Name]

## Overview

**Objective:** [1-2 sentence goal from the brief]

**Phases:** [number] phases, [number] total tasks, [number] demo checkpoints

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

### Demo 2.1: [Feature Name] Verification 🧪

**Status:** 🧪 Pending Demo
**Subagent:** worker
**Demo Type:** script | mini-project

**What This Verifies:**
[Specific functionality being tested - what new behavior is this confirming?]

**Prerequisites:**
- Task 2.1 complete
- Task 2.2 complete

**Demo Description:**
[Clear description of what the demo should do and demonstrate]

**Demo Location:** `demo/[feature-name]/`

**Expected Behavior:**
[What should happen when the demo runs successfully]

**Verification Steps:**
1. [Step-by-step instructions for user to verify]
2. [What to look for]
3. [How to confirm success]

**Cleanup:**
[What side effects need to be cleaned up - files created, state changed, etc.]

**Completion Notes:** _(filled by orchestrator after demo verified)_

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

### Demo Checkpoints
[When demos should be created and verified]
- Demo 2.1 after Task 2.1 and 2.2 reviewed
- Demo 3.1 after Phase 3 reviewed
- [Demos occur AFTER review passes, BEFORE next phase]

### Documentation Checkpoints
[When the documenter should be dispatched]
- After Phase 1 review passes
- After Phase 2 demo verified
- After final phase demo verified

---

## Demo Summary Table

| Demo | Phase | Verifies | Type | Prerequisites | Status |
|------|-------|----------|------|---------------|--------|
| 2.1 | 2 | Auth flow | script | 2.1, 2.2 | 🧪 |
| 3.1 | 3 | API integration | mini-project | 3.1, 3.2, 3.3 | 🧪 |
| ... | ... | ... | ... | ... | 🧪 |

---

## Task Summary Table

| Phase | Task | Subagent | Dependencies | Parallel? | Status |
|-------|------|----------|--------------|-----------|--------|
| 1 | 1.1 Setup project structure | worker | none | no | ⏳ |
| 1 | 1.2 Create base types | worker | none | yes (with 1.1) | ⏳ |
| 2 | 2.1 Implement auth service | executor | 1.1, 1.2 | no | ⏳ |
| 2 | Demo 2.1 Auth verification | worker | 2.1 reviewed | no | 🧪 |
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
- Demos verified: 0 of [N]

### Divergences from Plan
_(none yet)_

### Handoff History
_(none)_
