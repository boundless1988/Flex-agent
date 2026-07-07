# Agent Harness 设计规格

> 状态：设计归档与维护参考。  
> 运行真源：Harness 运行以 `config/`、`skills/`、`integrations/` 及宿主接入文件的实际内容为准。  
> 更新原则：仅在架构、职责边界或关键设计决策变化时更新；不记录软件版本、安装状态或临时测试结果。  
> 约束优先级：本文记录的稳定架构，高于未在本项目确认的默认实践。  
> 目标读者：负责维护、迁移、重建或审计本地 Harness 的 Codex、Claude Code 或人工开发者。

---

## 1. 目标

构建一套本地、用户级、可跨宿主使用的 Agent Harness，重点解决以下问题：

1. 在普通通用 Agent 使用与严格 AI Coding 工作流之间人工切换。
2. 让开发任务具备明确、可恢复、可审计的流程状态。
3. 沉淀可复用的方法型 Skills，并删除不符合本地目标的强制流程。
4. 支持 Codex App、Codex CLI、Claude Code 等本地宿主。
5. 支持不同宿主、不同模型和多个可见 CLI Agent 协同工作。
6. 支持实施 Agent 内部使用宿主原生 Subagent。
7. 所有仓库修改通过独立 Git worktree 隔离。
8. 保持设计简单，避免固定角色、重复状态层、过度协议化和无必要的文件包装。
9. Memory 仅作为经验记录，不自动影响运行时行为。
10. 在不增加独立复杂模块的前提下，形成执行、验证、反馈、修正闭环。

---

## 2. 设计原则

### 2.1 简洁优先

只保留对可靠执行有直接价值的组件。

不因已有实践中存在某个 Skill、角色、状态文件或流程层级，就默认将其纳入本 Harness。

新增任何结构前应先证明：

- 现有组件无法表达该职责；
- 该职责会稳定重复出现；
- 独立后能形成清晰边界；
- 增加的维护成本低于收益。

### 2.2 单一真源

- 通用常驻规则只有一份真源。
- Skill 内容只有一份真源。
- 任务工作流状态只有一个真源。
- 宿主配置是生成物或接入结果，不作为独立维护源。

### 2.3 控制与执行分离

`workflow-controller` 负责流程判断、分派和裁决。

专项 Skill 负责具体方法，不推进全局阶段，不修改全局任务状态。

宿主集成层负责机械操作，不承担业务流程决策。

### 2.4 公共语义与宿主实现分离

公共流程、触发条件、输入输出和不变量写在 `SKILL.md`。

宿主专属调用方式可写入：

```text
references/hosts/codex.md
references/hosts/claude-code.md
```

真正的 CLI、pane、路径、进程和输出捕获逻辑放在 `integrations/` 或 Skill 的确定性脚本中。

不为不同宿主复制整份 Skill。

### 2.5 证据优先

设计、评审、验证和完成均以可检查的项目上下文和执行证据为准。

不能把假设写成已确认事实。

---

## 3. 约束与采用顺序

本 Harness 只保留已经在本文确认的稳定架构、职责边界和执行规则。

方法型 Skills、控制层、通信层和宿主接入能力均以本项目目标重新定义，不保留未被确认的外部默认流程、固定角色、固定路径或历史迁移说明。

### 3.1 优先级

发生冲突时按以下顺序处理：

```text
用户当前明确指令
> 项目自身约束与实际运行文件
> 本文记录的稳定架构
> 已确认的本地实现约定
> 一般工程实践
```

---

## 4. 运行模式

Harness 有两个模式。

### 4.1 GENERAL

默认模式。

行为：

- 使用宿主自身的通用 Agent 能力；
- 不自动进入开发工作流；
- 不要求调用 `workflow-controller`；
- 普通问答、写作、分析和非仓库修改任务按宿主原生方式处理。

### 4.2 DEVELOPER

仅在用户明确切换后启用。

