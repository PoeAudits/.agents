---
name: pickup
description: Continues orchestration from a handoff report. Reads the handoff file and resumes execution from where the previous agent stopped.
---

# Orchestration Pickup

This command is used to **continue orchestration** from a previous session's handoff. When invoked with a handoff file, you must:

1. **Read and understand** the handoff report
2. **Verify the current state** matches the handoff
3. **Present your understanding** of what's left and your continuation plan
4. **Wait for user confirmation** before proceeding
5. **Resume orchestration** from the documented position

---

## Usage

```
/pickup @thoughts/handoffs/handoff-YYYY-MM-DD-description.md
```

Or with additional context:
```
/pickup @thoughts/handoffs/handoff-file.md

Additional instructions:
[Any updates or changes to the original plan]
```

---

## Pickup Process

### Step 1: Read the Handoff Report

The handoff file contains:
- Current execution state (phase, task, status)
- Completed work summary
- Divergences from original plan
- Blockers and open issues
- Continuation instructions
- Files to review

**Extract these key details:**
- What was the last completed task?
- What is the current/next task?
- Are there any blockers?
- What files were changed?
- What decisions were made?

### Step 2: Read the Plan

Get the plan file path from the handoff report and read it.

**Verify:**
- The Execution Status section matches the handoff
- Task completion markers are accurate
- No unexpected changes since handoff

### Step 3: Gather Context

Before resuming, dispatch **seeker** to:
- Verify the files mentioned in handoff exist and match expectations
- Gather any context mentioned in "Context to Gather" section
- Check for any changes since the handoff

### Step 4: Present Understanding (REQUIRED - WAIT FOR CONFIRMATION)

**Before any implementation**, you MUST present your understanding and wait for user confirmation:

```markdown
## Pickup Summary

**Handoff ID:** [from handoff file]
**Plan:** [path to plan]

---

### Current Position

**Resuming From:**
- **Phase:** [Phase N: Name] - [phase status]
- **Task:** [Task N.M: Name] - [task status]

**Progress So Far:**
- Phases complete: [N] of [Total]
- Tasks complete: [N] of [Total]

---

### What's Left To Do

**Remaining in Current Phase ([Phase N: Name]):**
- [ ] Task N.M: [Name] - [brief description]
- [ ] Task N.M+1: [Name] - [brief description]
...

**Remaining Phases:**
| Phase | Name | Tasks | Description |
|-------|------|-------|-------------|
| [N+1] | [Name] | [count] | [1-line goal] |
| [N+2] | [Name] | [count] | [1-line goal] |

**Total Remaining:** [N] tasks across [N] phases

---

### Key Context from Handoff

**Divergences Already Made:**
- [Any divergences noted in handoff, or "None"]

**Previous Blockers/Issues:**
- [Any blockers noted and how they were resolved, or "None"]

**Important Decisions Made:**
- [Key decisions from previous session that affect continuation]

---

### My Continuation Plan

**Starting With:**
> Task [N.M]: [Name]

**Why this is the starting point:**
- [Explanation based on handoff state]

**Subagent I'll use:** [worker/executor] because [brief reason]

**Approach for This Session:**
1. **First:** [Immediate action - complete current task / address blocker / etc.]
2. **Then:** [Next step - review / continue to next task]
3. **After that:** [Following step]
4. **Phase end:** [Document when phase completes]

**Potential Challenges I See:**
- [Any risks, uncertainties, or things to watch for]
- [Or "None identified" if straightforward]

---

### Confirmation Required

Please review my understanding and confirm before I proceed:

- Reply **"continue"** to proceed with this plan
- Reply **"stop"** or provide corrections if something is wrong
- Reply with questions if you want to discuss anything first
```

**CRITICAL:** Do NOT proceed with any implementation until the user explicitly confirms. This checkpoint ensures alignment before work begins.

---

### Step 5: Resume Orchestration (ONLY AFTER USER CONFIRMS)

