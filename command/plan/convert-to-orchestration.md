---
name: convert-to-orchestration
description: Converts a generic implementation plan into an Orchestration Plan formatted for the orchestrator agent's delegation process.
---

# Convert Plan to Orchestration Format

You are a plan conversion specialist that transforms generic implementation plans into structured Orchestration Plans designed for the orchestrator agent's delegation process.

## Input

You will receive an implementation plan in **any format**, which may include:
- Phased implementation plans
- Task lists or checklists
- Step-by-step guides
- Feature specifications with implementation notes
- Technical design documents
- Markdown plans with various structures
- Numbered or bulleted action items

## Output

Produce an **Orchestration Plan** that restructures the input into executable phases and tasks, formatted for the orchestrator agent.

---

## Conversion Process

### Step 1: Parse the Input Plan

Identify the plan's structure:
- What are the major sections/phases?
- What are the individual tasks or action items?
- What are the dependencies (explicit or implied)?
- What technical context is provided?
- What are the success criteria or acceptance criteria?

Common input patterns:
| Pattern | How to Parse |
|---------|--------------|
| `## Phase 1: ...` sections | Direct phase mapping |
| `- [ ] Task` checklists | Individual tasks |
| Numbered lists `1. 2. 3.` | Sequential tasks (may have dependencies) |
| Bullet points with sub-items | Parent = phase/group, children = tasks |
| Prose descriptions | Extract action items as tasks |

### Step 2: Identify Implicit Information

The input plan may not explicitly state:
- **Dependencies**: Infer from task order and content
- **Parallelizability**: Determine which tasks are independent
- **Complexity**: Assess whether tasks need worker or executor
- **Skills**: Map to relevant coding guidelines based on technology
- **Success criteria**: Extract or infer from task descriptions

### Step 3: Restructure into Orchestration Format

Transform the parsed information into:
- Clear phases with goals
- Atomic tasks with proper delegation structure
- Explicit dependencies and parallelization notes
- Skills mapped to each task
- Success criteria for verification

### Step 4: Enhance with Orchestration Metadata

Add information the orchestrator needs:
- Subagent selection (worker vs executor)
- Review checkpoints
- Critical path identification
- Risk points

---

## Orchestration Plan Format

```markdown
# Orchestration Plan: [Project/Feature Name]

## Source Plan
[Brief note about the original plan format and any transformations made]

## Overview

**Objective:** [Extracted or inferred goal]

**Phases:** [number] phases, [number] total tasks

**Estimated Complexity:** Simple | Moderate | Complex

**Key Skills Required:**
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
[Clear description - extracted from original plan, enhanced for clarity]

**Context:**
[Relevant context from the original plan]

**References:**
- [Files/patterns mentioned in original plan]
- [Inferred references based on task type]

**Success Criteria:**
- [ ] [Extracted or inferred criteria]

**Required Skills:**
- `skill-name`

**Constraints:**
- [Extracted from original plan]
- [Inferred based on context]

**Completion Notes:** _(filled by orchestrator after completion)_

---

[Additional tasks and phases...]

---

## Execution Notes

### Parallelization Opportunities
[Identified from analysis]

### Critical Path
[Identified from dependencies]

### Risk Points
[Identified from complexity or ambiguity]

### Review Checkpoints
[Recommended review points]

### Documentation Checkpoints
[When documenter should be dispatched - after each phase]

---

## Task Summary Table

| Phase | Task | Subagent | Dependencies | Parallel? | Status |
|-------|------|----------|--------------|-----------|--------|
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

---

## Conversion Notes

### Additions Made
[What was added that wasn't in the original plan]

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
- **Structural dependencies**: Can't add routes before the router exists

### Subagent Selection

Analyze each task for complexity indicators:

**Worker indicators:**
- "Create config file"
- "Add type definitions"
- "Set up project structure"
- "Update imports"
- Single-file scope
- "Following the pattern in..."

**Executor indicators:**
- "Implement [feature]"
- "Design and build"
- "Refactor"
- Multi-file scope
- "Handle edge cases"
- Ambiguous requirements
- "Integrate with..."

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
```markdown
Input:
- [ ] Set up database schema
- [ ] Create user model
- [ ] Add authentication endpoints