行为：

- 仓库修改任务必须由 `workflow-controller` 管理；
- 复杂、多阶段或多 Agent 的只读工程任务可以由 Controller 管理；
- 普通只读代码问答不强制进入完整流程。

### 4.3 模式切换规则

- 只能由用户人工切换；
- 只对当前会话有效；
- 不设置项目默认模式；
- 不自动根据目录、仓库或任务内容切换；
- 精确的宿主命令或 UI 形式属于待实现细节。

---

## 5. 开发生命周期

固定阶段：

```text
UNDERSTAND
→ PREPARE
→ IMPLEMENT
→ VERIFY
→ COMPLETE
```

阶段与状态是不同概念。阶段固定，状态用于表达当前是否进行中、等待用户、受阻等；状态的最终枚举暂不强制扩展。

### 5.1 UNDERSTAND

目标：

- 理解任务；
- 检查项目上下文；
- 判断是否已具备直接实施条件。

对于仓库修改任务，先尝试形成：

```text
Goal
Changes
Verification
```

含义：

- `Goal`：需要达成的结果；
- `Changes`：预计修改的范围和行为；
- `Verification`：如何证明修改正确。

若三项完整，且不存在未决需求或实质技术决策，可走直接路径，不强制完整设计和计划。

若不完整，则进入：

```text
澄清
→ brainstorming
→ writing-plans
→ 必要时 reviewing-plans
→ 用户明确确认
```

### 5.2 PREPARE

在第一次实际修改前执行。

主要职责：

- 建立或接管任务目录；
- 创建独立 worktree 和任务分支；
- 记录 base commit、branch、worktree；
- 检查已有基线验证命令；
- 准备实施上下文。

Worktree 不应在早期只读分析阶段创建。

### 5.3 IMPLEMENT

按确认后的摘要或计划实施。

Controller 选择实施组织方式：

- `executing-plans`
- 实施 Agent 内部的 `subagent-driven-development`

可按需使用：

- `test-driven-development`
- `systematic-debugging`
- `receiving-code-review`

### 5.4 VERIFY

必须基于实际证据验证修改。

可包括：

- 目标测试；
- 项目已有测试命令；
- build；
- type check；
- lint；
- 静态分析；
- 手工验收；
- 兼容或迁移检查。

验证失败时可自动回到 IMPLEMENT，再次进入 VERIFY，前提是：

- 不改变已确认需求；
- 不改变已确认方案；
- 不扩大范围。

若需要改变以上内容，必须返回 UNDERSTAND 并由用户重新确认。

### 5.5 COMPLETE

只有 VERIFY 通过后才能进入。

在 VERIFY 通过与 COMPLETE 之间：

- 创建一次本地 Git commit；
- 不要求中间 commit；
- 不要求 frequent commits；
- 不创建 WIP commit。

完成后默认：

- 保留 branch；
- 保留 worktree；
- 不自动 merge；
- 不自动 push；
- 不自动 rebase；
- 不自动删除 branch；
- 不自动删除 worktree。

后续动作由 `finishing-a-development-branch` 提供选项，并受用户确认约束。

---

## 6. Git 与 Worktree 规则

### 6.1 强制规则

所有仓库修改必须在独立 worktree 中进行，没有跳过选项。

只读任务通常不创建 worktree。

### 6.2 创建时机

在第一次实际修改前创建，不在早期分析时创建。

### 6.3 基线验证

创建 worktree 后：

- 仅运行项目已经明确存在的基线命令；
- 不猜测完整测试命令；
- 不擅自添加新的基线要求。

若基线失败：

- 记录失败；
- 暂停；
- 由用户确认是否继续。

### 6.4 写入并发

同一 worktree：

- 允许多个 Agent 并行只读；
- 同一时间只允许一个 Agent写入；
- 写入由 Controller 串行化。

当前设计不为并行写者自动创建更多 worktree。

---

