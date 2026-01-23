---
name: dispatch
description: Use when orchestrating AI agents via CLI, executing single/parallel agent dispatch, running YAML workflows, configuring agents in TOML, or piping outputs between agents.
---

# Dispatch CLI

Multi-agent orchestration CLI for dispatching prompts to AI agents.

## Commands

### Single Agent
```bash
dispatch agent <agent> [prompt]
dispatch <agent> [prompt]           # shorthand

# With stdin
echo "prompt" | dispatch agent <agent>
```

### Parallel Agents
```bash
dispatch parallel <agent1> <agent2> [prompt]
dispatch parallel @group [prompt]   # expand group

# Inline per-agent prompts (different prompt per agent)
dispatch parallel claude::"Security review of code" gpt::"Performance review"
```

### Workflows
```bash
dispatch workflow <file.yaml> [prompt]
dispatch workflow <file.yaml> --validate        # validate only
dispatch workflow <file.yaml> --dry-run "x"     # show execution plan
dispatch workflow <file.yaml> --describe        # show step dependency graph
dispatch workflow <file.yaml> --extract-step design "x"  # extract single step output
```

### Session Management
```bash
dispatch continue <session-id>      # continue with stdin
dispatch sessions                   # list sessions
dispatch sessions --cleanup 7       # delete >7 days old
dispatch agents                     # list agents
dispatch agents --groups            # show groups
```

## Common Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--config <path>` | `-c` | Config file path |
| `--timeout <sec>` | `-t` | Timeout in seconds |
| `--output <fmt>` | `-o` | Output format: json, text, jsonl |
| `--cwd <dir>` | | Working directory (supports ~) |
| `--raw` | | Raw output (no JSON wrapper) |
| `--write-to <file>` | | Write text output to file |
| `--debug` | `-d` | Debug logging to stderr |
| `--verbose` | `-v` | Info-level logs |
| `--session <id>` | `-s` | Continue existing session |
| `--fail-fast` | | Stop on first failure (parallel) |
| `--prompts <file>` | `-p` | YAML file with agent-specific prompts |

### Workflow-Specific Flags

| Flag | Description |
|------|-------------|
| `--validate` | Validate workflow without executing |
| `--dry-run` | Show execution plan without running |
| `--describe` | Show step dependency graph |
| `--extract-step <name>` | Extract and output only the specified step |

### Working Directory (--cwd)

The `--cwd` flag sets the working directory for agent execution:
```bash
dispatch agent claude --cwd ~/project "Review the code"
```
- Agents run with this directory as their working directory
- Agents can reference local paths in prompts (e.g., "Review src/main.py")
- File operations by the agent happen relative to this directory
- Supports tilde expansion (`~`)

## Input Priority

When both positional prompt and stdin are available:
1. **Positional prompt** takes precedence (stdin is ignored)
2. **Stdin** is used only when no positional prompt provided

To combine piped output with new instructions:
```bash
# Wrong - stdin ignored when positional provided
cat prev.json | dispatch agent claude "Review this"

# Correct - embed previous output in prompt
dispatch agent claude "Review this: $(cat prev.json | jq -r '.text')"

# Or use stdin only (no positional)
cat prev.json | dispatch agent claude
```

## Agent Configuration (TOML)

Default path: `~/.config/dispatch/config.toml` or set `DISPATCH_CONFIG`.

```toml
[agents.claude]
start = "claude -p --output-format json"
continue = "claude -p --output-format json --continue"
format = "jsonl"    # jsonl | json | text
flags = ""          # optional extra flags

[agents.gpt]
start = "opencode run -m openai/gpt-4o --format json"
continue = "opencode run -m openai/gpt-4o --format json -c"
format = "jsonl"

[groups]
reviewers = ["critic", "advocate"]
all = ["claude", "gpt", "critic", "advocate"]

[settings]
timeout = 600
sessionDir = "~/.config/dispatch/sessions"
defaultAgents = ["claude"]
```

## Workflow YAML Format

```yaml
name: workflow-name
description: Optional description

steps:
  # Single agent step
  - name: step1
    agent: claude
    prompt: |
      Process this: {{input}}

  # Parallel step
  - name: step2
    parallel: [critic, advocate]
    prompts:
      critic: "Critique: {{step1}}"
      advocate: "Support: {{step1}}"
    # Or use shared prompt:
    # prompt: "Review: {{step1}}"

  # Reference previous parallel results
  - name: step3
    agent: claude
    prompt: |
      Critic said: {{step2.critic}}
      Advocate said: {{step2.advocate}}
```

