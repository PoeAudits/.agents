---
name: python-coding-guidelines
description: Must be read if not already read before writing any Python code.
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

# Python Coding Guidelines

## Core Review Areas
Code Quality & Readability: Ensure code follows "write for readability" principle - imagine someone ramping up 3-9 months from now
Python Patterns: Check for proper Python patterns, especially as it relates to context managers and exceptions
Security: Prevent secret exposure and ensure proper authentication patterns

## Architecture & Design Patterns
Protocol vs ABC: Always use `Protocol` for structural subtyping instead of `ABC` inheritance
Functional vs Class-based: Prefer functional style with pure functions unless you need to create multiple instances of the same object type - then use classes
Data-centric design: Structure functions around data structures - functions should receive and return the same data structure (mutated) or return a copied/transformed version
Mutability: Prefer mutable data structures; avoid `frozen=True` on dataclasses unless immutability is explicitly required

## Python & Code Style
Type Safety: Explicit return types on functions, comprehensive type annotations
Modern Python: Use `str | None` instead of `Optional[str]`, built-in collections over imported types
Import Organization: Standard library, third-party, local imports (alphabetically sorted within groups)
Variable Naming: Keep variable names consistent for easier grepping, use descriptive names for exports
Error Handling: Avoid bare `except:`, be specific with exception types
Code Patterns: Prefer early returns over nested conditionals
Private Members: Use single underscore prefix (`_private`) for private functions/variables
Constants: Use `UPPER_SNAKE_CASE` at module level for constants
Comprehensions: Use list/dict/set comprehensions for single-level operations only; break nested comprehensions into explicit loops
String Formatting: Use f-strings exclusively; avoid `%` formatting and `.format()` unless required for lazy evaluation (e.g., logging)
Match Statements: Use `match/case` when there are more than two options; use `if/elif/else` for simple binary or ternary conditions
Walrus Operator: Avoid `:=` for clarity unless it significantly improves readability

## Context Managers
Use `with` statements for resource management (files, connections, locks)
Write custom context managers for resources that need setup/teardown
```python
# Good
with open("file.txt") as f:
    content = f.read()

# Good - custom context manager
@contextmanager
def database_connection():
    conn = create_connection()
    try:
        yield conn
    finally:
        conn.close()
```

## Generators
Use generators for large datasets to avoid loading everything into memory
Materialize to lists only when the full collection is needed
```python
# Good - generator for large data
def process_large_file(path: Path) -> Iterator[dict]:
    with open(path) as f:
        for line in f:
            yield parse_line(line)
```

## Decorators
Leverage decorators when they provide clear value
Keep custom decorators small and focused
Prefer simple functions over complex decorator chains

## Module Exports
Define explicit `__all__` in modules to control public API
```python
__all__ = ["UserService", "create_user", "UserConfig"]
```

## Docstrings
Keep docstrings minimal or omit entirely
If used, keep to a single line describing the purpose
Avoid verbose parameter/return documentation - let type hints speak for themselves

## Formatting
Add blank lines after class definitions and dataclass decorators
Use double quotes for strings (ruff default)
Line length of 100 characters
Proper spacing around operators and after commas
Check all code with `uv run ruff check` and `uv run ruff format`

## Dependency Management
Use the `uv` package manager
Avoid adding new packages unless necessary
Vet new dependencies carefully (check source, maintenance, security)
Use `uv add` and `uv add --dev` to update dependencies, NOT manual pyproject.toml edits
Keep dependencies up to date (check for major version updates regularly)

## Data Validation
Use dataclasses for simple internal data structures
Use Pydantic for complex data structures or external data validation (APIs, config files, user input)
```python
# Simple internal data - use dataclass
@dataclass
class Point:
    x: float
    y: float

# Complex external data - use Pydantic
class UserConfig(BaseModel):
    name: str
    email: EmailStr
    settings: dict[str, Any]
```

## CLI Tools
Use `argparse` for command-line interfaces

## Async
Use `asyncio` as the async library
Prefer sync code unless async provides clear benefits (I/O bound operations, concurrent requests)

## Logging
Use the standard `logging` module
Configure different colors for different log levels
Timestamp format should include date and time to the minute (no seconds/milliseconds)
Example format: `"%(asctime)s - %(levelname)s - %(message)s"` with `datefmt="%Y-%m-%d %H:%M"`

## Testing
Framework: Use `pytest`
Organization: Mirror source directory structure in tests
Naming: Use `test_*.py` for test files
Structure: Use multiple focused test files rather than one large test file
Async tests: Use `pytest-asyncio` when testing async code

## Security & Authentication
Secret Management:
Never commit or log secrets, API keys, or credentials
Use .env files with `dotenv.load_dotenv()`
Never use `os.environ["ANTHROPIC_API_KEY"] = "sk-..."`

## HTTP Client
Use `requests` for HTTP requests (sync)
Use `httpx` if async HTTP is needed

## Path Handling
Use `pathlib.Path` instead of string paths
Avoid `os.path` functions; prefer `Path` methods

## Virtual Environments
Use `uv venv` to create virtual environments
Use default `.venv` directory name

## Script Entrypoints
Use the `if __name__ == "__main__":` pattern for script entrypoints
```python
def main() -> None:
    # Script logic here
    pass

if __name__ == "__main__":
    main()
```

## File Structure
Use `tmp/` folder for temporary files (gitignored)
Follow python best practices for file names (snake_case)
Keep the `__init__.py` file up to date within a directory if the files in the directory are edited
Group related functions together in files; separate unrelated code into different files
No hard max file length, but prioritize logical grouping over file size