## 7. 项目级状态

项目内使用：

```text
<project>/.harness/
├── tasks/
│   └── <task-id>/
│       ├── control.md
│       ├── controller.json
│       └── 其他按需产物
└── memory.md
```

`.harness/` 应加入项目 `.gitignore`，不进入项目版本控制。

### 7.1 control.md

任务工作流状态的唯一真源。

至少表达：

- Task goal
- Phase
- Status
- Git worktree
- Git branch
- Base commit
- Confirmed design or plan
- Current work
- Verification
- Next step

不强制复杂子目录。

按需增加：

```text
design.md
plan.md
review.md
verification.md
```

只有存在持续价值时才落盘。

### 7.2 controller.json

最小格式：

```json
{
  "executor": "codex-1",
  "acquired_at": "..."
}
```

规则：

- 同一任务同一时间只有一个活动 Controller；
- 显式接管时更新该文件；
- 不使用 heartbeat；
- 不自动过期；
- 不保存 session ID、pane ID 或复杂锁状态。

---

## 8. workflow-controller

### 8.1 定位

`workflow-controller` 是控制平面核心。

它负责把状态外置、阶段推进和确定性门禁组合成可恢复的任务控制平面。

### 8.2 职责

- 创建或接管任务；
- 读取和更新 `control.md`；
- 读取和更新 `controller.json`；
- 判断当前阶段和下一步；
- 判断直接路径或完整路径；
- 选择适用 Skill；
- 选择 executor；
- 判断任务串行或并行；
- 拆分相互独立的阶段级任务；
- 通过 `multi-agent-coordination` 分派；
- 收集最终回复或正式产物；
- 汇总、裁决、推进、回退或等待用户；
- 管理 VERIFY 失败后的受控循环；
- 在完成前执行规定门禁；
- 调用 Git 收尾流程。

### 8.3 不负责

Controller 不亲自完成：

- 需求分析；
- 方案设计；
- 编码；
- 代码评审；
- 测试；
- 专项验证；
- 调试推理。

它可调用本地确定性 Skill 或脚本完成 worktree、状态和收尾操作，但不把专项工作吸收到 Controller 中。

### 8.4 并行判断

并行判断职责属于 Controller。

仅在以下条件成立时并行：

- 至少两个独立任务；
- 无前后依赖；
- 无共享写入冲突；
- 每个任务边界可独立描述；
- 每个结果可独立返回；
- Controller 能汇总或裁决。

否则串行。

---

## 9. 多 Agent 两级结构

### 9.1 阶段级 Agent

所有由 `workflow-controller` 拆分的阶段级 Agent，无论是否跨宿主，都必须通过：

```text
workflow-controller
→ multi-agent-coordination
→ 可见 CLI pane
```

目的：

- 查看 Agent 进度；
- 管理不同模型；
- 支持人工观察；
- 支持人工介入；
- 保持同宿主和跨宿主一致的调度方式。

### 9.2 实施内部 Subagent

`subagent-driven-development` 只在具体实施 Agent 内部使用。

结构：

```text
实施 Agent
→ 宿主原生 Subagent
```

规则：

- 不经过 `multi-agent-coordination`；
- 不要求为内部 Subagent 建立可见 pane；
- 不直接修改 `control.md`；
- 不推进任务阶段；
- 不直接决定后续 Skill；
- 结果先返回实施 Agent；
- 实施 Agent 汇总后返回 Controller。

只有 `workflow-controller` 可以调用 `multi-agent-coordination`。

---

## 10. multi-agent-coordination

### 10.1 定位

它是可见 CLI Agent 的通信和运行通道管理能力，不负责流程决策。

### 10.2 运行环境

目标支持：

- Native Windows：PSMux
- WSL2：tmux
- Windows Terminal：视觉承载层

当前优先 Native Windows。

### 10.3 Pane 模型