### Template Variables
- `{{input}}` - Original workflow input
- `{{stepName}}` - Single agent step output
- `{{stepName.agent}}` - Specific agent from parallel step

### YAML Prompt Tips
- Use `|` for multi-line prompts (preserves newlines)
- Use `>` for folded text (joins lines with spaces)
- Escape literal `{{` by doubling: `{{{{` renders as `{{`
- Quotes in prompts work normally within YAML block scalars
```yaml
prompt: |
  Analyze this code:
  {{input}}
  
  Note: Use {{{{curly braces}}}} for template syntax in output.
```

## Output Structure

### Single Agent (JSON)
```json
{
  "success": true,
  "agent": "claude",
  "text": "response...",
  "sessionId": "abc123",
  "agentSessionId": "xyz789",
  "durationMs": 1500
}
```

### Parallel (JSON)
```json
{
  "success": true,
  "pattern": "parallel",
  "sessionId": "abc123",
  "results": {
    "critic": { "success": true, "text": "..." },
    "advocate": { "success": true, "text": "..." }
  },
  "errors": {}
}
```

### Workflow (JSON)
```json
{
  "success": true,
  "workflow": "workflow-name",
  "sessionId": "dispatch-123-abc",
  "steps": {
    "step1": { "success": true, "pattern": "single", "text": "...", "durationMs": 1234 },
    "step2": { "success": true, "pattern": "parallel", "results": {...}, "durationMs": 5678 }
  },
  "durationMs": 12345,
  "timestamp": "2025-01-19T..."
}
```

Note: Steps are keyed by name (object), not an array. Access via `jq '.steps.stepName.text'`.

### Error (JSON)
```json
{
  "success": false,
  "error": {
    "code": "AGENT_ERROR",
    "message": "...",
    "retriable": true
  }
}
```

## Writing Output to Files

Use `--write-to` to write text output directly to a file:

```bash
# Single agent - writes .text to file
dispatch agent claude "Explain this code" --write-to explanation.md

# Parallel - writes combined agent outputs to file
dispatch parallel critic advocate "Review this" --write-to reviews.md

# Workflow - writes full result or extracted step
dispatch workflow review.yaml "code" --write-to result.json
dispatch workflow review.yaml "code" --extract-step design --write-to design.md
```

This eliminates the need for `jq` extraction and shell redirection:
```bash
# Before (2 steps)
dispatch agent claude "prompt" -o json > tmp.json && jq -r '.text' tmp.json > output.md

# After (1 step)
dispatch agent claude "prompt" --write-to output.md
```

## Chaining Outputs

### Simple Piping (No New Prompt)
When piping without a positional prompt, the full JSON output is passed:
```bash
dispatch agent analyst "data" | dispatch agent critic
dispatch agent analyst "data" | dispatch parallel reviewer synthesizer
```

The receiving agent gets the complete JSON object from the previous dispatch.

### Chaining with New Instructions
To add new instructions while using previous output, extract the text field:
```bash
# Extract text and embed in new prompt
dispatch agent claude "Summarize: $(dispatch agent analyst 'data' | jq -r '.text')"

# Or save intermediate results to files
dispatch agent analyst "data" -o json > analysis.json
dispatch agent claude "Review this analysis: $(jq -r '.text' analysis.json)"
```

### Robust File-Based Chaining
For complex pipelines or long outputs, use files to avoid shell escaping issues:
```bash
# Step 1: Generate analysis
dispatch agent analyst "$(cat code.py)" -o json > step1.json

# Step 2: Review with context
dispatch agent reviewer "Review this code analysis:

$(jq -r '.text' step1.json)

Focus on security issues." -o json > step2.json

# Step 3: Final synthesis
dispatch agent claude --raw "Create a summary from:
Analysis: $(jq -r '.text' step1.json)
Review: $(jq -r '.text' step2.json)" > final.txt
```

### Why Positional + Stdin Doesn't Work
Dispatch prioritizes positional prompts over stdin. This fails:
```bash
# WRONG: stdin is ignored when positional prompt provided
cat prev.json | dispatch agent claude "Review this"
```

