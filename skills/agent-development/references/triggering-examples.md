# Agent Description Best Practices: Writing Effective Triggering Descriptions

Complete guide to writing effective agent `description` fields that enable reliable triggering in Opencode.

## How Agent Descriptions Work

In Opencode, the `description` field in agent frontmatter is a **plain-text string** that tells the system when to use the agent. **There are no XML blocks or special markup** — just clear, specific prose that describes triggering conditions.

```yaml
---
description: Use when the user asks to review code, check implementation quality, or analyze recent changes. Triggers on requests like "review my code", "check this implementation", or "look over my changes". Also activates proactively after a significant chunk of code has been written.
# model: (omit for primary; required for subagent)
permission:
  write: deny
---
```

**Important:** Do NOT use XML tags like `<example>`, `<commentary>`, or similar. Use plain text only.

## Anatomy of a Good Description

### Structure

A well-written description has three parts:

1. **Primary trigger** — The main use case, starting with "Use when..."
2. **Keyword examples** — Specific phrases or requests that should trigger the agent
3. **Proactive conditions** (optional) — When the agent should activate without being asked

### Example Breakdown

```
Use when the user asks to review code, check implementation quality,
or analyze recent changes. Triggers on requests like "review my code",
"check this implementation", or "look over my changes". Also activates
proactively after a significant chunk of code has been written.
```

| Part | Text |
|------|------|
| Primary trigger | "Use when the user asks to review code, check implementation quality, or analyze recent changes." |
| Keyword examples | `"review my code"`, `"check this implementation"`, `"look over my changes"` |
| Proactive condition | "Also activates proactively after a significant chunk of code has been written." |

## Writing Effective Descriptions

### Start with "Use when..."

Always begin with a clear statement of when the agent should be used:

**Good:**
```
Use when the user asks for security analysis of code, requests vulnerability scanning, or mentions concerns about code security.
```

**Bad:**
```
This agent reviews code for security issues.
```

The first version tells the system *when* to trigger. The second just describes *what* the agent does — it doesn't help with triggering decisions.

### Include Specific Keywords and Phrases

List the actual words and phrases users are likely to say:

**Good:**
```
Use when the user asks to "generate tests", "write tests", "add test coverage", or "create a test suite". Also triggers on requests mentioning specific test frameworks like Jest, Vitest, or pytest.
```

**Bad:**
```
Use when the user wants tests.
```

### Describe Proactive Conditions Clearly

If the agent should trigger without being asked, spell out exactly when:

**Good:**
```
Also activates proactively after new API endpoints are implemented, database queries are written, or authentication logic is added — any code that handles user input or sensitive data.
```

**Bad:**
```
Also use proactively when appropriate.
```

### Distinguish from Similar Agents

If your agent could overlap with others, clarify the boundaries:

**Good:**
```
Use when the user needs deep security analysis. For general code quality reviews (style, patterns, readability), use the code-reviewer agent instead. This agent focuses specifically on vulnerabilities, injection attacks, auth issues, and data exposure.
```

## Description Patterns by Agent Type

### Analysis Agent

```
Use when the user asks to analyze code for [specific issues], review [specific aspect] of implementation, or check for [specific problems]. Triggers on requests like "[phrase 1]", "[phrase 2]", or "[phrase 3]". Focuses on [scope] — for [different scope], use [other-agent] instead.
```

**Example:**
```
Use when the user asks to analyze TypeScript code for type safety issues, review type annotations, or check for unsafe 'any' usage. Triggers on requests like "check my types", "review type safety", or "find type issues". Focuses on TypeScript-specific concerns — for general code quality, use the code-reviewer agent instead.
```

### Generation Agent

```
Use when the user asks to create [what], generate [what], or write [what] for [context]. Triggers on requests like "[phrase 1]", "[phrase 2]", or "[phrase 3]". Also activates proactively after [condition] when [what] is missing.
```

**Example:**
```
Use when the user asks to create tests, generate a test suite, or write unit tests for existing code. Triggers on requests like "add tests", "generate tests for this", or "write a test suite". Also activates proactively after new functions are implemented without corresponding tests.
```

### Validation Agent

```
Use when the user asks to validate [what], verify [what], or check [what] against [criteria]. Triggers on requests like "[phrase 1]", "[phrase 2]", or "[phrase 3]". Also activates proactively before [action] to catch issues early.
```

**Example:**
```
Use when the user asks to validate API contracts, verify schema compliance, or check request/response formats. Triggers on requests like "validate my API", "check the schema", or "verify the contract". Also activates proactively before committing API changes to catch breaking changes early.
```

### Orchestration Agent

```
Use when the user needs to coordinate [complex workflow], run [multi-step process], or manage [what]. Triggers on requests like "[phrase 1]", "[phrase 2]", or "[phrase 3]".
```

**Example:**
```
Use when the user needs to coordinate a full release process, run deployment checks, or manage the build-test-deploy pipeline. Triggers on requests like "prepare a release", "run the deployment", or "ship this version".
```

## Common Mistakes

### Too Vague

```
Use when the user needs help with code.
```

**Why bad:** Almost everything involves code. This will trigger constantly or not at all because it doesn't differentiate from other agents.

