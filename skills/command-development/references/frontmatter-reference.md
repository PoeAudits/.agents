# Command Frontmatter Reference

YAML frontmatter is optional metadata at the top of a command file.

```markdown
---
name: my-command
description: Short description shown in /help
argument-hint: [arg1] [arg2]
---

[command instructions...]
```

All fields are optional. Use the minimum you need.

## Fields

### name

Optional explicit command name.

```yaml
name: git-status
```

### description

Shown in `/help`.

```yaml
description: Summarize git status
```

### argument-hint

Documents expected arguments.

```yaml
argument-hint: [@file] [options]
```

### model

Pins a model for this command.

**This repo:** only include `model:` when the user explicitly requests a specific model.

```yaml
model: <explicitly-requested-model>
```

### agent

Routes execution to a specific agent.

**This repo:** only include `agent:` when the user explicitly requests it.

```yaml
agent: <explicitly-requested-agent>
```

### subtask

Runs the command in an isolated subtask context.

```yaml
subtask: true
```
