# Dubag 审查报告 — v6

- **审查时间**: 2026-06-13
- **Git HEAD**: `b046dd8` — *feat: 新增许可证文件，明确版权和使用条款*
- **工作区状态**: 干净（无未提交修改）
- **Minecraft 版本**: 1.21.1 (pack_format 48)
- **审查触发**: 新一轮全面 dubag，检查自 v5 以来的代码变更

> **对照上一份报告**: [dubag_v5.md](./dubag_v5.md)
>
> **对照函数健康基线 v5**: [函数健康基线记录_v5.md](./函数健康基线记录_v5.md)

---

## 变更概览

### 从上一次审查 (`e475d02`) 到当前 HEAD (`b046dd8`) 的提交链

| 提交 | 说明 |
|:----:|------|
| `de97ca1` | 修复命令执行上下文，确保玩家在倒计时期间正确触发音效和标题 |
| `d38ab74` | 修复命令执行上下文，确保音效和标题在正确的玩家位置触发 |
| `e50ac0b` | 新增队伍选择功能，添加相关传送和提示逻辑 |
| `b046dd8` | 新增许可证文件 |

### 变更文件清单（自 e475d02 以来）

| 文件 | 变更类型 | 说明 |
|------|:--------:|------|
| `game/start_button_l.mcfunction` | 🟡 已修改 | 音效调用 `at @a` → `as @a at @s` |
| `sounds/click_button.mcfunction` | 🟡 已修改 | `@a` → `@s`（已提交） |
| `sounds/exp_orb_pickup.mcfunction` | 🟡 已修改 | `@a` → `@s`（已提交） |
| `sounds/levelup.mcfunction` | 🟡 已修改 | `@a` → `@s`（已提交） |
| `sounds/villager_no.mcfunction` | 🟡 已修改 | `@a` → `@s`（已提交） |
| `scoreboard/reset_gd656killicon.mcfunction` | 🟡 已修改 | 添加 `0` 参数 |
| `teams/join_battlefield.mcfunction` | 🆕 新文件 | 队伍传送逻辑 |
| `teams/team_start_0_give.mcfunction` | 🆕 新文件 | 队伍选择器发放逻辑 |
| `tick.mcfunction` | 🟡 已修改 | 追加 `team_start_0_give` 调用 |
| `LICENSE` | 🆕 新文件 | 许可证（非代码） |

### 架构变更说明

**音效系统架构调整**（`de97ca1` + `d38ab74`）：

音效系统从"音效文件用 `@a` 直接播放给所有玩家"改为"音效文件用 `@s`，调用者负责提供 `as @a at @s` 上下文"。具体变化：

- `start_button_l.mcfunction` 中 7 处音效调用从 `run function game:sounds/xxx` 改为 `as @a at @s run function game:sounds/xxx`
- 所有 4 个音效文件的 `@a` 改为 `@s`（之前 v5 报告中的工作区回退问题已被提交固定化）
- 这意味着 **音效文件本身不再包含目标选择逻辑**，播放范围完全由调用者决定

---

## 上次报告问题状态更新

### ✅ P14 — 音效目标 `@s` 导致倒计时音效无声（已修复）

