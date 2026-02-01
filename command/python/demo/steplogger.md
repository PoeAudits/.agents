---
description: Creates or updates a StepLogger utility for Python demo-driven development pipelines.
temperature: 0.05
---

# Python StepLogger Implementation

You are an implementation agent that creates a StepLogger utility for Python demo-driven development pipelines.

## Your Task

Create or update a StepLogger class that provides formatted, color-coded console output for pipeline steps. Place it in the project's utility location (typically `src/<project>/step_logger.py` or `lib/step_logger.py`).

## Requirements

### Core Functionality

The StepLogger must support:

1. **Construction** with a step name, whether data is cached, and whether this is the frontier step
2. **start()** - Print step header with name and status (NEW/CACHED)
3. **info(message)** - Print an indented info message (colored)
4. **detail(label, value)** - Print a label: value pair (colored)
5. **sample(label, items)** - Print a label followed by up to 5 sample items
6. **warning(message)** - Print a yellow warning message
7. **error(message)** - Print a red error message
8. **complete()** - Print success message with duration

### Two-Tier Color Scheme

The logger uses different color intensities based on whether this is the frontier step (newest/last step in pipeline):

**Frontier step** (`is_frontier=True`): Bright colors
- GREEN_BRIGHT: `\033[92m` - Headers, success, info
- YELLOW_BRIGHT: `\033[93m` - Warnings
- RED_BRIGHT: `\033[91m` - Errors
- CYAN_BRIGHT: `\033[96m` - Details, values

**Previous steps** (`is_frontier=False`): Dark/standard colors
- GREEN_DARK: `\033[32m` - Headers, success, info
- YELLOW_DARK: `\033[33m` - Warnings
- RED_DARK: `\033[31m` - Errors
- CYAN_DARK: `\033[36m` - Details, values

**Common colors**:
- GRAY: `\033[90m` - Cached status indicator
- RESET: `\033[0m` - Return to default

### Output Format

Step header (frontier step, fresh data):
```
================================================================================
[STEP 2: Filter Pools]                                                    (NEW)
================================================================================
```

Step header (previous step, cached):
```
================================================================================
[STEP 1: Anchor Prices]                                                (CACHED)
================================================================================
```

Info messages (2-space indent, colored based on frontier status):
```
  Loading trigger_pools.json...
    Total pools: 2,638
```

Detail output (label: value pairs):
```
  Pools with WETH: 1,804
  Pools with USDC: 314
```

Sample output:
```
  Top 5 by anchor balance:
    WETH/USDC 0.3%: $81.06M
    USDC/USDT 0.05%: $52.50M
    WBTC/WETH 0.3%: $47.10M
```

Completion:
```
  [OK] Step complete in 5.68s
```

### Cached Output Behavior

When displaying cached data, show the same level of detail as fresh runs:
- Display all data breakdowns, summaries, and sample items from the cache
- Skip lines that represent active operations (progress bars, "Fetching..." messages)
- The output should be nearly identical to fresh runs, just without network activity lines

## Implementation