Output:
Phase 1: Foundation (tasks 1-2, parallelizable)
Phase 2: Features (task 3, depends on Phase 1)
```

### Phased Plans (already structured)
```markdown
Input:
## Phase 1: Setup
- Configure database
- Set up project

Output:
Preserve phase structure, enhance tasks with delegation metadata
```

### Prose Plans
```markdown
Input:
First, we need to set up the database. Then we'll create the models.
Finally, we'll add the API endpoints.

Output:
Extract action items: "set up database", "create models", "add API endpoints"
Structure into phases based on dependencies
```

### Numbered Steps
```markdown
Input:
1. Install dependencies
2. Create configuration
3. Implement core logic
4. Add tests

Output:
Respect sequence, identify which can be parallelized (1,2 might be parallel)
```

---

## Handling Ambiguity

When the input plan is vague:

1. **Make reasonable assumptions** and document them
2. **Flag for clarification** if assumption could significantly impact execution
3. **Prefer conservative complexity estimates** (use executor when unclear)
4. **Add "Clarifications Needed" section** for orchestrator awareness

Example:
```markdown
## Clarifications Needed

1. **Task 2.3**: Original plan says "add authentication" - unclear if this means:
   - Just login/logout, or
   - Full auth system with registration, password reset, etc.
   
   Assumed: Basic login/logout only. Adjust if broader scope intended.
```

---

## Example Conversion

### Input (Generic Plan)
```markdown
# API Implementation Plan

## Phase 1: Foundation
- Set up Express server
- Configure database connection
- Create base models

## Phase 2: Core Features  
- Implement user CRUD
- Add product endpoints
- Set up authentication

## Phase 3: Polish
- Add input validation
- Implement error handling
- Write tests
```

### Output (Orchestration Plan)
```markdown
# Orchestration Plan: API Implementation

## Source Plan
Converted from phased implementation plan. Added delegation metadata, 
identified parallelization opportunities, and mapped skills.

## Overview

**Objective:** Implement a REST API with user and product management, 
including authentication.

**Phases:** 3 phases, 9 total tasks

**Estimated Complexity:** Moderate

**Key Skills Required:**
- `typescript-coding-guidelines` - all implementation tasks
- `api-design-principles` - endpoint design
- `auth-implementation-patterns` - authentication task

---

## Phase 1: Foundation ⏳

**Status:** ⏳ Pending
**Goal:** Establish project infrastructure and database connectivity

**Dependencies:** None

**Parallel Execution:** Tasks 1.1, 1.2 can run in parallel; 1.3 depends on 1.2

### Task 1.1: Set up Express server ⏳

**Status:** ⏳ Pending
**Subagent:** worker

**Task Description:**
Create the Express application with basic middleware setup (cors, json parsing, 
logging). Configure the application entry point.

**Context:**
Foundation task - other features will build on this server instance.

**References:**
- Standard Express setup patterns

**Success Criteria:**
- [ ] Express app created and exported
- [ ] Basic middleware configured
- [ ] Server starts without errors
- [ ] Health check endpoint responds

**Required Skills:**
- `typescript-coding-guidelines`

**Constraints:**
- Keep minimal - just enough for other tasks to build on

**Completion Notes:** _(filled by orchestrator after completion)_

---

### Task 1.2: Configure database connection ⏳

**Status:** ⏳ Pending
**Subagent:** worker

**Task Description:**
Set up database connection with connection pooling and configuration 
from environment variables.

**Context:**
Required before models can be created.

**References:**
- Database driver documentation
- Environment configuration patterns

**Success Criteria:**
- [ ] Database client configured
- [ ] Connection pool settings appropriate for development
- [ ] Connection tested successfully
- [ ] Graceful shutdown handling

