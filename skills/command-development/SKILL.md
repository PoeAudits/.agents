---
name: command-development
description: This skill should be used when the user asks to "create a slash command", "add a command", "write a custom command", "define command arguments", "use command frontmatter", "organize commands", "create command with file references", "interactive command", "use question tool in command", or needs guidance on slash command structure, YAML frontmatter fields, dynamic arguments, bash execution in commands, user interaction patterns, or command development best practices for Opencode.
version: 0.3.0
---

# Command Development for Opencode

## Overview

Slash commands are frequently-used prompts defined as Markdown files that the agent executes during interactive sessions. Command structure, frontmatter options, and dynamic features enable creating powerful, reusable workflows.

**Key concepts:**
- Markdown file format for commands
- YAML frontmatter for configuration
- Dynamic arguments and file references
- Bash execution for context
- Command organization and namespacing

## Command Basics

### What is a Slash Command?

A slash command is a Markdown file containing a prompt that the agent executes when invoked. Commands provide:
- **Reusability**: Define once, use repeatedly
- **Consistency**: Standardize common workflows
- **Sharing**: Distribute across team or projects
- **Efficiency**: Quick access to complex prompts

### Critical: Commands are Instructions FOR the Agent

**Commands are written for agent consumption, not human consumption.**

When a user invokes `/command-name`, the command content becomes the agent's instructions. Write commands as directives TO the agent about what to do, not as messages TO the user.

**Correct approach (instructions for the agent):**
```markdown
Review this code for security vulnerabilities including:
- SQL injection
- XSS attacks
- Authentication issues

Provide specific line numbers and severity ratings.
```

**Incorrect approach (messages to user):**
```markdown
This command will review your code for security issues.
You'll receive a report with vulnerability details.
```

The first example tells the agent what to do. The second tells the user what will happen but doesn't instruct the agent. Always use the first approach.

### Command Locations

**Project commands** (shared with team):
- Location: `.opencode/command/`
- Scope: Available in specific project
- Use for: Team workflows, project-specific tasks

**Personal commands** (available everywhere):
- Location: `~/.config/opencode/command/`
- Scope: Available in all projects
- Use for: Personal workflows, cross-project utilities

## File Format

### Basic Structure

Commands are Markdown files with `.md` extension:

```
.opencode/command/
├── review.md           # /review command
├── test.md             # /test command
└── deploy.md           # /deploy command
```

**Simple command:**
```markdown
Review this code for security vulnerabilities including:
- SQL injection
- XSS attacks
- Authentication bypass
- Insecure data handling
```

No frontmatter needed for basic commands.

### With YAML Frontmatter

Add configuration using YAML frontmatter:

```markdown
---
description: Review code for security issues
model: anthropic/claude-sonnet-4
---

Review this code for security vulnerabilities...
```

## YAML Frontmatter Fields

### description

**Purpose:** Brief description shown in `/help`
**Type:** String
**Default:** First line of command prompt

```yaml
---
description: Review pull request for code quality
---
```

**Best practice:** Clear, actionable description (under 60 characters)

### model

**Purpose:** Specify model for command execution
**Type:** String
**Default:** Inherits from conversation

```yaml
---
model: anthropic/claude-haiku-4-5
---
```

**Use cases:**
- `anthropic/claude-haiku-4-5` - Fast, simple commands
- `anthropic/claude-sonnet-4` - Standard workflows
- `anthropic/claude-opus-4-5` - Complex analysis

### argument-hint

### agent

**Purpose:** Route command execution to a specific agent
**Type:** String
**Default:** None (uses default agent)

```yaml
---
agent: code-reviewer
---
```

**Use when:** Command is handled by a specialized agent with its own system prompt and configuration.




## Dynamic Arguments

### Using $ARGUMENTS

Capture all arguments as single string:

```markdown
---
description: Fix issue by number
argument-hint: [issue-number]
---

Fix issue #$ARGUMENTS following our coding standards and best practices.
```

**Usage:**
```
> /fix-issue 123
> /fix-issue 456
```

