---
name: test-driven-development
description: Use when the controller, implementation context, plan, or user explicitly selects test-first development for a feature, bug fix, refactor, behavior change, or regression fix.
---

# Test-Driven Development

Use test-first development as an optional implementation method when it has been selected for the current work.

## Entry Conditions

Use this skill only when one of these is true:

- `workflow-controller` selects TDD for the current work;
- the confirmed plan requires TDD for a specific work item;
- the implementation context chooses TDD for a suitable change;
- the user explicitly asks for TDD.

Do not use this skill as a global gate for all repository changes. Do not treat non-use of TDD as failure unless TDD was selected for that specific work.

## Boundary

This skill does not advance workflow phases, update `control.md`, call `multi-agent-coordination`, create commits, or decide task completion.

Return implementation and verification evidence to the current implementation context or `workflow-controller`.

## Method

For each selected behavior:

1. Write one minimal test that describes the desired behavior.
2. Run the focused test and confirm it fails for the expected reason.
3. Write the smallest production change that can make the test pass.
4. Run the focused test and confirm it passes.
5. Refactor only after the test is green.
6. Re-run the relevant tests after refactoring.
7. Repeat for the next behavior.

If the test passes before implementation, the behavior already exists or the test is wrong. Re-check the test before changing production code.

If the test errors for setup, syntax, or fixture reasons, fix the test setup until it fails for the expected missing behavior.

## Good Tests

Prefer tests that:

- name one observable behavior;
- exercise real production code;
- use mocks only at external or slow boundaries;
- verify behavior rather than implementation details;
- include important edge cases and error paths;
- can be run as a focused command.

Split tests whose names contain multiple independent behaviors.

## Minimal Implementation

During the green step:

- implement only what the failing test requires;
- avoid unrelated cleanup;
- avoid speculative options, abstractions, or configuration;
- keep public behavior aligned with the confirmed requirement.

After the test passes, refactor names, duplication, and structure while keeping tests green.

## Testing Anti-Patterns

Avoid:

- testing that a mock exists instead of testing real behavior;
- adding production methods used only by tests;
- mocking a high-level method without understanding side effects the test needs;
- creating partial mocks that omit fields downstream code may consume;
- writing tests only after implementation and treating that as TDD.

When mocks become larger than the behavior under test, reconsider whether an integration-style test with real components is clearer.

## Bug Fix Pattern

For a bug:

1. Write a regression test that reproduces the original symptom.
2. Confirm the test fails before the fix.
3. Fix the root cause.
4. Confirm the regression test passes.
5. Run adjacent tests needed to catch regressions.

If the root cause is unclear, use `systematic-debugging` before guessing at a fix.

## Verification

Before reporting the TDD work item complete, provide:

- test file or scenario added;
- focused command used to verify red;
- focused command used to verify green;
- broader command, if required by the plan or controller;
- any coverage gaps or tests not run.

Use `verification-before-completion` before claiming the overall task is complete.

## Self-Review

Before returning, check:

- TDD was explicitly selected for this work;
- every new behavior has a test;
- each test was observed failing for the expected reason before implementation;
- implementation stayed minimal;
- mocks test behavior, not mock existence;
- no unrelated workflow state or Git action was performed.