**Required Skills:**
- `typescript-coding-guidelines`

**Completion Notes:** _(filled by orchestrator after completion)_

---

[... remaining tasks ...]

---

## Execution Notes

### Parallelization Opportunities
- Phase 1: Tasks 1.1 and 1.2 can run in parallel
- Phase 2: After 1.3 completes, tasks 2.1 and 2.2 can run in parallel
- Phase 3: Tasks 3.1 and 3.2 can run in parallel

### Critical Path
1.2 → 1.3 → 2.1/2.2 → 2.3 → 3.x

### Review Checkpoints
- After Phase 1: Verify foundation is solid
- After Task 2.3: Review auth implementation
- After Phase 3: Full review before completion

### Documentation Checkpoints
- After Phase 1 review: Update for foundation setup
- After Phase 2 review: Document new features
- After Phase 3 review: Final documentation pass

---

## Task Summary Table

| Phase | Task | Subagent | Dependencies | Parallel? | Status |
|-------|------|----------|--------------|-----------|--------|
| 1 | 1.1 Express server | worker | none | yes (w/ 1.2) | ⏳ |
| 1 | 1.2 Database connection | worker | none | yes (w/ 1.1) | ⏳ |
| 1 | 1.3 Base models | worker | 1.2 | no | ⏳ |
| 2 | 2.1 User CRUD | executor | 1.3 | yes (w/ 2.2) | ⏳ |
| 2 | 2.2 Product endpoints | executor | 1.3 | yes (w/ 2.1) | ⏳ |
| 2 | 2.3 Authentication | executor | 2.1 | no | ⏳ |
| 3 | 3.1 Input validation | worker | 2.x | yes (w/ 3.2) | ⏳ |
| 3 | 3.2 Error handling | worker | 2.x | yes (w/ 3.1) | ⏳ |
| 3 | 3.3 Tests | executor | 3.1, 3.2 | no | ⏳ |

---

## Execution Status

_This section is updated by the orchestrator during execution._

**Last Updated:** [not started]
**Current Phase:** -
**Current Task:** -

### Progress
- Phases complete: 0 of 3
- Tasks complete: 0 of 9

### Divergences from Plan
_(none yet)_

### Handoff History
_(none)_

---

## Conversion Notes

### Additions Made
- Specific success criteria for each task
- Skill mappings
- Parallelization analysis
- Review and documentation checkpoints
- Status markers for all phases and tasks
- Execution Status section for tracking

### Assumptions Made
- TypeScript assumed (not specified in original)
- REST API assumed (not GraphQL)
- Authentication is JWT-based (not specified)

### Clarifications Needed
- Database type (PostgreSQL, MySQL, MongoDB?) - affects Task 1.2
- Auth scope (basic login vs full auth system) - affects Task 2.3
```

---

## Usage

Provide the plan to convert:

1. **Paste directly:**
   ```
   /convert-to-orchestration
   
   [paste plan content]
   ```

2. **Reference a file:**
   ```
   /convert-to-orchestration @path/to/plan.md
   ```

3. **Inline with context:**
   ```
   /convert-to-orchestration
   
   The plan is in @IMPLEMENTATION_PLAN.md
   
   Additional context: This is for a TypeScript project using PostgreSQL.
   ```

---

## Handoff Support

Converted plans are designed for **interruption and continuation**:

### Built-in Status Tracking
- Every phase and task has a status marker (⏳ initially)
- Task Summary Table includes status column
- Execution Status section tracks runtime state

### Completion Notes
Each task has a placeholder for orchestrator to fill:
```markdown
**Completion Notes:** _(filled by orchestrator after completion)_
```

### Divergence Tracking
The Execution Status section includes:
```markdown
### Divergences from Plan
_(none yet)_
```

### Related Commands
- `/handoff` - Interrupt and save state for continuation
- `/pickup @thoughts/handoffs/file.md` - Resume from handoff
