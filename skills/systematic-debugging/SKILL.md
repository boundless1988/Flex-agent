---
name: systematic-debugging
description: Use when a bug, test failure, build failure, runtime exception, regression, flaky behavior, or environment issue has an unclear root cause and Codex needs evidence-driven diagnosis before changing code.
---

# Systematic Debugging

Find the root cause of an observed failure before proposing or applying a fix.

## Entry Conditions

Use this skill when:

- a test, build, type check, lint, or runtime path fails;
- behavior differs from the confirmed requirement;
- a regression appears after a change;
- a failure is flaky, timing-dependent, or environment-dependent;
- an earlier fix attempt did not solve the issue;
- the root cause is not already demonstrated by evidence.

Do not use this skill when the root cause and fix are already confirmed, or when the task is ordinary implementation with no unexpected failure.

## Boundary

This skill does not advance workflow phases, update `control.md`, call `multi-agent-coordination`, create commits, or perform branch finishing.

Return findings, fixes attempted, and verification evidence to the current implementation context or `workflow-controller`.

## Method

### 1. Establish the Symptom

- Read the complete error message, stack trace, failing assertion, or log.
- Record the command, input, environment, and exact observed output.
- Distinguish the symptom from the suspected cause.
- If the failure cannot be reproduced, gather enough data to describe when it appears and when it does not.

### 2. Check Recent and Relevant Context

- Inspect recent local changes, configuration changes, dependency changes, environment differences, and affected files.
- Find similar working code or tests in the same repository.
- Compare the broken path with the working path and list material differences.
- Do not assume a difference is irrelevant until checked.

### 3. Trace the Cause

When the error appears deep in a call chain:

1. identify the immediate failing operation;
2. trace the bad value, state, or decision one caller upward;
3. continue until the original trigger is found;
4. fix the source rather than the symptom.

Add diagnostic logging or temporary instrumentation only when it directly tests where the failure originates. Remove or justify diagnostic code before completion.

### 4. Form One Hypothesis

State a single hypothesis:

```text
I think the root cause is <cause> because <evidence>.
```

Then test the smallest useful change or observation that can confirm or falsify it.

Do not bundle multiple fixes. If the hypothesis fails, update the evidence and form a new hypothesis instead of stacking guesses.

### 5. Fix the Root Cause

When the root cause is supported by evidence:

- prefer the smallest fix that addresses the source of the problem;
- add or update a focused regression check when practical;
- add defense-in-depth validation at important boundaries when invalid data or unsafe state crossed multiple layers;
- avoid unrelated refactoring or opportunistic cleanup.

TDD may be useful for the regression check, but this skill does not make TDD mandatory.

### 6. Verify

Run the narrow command that demonstrates the failure is fixed, then any broader checks required by the task context.

Use `verification-before-completion` before claiming the work is fixed, passing, or complete.

## Supporting Techniques

### Root Cause Tracing

Use when a failure is reported far from the original source.

- Start at the failing operation.
- Ask what input or state made it fail.
- Ask where that input or state came from.
- Repeat until changing the source would prevent the symptom.

### Defense In Depth

Use after finding a bug caused by invalid data, unsafe state, or assumptions crossing layers.

- Validate at the entry point.
- Validate again where the operation becomes dangerous or expensive.
- Add environment guards for test-only or platform-specific hazards.
- Keep debug context sufficient for future investigation.

### Condition-Based Waiting

Use for flaky asynchronous tests or timing-sensitive behavior.

- Wait for the actual condition, event, state, count, file, or output.
- Avoid arbitrary sleeps unless testing real timing behavior.
- If an arbitrary timeout is required, document the known timing reason.
- Always include a bounded timeout with a useful error message.

## Red Flags

Stop and return to evidence gathering if you are about to:

- change code because the fix "seems obvious";
- add a retry, timeout, null check, or fallback without explaining the root cause;
- make several changes before re-running a focused check;
- rely on manual inspection when a reproducible check is available;
- keep trying fixes after several failed attempts without questioning the underlying design;
- treat a reviewer, manager, or prior pattern as proof without checking the current codebase.

If three focused fix attempts fail, pause and report that the diagnosis or architecture may be wrong before continuing.

## Output

Return:

- symptom and reproduction evidence;
- relevant context inspected;
- root cause hypothesis and result;
- confirmed root cause, or what remains unknown;
- changes made, if any;
- verification performed and result;
- next step or blocker.

Do not present assumptions as confirmed facts.

## Self-Review

Before returning, check:

- the failure was understood before fixing;
- evidence supports the root cause;
- the fix addresses the source, not only the symptom;
- no unrelated changes were introduced;
- verification evidence is fresh and specific;
- unresolved uncertainty is explicitly reported.
