---
name: code-review
description: Use when Codex must perform a read-only technical code review of implemented changes against confirmed requirements, plan, and repository context, reporting correctness, boundary, maintainability, security, and test findings with severity and evidence.
---

# Code Review

Perform a read-only review of implemented changes. The goal is to find concrete issues before completion, not to request another reviewer, dispatch an agent, or fix the code during review.

## Entry Conditions

Use this skill when:

- A change set, diff, branch, worktree, or list of modified files is available.
- Requirements, a confirmed plan, or an expected behavior summary is available.
- The user or `workflow-controller` asks for code review.
- Review is needed before verification, completion, merge, or acceptance.

Do not use this skill for:

- Plan review before implementation. Use `reviewing-plans`.
- Applying review feedback. Use `receiving-code-review`.
- Debugging an unknown failure. Use `systematic-debugging`.
- Dispatching reviewers or choosing executors. That belongs to `workflow-controller` and its coordination layer.

## Inputs

Gather the minimum evidence needed to review:

- Requirements, confirmed plan, acceptance criteria, and known non-goals.
- Changed files, diff, branch range, or paths to inspect.
- Relevant surrounding code, tests, schemas, APIs, migrations, or docs.
- Verification evidence already produced, including failures.
- Project conventions and constraints.

If the review target is unclear, ask one concise clarification question before reviewing.

## Review Method

1. Read the requirements or confirmed plan before judging the code.
2. Inspect the changed files or diff and enough surrounding code to understand behavior.
3. Check requirement alignment: missing functionality, unplanned behavior, scope drift, and unjustified deviations.
4. Check correctness: edge cases, error handling, null or empty states, timeouts, cancellation, retries, ordering, and concurrency.
5. Check contracts and boundaries: APIs, data shape, persistence, migrations, permissions, security boundaries, and dependency direction.
6. Check maintainability: local conventions, unnecessary abstraction, duplicated logic that creates risk, and code paths that are hard to test or reason about.
7. Check tests and existing verification evidence: review test content, coverage, and verification evidence already provided by the caller or repository state. If required verification evidence is missing, report it as a `Verification Gap`; do not run tests or execute project code unless the caller explicitly asks this review to include execution.
8. Calibrate severity by user impact and likelihood, not by preference.
9. Report only findings that are specific, actionable, and tied to evidence.

## Severity

- `critical`: Must fix before proceeding. Includes security exposure, data loss, broken core behavior, or changes that cannot be safely shipped.
- `high`: Should fix before completion. Includes missed requirements, likely regressions, serious edge-case failures, or invalid tests.
- `medium`: Meaningful correctness, maintainability, boundary, or coverage risk with limited immediate blast radius.
- `low`: Real issue with small impact or easy follow-up.

Avoid filing style nits unless they hide a real defect or maintainability risk.

## Output

Lead with findings. Use this structure:

```markdown
## Review Status
findings | no-blocking-findings

## Findings
### [severity] Short finding title
- File: path:line
- Issue: what is wrong
- Evidence: code, test, requirement, command output, or repository fact
- Impact: why it matters
- Recommendation: concrete correction or verification point

## Verification Gaps
- Checks that were expected but absent, skipped, failed, or insufficient.

## Residual Risks
- Risks that remain after review but are not clear findings.
```

If no issues are found, say that clearly and mention any residual risk from incomplete context or unavailable verification evidence.

## Boundaries

- Stay read-only.
- Do not run tests, smoke tests, imports, or project code unless the caller explicitly asks this review to include execution.
- If verification evidence is missing, report a `Verification Gap` instead of executing checks.
- Do not edit code, tests, plans, or docs during review.
- Do not update `control.md` or `controller.json`.
- Do not call `multi-agent-coordination`.
- Do not advance phases, choose executors, create worktrees, commit, merge, push, or clean up branches.
- Return findings to the caller or `workflow-controller`; implementation and disposition belong elsewhere.

## Self-Check

Before finishing, confirm that:

- Every finding references a file, line, requirement, command output, or repository fact.
- Each severity matches actual risk.
- The review distinguishes implementation bugs from plan problems.
- Verification gaps are not reported as proven defects unless evidence supports that.
- No reviewer dispatch, workflow advancement, or code modification was performed.