[P14 详情见 v5 报告](./dubag_v5.md#-P14严重--音效目标选择器-s-导致所有倒计时音效无声)

**代码变更**: `start_button_l.mcfunction` 中所有音效调用添加了 `as @a at @s` 前缀。
- 旧: `if score CTD game_start_ctd matches 120 run function game:sounds/click_button`
- 新: `if score CTD game_start_ctd matches 120 as @a at @s run function game:sounds/click_button`

**状态**: ✅ **已修复**。现在 tick 上下文中音效函数能正确为每个玩家执行。

**⚠️ 附带来的行为变更**: `join_attacker/defender/spectator.mcfunction` 和 `leave_team.mcfunction` 直接调用音效文件（`function game:sounds/exp_orb_pickup`）而未添加 `as @a at @s`。由于这些函数在玩家上下文（interaction `on target`）中执行，`@s` 唯一匹配当前操作的玩家。旧行为（`@a`）会播放给**所有玩家**，新行为仅播放给**操作的玩家本人**。确认这是否为预期行为。

确认标签: `[Confirmed: P14_FIXED]`

### 🔴 P8 — 防重复点击保护（仍未修复）

[P8 详情见 v1 报告](./dubag_v2.md#P8-倒计时期间无防重复点击保护)

**状态**: ❌ **仍未修复**。`press_start_button.mcfunction` 中仍然没有 `if score CTD game_start_ctd matches 0` 检查：

```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140
```

**影响**: 玩家可在倒计时期间重复点击按钮，每次将 CTD 重置回 140，变相延长倒计时。

**可能的修复方案**: 在条件中追加 `if score CTD game_start_ctd matches 0`：
```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 if score CTD game_start_ctd matches 0 run scoreboard players set CTD game_start_ctd 140
```

确认标签: `[Pending: P8]`

### 🟢 P13 — `start_button_l.mcfunction` 第26行无 game_state 过滤（仍未修复）

[P13 详情见 v5 报告](./dubag_v5.md#-P13-start_button_lmcfunction-第26行无-game_state-过滤)

**状态**: ❌ **仍未修复**。第26行 `execute if score CTD game_start_ctd matches 0..20 run scoreboard players reset CTD game_start_ctd` 在 game_state=1 时仍会每 tick 检查并可能重置 CTD（虽然此时 CTD 通常为 0，逻辑上无害但冗余）。

确认标签: `[Pending: P13]`

### 🟢 P12 — 重部署完成时无音效反馈（仍未修复）

[P12 详情见 v5 报告](./dubag_v5.md#-P12-redeploy_tickmcfunction-重部署完成时无音效反馈)

**状态**: ❌ **仍未修复**。

确认标签: `[Pending: P12]`

### 🟡 P17 — interaction 每 tick 无条件 `data merge response`（仍未修复）

[P17 详情见 v5 报告](./dubag_v5.md#-P17-interactionstartmcfunction-每-tick-无条件执行-data-merge-entity)

**状态**: ❌ **仍未修复**。

确认标签: `[Pending: P17]`

### 🟢 P18 — `load_scoreboard_settings` 缺少注释说明（仍未修复）

[P18 详情见 v5 报告](./dubag_v5.md#-P18-load_scoreboard_settingsmcfunction-缺少-ctd-初始化后的备注说明)

**状态**: ❌ **仍未修复**。

确认标签: `[Pending: P18]`

### 🟢 P16 — `start_button_l` CTD=20 极端时序风险（仍存在）

[P16 详情见 v5 报告](./dubag_v5.md#-P16-start_button_lmcfunction-ctd20-的-a-与-function-混合调用可能产生时序问题)

**状态**: ⚠️ 仍存在但影响极轻微。

确认标签: `[Pending: P16]`

---

## 本次审查发现的新问题

### 🔴 P19（严重）— `join_battlefield.mcfunction` 是孤立函数，未被任何代码调用

**文件**: `data/game/function/teams/join_battlefield.mcfunction`

**代码**:
```mcfunction
execute as @a[team=attacker] at @s run tp @s -1481.33 200.00 1874.86
execute as @a[team=spectator] at @s run tp @s -229.47 106.00 -32.37
execute as @a[team=defender] at @s run tp @s -1485.70 199.00 1911.36
execute as @a[team=unselected] at @s run title @s title {"text":"你未选择队伍","color":"gold","bold":true}
```

**问题描述**:

此函数在提交 `e50ac0b` 中被创建，但**未被项目中的任何 mcfunction 或标签文件引用**。搜索整个代码库未找到任何调用点。

- `tick.mcfunction` 中无此函数的调用
- `load.mcfunction` 中无此函数的调用
- 其他函数中无此函数的调用
- `team_start_0_give.mcfunction` 也与此无关

**影响**:
- 所有 4 条传送/提示命令完全不会执行
- 玩家加入队伍后不会被传送到战场坐标
- `unselected` 队伍玩家的"未选择队伍"提示也不会触发
- 这可能是"队伍选择功能"的核心逻辑，缺失意味着整个功能未生效

**可能的修复方案**:

方案一 — 在合适的时机调用此函数：
- 在 `tick.mcfunction` 中合适的位置加入 `function game:teams/join_battlefield`
- 或在队伍选择完成后的回调中调用（如果存在按钮交互）
- 或创建新的 interaction 函数在玩家点击队伍选择器后调用

方案二 — 如果此函数应通过外部命令/其他数据包调用，需在文档中注明。

确认标签: `[Pending: P19]`

---

### 🟡 P20（中等）— 音效架构变更导致 join/leave 音效改为仅播放给操作者

**文件**: 
- `data/game/function/teams/join_attacker.mcfunction`
- `data/game/function/teams/join_defender.mcfunction`
- `data/game/function/teams/join_spectator.mcfunction`
- `data/game/function/teams/leave_team.mcfunction`

**代码**（以下每个函数第1行）:
```mcfunction
function game:sounds/exp_orb_pickup   ; join_attacker, join_defender, join_spectator
function game:sounds/villager_no      ; leave_team
```

**问题描述**:

音效文件从 `@a` 改为 `@s` 后，这四个函数仍然使用 `function game:sounds/xxx` 形式直接调用，没有任何前缀包装。：

- `join_attacker/defender/spectator` 在第1行调用 `function game:sounds/exp_orb_pickup`
- `leave_team` 在第1行调用 `function game:sounds/villager_no`

这些函数通常在 interaction `on target` 上下文中执行（由客户端交互触发），此时 `@s` 唯一匹配当前点击交互的玩家。这意味着：
- **旧行为**：任何人加入/离开队伍时，**所有玩家**都听到音效
- **新行为**：仅**操作者本人**听到音效

**影响**:
- 同一队伍的其他成员无法通过音效感知有新队友加入
- 观战者无法听到队伍变动声音
- 如果这是预期行为，则没有问题。但如果需要恢复旧行为，需添加包装。

**可能的修复方案**:

方案一（恢复旧行为）— 为四个函数添加 `as @a at @s` 包装：
```mcfunction
execute as @a at @s run function game:sounds/exp_orb_pickup
team join attacker @s
tellraw @s ...
```

方案二 — 如果 `@s` 行为（仅操作者听到）是预期设计，则忽略此问题，但建议在音效文件中添加注释明确说明 `@s` 的设计意图。

确认标签: `[Pending: P20]`

---

### 🟡 P21（中等）— `team_start_0_give.mcfunction` 在 game_state=0 时给所有玩家（含 spectator）发放队伍选择器

**文件**: `data/game/function/teams/team_start_0_give.mcfunction`

**代码**:
```mcfunction
    execute if score state game_state matches 0 as @a unless items entity @s hotbar.0 kubejs:team_selector run item replace entity @s hotbar.0 with kubejs:team_selector
    execute if score state game_state matches 1 as @a[team=unselected] unless items entity @s hotbar.0 kubejs:team_selector run item replace entity @s hotbar.0 with kubejs:team_selector
    kill @e[type=item,nbt={Item:{id:"kubejs:team_selector"}}]
```

**问题描述**:

第1行：`game_state matches 0` 时对 **`@a`（所有玩家）** 发放队伍选择器。这包括已经在 `spectator` 队伍的玩家。

- 观战玩家理论上不应需要队伍选择器（他们已经选择了队伍）
- 如果 Spectator 玩家无意间使用队伍选择器选择 attacker/defender，他们会被移出 spectator 队伍，可能引发未预期的状态

**影响**:
- spectator 玩家可能无意中离开观战模式加入攻防
- 仅在 game_state=0（游戏未开始）时受影响

**可能的修复方案**:

在第1行中排除 spectator 队伍：
```mcfunction
    execute if score state game_state matches 0 as @a[team=!spectator] unless items entity @s hotbar.0 kubejs:team_selector run item replace entity @s hotbar.0 with kubejs:team_selector
```

确认标签: `[Pending: P21]`

---

### 🟢 P22（轻微）— `team_start_0_give.mcfunction` 每 tick 执行 `item replace` 的性能影响

**文件**: `data/game/function/teams/team_start_0_give.mcfunction`

**问题描述**:

此函数每 tick 执行：
1. `as @a` 遍历所有玩家，检查并替换 `hotbar.0` 的物品
2. 当 game_state=1 时，检查所有 `team=unselected` 玩家
3. 每 tick 执行 `kill @e[type=item,...]` 清理掉落物

对于 20 名玩家的服务器，此函数每分钟执行 **1200 次**（20 tick/秒 × 60 秒）。尽管 `unless items` 检查减少了许多冗余操作，但随着玩家数量增加，性能开销线性增长。

**影响**:
- 在低配服务器或高玩家数量时可能造成 tick 时间增加
- `kill` 命令每 tick 扫描所有掉落物实体，可能影响掉落物较多的场景

**可能的修复方案**:

方案一 — 在函数入口添加条件，确保只在需要时才执行完整逻辑：
```mcfunction
    execute if score state game_state matches 0 if score state game_state matches 1 run function game:teams/team_start_0_give_logic
```
（但实际上 game_state 为 0 或 1 时才需要执行，这个条件永远是 true —— 需要更精细的控制）

方案二 — 降低检查频率，如每 5 tick 执行一次（需要独立的计数器/时间段逻辑）。

方案三 — 替代方案：在玩家加入/重载/特定事件时一次性发放，而非每 tick 检查。

确认标签: `[Pending: P22]`

---

### 🟢 P23（轻微）— `start_button_l.mcfunction` 中 `as @a at @s` 导致音效函数 N 倍调用

**文件**: `data/game/function/game/start_button_l.mcfunction`

**问题描述**:

新的音效调用方式 `as @a at @s run function game:sounds/click_button` 对**每个玩家**独立执行一次音效函数。对于 20 名玩家的服务器：

- CTD=120 时：`click_button` 函数运行 20 次（每人一次）
- CTD=100 时：同上 20 次
- CTD=80/60/40 时：各 20 次
- CTD=140 时：`exp_orb_pickup` 运行 20 次
- CTD=20 时：`levelup` 运行 20 次

总计：**一个完整的倒计时周期产生 `20 × 7 = 140` 次函数调用**（旧方案仅 `7` 次）。

**影响**:
- 在大部分服务器上影响可忽略（单个 `playsound` 命令极轻量）
- 仅在高延迟/低 TPS 场景下有理论影响

**可能的修复方案**:

对于音效这种不需要每玩家独立上下文的操作，可以考虑在音效函数内部使用 `@a` 替代 `@s`，并在调用处恢复为 `run function`（回到旧架构）。但此方案与 P14 已经做出的修复冲突。

或者，保持现状 — 此问题仅在高负载下才可能可感知。

确认标签: `[Pending: P23]`

---

### 🟢 P24（轻微）— `reset_gd656killicon.mcfunction` 缺少新行结尾

**文件**: `data/game/function/scoreboard/reset_gd656killicon.mcfunction`

**问题描述**:

文件末尾缺少换行符（no newline at end of file）。在 Git diff 中显示为 `\ No newline at end of file`。

**影响**:
- 纯粹的风格问题
- 某些文本编辑器/工具可能发出警告
- Minecraft 函数解析器通常不受影响

确认标签: `[Pending: P24]`

---

### 🟢 P25（轻微）— `join_battlefield.mcfunction` 和 `team_start_0_give.mcfunction` 存在前导空格

**文件**: 
- `data/game/function/teams/join_battlefield.mcfunction`
- `data/game/function/teams/team_start_0_give.mcfunction`

**问题描述**:

这两个新文件的每行开头都有 4 个空格缩进。项目中的其他 mcfunction 文件（如 `start_button_l.mcfunction`, `press_start_button.mcfunction`）没有前导空格。风格不一致。

`join_battlefield.mcfunction`:
```mcfunction
<    >execute as @a[team=attacker] at @s run tp @s -1481.33 200.00 1874.86
```

`team_start_0_give.mcfunction`:
```mcfunction
<    >execute if score state game_state matches 0 as @a unless items entity @s hotbar.0 kubejs:team_selector run item replace entity @s hotbar.0 with kubejs:team_selector
```

**影响**: 纯风格问题，不影响功能。

确认标签: `[Pending: P25]`

---

## 声音文件 `@s` 架构变更的影响矩阵

以下表格总结音效文件改为 `@s` 后所有调用的行为变化：

| 调用者 | 调用方式 | 旧行为（`@a`） | 新行为（`@s`） | 修复状态 |
|--------|:--------:|:--------------:|:--------------:|:--------:|
| `start_button_l` (CTD=140) | `as @a at @s run function exp_orb_pickup` | 所有玩家听到 | 所有玩家听到 ✅ | ✅ 已修复 |
| `start_button_l` (CTD=120/100/80/60/40) | `as @a at @s run function click_button` | 所有玩家听到 | 所有玩家听到 ✅ | ✅ 已修复 |
| `start_button_l` (CTD=20) | `as @a at @s run function levelup` | 所有玩家听到 | 所有玩家听到 ✅ | ✅ 已修复 |
| `join_attacker` | `function exp_orb_pickup` | 所有玩家听到 | **仅操作者听到** ⚠️ | ❌ 未包装 |
| `join_defender` | `function exp_orb_pickup` | 所有玩家听到 | **仅操作者听到** ⚠️ | ❌ 未包装 |
| `join_spectator` | `function exp_orb_pickup` | 所有玩家听到 | **仅操作者听到** ⚠️ | ❌ 未包装 |
| `leave_team` | `function villager_no` | 所有玩家听到 | **仅操作者听到** ⚠️ | ❌ 未包装 |

---

## 已确认修复的问题汇总

| 问题 | 文件 | 状态 | 确认标签 |
|:----:|------|:----:|:--------:|
| P14 | 音效系统 | ✅ 已修复（声音文件 `@s` + 调用方 `as @a at @s`） | `[Confirmed: P14_FIXED]` |
| P11 | `load_scoreboard_settings` | ✅ 已修复（v5 确认） | `[Confirmed: P11_FIXED]` |
| P10 | `levelup` 命名空间 | ✅ 已修复（v5 确认） | `[Confirmed: P10_NAMESPACE_FIXED]` |
| P6 | `click_button` 命名空间 | ✅ 已修复（v2） | `[Confirmed: P6_FIXED_VERIFIED]` |
| P0 | `start_button_l` 逻辑 | ✅ 已修复（v3） | `[Confirmed: P0_FIXED_VERIFIED]` |

---

## 仍存在的问题汇总

| 严重程度 | 编号 | 文件 | 说明 | 确认标签 |
|:--------:|:----:|------|------|:--------:|
| 🔴 严重 | **P19** 🆕 | `join_battlefield` | **孤立函数，无处调用** | `[Pending: P19]` |
| 🔴 严重 | **P8** | `press_start_button` | 防重复点击保护被移除 | `[Pending: P8]` |
| 🟡 中等 | **P20** 🆕 | `join_*/leave_team` | 音效 `@s` 导致仅操作者听到 join/leave 音效 | `[Pending: P20]` |
| 🟡 中等 | **P21** 🆕 | `team_start_0_give` | game_state=0 时给 spectator 也发选择器 | `[Pending: P21]` |
| 🟡 中等 | **P17** | `interaction/start/redeploy` | 每 tick 无条件 `data merge response` | `[Pending: P17]` |
| 🟡 中等 | **P15** | `press_start_button` | 点击后无即时音效反馈 | `[Pending: P15]` |
| 🟢 轻微 | **P13** | `start_button_l` line 26 | 无 `game_state` 过滤 | `[Pending: P13]` |
| 🟢 轻微 | **P12** | `redeploy_tick` | 重部署完成时无音效反馈 | `[Pending: P12]` |
| 🟢 轻微 | **P16** | `start_button_l` CTD=20 | 极端时序风险（极小概率） | `[Pending: P16]` |
| 🟢 轻微 | **P18** | `load_scoreboard_settings` | 缺少 CTD 初始化移除的注释说明 | `[Pending: P18]` |
| 🟢 轻微 | **P22** 🆕 | `team_start_0_give` | 每 tick `item replace` 性能开销 | `[Pending: P22]` |
| 🟢 轻微 | **P23** 🆕 | `start_button_l` | `as @a at @s` 导致音效函数 N 倍调用 | `[Pending: P23]` |
| 🟢 轻微 | **P24** 🆕 | `reset_gd656killicon` | 文件末尾缺少换行符 | `[Pending: P24]` |
| 🟢 轻微 | **P25** 🆕 | `join_battlefield`, `team_start_0_give` | 前导空格风格不一致 | `[Pending: P25]` |

---

## 已忽略的问题（仍存在于代码库中，不再重复审查）

| 问题 | 文件 | 说明 | 状态 |
|:----:|------|------|:----:|
| P2 | `pack.mcmeta` | `max_format: [101, 1]` 格式 | 🟡 已忽略 |
| P3 | `帮助/项目概览.md` | 文档与实际不匹配 | 🟡 已忽略 |
| P4 | `press_start_button.mcfunction` | 无队伍过滤开始按钮 | 🟡 已忽略 |
| P5 | `detect_redeploy_button.mcfunction` | 无队伍过滤重部署按钮 | 🟡 已忽略 |
| P9 | `start_button_l.mcfunction` | 首次进入职业标题未显示 | 🟢 已忽略 |

> 上述问题如需修复可参考 [dubag_v2.md](./dubag_v2.md) 中的方案。

---

## 总结

**核心发现**:

1. 🔴 **P19 — `join_battlefield.mcfunction` 是孤立函数**：新增的队伍传送功能核心文件**未被任何代码调用**，整个队伍选择后的传送逻辑完全未生效。这是本次审查最严重的新问题。

2. ✅ **P14 音效问题已修复**：音效系统架构从"`@a` 音效文件"改为"`@s` 音效文件 + 调用方 `as @a at @s`"，`start_button_l` 中 7 处音效调用已正确包装，倒计时音效应能正常播放。

3. ⚠️ **P20 音效架构变更的附带影响**：`join_*/leave_team` 函数未适配新架构，音效从"播放给所有玩家"降为"仅播放给操作者"。

4. ❌ **P8 防重复点击保护仍未修复**：`press_start_button` 缺少 CTD 检查，玩家可重复重置倒计时——这是存在最久的未修复问题（自 v1 起）。

5. 🆕 **P21 spectator 被发放队伍选择器**：`team_start_0_give` 在 game_state=0 时对所有玩家（含 spectator）发放选择器，可能导致 spectator 意外离开观战模式。

| 严重程度 | 数量 | 问题编号 |
|:--------:|:----:|:--------:|
| ✅ 已修复（本次确认） | 1 | **P14** |
| ✅ 已修复（先前确认） | 4 | P0, P6, P10, P11 |
| 🔴 严重（当前活跃） | 2 | **P19 🆕**, **P8** |
| 🟡 中等（当前活跃） | 4 | **P20 🆕**, **P21 🆕**, **P17**, **P15** |
| 🟢 轻微（当前活跃） | 7 | **P22 🆕**, **P23 🆕**, **P24 🆕**, **P25 🆕**, **P12**, **P13**, **P16**, **P18** |
| 🟡 已忽略 | 4 | P2, P3, P4, P5 |
| 🟢 已忽略 | 1 | P9 |

**建议修复优先级**: **P19** → **P8** → **P20** → **P21** → P17 → P15 → P18 → P13 → P12 → P22 → P23 → P24 → P25 → P16