Once user confirms (says "continue", "proceed", "go ahead", etc.), then resume:

```
IF current task was "In Progress":
    → Assess the partial work
    → Decide: complete it or restart it
    
IF current task was "Blocked":
    → Address the blocker first
    → Use seeker to gather needed information
    
IF current task was "Awaiting Review":
    → Dispatch reviewer
    → Handle review results
    
IF current task was "Pending":
    → Start the task normally
```

### Step 6: Acknowledge and Begin

After user confirms, briefly acknowledge:

```markdown
## Proceeding with Orchestration

Confirmed. Starting with **Task [N.M]: [Name]**.

[Dispatch appropriate subagent...]
```

---

## Handling Handoff Scenarios

### Scenario: Task Was In Progress

```
1. Read the partial work description from handoff
2. Dispatch seeker to examine current state of affected files
3. Determine if work is:
   a) Complete but not marked → Mark complete, proceed
   b) Partially complete → Resume or restart based on quality
   c) Not started despite status → Start fresh
4. Continue with appropriate subagent
```

### Scenario: Task Was Blocked

```
1. Read the blocker description
2. Read the "Needed" information
3. Dispatch seeker to gather the needed context
4. Re-attempt the task with new information
5. If still blocked, document and notify user
```

### Scenario: Review Was Pending

```
1. Identify files that need review
2. Dispatch reviewer with original requirements
3. Handle review results:
   - PASS → Proceed to next task
   - NEEDS REVISION → Dispatch worker/executor to fix
   - PASS WITH NOTES → Note issues, proceed
```

### Scenario: Documentation Was Pending

```
1. Check if phase implementation is complete
2. Verify review passed
3. Dispatch documenter with phase summary
4. Then proceed to next phase
```

---

## Validating Handoff Accuracy

Before trusting the handoff, verify:

| Check | How |
|-------|-----|
| Files exist | Glob/read the listed files |
| Plan status matches | Read plan, check markers |
| No conflicting changes | Check git status if available |
| Handoff is recent | Check timestamp |

If discrepancies are found:

```markdown
## Handoff Discrepancy Detected

**Issue:** [what doesn't match]

**Handoff says:** [handoff state]
**Actual state:** [current state]

**Resolution options:**
a) Trust handoff, ignore discrepancy
b) Trust current state, update from there
c) Stop and ask user for guidance

Awaiting instruction...
```

---

## Continuing the Orchestration

After pickup is complete, continue normal orchestration:

1. Follow the standard orchestration flow
2. Update plan status as tasks complete
3. Dispatch reviewer after implementation steps
4. Dispatch documenter after phases
5. Handle blockers with seeker → re-delegate

### Progress Markers

Continue using the status markers from handoff:

| Marker | Meaning |
|--------|---------|
| `✅` | Complete |
| `🔄` | In Progress |
| `⏳` | Pending |
| `⚠️` | Blocked |
| `❌` | Failed |
| `📝` | Needs Review |
| `📄` | Needs Documentation |

Update the plan's Execution Status section as you progress.

---

## When Another Handoff is Needed

If you need to hand off again:

1. Use `/handoff` command
2. Reference the original handoff in the new one
3. Update the plan status section
4. Create new handoff file with incremented context

```markdown
## Previous Handoffs
- `handoff-2025-01-20-initial.md` - Initial → Phase 2
- `handoff-2025-01-21-continued.md` - Phase 2 → Phase 3 (current)
```

---

## Important Notes

1. **Wait for confirmation** - ALWAYS present understanding and wait for user to confirm before implementing
2. **Verify before acting** - Don't trust handoff blindly; check current state
3. **Acknowledge divergences** - Previous session's changes are now canonical
4. **Continue the pattern** - Follow same orchestration style as original
5. **Update as you go** - Keep plan status current for potential future handoffs
6. **Don't repeat work** - Trust completed task markers unless evidence suggests otherwise
