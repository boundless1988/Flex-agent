---
name: brainstorming
description: Use when requirements, expected behavior, architecture, or technical approach are not sufficiently resolved to form a complete Goal / Changes / Verification execution summary. Clarifies intent and produces an approved design before implementation.
---

# Brainstorming

Turn an unresolved request into a clear, bounded, and approved design.

## Entry Conditions

Use this skill only when at least one of the following remains unresolved:

- the goal or success criteria;
- the required behavior;
- the scope or non-goals;
- a material technical decision;
- the expected verification approach.

Do not use this skill for:

- ordinary read-only questions;
- repository changes whose Goal, Changes, and Verification are already complete;
- implementation planning;
- code modification.

## Hard Boundary

Do not modify repository files, create a worktree, or start implementation while using this skill.

Do not update task workflow state directly. Return the result to `workflow-controller`.

## Process

1. Review available project and conversation context before asking questions.
2. Identify the smallest set of unresolved decisions.
3. Ask one focused question at a time.
4. Do not ask for information already present in the available context.
5. When multiple reasonable approaches exist, present two or three options with trade-offs and a recommendation.
6. When only one approach is materially reasonable, explain it directly rather than inventing alternatives.
7. Present the design at a level proportional to the task.
8. Obtain explicit user confirmation for the final design.

## Design Coverage

Cover only the areas relevant to the task:

- goals and non-goals;
- observable behavior;
- affected components;
- interfaces and data flow;
- error handling and edge cases;
- compatibility or migration concerns;
- testing and verification;
- material risks and trade-offs.

Avoid unrelated refactoring or speculative features.

## Scope Control

If the request contains multiple independent subsystems:

1. identify the independent parts;
2. describe their dependencies;
3. recommend an implementation order;
4. limit the current design to one coherent scope unless the user confirms otherwise.

## Output

Return a concise design summary containing:

- Goal
- Scope and non-goals
- Confirmed decisions
- Proposed approach
- Verification expectations
- Remaining unresolved items, if any

Persist a design document only when the Controller or user requires one.

When persisted, use the current task directory, normally:

`.harness/tasks/<task-id>/design.md`

Do not commit the design document.

Do not invoke `writing-plans` directly. The Controller decides whether to:

- request further clarification;
- invoke `reviewing-plans`;
- invoke `writing-plans`;
- wait for user confirmation.

## Self-Review

Before returning the result, check for:

- placeholders or incomplete decisions;
- contradictory statements;
- ambiguous requirements;
- unnecessary scope;
- missing success criteria;
- assumptions presented as confirmed facts.

Fix clear issues before returning. Report unresolved issues explicitly.

## Principles

- Use existing context first.
- Ask one question per turn.
- Prefer precise choices when they help.
- Keep simple designs short.
- Apply YAGNI.
- Separate confirmed decisions from assumptions.
- Do not perform implementation work.