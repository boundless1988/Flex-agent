# Agent Harness

Agent Harness 是一个本地 Agent 开发协作框架，用于让 Codex、Claude Code 等工具通过统一 workflow、skills、Git worktree 和可见 CLI executor pane 协作完成开发任务。

设计目标：

- 不运行后台服务。
- 不自动管理 pane / CLI 生命周期。
- 不自动 merge、push、rebase 或 cleanup。
- 仓库修改任务必须使用独立 Git worktree。
- 任务状态记录在目标仓库的 `.harness/tasks/<task-id>/control.md`。
- visible executor pane 由用户手动准备，Harness 只使用已存在的通道。

---

## 目录结构

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

常用外部位置：

```text
%USERPROFILE%\.codex\AGENTS.md
%USERPROFILE%\.agents\skills
%USERPROFILE%\.claude\skills
```

---

## 安装 / 引入

将本仓库放到：

```text
%USERPROFILE%\.agent-harness
```

然后执行 Codex 规则与 skills 接入脚本，将 Harness 的规则和 skills 同步到 Codex 可读取的位置；再执行 Claude Code skills 接入脚本，将同一份 Harness skills 链接到 Claude Code 可读取的位置。

```powershell
powershell -ExecutionPolicy Bypass -File .\integrations\codex\sync-rules.ps1
powershell -ExecutionPolicy Bypass -File .\integrations\codex\install-skills.ps1
powershell -ExecutionPolicy Bypass -File .\integrations\claude-code\install-skills.ps1
```

同步后可抽查某个 skill 的 hash：

```powershell
Get-FileHash "$env:USERPROFILE\.agent-harness\skills\code-review\SKILL.md" -Algorithm SHA256
Get-FileHash "$env:USERPROFILE\.agents\skills\code-review\SKILL.md" -Algorithm SHA256
Get-FileHash "$env:USERPROFILE\.claude\skills\code-review\SKILL.md" -Algorithm SHA256
```

hash 一致表示该 skill 已接入。

---

## 使用方式

本节按项目的完整设计说明 executor、routing 和本地凭证配置。示例中的 executor名称、模型和路由仅用于展示不同场景，不代表项目必须采用的默认配置。实际注册项与默认路由始终分别以 `config/executors.yaml` 和 `config/routing.yaml` 为准。

### 进入 DEVELOPER 模式

在新的 Codex app thread 中输入：

```text
进入 DEVELOPER 模式。
```

确认进入后，再发送仓库修改任务。普通聊天、只读问答、非开发任务不需要进入该模式。

### 任务状态与 Workflow

Harness 管理的任务会在目标仓库中创建：

```text
<repo>\.harness\tasks\<task-id>\control.md
<repo>\.harness\tasks\<task-id>\controller.json
```

`control.md` 是任务状态真源，记录阶段、计划、worktree、executor 输出、验证证据和
最终提交。默认开发流程为：

```text
UNDERSTAND -> PREPARE -> IMPLEMENT -> VERIFY -> COMPLETE
```

默认规则：

- 所有仓库修改必须在独立 worktree 中完成。
- VERIFY 通过后才进入 COMPLETE。
- COMPLETE 创建一次本地 completion commit。
- 默认不 merge、不 push、不 rebase、不删除 branch、不清理 worktree。

### Executor 注册模型

`config/executors.yaml` 是 executor 注册表。每个 executor 表示一个独立 CLI 进程、pane 和上下文。需要并行运行同类 executor 时，使用不同 ID，例如 `review-1`、`review-2`，不要让两个 pane 共享同一身份。

支持的配置字段：

| 字段 | 说明 |
| --- | --- |
| `host` | 必填；当前设计包含 `codex-cli` 与 `claude-code`。 |
| `model` | 必填；记录该 executor 预期使用的模型。 |
| `provider` | 可选；第三方 provider 标识，例如 `mimo` 或 `deepseek`。 |
| `reasoning_effort` | 可选；由对应 launcher/CLI 在模型支持时使用。 |