Use extraction patterns shown above instead.

## Output Cleanup Patterns

When agents include unwanted content (preambles, markdown code blocks), use these patterns:

```bash
# Extract just .text from JSON output
dispatch agent claude "prompt" | jq -r '.text'

# Or use -o text for direct text extraction
dispatch agent claude "prompt" -o text

# Strip markdown code blocks from text output
dispatch agent claude "prompt" -o text | sed '/^```/d'

# Remove preamble (first line if not code)
dispatch agent claude "prompt" -o text | tail -n +2

# Extract code from markdown code block
dispatch agent claude "prompt" -o text | sed -n '/^```python/,/^```/p' | sed '1d;$d'
```

For cleaner code output, be explicit in prompts:
- "Output ONLY the Python code, no explanations or markdown"
- "Do not include code fences or language markers"
- "Start your response with the code itself"

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Agent error |
| 2 | Timeout |
| 3 | Config error |
| 4 | Validation error |
| 6 | Agent not found |
| 9 | All parallel agents failed |

## Groups

Reference groups with `@` prefix:
```bash
dispatch parallel @reviewers "review this"  # expands to agents in group
```

Groups are defined in config TOML under `[groups]`.

## Per-Agent Prompts File

Use `-p` / `--prompts` with a YAML file for different prompts per agent:

```yaml
# prompts.yaml
claude: |
  Focus on code quality and best practices.
  Input: {{input}}

gpt: |
  Focus on security vulnerabilities.
  Input: {{input}}

default: |
  Review this: {{input}}
```

```bash
dispatch parallel claude gpt -p prompts.yaml "$(cat code.py)"
```

### Template Variables in Prompts
- `{{input}}` - The positional prompt or stdin content
- `{{agent}}` - The agent name
- `{{previous}}` - Previous dispatch output (when piping)

### Inline Prompts for Parallel

For quick one-off different prompts without a file:
```bash
dispatch parallel \
  claude::"Security review of: $(cat code.py)" \
  gpt::"Performance review of: $(cat code.py)"
```

Note: Inline prompts use `::` separator with optional quotes around the prompt.

## Agent Requirements

For an agent to work with dispatch:
1. **Must output to stdout** - Response text must go to stdout, not files
2. **Must accept prompt** - As final argument or via stdin
3. **Format compliance** - For JSON format, must output valid JSON
4. **Session support** - Continue command must accept session ID

## Troubleshooting

### Piping Not Working
If piped input seems ignored, check if you provided a positional prompt.
Positional arguments take priority over stdin.

### Timeout Errors
The default timeout is 600 seconds. Adjust for task complexity:

| Task Type | Timeout | Flag |
|-----------|---------|------|
| Simple Q&A | 60-120s | `-t 120` |
| Code review | 120-300s | `-t 300` |
| Code generation | 300-600s | (default) |
| Complex analysis | 600-900s | `-t 900` |
| Documentation | 600-1200s | `-t 1200` |
| Large refactoring | 1200-1800s | `-t 1800` |

**Workflow Timeouts**:
- Total timeout applies to entire workflow execution
- Rule of thumb: steps × average_step_time × 1.5
- 3-step simple workflow: `-t 1200` (3 × 300s + buffer)
- 4-step complex workflow: `-t 2400` (4 × 500s + buffer)
- Parallel steps run concurrently, count as one step for timeout calculation

### Agent Not Found (Exit Code 6)
Verify agent is defined in config.toml:
```bash
dispatch agents  # List available agents
```

### Agent Writes Files Instead of Stdout
Some agents (like Claude Code) write files by default. Prompt explicitly:
"Output your response to stdout, do not write any files."

### Workflow Execution Issues
If workflows hang or crash:
1. Test each step individually with `dispatch agent`
2. Use `--dry-run` to verify prompts resolve correctly
3. Increase timeout: `dispatch workflow -t 600 file.yaml`

## Autonomous Loops

For autonomous iterative execution of implementation plans, see:

- **execution-loop** skill - Run agent in loop with fresh context per iteration
- **loop-format** skill - Format plans for optimal loop execution

```bash
# Format plan then run loop
dispatch loop-format PLAN.md --backup
dispatch loop claude --prompt PROMPT.md --plan PLAN.md --max-iterations 50
```

