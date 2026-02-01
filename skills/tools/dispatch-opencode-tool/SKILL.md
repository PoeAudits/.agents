---
name: dispatch-opencode-tool
description: Use when calling dispatch AI agent orchestration tools from within opencode. Covers dispatch_run, dispatch_parallel, dispatch_workflow, and dispatch_agents tools.
---

# Dispatch OpenCode Tools

OpenCode tool wrappers for the dispatch CLI - enabling AI agent orchestration directly from conversations.

## Available Tools

| Tool | Description |
|------|-------------|
| `dispatch_run` | Dispatch a prompt to a single AI agent |
| `dispatch_parallel` | Execute across multiple agents concurrently |
| `dispatch_workflow` | Run a multi-step YAML workflow |
| `dispatch_agents` | List available agents and groups |

## Permissions

**Default permission: DENY**

These tools are denied by default. Agents must explicitly override permissions to use them.

Example agent permission override:
```json
{
  "tools": {
    "dispatch_run": "allow",
    "dispatch_parallel": "allow",
    "dispatch_workflow": "allow",
    "dispatch_agents": "allow"
  }
}
```

## Tool Reference

### dispatch_run

Dispatch a prompt to a single AI agent.

**Arguments:**
| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `agent` | string | yes | Agent name (e.g., "claude", "gpt") |
| `prompt` | string | yes | The prompt or task to send |
| `sessionId` | string | no | Continue a previous conversation |
| `timeout` | number | no | Timeout in seconds |

**Example calls:**
```typescript
// Simple dispatch
dispatch_run({ agent: "claude", prompt: "Explain quantum computing" })

// With session continuation
dispatch_run({ 
  agent: "claude", 
  prompt: "Continue the explanation", 
  sessionId: "dispatch-1234-abc" 
})

// With timeout
dispatch_run({ 
  agent: "gpt", 
  prompt: "Review this code for security issues", 
  timeout: 120 
})
```

**Output format:**
```
[Agent: claude] (1523ms)

The response text from the agent...
```

On error:
```
[ERROR] AGENT_NOT_FOUND: Agent 'unknown' not found
Suggestion: Available agents: claude, gpt, critic
```

### dispatch_parallel

Execute a prompt across multiple agents concurrently.

**Arguments:**
| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `agents` | string[] | yes | List of agent names (min 2), supports @groups |
| `prompt` | string | yes | The prompt to send to all agents |
| `sessionId` | string | no | Continue a previous conversation |
| `timeout` | number | no | Timeout in seconds |
| `failFast` | boolean | no | Stop on first failure |

**Example calls:**
```typescript
// Basic parallel dispatch
dispatch_parallel({ 
  agents: ["claude", "gpt"], 
  prompt: "Review this code for bugs" 
})

// Using agent groups
dispatch_parallel({ 
  agents: ["@reviewers"], 
  prompt: "Analyze this architecture" 
})

// With fail-fast
dispatch_parallel({ 
  agents: ["claude", "gpt", "critic"], 
  prompt: "Rate this proposal",
  failFast: true
})
```

**Output format:**
```
[Parallel Dispatch] (3421ms)

--- claude (1234ms) ---
Claude's response...

--- gpt (2100ms) ---
GPT's response...
```

### dispatch_workflow

Execute a multi-step YAML workflow.

**Arguments:**
| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `file` | string | yes | Path to YAML workflow file |
| `input` | string | no | Initial input for {{input}} variable |
| `sessionId` | string | no | Continue a previous conversation |
| `timeout` | number | no | Per-step timeout in seconds |
| `dryRun` | boolean | no | Show plan without executing |

**Example calls:**
```typescript
// Execute workflow with input
dispatch_workflow({ 
  file: "review.yaml", 
  input: "Review the authentication module" 
})

// Dry run to preview
dispatch_workflow({ 
  file: "complex-analysis.yaml", 
  input: "Analyze the codebase",
  dryRun: true
})
```

**Output format:**
```
[Workflow: code-review] (12345ms)

✓ Step: analyze (single, 3000ms)
The analysis shows...

✓ Step: review (parallel, 5000ms)
  [critic]: The code has issues with...
  [advocate]: The code demonstrates good...

✓ Step: synthesize (single, 4000ms)
Based on the reviews...

=== Final Output ===
Synthesized conclusion here...
```

### dispatch_agents

List available agents and groups.

**Arguments:**
| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `showGroups` | boolean | no | Include agent groups |

**Example calls:**
```typescript
// List agents only
dispatch_agents({})

// Include groups
dispatch_agents({ showGroups: true })
```

**Output format:**
```
Agents:
  - claude
  - gpt
  - critic
  - advocate

Groups:
  @reviewers: [critic, advocate]
  @all: [claude, gpt, critic, advocate]
```

## Use Cases

### When to use dispatch_run
- Delegate a specific task to a specialized agent
- Continue a multi-turn conversation
- Get a second opinion on a problem
- Offload research or analysis tasks

### When to use dispatch_parallel
- Need multiple perspectives on the same problem
- Want to compare responses from different models
- Running code review with multiple reviewers
- Gathering diverse opinions before deciding

### When to use dispatch_workflow
- Multi-step processes with dependencies
- Complex analysis requiring multiple agents
- Automated pipelines (analyze → critique → synthesize)
- Reproducible multi-agent processes

### When to use dispatch_agents
- Discover available agents before dispatching
- Check group membership
- Verify agent configuration

## Best Practices

1. **Check agents first** - Call `dispatch_agents` to verify available agents before dispatching
2. **Use appropriate timeouts** - Complex tasks need longer timeouts (300-600s)
3. **Prefer workflows for multi-step tasks** - More reliable than chaining individual calls
4. **Use sessions sparingly** - Start fresh sessions for new topics
5. **Parallel for diversity** - Use when you want multiple perspectives, not just speed

## Error Handling

All tools return human-readable error messages:

| Error Code | Meaning | Suggestion |
|------------|---------|------------|
| `AGENT_NOT_FOUND` | Agent not configured | Check `dispatch_agents` output |
| `TIMEOUT` | Agent exceeded time limit | Increase timeout parameter |
| `AGENT_ERROR` | Agent failed to respond | Check agent configuration |
| `CONFIG_ERROR` | Configuration issue | Verify dispatch config.toml |

## Session Management

Sessions allow continuing conversations:

```typescript
// First call - get sessionId from output metadata
const result1 = dispatch_run({ agent: "claude", prompt: "Start analysis" })
// Result includes sessionId: "dispatch-1234-abc"

// Continue with same session
const result2 = dispatch_run({ 
  agent: "claude", 
  prompt: "Continue with more detail",
  sessionId: "dispatch-1234-abc"
})
```

Sessions are stored in `~/.config/dispatch/sessions/` and can be listed with `dispatch sessions` CLI command.

## Configuration

Tools use dispatch configuration from `~/.config/dispatch/config.toml`.

See the **dispatch** skill for full configuration reference.
