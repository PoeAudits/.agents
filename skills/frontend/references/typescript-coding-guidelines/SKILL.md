---
name: typescript-coding-guidelines
description: Must be read if not already read before writing any Typescript code.
license: MIT
---

# General Coding Guidelines

## Structure
Order matters for readability (even if it doesn't affect semantics). On the first read, a file is read top-down, so put important things near the top. The main function goes first.

## Control Flow
Use only very simple, explicit control flow for clarity. Do not use recursion to ensure that all executions that should be bounded are bounded. Use only a minimum of excellent abstractions but only if they make the best sense of the domain. Abstractions are never zero cost. Every abstraction introduces the risk of a leaky abstraction.

## Data Structures
All loops and all queues must have a fixed upper bound to prevent infinite loops or tail latency spikes. This follows the “fail-fast” principle so that violations are detected sooner rather than later. Where a loop cannot terminate (e.g. an event loop), this must be asserted.

## Error Handling
All errors must be handled. An analysis of production failures in distributed data-intensive systems found that the majority of catastrophic failures could have been prevented by simple testing of error handling code.

## Naming
Add units or qualifiers to variable names, and put the units or qualifiers last, sorted by descending significance, so that the variable starts with the most significant word, and ends with the least significant word. For example, latency_ms_max rather than max_latency_ms. This will then line up nicely when latency_ms_min is added, as well as group all variables that relate to latency.

When choosing related names, try hard to find names with the same number of characters so that related variables all line up in the source. For example, source and target are better than src and dest because they have the second-order effect that any related variables such as source_offset and target_offset will all line up in calculations and slices. This makes the code symmetrical, with clean blocks that are easier for the eye to parse and for the reader to check.

When a single function calls out to a helper function or callback, prefix the name of the helper function with the name of the calling function to show the call history. For example, read_sector() and read_sector_callback().

A noun is often a better descriptor than an adjective or present participle, because a noun can be directly used in correspondence without having to be rephrased.


## Types
Use the smallest type that can represent the value. Every variable, parameter, and return value must have an explicit type.

# Typescript Coding Guidelines

## Architecture & Design Patterns
Functional vs Class-based: Prefer functional style unless you need to create multiple instances of the same object type
Composition over Inheritance: Prefer composition and interfaces over abstract classes and inheritance
Small Functions: Keep functions small, well-contained, and single-purpose - each function should do one thing well

## Interfaces vs Types
Use `interface` for object shapes - if it can be an interface, it should be
Use `type` for unions, intersections, and mapped types
```typescript
// Good - object shape
interface User {
  id: string;
  name: string;
}

// Good - union type
type Status = "pending" | "active" | "inactive";

// Good - intersection
type AdminUser = User & { permissions: string[] };
```

## Type System
Strict Mode: Always use `strict: true` in tsconfig (including `strictNullChecks`)
No `any`: Never use `any` except in extreme circumstances; everything should be strictly typed
Type Guards: Prefer type guards over `as Type` assertions
```typescript
// Good - type guard
function isUser(obj: unknown): obj is User {
  return typeof obj === "object" && obj !== null && "id" in obj;
}

// Avoid - type assertion
const user = data as User;
```
Explicit Return Types: Always annotate function return types explicitly
Type-Only Imports: Use `import type` for types to improve build performance and clarify intent
```typescript
// Good - type-only import
import type { User, UserConfig } from "./types";
import { createUser } from "./user";

// Avoid - mixing types with runtime imports when separable
import { User, UserConfig, createUser } from "./user";
```

## Advanced Type Patterns
Branded Types: Use branded types for domain modeling to prevent primitive type confusion
```typescript
type UserId = string & { readonly __brand: "UserId" };
type OrderId = string & { readonly __brand: "OrderId" };

function createUserId(id: string): UserId {
  return id as UserId;
}

// Compiler prevents mixing UserId and OrderId
function getUser(id: UserId): User { /* ... */ }
getUser(orderId); // Error: OrderId not assignable to UserId
```

Discriminated Unions: Use discriminated unions for state machines and variant types
```typescript
type RequestState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: User }
  | { status: "error"; error: Error };

function handleState(state: RequestState): void {
  switch (state.status) {
    case "idle":
      return;
    case "loading":
      showSpinner();
      return;
    case "success":
      displayUser(state.data); // TypeScript knows data exists
      return;
    case "error":
      showError(state.error); // TypeScript knows error exists
      return;
  }
}
```

Exhaustive Checking: Use the `never` type to ensure all cases are handled
```typescript
function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${x}`);
}

function handleStatus(status: Status): string {
  switch (status) {
    case "pending":
      return "Waiting...";
    case "active":
      return "Running";
    case "inactive":
      return "Stopped";
    default:
      return assertNever(status); // Compile error if case is missing
  }
}
```

Const Assertions: Use `as const` for literal types and immutable data
```typescript
// Creates readonly tuple with literal types
const ROLES = ["admin", "user", "guest"] as const;
type Role = (typeof ROLES)[number]; // "admin" | "user" | "guest"

// Creates deeply readonly object with literal types
const CONFIG = {
  api: { timeout_ms: 5000, retries_max: 3 },
  features: { darkMode: true },
} as const;
```

Satisfies Operator: Use `satisfies` to validate types while preserving inference
```typescript
type RouteConfig = Record<string, { path: string; auth: boolean }>;

