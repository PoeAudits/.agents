---
name: agents-documentation
description: Guidelines for writing and updating AGENTS.md files. Use when creating or modifying AGENTS.md documentation for AI coding assistants.
---

# AGENTS.md Documentation Guidelines

AGENTS.md is written for **AI coding assistants** - Claude, Cursor, GitHub Copilot, and similar tools. Its purpose is to help AI understand your codebase structure, patterns, and conventions so it can generate better code.

## Core Principles

1. **Optimize for AI comprehension** - Structure information for quick pattern matching
2. **Focus on architecture** - How things connect, not how to use them
3. **Document patterns, not files** - AI can read individual files; document conventions and non-obvious relationships
4. **Be explicit about non-obvious things** - AI can read code; tell it what code doesn't show
5. **Keep it current** - Stale AGENTS.md leads to wrong suggestions
6. **Keep it minimal** - Every line should earn its place; remove outdated content when updating

---

## What AGENTS.md Is NOT

| AGENTS.md is NOT | That belongs in |
|------------------|-----------------|
| User documentation | README.md |
| API reference | README.md or docs/ |
| Getting started guide | README.md |
| Installation instructions | README.md |
| Changelog | CHANGELOG.md |

---

## Size Guidelines

AGENTS.md should stay lean. AI agents can read source code directly — documentation should only capture what code alone doesn't convey.

| Document | Target Size | Notes |
|----------|-------------|-------|
| Root AGENTS.md | Under 500 lines | Architecture, patterns, conventions. Push directory-specific detail to subdirectory files |
| Subdirectory AGENTS.md | Under 150 lines | Document the pattern for that directory, not every individual file |

**When a file is getting too long:**
- Remove per-file documentation (AI can read the files themselves)
- Consolidate similar patterns into one section
- Move directory-specific details to subdirectory AGENTS.md files
- Cut anything that restates what the code already shows

---

## Standard Structure

```markdown
# Project Name

Brief description focused on what AI needs to know.

## Architecture Overview

High-level description of how the system is organized.
Include a simple diagram if helpful.

## Directory Structure

\`\`\`
src/
├── components/     # React components
├── services/       # Business logic
├── repositories/   # Data access
├── types/          # Type definitions
└── utils/          # Shared utilities
\`\`\`

## Key Patterns

### [Pattern Name]
- Where it's used
- How it works
- Example location

## Coding Conventions

### Naming
- Files: kebab-case
- Components: PascalCase
- Functions: camelCase

### File Organization
- One component per file
- Co-locate tests with source
- Types in separate files

## Key Abstractions

### [Abstraction Name]
- Purpose
- Location
- How to use/extend

## Dependencies & Integrations

### Internal Dependencies
- [Module A] depends on [Module B]

### External Services
- [Service]: What it's used for

## Common Tasks

### Adding a new [thing]
1. Step 1
2. Step 2
3. Step 3

## Do NOT

- Things to avoid
- Anti-patterns
- Deprecated approaches
```

---

## Section Guidelines

### Architecture Overview

Help AI understand the big picture:

```markdown
## Architecture Overview

This is a layered backend service:

\`\`\`
┌─────────────────────────────────────┐
│           API Routes                │  ← HTTP handlers
├─────────────────────────────────────┤
│           Services                  │  ← Business logic
├─────────────────────────────────────┤
│         Repositories                │  ← Data access
├─────────────────────────────────────┤
│           Database                  │  ← PostgreSQL
└─────────────────────────────────────┘
```

Data flows top-down. Services never access the database directly;
they always go through repositories.
```

### Directory Structure

Annotate what each directory contains:

```markdown
## Directory Structure

\`\`\`
src/
├── api/
│   ├── routes/          # Express route handlers
│   ├── middleware/      # Request middleware
│   └── validators/      # Request validation schemas
├── services/            # Business logic (one service per domain)
├── repositories/        # Data access layer
├── models/              # Database models/entities
├── types/               # Shared TypeScript types
├── utils/               # Pure utility functions
└── config/              # Configuration loading
\`\`\`

### Key Conventions
- Route handlers are thin - delegate to services
- Services contain business logic
- Repositories handle all database queries
- Types are shared; don't duplicate
```

### Key Patterns

Document patterns AI should recognize and follow:

```markdown
## Key Patterns

### Service Pattern

All business logic lives in service classes.

**Structure:**
\`\`\`typescript
// src/services/[domain].service.ts
export class DomainService {
  constructor(private repo: DomainRepository) {}
  
  async findById(id: string): Promise<Domain> { ... }
  async create(data: CreateDomainDto): Promise<Domain> { ... }
}
\`\`\`

**Example:** `src/services/user.service.ts`

**Rules:**
- One service per domain
- Inject repositories via constructor
- Throw domain-specific errors, not generic ones

### Repository Pattern

Data access is abstracted behind repository classes.

**Structure:**
\`\`\`typescript
// src/repositories/[domain].repository.ts
export class DomainRepository {
  constructor(private db: Database) {}
  
  async findById(id: string): Promise<Domain | null> { ... }
}
\`\`\`

**Example:** `src/repositories/user.repository.ts`

**Rules:**
- Return null for not found, don't throw
- Use parameterized queries, never string concatenation
- Keep queries simple; complex logic belongs in services
```

### Coding Conventions

Be specific about naming and organization:

