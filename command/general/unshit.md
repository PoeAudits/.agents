---
name: unshit
description: Review codebase for bloat, unused/redundant code, and verbose implementations
---


## Phase 1: Discover Code Issues with Seeker Agents

Use the `task` tool with `subagent_type: seeker` to dispatch multiple parallel code reviews. Create at least 4-6 seeker agents to cover different aspects:

### Seeker 1: Find Dead/Unused Code
Launch seeker agent to find:
- Functions, methods, or classes never called/used
- Variables that are declared but never accessed
- Imports that are not used
- Dead code blocks (commented out code that's not documentation)
- Unreachable code paths

Instructions for seeker:
- Search for patterns like unused imports, variables assigned but never read
- Look for functions with no references outside their definition
- Check for exports that are never imported elsewhere
- Identify commented code blocks (not docstrings/comments explaining code)
- Return: File paths, line numbers/ranges, and brief description of each unused item found

### Seeker 2: Find Redundant Implementations
Launch seeker agent to find:
- Duplicate logic across multiple files/functions
- Functions doing similar things that could be unified
- Repeated patterns that could be abstracted
- Copy-paste code blocks
- Multiple implementations of the same utility/concept

Instructions for seeker:
- Look for similar function signatures and implementations
- Identify utility functions duplicated across files
- Find patterns where the same logic is written multiple times
- Check for identical or near-identical code blocks
- Return: Groups of redundant implementations with file paths and descriptions

### Seeker 3: Find Verbose/Overcomplicated Code
Launch seeker agent to find:
- Overly complex functions that could be simplified
- Nested conditionals/indents that are excessive (4+ levels)
- Functions with too many parameters (5+)
- Functions with too many lines (50+ lines is a threshold, 100+ is bloat)
- Classes with too many responsibilities
- Long chains of method calls or ternary operations

Instructions for seeker:
- Identify functions exceeding reasonable complexity metrics
- Look for deeply nested code blocks
- Find complex boolean expressions
- Check for premature abstraction that's overengineered
- Return: Locations with descriptions of how/why they're too verbose

### Seeker 4: Find Import/Dependency Bloat
Launch seeker agent to find:
- Heavy dependencies used for trivial tasks
- Multiple libraries doing the same thing
- Large imports where lighter alternatives exist
- Dependencies that could be replaced with standard library
- Unused or barely-used heavy dependencies

Instructions for seeker:
- Analyze package.json, requirements.txt, Cargo.toml, etc.
- Check if heavy dependencies are justified by their usage
- Look for cases where a 10-line utility could replace a dependency
- Identify dependency conflicts or redundancies
- Return: Dependency concerns with file paths and usage analysis

### Seeker 5: Find Configuration/Test Bloat
Launch seeker agent to find:
- Configuration files with unused settings
- Test files with excessive boilerplate
- Overly complex build configurations
- Duplicate test setups
- Dead configuration or stale tests

Instructions for seeker:
- Check config files for unused options
- Look for test patterns that are duplicated unnecessarily
- Identify tests that don't actually test anything meaningful
- Find configuration that could be simplified
- Return: Config/test bloat locations with descriptions

## Phase 2: Compile Findings

After all seeker agents return their results:

1. Consolidate all findings into a single report
2. Group issues by category:
   - Dead/Unused Code
   - Redundancy
   - Verbosity/Complexity
   - Dependency Bloat
   - Config/Test Bloat

3. For each issue, document:
   - Exact file path and line numbers
   - Brief description of the bloat issue
   - Severity (High/Medium/Low) based on impact
   - Estimated effort to fix (Quick/Medium/Complex)

## Phase 3: Create Improvement Plan

Craft a detailed plan to address the findings:

1. Prioritize issues by severity and effort
2. Group related fixes into batches
3. For each batch, outline:
   - What files need changes
   - What the general approach should be (without writing the actual code yet)
   - Any risks or considerations
   - Expected outcome/improvement

4. Create a plan document that:
   - Starts with a summary of total bloat found
   - Lists issues in priority order
   - Groups fixes into logical phases
   - Provides clear next steps for implementation

Do NOT implement the fixes yet - only identify the bloat and create the plan.

Output a comprehensive report showing what you found and the proposed plan to fix it.