```python
import time
from typing import Any, Sequence


class StepLogger:
    """Logger for demo-driven development pipeline steps.
    
    Uses a two-tier color scheme:
    - Frontier step (is_frontier=True): Bright colors for the newest step
    - Previous steps (is_frontier=False): Dark colors for completed steps
    """

    # Bright colors for frontier step
    COLORS_BRIGHT = {
        "GREEN": "\033[92m",
        "YELLOW": "\033[93m",
        "RED": "\033[91m",
        "CYAN": "\033[96m",
    }

    # Dark colors for previous steps
    COLORS_DARK = {
        "GREEN": "\033[32m",
        "YELLOW": "\033[33m",
        "RED": "\033[31m",
        "CYAN": "\033[36m",
    }

    # Common colors
    GRAY = "\033[90m"
    RESET = "\033[0m"

    def __init__(self, name: str, is_cached: bool = False, is_frontier: bool = True) -> None:
        self.name = name
        self.is_cached = is_cached
        self.is_frontier = is_frontier
        self.start_time: float | None = None
        self.colors = self.COLORS_BRIGHT if is_frontier else self.COLORS_DARK

    def start(self) -> None:
        self.start_time = time.time()
        status = "(CACHED)" if self.is_cached else "(NEW)"
        color = self.colors["GREEN"]

        padding = 80 - len(self.name) - len(status) - 3

        print(f"\n{'=' * 80}")
        print(f"{color}[{self.name}]{' ' * padding}{status}{self.RESET}")
        print(f"{'=' * 80}\n")

    def info(self, message: str) -> None:
        color = self.colors["GREEN"]
        print(f"  {color}{message}{self.RESET}")

    def detail(self, label: str, value: Any) -> None:
        cyan = self.colors["CYAN"]
        print(f"  {label}: {cyan}{value}{self.RESET}")

    def detail_indent(self, label: str, value: Any) -> None:
        cyan = self.colors["CYAN"]
        print(f"    {label}: {cyan}{value}{self.RESET}")

    def sample(self, label: str, items: Sequence[Any], items_max: int = 5) -> None:
        color = self.colors["GREEN"]
        cyan = self.colors["CYAN"]
        print(f"\n  {color}{label}{self.RESET}")
        for item in list(items)[:items_max]:
            print(f"    {cyan}{item}{self.RESET}")

    def warning(self, message: str) -> None:
        yellow = self.colors["YELLOW"]
        print(f"  {yellow}[WARN] {message}{self.RESET}")

    def error(self, message: str) -> None:
        red = self.colors["RED"]
        print(f"  {red}[ERROR] {message}{self.RESET}")

    def complete(self) -> None:
        green = self.colors["GREEN"]

        if self.start_time:
            duration = time.time() - self.start_time
            print(f"\n  {green}[OK] Step complete in {duration:.2f}s{self.RESET}\n")
        else:
            print(f"\n  {green}[OK] Step complete{self.RESET}\n")


if __name__ == "__main__":
    # Frontier step (bright colors) - fresh data
    logger = StepLogger("STEP 2: Filter Pools", is_cached=False, is_frontier=True)
    logger.start()
    logger.info("Loading trigger_pools.json...")
    logger.detail_indent("Total pools", "2,638")
    logger.info("Filtering by anchor token...")
    logger.detail("Pools with WETH", "1,804")
    logger.detail("Pools with USDC", "314")
    logger.detail("Pools with USDT", "248")
    logger.sample("Top 5 by anchor balance:", [
        "WETH/USDC 0.3%: $81.06M",
        "USDC/USDT 0.05%: $52.50M",
        "WBTC/WETH 0.3%: $47.10M",
    ])
    logger.warning("12 pools excluded (balance < $1,000)")
    logger.complete()

    # Previous step (dark colors) - cached data
    logger2 = StepLogger("STEP 1: Anchor Prices", is_cached=True, is_frontier=False)
    logger2.start()
    logger2.info("Anchor Prices:")
    logger2.detail_indent("USDC", "$1.00")
    logger2.detail_indent("USDT", "$1.00")
    logger2.detail_indent("WETH", "$3,084.81")
    logger2.detail_indent("WBTC", "$90,296.70")
    logger2.complete()
```

## Usage in Pipeline Steps

```python
from step_logger import StepLogger


def run_step(
    step_num: int,
    cache: dict[str, Any],
    force_refresh: bool = False,
    is_frontier: bool = False,
) -> dict[str, Any]:
    cache_key = f"step_{step_num}_output"
    is_cached = not force_refresh and cache_key in cache

    logger = StepLogger(
        f"STEP {step_num}: Data Processing",
        is_cached=is_cached,
        is_frontier=is_frontier,
    )
    logger.start()

    if is_cached:
        data = cache[cache_key]
        # Show same detail as fresh run, using cached data
        logger.info("Data Processing Results:")
        logger.detail("Total items", len(data))
        logger.detail("Valid items", data.get("valid_count", 0))
        logger.sample("Sample items:", list(data.get("items", {}).items())[:5])
        logger.complete()
        return data

    # Fresh run with network calls
    logger.info("Fetching data...")
    result = fetch_data()

    logger.info("Data Processing Results:")
    logger.detail("Total items", len(result))
    logger.detail("Valid items", result.get("valid_count", 0))
    logger.sample("Sample items:", list(result.get("items", {}).items())[:5])

    cache[cache_key] = result
    logger.complete()

    return result
```

## Pipeline Orchestrator Pattern

```python
def run_pipeline(refresh: bool = False, no_cache: bool = False) -> None:
    cache = {} if no_cache else load_cache()
    steps = [step_0, step_1, step_2, step_3]
    step_count = len(steps)

    for i, step_fn in enumerate(steps):
        is_frontier = (i == step_count - 1)
        # Only refresh the frontier step when --refresh is used
        force_refresh = no_cache or (refresh and is_frontier)
        step_fn(cache, force_refresh=force_refresh, is_frontier=is_frontier)

    save_cache(cache)
```

## Notes

- Uses only standard library (no external dependencies)
- Not thread-safe (designed for single-threaded pipeline execution)
- Timing is automatic from start() to complete()
- Frontier step = last step in pipeline (brightest colors)
- Cached output should show same detail as fresh, minus network activity lines

## Additional Instructions

$ARGUMENTS
