---
name: writing-plans
description: Use after requirements and design are sufficiently confirmed, when implementation needs an explicit sequence of repository changes and verification steps.
---

# Writing Implementation Plans

Convert an approved design into a concrete, ordered implementation plan.

## Entry Conditions

Use this skill only when:

- the Goal, Changes, and Verification summary is complete;
- material requirements and technical decisions are resolved;
- implementation has not started;
- a written plan is useful because the task is not safely executable from a short summary alone.

Do not use this skill for:

- unresolved requirements or architecture;
- ordinary read-only questions;
- direct implementation;
- code review or verification.

## Hard Boundary

Do not modify repository files.

Do not create or switch worktrees.

Do not commit, merge, push, rebase, or clean branches.

Do not choose or invoke the implementation executor. Return the plan to `workflow-controller`.

## Planning Method

1. Review the approved design and relevant repository context.
2. Identify the exact components and files likely to change.
3. Break implementation into dependency-ordered work items.
4. Keep each work item independently understandable and verifiable.
5. Include necessary tests, documentation, configuration, or migration work.
6. Distinguish required work from optional improvements.
7. Avoid speculative refactoring and unrelated cleanup.
8. State assumptions and unresolved risks explicitly.

## Plan Structure

The plan should contain:

### Goal

A concise statement of the intended outcome.

### Preconditions

Only conditions that must be true before implementation begins.

### Work Items

For each work item include:

- purpose;
- expected files or components;
- concrete changes;
- dependencies on earlier work;
- validation for that work item;
- relevant edge cases or failure handling.

Use ordered items when dependencies exist.

Mark work items as parallelizable only when they:

- have no ordering dependency;
- do not require concurrent writes to the same worktree;
- can return independently reviewable results.

### Verification Plan

List the actual evidence required before completion, such as:

- targeted tests;
- existing project test commands;
- build or type-check commands;
- linting or static analysis;
- manual acceptance checks;
- compatibility or migration validation.

Do not invent project commands. Use only commands confirmed from repository context or explicitly mark them as unresolved.

### Risks and Rollback

Include only material risks, migration concerns, or rollback needs.

### Completion Criteria

State the conditions that must be true before the task can enter completion.

## Persistence

Persist the plan only when required by the Controller or user.

When persisted, use the current task directory, normally:

`.harness/tasks/<task-id>/plan.md`

Do not commit the plan file.

## Relationship to Other Skills

- Unresolved requirements return to `brainstorming`.
- A complex or high-impact plan may be sent to `reviewing-plans`.
- The Controller decides whether implementation uses `executing-plans` or `subagent-driven-development`.
- TDD is included only when the Controller or implementation context selects `test-driven-development`.

## Output

Return:

- the ordered implementation plan;
- dependencies and parallelizable items;
- verification requirements;
- assumptions and unresolved risks.

Do not advance task state directly.

## Self-Review

Before returning, verify that:

- every work item contributes to the confirmed goal;
- file and component references are grounded in repository context;
- dependencies are explicit;
- verification covers observable behavior;
- no implementation action is embedded in the plan;
- no intermediate commit is required;
- no unresolved design decision is disguised as an implementation step.