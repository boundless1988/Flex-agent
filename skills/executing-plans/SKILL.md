---
name: executing-plans
description: Use when an implementation agent is assigned a confirmed plan or work items and must execute them in scope, apply focused changes, run work-item verification, and return implementation evidence.
---

# Executing Plans

Implement a confirmed plan without changing the global workflow.

## Entry Conditions

Use this skill when:

- requirements and plan are confirmed;
- an isolated worktree has been prepared when repository changes are required;
- the current agent is assigned implementation work;
- the expected output is changed files plus verification evidence.

Do not use this skill to clarify requirements, write the plan, perform initial code review, or complete branch finishing.

## Boundary

This skill does not update `control.md`, call `multi-agent-coordination`, choose executors, create worktrees, switch to `subagent-driven-development`, advance to VERIFY, create commits, merge, push, rebase, clean branches, or call `finishing-a-development-branch`.

Return implementation results to `workflow-controller` or the caller.

## Inputs

Require:

- confirmed goal;
- confirmed plan or assigned work items;
- worktree path;
- scope and non-goals;
- verification expectations;
- known constraints or commands.

If any input is missing and cannot be inferred from the provided plan, stop and report the missing item.

## Execution Method

1. Read the full assigned plan or work item.
2. Review it against current repository context before editing.
3. Identify blockers, ambiguity, or plan/code mismatch.
4. If a blocker affects correctness or scope, stop and return it.
5. Implement one coherent work item at a time.
6. Keep edits limited to the confirmed scope.
7. Run the verification specified for that work item when available.
8. Record what changed and what evidence supports it.
9. Continue only while remaining within the confirmed plan.

Do not silently change architecture, requirements, public behavior, or scope. If the plan is wrong, return the issue instead of improvising a larger redesign.

## Use of Other Methods

- Use `test-driven-development` only when the controller, plan, user, or implementation context selected it for the work item.
- Use `systematic-debugging` when a failure has unclear root cause.
- Use `receiving-code-review` when handling review feedback during implementation.
- Use `verification-before-completion` before making completion or fixed claims.

This skill may use normal local tools for editing and checking code, but it does not dispatch phase-level agents or visible panes.

## Verification During Implementation

For each work item, use the narrowest useful check first:

- targeted test;
- type check for touched area;
- lint or static check;
- build;
- manual acceptance check;
- code inspection when no executable check exists.

Do not invent project commands. If the plan names a command, run that command unless it is unsafe or impossible, then report why.

If verification fails:

- report the exact command or check;
- include the important failure evidence;
- fix within the confirmed scope if the cause is clear;
- use `systematic-debugging` when the cause is unclear;
- return to the controller if fixing requires changed requirements, changed design, or expanded scope.

## Output

Return:

- work items completed;
- files or components changed;
- behavior changed;
- verification run and results;
- work items not completed and why;
- blockers, residual risks, or scope questions;
- recommended next step for the controller.

Do not claim the whole task is complete unless `verification-before-completion` evidence supports that claim and the controller has requested that status.

## Self-Review

Before returning, check:

- every edit maps to a confirmed work item;
- no unrelated refactor or cleanup was introduced;
- no workflow state was updated directly;
- no phase-level agent coordination was attempted;
- no commit or branch finishing action was taken;
- verification evidence is reported accurately;
- unresolved plan or scope issues are explicit.
