---
name: documentation
description: Documentation skills for maintaining README.md and AGENTS.md files. This skill should be used when "writing README files", "creating AGENTS.md", "updating project documentation", or "documenting code for AI assistants".
---

# Documentation Skills

A collection of skills for maintaining project documentation. Each skill focuses on a specific documentation audience and format.

## Activation Triggers

- Creating new project documentation
- Updating documentation after implementation changes
- Writing README files for human users
- Creating AGENTS.md files for AI coding assistants
- Reviewing documentation for completeness and accuracy
- The documenter subagent is processing phase completions

## Quick Routing

**Writing for human users?** → `readme-documentation`

**Writing for AI assistants?** → `agents-documentation`

## Skill Map

| Skill | Covers |
|-------|--------|
| [readme-documentation](references/readme-documentation/SKILL.md) | Guidelines for writing and updating README.md files for human readers including structure, examples, and best practices |
| [agents-documentation](references/agents-documentation/SKILL.md) | Guidelines for writing and updating AGENTS.md files for AI coding assistants including architecture patterns and conventions |
