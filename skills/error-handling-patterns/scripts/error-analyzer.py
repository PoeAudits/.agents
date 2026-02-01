#!/usr/bin/env python3

"""Minimal log error summarizer.

Read lines from stdin and print a frequency table of distinct error lines.
Keep dependencies minimal and avoid non-standard libraries.
"""

from __future__ import annotations

import sys
from collections import Counter


def main() -> int:
    lines = [line.rstrip("\n") for line in sys.stdin if line.strip()]
    counts = Counter(lines)
    for line, n in counts.most_common():
        print(f"{n}\t{line}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
