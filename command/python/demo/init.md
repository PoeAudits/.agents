---
description: Verifies and aligns Python project structure for demo-driven development.
temperature: 0.05
---

# Demo Project Initialization

You are an initialization agent that verifies a Python project follows the demo-driven development structure and fixes any gaps.

## Your Task

Check the existing project structure and ensure it matches the expected conventions. Create missing directories and files as needed. Do NOT create a new project directory - operate within the current working directory.

## Process

### Step 1: Analyze Current Structure

Check what exists:
```bash
ls -la
ls -la src/ 2>/dev/null || echo "No src/ directory"
ls -la thoughts/ 2>/dev/null || echo "No thoughts/ directory"
```

### Step 2: Report Status

Present findings to the user:

```
## Project Structure Check

✓ Exists: src/project_name/
✓ Exists: pyproject.toml
✗ Missing: src/project_name/parser/
✗ Missing: thoughts/plans/
✗ Missing: AGENTS.md

Shall I create the missing items?
```

### Step 3: Create Missing Structure

Upon confirmation, create missing directories and files.

## Expected Structure

```
project/
├── src/
│   └── <project_name>/
│       ├── __init__.py
│       ├── main.py              # Pipeline orchestrator
│       ├── parser/
│       │   ├── __init__.py
│       │   └── args.py          # Argument parser
│       ├── steps/               # Pipeline step modules
│       │   └── __init__.py
│       └── step_logger.py       # Logging utility
├── lib/                         # Shared utilities
├── tests/
│   └── __init__.py
├── thoughts/
│   └── plans/                   # Implementation plans
├── .cache/                      # Step output cache (gitignored)
├── pyproject.toml
├── AGENTS.md
└── .gitignore
```

## File Templates

### pyproject.toml (if missing)

```toml
[project]
name = "project-name"
version = "0.1.0"
description = ""
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "ruff>=0.4",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
```

### AGENTS.md (if missing)

```markdown
# AGENTS.md

## Overview
[Project description - to be filled in]

## Architecture Decisions
- Caching: JSON files in .cache/ directory
- Logging: StepLogger for pipeline step output
- CLI: argparse in separate parser/ module

## Key Patterns
- StepLogger: Use for all pipeline step output
- ArgParser: Separate module in parser/args.py
- Steps: Each step in its own module in steps/

## File Structure
src/<project>/main.py - pipeline orchestrator
src/<project>/parser/args.py - CLI argument parser
src/<project>/steps/ - pipeline step modules
src/<project>/step_logger.py - colored console logging
lib/ - shared utilities
tests/ - test files
thoughts/plans/ - implementation plans
```

### main.py (if missing)

```python
"""Pipeline orchestrator."""

from parser import parse_args


def main() -> None:
    args = parse_args()

    if args.verbose:
        print("Verbose mode enabled")

    # TODO: Add pipeline steps here
    print("Pipeline not yet implemented")


if __name__ == "__main__":
    main()
```

### parser/__init__.py (if missing)

```python
"""Argument parser module."""

from .args import Args, create_parser, parse_args

__all__ = ["Args", "create_parser", "parse_args"]
```

### parser/args.py (if missing)

Use the template from the argparser command.

### step_logger.py (if missing)

Use the template from the steplogger command.

### .gitignore additions

Ensure these entries exist:
```
.cache/
__pycache__/
*.pyc
.venv/
```

## uv Setup

If pyproject.toml was created or modified:

```bash
uv venv
uv sync
```

If dev dependencies are needed:
```bash
uv sync --extra dev
```

## Verification

After initialization, verify:

```bash
# Check structure
tree -L 3 src/

# Verify uv setup
uv run python -c "print('Python environment OK')"

# Run the pipeline (should show "not yet implemented")
uv run python -m project_name
```

## Example Interaction

```
User: /demo-init

Agent: ## Project Structure Check

Checking current directory...

✓ Exists: pyproject.toml
✓ Exists: src/weather_dashboard/
✓ Exists: src/weather_dashboard/__init__.py
✗ Missing: src/weather_dashboard/parser/
✗ Missing: src/weather_dashboard/steps/
✗ Missing: src/weather_dashboard/step_logger.py
✗ Missing: thoughts/plans/
✗ Missing: AGENTS.md
✓ Exists: .gitignore (but missing .cache/ entry)

Shall I create the missing items and update .gitignore?

User: yes

Agent: Creating structure...

  mkdir -p src/weather_dashboard/parser
  Created src/weather_dashboard/parser/__init__.py
  Created src/weather_dashboard/parser/args.py
  
  mkdir -p src/weather_dashboard/steps
  Created src/weather_dashboard/steps/__init__.py
  
  Created src/weather_dashboard/step_logger.py
  
  mkdir -p thoughts/plans
  
  Created AGENTS.md
  
  Updated .gitignore (added .cache/)

Running uv sync...
  uv sync --extra dev
  ✓ Dependencies installed

Verification:
  uv run python -m weather_dashboard
  > Pipeline not yet implemented

Project structure ready for demo-driven development.
Next: Create a plan with /demo-planner
```

## Additional Instructions

$ARGUMENTS
