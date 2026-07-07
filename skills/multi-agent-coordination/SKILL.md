---
name: multi-agent-coordination
description: "用于 workflow-controller 调度阶段级可见 CLI Agent 的通信通道管理：检查 executor 可用性，发送任务，等待空闲，捕获结果；后端或通道不可用时返回 unavailable。"
---

# Multi-Agent Coordination

`multi-agent-coordination` 是阶段级可见 CLI Agent 的通信层。它只管理 executor 通道，不做流程决策。

## 何时使用

只由 `workflow-controller` 调用，用于阶段级 Agent：

- 查询 executor 是否可用；
- 向目标 executor 发送 handoff；
- 等待目标 executor 完成或进入等待状态；
- 捕获目标 executor 返回内容。

不要用于实施 Agent 内部的 `subagent-driven-development`。内部 Subagent 使用宿主原生机制，不经过本 Skill。

## 职责边界

本 Skill 负责：

- 维护通道抽象；
- 按 executor 名称定位已注册通道；
- 暴露 `status`、`send`、`wait`、`capture` 四类操作语义；
- 将通道不可用、目标不明确、后端未安装、捕获失败等情况报告给 Controller。

本 Skill 不负责：

- 判断调用哪个 Skill；
- 判断是否并行；
- 定义业务角色；
- 更新 `control.md`；
- 推进阶段；
- 裁决 Agent 结果；
- 实施 pane、CLI、进程或终端复用逻辑；
- 管理实施 Agent 内部 Subagent。

无可用后端时必须返回 unavailable；不得以临时 shell、后台进程或临时 pane 模拟通道。具体机械实现属于 integration 层。

## Executor 模型

executor 是独立运行通道，不是业务角色。

每个 executor 至少对应：

- 宿主；
- 模型配置；
- 独立 CLI 进程；
- 独立可见通道；
- 独立上下文。

Controller 只能使用已注册 executor，不得发明 executor。executor 不可用时，返回 `unavailable` 给 Controller，由 Controller 决定重试、改用其他已注册 executor 或停止。

## Pane 生命周期

- 一个 executor 对应一个长期存在的 pane 和一个已启动的 CLI 进程。
- pane 标题使用 executor 名称。
- pane、window、session 和 CLI 进程由用户或 integration 启动入口预先准备。
- 本 Skill 只使用已存在的 executor 通道，不创建、重建、respawn 或替换 pane / CLI 进程。
- 同一任务继续工作时，可以保留上下文。
- 同一任务中的新独立工作项，可以在 handoff 中要求 Agent 忽略先前上下文。
- 新任务或 worktree 变化时，Controller 必须在 handoff 中提供目标工作目录或 worktree 路径；本 Skill 不负责切换工作目录或重启 CLI。
- pane 必须保留，不创建临时替代 pane。
- 目标 pane 不存在、CLI 未运行、工作目录不适合安全执行或重启需求无法满足时，返回 `unavailable` 并暂停，不得静默降级。

## 操作语义

### status

输入：executor 名称。

输出之一：

- `idle`：可接收任务；
- `busy`：正在执行；
- `waiting_user`：需要补充输入或确认；
- `unavailable`：未注册、后端缺失、通道不可定位或无法安全通信。

不得增加业务状态，例如 completed。任务完成由 Controller 结合 `wait` 和 `capture` 结果判断。

### send

输入：

- executor 名称；
- 工作目录或 worktree；
- handoff 文本；
- 是否为新任务或同任务 follow-up。

发送前必须确认 executor 为可用通道。若目标不明确、通道冲突、后端不可用或 executor 忙于不相关任务，返回失败，不发送。

handoff 内容由 Controller 提供，至少包含目标、当前阶段、Skill、工作目录、范围、读写边界、预期输出、证据要求、停止条件。

### wait

输入：

- executor 名称；
- 等待目标：空闲、等待用户、超时或后端失败；
- 超时策略。

输出必须说明结果是 `idle`、`waiting_user`、`busy`、`timeout` 或 `unavailable`。超时不是成功。

### capture

输入：executor 名称。

输出：

- 捕获到的最新 Agent 返回内容；
- 捕获时间和通道标识；
- 捕获失败原因。

如果 capture 结果为空、截断或不可信，必须标记为不完整，不得让 Controller 当作成功结果裁决。

## 发送安全

- 新独立任务可以要求后端清理目标上下文；同一任务的 follow-up 不应清理上下文。
- 不要向不明确的通道发送内容。
- 不要在已有任务未完成时覆盖上下文。
- 不要保存完整转录副本；只把捕获结果返回给 Controller。
- 不要执行远端、破坏性或项目外操作。

## 返回格式

返回结构化摘要：

```text
operation:
executor:
status:
backend:
sent:
captured:
result:
error:
```

`backend` 未接入时写 `none`，`status` 写 `unavailable`。

## 停止条件

遇到以下情况必须返回 Controller，不得自行绕过：

- 后端未安装或未配置；
- executor 未注册；
- 通道定位不唯一；
- 目标 executor 忙于不相关任务；
- send、wait 或 capture 失败；
- 捕获结果不完整；
- 操作会变成流程决策、任务裁决或状态推进。
