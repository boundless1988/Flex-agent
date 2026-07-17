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
    codex/
      install-skills.ps1
      start-codex.ps1
      sync-rules.ps1
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

This section describes the full executor, routing, and local credential design. Executor names,
models, and routes in the examples demonstrate different scenarios; they are not mandatory
defaults. The effective registry and default routes are always `config/executors.yaml` and
`config/routing.yaml`, respectively.

### Enter DEVELOPER mode

In a new Codex app thread, enter:

```text
进入 DEVELOPER 模式。
```

After confirmation, send the repository modification task. Normal chat, read-only questions,
and non-development tasks do not require this mode.

### Task State and Workflow

Harness-managed tasks create state files in the target repository:

```text
<repo>\.harness\tasks\<task-id>\control.md
<repo>\.harness\tasks\<task-id>\controller.json
```

`control.md` is the task state source of truth. It records phases, plans, worktrees, executor
outputs, verification evidence, and completion commits. The default development workflow is:

```text
UNDERSTAND -> PREPARE -> IMPLEMENT -> VERIFY -> COMPLETE
```

Default rules:

- All repository modifications must be made in an isolated worktree.
- VERIFY must pass before COMPLETE.
- COMPLETE creates one local completion commit.
- By default, the Harness does not merge, push, rebase, delete branches, or clean worktrees.

### Executor registry model

`config/executors.yaml` is the executor registry. Each executor represents an independent CLI
process, pane, and context. To run multiple instances of the same executor type concurrently,
give them different IDs such as `review-1` and `review-2`; two panes must not share one identity.

Supported configuration fields:

| Field | Meaning |
| --- | --- |
| `host` | Required; the current design includes `codex-cli` and `claude-code`. |
| `model` | Required; records the model the executor is expected to use. |
| `provider` | Optional; identifies a third-party provider such as `mimo` or `deepseek`. |
| `reasoning_effort` | Optional; used by the corresponding launcher/CLI when the model supports it. |

The registry declares executors but does not create processes. A visible executor must also be
started with the matching launcher, and its pane title must equal the executor ID.

### Configure and start a Codex executor

A native Codex/OpenAI model does not need `provider`:

```yaml
executors:
  codex-planning-1:
    host: codex-cli
    model: "<codex-model-id>"
    reasoning_effort: "<supported-effort>"
```

Using Codex through an already adapted third-party provider requires both `provider` and
`model`:

```yaml
executors:
  codex-mimo-build-1:
    host: codex-cli
    provider: mimo
    model: "<mimo-model-id>"
```

`integrations/codex/start-codex.ps1` reads the registry by executor ID and passes `model` and the
optional `reasoning_effort` to Codex CLI. The current launcher implements native Codex/OpenAI and
the MiMo Responses-compatible provider. For MiMo it disables the unsupported `web_search` and
`image_generation` features. Other providers cannot be enabled by adding YAML alone; their
endpoint, authentication, and wire API configuration must first be implemented in the launcher.
DeepSeek is not connected through this Codex launcher.

Run a DryRun after changing configuration:

```powershell
& .\integrations\codex\start-codex.ps1 `
  -Executor codex-planning-1 `
  -WorkingDirectory "<TARGET_WORKTREE_PATH>" `
  -DryRun |
  Format-List
```

After confirming the model, provider, reasoning effort, and arguments, start the interactive
executor:

```powershell
& .\integrations\codex\start-codex.ps1 `
  -Executor codex-planning-1 `
  -WorkingDirectory "<TARGET_WORKTREE_PATH>"
```

If the service reports that a model needs a newer version, check `codex --version` and upgrade
using the installation method for that Codex CLI. Restart the CLI process after changing an
executor; a running process does not hot-reload the YAML file.

### Configure and start a Claude Code executor

By design, a Claude Code executor may use Claude Code's native authentication or one of the
provider launch paths supplied by this project for DeepSeek or MiMo:

```yaml
executors:
  claude-native-review-1:
    host: claude-code
    model: "<claude-model-id>"

  claude-deepseek-review-1:
    host: claude-code
    provider: deepseek
    model: "<deepseek-model-id>"

  claude-mimo-review-1:
    host: claude-code
    provider: mimo
    model: "<mimo-model-id>"
