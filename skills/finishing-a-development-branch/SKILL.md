---
name: finishing-a-development-branch
description: Use after implementation verification has passed and the user or workflow-controller needs structured branch disposition options such as keeping the branch, local merge, push or PR, rebase, cleanup, or discard, with explicit confirmation for all remote or destructive actions.
---

# Finishing A Development Branch

Guide the final handling of a development branch after implementation verification. The default outcome is to preserve the branch and worktree. Merge, push, rebase, deletion, cleanup, and discard require explicit user selection.

## Entry Conditions

Use this skill when:

- Implementation work is complete.
- Verification evidence is available and passed.
- The task branch or worktree needs a disposition decision.
- The caller or `workflow-controller` asks for branch finishing options.

Do not use this skill to:

- Perform implementation.
- Replace `verification-before-completion`.
- Create intermediate, WIP, or frequent commits.
- Automatically merge, push, rebase, delete, or clean up without explicit user choice.

If verification evidence is missing or failing, stop and return to the caller. Do not offer merge, push, or cleanup options as if the work were complete.

## Inputs

Collect or confirm:

- Repository root and current worktree path.
- Current branch name, detached state, and base branch if known.
- Base commit and final local commit evidence, if the workflow already created it.
- Verification commands and results.
- Whether a remote exists and whether PR creation is available.
- Whether the worktree is Harness-managed, externally managed, or unknown.

If a required fact is unavailable, ask only for that fact or return a blocked result.

## Completion Commit Boundary

The Harness flow creates one local completion commit after VERIFY passes and before COMPLETE. This skill must not turn that into frequent commits or task-by-task commits.

- If the completion commit already exists, use it as branch disposition input.
- If verified changes remain uncommitted and the caller explicitly instructs this skill to create the completion commit, create only one local commit for the verified final state.
- If there is no explicit instruction to commit, stop and report that the completion commit gate is unresolved.

Do not create WIP commits, checkpoint commits, or per-sub-task commits.

## Default Option

If the user has not selected an action, present options and default to preserving the current branch and worktree.

Use this menu shape, adapted to known repository facts:

```markdown
Implementation is verified. Choose branch handling:

1. Keep branch and worktree as-is (default)
2. Merge locally into <base-branch>
3. Push branch or create PR
4. Rebase or update branch
5. Delete branch and/or cleanup worktree
6. Discard this work
```

Do not execute options 2-6 without explicit user selection. For ambiguous replies, ask a concise clarification question.

## Action Rules

### 1. Keep Branch And Worktree

Report the branch, worktree path, final commit if known, and verification evidence. Do not modify Git state.

### 2. Merge Locally

Before merging:

- Confirm target base branch.
- Confirm the user selected local merge.
- Ensure verification evidence exists for the feature branch.

After merging:

- Verify the merged result using the verification command selected by the caller or project.
- Do not delete the feature branch or worktree unless the user also explicitly chose cleanup.

### 3. Push Branch Or Create PR

Before pushing or creating a PR:

- Confirm remote and target branch.
- Confirm the user explicitly selected push or PR creation.
- State any command that will affect the remote before running it.

Do not clean up the local worktree after push or PR creation unless the user separately chooses cleanup.

### 4. Rebase Or Update Branch

Before rebasing:

- Confirm the target base branch.
- Confirm whether the rebase rewrites only local task history.
- Treat shared-history rebase as high risk and require explicit confirmation.

Run verification again after rebase. Do not push rewritten history unless explicitly requested.

### 5. Delete Branch And/Or Cleanup Worktree

Before deletion or cleanup:

- Confirm exact branch name.
- Confirm exact worktree path.
- Confirm whether the worktree is safe for this Harness to remove.
- Require explicit user confirmation for each destructive operation.

Do not remove a worktree whose ownership is unknown, whose path is outside the expected task worktree, or whose branch still needs to be preserved.

### 6. Discard This Work

Discard is destructive. Before any discard:

- Show the branch, worktree path, and commits or changes that would be lost.
- Require a clear explicit confirmation from the user.
- Re-check the target path and branch immediately before deletion.

If the confirmation is not exact enough, stop.

## Safety Rules

- Preserve branch and worktree by default.
- Do not run remote operations without explicit user selection.
- Do not run merge, rebase, delete, cleanup, or discard as an implied next step.
- Do not delete a branch before confirming any selected merge or preservation path succeeded.
- Do not remove a worktree from inside that same worktree.
- Do not remove worktrees with unknown ownership.
- Do not force-push unless the user explicitly requests force-push and accepts the risk.
- Do not proceed when verification evidence is missing or stale.

## Output

Return:

```markdown
## Branch Finishing Result
- Selected action:
- Branch:
- Worktree:
- Base branch:
- Final commit:
- Verification evidence:
- Git operations performed:
- Preserved resources:
- Follow-up needed:
```

For the default keep option, `Git operations performed` should be `none`.

## Boundaries

- Do not update `control.md` or `controller.json`.
- Do not call `multi-agent-coordination`.
- Do not decide VERIFY or COMPLETE phase transitions.
- Do not run broad new verification that was not selected by the caller or project.
- Do not introduce frequent commits or intermediate commits.
- Return the result to the caller or `workflow-controller` for state updates and final messaging.

## Self-Check

Before finishing, confirm that:

- Verification evidence exists and was not invented.
- The branch/worktree default remains preserve.
- Every remote or destructive operation was explicitly selected.
- Any cleanup target path and branch name were checked immediately before action.
- The output states exactly what was changed and what was preserved.
