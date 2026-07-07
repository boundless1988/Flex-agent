# Flex-agent

[English](./README.en.md) | 简体中文

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

### 进入 DEVELOPER 模式

在新的 Codex app thread 中输入：

```text
进入 DEVELOPER 模式。
```

确认进入后，再发送仓库修改任务。

普通聊天、只读问答、非开发任务不需要进入该模式。

### 任务状态

Harness 管理的任务会在目标仓库中创建：

```text
<repo>\.harness\tasks\<task-id>\control.md
<repo>\.harness\tasks\<task-id>\controller.json
```

`control.md` 是任务状态真源，记录阶段、计划、worktree、executor 输出、验证证据和最终提交。

---

## Workflow

默认开发流程：

```text
UNDERSTAND -> PREPARE -> IMPLEMENT -> VERIFY -> COMPLETE
```

默认规则：

- 所有仓库修改必须在独立 worktree 中完成。
- VERIFY 通过后才进入 COMPLETE。
- COMPLETE 创建一次本地 completion commit。
- 默认不 merge、不 push、不 rebase、不删除 branch、不清理 worktree。

---

## Executor 与路由

Executor 定义：

```text
config/executors.yaml
```

路由配置：

```text
config/routing.yaml
```

常用角色：

```text
executing-plans                 -> claude-deepseek-1
systematic-debugging            -> claude-deepseek-1
code-review                     -> claude-deepseek-2
verification-before-completion  -> claude-mimo-2
```

visible CLI executor 的稳定身份是 pane title，例如：

```text
claude-deepseek-2
```

不是 pane index。

---

## 重启后恢复 visible executor

PSMux/tmux pane 不跨机器重启保留。重启后只需恢复当前任务需要的 executor。

最小 review executor：

```powershell
$tmux = "D:\psmux\tmux.exe"

& $tmux new-session -d -s agent-harness -n claude-review powershell.exe
Start-Sleep -Milliseconds 500

& $tmux select-pane `
  -t "agent-harness:claude-review.0" `
  -T "claude-deepseek-2"
```

在 pane 中启动 Claude DeepSeek：

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

检查 pane：

```powershell
& $tmux list-panes -a `
  -F '#{session_name}:#{window_name}.#{pane_index} | #{pane_title} | #{pane_current_command} | #{pane_current_path}'
```

---

## Claude Code Provider Launcher

Claude Code 启动脚本：

```text
integrations/claude-code/start-claude.ps1
```

用途：

- 设置 DeepSeek / MiMo provider 环境变量。
- 切换到目标工作目录。
- 启动 Claude Code。
- 退出后恢复环境。

API key 应保存在 Windows 用户环境变量中：

```text
DEEPSEEK_API_KEY
MIMO_API_KEY
```

不要提交 API key 或 token。

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
