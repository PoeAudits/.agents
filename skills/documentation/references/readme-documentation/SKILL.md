---
name: readme-documentation
description: Guidelines for writing and updating README.md files. Use when creating or modifying README documentation for human readers.
---

# README.md Documentation Guidelines

README.md is the front door of your project. It's written for **humans** - developers who want to use, understand, or contribute to the project.

## Core Principles

1. **Answer "What is this?"** within the first few sentences
2. **Get users running quickly** - prioritize getting started over completeness
3. **Show, don't just tell** - use examples liberally
4. **Be scannable** - use headers, lists, and code blocks
5. **Keep it current** - outdated docs are worse than no docs

---

## Standard Structure

A good README follows this structure (adapt based on project type):

```markdown
# Project Name

One-line description of what this project does.

## Overview

2-3 sentences expanding on what the project does and why it exists.
Include the primary use case.

## Features

- Feature 1 - brief description
- Feature 2 - brief description
- Feature 3 - brief description

## Quick Start

Minimal steps to get running:

\`\`\`bash
npm install project-name
\`\`\`

\`\`\`typescript
import { thing } from 'project-name';
thing.doSomething();
\`\`\`

## Installation

Detailed installation instructions including:
- Prerequisites
- Installation steps
- Verification

## Usage

### Basic Usage

Simple example with explanation.

### Advanced Usage

More complex examples for power users.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| option1 | string | "default" | What it does |

## API Reference

(For libraries - document public API)

## Contributing

How to contribute, run tests, submit PRs.

## License

License type and link.
```

---

## Section Guidelines

### Title and Description

```markdown
# Project Name

A brief, compelling description that answers "what does this do?"
```

**Good**: "A fast, type-safe ORM for TypeScript and Node.js"
**Bad**: "This is a project that does database stuff"

### Overview

- 2-4 sentences maximum
- Answer: What? Why? For whom?
- Include primary use case

```markdown
## Overview

ProjectName simplifies database operations in TypeScript applications. 
It provides a type-safe query builder that catches errors at compile time,
eliminating runtime SQL errors. Built for teams who want the safety of an 
ORM without sacrificing query flexibility.
```

### Features

- Bullet list, not paragraphs
- Lead with the benefit, not the implementation
- Keep descriptions to one line

```markdown
## Features

- **Type-safe queries** - Catch SQL errors at compile time
- **Auto-migrations** - Schema changes generate migrations automatically
- **Connection pooling** - Built-in pool management for production
```

### Quick Start

- Absolute minimum to get something working
- Copy-pasteable commands
- Should take < 2 minutes

```markdown
## Quick Start

\`\`\`bash
npm install myproject
\`\`\`

\`\`\`typescript
import { Client } from 'myproject';

const client = new Client();
const result = await client.query('SELECT * FROM users');
console.log(result);
\`\`\`
```

### Installation

More detailed than Quick Start:
- All prerequisites
- Different installation methods (npm, yarn, pnpm)
- Environment setup
- Verification steps

### Usage / Examples

- Start simple, progress to complex
- Use realistic examples
- Include expected output when helpful
- Group by use case, not by API

```markdown
## Usage

### Creating a Record

\`\`\`typescript
const user = await db.users.create({
  name: 'Alice',
  email: 'alice@example.com'
});
// Returns: { id: 1, name: 'Alice', email: 'alice@example.com' }
\`\`\`

### Querying with Filters

\`\`\`typescript
const activeUsers = await db.users.findMany({
  where: { active: true },
  orderBy: { createdAt: 'desc' }
});
\`\`\`
```

### Configuration

- Use tables for options
- Include types, defaults, and descriptions
- Group related options

```markdown
## Configuration

### Database Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `host` | string | "localhost" | Database host |
| `port` | number | 5432 | Database port |
| `poolSize` | number | 10 | Connection pool size |

### Logging Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `logLevel` | "debug" \| "info" \| "error" | "info" | Minimum log level |
```

### API Reference

For libraries, document public API:
- Function signatures
- Parameter descriptions
- Return types
- Examples for non-obvious usage

```markdown
## API Reference

### `createClient(options)`

Creates a new database client.

**Parameters:**
- `options.host` (string): Database host
- `options.port` (number): Database port

**Returns:** `Client` instance

**Example:**
\`\`\`typescript
const client = createClient({ host: 'localhost', port: 5432 });
\`\`\`
```

---

## Writing Style

### Do

- Use second person ("you") 
- Use active voice
- Use present tense
- Be concise
- Use code examples liberally

### Don't

- Use jargon without explanation
- Write long paragraphs
- Assume knowledge of your specific project
- Leave placeholders like "TODO" or "TBD"
- Include implementation details (save for AGENTS.md)

---

## Updating README After Changes

### When a Feature is Added

1. Add to Features list if user-facing
2. Add usage example if non-obvious
3. Update Configuration if new options
4. Update API Reference if new public API

### When a Breaking Change Occurs

1. Add Migration section or update existing
2. Update affected examples
3. Note the breaking change prominently

### When Dependencies Change

1. Update Installation prerequisites
2. Update version requirements

---

## Checklist Before Committing README Changes

- [ ] Title clearly states what the project does
- [ ] Quick Start actually works (test it!)
- [ ] All code examples are syntactically correct
- [ ] No broken links
- [ ] Configuration table is complete
- [ ] No TODO/TBD placeholders left
- [ ] Consistent formatting throughout
- [ ] Spelling and grammar checked