**Fix:**
```
Use when the user asks to refactor code for better readability, simplify complex functions, or reduce code duplication. Triggers on "simplify this", "refactor for clarity", or "this code is too complex".
```

### Too Narrow

```
Use when the user says "review PR #123".
```

**Why bad:** Only matches one exact phrase. Users say things many different ways.

**Fix:**
```
Use when the user asks to review a pull request, check PR changes, or analyze a PR diff. Triggers on mentions of "PR", "pull request", "review changes", or "check my PR".
```

### Describes Output Instead of Trigger

```
This agent produces a detailed security report with vulnerability classifications and remediation steps.
```

**Why bad:** Describes what the agent *outputs*, not when to *use* it.

**Fix:**
```
Use when the user asks for security analysis, vulnerability scanning, or penetration testing of code. Triggers on "check for vulnerabilities", "security review", or "is this code secure". Produces a detailed security report with vulnerability classifications and remediation steps.
```

### Missing Proactive Conditions

```
Use when the user asks to review code quality.
```

**Why bad:** Only covers explicit requests. If the agent should also trigger proactively, that needs to be stated.

**Fix:**
```
Use when the user asks to review code quality. Also activates proactively after a logical chunk of code is written — such as completing a feature, adding a new module, or finishing a refactor.
```

### Using XML Blocks

```yaml
---
description: |
  <example>
  User: "Review my code"
  </example>
---
```

**Why bad:** Opencode expects plain text descriptions, not XML markup.

**Fix:**
```yaml
---
description: Use when the user asks to review code. Triggers on requests like "review my code", "check my changes", or "look over this".
---
```

## How Many Trigger Phrases?

### Minimum: 3 phrases
Cover at least the most common ways users express the need.

### Recommended: 5-8 phrases
Cover explicit requests, variations, and implicit signals.

### Maximum: ~12 phrases
Beyond this, the description becomes unwieldy. Focus on the most distinctive triggers.

## Template

Use this template as a starting point:

```
Use when [primary trigger condition]. Triggers on requests like
"[phrase 1]", "[phrase 2]", "[phrase 3]", or "[phrase 4]".
[Optional: Also triggers when [implicit signal] or [contextual condition].]
[Optional: Also activates proactively after/when [proactive condition].]
[Optional: For [related but different need], use [other-agent] instead.]
```

## Real-World Examples

### Code Review Agent

```
Use when the user asks to review code, check implementation quality, or analyze recent changes. Triggers on requests like "review my code", "check this implementation", "look over my changes", or "code review". Also activates proactively after a significant feature implementation or refactor is completed.
```

### Test Generation Agent

```
Use when the user asks to generate tests, write test cases, or add test coverage. Triggers on requests like "write tests for this", "generate a test suite", "add unit tests", or "create test cases". Also activates proactively after new functions or modules are implemented without corresponding tests.
```

### Documentation Agent

```
Use when the user asks to write documentation, generate API docs, or document code. Triggers on requests like "document this API", "write docs", "add documentation", or "generate README". Also activates proactively after new API endpoints are implemented or public interfaces are added.
```

### Security Analysis Agent

```
Use when the user asks for security review, vulnerability analysis, or safety checks on code. Triggers on requests like "check for vulnerabilities", "security audit", "is this secure", or "review for injection attacks". Also activates proactively after code handling user input, authentication, or database queries is written.
```

### Validation Agent

```
Use when the user asks to validate code, check compliance, or verify implementation against standards. Triggers on requests like "validate this", "check compliance", "verify against standards", or "does this meet requirements". Also activates proactively before commits to catch issues early.
```

## Debugging Triggering Issues

### Agent Not Triggering

**Check:**
1. Description includes keywords that match how users actually phrase requests
2. Primary trigger condition is broad enough to catch variations
3. Specific trigger phrases cover common phrasings

**Fix:** Add more trigger phrases covering different ways users express the same need.

### Agent Triggers Too Often

**Check:**
1. Description is too broad or generic
2. Trigger phrases overlap with other agents
3. No boundary conditions distinguishing from similar agents

**Fix:** Make the description more specific. Add "For [X], use [other-agent] instead" boundaries.

### Agent Triggers in Wrong Scenarios

**Check:**
1. Trigger phrases are ambiguous (could mean different things)
2. Description doesn't distinguish the agent's specific focus

**Fix:** Clarify the specific domain and add distinguishing context.

## Best Practices Summary

**DO:**
- Start with "Use when..." to clearly define triggering conditions
- Include 5-8 specific trigger phrases users are likely to say
- Describe proactive conditions if the agent should auto-trigger
- Distinguish from similar agents with clear boundaries
- Use plain, specific language (no XML tags)

**DON'T:**
- Write vague descriptions that could apply to any agent
- Only describe what the agent does (describe *when* to use it)
- Use only one trigger phrase (users say things many ways)
- Forget proactive conditions if the agent should auto-trigger
- Make descriptions excessively long (aim for 2-4 sentences)
- Use XML blocks like `<example>` or `<commentary>`

## Conclusion

Well-written descriptions are crucial for reliable agent triggering. Focus on clearly stating *when* the agent should be used, include specific phrases users are likely to say, and describe any proactive triggering conditions. Keep it **plain text** (no XML), specific, and concise.