// Validates structure but preserves literal types
const routes = {
  home: { path: "/", auth: false },
  dashboard: { path: "/dashboard", auth: true },
} satisfies RouteConfig;

// TypeScript knows exact keys: routes.home, routes.dashboard
// Not just: routes[string]
```

Const Enums: Use `const enum` only when you need inlined values and control the entire codebase
```typescript
// Good - when you need zero runtime overhead and don't publish as library
const enum HttpStatus {
  OK = 200,
  NOT_FOUND = 404,
  SERVER_ERROR = 500,
}
// Compiles to: if (status === 200) instead of: if (status === HttpStatus.OK)

// Avoid const enum when:
// - Publishing a library (consumers can't use --isolatedModules)
// - Using --isolatedModules (const enums don't work)
// - You need runtime iteration over enum values

// Prefer union types for most cases (see Enums section)
```

## Build Optimization
Project References: Use project references for large codebases to enable incremental builds
```json
// tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo"
  },
  "references": [
    { "path": "./packages/shared" },
    { "path": "./packages/api" }
  ]
}
```
Build with: `tsc --build` to leverage incremental compilation

Incremental Compilation: Enable incremental builds for faster compilation
```json
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo"
  }
}
```

Skip Lib Check: Use `skipLibCheck: true` to speed up compilation (skips type checking of declaration files)

## Null Handling
Prefer `undefined` over `null` for absent values (aligns with TypeScript's optional property behavior)
Use explicit null checks over optional chaining for clarity
```typescript
// Preferred - explicit check
if (user !== undefined) {
  console.log(user.name);
}

// Avoid when possible
console.log(user?.name);
```
Nullish Coalescing: Use `??` over `||` for defaults when dealing with potentially falsy values (industry standard)

## Enums
Prefer union types over TypeScript `enum` (avoids runtime quirks)
```typescript
// Good - union type
type Status = "pending" | "active" | "inactive";

// Avoid - enum
enum Status {
  Pending,
  Active,
  Inactive,
}
```

## Code Style
Semicolons: Use semicolons
Quotes: Use double quotes for strings; use single quotes only when the string contains double quotes
Naming Conventions: Follow TypeScript industry standards
- `camelCase` for variables, functions, methods
- `PascalCase` for classes, interfaces, types, enums
- `UPPER_SNAKE_CASE` for constants
File Naming: Follow industry standard conventions (`kebab-case.ts` for files, `PascalCase.ts` for files exporting a single class/component)

## Comments & Documentation
Keep comments minimal or omit entirely (same as Python)
Use JSDoc for public APIs when documentation is needed
Let type annotations document function signatures

## Modules & Imports
Named Imports: Always use named imports; avoid `import *`
```typescript
// Good
import { UserService, UserRepository } from "./user";

// Avoid
import * as User from "./user";
```
Barrel Files: Use `index.ts` re-exports only in specific scenarios where they provide clear organizational benefit
Default vs Named Exports: Follow common conventions - named exports are generally preferred for better refactoring support
Path Aliases: Use `@/` style imports for cleaner paths (configure in tsconfig `paths`)
```typescript
// Good - path alias
import { UserService } from "@/services/user";

// Also acceptable - relative
import { UserService } from "../../services/user";
```

## Error Handling
Custom Errors: Create custom error classes, typically in their own file
```typescript
// errors.ts
export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ValidationError";
  }
}
```
Exceptions: Use throw/catch for error handling (not Result/Either pattern)

## Async
Async/Await: Prefer `async/await` over raw Promises for readability
Use raw Promises only when best practices dictate (e.g., `Promise.all` for concurrent operations)

## Testing
Framework: Use Bun's built-in test runner for Bun projects; use Vitest or Jest for pnpm/Node projects (whichever is most common for the project type)
Organization: Keep tests in a separate `tests/` directory (not colocated with source)
Structure: Mirror source directory structure within tests

## Tooling
Linter/Formatter: Use ESLint + Prettier
Runtime: Prefer Bun; use Node.js when project requirements dictate

## Dependency Management
Use Bun or pnpm package manager - always check which package manager is used in the project
Avoid adding new packages unless necessary
Use lockfiles (`bun.lockb`, `pnpm-lock.yaml`)

## Security
Never commit or log secrets, API keys, or credentials
Use environment variables for sensitive configuration

## React & Next.js
Components: Use functional components only; avoid class components
Hooks: Prefer hooks over HOCs (Higher-Order Components)
Styling: Use Tailwind CSS for styling
```typescript
// Good - functional component with hooks
function UserProfile({ userId }: UserProfileProps): JSX.Element {
  const [user, setUser] = useState<User | undefined>(undefined);
  
  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, [userId]);
  
  return <div className="p-4 bg-white rounded-lg">{user?.name}</div>;
}
```

## Runtime Validation
Use Zod for runtime validation of external data (API responses, form inputs, environment variables)
```typescript
import { z } from "zod";

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  age: z.number().min(0),
});

type User = z.infer<typeof UserSchema>;

// Validate at runtime
const user = UserSchema.parse(apiResponse);
```
