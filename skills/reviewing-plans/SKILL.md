---
name: reviewing-plans
description: Use when Codex must independently review a confirmed design, implementation plan, migration plan, or feature-slice plan before implementation, checking assumptions, scope, sequencing, coupling, test gaps, and residual risk with evidence-based findings.
---

# Reviewing Plans

Review an existing plan as a read-only independent reviewer. The goal is to decide whether the plan is specific, bounded, and safe enough for implementation, not to rewrite it during review.

## Entry Conditions

Use this skill when:

- A design, implementation plan, migration plan, or feature-slice plan already exists.
- The user or `workflow-controller` requests an independent plan review.
- The plan affects architecture, public contracts, state, data, sequencing, concurrency, migration, or user-visible behavior.

Do not use this skill for:

- Writing the plan. Use `writing-plans`.
- Reviewing implemented code. Use `code-review`.
- Implementing fixes or editing the plan unless the caller explicitly changes the task.

## Inputs

Gather only the context needed to judge the plan:

- The goal, requirements, non-goals, and success criteria.
- The plan text or plan file.
- Relevant source-of-truth docs, code facts, tests, schemas, APIs, or state machines.
- Known constraints from the user, repository, or Harness design.
- Expected verification and completion criteria.

If the target plan or review scope is unclear, ask one concise clarification question.

## Review Method

1. Identify the plan's claimed goal, scope, non-goals, success signals, and implementation boundary.
2. List the key assumptions the plan depends on.
3. Check each assumption against concrete evidence from the plan, repository, tests, docs, schemas, or current behavior.
4. Review architecture boundaries: ownership, dependency direction, public contracts, storage boundaries, external protocols, and leakage of implementation details.
5. Review coupling: shared mutable state, cross-layer changes, broad contracts, bidirectional dependencies, and slices that force unrelated work to move together.
6. Review execution semantics: state transitions, lifecycle, cancellation, retry, idempotency, concurrency, recovery, ordering, durability, and partial failure.
7. Review sequencing: slice size, dependency order, migration order, rollback safety, and whether later work leaks into the current slice.
8. Review validation: whether planned tests and checks prove the target behavior, cover failure paths, and preserve regressions.
9. Separate blockers, deferrable risks, and questions that need more evidence.

Prefer project-local conventions and existing architecture over abstract best-practice claims. Do not report style preferences or low-value cleanup as findings.

## Finding Rules

Only report material findings that are evidence-based and actionable. Each finding must answer:

- What can go wrong?
- Why is the plan, assumption, boundary, or sequence fragile?
- What is the likely impact?
- What concrete change would reduce the risk?
- What evidence supports the finding?

Use these severity levels:

- `critical`: The plan is likely to cause data loss, security exposure, broken core behavior, or irreversible state damage.
- `high`: The plan can plausibly fail implementation, violate confirmed requirements, or create costly rework.
- `medium`: The plan leaves a meaningful gap in boundary, sequencing, test coverage, or maintainability.
- `low`: The issue is real but limited in blast radius or easy to correct.

Put plausible but unproven concerns under open questions or residual risks instead of presenting them as findings.

## Output

Return a concise review with this structure:

```markdown
## Verdict
pass | pass-with-concerns | changes-required

## Findings
### [severity] Short finding title
- Location: plan section, requirement, code fact, or source reference
- Issue: what is wrong or missing
- Evidence: direct plan text, code fact, test fact, doc, or constraint
- Impact: why it matters
- Recommendation: concrete correction or verification point

## Open Questions
- Questions that block confidence and cannot be answered from available context.

## Residual Risks
- Accepted or deferrable risks that should remain visible.
```

If there are no findings, say that directly and still list any residual risks or verification gaps found during review.

## Boundaries

- Stay read-only unless the caller explicitly requests plan edits as a new task.
- Do not modify source code.
- Do not update `control.md` or `controller.json`.
- Do not call `multi-agent-coordination`.
- Do not advance phases, choose executors, create worktrees, commit, merge, push, or clean up branches.
- Return the review to the caller or `workflow-controller` for decision and next-step handling.

## Self-Check

Before finishing, confirm that:

- Every finding has specific evidence.
- No finding is only a style preference or unsupported speculation.
- The verdict follows from the findings.
- Suggested corrections stay inside the reviewed plan's scope.
- Any workflow, routing, or state decision is left to `workflow-controller`.
