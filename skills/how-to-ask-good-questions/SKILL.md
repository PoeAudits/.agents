---
name: how-to-ask-good-questions
description: Principles for asking effective clarifying questions. Covers when to ask vs. proceed, question formatting, conflict detection, pause protocols, and assumption handling. Use when instructions are ambiguous, underspecified, or potentially contradictory.
---

# How to Ask Good Questions

## Purpose

This skill provides principles and techniques for gathering information effectively through clarifying questions. The goal is to ask the **minimum set of high-leverage questions** needed to proceed confidently, while making it easy for users to respond quickly.

## When to Use This Skill

Use this skill when:
- A request has multiple plausible interpretations
- Key details are missing or unclear
- You detect potential contradictions in requirements
- The scope, constraints, or success criteria are ambiguous
- Acting on assumptions could lead to significant rework

## When NOT to Use This Skill

Do not ask questions when:
- The request is already clear and actionable
- A quick, low-risk discovery read can answer the question (check configs, existing patterns, docs first)
- The action is low-risk and easily reversible
- You've already asked about this topic and received an answer

**Key principle:** Before asking, check if the answer is discoverable from context. Read relevant files, configs, or documentation first.

---

## Determining If Clarification Is Needed

Treat a request as underspecified if any of the following are unclear:

| Dimension | Questions to Consider |
|-----------|----------------------|
| **Objective** | What should change? What should stay the same? |
| **"Done" criteria** | How will we know it's complete? What does success look like? |
| **Scope** | Which files/components/users are in scope? What's explicitly out? |
| **Constraints** | Compatibility requirements? Performance targets? Style guidelines? Dependencies? Timeline? |
| **Environment** | Language/runtime versions? OS? Build/test infrastructure? |
| **Safety/Reversibility** | Data migration risks? Rollout/rollback plan? Impact on existing users? |

If multiple plausible interpretations exist for any of these, assume clarification is needed.

---

## Question Design Principles

### Question Count Guidelines

- **Ask 3-10 questions per round** depending on complexity:
  - **3-4 questions:** Focused requests with limited ambiguity
  - **5-7 questions:** Moderate complexity, multiple unclear dimensions
  - **8-10 questions:** Broad requests, many unknowns, or significant risk
- **Prioritize questions that eliminate whole branches of work** - one good question can save hours
- **Separate "must know" from "nice to know"** - ask critical questions first, defer optional ones

### Question Ordering

Structure questions in this order to build understanding progressively:

1. **Scope questions first:** What's in/out? Which components are affected?
2. **Objective/goal questions:** What should change? What does success look like?
3. **Constraint questions:** Compatibility, performance, timeline requirements?
4. **Implementation preference questions:** Approach, style, patterns to follow?
5. **Edge cases and "done" criteria last:** Error handling, acceptance criteria?

This ordering ensures you understand the boundaries before diving into details.

### Combining Related Questions

When multiple questions address the same topic, combine them to reduce cognitive load:

**Instead of:**
```
1) Should this support OAuth?
2) Should this support email/password?
3) Should this support magic links?
```

**Combine into:**
```
1) Authentication methods to support?
   a) Email/password only (recommended)
   b) Email/password + OAuth (Google, GitHub)
   c) Email/password + OAuth + magic links
   d) Not sure - use recommended
```

**Combine when:**
- Questions are about the same feature dimension
- Options are mutually exclusive or form a progression
- Answering one would inform the others

### Handling Cascading/Dependent Options

When one answer makes other questions irrelevant, handle it explicitly:

**Option 1: Note dependencies inline**
```
1) Authentication approach?
   a) Build custom auth
   b) Use third-party service (Auth0, Supabase, Firebase)
   c) Not sure - use recommended
   
   → If you choose (b), skip questions 2-4 (the service handles those details)

2) Session management? [Skip if 1b]
   a) JWT tokens (recommended)
   b) Server-side sessions
```

**Option 2: Create branching question sets**
```
1) Authentication approach?
   a) Build custom → I'll ask 4 follow-up questions
   b) Use third-party service → I'll ask 2 follow-up questions (which service, config preferences)
```

**Option 3: Defer dependent questions**
Ask the branching question first, wait for the answer, then ask relevant follow-ups only.