注册表只声明 executor，不会自动创建进程。visible executor 还必须使用匹配的 launcher启动，并将 pane title 设置为 executor ID。

### 配置和启动 Codex executor

原生 Codex/OpenAI 模型不需要 `provider`：

```yaml
executors:
  codex-planning-1:
    host: codex-cli
    model: "<codex-model-id>"
    reasoning_effort: "<supported-effort>"
```

通过已经适配的第三方 provider 使用 Codex 时，需要同时声明 `provider` 和 `model`：

```yaml
executors:
  codex-mimo-build-1:
    host: codex-cli
    provider: mimo
    model: "<mimo-model-id>"
```

`integrations/codex/start-codex.ps1` 按 executor ID 读取注册表，将 `model` 和可选的`reasoning_effort` 传给 Codex CLI。当前 launcher 实现了原生 Codex/OpenAI 和 MiMo Responses-compatible provider；MiMo 场景会关闭 endpoint 不支持的`web_search`、`image_generation`。其他 provider 不能只增加 YAML，必须先在 launcher中实现对应的 endpoint、认证和 wire API 配置。DeepSeek 不通过该 Codex launcher接入。

修改配置后先执行 DryRun：

```powershell
& .\integrations\codex\start-codex.ps1 `
  -Executor codex-planning-1 `
  -WorkingDirectory "<TARGET_WORKTREE_PATH>" `
  -DryRun |
  Format-List
```

确认模型、provider、推理强度和参数正确后，再启动交互式 executor：

```powershell
& .\integrations\codex\start-codex.ps1 `
  -Executor codex-planning-1 `
  -WorkingDirectory "<TARGET_WORKTREE_PATH>"
```

如果服务端提示模型需要更新版本，先检查 `codex --version`，再按 Codex CLI 的安装方式升级。修改 executor 配置后必须重启对应 CLI 进程；运行中的进程不会热加载 YAML。

### 配置和启动 Claude Code executor

设计上，Claude Code executor 可以使用 Claude Code 自身的原生认证，也可以通过项目已提供的 provider launcher 使用 DeepSeek 或 MiMo：

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

原生 Claude Code executor 使用 Claude Code 自身的登录和模型配置，直接在目标worktree 中启动 `claude`。项目保留的`integrations/claude-code/start-claude.ps1` 当前只接受 `deepseek` 和 `mimo`：

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

需要特别注意：当前 Claude launcher 不按 executor ID 读取 `executors.yaml`，实际provider 模型由脚本中的 `ANTHROPIC_MODEL`、默认模型和 subagent 模型环境变量决定。因此修改 Claude/DeepSeek/MiMo 模型时，必须同时更新注册表和 launcher，确保声明值与运行值一致。其他 Claude provider 需要新增launcher 分支或直接使用该 provider 的原生 Claude Code 配置。`start-claude.ps1` 没有 DryRun。重新注册 Claude executor 时，应先检查`claude --version`、API Key 和目标工作目录，再进行一次真实 smoke test。

### 配置 routing

`config/routing.yaml` 只为阶段级 Agent Skill 指定默认 executor。路由值是 executorID，与 executor 使用 Codex 还是 Claude Code 无关。例如，一个同时使用两个宿主的配置可以是：

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

`code-review` 同样可以指向某个 Codex executor；routing 不限制宿主。所有 defaults 和`parallel_pool` 项都必须已经注册。`parallel_pool` 用于主动并行调度，不是故障降级。executor 不可用时 Harness 不会自动切换模型或宿主，而是暂停并等待重试、改选已注册executor 或终止。

`workflow-controller`、`multi-agent-coordination`、`using-git-worktrees`、`subagent-driven-development`、`test-driven-development`、`receiving-code-review` 和`finishing-a-development-branch` 属于 controller 或实施上下文内部能力，不配置独立阶段路由。

### 创建和恢复 visible executor

visible CLI executor 的稳定身份是 pane title，不是 pane index。注册 executor 和配置routing 不会自动创建 PSMux/tmux pane；必须先根据本机现有状态创建 session、window或 pane，再设置 title 并启动对应 launcher。

#### 1. 创建缺失的 session、window 或 pane

先定义 PSMux 路径和目标名称：

```powershell
$tmux = "D:\psmux\tmux.exe"
$session = "agent-harness"
$window = "workers"
$shell = "powershell.exe"
$windowTarget = "${session}:${window}"
```

根据实际状态只执行下面一种创建命令：

- 尚无 `agent-harness` session：创建 session、初始 window 和第一个 pane。

```powershell
& $tmux new-session `
  -d `
  -s $session `
  -n $window `
  $shell