- 一个 executor 对应一个长期存在的 pane；
- pane 标题使用 executor 名称；
- executor 不是业务角色；
- 同一宿主和模型可注册多个 executor；
- pane 在任务间复用。

上下文规则：

- 同一任务继续工作时可保留上下文；
- 同一任务中的新独立工作项可清理上下文；
- 新任务或 worktree 变化时，由用户在目标 pane 中手动启动或重启 CLI 并切换到目标工作目录；
- Harness 只使用已存在且已准备好的 pane / CLI 通道；
- 目标 pane、CLI 或工作目录不满足要求时暂停，不自动创建、重启或替换通道。

### 10.4 最小接口

```text
status
send
wait
capture
```

状态：

```text
idle
busy
waiting_user
unavailable
```

`wait` 只用于辅助等待。任务完成必须由 `capture` 返回的明确结束证据判断，例如唯一 completion marker 或等价的可验证结果；不增加 `completed` 状态。

### 10.5 不负责

- 不判断调用哪个 Skill；
- 不判断是否并行；
- 不定义业务角色；
- 不推进 `control.md`；
- 不处理实施内部 Subagent。

---

## 11. Executor 与 Routing

### 11.1 Executor 含义

Executor 是一个独立运行通道，不只是“宿主 + 模型”。

一个 executor 对应：

- 一个宿主；
- 一个模型配置；
- 一个独立 CLI 进程；
- 一个独立 pane；
- 一个独立上下文。

### 11.2 已注册 Executor

`config/executors.yaml` 当前结构：

```yaml
executors:
  codex-1:
    host: codex-cli
    model: default

  codex-2:
    host: codex-cli
    model: default

  codex-3:
    host: codex-cli
    model: default

  claude-1:
    host: claude-code
    model: default
```

`default` 表示使用宿主当前默认模型。实际注册项以 `config/executors.yaml` 为准。

### 11.3 Routing

`routing.yaml` 只为阶段级 Agent Skill 提供默认 executor。

当前配置：

```yaml
routing:
  defaults:
    brainstorming: codex-1
    writing-plans: codex-1
    reviewing-plans: codex-2
    executing-plans: codex-1
    systematic-debugging: codex-2
    code-review: codex-3
    verification-before-completion: codex-2
    writing-skills: codex-1

  parallel_pool:
    - codex-1
    - codex-2
    - codex-3
```

### 11.4 不进入 Routing 的 Skill

以下 Skill 不作为独立阶段级 Agent 路由：

- `workflow-controller`
- `multi-agent-coordination`
- `using-git-worktrees`
- `subagent-driven-development`
- `test-driven-development`
- `receiving-code-review`
- `finishing-a-development-branch`

原因：

- Controller 自身能力不能递归分派；
- coordination 是 Controller 的通信机制；
- worktree 和 branch finishing 属于当前任务上下文中的确定性操作；
- subagent-driven-development、TDD、receiving-code-review 是实施 Agent 内部方法。

### 11.5 路由规则

普通分派：

- 优先使用 Skill 默认 executor。

并行分派：

- Controller 可从 `parallel_pool` 中选择空闲 executor；
- 可将同一 Skill 的多个独立任务分配给不同 executor；
- 这是主动并行调度，不是故障降级。

失败处理：

- executor 不可用时不自动切换；
- 暂停；
- 用户选择重试、改用其他已注册 executor 或终止。

Controller 不得发明未注册 executor。

---

## 12. Skill 体系

目标 Skill 共 15 个。

### 12.1 总控与通信

1. `workflow-controller`
2. `multi-agent-coordination`

### 12.2 需求、方案与计划

3. `brainstorming`
4. `writing-plans`
5. `reviewing-plans`

### 12.3 环境与实施

6. `using-git-worktrees`
7. `executing-plans`
8. `subagent-driven-development`

### 12.4 开发方法

9. `test-driven-development`
10. `systematic-debugging`

### 12.5 评审、验证与收尾

