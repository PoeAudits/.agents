---
name: ralph-plan
description: Creates an IMPLEMENTATION_PLAN.md optimized for Ralph Wiggum autonomous development loops
---

# Ralph Plan Command

Generate an IMPLEMENTATION_PLAN.md file optimized for Ralph Wiggum autonomous development.

**Arguments:** $ARGUMENTS

## Overview

Ralph-driven development forces an AI agent to re-read full context every iteration, eliminating context drift. Each Ralph loop iteration:

1. Reads the plan
2. Picks ONE task
3. Completes it
4. Commits (updating the plan in the same commit)
5. Repeats until done

This command creates a plan file structured for optimal Ralph consumption.

## Argument Parsing

Parse the provided arguments:

1. **Goal** (optional): Natural language description of what to accomplish
2. **--specs** (optional): Path to specs directory (default: `specs/`)
3. **--src** (optional): Path to source directory (default: `src/`)

**Examples:**
```
/ralph-plan
# Uses defaults, analyzes specs/ vs src/

/ralph-plan "implement user authentication with OAuth"
# Creates plan focused on the specified goal

/ralph-plan --specs ./requirements --src ./app
# Custom paths for specs and source
```

## Workflow

### Phase 1: Discovery

#### 1.1 Locate Specifications

Search for specification files:

```
Glob: specs/**/*.md
Glob: requirements/**/*.md
Glob: docs/specs/**/*.md
```

If no specs found, check for:
- README.md with requirements sections
- Issue tracker references
- Inline TODO/FIXME comments in code

#### 1.2 Analyze Existing Codebase

Explore the source directory structure:

```
Glob: src/**/*
Glob: lib/**/*
Glob: app/**/*
```

Identify:
- Existing patterns and conventions
- Shared utilities in `src/lib/` or similar
- Test structure and coverage

#### 1.3 Find Gaps and Incomplete Work

Search for indicators of incomplete implementation:

```
Grep: TODO|FIXME|HACK|XXX|PLACEHOLDER
Grep: NotImplementedError|throw.*not.?implement
Grep: \.skip\(|\.todo\(|pending\(|it\.todo\(|it\.skip\(|test\.todo\(|test\.skip\(|@pytest\.mark\.skip|@unittest\.skip|xit\(|xdescribe\(
```

Also look for:
- Stub implementations (`pass`, `throw new Error('Not implemented')`, empty function bodies)
- Commented-out code blocks
- Skipped or flaky tests
- Inconsistent patterns across similar files

**For each test placeholder found:** Create a task to either implement the test OR remove it if equivalent coverage exists elsewhere. Don't leave `it.todo()` or `@pytest.mark.skip` markers unaddressed.

### Phase 2: Gap Analysis

Compare specifications against existing code:

1. **For each spec file**, identify:
   - What functionality is specified
   - What acceptance criteria exist
   - What constraints are defined

2. **For each specified feature**, search the codebase:
   - Does implementation exist?
   - Is it complete or partial?
   - Does it match the specification?

3. **Categorize findings**:
   - NOT_STARTED: No implementation found
   - PARTIAL: Implementation exists but incomplete
   - INCONSISTENT: Implementation differs from spec
   - COMPLETE: Fully implemented per spec

**CRITICAL**: Do NOT assume functionality is missing. Confirm with code search first. Search thoroughly before marking anything as NOT_STARTED.

### Phase 3: Task Generation

Convert gaps into Ralph-consumable tasks following these principles:

#### Task Properties

Each task MUST be:
- **Atomic**: One logical change, one commit
- **Independent**: Completable without other pending tasks (respect dependencies)
- **Verifiable**: Has clear completion criteria
- **Specific**: No ambiguity about what to do

#### Task Format

Use checkbox format that Ralph parses:

```markdown
- [ ] <Concise task description>
```

#### Task Ordering

Order tasks by:
1. **Dependencies first**: Foundation before features
2. **Priority**: Critical path items early
3. **Risk**: Uncertain items early (fail fast)

#### Task Granularity

Each task should represent **one logical unit of work** - something Ralph can complete, test, and commit in a single iteration.

**Group related items** when they would naturally be implemented together:
- Multiple HTTP methods (GET/POST/PUT/DELETE) that share the same pattern
- Multiple CLI commands using the same framework
- Multiple similar validation rules following identical patterns
- Multiple related utility functions in the same module

**Keep separate** when items have different concerns:
- Different error types with distinct behaviors
- Features that touch different parts of the codebase
- Items with different testing requirements

**Anti-pattern - too granular:**
```markdown
- [ ] Implement GET method
- [ ] Implement POST method
- [ ] Implement PUT method
- [ ] Implement DELETE method
```

**Better - one logical unit:**
```markdown
- [ ] Implement HTTP methods (GET, POST, PUT, PATCH, DELETE) in src/client.ts
```