```

- session 已存在，但尚无目标 window：在现有 session 中创建 window 和第一个 pane。

```powershell
& $tmux new-window `
  -d `
  -t $session `
  -n $window `
  $shell
```

- session 和 window 都存在，需要增加并行 executor：在目标 window 中新增 pane。

```powershell
& $tmux split-window `
  -d `
  -t $windowTarget `
  $shell
```

`-d` 表示在后台创建，不把当前终端切换到新 session/window/pane。创建后列出目标window 的 pane，确认实际 index 和当前命令：

```powershell
& $tmux list-panes `
  -t $windowTarget `
  -F '#{session_name}:#{window_name}.#{pane_index} | #{pane_current_command} | #{pane_current_path}'
```

从输出中选择新建或需要恢复的 pane，并填写其完整 target；不要默认 pane index 一定是 `0`：

```powershell
$pane = "agent-harness:workers.<PANE_INDEX>"
```

如果 pane 已经存在，可跳过创建命令，直接通过 `list-panes` 获取 `$pane`。发送 launcher命令前，确认该 pane 当前停留在空闲 PowerShell prompt；不要把命令发送给仍在运行的Codex、Claude 或其他前台程序。

#### 2. 设置 executor 身份并启动 launcher

以下示例在选定的 pane 中启动一个 Codex executor：

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

Claude provider executor 使用相同的 executor ID 作为 pane title，但启动命令改为：

```powershell
$launcher = "$env:USERPROFILE\.agent-harness\integrations\claude-code\start-claude.ps1"
$command = "& '$launcher' -Provider deepseek -WorkingDirectory '$worktree'"
```

无论使用哪种宿主，`$executor`、`executors.yaml` 中的注册 ID、routing target 和 panetitle 都必须一致。Claude provider launcher 不读取 executor ID，因此需要特别检查 pane title 与 `-Provider` 是否对应预期注册项。

#### 3. 检查 executor 状态

列出所有 pane：

```powershell
& $tmux list-panes -a `
  -F '#{session_name}:#{window_name}.#{pane_index} | #{pane_title} | #{pane_current_command} | #{pane_current_path}'