**Expands to:**
```
Fix issue #123 following our coding standards...
Fix issue #456 following our coding standards...
```

### Using Positional Arguments

Capture individual arguments with `$1`, `$2`, `$3`, etc.:

```markdown
---
description: Review PR with priority and assignee
argument-hint: [pr-number] [priority] [assignee]
---

Review pull request #$1 with priority level $2.
After review, assign to $3 for follow-up.
```

**Usage:**
```
> /review-pr 123 high alice
```

**Expands to:**
```
Review pull request #123 with priority level high.
After review, assign to alice for follow-up.
```

### Combining Arguments

Mix positional and remaining arguments:

```markdown
Deploy $1 to $2 environment with options: $3
```

**Usage:**
```
> /deploy api staging --force --skip-tests
```

**Expands to:**
```
Deploy api to staging environment with options: --force --skip-tests
```

## File References

### Using @ Syntax

Include file contents in command:

```markdown
---
description: Review specific file
argument-hint: [file-path]
---

Review @$1 for:
- Code quality
- Best practices
- Potential bugs
```

**Usage:**
```
> /review-file src/api/users.ts
```

**Effect:** The agent reads `src/api/users.ts` before processing command

### Multiple File References

Reference multiple files:

```markdown
Compare @src/old-version.js with @src/new-version.js

Identify:
- Breaking changes
- New features
- Bug fixes
```

### Static File References

Reference known files without arguments:

```markdown
Review @package.json and @tsconfig.json for consistency

Ensure:
- TypeScript version matches
- Dependencies are aligned
- Build configuration is correct
```

## Bash Execution in Commands

Commands can execute bash commands inline to dynamically gather context before the agent processes the command. This is useful for including repository state, environment information, or project-specific context.

**Use when:**
- Including dynamic context (git status, environment vars, etc.)
- Gathering project/repository state
- Building context-aware workflows

**Syntax:** Use `!` followed by a backtick-wrapped command:

```markdown
Current branch: !`git branch --show-current`
Recent commits: !`git log --oneline -5`
```

The bash output is substituted into the command text before the agent processes it.

## Command Organization

### Flat Structure

Simple organization for small command sets:

```
.opencode/command/
├── build.md
├── test.md
├── deploy.md
├── review.md
└── docs.md
```

**Use when:** 5-15 commands with no clear categories

### Namespaced Structure

Organize commands in subdirectories:

```
.opencode/command/
├── ci/
│   ├── build.md        # /ci/build
│   ├── test.md         # /ci/test
│   └── lint.md         # /ci/lint
├── git/
│   ├── commit.md       # /git/commit
│   └── pr.md           # /git/pr
└── docs/
    ├── generate.md     # /docs/generate
    └── publish.md      # /docs/publish
```

**Benefits:**
- Logical grouping by category
- Namespace shown in `/help`
- Easier to find related commands

**Use when:** 15+ commands with clear categories

## Best Practices

### Command Design

1. **Single responsibility:** One command, one task
2. **Clear descriptions:** Self-explanatory in `/help`
3. **Document arguments:** Always provide `argument-hint`
4. **Consistent naming:** Use verb-noun pattern (review-pr, fix-issue)

### Argument Handling

1. **Validate arguments:** Check for required arguments in prompt
2. **Provide defaults:** Suggest defaults when arguments missing
3. **Document format:** Explain expected argument format
4. **Handle edge cases:** Consider missing or invalid arguments

```markdown
---
argument-hint: [pr-number]
---

$IF($1,
  Review PR #$1,
  Please provide a PR number. Usage: /review-pr [number]
)
```

### File References

1. **Explicit paths:** Use clear file paths
2. **Check existence:** Handle missing files gracefully
3. **Relative paths:** Use project-relative paths
4. **Glob support:** Consider using glob tool for patterns

### Bash Commands

1. **Safe commands:** Avoid destructive operations
2. **Handle errors:** Consider command failures
3. **Keep fast:** Long-running commands slow invocation

### Documentation

1. **Add comments:** Explain complex logic
2. **Provide examples:** Show usage in comments
3. **List requirements:** Document dependencies
4. **Version commands:** Note breaking changes