### Phase 4: Generate Plan

Create `IMPLEMENTATION_PLAN.md` with this structure:

```markdown
# Implementation Plan

> Generated: <timestamp>
> Goal: <goal description or "Full implementation per specs">

## Overview

<2-3 sentence summary of what this plan accomplishes>

## Progress

- [ ] Phase 1: Foundation (0/N)
- [ ] Phase 2: Core Features (0/N)
- [ ] Phase 3: Integration (0/N)
- [ ] Phase 4: Polish (0/N)

**Total: 0/X tasks complete**

## Already Implemented

<!-- List notable functionality that is complete per specs - no tasks needed -->
<!-- This helps Ralph avoid re-implementing existing work -->

- <function/class> in <file> - <brief note on what it does>

## Tasks

### Phase 1: Foundation (N tasks)
<!-- Infrastructure, setup, core utilities -->

- [ ] <task>
- [ ] <task>

### Phase 2: Core Features (N tasks)
<!-- Main functionality -->

- [ ] <task>
- [ ] <task>

### Phase 3: Integration (N tasks)
<!-- Connecting components, edge cases -->

- [ ] <task>
- [ ] <task>

### Phase 4: Polish (N tasks)
<!-- Tests, documentation, cleanup -->

- [ ] <task>
- [ ] <task>
- [ ] Final verification: run full test suite, confirm no TODOs/skipped tests remain, create `.ralph-done`

## Notes

<!-- Discoveries, constraints, decisions made during planning -->
```

#### Task Description Guidelines

Good task descriptions:
```markdown
- [ ] Create UserService class in src/services/user.ts with login() and logout() methods
- [ ] Add input validation for email field in RegistrationForm component
- [ ] Write unit tests for calculateTotal() covering edge cases: empty cart, negative quantities
```

When skipped tests exist, reference them:
```markdown
- [ ] Implement errors_by_field property (enables skipped test: test_errors_by_field)
- [ ] Add OAuth refresh logic (enables skipped tests: test_oauth_refresh, test_401_handling)
```

Bad task descriptions (too vague):
```markdown
- [ ] Implement authentication
- [ ] Fix the bug
- [ ] Add tests
```

### Phase 5: Validation

Before finalizing, verify:

1. **No duplicate work**: Check each task doesn't duplicate existing functionality
2. **Dependencies resolved**: Earlier tasks don't depend on later ones
3. **Completeness**: All gaps from analysis are addressed
4. **Granularity**: No task requires more than ~30 minutes of work

### Phase 6: Output

Write the plan to `IMPLEMENTATION_PLAN.md` in the current directory.

Provide a summary:

```
## Ralph Plan Generated

**File:** IMPLEMENTATION_PLAN.md
**Tasks:** X total (Y foundation, Z core, W integration, V polish)
**Specs analyzed:** N files
**Gaps found:** M items

**Ready for Ralph loop:**
```bash
# With opencode-ralph CLI
ralph

# Or manual loop
while :; do cat PROMPT.md | claude --dangerously-skip-permissions; done
```

**Remember:**
- Ralph picks ONE task per iteration
- Plan is disposable - regenerate if trajectory goes wrong
- Update AGENTS.md with operational learnings
```

## Plan Maintenance Notes

Include these notes in generated plans for Ralph:

```markdown
---

## For Ralph

When working from this plan:

1. Pick the FIRST unchecked task (order matters)
2. Search codebase before implementing (don't assume not implemented)
3. Complete the task fully - no placeholders or stubs
4. Mark task complete: `- [x]`
5. Update the Progress section counts
6. If you discover issues, add them as new tasks
7. If you learn operational details, update AGENTS.md
8. Commit the implementation AND plan update together
9. When ALL tasks complete: run final verification, create `.ralph-done`

**Plan Structure Rules:**
- Keep phases in original order (Phase 1, 2, 3, 4)
- Change only the checkbox: `- [ ]` to `- [x]`
- Do NOT move completed tasks to a separate section
- Do NOT reorder phases based on completion status

**Do NOT:**
- Skip tasks or change order without reason
- Leave partial implementations
- Forget to update this plan
- Push to remote (only commit)
```

## Error Handling

**No specs found:**
```
No specification files found in specs/, requirements/, or docs/specs/.

Options:
1. Create specs first: Document requirements in specs/<feature>.md
2. Provide path: /ralph-plan --specs <path>
3. Provide goal: /ralph-plan "description of what to build"
```

**No source directory:**
```
No source directory found. This appears to be a new project.

Creating plan for greenfield implementation based on specs.
```

**Goal too vague:**
```
The goal "<goal>" is too broad for effective planning.

Please be more specific. Examples:
- "Add OAuth2 authentication with Google and GitHub providers"
- "Implement shopping cart with add, remove, and checkout flows"
- "Create REST API for user management with CRUD operations"
```
