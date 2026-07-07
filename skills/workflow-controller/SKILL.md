---
name: workflow-controller
description: "用于 Harness 管理的工程任务控制平面：创建或接管任务，维护 control.md 和 controller.json，判断五阶段流程，选择 Skill 与 executor，分派阶段级 Agent，裁决结果，并管理 VERIFY 后的单次本地提交和分支收尾。"
---

# Workflow Controller
`workflow-controller` 是任务流程的唯一控制平面，只负责判断、分派、裁决和记录状态。

## 何时使用
使用本 Skill：

- DEVELOPER 模式下的仓库修改任务；
- 复杂、多阶段或多 Agent 的只读工程任务；
- 需要创建、恢复或接管 `.harness/tasks/<task-id>/` 的任务；
- 用户明确要求由 Controller 管理流程。

不用于 GENERAL 模式下的普通问答、简单只读代码问答、写作或非工作流任务。

## 唯一权限与硬边界
只有 `workflow-controller` 可以：

- 创建任务目录、`control.md`、`controller.json`，并写入这两个状态文件；
- 推进、回退、重试、暂停或完成阶段；
- 判断直接路径或完整路径；
- 选择 Skill、executor、串行或并行；
- 调用 `multi-agent-coordination` 分派阶段级 Agent；
- 管理 IMPLEMENT / VERIFY 循环；
- 在 VERIFY 通过后执行确定性本地 completion commit，或调用确定性脚本完成该提交；
- 调用分支收尾流程。

专项 Agent 可以按 handoff 或任务需要只读必要状态，但不得写入任务状态、推进阶段或调用 `multi-agent-coordination`。

Controller 不亲自做需求澄清、方案设计、计划写作、编码、代码评审、调试推理、专项验证、pane/CLI 通信实现。

## 状态真源
任务状态只以项目内文件为准：

```text
.harness/tasks/<task-id>/control.md
.harness/tasks/<task-id>/controller.json
```

`control.md` 至少表达任务目标、阶段、状态、worktree、branch、base commit、确认的设计或计划、当前工作、验证证据和下一步。状态字段不固定完整枚举，按任务需要记录。

`controller.json` 只记录最小接管信息，例如 executor 和 acquired_at。不要增加 heartbeat、自动过期、pane ID、session ID 或复杂锁。

每次启动、resume、上下文压缩后继续、Agent 返回或用户插话后，先读状态文件再决定动作。若状态与项目证据冲突，停止并要求人工裁决。

## 五阶段规则
固定阶段只能是：

```text
UNDERSTAND -> PREPARE -> IMPLEMENT -> VERIFY -> COMPLETE
```

不得新增评审阶段或其他阶段。

### UNDERSTAND
先判断是否具备直接路径：

```text
Goal
Changes
Verification
```

三项完整且无未决需求、方案或范围决策时，可记录摘要并进入后续阶段。

若不完整，按需分派 `brainstorming`、`writing-plans`、`reviewing-plans`。经过这些完整路径后，进入 PREPARE 前必须获得用户明确确认。

复杂只读任务若不需要仓库修改，可在证据充分后跳过 PREPARE、worktree 和 commit，直接进入 COMPLETE。

### PREPARE
仓库修改任务必须在首次修改前通过 `using-git-worktrees` 建立或接管隔离 worktree，记录 worktree、branch、base commit，并仅运行已明确存在的基线命令。

基线失败时记录证据并等待用户决定，不得直接进入 IMPLEMENT。

### IMPLEMENT
按确认摘要或计划分派实施：

- 普通实施使用 `executing-plans`；
- `subagent-driven-development` 只能由实施 Agent 在内部使用，不经过 `multi-agent-coordination`，不创建阶段级 pane，不修改任务状态；
- `test-driven-development` 只在用户、计划、Controller 或实施上下文选择时使用；
- `systematic-debugging` 用于根因不明的失败。

`code-review` 只能作为 IMPLEMENT 后、VERIFY 前的可选只读活动；有有效发现时，返回 IMPLEMENT 通过 `receiving-code-review` 或实施任务处理。

### VERIFY
仓库修改任务必须通过 `verification-before-completion` 取得真实证据后才能完成。

VERIFY 失败时，只有需求、方案和范围都不变，才可回到 IMPLEMENT 修复并再次 VERIFY。若需要改变需求、方案或范围，必须回到 UNDERSTAND 并等待用户重新确认。

### COMPLETE
仓库修改任务完成顺序固定为：

```text
VERIFY 通过
-> Controller 执行确定性本地 completion commit，或调用确定性脚本
-> finishing-a-development-branch
-> 默认保留 branch 和 worktree，或执行用户明确选择的其他动作
-> COMPLETE
```

completion commit 不交给实施 Agent，不产生中间 commit、checkpoint commit 或 frequent commits。

不得自动 merge、push、rebase、删除 branch、删除 worktree 或 cleanup。远端、历史改写和破坏性动作必须由用户明确选择。

## 分派与并行
阶段级 Agent 一律通过 `multi-agent-coordination` 分派。Controller 只使用其抽象能力，不实现 pane、CLI、进程或输出捕获。

handoff 至少包含：目标、当前阶段、Skill、工作目录、范围、读写边界、预期输出、证据要求、停止条件。

executor 只能来自已注册配置。不可用时暂停，由用户选择重试、换用已注册 executor 或终止。

只有同时满足以下条件才并行：

- 至少两个独立任务；
- 无顺序依赖；
- 无共享写入冲突；
- 边界和预期输出可独立描述；
- 结果可独立裁决；
- Controller 能汇总或裁决。

否则串行。当前设计不为并行写者自动创建更多 worktree。

## 结果裁决
Agent 返回后，Controller 必须：

1. 读取返回内容和必要产物；
2. 对照目标、确认方案、范围和证据要求；
3. 判断接受、拒绝、延期、需要更多证据、等待用户或受阻；
4. 更新 `control.md`；
5. 决定推进、回退、重试、继续等待或停止。

不得把 Agent 的成功声明当作证据。必须检查其返回的命令、测试、文件、评审或手工验证依据。


## Memory 记录

- Harness 管理的 Agent 调用结束并完成 capture 后，Controller 可按需调用 `integrations/memory/record-memory.ps1 -Source auto` 记录可复用经验。
- Memory 只是经验台账，不是任务状态；写入失败不得影响阶段裁决或任务结果。
- Memory 不自动生效，promotion 由人工完成。

## 停止条件
遇到以下情况必须停止并等待用户或外部状态变化：

- 目标、范围、方案或验证口径无法确认；
- 完整路径进入 PREPARE 前缺少用户明确确认；
- `control.md` 与项目证据冲突，或 `controller.json` 显示已有 Controller 且未明确接管；
- 仓库修改任务尚未建立 worktree，或基线失败；
- executor 或 `multi-agent-coordination` 不可用；
- Agent 结果要求改变需求、方案或范围；
- VERIFY 失败且修复会扩大范围；
- merge、push、rebase、删除、清理、discard 或其他高风险操作缺少用户明确选择。
