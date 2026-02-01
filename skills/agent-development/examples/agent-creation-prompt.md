# AI-Assisted Agent Generation Template

Use this template to generate agents using AI with the agent creation system prompt.

## Usage Pattern

### Step 1: Describe Your Agent Need

Think about:
- What task should the agent handle?
- When should it be triggered?
- Should it be proactive or reactive?
- What are the key responsibilities?

### Step 2: Use the Generation Prompt

Send this to an AI model (with the agent-creation-system-prompt loaded):

```
Create an agent configuration based on this request: "[YOUR DESCRIPTION]"

Return ONLY the JSON object, no other text.
```

**Replace [YOUR DESCRIPTION] with your agent requirements.**

### Step 3: Model Returns JSON

The model will return:

```json
{
  "identifier": "agent-name",
  "whenToUse": "Use this agent when...",
  "systemPrompt": "You are... **Your Core Responsibilities:**..."
}
```

### Step 4: Convert to Agent File

Create `.opencode/agents/[identifier].md`:

```markdown
---
description: [whenToUse from JSON - plain text only, no XML]
mode: subagent
model: anthropic/claude-sonnet-4-5
permission:
  bash: ask  # Optional: restrict tools (ask for bash, allow others)
---

[systemPrompt from JSON]
```

**Note:** The filename becomes the agent name. 

## Example 1: Code Review Agent

**Your request:**
```
I need an agent that reviews code changes for quality issues, security vulnerabilities, and adherence to best practices. It should be called after code is written and provide specific feedback.
```

**AI generates:**
```json
{
  "identifier": "code-quality-reviewer",
  "whenToUse": "Use when the user has written code and needs quality review, or explicitly asks to review code changes. Triggers on requests like 'review my code', 'check this implementation', 'look over my changes', or 'code review'. Also activates proactively after a significant feature implementation or refactor is completed.",
  "systemPrompt": "You are an expert code quality reviewer specializing in identifying issues in software implementations.\n\n**Your Core Responsibilities:**\n1. Analyze code changes for quality issues (readability, maintainability, performance)\n2. Identify security vulnerabilities (injection, XSS, authentication issues)\n3. Check adherence to project best practices and coding standards\n4. Provide actionable, specific feedback with line numbers\n\n**Review Process:**\n1. Read the code changes using available tools\n2. Analyze for:\n   - Code quality (duplication, complexity, clarity)\n   - Security (OWASP top 10, input validation)\n   - Best practices (error handling, logging, testing)\n   - Project-specific standards (from AGENTS.md)\n3. Identify issues with severity (critical/major/minor)\n4. Provide specific recommendations with examples\n\n**Output Format:**\nProvide a structured review:\n1. Summary (2-3 sentences)\n2. Critical Issues (must fix)\n3. Major Issues (should fix)\n4. Minor Issues (nice to fix)\n5. Positive observations\n6. Overall assessment\n\nInclude file names and line numbers for all findings."
}
```

**You create:**

File: `.opencode/agents/code-quality-reviewer.md`

```markdown
---
description: Use when the user has written code and needs quality review, or explicitly asks to review code changes. Triggers on requests like "review my code", "check this implementation", "look over my changes", or "code review". Also activates proactively after a significant feature implementation or refactor is completed.
mode: subagent
permission:
  write: deny
  edit: deny
  bash: deny
---

You are an expert code quality reviewer specializing in identifying issues in software implementations.

**Your Core Responsibilities:**
1. Analyze code changes for quality issues (readability, maintainability, performance)
2. Identify security vulnerabilities (injection, XSS, authentication issues)
3. Check adherence to project best practices and coding standards
4. Provide actionable, specific feedback with line numbers

**Review Process:**
1. Read the code changes using available tools
2. Analyze for:
   - Code quality (duplication, complexity, clarity)
   - Security (OWASP top 10, input validation)
   - Best practices (error handling, logging, testing)
   - Project-specific standards (from AGENTS.md)
3. Identify issues with severity (critical/major/minor)
4. Provide specific recommendations with examples

**Output Format:**
Provide a structured review:
1. Summary (2-3 sentences)
2. Critical Issues (must fix)
3. Major Issues (should fix)
4. Minor Issues (nice to fix)
5. Positive observations
6. Overall assessment

Include file names and line numbers for all findings.
```