11. `code-review`
12. `receiving-code-review`
13. `verification-before-completion`
14. `finishing-a-development-branch`

### 12.6 Harness 自维护

15. `writing-skills`

## 13. Skill 通用结构

```text
skill-name/
├── SKILL.md
├── scripts/              # 仅在需要确定性操作时存在
├── references/           # 按需
│   └── hosts/
│       ├── codex.md
│       └── claude-code.md
└── agents/               # 仅在宿主确有可选元数据时使用
```

### 13.1 SKILL.md 保存

- 触发条件；
- 不触发条件；
- 输入；
- 输出；
- 前置条件；
- 执行方法；
- 不变量；
- 失败条件；
- 与其他 Skill 的边界；
- 必要的自检。

### 13.2 scripts 保存

只存放：

- 确定性；
- 可重复；
- 幂等；
- 结构化输出；
- 不应依赖模型自由判断的操作。

主流程调用 Skill，不直接依赖内部脚本路径，除非 Skill 明确指示。

### 13.3 Host references 保存

- 宿主原生 Subagent 调用方式；
- 宿主工具名称映射；
- 工作目录传递；
- 权限差异；
- 结果捕获方式；
- 宿主限制。

公共 `SKILL.md` 不需要刻意限制在最低能力公分母，但宿主差异不能污染公共流程。

---

## 14. 各 Skill 的边界

### 14.1 brainstorming

用途：

- Goal、Changes、Verification 不完整；
- 需求、行为、范围或技术决策未解决。

方法要点：

- 先读上下文；
- 一次一个问题；
- 方案比较；
- 说明取舍；
- 获得明确确认。

不得：

- 所有任务都强制设计；
- 引入与当前宿主无关的可视化或后台辅助服务；
- 写入固定外部路径；
- 设计阶段 commit；
- 自行调用 `writing-plans`；
- 自行推进流程。

### 14.2 writing-plans

用途：

- 已有确认方案；
- 任务需要显式实施计划。

保留：

- 文件级计划；
- 依赖顺序；
- 小步可验证；
- 测试和文档；
- 风险和完成条件。

不得：

- 强制 TDD；
- frequent commits；
- 写入固定外部路径；
- 自行选择实施方式；
- 自行调用下一 Skill；
- 自行创建 worktree；
- 中间 commit。

### 14.3 reviewing-plans

职责：

- 独立复核已形成的设计或实施计划；
- 检查假设、边界、顺序、耦合、测试缺口和残余风险；
- 输出有证据的 findings；
- 不修改代码；
- 不自行推进流程。

不得引入固定 artifact 协议、未定义工具依赖、无依据的强对抗措辞或宿主专属命令。

### 14.4 using-git-worktrees

职责：

- 创建、验证或接管隔离 worktree；
- 创建任务分支；
- 记录 worktree、branch、base commit；
- 运行已有明确基线命令；
- 处理脏工作区和已存在 worktree 的安全检查。

不负责：

- 实施；
- commit；
- merge；
- push；
- cleanup。

### 14.5 executing-plans

职责：

- 实施 Agent 按确认计划执行；
- 保持范围；
- 执行工作项验证；
- 汇总实施结果。

不得：

- 依赖未定义 Skill 或命名空间；
- 强制改用 subagent-driven-development；
- 宿主枚举；
- 自行进入收尾流程；
- 中间 commit 要求。

### 14.6 subagent-driven-development

职责：

- 实施 Agent 内部拆分工作项；
- 使用当前宿主原生 Subagent；
- 结果汇总回实施 Agent。

必须保证：

- 不调用 `multi-agent-coordination`；
- 不创建可见阶段级 pane；
- 不修改 `control.md`；
- 不推进阶段；
- 不直接调用 branch finishing；
- 最终评审通过 `code-review` 语义处理；
- 宿主差异放入 host references。

### 14.7 test-driven-development

保留为可选方法。

