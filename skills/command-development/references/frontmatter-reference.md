# Command Frontmatter Reference

Complete reference for YAML frontmatter fields in slash commands.

## Frontmatter Overview

YAML frontmatter is optional metadata at the start of command files:

```markdown
---
description: Brief description
model: anthropic/claude-sonnet-4-5
argument-hint: [arg1] [arg2]
---

Command prompt content here...
```

All fields are optional. Commands work without any frontmatter.

## Field Specifications

### description

**Type:** String
**Required:** No
**Default:** First line of command prompt
**Max Length:** ~60 characters recommended for `/help` display

**Purpose:** Describes what the command does, shown in `/help` output

**Examples:**
```yaml
description: Review code for security issues
```
```yaml
description: Deploy to staging environment
```
```yaml
description: Generate API documentation
```

**Best practices:**
- Keep under 60 characters for clean display
- Start with verb (Review, Deploy, Generate)
- Be specific about what command does
- Avoid redundant "command" or "slash command"

**Good:**
- ✅ "Review PR for code quality and security"
- ✅ "Deploy application to specified environment"
- ✅ "Generate comprehensive API documentation"

**Bad:**
- ❌ "This command reviews PRs" (unnecessary "This command")
- ❌ "Review" (too vague)
- ❌ "A command that reviews pull requests for code quality, security issues, and best practices" (too long)

### model

**Type:** String
**Required:** No
**Default:** Inherits from conversation
**Values:** `anthropic/claude-sonnet-4-5`, `anthropic/claude-opus-4-5`, `anthropic/claude-haiku-4-5`, `inherit`

**Purpose:** Specify which model executes the command

**Examples:**
```yaml
model: anthropic/claude-haiku-4-5    # Fast, efficient for simple tasks
```
```yaml
model: anthropic/claude-sonnet-4-5     # Balanced performance (default)
```
```yaml
model: anthropic/claude-opus-4-5     # Maximum capability for complex tasks
```
```yaml
model: inherit                       # Use the current conversation model
```

**When to use:**

**Use `anthropic/claude-haiku-4-5` for:**
- Simple, formulaic commands
- Fast execution needed
- Low complexity tasks
- Frequent invocations

```yaml
---
description: Format code file
model: anthropic/claude-haiku-4-5
---
```

**Use `anthropic/claude-sonnet-4-5` for:**
- Standard commands (default)
- Balanced speed/quality
- Most common use cases

```yaml
---
description: Review code changes
model: anthropic/claude-sonnet-4-5
---
```

**Use `anthropic/claude-opus-4-5` for:**
- Complex analysis
- Architectural decisions
- Deep code understanding
- Critical tasks

```yaml
---
description: Analyze system architecture
model: anthropic/claude-opus-4-5
---
```

**Best practices:**
- Omit unless specific need
- Use `anthropic/claude-haiku-4-5` for speed when possible
- Reserve `anthropic/claude-opus-4-5` for genuinely complex tasks
- Test with different models to find right balance

### argument-hint

**Type:** String
**Required:** No
**Default:** None

**Purpose:** Document expected arguments for users and autocomplete

**Format:**
```yaml
argument-hint: [arg1] [arg2] [optional-arg]
```

**Examples:**

**Single argument:**
```yaml
argument-hint: [pr-number]
```

**Multiple required arguments:**
```yaml
argument-hint: [environment] [version]
```

**Optional arguments:**
```yaml
argument-hint: [file-path] [options]
```

**Descriptive names:**
```yaml
argument-hint: [source-branch] [target-branch] [commit-message]
```

**Best practices:**
- Use square brackets `[]` for each argument
- Use descriptive names (not `arg1`, `arg2`)
- Indicate optional vs required in description
- Match order to positional arguments in command
- Keep concise but clear

**Examples by pattern:**

**Simple command:**
```yaml
---
description: Fix issue by number
argument-hint: [issue-number]
---

Fix issue #$1...
```

**Multi-argument:**
```yaml
---
description: Deploy to environment
argument-hint: [app-name] [environment] [version]
---

Deploy $1 to $2 using version $3...
```

**With options:**
```yaml
---
description: Run tests with options
argument-hint: [test-pattern] [options]
---

Run tests matching $1 with options: $2
```

### agent

**Type:** String
**Required:** No
**Default:** None (uses the default agent)

**Purpose:** Specify which agent executes the command. Useful when you have custom agents defined and want a command to always run with a particular agent's system prompt and configuration.

**Examples:**
```yaml
agent: code-reviewer
```
```yaml
agent: deployment-manager
```
```yaml
agent: security-auditor
```

**Best practices:**
- Only specify when the command requires a specific agent's capabilities
- Ensure the referenced agent is defined in your project or global config
- Omit to use the default agent
- Use descriptive agent names that match their purpose
- Document why a specific agent is needed in command comments
- If this is a subagent the command will trigger a subagent invocation by default; to disable this behavior, set `subtask: false`

