# Claude Code Host Reference

Use this reference only for host-native subagents inside `subagent-driven-development`.

## Invocation

- Use Claude Code's native task or subagent mechanism when it is available in the active session.
- Select the most appropriate available subagent type for the task, but do not treat subagent type names as Harness roles.
- Pass a complete task-local prompt with working directory, write permission boundary, relevant files, exact requirements, and expected report format.
- If the active Claude Code environment does not expose a native subagent mechanism, report that this skill is unavailable for the current host and continue with ordinary implementation in the parent agent.

## Context And Permissions

- Do not assume the subagent sees the parent session history.
- Keep each prompt scoped to one implementation sub-task.
- Keep writing subagents serial in a shared worktree.
- Use Claude Code's normal tool permission and approval behavior; do not bypass it with a background CLI process.

## Result Capture

Require the subagent to return:

- status: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`;
- changed or inspected files;
- commands or checks run and their results;
- unresolved concerns;
- a short implementation summary.

The parent implementation agent remains responsible for integrating results and returning a consolidated report to the caller.

## Prohibited Substitutes

- Do not use `multi-agent-coordination` for internal subagents.
- Do not create visible phase-level panes for internal subagent work.
- Do not let a Claude Code subagent update `control.md`, advance phases, or perform branch finishing.