Controller 或实施上下文决定是否采用。

不得写成：

- 所有改动都必须 TDD；
- 跳过必须记录理由；
- 未采用即失败。

### 14.8 systematic-debugging

用于根因不明的：

- 测试失败；
- 构建失败；
- 运行时异常；
- 回归；
- 环境问题。

保留系统化定位、最小实验、证据驱动和避免盲改。

不推进阶段。

### 14.9 code-review

职责：

- 评审确认需求和计划符合性；
- 检查正确性、边界、可维护性和测试；
- 输出明确 findings、严重程度和依据；
- 默认只读；
- 不修改代码；
- 不推进流程。

Agent 的选择和分派由 Controller 与 coordination 负责。

### 14.10 receiving-code-review

用于实施 Agent 处理评审反馈：

- 验证 finding 是否成立；
- 区分有效问题、误判和需澄清项；
- 修复有效问题；
- 返回处理结果。

不因 Reviewer 意见自动扩大范围。

### 14.11 verification-before-completion

仓库修改任务强制使用。

职责：

- 执行真实验证；
- 收集证据；
- 不接受“看起来正确”；
- 不接受未执行命令的推测；
- 验证失败时返回 Controller。

### 14.12 finishing-a-development-branch

职责范围：

- 提供完成后的分支处理选项；
- 支持保留、合并、推送、清理等动作。

但实际默认：

- 保留 branch 和 worktree；
- 不自动执行远端或破坏性操作；
- 需要用户明确选择。

VERIFY 通过后的本地 commit 是固定流程动作，不应被改写为频繁 commit。

### 14.13 writing-skills

用于 Harness 自维护：

- 新建或修改 Skill；
- 检查结构、触发条件、边界和引用；
- 必要时增加 scripts 或 references；
- 不进入普通开发任务主流程。

---

## 15. Agent 交接

不建立固定：

```text
assignments/
results/
```

不要求每次分派都生成包装文件。

Controller 交接内容：

- 任务说明；
- 适用 Skill；
- 工作目录；
- 必要输入；
- 预期输出；
- 只读或可写约束；
- 需要返回的证据。

Agent 返回：

- 最终文本；
- 或有持续价值的正式产物。

Controller：

- 捕获；
- 判断；
- 更新 `control.md`；
- 决定下一步。

不保存完整转录副本。

---

## 16. 用户级 Harness 目录

目标位置：

```text
%USERPROFILE%\.agent-harness
```

与宿主目录并列，不放入 `.codex` 或 `.claude` 内部。

目标结构：

```text
.agent-harness/
├── config/
│   ├── rules.md
│   ├── executors.yaml
│   └── routing.yaml
├── skills/
├── integrations/
│   ├── codex/
│   └── claude-code/
├── generated/
└── memory.md
```

按需生成的备份目录只在同步脚本需要保留旧宿主文件时创建。

---

## 17. 通用规则与宿主适配

### 17.1 通用规则真源

```text
.agent-harness/config/rules.md
```

当前包含：

- 中立、专业的输出风格；
- 前提和逻辑审查；
- 不迎合用户立场；
- 默认中文；
- GENERAL / DEVELOPER 模式规则。

### 17.2 规则适配器

当前只有 Codex 规则入口由 Harness 同步。Claude Code 作为可见 executor 使用，不接入全局 controller rules。

Codex 链路：

```text
config/rules.md
→ generated/codex/AGENTS.md
→ CODEX_HOME/AGENTS.md
```

Codex 路径解析：

```text
有 CODEX_HOME
→ 使用 CODEX_HOME

无 CODEX_HOME
→ 使用 $HOME\.codex
```

当前不增加统一 `hosts.yaml`。

同步或接入前：

- 验证目标目录存在；
- 内容变化时备份旧文件；
- 内容不变时不重复覆盖。

### 17.3 Skill 接入

Skill 内容不需要按宿主转换。

规则：