### Make Questions Easy to Answer

Structure questions so users can respond quickly with minimal cognitive load:

1. **Use numbered questions with lettered options:**
   ```
   1) Scope?
      a) Minimal change (recommended)
      b) Refactor while touching the area
      c) Not sure - use recommended
   
   2) Backward compatibility?
      a) Must support existing API (recommended)
      b) Breaking changes acceptable
      c) Not sure - use recommended
   ```

2. **Provide a fast-path response:**
   ```
   Reply with: `defaults` to accept all recommended options
   Or reply with your choices: `1a 2b`
   ```

3. **Include a "not sure" escape hatch:**
   - "Not sure - use recommended"
   - "Skip - decide for me"

4. **Mark defaults clearly:**
   - Bold the recommended choice, or
   - Add "(recommended)" or "(default)" labels
   - Put a **Recommended** header above option blocks

5. **Optimize for scannability:**
   - Short, numbered questions
   - Avoid paragraphs of explanation
   - Use bullet points and tables

### Question Templates

Use these patterns as starting points:

- **Scope clarification:**
  "Before I start, I need to understand: (1) ..., (2) ..., (3) .... If you're unsure about (2), I'll assume ...."

- **Binary choice:**
  "Should this: A) ... or B) ...? (pick one)"

- **Success criteria:**
  "What would you consider 'done'? For example: ..."

- **Constraints:**
  "Any constraints I must follow (versions, performance, style, deps)? If none, I'll target existing project defaults."

- **Compact multi-choice:**
  ```
  1) Target? a) New users only  b) All users  c) Not sure
  2) Timeline? a) This sprint  b) Flexible  c) Not sure
  
  Reply: `1b 2a` or `defaults`
  ```

---

## Review Before Sending

After drafting your questions, review them before presenting to the user:

### Check for Overlap

Look for questions that ask about the same thing differently:
- "What's the scope?" and "Which components should I touch?" → Combine
- "What does done look like?" and "What are the acceptance criteria?" → Combine
- "Any constraints?" and "What's the timeline?" → Keep separate (timeline is specific)

### Check for Redundancy

Remove questions where:
- The answer is implied by another question's answer
- You could infer the answer from context
- The question is "nice to know" but not blocking

### Check for Gaps

Ensure you've covered the essential dimensions:
- [ ] Scope (in/out) is clear
- [ ] Success criteria are defined
- [ ] Key constraints are identified
- [ ] No obvious ambiguities remain

### Merge Similar Questions

If two questions have significant overlap, merge them:

**Before:**
```
3) Error handling approach?
4) How should failures be logged?
```

**After:**
```
3) Error handling?
   a) Silent failures with logging (recommended)
   b) User-visible error messages
   c) Throw exceptions, let caller handle
```

---

## Conflict Detection

### Direct Contradictions (Stop Immediately)

A **direct contradiction** occurs when two statements are logically incompatible - both cannot be true simultaneously.

**Criteria for direct contradiction:**
- Statement A explicitly negates Statement B
- Satisfying A makes B impossible (not just difficult)
- No reasonable interpretation reconciles them

**Examples:**
- "Must be synchronous" vs. "Should use async/await throughout"
- "No external dependencies" vs. "Use Redis for caching"
- "Read-only operation" vs. "Update the user's profile"

**When detected:**

1. **Stop asking other questions**
2. **Clearly identify the conflict**
3. **Quote both conflicting statements**
4. **Ask for explicit resolution**

Example:
> I need to pause - I've detected a contradiction:
>
> Earlier: "The system should process requests in real-time"
> Just now: "Batch processing overnight is fine"
>
> These seem to conflict. Which approach is correct, or is there a distinction I'm missing?

**Do not continue gathering information until the contradiction is resolved.** Conflicting information leads to poor downstream results.

### Potential Tensions (Flag Before Continuing)

A **tension** exists when requirements are difficult to satisfy together but not logically impossible. They require tradeoffs or creative solutions.

**Criteria for tension:**
- Both requirements are technically possible
- Achieving both fully is difficult or expensive
- A tradeoff or prioritization decision is needed