```

A native Claude Code executor uses Claude Code's own login and model configuration and starts
`claude` directly in the target worktree. The retained
`integrations/claude-code/start-claude.ps1` currently accepts only `deepseek` and `mimo`:

```powershell
& .\integrations\claude-code\start-claude.ps1 `
  -Provider deepseek `
  -WorkingDirectory "<TARGET_WORKTREE_PATH>"
```

```powershell
& .\integrations\claude-code\start-claude.ps1 `
  -Provider mimo `
  -WorkingDirectory "<TARGET_WORKTREE_PATH>"
```

Important: the current Claude launcher does not read `executors.yaml` by executor ID. Its actual
provider models come from the `ANTHROPIC_MODEL`, default-model, and subagent-model environment
variables defined in the script. When changing a Claude/DeepSeek/MiMo model, update both the
registry and launcher so the declared and runtime values remain aligned. Another Claude provider
requires a new launcher branch or that provider's native Claude Code configuration.

`start-claude.ps1` has no DryRun. When registering a Claude executor, check `claude --version`,
the API key, and the target working directory, then perform one real smoke test.

### Configure routing

`config/routing.yaml` assigns default executors only to stage-level Agent Skills. A route value is
an executor ID and does not depend on whether that executor uses Codex or Claude Code. For
example, a configuration using both hosts could be:

```yaml
routing:
  defaults:
    brainstorming: codex-planning-1
    writing-plans: codex-planning-1
    reviewing-plans: codex-planning-1
    executing-plans: codex-implementation-1
    systematic-debugging: codex-debug-1
    code-review: claude-deepseek-review-1
    verification-before-completion: codex-verification-1
    writing-skills: codex-planning-1

  parallel_pool:
    - codex-planning-1
    - codex-implementation-1
    - codex-debug-1
    - codex-verification-1
    - claude-deepseek-review-1
```

`code-review` may point to a Codex executor instead; routing does not restrict the host. Every
entry in defaults and `parallel_pool` must be registered. `parallel_pool` enables active parallel
scheduling, not failover. If an executor is unavailable, the Harness does not automatically
switch models or hosts; it pauses for a retry, another registered executor, or termination.

`workflow-controller`, `multi-agent-coordination`, `using-git-worktrees`,
`subagent-driven-development`, `test-driven-development`, `receiving-code-review`, and
`finishing-a-development-branch` are controller or implementation-context capabilities and do
not receive independent stage routes.

### Create and recover visible executors

The stable identity of a visible CLI executor is its pane title, not its pane index. Registering an
executor and configuring routing do not create a PSMux/tmux pane. First create the missing
session, window, or pane for the current machine state; then set its title and start the matching
launcher.

#### 1. Create the missing session, window, or pane

Define the PSMux path and target names:

```powershell
$tmux = "D:\psmux\tmux.exe"
$session = "agent-harness"
$window = "workers"
$shell = "powershell.exe"
$windowTarget = "${session}:${window}"
```

Run exactly one of the following creation commands for the current state:

- No `agent-harness` session exists: create the session, initial window, and first pane.

```powershell
& $tmux new-session `
  -d `
  -s $session `
  -n $window `
  $shell
```

- The session exists but the target window does not: create the window and its first pane in the
  existing session.

```powershell
& $tmux new-window `
  -d `
  -t $session `
  -n $window `
  $shell
```

- The session and window exist, and another parallel executor is needed: add a pane to the target
  window.

```powershell
& $tmux split-window `
  -d `
  -t $windowTarget `
  $shell
```

`-d` creates the resource in the background without switching the current terminal to the new
session, window, or pane. List panes in the target window afterward to find the actual index and
current command:

```powershell
& $tmux list-panes `
  -t $windowTarget `
  -F '#{session_name}:#{window_name}.#{pane_index} | #{pane_current_command} | #{pane_current_path}'
```

Choose the newly created pane or the pane being recovered and fill in its complete target. Do not
assume the pane index is always `0`:

```powershell
$pane = "agent-harness:workers.<PANE_INDEX>"
```

If the pane already exists, skip the creation commands and obtain `$pane` directly from
`list-panes`. Before sending a launcher command, confirm that the pane is at an idle PowerShell
prompt; do not send the command to a Codex, Claude, or other foreground process that is still
running.

#### 2. Set the executor identity and start its launcher

The following example starts a Codex executor in the selected pane:

```powershell
$tmux = "D:\psmux\tmux.exe"
$pane = "agent-harness:workers.<PANE_INDEX>"
$executor = "codex-planning-1"
$worktree = "<TARGET_WORKTREE_PATH>"
$launcher = "$env:USERPROFILE\.agent-harness\integrations\codex\start-codex.ps1"
$command = "& '$launcher' -Executor '$executor' -WorkingDirectory '$worktree'"

& $tmux select-pane -t $pane -T $executor
& $tmux send-keys -t $pane C-u
& $tmux send-keys -t $pane -l $command
& $tmux send-keys -t $pane Enter
```

A Claude provider executor uses the same executor ID as its pane title but changes the launch
command to:

```powershell
$launcher = "$env:USERPROFILE\.agent-harness\integrations\claude-code\start-claude.ps1"
$command = "& '$launcher' -Provider deepseek -WorkingDirectory '$worktree'"
```

For either host, `$executor`, the registered ID in `executors.yaml`, the routing target, and the
pane title must match. The Claude provider launcher does not read the executor ID, so verify that
the pane title and `-Provider` represent the intended registered executor.

#### 3. Inspect executor state

List every pane with:

```powershell
& $tmux list-panes -a `
  -F '#{session_name}:#{window_name}.#{pane_index} | #{pane_title} | #{pane_current_command} | #{pane_current_path}'
```

Confirm that:

- `pane_title` equals the executor ID;
- `pane_current_command` is the expected Codex, Claude, or host process;
- `pane_current_path` points to the target worktree.

#### 4. Recovery order after a machine restart

PSMux/tmux panes do not survive a machine restart. Recover them in this order:

1. Use `new-session`, `new-window`, or `split-window` to recreate the panes required by the current
   task.
2. Use `list-panes` to obtain the actual pane target.
3. Set the pane title to the registered executor ID.
4. Run the matching Codex or Claude launcher again in the correct worktree.
5. Use `list-panes -a` again to check the title, process, and path.

Recreate only the executors required by the current routes and task; there is no need to start
every executor in the registry.

### Configure API keys locally on Windows

A new local environment does not inherit API keys from another machine. The Harness neither
stores nor synchronizes credentials, so provider authentication must be initialized separately
after installing the skills.

| Scenario | Credential used by the Harness |
| --- | --- |
| Native Codex/OpenAI | Use Codex CLI's own login or authentication configuration; the Harness does not manage it. |
| Codex + MiMo | `MIMO_API_KEY`. |
| Claude Code + DeepSeek | `DEEPSEEK_API_KEY`. |
| Claude Code + MiMo | `MIMO_API_KEY`. |
| Native Claude Code | Use Claude Code's own login or authentication configuration; the Harness does not manage it. |

The Claude provider launcher reads Windows User environment variables directly. The Codex MiMo
launcher tells Codex CLI to read `MIMO_API_KEY` from its current process environment. Persist the
key as a User environment variable, then start a new terminal/PSMux process. Prefer the Windows
"Edit environment variables for your account" UI so the plaintext key does not enter PowerShell
history. The following interactive helper is also available; typed input is not displayed:

```powershell
function Set-UserApiKey {
  param([Parameter(Mandatory)][string] $Name)

  $secure = Read-Host $Name -AsSecureString
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)

  try {
    $value = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    [Environment]::SetEnvironmentVariable($Name, $value, "User")
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }
}

Set-UserApiKey -Name MIMO_API_KEY
Set-UserApiKey -Name DEEPSEEK_API_KEY
```

Set only the keys you actually use. Open a new terminal and new PSMux/tmux panes afterward so
child processes inherit the updated User environment. If the PSMux/tmux server was already
running before the change, restart the corresponding server/session. Check configuration without
printing key values:

```powershell
"MIMO_API_KEY", "DEEPSEEK_API_KEY" | ForEach-Object {
  [pscustomobject]@{
    Name = $_
    Configured = -not [string]::IsNullOrWhiteSpace(
      [Environment]::GetEnvironmentVariable($_, "User")
    )
  }
}
```

Remove a User environment variable when a provider is no longer used:

```powershell
[Environment]::SetEnvironmentVariable("MIMO_API_KEY", $null, "User")
[Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", $null, "User")
```

Windows User environment variables are local persistent configuration, not an encrypted secret
vault. Never place keys in `executors.yaml`, README files, task state, `.env` files, logs, or Git.
Do not create `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` merely because the Harness is installed;
configure them only when the selected CLI authentication method explicitly requires them.

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
