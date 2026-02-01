---
description: Find bloat, dead code, and redundancy then produce a cleanup plan
---

## Project Context

Project: !`basename "$(git rev-parse --show-toplevel 2>/dev/null)"`
Root: !`git rev-parse --show-toplevel 2>/dev/null`
Languages: !`find . -maxdepth 4 -type f \( -name '*.py' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.go' -o -name '*.rs' -o -name '*.sol' \) 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -5`
Dependency files: !`ls -1 package.json requirements.txt pyproject.toml Cargo.toml go.mod go.sum 2>/dev/null`
Top-level structure: !`ls -1`
Git status: !`git status --short | head -20`
Lines of code estimate: !`find . -type f \( -name '*.py' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.go' -o -name '*.rs' -o -name '*.sol' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/__pycache__/*' -not -path '*/vendor/*' 2>/dev/null | wc -l` source files

## Phase 0: Propose Scope and Get User Input

Based on the project context above, propose a review scope:
- Which directories contain the core source code
- Which directories to skip (generated, vendored, build output)
- Estimated scale of the review

Present the proposed scope to the user, then use the question tool to gather preferences:

**Question 1 - Review focus:**
- header: "Focus areas"
- question: "Which areas should this review focus on?"
- multiple: true
- options:
  - Dead code (Unused functions, imports, variables, unreachable paths)
  - Redundancy (Duplicate logic, copy-paste code, unifiable patterns)
  - Complexity (Verbose functions, deep nesting, overengineering)
  - Dependency bloat (Heavy/unused deps, stdlib replacements)
  - Config/test bloat (Stale config, duplicate test setup, dead tests)

**Question 2 - Depth:**
- header: "Depth"
- question: "How thorough should the review be?"
- options:
  - Quick scan (Top-level issues only, fast)
  - Standard (Recommended) (Balanced depth and speed)
  - Deep audit (Exhaustive, may take longer)

If the user comments on the proposed scope or adjusts it, incorporate their feedback before proceeding.

## Phase 1: Dispatch Seeker Agents

Use the `task` tool with `subagent_type: seeker` to dispatch parallel code reviews. Only dispatch seekers for the focus areas the user selected.

**Global seeker directives** (include in every seeker prompt):
- Respect `.gitignore` -- skip `node_modules`, `dist`, `build`, `__pycache__`, `.git`, `vendor`, and any other generated/vendored directories
- Scope to the directories agreed on in Phase 0
- Use the project context (languages, dependency files) to target searches
- Return: file path with line numbers/ranges, brief description, and estimated lines affected

### Seeker: Dead/Unused Code
Find functions, methods, or classes never called. Find variables declared but never accessed, unused imports, commented-out code blocks (not explanatory comments), unreachable code paths, and exports never imported elsewhere.

### Seeker: Redundant Implementations
Find duplicate logic across files/functions, near-identical code blocks, utility functions duplicated across modules, repeated patterns that could be abstracted, and multiple implementations of the same concept.

### Seeker: Verbose/Overcomplicated Code
Find functions with deep nesting (4+ levels), excessive parameters (5+), or excessive length (50+ lines). Find classes with too many responsibilities, complex boolean expressions, premature/overengineered abstractions, and long method chains.

### Seeker: Import/Dependency Bloat
Analyze the project's dependency files. Find heavy dependencies used for trivial tasks, multiple libraries doing the same thing, dependencies replaceable with stdlib, and unused or barely-used heavy packages. Quantify how many call sites use each flagged dependency.

### Seeker: Configuration/Test Bloat
Find configuration files with unused settings, test files with excessive boilerplate or duplicate setup, overly complex build configs, and tests that don't assert anything meaningful.

## Phase 2: Compile Findings

After all seeker agents return:

1. Consolidate findings into a single report grouped by category
2. For each issue, document:
   - Exact file path and line numbers
   - Brief description
   - **Impact score** (1-10): Weight by lines of code affected, how central the code is (imported by many vs leaf), and whether it's in a hot path
   - **Frequency**: How many times the pattern repeats across the codebase
   - **Fix effort** estimate: lines to change, files touched, risk of regression
3. Sort issues by impact score descending within each category
4. Produce a summary table: total issues found, total estimated lines of dead/redundant code, breakdown by category

## Phase 3: Create Improvement Plan

Craft a cleanup plan based on the compiled findings:

1. Rank all issues by `impact / effort` ratio (highest value fixes first)
2. Group related fixes into batches (e.g., "remove all unused imports" is one batch)
3. For each batch:
   - Files affected
   - Approach (without writing code)
   - Risk assessment and what to test after
   - Expected lines removed or simplified
4. Organize batches into phases: quick wins first, then medium effort, then deep refactors

## Phase 4: Save Report

Determine the project name from the project context above.

Save the full report (findings + plan) to:
`~/thoughts/projects/{project}/reviews/YYYY-MM-DD_unshit.md`

Use today's date. The report should include:
- YAML frontmatter with `project`, `date`, `scope`, and `summary`
- Full findings by category with the impact/effort data
- The prioritized improvement plan
- A "quick wins" section listing items fixable in under 5 minutes each

Present a summary to the user with the report file path and the top 5 highest-impact findings.
