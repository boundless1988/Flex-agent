---
name: using-git-worktrees
description: Use during PREPARE when a repository modification task needs an isolated Git worktree, task branch, base commit record, existing-baseline check, or safe handoff of worktree details.
---

# Using Git Worktrees

Create, verify, or adopt an isolated worktree for repository modification work.

## Entry Conditions

Use this skill in PREPARE for repository modification tasks before the first actual file edit.

Use it to:

- detect whether the current checkout is already an isolated linked worktree;
- create or adopt the task worktree;
- create or identify the task branch;
- record worktree path, branch, and base commit;
- run baseline commands that are already known from project context;
- report dirty workspace, existing worktree, or baseline failures.

Do not use this skill for ordinary read-only tasks.

## Boundary

This skill does not implement the task, update `control.md`, call `multi-agent-coordination`, commit, merge, push, rebase, delete branches, delete worktrees, or clean up after completion.

Return the prepared environment details and any blockers to `workflow-controller`.

## Inputs

Require:

- project root;
- task identifier or branch naming input;
- desired worktree root or project convention, if already known;
- confirmed baseline commands, if any;
- current task state destination handled by the controller.

If worktree placement, branch name, or base branch cannot be inferred safely, return the missing item instead of guessing.

## Detect Existing Context

Before creating anything:

1. Confirm the project is a Git repository.
2. Determine the repository root.
3. Determine whether the current checkout is a linked worktree.
4. Guard against mistaking a submodule for a linked worktree.
5. Identify the current branch or detached state.
6. Check for uncommitted local changes in the source checkout before using it as the base.

If already in the correct task worktree, adopt it and report its path, branch, and base commit.

If in an unrelated worktree or dirty checkout, pause and report the conflict to the controller.

## Create or Adopt Worktree

When creating a worktree:

1. choose a safe worktree path using explicit controller or user input first;
2. avoid placing worktrees inside tracked source paths;
3. if using a project-local worktree directory, verify it is ignored before creating anything there;
4. create a task branch from the intended base;
5. record the base commit before implementation starts.

If the selected project-local directory is not ignored, do not edit `.gitignore` from this skill unless the controller explicitly instructs that as part of PREPARE. Report the issue and wait for direction or choose a safe external worktree root if the controller provides one.

If the worktree already exists:

- verify it points to the expected repository;
- verify branch and base assumptions;
- check whether it contains unrelated changes;
- adopt only if safe.

## Baseline Verification

Run only commands that are already explicitly known from repository context, controller input, or the confirmed plan.

Do not invent commands such as `npm test`, `pytest`, `cargo test`, or build commands from file names alone.

For each baseline command:

- run it from the worktree root;
- capture command, exit result, and important output;
- if it fails, stop and return the failure to the controller;
- do not proceed to implementation until the controller or user decides how to handle the failed baseline.

If no baseline command is known, report that no baseline was run.

## Output

Return:

- repository root;
- worktree path;
- branch name;
- base commit;
- whether the worktree was created or adopted;
- source checkout cleanliness;
- baseline commands run and results;
- blockers or decisions needed.

Do not write task state directly; the controller records these details.

## Self-Review

Before returning, check:

- worktree exists and is separate from the source checkout;
- branch and base commit are known;
- no implementation edits were made;
- no commit, merge, push, rebase, delete, or cleanup action was taken;
- only known baseline commands were run;
- any dirty state or baseline failure was reported.
