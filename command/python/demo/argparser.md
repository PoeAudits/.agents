---
description: Creates or updates an argument parser module for Python CLI pipelines.
temperature: 0.05
---

# Python ArgParser Module

You are an implementation agent that creates or updates an argument parser module for Python CLI applications. The parser should be in a separate module from main.py for clean separation of concerns.

## Your Task

Create or update an argument parser module at `src/<project>/parser/args.py`. If the file exists, align it with the template pattern. If it doesn't exist, create it with the basic template.

## Requirements

### File Location

```
src/<project>/
├── main.py              # Imports and uses the parser
└── parser/
    ├── __init__.py      # Exports create_parser and parse_args
    └── args.py          # Parser definition
```

### Docstring Format

The args.py file MUST have a docstring at the top documenting all CLI commands. This serves as quick reference for the user. Order commands by frequency of use (most common first).

```python
"""
CLI Commands
============

Run full pipeline (cached):
    python -m project_name
    make run

Refresh newest step only:
    python -m project_name --refresh
    make run-refresh

Run with empty cache (all steps fresh):
    python -m project_name --no-cache
    make cache-clear && make run

Run up to specific step:
    python -m project_name --step 2
    python -m project_name --step 0 --refresh

Debug mode:
    python -m project_name --verbose

Options
-------
--refresh, -r     Refresh cache for newest step only
--no-cache        Clear all cache, run everything fresh
--step N, -s N    Run only up to step N (0-indexed)
--verbose, -v     Enable verbose/debug output
--help, -h        Show this help message
"""
```

### Template Implementation

```python
"""
CLI Commands
============

Run full pipeline (cached):
    python -m project_name
    make run

Refresh newest step only:
    python -m project_name --refresh
    make run-refresh

Run with empty cache (all steps fresh):
    python -m project_name --no-cache
    make cache-clear && make run

Options
-------
--refresh, -r     Refresh cache for newest step only
--no-cache        Clear all cache, run everything fresh
--step N, -s N    Run only up to step N (0-indexed)
--verbose, -v     Enable verbose/debug output
--help, -h        Show this help message
"""

import argparse
from dataclasses import dataclass


@dataclass
class Args:
    """Parsed command-line arguments."""

    refresh: bool
    no_cache: bool
    step: int | None
    verbose: bool


def create_parser() -> argparse.ArgumentParser:
    """Create the argument parser for the pipeline CLI."""
    parser = argparse.ArgumentParser(
        description="Run the data processing pipeline.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "--refresh",
        "-r",
        action="store_true",
        help="Refresh cache for newest step only",
    )

    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Clear all cache, run everything fresh",
    )

    parser.add_argument(
        "--step",
        "-s",
        type=int,
        default=None,
        help="Run only up to step N (0-indexed)",
    )

    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose/debug output",
    )

    return parser


def parse_args() -> Args:
    """Parse command-line arguments and return typed Args object."""
    parser = create_parser()
    namespace = parser.parse_args()

    return Args(
        refresh=namespace.refresh,
        no_cache=namespace.no_cache,
        step=namespace.step,
        verbose=namespace.verbose,
    )


if __name__ == "__main__":
    args = parse_args()
    print(f"refresh: {args.refresh}")
    print(f"no_cache: {args.no_cache}")
    print(f"step: {args.step}")
    print(f"verbose: {args.verbose}")
```

### Parser __init__.py

```python
"""Argument parser module."""

from .args import Args, create_parser, parse_args

__all__ = ["Args", "create_parser", "parse_args"]
```

### Usage in main.py

```python
from parser import parse_args


def main() -> None:
    args = parse_args()

    if args.verbose:
        print("Verbose mode enabled")

    run_pipeline(
        refresh=args.refresh,
        no_cache=args.no_cache,
        step_max=args.step,
    )


if __name__ == "__main__":
    main()
```

### Pipeline Integration

The orchestrator should handle the flags as follows:

```python
def run_pipeline(refresh: bool = False, no_cache: bool = False, step_max: int | None = None) -> None:
    cache = {} if no_cache else load_cache()
    steps = [step_0, step_1, step_2, step_3]
    
    if step_max is not None:
        steps = steps[:step_max + 1]
    
    step_count = len(steps)

    for i, step_fn in enumerate(steps):
        is_frontier = (i == step_count - 1)
        # --no-cache: refresh everything
        # --refresh: only refresh the frontier step
        force_refresh = no_cache or (refresh and is_frontier)
        step_fn(cache, force_refresh=force_refresh, is_frontier=is_frontier)

    save_cache(cache)
```

## Makefile Integration

When adding CLI arguments, also add corresponding Makefile targets. Standard targets:

```makefile
# Run pipeline (cached)
run:
	python -m project_name

# Refresh newest step only
run-refresh:
	python -m project_name --refresh

# Clear cache directory
cache-clear:
	rm -rf cache/*

# Run with verbose output
run-verbose:
	python -m project_name --verbose

# Run specific step
run-step-%:
	python -m project_name --step $*
```

## Adding New Arguments

When adding new CLI arguments:

1. **Update the docstring first** - Add the new command with examples (including make command)
2. **Add to Args dataclass** - Add the typed field
3. **Add to create_parser()** - Add the argument definition
4. **Add to parse_args()** - Map namespace to Args field
5. **Update main.py** - Use the new argument
6. **Update Makefile** - Add corresponding target

### Example: Adding --output flag

```python
# 1. Update docstring (add to appropriate section)
"""
Output options:
    python -m project_name --output results.json
    make run-output FILE=results.json

Options
-------
--output FILE, -o FILE    Write results to FILE (default: stdout)
"""

# 2. Add to Args dataclass
@dataclass
class Args:
    refresh: bool
    no_cache: bool
    step: int | None
    verbose: bool
    output: str | None  # New field

# 3. Add to create_parser()
parser.add_argument(
    "--output",
    "-o",
    type=str,
    default=None,
    help="Write results to FILE (default: stdout)",
)

# 4. Add to parse_args()
return Args(
    refresh=namespace.refresh,
    no_cache=namespace.no_cache,
    step=namespace.step,
    verbose=namespace.verbose,
    output=namespace.output,  # New mapping
)

# 6. Add to Makefile
# run-output:
# 	python -m project_name --output $(FILE)
```

## Guidelines

### Docstring Ordering

Order commands in the docstring by frequency of use:
1. Most common usage (running the full pipeline)
2. Refresh newest step (`--refresh`)
3. Full cache clear (`--no-cache`)
4. Step-specific runs
5. Debug/development options

### Argument Naming

- Use descriptive names (`--refresh` not `--r`)
- Provide short aliases for common flags (`-r`, `-v`, `-s`)
- Use consistent patterns across projects
- `--refresh` = newest step only, `--no-cache` = everything

### Type Safety

- Always use a dataclass for parsed args (not raw namespace)
- Use explicit types (`int | None` not `Optional[int]`)
- Validate arguments in parse_args() if needed

## Additional Instructions

$ARGUMENTS