**Usage patterns:**

**Code review with specialized agent:**
```yaml
---
description: Review code for security issues
agent: security-auditor
---

Review the current changes for security vulnerabilities...
```

**Deployment with ops agent:**
```yaml
---
description: Deploy to staging
agent: deployment-manager
argument-hint: [environment]
---

Deploy to $1 environment following the deployment runbook.
```

### subtask

**Type:** Boolean
**Required:** No
**Default:** false

**Purpose:** Forces the command to run as a subtask (subagent invocation). When enabled, the command executes in an isolated context with its own conversation, preventing it from polluting the main conversation history. Useful for self-contained operations that should not affect the parent context.

**Examples:**
```yaml
subtask: true
```

**When to use:**

1. **Isolated operations:** Commands that should not affect main conversation state
   ```yaml
   ---
   description: Analyze codebase metrics
   subtask: true
   ---
   ```

2. **Heavy processing:** Commands that generate large amounts of intermediate output
   ```yaml
   ---
   description: Generate comprehensive test suite
   subtask: true
   model: anthropic/claude-opus-4-5
   ---
   ```

3. **Reusable utilities:** Commands invoked programmatically that need clean context
   ```yaml
   ---
   description: Lint and fix file
   subtask: true
   ---
   ```

**Default behavior (false):**
- Command runs in the current conversation context
- Output and context are part of the main conversation

**When true:**
- Command runs in an isolated subagent context
- Results are returned to the parent conversation
- Intermediate steps do not clutter main history

**Best practices:**
- Use for commands that produce verbose intermediate output
- Use when command should not have side effects on conversation state
- Combine with `agent` field to run specialized agents as subtasks
- Omit unless isolation is specifically needed

## Complete Examples

### Minimal Command

No frontmatter needed:

```markdown
Review this code for common issues and suggest improvements.
```

### Simple Command

Just description:

```markdown
---
description: Review code for issues
---

Review this code for common issues and suggest improvements.
```

### Standard Command

Description with model:

```markdown
---
description: Review Git changes
model: anthropic/claude-sonnet-4-5
---

Current changes: !`git diff --name-only`

Review each changed file for:
- Code quality
- Potential bugs
- Best practices
```

### Complex Command

All common fields:

```markdown
---
description: Deploy application to environment
argument-hint: [app-name] [environment] [version]
model: anthropic/claude-sonnet-4-5
agent: deployment-manager
---

Deploy $1 to $2 environment using version $3

Pre-deployment checks:
- Verify $2 configuration
- Check cluster status: !`kubectl cluster-info`
- Validate version $3 exists

Proceed with deployment following deployment runbook.
```

### Subtask Command

Isolated execution:

```markdown
---
description: Generate test coverage report
subtask: true
model: anthropic/claude-haiku-4-5
---

Analyze the current project and generate a comprehensive test coverage report.

Steps:
1. Identify all source files
2. Map existing tests to source files
3. Calculate coverage gaps
4. Output a summary with recommendations
```

### Agent-Specific Command

Using a specialized agent:

```markdown
---
description: Audit code for security vulnerabilities
agent: security-auditor
argument-hint: [file-or-directory]
---

Perform a security audit on $1:

Check for:
- Injection vulnerabilities
- Authentication issues
- Data exposure risks
- Dependency vulnerabilities

Provide a severity-ranked report with remediation steps.
```

## Validation

### Common Errors

**Invalid YAML syntax:**
```yaml
---
description: Missing quote
model: anthropic/claude-sonnet-4-5
---  # ❌ Missing closing quote above
```

**Fix:** Validate YAML syntax

**Invalid model name:**
```yaml
model: sonnet  # ❌ Not a valid model identifier
```

**Fix:** Use full model strings: `anthropic/claude-sonnet-4-5`, `anthropic/claude-opus-4-5`, or `anthropic/claude-haiku-4-5`

### Validation Checklist

Before committing command:
- [ ] YAML syntax valid (no errors)
- [ ] Description under 60 characters
- [ ] model is valid full model string if specified
- [ ] argument-hint matches positional arguments
- [ ] agent references a defined agent if specified
- [ ] subtask used appropriately for isolation needs

## Best Practices Summary

1. **Start minimal:** Add frontmatter only when needed
2. **Document arguments:** Always use argument-hint with arguments
3. **Choose right model:** Use `anthropic/claude-haiku-4-5` for speed, `anthropic/claude-opus-4-5` for complexity
4. **Use agents wisely:** Specify agent only when a specialized agent is needed
5. **Subtask for isolation:** Use subtask when command should run in isolated context
6. **Clear descriptions:** Make commands discoverable in `/help`
7. **Test thoroughly:** Verify frontmatter works as expected