**Examples:**
- "Sub-100ms response" + "Query external API on every request" (possible with caching, but tension exists)
- "Simple, minimal UI" + "Show all available options" (possible with progressive disclosure, but tension exists)
- "Done by Friday" + "Full test coverage" (possible if scope is small, but tension exists)

**When detected:**

1. **Present tensions before your next questions**
2. **Explain why they might conflict**
3. **Ask for clarification on tensions first**
4. **Then proceed with other questions**

Example:
> Before my next questions, I want to flag potential tensions:
>
> **Tension 1:** "Sub-100ms response times" + "query external API on every request" - external API latency may make this difficult. Options: caching, background refresh, or relaxed latency target.
>
> **Tension 2:** "Simple, minimal UI" + "show all available options" - may require tradeoffs like progressive disclosure or a "show more" pattern.
>
> How should these tensions be resolved?
>
> ---
> Additional questions:
> 1. ...

---

## Pause Protocol

### While Waiting for Answers

**Blocked actions:**
- Running commands that commit to a direction
- Editing files
- Producing detailed plans that depend on unknowns
- Making irreversible changes

**Allowed actions:**
- Low-risk discovery reads (inspect repo structure, read configs)
- Gathering context that doesn't commit you to a direction
- Preparing options for different answer scenarios

### When User Says "Just Proceed"

If the user explicitly asks you to proceed without answering questions:

1. **State your assumptions as a numbered list:**
   > Proceeding with these assumptions:
   > 1. Scope: minimal change, only touching X component
   > 2. Compatibility: must work with existing API
   > 3. Timeline: this can be done incrementally

2. **Ask for confirmation:**
   > Please confirm these assumptions are correct, or let me know what to adjust.

3. **Proceed only after confirmation or correction**

---

## Confirmation Before Acting

Once you have answers, confirm your understanding before starting work:

1. **Restate requirements in 1-3 sentences**
2. **Include key constraints and success criteria**
3. **Then begin work**

### Example Confirmation

**After receiving answers like:** `1a 2b 3a 4b`

> **Confirming before I start:**
> 
> I'll add JWT-based authentication to the existing Express app. Scope is login/logout only (no registration flow for now). Must maintain backward compatibility with the current session endpoints during migration. Success = users can authenticate via the new `/auth/login` endpoint and access protected routes.
>
> Starting implementation now.

### Example with Tensions Resolved

**After user resolves a performance vs. feature tension:**

> **Confirming approach:**
>
> I'll optimize the dashboard API with a 500ms target (relaxed from 100ms). Caching external API responses for 5 minutes is acceptable. Will add a loading state for the initial fetch. The "real-time" requirement applies only to the notification badge, not the full dashboard.
>
> Proceeding with this approach.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Asking questions you could answer by reading code/configs | Check context first, then ask only what you can't discover |
| Open-ended questions ("What else should I know?") | Specific multiple-choice or yes/no questions |
| Too many questions at once (15+) | 3-10 high-leverage questions per round |
| Vague questions ("Any preferences?") | Concrete options ("Should this use REST or GraphQL?") |
| Asking about low-stakes decisions | Make reasonable defaults, mention them briefly |
| Re-asking about topics already answered | Track what's been established |
| Paragraph-long question explanations | Short, scannable bullet points |
| Questions with significant overlap | Combine into single multi-option question |
| Ignoring dependent relationships | Note when answers make other questions irrelevant |

---

## Checklist: Before Asking

### Content Check
- [ ] Did I check if the answer is in the codebase (configs, patterns, docs)?
- [ ] Is each question high-leverage (eliminates significant ambiguity)?
- [ ] Am I asking the minimum number of questions needed?
- [ ] Have I covered scope, success criteria, and key constraints?

### Format Check
- [ ] Are questions formatted for quick response (numbered, multiple-choice)?
- [ ] Did I provide a fast-path option (`defaults`)?
- [ ] Did I mark recommended choices clearly?
- [ ] Did I include "not sure" escape hatches?

### Quality Check
- [ ] Are questions ordered logically (scope → goals → constraints → details)?
- [ ] Have I combined related questions where appropriate?
- [ ] Have I noted any cascading dependencies between questions?
- [ ] Is there any overlap between questions that should be merged?
- [ ] Am I blocking on must-know questions, not nice-to-know?