- `.agent-harness/skills` 是唯一 Skill 真源；
- Codex 通过 `$HOME\.agents\skills\<skill-name>` 访问；
- Claude Code 通过 `$HOME\.claude\skills\<skill-name>` 访问；
- 宿主目录中的子目录链接指向同一 Skill 真源，不复制内容；
- 不替换整个宿主 Skill 根目录；
- 不排斥宿主自身或其他个人 Skills；
- 新增、删除或重命名 Skill 时，需要相应建立或清理宿主链接。

---

## 18. 宿主集成层

宿主集成层负责：

- Codex 规则生成和同步；
- Skill 接入；
- Claude Code provider 启动入口；
- 使用已存在 executor 通道完成 status/send/wait/capture；
- 结果捕获；
- Memory Recorder 脚本入口；
- 宿主权限和 Hook 对接。

宿主集成层不负责：

- 流程阶段判断；
- Skill 选择；
- 业务角色；
- 模型成本推断；
- 任务裁决；
- 自动创建、重建、重启或替换 pane / CLI；
- 将全局 controller rules 接入 Claude Code。

---

## 19. Memory

### 19.1 定位

Memory 只是经验台账。

不是：

- 运行时检索系统；
- 自动上下文注入；
- 自动规则生成；
- Agent 默认必读内容；
- 任务状态。

### 19.2 位置

全局：

```text
~/.agent-harness/memory.md
```

项目：

```text
<project>/.harness/memory.md
```

### 19.3 最小格式

```markdown
## YYYY-MM-DD — Title

经验内容

状态：recorded | promoted | discarded
```

### 19.4 记录方式

Manual：

- 用户明确触发。

Auto：

- Harness 管理的 Agent 调用结束后；
- 由 Controller 在阶段级 Agent capture 完成后按需调用 `integrations/memory/record-memory.ps1 -Source auto`；
- 不依赖 COMPLETE、BLOCKED 或 FAILED。

直接宿主会话默认不自动记录；没有 Controller 调用时使用手动记录。

### 19.5 生效方式

Memory 不自动生效。

需要人工将经验提升为：

- 通用规则；
- 项目约束；
- Skill；
- 宿主配置。

Harness 不内置自动 promotion 流程。

---

## 20. 权限与高风险操作

普通项目内操作沿用宿主权限机制，包括：

- 读取项目；
- worktree 内写入；
- 本地构建；
- 本地测试；
- 本地静态分析。

以下类别必须显式人工确认：

- push；
- merge 到共享分支；
- rebase 共享历史；
- 删除 branch；
- 删除 worktree；
- 强制 Git 操作；
- 修改项目外文件；
- 读取或写入 secrets；
- 安装系统软件；
- 修改系统配置；
- 生产环境操作；
- 远端资源变更；
- 不可逆或破坏性命令。

最终拦截实现可组合：

- 宿主权限；
- Hook；
- Skill 前置检查；
- 确定性脚本；
- fail-closed。

---

## 21. Loop Engineering

不增加独立 `loop-engineering` 模块。

循环自然存在于：

```text
IMPLEMENT
→ VERIFY
→ 失败证据
→ IMPLEMENT
→ VERIFY
```

要求：

- 每轮基于新证据；
- 不盲目重复；
- 不未经确认扩大需求或方案；
- 触及已确认边界时返回 UNDERSTAND。

---

## 22. 明确排除

当前不引入：

- 固定业务角色层；
- architect / developer / reviewer / verifier 等角色文件；
- 项目注册表；
- project ID；
- Git common directory 作为状态中心；
- assignment/result 包装协议；
- intent × risk 复杂矩阵；
- Harness benchmark 或评测平台；
- Memory 自动检索和自动注入；
- Memory 自动生效；
- 自动 executor fallback；
- heartbeat；
- 自动锁过期；
- 分布式锁；
- 后台不可见的阶段级跨宿主 Agent；
- 多个 Agent 并行写同一 worktree；
- 自动 merge、push、rebase 或 cleanup；
- 每个阶段都固定生成文档；
- 所有任务都强制 brainstorming、完整计划或 TDD；
- frequent commits；
- 固定外部路径；
- 整份 Skill 的宿主分叉版本。