```

检查结果时确认：

- `pane_title` 等于 executor ID；
- `pane_current_command` 是预期的 Codex、Claude 或其宿主进程；
- `pane_current_path` 指向目标 worktree。

#### 4. 机器重启后的恢复顺序

PSMux/tmux pane 不跨机器重启保留。重启后按以下顺序恢复：

1. 根据当前任务需要，使用 `new-session`、`new-window` 或 `split-window` 重建 pane。
2. 使用 `list-panes` 获取实际 pane target。
3. 将 pane title 设置为已注册的 executor ID。
4. 在正确 worktree 中重新运行对应 Codex 或 Claude launcher。
5. 再次使用 `list-panes -a` 检查 title、进程和路径。

只恢复当前 routing 和任务实际需要的 executor，不需要启动注册表中的全部 executor。

### 在 Windows 本地配置 API Key

新的本地环境不会自动获得旧机器的 API Key。Harness 不保存或同步凭证；安装 skills后仍需单独完成 provider 认证。

| 场景 | Harness 使用的凭证 |
| --- | --- |
| 原生 Codex/OpenAI | 使用 Codex CLI 自身的登录或认证配置；Harness 不代管。 |
| Codex + MiMo | `MIMO_API_KEY`。 |
| Claude Code + DeepSeek | `DEEPSEEK_API_KEY`。 |
| Claude Code + MiMo | `MIMO_API_KEY`。 |
| 原生 Claude Code | 使用 Claude Code 自身的登录或认证配置；Harness 不代管。 |

当前 Claude provider launcher 会直接读取 Windows User 环境变量；Codex MiMolauncher 会让 Codex CLI 从当前进程环境读取 `MIMO_API_KEY`。因此推荐把 key 持久化为User 环境变量，并在设置后启动新的终端/PSMux 进程。推荐使用 Windows“编辑账户的环境变量”界面录入，避免把明文 key 写入 PowerShell history。也可以使用下面的交互式函数；输入内容不会显示在终端：

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

只设置实际使用的 key。设置完成后，新建终端和 PSMux/tmux pane，使子进程继承新的User 环境；如果 PSMux/tmux server 在设置前已经运行，应重启对应 server/session。可在不输出 key 内容的情况下检查是否已配置：

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

不再使用某个 provider 时，可删除对应的 User 环境变量：

```powershell
[Environment]::SetEnvironmentVariable("MIMO_API_KEY", $null, "User")
[Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", $null, "User")
```

Windows User 环境变量是本机持久化配置，不是加密 secret vault。不要把 key 写入`executors.yaml`、README、任务状态、`.env`、日志或 Git；不要为了安装 Harness 而默认创建 `OPENAI_API_KEY`、`ANTHROPIC_API_KEY`，只有所选 CLI 认证方式明确要求时才配置。

---

## code-review 只读规则

`code-review` 是 inspection skill，不是 verification skill。

默认允许：

- 阅读文件
- 查看 diff
- 查看 Git metadata
- 查看已有验证证据

默认不允许：

- 运行测试
- 运行 smoke test
- import 项目代码
- 执行项目代码
- 运行可能生成缓存或修改工作区的命令

如果验证证据不足，应记录 `Verification Gap`，而不是自行运行测试。

---

---

## Memory

Memory 是经验台账，不是任务状态，也不会自动进入运行时上下文。

位置：

```text
全局：%USERPROFILE%\.agent-harness\memory.md
项目：<project>\.harness\memory.md
```

记录格式：

```markdown
## YYYY-MM-DD — Title

经验内容

状态：recorded | promoted | discarded
```

手动记录：

```powershell
powershell -ExecutionPolicy Bypass `
  -File "$env:USERPROFILE\.agent-harness\integrations\memory\record-memory.ps1" `
  -Scope global `
  -Source manual `
  -Title "<title>" `
  -Content "<content>"
```

项目级记录：

```powershell
powershell -ExecutionPolicy Bypass `
  -File "$env:USERPROFILE\.agent-harness\integrations\memory\record-memory.ps1" `
  -Scope project `
  -ProjectPath "<project>" `
  -Source manual `
  -Title "<title>" `
  -Content "<content>"
```

Auto 记录由 Controller 在 Harness 管理的阶段级 Agent 调用结束并完成 capture 后按需触发：

```powershell
-Source auto
```

Memory 不自动生效。需要人工将经验提升为通用规则、项目约束、Skill 或宿主配置。

## 清理规则

清理必须手动执行。

清理前确认：

- work 已提交，或确认不再需要。
- 没有 controller 依赖该状态。
- 用户明确要求清理。

常用检查：

```powershell
git worktree list
git status --short --branch
D:\psmux\tmux.exe list-sessions
D:\psmux\tmux.exe list-panes -a
```

---

## 安全规则

不要提交：

- API key
- token
- provider credentials
- 包含密钥的日志
- 临时 worktree
- `.pytest_cache`
- `__pycache__`
- 本机 session 状态

凭证应保存在本机环境变量中。
