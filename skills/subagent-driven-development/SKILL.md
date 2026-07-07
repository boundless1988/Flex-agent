---
name: subagent-driven-development
description: Use when an implementation agent needs to split a confirmed implementation plan into internal host-native subagent tasks within the same execution context, while keeping results routed back to the implementation agent without advancing workflow phases.
---

# Subagent-Driven Development

Use host-native subagents inside the current implementation agent to execute parts of a confirmed plan with isolated task context. This is an implementation method, not a workflow controller, reviewer, verifier, branch finisher, or phase-level multi-agent dispatcher.

## Entry Conditions

Use this skill only when:

- A confirmed implementation plan or task list already exists.
- The caller has selected this method for implementation.
- Work is already happening in the correct task worktree or workspace.
- The work can be split into bounded sub-tasks with clear inputs and expected outputs.
- The current host exposes a native subagent mechanism.

Do not use this skill when:

- The work needs visible cross-host or phase-level agents; that belongs to `workflow-controller` through `multi-agent-coordination`.
- The plan is still unclear; return for clarification, `brainstorming`, or `writing-plans`.
- The task is tightly coupled enough that isolated sub-tasks would create merge or reasoning risk.
- The current host has no native subagent mechanism. Fall back to ordinary `executing-plans` behavior instead of emulating subagents with panes or new CLI sessions.

## Host References

Before dispatching an internal subagent, read the host reference for the active host:

- Codex: [references/hosts/codex.md](references/hosts/codex.md)
- Claude Code: [references/hosts/claude-code.md](references/hosts/claude-code.md)

Keep host-specific tool names, permissions, context inheritance behavior, and result capture details in those references. Do not copy those details into this public workflow.

## Method

1. Read the confirmed plan and identify the implementation boundary, non-goals, global constraints, and verification expectations.
2. Split work into serial sub-tasks that can be completed without two writers modifying the same worktree at the same time.
3. For each sub-task, prepare a compact brief containing:
   - the task goal;
   - exact requirements and constraints relevant to that task;
   - working directory or worktree path;
   - files or modules likely in scope;
   - dependencies on earlier sub-tasks;
   - expected report format;
   - whether the subagent may write files.
4. Dispatch one host-native implementation subagent at a time unless the sub-task is explicitly read-only.
5. Give the subagent only the task-local context it needs. Do not pass the whole session transcript or unrelated plan history.
6. Require the subagent to return:
   - status: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`;
   - files changed or inspected;
   - checks it ran and their results;
   - concerns, assumptions, or unresolved questions;
   - any follow-up needed from the implementation agent.
7. Read each result, decide whether the implementation agent can proceed, and resolve local integration conflicts before dispatching the next writing sub-task.
8. Keep a concise in-session progress record. If the caller provided a task-local scratch location, durable notes may be written there; do not assume fixed upstream directories.
9. Return the consolidated implementation result to the caller or `workflow-controller`.

## Handling Subagent Status

- `DONE`: Inspect the report, verify that the sub-task scope was respected, then continue to the next sub-task.
- `DONE_WITH_CONCERNS`: Read the concerns before continuing. If they affect correctness, scope, or plan validity, resolve them before more writes.
- `NEEDS_CONTEXT`: Provide missing context or reduce the task; redispatch only after changing the prompt or inputs.
- `BLOCKED`: Determine whether the blocker is missing context, task size, host limitation, or a plan problem. Return to the caller when the plan or scope must change.

Do not force repeated retries with the same prompt after a blocker. Change the task, context, model, or plan path before redispatching.

## Prompt Discipline

Internal subagent prompts should:

- describe one sub-task, not the whole project history;
- cite exact plan requirements and constraints relevant to that sub-task;
- name the working directory and write permissions;
- require focused checks for changed behavior;
- require a short final report with evidence;
- tell the subagent to stop and report `NEEDS_CONTEXT` or `BLOCKED` when requirements or approach are ambiguous.

Prompts should not:

- ask a subagent to decide the global workflow phase;
- ask a subagent to update `control.md` or task state;
- ask a subagent to call other Harness Skills;
- ask a subagent to commit, merge, push, rebase, delete, or clean up branches;
- ask a subagent to run broad verification gates owned by `verification-before-completion`;
- ask a subagent to perform formal `code-review`.

## Output

Return a concise implementation summary:

```markdown
## Implementation Summary
- Sub-tasks completed:
- Files changed:
- Checks run:
- Concerns or blockers:
- Scope deviations:
- Suggested next owner:
```

If the implementation did not complete, state the first blocking condition and the evidence. Do not mark workflow phases complete.

## Boundaries

- Do not call `multi-agent-coordination`.
- Do not create visible phase-level panes or external CLI agents.
- Do not modify `control.md` or `controller.json`.
- Do not advance UNDERSTAND, PREPARE, IMPLEMENT, VERIFY, or COMPLETE.
- Do not directly call `code-review`, `verification-before-completion`, or `finishing-a-development-branch`.
- Do not create intermediate, WIP, or frequent commits as part of sub-task execution.
- Do not introduce host-specific commands into this public `SKILL.md`.
- Return all results to the implementation agent, which returns to the caller or `workflow-controller`.

## Self-Check

Before finishing, confirm that:

- All sub-tasks stayed inside the confirmed plan.
- Only one writing subagent operated in the worktree at a time.
- Host-specific details stayed in host references.
- No workflow state was updated by this skill.
- The final response gives enough evidence for the caller to decide the next workflow step.
