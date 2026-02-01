---
description: Initialize or update project AGENTS.md
argument-hint: [focus-area]
---

<!--
PURPOSE:
Generates or updates the AGENTS.md file for the current project by
analyzing the codebase and synthesizing findings into a structured
document that other AI agents can use as context.

USAGE:
  /init              - Full initialization or update
  /init testing      - Focus on testing conventions
  /init architecture - Focus on architecture and patterns

RELATED COMMANDS:
  /commit - Commit changes after reviewing the generated AGENTS.md
-->

# Initialize AGENTS.md

Load the agents-documentation skill before writing any content.

## Step 1: Detect Current State

Existing AGENTS.md: !`test -f AGENTS.md && echo "EXISTS" || echo "NONE"`
Project root contents: !`ls -1`
Git remote: !`git remote get-url origin 2>/dev/null || echo "no remote"`

If AGENTS.md exists, read it and note its current sections for comparison.

## Step 2: Research the Codebase

Use task tool with seeker agents to gather the following. Launch multiple agents in parallel where possible.

Focus area (if provided): $1

### Research checklist

- **Tech stack**: Languages, frameworks, major dependencies
- **Directory structure**: Top-level layout, where source/test/config lives
- **Build and run**: How to install deps, build, run, and test (Makefile, package.json scripts, etc.)
- **Code conventions**: Naming patterns, file organization, import style
- **Key patterns**: Architecture patterns, state management, error handling
- **Configuration**: Environment variables, config files, secrets handling
- **Testing**: Test framework, test location, how to run tests
- **CI/CD**: Pipeline config, deployment process

If a focus area was provided via $1, prioritize that area but still gather baseline info for all sections.

## Step 3: Synthesize into AGENTS.md

Structure the AGENTS.md with these sections (adapt headings to fit the project):

1. **Project overview** - What this project is, in 1-2 sentences
2. **Tech stack** - Languages, frameworks, key dependencies
3. **Directory structure** - Brief map of important directories
4. **Getting started** - Install, build, run, test commands
5. **Code conventions** - Naming, formatting, patterns to follow
6. **Architecture** - Key patterns, data flow, module boundaries
7. **Testing** - Framework, conventions, how to run
8. **Common tasks** - Frequent development workflows

## Step 4: Handle Create vs Update

If AGENTS.md does **not** exist:
- Create it with all sections from Step 3
- Present the full document to the user for review

If AGENTS.md **already exists**:
- Compare current content against research findings
- Update outdated sections in place
- Flag any content that appears deprecated or no longer matches the codebase
- Present a summary of changes to the user:
  - Sections added
  - Sections updated (with what changed)
  - Deprecated content flagged

## Step 5: Confirm with User

Use the question tool to ask:

- header: "Review"
- question: "AGENTS.md has been drafted. How would you like to proceed?"
- options:
  - Apply as-is (Write the file)
  - Show full preview (Display before writing)
  - Adjust sections (Let me specify changes)