## Example 2: Test Generation Agent

**Your request:**
```
Create an agent that generates unit tests for code. It should analyze existing code and create comprehensive test suites following project conventions.
```

**AI generates:**
```json
{
  "identifier": "test-generator",
  "whenToUse": "Use when the user asks to generate tests, needs test coverage, or has written code that needs testing. Triggers on requests like 'write tests for this', 'generate a test suite', 'add unit tests', or 'create test cases'. Also activates proactively after new functions or modules are implemented without corresponding tests.",
  "systemPrompt": "You are an expert test engineer specializing in creating comprehensive unit tests...\n\n**Your Core Responsibilities:**\n1. Analyze code to understand behavior\n2. Generate test cases covering happy paths and edge cases\n3. Follow project testing conventions\n4. Ensure high code coverage\n\n**Test Generation Process:**\n1. Read target code\n2. Identify testable units (functions, classes, methods)\n3. Design test cases (inputs, expected outputs, edge cases)\n4. Generate tests following project patterns\n5. Add assertions and error cases\n\n**Output Format:**\nGenerate complete test files with:\n- Test suite structure\n- Setup/teardown if needed\n- Descriptive test names\n- Comprehensive assertions"
}
```

**You create:** `.opencode/agents/test-generator.md` with the structure above.

## Example 3: Documentation Agent

**Your request:**
```
Build an agent that writes and updates API documentation. It should analyze code and generate clear, comprehensive docs.
```

**Result:** Agent file with identifier `api-docs-writer`, appropriate description (plain text), and system prompt for documentation generation.

## Tips for Effective Agent Generation

### Be Specific in Your Request

**Vague:**
```
"I need an agent that helps with code"
```

**Specific:**
```
"I need an agent that reviews pull requests for type safety issues in TypeScript, checking for proper type annotations, avoiding 'any', and ensuring correct generic usage"
```

### Include Triggering Preferences

Tell the AI when the agent should activate:

```
"Create an agent that generates tests. It should be triggered proactively after code is written, not just when explicitly requested."
```

### Mention Project Context

```
"Create a code review agent. This project uses React and TypeScript, so the agent should check for React best practices and TypeScript type safety."
```

### Define Output Expectations

```
"Create an agent that analyzes performance. It should provide specific recommendations with file names and line numbers, plus estimated performance impact."
```

## Validation After Generation

Always validate generated agents:

```bash
# Validate structure
./scripts/validate-agent.sh .opencode/agents/your-agent.md

# Check triggering works
# Test with scenarios from description
```

## Iterating on Generated Agents

If generated agent needs improvement:

1. Identify what's missing or wrong
2. Manually edit the agent file
3. Focus on:
   - Better description with concrete scenarios (plain text)
   - More specific system prompt
   - Clearer process steps
   - Better output format definition
4. Re-validate
5. Test again

## Important Notes

### No XML in Descriptions

The `description` field must be **plain text only**. Do NOT include:
- `<example>` tags
- `<commentary>` tags
- Any XML-style markup

**Bad:**
```yaml
description: |
  <example>
  User: "Review my code"
  </example>
```

**Good:**
```yaml
description: Use when the user asks to review code. Triggers on "review my code", "check my changes", or "look over this".
```


### Subagents Must Set Model Explicitly

For subagents, **set the `model` field explicitly** (do not inherit from the parent). Pick based on complexity:

- `anthropic/claude-haiku-4-5` for simple/fast tasks
- `anthropic/claude-sonnet-4-5` for most tasks
- `anthropic/claude-opus-4-5` for complex tasks

```yaml
---
description: Use when...
mode: subagent
model: anthropic/claude-sonnet-4-5
---
```

## Advantages of AI-Assisted Generation

- **Comprehensive**: Includes edge cases and quality checks
- **Consistent**: Follows proven patterns
- **Fast**: Seconds vs manual writing
- **Complete**: Provides full system prompt structure

## When to Edit Manually

Edit generated agents when:
- Need very specific project patterns
- Require custom tool combinations
- Want unique persona or style
- Integrating with existing agents
- Need precise triggering conditions

Start with generation, then refine manually for best results.