```markdown
---
description: Deploy application to environment
argument-hint: [environment] [version]
---

<!--
Usage: /deploy [staging|production] [version]
Requires: AWS credentials configured
Example: /deploy staging v1.2.3
-->

Deploy application to $1 environment using version $2...
```

## Common Patterns

### Review Pattern

```markdown
---
description: Review code changes
---

Files changed: !`git diff --name-only`

Review each file for:
1. Code quality and style
2. Potential bugs or issues
3. Test coverage
4. Documentation needs

Provide specific feedback for each file.
```

### Testing Pattern

```markdown
---
description: Run tests for specific file
argument-hint: [test-file]
---

Run tests: !`npm test $1`

Analyze results and suggest fixes for failures.
```

### Documentation Pattern

```markdown
---
description: Generate documentation for file
argument-hint: [source-file]
---

Generate comprehensive documentation for @$1 including:
- Function/class descriptions
- Parameter documentation
- Return value descriptions
- Usage examples
- Edge cases and errors
```

### Workflow Pattern

```markdown
---
description: Complete PR workflow
argument-hint: [pr-number]
---

PR #$1 Workflow:

1. Fetch PR: !`gh pr view $1`
2. Review changes
3. Run checks
4. Approve or request changes
```

### Agent-Routed Pattern

```markdown
---
description: Deep code review
argument-hint: [file-path]
agent: code-reviewer
---

Perform a comprehensive review of @$1 analyzing:
- Code structure
- Security issues
- Performance
- Best practices
```

### Subagent Pattern

```markdown
---
description: Comprehensive review workflow
argument-hint: [file]
subtask: true
---

Target: @$1

Phase 1 - Static Analysis:
!`npm run lint -- $1`

Phase 2 - Deep Review:
Analyze code structure, security, and performance.

Phase 3 - Report:
Compile findings into a structured report.
```

## Troubleshooting

**Command not appearing:**
- Check file is in correct directory
- Verify `.md` extension present
- Ensure valid Markdown format
- Restart Opencode

**Arguments not working:**
- Verify `$1`, `$2` syntax correct
- Check `argument-hint` matches usage
- Ensure no extra spaces

**Bash execution failing:**
- Verify command syntax in backticks
- Test command in terminal first
- Check for required permissions

**File references not working:**
- Verify `@` syntax correct
- Check file path is valid
- Use absolute or project-relative paths

## Validation Patterns

Commands should validate inputs and resources before processing.

### Argument Validation

```markdown
---
description: Deploy with validation
argument-hint: [environment]
---

Validate environment: !`echo "$1" | grep -E "^(dev|staging|prod)$" || echo "INVALID"`

If $1 is valid environment:
  Deploy to $1
Otherwise:
  Explain valid environments: dev, staging, prod
  Show usage: /deploy [environment]
```

### File Existence Checks

```markdown
---
description: Process configuration
argument-hint: [config-file]
---

Check file exists: !`test -f $1 && echo "EXISTS" || echo "MISSING"`

If file exists:
  Process configuration: @$1
Otherwise:
  Explain where to place config file
  Show expected format
  Provide example configuration
```

### Error Handling

```markdown
---
description: Build with error handling
---

Execute build: !`bash scripts/build.sh 2>&1 || echo "BUILD_FAILED"`

If build succeeded:
  Report success and output location
If build failed:
  Analyze error output
  Suggest likely causes
  Provide troubleshooting steps
```

**Best practices:**
- Validate early in command
- Provide helpful error messages
- Suggest corrective actions
- Handle edge cases gracefully

---

## Additional Resources

### Reference Files
- **`references/frontmatter-reference.md`** - Complete frontmatter field reference
- **`references/interactive-commands.md`** - Patterns for interactive command workflows
- **`references/testing-strategies.md`** - Strategies for testing commands
- **`references/documentation-patterns.md`** - Documentation patterns for commands
- **`references/advanced-workflows.md`** - Advanced command workflow patterns

### Examples
- **`examples/`** - Command pattern examples