---

## 23. 实施状态与运行真源

本文档不再维护本机的软件版本、安装状态、临时测试结果或逐项完成清单。

判断当前 Harness 状态时，应直接检查：

- `config/rules.md`、`config/executors.yaml`、`config/routing.yaml`；
- `skills/` 下的实际 Skill 与引用文件；
- `integrations/` 下的宿主接入实现；
- Codex 规则入口以及 Codex / Claude Code 的 Skill 发现目录；
- 项目内 `.harness/tasks/<task-id>/control.md` 与 `controller.json`；
- 实际可用的 executor、pane 和宿主 CLI。

本文只保留稳定架构、职责边界和关键设计决策。环境变化、工具升级和临时可用性不需要回写本文。

---

## 24. Skill 维护与审计要求

负责新建、修改、迁移或审计 Skill 的 Agent 应：

1. 读取目标 Skill 的完整 `SKILL.md` 及其辅助文件、脚本和引用。
2. 检查跨 Skill 依赖、未定义命名空间、固定路径、工具名和宿主假设。
3. 以实际运行文件为直接依据，并用本文核对稳定架构和职责边界。
4. 优先保留有效内容，不为了保留旧写法牺牲本地边界。
5. 不新增未确认的 Skill、固定业务角色或重复控制层。
6. 不让专项 Skill 推进全局流程或修改 `control.md`。
7. 不让内部 Subagent 调用 `multi-agent-coordination`。
8. 不引入中间 commit、frequent commits 或宿主分叉版完整 Skill。
9. 公共逻辑写在 `SKILL.md`，宿主差异写在 host reference 或 integration。
10. 修改后执行交叉引用、边界、编码和宿主可用性检查。

报告至少包含：

- 修改文件；
- 修改原因；
- 保留、删除或改写的内容；
- 新增依赖；
- 验证结果；
- 未解决问题；
- 需要人工确认的架构变化。

---

## 25. 推荐维护顺序

对现有 Harness 做变更时，优先采用以下顺序：

```text
读取实际运行文件
→ 明确受影响边界
→ 进行最小修改
→ 检查交叉引用与职责重叠
→ 在相关宿主中验证
→ 记录结果与未决项
```

只有架构、职责边界或关键设计决策发生变化时，才同步更新本文档。

---

## 26. Skill 维护完成判定

Skill 变更只有在以下条件全部成立时才算完成：

- 目标 Skill 的 frontmatter 名称与目录一致；
- 不引用已删除 Skill、未定义命名空间或失效固定路径；
- 不强制中间 commit、完整设计、完整计划或 TDD；
- 专项 Skill 不推进全局阶段；
- 只有 Controller 更新 `control.md`；
- 只有 Controller 调用 `multi-agent-coordination`；
- 内部 Subagent 的边界明确；
- host-specific 内容已隔离；
- 辅助文件引用有效；
- 不向宿主暴露其不支持的功能；
- Skill 之间没有明显重复职责；
- 没有因精简导致必要职责缺失；
- 相关宿主能够发现并正确加载变更后的 Skill。

---

## 27. 设计结论

本 Harness 的核心结构是：

```text
人工模式切换
+ 用户级通用规则真源
+ 单一 Skill 真源
+ 薄 workflow-controller
+ 可见 multi-agent-coordination
+ 宿主原生内部 Subagent
+ 项目级 control.md
+ 强制 worktree
+ VERIFY 门禁
+ 被动 Memory 台账
```

后续工作属于维护、集成和验证，不应继续增加新的架构层，除非实际运行证据证明当前结构无法满足已确认目标。