```markdown
## Coding Conventions

### Naming Conventions

| Thing | Convention | Example |
|-------|------------|---------|
| Files | kebab-case | `user-service.ts` |
| Classes | PascalCase | `UserService` |
| Functions | camelCase | `getUserById` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Types/Interfaces | PascalCase | `UserResponse` |
| Type files | `.types.ts` suffix | `user.types.ts` |

### Import Order

1. Node built-ins
2. External packages
3. Internal absolute imports
4. Relative imports

### File Organization

- One class/component per file
- Co-locate tests: `foo.ts` → `foo.test.ts`
- Co-locate types when specific to one file
- Shared types go in `types/`

### Error Handling

- Services throw typed errors: `throw new UserNotFoundError(id)`
- Controllers catch and map to HTTP responses
- Never swallow errors silently
```

### Key Abstractions

Document the core concepts AI needs to understand:

```markdown
## Key Abstractions

### Domain Models

Located in `src/models/`. Represent core business entities.

- `User` - System user with auth credentials
- `Project` - User-owned project container
- `Task` - Work item within a project

### DTOs (Data Transfer Objects)

Located in `src/types/dto/`. Used for API input/output.

- `Create*Dto` - Input for creation endpoints
- `Update*Dto` - Input for update endpoints  
- `*Response` - Output from endpoints

### Error Types

Located in `src/errors/`. Typed errors for different failure cases.

- `NotFoundError` - Resource doesn't exist
- `ValidationError` - Input validation failed
- `AuthorizationError` - Permission denied
```

### Dependencies & Integrations

Help AI understand how things connect:

```markdown
## Dependencies & Integrations

### Internal Dependencies

\`\`\`
Routes → Services → Repositories → Database
           ↓
        External APIs
\`\`\`

- Routes depend on Services (never Repositories directly)
- Services depend on Repositories and external API clients
- Repositories depend only on database connection

### External Services

| Service | Purpose | Client Location |
|---------|---------|-----------------|
| Stripe | Payments | `src/clients/stripe.ts` |
| SendGrid | Email | `src/clients/email.ts` |
| S3 | File storage | `src/clients/storage.ts` |
```

### Common Tasks

Guide AI through common operations:

```markdown
## Common Tasks

### Adding a New API Endpoint

1. Create route handler in `src/api/routes/`
2. Add validation schema in `src/api/validators/`
3. Implement service method in `src/services/`
4. Add repository method if new data access needed
5. Register route in `src/api/routes/index.ts`

### Adding a New Service

1. Create `src/services/[name].service.ts`
2. Create `src/services/[name].service.test.ts`
3. Export from `src/services/index.ts`
4. Create corresponding repository if needed

### Adding a Database Migration

1. Run `npm run migration:create [name]`
2. Edit migration in `src/migrations/`
3. Run `npm run migration:run`
4. Update relevant models in `src/models/`
```

### Do NOT Section

Explicitly state anti-patterns:

```markdown
## Do NOT

### Architecture
- Do NOT access repositories from route handlers (go through services)
- Do NOT import from `src/` using relative paths outside the module
- Do NOT put business logic in route handlers

### Code Style
- Do NOT use `any` type (use `unknown` and narrow)
- Do NOT use default exports (use named exports)
- Do NOT mutate function parameters

### Database
- Do NOT write raw SQL outside of repositories
- Do NOT use string concatenation for queries (SQL injection risk)
- Do NOT commit with pending migrations

### Deprecated Patterns
- Do NOT use the old `BaseService` class (removed in v2)
- Do NOT use `src/helpers/` (moved to `src/utils/`)
```

---

## Subdirectory AGENTS.md

For complex directories, create local AGENTS.md files. Focus on the **pattern** for that directory — do not list every file with its methods and dependencies (AI can read the files directly).

```markdown
# src/services/AGENTS.md

## Purpose
Contains all business logic services.

## Pattern
- One file per domain: `[domain].service.ts`
- Corresponding test: `[domain].service.test.ts`
- Injected repositories via constructor
- Services throw domain-specific errors, not generic ones

## Conventions
- Services never access the database directly — always through repositories
- External API calls are wrapped in client classes, not called inline
```

**Do NOT** list every file individually with its methods and dependencies. That information is already in the source code and becomes stale quickly.

---

## Updating AGENTS.md After Changes

### When Architecture Changes

1. Update Architecture Overview diagram
2. Update Directory Structure if new directories added or removed
3. Update Dependencies section

### When Patterns are Added/Changed

1. Add new pattern documentation
2. **Remove or replace** documentation for the old pattern it supersedes
3. Update examples to point to new code
4. Add to Common Tasks if applicable

### When Conventions Change

1. Update Coding Conventions section
2. Add old pattern to "Do NOT" with deprecation note

### When Files/Components are Deleted

1. Remove references to deleted files from all sections
2. Remove or update patterns that no longer apply
3. Remove subdirectory AGENTS.md if the directory was deleted

### Cleanup Discipline

When updating any section, also review that section for outdated content:
- Remove documentation for files/components that no longer exist (within the context of what you know changed)
- Replace descriptions superseded by the current changes
- Condense or merge content that has become redundant
- **Do not** search the codebase for unrelated stale content — only clean up within the scope of what you're updating

---

## Checklist Before Committing AGENTS.md Changes

- [ ] Architecture diagram matches current structure
- [ ] Directory structure is accurate
- [ ] Key patterns are documented (patterns, not per-file listings)
- [ ] Examples point to real files that exist
- [ ] Outdated content from this update's scope has been removed
- [ ] References to deleted files/components have been removed
- [ ] Dependencies section reflects actual imports
- [ ] "Do NOT" section is current
- [ ] Root AGENTS.md is under 500 lines
- [ ] Subdirectory AGENTS.md files are under 150 lines
- [ ] Subdirectory AGENTS.md files updated if needed
