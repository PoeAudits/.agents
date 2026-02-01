---
description: Transform a Planning Brief into an Orchestration Plan with demos
argument-hint: [@planning-brief] [additional instructions]
---

# Planning Brief to Orchestration Plan (with Demo Verification)

## Input

Planning Brief: $1

Additional instructions: $2

Project directory: !`pwd`

## Goal

Transform the Planning Brief into a structured Orchestration Plan with phases, tasks, and demo verification checkpoints, formatted for the orchestrator agent. This version includes **demo verification tasks** to confirm implementations work before proceeding.

---

## Transformation Process

### Step 1: Analyze the Brief

Before planning, understand:
1. What is the end goal?
2. What are the major components/areas of work?
3. What are the dependencies between components?
4. What can be parallelized?
5. What skills are relevant?
6. **What functionality needs demo verification?**

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

### Step 4: Identify Demo Checkpoints

After analyzing tasks, identify natural points where **demo verification** should occur:

**Include a demo when:**
- A new user-facing feature is complete
- A new integration is working
- Complex business logic has been implemented
- A significant behavioral change has been made
- The feature could affect downstream implementations

**Skip demos for:**
- Pure refactoring with no behavioral change
- Configuration or setup tasks
- Internal utilities with no user-visible behavior
- Tasks that are verified by existing tests

### Step 5: Classify Tasks

For each task, determine:
- **Subagent**: worker (straightforward) vs executor (complex)
- **Dependencies**: what must complete first
- **Parallelizable**: can run alongside other tasks
- **Skills**: relevant coding guidelines or patterns

For each demo task:
- **Demo type**: script (simple) vs mini-project (complex)
- **What it verifies**: specific functionality being tested
- **Prerequisites**: what must be working for the demo

---

## Orchestration Plan Format

Follow the plan template defined in: @.agents/command/plan/orchestration-plan-with-demos-template.md

---

## Status Markers

Use these markers consistently throughout the plan:

| Marker | Meaning | When to Use |
|--------|---------|-------------|
| `⏳` | Pending | Not started yet |
| `🔄` | In Progress | Currently being worked on |
| `📝` | Needs Review | Implementation done, awaiting review |
| `🔧` | Needs Fix | Review found issues |
| `🧪` | Pending Demo | Review passed, demo needs creation/verification |
| `👤` | Awaiting User | Demo created, waiting for user verification |
| `📄` | Needs Docs | Demo verified, awaiting documentation |
| `✅` | Complete | Fully done including docs |
| `⚠️` | Blocked | Cannot proceed |
| `❌` | Failed | Needs attention |
| `⏸️` | Paused | Interrupted (handoff) |

### Status Flow (with Demos)

```
⏳ Pending
   ↓
🔄 In Progress
   ↓
📝 Needs Review
   ↓
[Review Pass] → 🧪 Pending Demo (if demo required)
   ↓              ↓
[Review Fail]    👤 Awaiting User (demo created)
   ↓              ↓
🔧 Needs Fix     [User Verified] → 📄 Needs Docs → ✅ Complete
   ↓
🔄 In Progress (loop)
```

### Flow Without Demo

```
⏳ → 🔄 → 📝 → [Review Pass] → 📄 → ✅
```

---

## Demo Task Guidelines

### When to Include Demos

**DO include a demo for:**
- New user-facing features (UI, CLI commands, API endpoints)
- New integrations (external APIs, databases, services)
- Complex business logic that could have subtle bugs
- Behavioral changes that downstream code depends on
- Features the user specifically wants to verify

**DON'T include a demo for:**
- Pure refactoring (behavior unchanged)
- Configuration/setup tasks
- Internal utilities (unless they affect user-visible behavior)
- Tasks already covered by unit/integration tests
- Simple type definitions or interfaces

### Demo Complexity Selection

| Choose Script When | Choose Mini-Project When |
|--------------------|--------------------------|
| Single function/endpoint to test | Multiple components interact |
| Simple input → output verification | Requires setup (config, env, data) |
| Can run with a single command | Needs its own dependencies |
| No persistent state needed | Demonstrates a workflow or flow |
| < 50 lines of demo code | Realistic usage scenario |

### Demo Directory Structure

Each demo lives in its own directory under `demo/`:

```
demo/
├── auth-flow/
│   ├── Makefile           # run and clean targets
│   ├── README.md          # verification instructions
│   └── test_auth.py       # demo script
│
├── api-integration/
│   ├── Makefile
│   ├── README.md
│   ├── package.json       # mini-project deps
│   ├── src/
│   │   └── demo.ts
│   └── .gitignore
│
└── data-pipeline/
    ├── Makefile
    ├── README.md
    └── run_pipeline.sh
```

### Demo Makefile Template

Every demo directory must have a Makefile with at least these targets:

```makefile
# demo/<feature-name>/Makefile

.PHONY: run clean help

help:
	@echo "Demo: <Feature Name>"
	@echo ""
	@echo "Targets:"
	@echo "  run    - Run the demo"
	@echo "  clean  - Remove all demo artifacts and side effects"
	@echo ""
	@echo "See README.md for verification instructions."

run:
	# Command(s) to run the demo
	python test_auth.py

clean:
	# Command(s) to clean up side effects
	rm -rf ./output
	rm -f ./*.log
```

For mini-projects, include additional targets as needed:

```makefile
.PHONY: run clean setup help

help:
	@echo "Demo: <Feature Name>"
	@echo ""
	@echo "Targets:"
	@echo "  setup  - Install dependencies"
	@echo "  run    - Run the demo"
	@echo "  clean  - Remove all demo artifacts and side effects"

setup:
	npm install

run: setup
	npm start

clean:
	rm -rf node_modules
	rm -rf dist
	rm -rf ./output
```

### Demo README Template

Every demo must have a README.md following this structure:

```markdown
# Demo: [Feature Name]

## What This Tests

[1-2 sentences describing what functionality this demo verifies]

## New Functionality Being Verified

- [Specific feature 1]
- [Specific feature 2]
- [Behavior that was just implemented]

## Prerequisites

- [Required setup, e.g., "API server running on localhost:3000"]
- [Environment variables needed]
- [Any data or state that must exist]

## How to Run

\`\`\`bash
cd demo/<feature-name>
make run
\`\`\`

## Expected Output

[What the user should see when the demo runs successfully]

\`\`\`
Example output here...
\`\`\`

## Verification Checklist

- [ ] [Specific thing to verify - e.g., "Response contains user ID"]
- [ ] [Another verification point - e.g., "Token expires after 1 hour"]
- [ ] [Edge case to check - e.g., "Invalid credentials return 401"]

## How to Clean Up

\`\`\`bash
make clean
\`\`\`

This removes:
- [List of artifacts/side effects that get cleaned up]

## Troubleshooting

**Problem:** [Common issue]
**Solution:** [How to fix it]
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
- **All demo creation tasks**

### Use Executor For:
- Multi-file coordinated changes
- Complex business logic
- New patterns or architecture
- Ambiguous requirements requiring judgment
- Full feature implementations
- Tasks requiring design decisions
- Estimated > 100 lines or uncertain scope

**When in doubt, choose executor (except for demos - always worker).**

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

### Example Good Demo Task

```markdown
### Demo 2.1: Authentication Flow Verification 🧪

**Status:** 🧪 Pending Demo
**Subagent:** worker
**Demo Type:** script

**What This Verifies:**
The JWT authentication flow - login with valid credentials returns tokens,
invalid credentials are rejected, and tokens can be used to access protected endpoints.

**Prerequisites:**
- Task 2.1 (Auth Service) reviewed and passing
- Task 2.2 (Auth Middleware) reviewed and passing

**Demo Description:**
Create a Python script that exercises the authentication endpoints:
1. Attempt login with invalid credentials (expect 401)
2. Login with valid test credentials (expect tokens)
3. Use access token to hit a protected endpoint (expect success)
4. Use expired/invalid token (expect 401)

**Demo Location:** `demo/auth-flow/`

**Expected Behavior:**
- Invalid login returns 401 with error message
- Valid login returns { accessToken, refreshToken }
- Protected endpoint returns user data with valid token
- Protected endpoint returns 401 with invalid token

**Verification Steps:**
1. Start the API server: `make run-server`
2. Run the demo: `cd demo/auth-flow && make run`
3. Verify output shows all 4 test cases passing
4. Check that tokens have correct expiry (1 hour access, 7 day refresh)

**Cleanup:**
- No persistent side effects (uses test database that resets)
- Run `make clean` to remove any log files

