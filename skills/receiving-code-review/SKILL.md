---
name: receiving-code-review
description: Use when Codex receives review feedback or findings and must evaluate, clarify, accept, reject, or implement them without blindly following reviewer suggestions or expanding scope.
---

# Receiving Code Review

Evaluate review feedback technically, then handle valid findings within the confirmed task scope.

## Entry Conditions

Use this skill when:

- a reviewer, user, tool, or another agent returns code review feedback;
- implementation needs to process findings from `code-review`;
- feedback is ambiguous, partly wrong, or may conflict with prior decisions;
- multiple findings need triage and ordered handling.

Do not use this skill to perform the initial review. Use `code-review` for that.

## Boundary

This skill does not advance workflow phases, update `control.md`, call `multi-agent-coordination`, choose reviewers, or broaden the task scope.

Return accepted fixes, rejected findings, unresolved questions, and verification evidence to the current implementation context or `workflow-controller`.

## Review Feedback Process

1. Read all feedback before editing.
2. Split feedback into distinct findings or requests.
3. For each item, identify the exact claim and affected files or behavior.
4. Check the claim against the codebase, requirements, tests, and confirmed plan.
5. Classify the item.
6. Handle one item at a time.
7. Verify each accepted fix with focused evidence.

## Classification

Use these categories:

- `valid`: the issue is real and in scope;
- `valid-but-out-of-scope`: the issue is real but outside the confirmed task;
- `unclear`: the request lacks enough information to implement safely;
- `conflicts-with-confirmed-decision`: the feedback contradicts prior user or design confirmation;
- `not-reproducible`: the claim could not be confirmed with available evidence;
- `incorrect`: the feedback is contradicted by code, tests, or requirements.

## Handling Rules

For `valid` findings:

- implement the smallest fix that resolves the finding;
- keep changes within the confirmed task scope;
- run focused verification;
- record what changed and how it was verified.

For `unclear` findings:

- do not guess;
- ask the minimum clarifying question or return the exact missing information needed.

For `valid-but-out-of-scope` findings:

- report the issue separately;
- do not implement unless the user or controller expands scope.

For `conflicts-with-confirmed-decision` findings:

- stop and return the conflict for decision;
- do not silently override the confirmed design or plan.

For `not-reproducible` or `incorrect` findings:

- explain the evidence checked;
- provide a concise technical reason for not changing code;
- state any residual risk.

## Multi-Item Feedback

When feedback contains multiple items:

1. clarify blocking ambiguity first;
2. handle correctness, security, data loss, or build-breaking issues before style issues;
3. keep independent fixes separate in the report;
4. verify after each material fix or after a small coherent group;
5. do not use one finding as permission for unrelated cleanup.

## Communication

Use technical acknowledgement, not performative agreement.

Prefer:

- `Finding confirmed: <specific issue>. Fixing <scope>.`
- `I cannot verify this because <missing evidence>.`
- `This appears out of scope because <reason>.`
- `This conflicts with <confirmed decision>. Returning for decision.`

Avoid:

- claiming a reviewer is right before checking;
- gratitude or praise as a substitute for action;
- defensive wording;
- long apologies if an initial pushback was wrong.

## Verification

For every accepted fix, provide the verification evidence appropriate to the finding:

- targeted test;
- reproduction check;
- build/type/lint command;
- manual acceptance check;
- static inspection with file references when no executable check exists.

If verification fails, use `systematic-debugging` when the cause is unclear.

Use `verification-before-completion` before claiming all review feedback is resolved.

## Output

Return:

- feedback items and classifications;
- accepted fixes and changed behavior;
- rejected or deferred items with evidence;
- unresolved questions;
- verification commands or checks and results;
- remaining risk.

## Self-Review

Before returning, check:

- every feedback item is accounted for;
- no unverified finding was blindly implemented;
- no out-of-scope change slipped in;
- valid fixes have evidence;
- disagreements are grounded in code, tests, requirements, or confirmed decisions.
