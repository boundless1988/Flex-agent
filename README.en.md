# Agent Harness

Agent Harness is a local development coordination framework for Codex, Claude Code, and other agents. It coordinates repository work through explicit workflows, reusable skills, Git worktrees, and visible CLI executor panes.

Design goals:

- No background service.
- No automatic pane or CLI lifecycle manager.
- No automatic merge, push, rebase, or cleanup.
- Repository modification tasks must use isolated Git worktrees.
- Task state is recorded in `.harness/tasks/<task-id>/control.md`.
- Visible executor panes are prepared manually, and the harness only uses existing channels.

---

## Directory Layout

```text
.agent-harness/
  config/
    executors.yaml
    routing.yaml
  integrations/
    claude-code/
      install-skills.ps1
      start-claude.ps1
  skills/
    workflow-controller/
    multi-agent-coordination/
    code-review/
    verification-before-completion/
    ...
  README.md
  README.en.md
```

Common external locations:

```text
%USERPROFILE%\.codex\AGENTS.md
%USERPROFILE%\.agents\skills
%USERPROFILE%\.claude\skills
```

---

## Install / Import

Place this repository at:

```text
%USERPROFILE%\.agent-harness
```

Then run the Codex rules and skills integration scripts to copy or link Harness rules and skills into Codex-readable locations. Then run the Claude Code skills integration script to link the same Harness skills into the Claude Code-readable location.

```powershell
powershell -ExecutionPolicy Bypass -File .\integrations\codex\sync-rules.ps1
powershell -ExecutionPolicy Bypass -File .\integrations\codex\install-skills.ps1
powershell -ExecutionPolicy Bypass -File .\integrations\claude-code\install-skills.ps1
```

After syncing, check a skill hash if needed:

```powershell
Get-FileHash "$env:USERPROFILE\.agent-harness\skills\code-review\SKILL.md" -Algorithm SHA256
Get-FileHash "$env:USERPROFILE\.agents\skills\code-review\SKILL.md" -Algorithm SHA256
Get-FileHash "$env:USERPROFILE\.claude\skills\code-review\SKILL.md" -Algorithm SHA256
```

Matching hashes mean the skill is integrated.

---

## Usage

### Enter DEVELOPER mode

In a new Codex app thread, enter:

```text
进入 DEVELOPER 模式。
```

After confirmation, send the repository modification task.

Normal chat, read-only questions, and non-development tasks do not require this mode.

### Task State

Harness-managed tasks create state files in the target repository:

```text
<repo>\.harness\tasks\<task-id>\control.md
<repo>\.harness\tasks\<task-id>\controller.json
```

`control.md` is the task state source of truth. It records phases, plans, worktrees, executor outputs, verification evidence, and completion commits.

---

## Workflow

Default development workflow:

```text
UNDERSTAND -> PREPARE -> IMPLEMENT -> VERIFY -> COMPLETE
```

Default rules:

- All repository modifications must be made in an isolated worktree.
- VERIFY must pass before COMPLETE.
- COMPLETE creates one local completion commit.
- By default, the harness does not merge, push, rebase, delete branches, or clean worktrees.

---

## Executors and Routing

Executor definitions:

```text
config/executors.yaml
```

Routing configuration:

```text
config/routing.yaml
```

Common roles:

```text
executing-plans                 -> claude-deepseek-1
systematic-debugging            -> claude-deepseek-1
code-review                     -> claude-deepseek-2
verification-before-completion  -> claude-mimo-2
```

For visible CLI executors, the stable identity is the pane title, for example:

```text
claude-deepseek-2
```

not the pane index.

---

## Recover visible executors after restart

PSMux/tmux panes do not survive machine restart. After restart, recreate only the executors needed for the current task.

Minimal review executor:

```powershell
$tmux = "D:\psmux\tmux.exe"

& $tmux new-session -d -s agent-harness -n claude-review powershell.exe
Start-Sleep -Milliseconds 500

& $tmux select-pane `
  -t "agent-harness:claude-review.0" `
  -T "claude-deepseek-2"
```

Start Claude DeepSeek in the pane:

```powershell
$tmux = "D:\psmux\tmux.exe"
$pane = "agent-harness:claude-review.0"
$launcher = "$env:USERPROFILE\.agent-harness\integrations\claude-code\start-claude.ps1"
$worktree = "<TARGET_WORKTREE_PATH>"

$command = "& '$launcher' -Provider deepseek -WorkingDirectory '$worktree'"

& $tmux send-keys -t $pane C-u
& $tmux send-keys -t $pane -l $command
& $tmux send-keys -t $pane Enter
```

Check panes:

```powershell
& $tmux list-panes -a `
  -F '#{session_name}:#{window_name}.#{pane_index} | #{pane_title} | #{pane_current_command} | #{pane_current_path}'
```

---

## Claude Code Provider Launcher

Claude Code launcher:

```text
integrations/claude-code/start-claude.ps1
```

It:

- Sets DeepSeek / MiMo provider environment variables.
- Switches to the target working directory.
- Starts Claude Code.
- Restores the environment after exit.

API keys should be stored in Windows user environment variables:

```text
DEEPSEEK_API_KEY
MIMO_API_KEY
```

Do not commit API keys or tokens.

---

## code-review read-only policy

`code-review` is an inspection skill, not a verification skill.

Allowed by default:

- Reading files
- Inspecting diffs
- Inspecting Git metadata
- Reading existing verification evidence

Not allowed by default:

- Running tests
- Running smoke tests
- Importing project code
- Executing project code
- Running commands that may generate cache files or modify the workspace

If verification evidence is insufficient, report `Verification Gap` instead of running tests.

---

---

## Memory

Memory is an experience ledger. It is not task state and is not automatically injected into runtime context.

Locations:

```text
Global: %USERPROFILE%\.agent-harness\memory.md
Project: <project>\.harness\memory.md
```

Entry format:

```markdown
## YYYY-MM-DD — Title

Experience content

状态：recorded | promoted | discarded
```

Manual record:

```powershell
powershell -ExecutionPolicy Bypass `
  -File "$env:USERPROFILE\.agent-harness\integrations\memory\record-memory.ps1" `
  -Scope global `
  -Source manual `
  -Title "<title>" `
  -Content "<content>"
```

Project-scoped record:

```powershell
powershell -ExecutionPolicy Bypass `
  -File "$env:USERPROFILE\.agent-harness\integrations\memory\record-memory.ps1" `
  -Scope project `
  -ProjectPath "<project>" `
  -Source manual `
  -Title "<title>" `
  -Content "<content>"
```

Auto recording is triggered as needed by the Controller after a Harness-managed phase-level Agent call finishes and capture is complete:

```powershell
-Source auto
```

Memory does not take effect automatically. Promotion into general rules, project constraints, skills, or host configuration is manual.

## Cleanup policy

Cleanup is manual.

Before cleanup, confirm:

- Work is committed or no longer needed.
- No controller depends on that state.
- The user explicitly requested cleanup.

Useful checks:

```powershell
git worktree list
git status --short --branch
D:\psmux\tmux.exe list-sessions
D:\psmux\tmux.exe list-panes -a
```

---

## Safety rules

Do not commit:

- API keys
- tokens
- provider credentials
- logs containing secrets
- temporary worktrees
- `.pytest_cache`
- `__pycache__`
- local session state

Keep credentials in local environment variables.
