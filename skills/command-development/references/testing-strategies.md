# Command Testing Strategies

Practical checks to catch the most common command issues.

## 1) File is in the right place

- Command file exists under `.agents/command/`
- File extension is `.md`

## 2) Frontmatter sanity

- If you use frontmatter, it should be valid YAML
- Keep `description` short

## 3) Argument sanity

- If you document args via `argument-hint`, ensure your command uses the same ordering (`$1`, `$2`, ...)
- Prefer `$ARGUMENTS` when you want “all remaining text”

## 4) File reference sanity (`@`)

Repo convention:
- User passes `@path` as `$1`
- Command uses `$1` directly (don’t write `@$1`)

## 5) Bash interpolation sanity

- Keep `!` backtick commands fast and non-destructive
- Prefer simple context gathering (branch, status, recent commits)
