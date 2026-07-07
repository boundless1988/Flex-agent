---
name: verification-before-completion
description: Use before Codex claims work is complete, fixed, passing, verified, ready for commit, or ready for handoff; requires fresh evidence from tests, builds, checks, review, or manual validation.
---

# Verification Before Completion

Make completion claims only after fresh verification evidence supports them.

## Entry Conditions

Use this skill before saying or implying that repository work is:

- complete;
- fixed;
- passing;
- verified;
- ready to commit;
- ready for review, handoff, or completion.

For Harness-managed repository modification tasks, this skill is required in VERIFY before COMPLETE.

## Boundary

This skill verifies work and reports evidence. It does not advance workflow phases, update `control.md`, call `multi-agent-coordination`, create commits, push, merge, clean branches, or decide completion by itself.

If verification fails, return the evidence to the current implementation context or `workflow-controller`.

## Verification Method

1. Identify the claim that is about to be made.
2. Identify the evidence required to support that claim.
3. Prefer existing project commands, targeted tests, builds, type checks, lint, static analysis, or manual acceptance checks grounded in the task.
4. Run or inspect the required evidence freshly when execution is available.
5. Read the full relevant output, including exit code, failure counts, warnings, skipped tests, and partial-run indicators.
6. Compare the evidence to the confirmed requirements and plan.
7. Report the actual state.

Do not invent project commands. If no command is known, say what evidence is missing and use the best available static or manual check.

## Evidence Standards

| Claim | Required evidence |
| --- | --- |
| Tests pass | Fresh test output showing success for the relevant suite or target |
| Build succeeds | Fresh build output or exit code showing success |
| Type check or lint is clean | Fresh tool output for the relevant scope |
| Bug is fixed | Reproduction or regression check for the original symptom |
| Review feedback is resolved | Each finding classified, fixed or deferred, and verified |
| Requirements are met | Requirement-by-requirement check against behavior or artifacts |
| Ready for completion | Required verification is done and failures are absent or explicitly accepted |

Previous runs, expected behavior, visual inspection alone, or another agent's success report are not enough for a completion claim.

## Handling Failures

If verification fails:

- do not claim completion;
- report the failing command or check;
- include the important failure output;
- identify whether the cause is understood;
- use `systematic-debugging` when the cause is unclear;
- return to implementation only within the confirmed scope.

If verification cannot be run:

- state exactly why;
- report what was checked instead;
- mark the result as unverified or partially verified;
- do not convert partial evidence into a full success claim.

## Manual Verification

Manual verification is acceptable when it is the right evidence for the task or no executable check exists.

Record:

- what was inspected;
- the input or scenario used;
- the expected result;
- the observed result;
- any gaps that remain untested.

## Output

Return:

- claim being verified;
- commands or checks used;
- pass/fail result;
- key evidence;
- unverified areas or residual risk;
- whether the task can proceed toward completion.

Use exact status language:

- `verified` only when evidence supports it;
- `partially verified` when some evidence is missing;
- `not verified` when verification was unavailable or failed.

## Self-Review

Before returning, check:

- the evidence is fresh for this work;
- the checked scope matches the claim;
- no failure, skip, or warning was ignored;
- assumptions are not presented as facts;
- the result is returned to the controller or caller rather than advancing the workflow directly.
