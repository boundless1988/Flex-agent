# Codex Host Reference

Use this reference only for host-native subagents inside `subagent-driven-development`.

## Invocation

- Use the current Codex host's native subagent or task-delegation facility only when it is exposed in the session.
- Pass the subagent an explicit prompt, working directory, write permission boundary, required files or paths, and expected report format.
- Do not rely on the subagent inheriting the parent session transcript. Include the task-local facts it needs.
- If no native Codex subagent facility is available, report that this skill is unavailable for the current host and continue with ordinary implementation in the parent agent.

## Context And Permissions

- Keep the subagent in the same task worktree or workspace selected by the caller.
- State whether the subagent may edit files or must stay read-only.
- Keep writing subagents serial in a shared worktree.
- Use Codex's normal approval and sandbox behavior; do not bypass it through shell-launched Codex processes.

## Result Capture

Require the subagent to return:

- status: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`;
- changed or inspected files;
- commands or checks run and their results;
- unresolved concerns;
- a short implementation summary.

The parent implementation agent must inspect the returned result and decide whether to continue, redispatch with more context, or return to the caller.

## Prohibited Substitutes

- Do not use `multi-agent-coordination` for internal subagents.
- Do not open visible CLI panes as a replacement for host-native subagents.
- Do not launch a separate Codex CLI process from shell to simulate a subagent.
- Do not let a Codex subagent update `control.md`, advance phases, or perform branch finishing.
