---
name: handoff
description: Interrupts orchestration and creates a handoff report for continuation by another agent. Updates the plan with current status and saves a focused handoff file.
---

# Orchestration Handoff

This command is used to **interrupt orchestration** and prepare for handoff to another agent session. When invoked, you must:

1. **Update the plan** with current execution status
2. **Create a handoff report** in `thoughts/handoffs/`
3. **Confirm the handoff** to the user

The **plan file is the source of truth** for progress, task status, and completion notes. The handoff report captures what's NOT in the plan: divergences, difficulties, context, and continuation guidance.

---

## Step 1: Update the Plan

Add or update a **Status Section** at the bottom of the current plan file:

```markdown
---

## Execution Status

**Last Updated:** [timestamp]
**Handoff ID:** [generated-id]

### Phase Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1: [Name] | ✅ Complete | [any notes] |
| Phase 2: [Name] | 🔄 In Progress | Currently on Task 2.3 |
| Phase 3: [Name] | ⏳ Pending | |

### Current Position

**Active Phase:** Phase 2: [Name]
**Active Task:** Task 2.3: [Task Name]
**Task Status:** [In Progress / Blocked / Awaiting Review]

### Completed Tasks This Session

- [x] Task 1.1: [Name] - [brief outcome]
- [x] Task 1.2: [Name] - [brief outcome]
- [x] Task 2.1: [Name] - [brief outcome]
- [x] Task 2.2: [Name] - [brief outcome]
- [ ] Task 2.3: [Name] - **IN PROGRESS**

### Next Actions

1. [What should happen next]
2. [Following action]
```

### Status Markers

Use these markers consistently:

| Marker | Meaning |
|--------|---------|
| `✅` | Complete |
| `🔄` | In Progress |
| `⏳` | Pending (not started) |
| `⚠️` | Blocked |
| `❌` | Failed (needs attention) |
| `📝` | Needs Review |
| `📄` | Needs Documentation |

---

## Step 2: Create Handoff Report

Create a file in `thoughts/handoffs/` with this structure:

**Filename:** `handoff-[YYYY-MM-DD]-[short-description].md`

The handoff report complements the plan — it captures what the plan doesn't: divergences, difficulties, important context, and continuation guidance. Do NOT repeat progress summaries, completed work details, or file change lists that are already in the plan.

```markdown
# Orchestration Handoff Report

**Created:** [timestamp]
**Plan File:** [path to plan file]
**Current Position:** Phase [N], Task [N.M] — [In Progress / Blocked / Pending]

---

## Objective

[1-2 sentence summary of what the orchestration is accomplishing]

---

## Divergences from Plan

[Document any deviations from the original plan. Write "None" if the plan was followed exactly.]

| Original Plan | What Was Done Instead | Why |
|---------------|----------------------|-----|
| [planned approach] | [actual approach] | [reason for change] |

**Scope Adjustments:**
- [Any tasks added, removed, or reordered — or "None"]

---

## Difficulties & Issues

### Current Blockers
[If the handoff is due to a blocker, or "None"]
- **Blocker:** [description]
- **Impact:** [what's blocked]
- **Attempted:** [what was tried]
- **Needed:** [what would unblock]

### Known Issues
[Problems encountered or deferred — or "None"]
- [Issue and how it was handled or why it was deferred]

---

## Important Context Not in the Plan

[Decisions, observations, and lessons learned that aren't captured in task completion notes]

- [Decision or observation]: [what and why it matters for continuation]
- [Another item]

---

## Continuation Guidance

### What to Do First
1. [First thing the pickup agent should do]
2. [Second step]
3. [Third step]

### Files to Review
[Key files the next agent should read before continuing]
- `path/to/file` - [why]

---

## Pickup Command

To continue this orchestration:

\`\`\`
/pickup @thoughts/handoffs/[this-filename].md
\`\`\`
```

---

## Step 3: Confirm Handoff

After creating both updates, confirm to the user:

```markdown
## Handoff Complete

**Plan Updated:** [path to plan]
**Handoff Report:** `thoughts/handoffs/[filename].md`

### To Continue
\`\`\`
/pickup @thoughts/handoffs/[filename].md
\`\`\`
```

---

## When to Use Handoff

Use `/handoff` when:
- You need to stop orchestration mid-execution
- Context window is getting full
- A long-running task needs to continue in a new session
- You want to checkpoint progress before a risky operation
- The user requests interruption

---

## Important Notes

1. **Update the plan first** - The plan is the source of truth; ensure its Execution Status is current before creating the handoff report
2. **Don't duplicate the plan** - The handoff captures what's NOT in the plan (divergences, difficulties, context, guidance)
3. **Be specific** - The pickup agent has no memory; be explicit about non-obvious context
4. **Note divergences** - Any deviation from plan must be documented in the handoff
5. **Guide continuation** - Tell the pickup agent what to do first and what files to read