**Completion Notes:** _(filled by orchestrator after demo verified)_
```

---

## Handling Complexity

### For Simple Briefs (2-4 tasks)
- May only need 1-2 phases
- Most tasks can be worker-level
- Minimal parallelization needed
- **0-1 demos** (only if user-facing behavior)

### For Moderate Briefs (5-10 tasks)
- 2-3 phases typical
- Mix of worker and executor tasks
- Look for parallelization in setup phase
- **1-2 demos** at key feature completions

### For Complex Briefs (10+ tasks)
- 3-5 phases
- Multiple executor tasks
- Critical path analysis important
- More review checkpoints needed
- Consider breaking into multiple plans
- **2-4 demos** at phase boundaries and major features

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
- [ ] **Demo checkpoints are identified at natural feature completion points**
- [ ] **Each demo has: type, what it verifies, prerequisites, expected behavior**
- [ ] **Demo Summary Table is populated**
- [ ] Documentation checkpoints are identified (after demos verified)
- [ ] Critical path is clear
- [ ] All phases have status markers (⏳)
- [ ] All tasks have status markers (⏳)
- [ ] All demos have status markers (🧪)
- [ ] Task Summary Table includes demos and status column
- [ ] Execution Status section is present

---

## Handoff Support

Plans are designed for **interruption and continuation**. The structure supports:

### Status Tracking
- Every phase, task, and demo has a status marker
- Task Summary Table provides at-a-glance progress
- Demo Summary Table shows verification status
- Execution Status section tracks runtime state

### Completion Notes
Each task and demo has a "Completion Notes" field that the orchestrator fills after completion:
```markdown
**Completion Notes:**
- Implemented in `src/services/auth.service.ts`
- Added 3 test files
- Used existing error pattern from utils
```

For demos:
```markdown
**Completion Notes:**
- Demo created at `demo/auth-flow/`
- User verified on 2024-01-15
- All verification checks passed
```

### Divergence Tracking
The Execution Status section tracks any deviations:
```markdown
### Divergences from Plan
- Task 2.1: Used Passport.js instead of custom JWT (simpler)
- Task 2.3: Split into 2.3a and 2.3b (too large)
- Demo 2.1: Added extra test case for token refresh
```

### Handoff Ready
When `/handoff` is invoked, the plan already has:
- Clear status on every task and demo
- Completion notes on finished work
- Divergences documented
- Current position identifiable

---

## Orchestrator Flow with Demos

The orchestrator follows this flow for each phase:

```
FOR each phase:
│
├─► FOR each task in phase:
│   │
│   ├─► GATHER CONTEXT (dispatch seeker if needed)
│   ├─► SELECT SUBAGENT (worker vs executor)
│   ├─► DELEGATE with structured prompt
│   ├─► REVIEW (dispatch reviewer)
│   └─► HANDLE ISSUES (if review finds problems)
│
├─► IF phase has demo checkpoint:
│   │
│   ├─► DISPATCH WORKER to create demo
│   │   └─ Include: demo location, what to verify, expected behavior
│   │
│   ├─► NOTIFY USER demo is ready
│   │   └─ "Demo created at demo/<feature>/. Please run and verify."
│   │
│   └─► WAIT for user confirmation
│       └─ Do not proceed until user confirms demo works
│
└─► DOCUMENT (dispatch documenter after demo verified)
```

### Demo Creation Prompt Template

When dispatching worker to create a demo:

```markdown
## Task
Create a verification demo for [feature name].

## Demo Location
`demo/[feature-name]/`

## What This Demo Should Verify
[From the demo task description - specific functionality]

## Demo Type
[script | mini-project]

## Expected Behavior
[What should happen when the demo runs]

## Required Files
Create these files:
- `Makefile` with `run` and `clean` targets
- `README.md` following the demo README template
- Demo script/code that exercises the functionality

## Verification Steps to Document
[Steps the user will follow to verify]

## Cleanup Requirements
[What side effects need cleanup - files, state, etc.]

## References
- Implementation files: [list of files just implemented]
- API/interface: [relevant interfaces to call]

## Success Criteria
- [ ] Demo directory created with Makefile and README
- [ ] `make run` executes the demo successfully
- [ ] `make clean` removes all side effects
- [ ] README contains clear verification instructions
- [ ] Demo exercises the new functionality specifically
```

---

Save the plan to the ~/thoughts/projects directory under the current project's directory.
