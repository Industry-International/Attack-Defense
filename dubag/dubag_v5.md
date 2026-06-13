# Dubag 审查报告 — v5

- **审查时间**: 2026-06-13
- **Git HEAD**: `e475d02` — *feat: 添加职业选择功能，处理未选择职业的玩家交互*
- **工作区状态**: 4 个音效文件有**未提交的修改** (`@a` → `@s`)
- **Minecraft 版本**: 1.21.1 (pack_format 48)
- **审查触发**: 用户反馈点击开始游戏后音效没有正常播放

> **对照上一份报告**: [dubag_v4.md](./dubag_v4.md)
>
> **对照函数健康基线**: [函数健康基线记录_v5.md](./函数健康基线记录_v5.md)

---

## 变更概览

### 从上一次审查 (`e249485`) 到当前 HEAD (`e475d02`) 的提交链

| 提交 | 说明 |
|:----:|------|
| `c6024ce` | 更新 `press_start_button.mcfunction` — 移除 CTD=0 检查（**P8 被回退**） |
| `05137da` | 移除 `load_scoreboard_settings.mcfunction` 中的 CTD 初始化（**P11 被修复**） |
| `c79d1ef` | 倒计时结束时清除物品 + 给予职业选择器 |
| `2899457` | CTD=20 添加职业选择 + 清除未选择职业玩家 |
| `c3a178a` | 添加 `reset_gd656killicon.mcfunction` |
| `4121811` | 音效播放目标 `@s` → `@a`（**正确修复了音效问题**） |
| `e475d02` | 重部署按钮按职业/无职业分流 + `no_job.mcfunction` |

### 工作区未提交的变更（当前问题根源）

```diff
- playsound minecraft:ui.button.click master @a ~ ~ ~ 1 1
+ playsound minecraft:ui.button.click master @s ~ ~ ~ 1 1
```
（4 个音效文件全部从 `@a` 回退为 `@s`）

### 变更文件清单

| 文件 | 变更类型 | 审查范围 |
|------|:--------:|----------|
| `sounds/click_button.mcfunction` | 🟡 工作区未提交 | + 调用者 `start_button_l` |
| `sounds/exp_orb_pickup.mcfunction` | 🟡 工作区未提交 | + 调用者 `start_button_l`, `join_*` |
| `sounds/levelup.mcfunction` | 🟡 工作区未提交 | + 调用者 `start_button_l` |
| `sounds/villager_no.mcfunction` | 🟡 工作区未提交 | + 调用者 `leave_team` |
| `game/press_start_button.mcfunction` | ✅ 已提交 | **P8 防重复检查被移除** |
| `game/start_button_l.mcfunction` | ✅ 已提交 | CTD=20 新增 clear + kubejsadmin |
| `redeploy/detect_redeploy_button.mcfunction` | ✅ 已提交 | 分流 job/no_job 路径 |
| `redeploy/no_job.mcfunction` | 🆕 新文件 | 无职业提示 |
| `scoreboard/load_scoreboard_settings.mcfunction` | ✅ 已提交 | 移除 CTD=0 初始化 |
| `scoreboard/reset_gd656killicon.mcfunction` | 🆕 新文件 | 模组专用命令 |

---

## 上次报告问题状态更新

### ✅ P11 — `/reload` 时 CTD 重置（已修复）

[P11 详情见 v4 报告](./dubag_v4.md#-P11-reload-时-load_scoreboard_settings-无条件重置-ctd可能中断倒计时)

- **旧**: `load_scoreboard_settings.mcfunction` 第4行 `scoreboard players set CTD game_start_ctd 0`
- **新**: 该行已在提交 `05137da` 中**移除**
- **状态**: ✅ **已修复**。现在 `/reload` 不再重置 CTD，倒计时可正常继续。
- **注意事项**: 首次加载世界时 CTD 未被显式初始化为 0。但在 Minecraft 中，未初始化的分数等价于 0，且 `press_start_button` 中 `run scoreboard players set CTD game_start_ctd 140` 会直接创建条目，因此功能不受影响。

确认标签: `[Confirmed: P11_FIXED]`

### ❌ P10 — `levelup.mcfunction` 缺少 `minecraft:` 前缀（已在提交中修复，但工作区未保留）

[P10 详情见 v3 报告](./dubag_v3.md#-P10-levelupmcfunction--缺少-minecraft-命名空间前缀)

- **提交 `4121811` 中**: 已修复为 `playsound minecraft:entity.player.levelup master @a ~ ~ ~ 0.5 1` ✅
- **工作区现状**: 保留了 `minecraft:` 前缀（正确），但 `@a` → `@s`（错误）
- **状态**: ⚠️ 命名空间问题**已修复**，但目标选择器问题导致实际无声

确认标签: `[Confirmed: P10_NAMESPACE_FIXED]`

### ❌❌ P8 — 防重复点击保护（被回退，严重回归）

[P8 详情见 v1 报告](./dubag_v1.md#P8-倒计时期间无防重复点击保护)

- **提交 `7f84ea9`**: 已修复 ✅ — 添加了 `if score CTD game_start_ctd matches 0`
- **提交 `c6024ce`**: **被回退** ❌ — 该条件被移除
- **当前代码**:
  ```mcfunction
  execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140
  ```
- **状态**: 🔴 **严重回归！P8 重新生效**

确认标签: `[Pending: P8_REGRESSION]`

### 🔴 P13 — `start_button_l.mcfunction` 第26行无 game_state 过滤（仍未修复）

[P13 详情见 v4 报告](./dubag_v4.md#-P13-start_button_lmcfunction-第24行--matches-020-在游戏进行中仍每-tick-执行)

- **状态**: ❌ 仍未修复
- **当前代码** (第26行):
  ```mcfunction
  execute if score CTD game_start_ctd matches 0..20 run scoreboard players reset CTD game_start_ctd
  ```

确认标签: `[Pending: P13]`

### 🟢 P12 — 重部署完成时无音效反馈（仍未修复）

[P12 详情见 v4 报告](./dubag_v4.md#-P12-redeploy_tickmcfunction-重部署完成时无音效反馈)

- **状态**: ❌ 仍未修复
- **相关**: 当 P14 修复后，可在 `redeploy_ctd=0` 时增加音效调用

确认标签: `[Pending: P12]`

---

## 本次审查发现的新问题

### 🔴 P14（严重）— 音效目标选择器 `@s` 导致所有倒计时音效无声

**这是用户反馈「点击开始游戏后音效没有正常播放」的根本原因**

**文件**: 所有 4 个音效文件（当前工作区未提交修改）

| 文件 | 当前代码 | 问题 |
|------|---------|:----:|
| `sounds/click_button.mcfunction` | `playsound minecraft:ui.button.click master @s ~ ~ ~ 1 1` | `@s` 无玩家实体 |
| `sounds/exp_orb_pickup.mcfunction` | `playsound minecraft:entity.experience_orb.pickup master @s ~ ~ ~ 0.5 1` | `@s` 无玩家实体 |
| `sounds/levelup.mcfunction` | `playsound minecraft:entity.player.levelup master @s ~ ~ ~ 0.5 1` | `@s` 无玩家实体 |
| `sounds/villager_no.mcfunction` | `playsound minecraft:entity.villager.no master @s ~ ~ ~ 0.5 1` | `@s` 无玩家实体 |

**问题描述**:

提交 `4121811` 已将这些音效文件的 `@s` 修正为 `@a`（播放给所有玩家），但当前工作区（未提交）将其**回退**为 `@s`。

问题在于音效函数的**调用上下文**：

- **`start_button_l.mcfunction`** 在 `tick.mcfunction` 中被调用，**没有** `execute as @a` 包装
- 因此音效函数运行在**服务端/控制台上下文**（无实体执行者）
- `playsound master @s ~ ~ ~` 中的 `@s` 不匹配任何玩家实体 → Minecraft **静默忽略**该命令
- 结果：倒计时全程（CTD=140, 120, 100, 80, 60, 40, 20）的 7 次音效全部无声

**影响链路**:
```
玩家点击开始按钮
  → press_start_button 设置 CTD=140（无音效）
  → tick 循环调用 start_button_l
    → CTD=140: function game:sounds/exp_orb_pickup → @s 无声 ❌
    → CTD=120/100/80/60/40: function game:sounds/click_button → @s 无声 ❌
    → CTD=20: function game:sounds/levelup → @s 无声 ❌
  → 游戏开始，全程无音效
```

**同样受影响但程度较轻的场景**:

| 音效文件 | 调用者 | 执行上下文 | `@s` 是否生效 |
|----------|--------|:----------:|:------------:|
| `exp_orb_pickup` | `start_button_l` | 服务端 tick | ❌ 无声 |
| `click_button` | `start_button_l` | 服务端 tick | ❌ 无声 |
| `levelup` | `start_button_l` | 服务端 tick | ❌ 无声 |
| `exp_orb_pickup` | `join_attacker/defender/spectator` | 取决于调用方 | ⚠️ 可能无声 |
| `villager_no` | `leave_team` | 取决于调用方 | ⚠️ 可能无声 |

**可能的修复方案**:

**方案一（推荐）** — 恢复为 `@a`（与提交 `4121811` 一致）：
```mcfunction
playsound minecraft:ui.button.click master @a ~ ~ ~ 1 1
playsound minecraft:entity.experience_orb.pickup master @a ~ ~ ~ 0.5 1
playsound minecraft:entity.player.levelup master @a ~ ~ ~ 0.5 1
playsound minecraft:entity.villager.no master @a ~ ~ ~ 0.5 1
```

**方案二** — 在 `start_button_l.mcfunction` 的每个音效调用前添加 `execute as @a`：
```mcfunction
execute if score state game_state matches 0 if score CTD game_start_ctd matches 140 run execute as @a at @s run function game:sounds/exp_orb_pickup
```
（改动量大，涉及 7 处调用，且 `join_*` 等其他调用者也需逐一适配）

**方案三（最小改动）** — 在 `tick.mcfunction` 中包装 `start_button_l` 的调用：
```mcfunction
execute as @a run function game:game/start_button_l
```
（⚠️ 风险：`start_button_l` 内部使用 `title @a`，改为在玩家上下文中调用后 `@a` 会变为仅执行该函数的玩家，需全面重构）

**严重程度**: 🔴 **严重** — 导致整个倒计时过程完全无声，影响核心游戏体验

确认标签: `[Pending: P14]`

---

### 🟡 P15 — `press_start_button.mcfunction` 缺少点击即时反馈音效

**文件**: `data/game/function/game/press_start_button.mcfunction`
**行号**: 1
**代码**:
```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140
```

**问题描述**:

当玩家点击开始按钮时，函数仅设置 `CTD=140`，没有调用任何音效函数。玩家在点击后需要等到下一个 tick 的 `start_button_l` 检测到 `CTD=140` 时才会听到 `exp_orb_pickup` 音效。

但更重要的是：此时 `on target` 已将执行上下文切换为**点击的玩家**，`@s` 在此上下文中是**有效**的。

**影响**:
- 点击按钮后无即时听觉反馈（如"按钮按下"的 click 声）
- 玩家可能不确定按钮是否被成功按下
- 尤其是在 P14 未修复的情况下，玩家完全听不到任何声音

**可能的修复方案**:

在 `press_start_button.mcfunction` 第1行的 `run` 之后串联音效：
```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run function game:sounds/click_button
```
或合并为一条：
```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run function game:game/start_click_feedback
```
（在 `start_click_feedback.mcfunction` 中同时设置 CTD 和播放音效）

**严重程度**: 🟡 **中等** — 无即时反馈影响用户体验，但与 P14 叠加后问题更加严重

确认标签: `[Pending: P15]`

---

### 🟡 P16 — `start_button_l.mcfunction` CTD=20 的 `@a` 与 `function` 混合调用可能产生时序问题

**文件**: `data/game/function/game/start_button_l.mcfunction`
**行号**: 14-26
**代码**:
```mcfunction
execute if score CTD game_start_ctd matches 20 run scoreboard players set state game_state 1    ← 第14行: game_state 已设为1
execute if score CTD game_start_ctd matches 20 run execute as @a[team=attacker] at @s run tp @s ...
...
execute if score CTD game_start_ctd matches 20 run function game:sounds/levelup            ← 第20行: 播放音效
...
execute if score CTD game_start_ctd matches 20 run give @a[team=!spectator,team=!unselected] kubejs:profession_selector
execute if score CTD game_start_ctd matches 0..20 run scoreboard players reset CTD game_start_ctd   ← 第26行: 重置CTD
```

**问题描述**:

第14行将 `game_state` 设置为 1，但后续同一 tick 的第20行才播放 `levelup` 音效。在第26行 `CTD` 被重置为 0 之前，`game_start_ctd.mcfunction`（同一 tick 的最后一步）会执行：

```
game_start_ctd.mcfunction: execute if score CTD game_start_ctd matches 1..140 run scoreboard players remove CTD game_start_ctd 1
```

当 CTD=20 时，`matches 1..140` 匹配，CTD 在第14-26行执行后被减为 19。然后第26行 `matches 0..20` 匹配（19∈[0,20]）→ 重置为 0。

但问题是：`game_start_ctd` 在 `start_button_l` **之后**执行（tick 顺序第8步 vs 第5步）。所以实际流程是：
```
start_button_l: CTD=20 → game_state=1, 传送玩家, 播放音效, CTD重置为0
game_start_ctd: CTD=0 → matches 1..140 不匹配 → 跳过
```
**当前逻辑是正确的**。但需要注意的是，`game_state` 被设为 1 后，后续的 `press_start_button`（下一 tick 的第2步）会因 `matches 0` 不匹配而跳过。同时 `start_button_l` 中 `if score state game_state matches 0` 的条件也不再满足。

**潜在风险（极小概率）**:
如果在 `scoreboard players set state game_state 1` 和 `function game:sounds/levelup` 之间出现服务端异常中断，会出现 game_state=1 但音效未播放的状态。不过这是极端情况，且重启后自动恢复。

**严重程度**: 🟢 **轻微** — 当前逻辑正确，仅理论上存在极端时序风险

确认标签: `[Pending: P16]`

---

### 🟡 P17 — `interaction/start.mcfunction` 每 tick 无条件执行 `data merge entity`

**文件**: `data/game/function/interaction/start.mcfunction`
**行号**: 1
**代码**:
```mcfunction
data merge entity @e[type=interaction,tag=start_button,limit=1] {response:1b}
```

**文件**: `data/game/function/interaction/redeploy.mcfunction`
**行号**: 1-2
**代码**:
```mcfunction
data merge entity @e[type=interaction,tag=attacker_redeploy,limit=1] {response:1b}
data merge entity @e[type=interaction,tag=defender_redeploy,limit=1] {response:1b}
```

**问题描述**:

`tick.mcfunction` 在**每 tick** 都调用 `interaction/start.mcfunction` 和 `interaction/redeploy.mcfunction`，而这些函数使用 `data merge entity` 设置 `{response:1b}`。

`response` 字段控制 Interaction 实体的视觉反馈动画（点击时的闪烁）。正常情况下，这个字段应在玩家点击时由服务器自动设置为 `true`，并在动画播放后自动重置。手动每 tick 设置 `{response:1b}` 可能导致：

1. Interaction 实体的 response 动画**持续激活**，视觉上按钮一直处于"被点击"的闪烁状态
2. 不必要的 NBT 写入操作，每 tick 执行，影响性能（虽然对单个实体影响很小）
3. 在模组环境中，与其他模组对 Interaction 实体的操作可能产生冲突

**可能的修复方案**:

方案一 — 仅在玩家实际点击时才设置 response（无需额外函数，已有机制）：
移除 `interaction/start.mcfunction` 和 `interaction/redeploy.mcfunction`，删除 `tick.mcfunction` 中对它们的调用。

方案二 — 检查是否已有 response 状态：
```mcfunction
execute unless data entity @e[type=interaction,tag=start_button,limit=1] response run data merge entity @e[type=interaction,tag=start_button,limit=1] {response:1b}
```

**严重程度**: 🟡 **中等** — 可能造成视觉异常和轻微性能浪费

确认标签: `[Pending: P17]`

---

### 🟢 P18 — `load_scoreboard_settings.mcfunction` 缺少 CTD 初始化后的备注说明

**文件**: `data/game/function/scoreboard/load_scoreboard_settings.mcfunction`
**当前代码**:
```mcfunction
scoreboard objectives modify game_start_ctd displayname {"translate":"scoreboard.game_start_ctd","color":"gold","bold":true}
scoreboard objectives modify game_state displayname {"translate":"scoreboard.game_state","color":"gold"}
scoreboard players set state game_state 0
scoreboard objectives modify redeploy_ctd displayname {"translate":"scoreboard.redeploy_ctd","color":"gold","bold":true}
```

**问题描述**:

提交 `05137da` 移除了 `scoreboard players set CTD game_start_ctd 0` 这一行，但**没有添加注释说明**为什么移除。后续维护者可能不理解为什么 CTD 不再在这里初始化。

同时，`game_state=0` 的初始化仍然保留，而 `CTD` 的初始化现在完全依赖 `press_start_button.mcfunction` 在玩家点击时设置。如果未来有其他路径需要读取 CTD 的值（比如积分榜显示），可能会读到未初始化的 0 值。

**可能的修复方案**:

添加注释说明 CTD 不再在此处初始化，以及其原因：
```mcfunction
# CTD 不再在此处初始化（避免 /reload 时重置倒计时）
# 由 press_start_button.mcfunction 在玩家点击时设置为 140
```

**严重程度**: 🟢 **轻微** — 不影响功能，仅维护性问题

确认标签: `[Pending: P18]`

---

## 已确认修复的问题汇总

| 问题 | 文件 | 状态 | 确认标签 |
|:----:|------|:----:|:--------:|
| P0 | `start_button_l` line 24 — `matches 20..` 逻辑 | ✅ 已修复（v3） | `[Confirmed: P0_FIXED_VERIFIED]` |
| P6 | `click_button` 命名空间 | ✅ 已修复（v2） | `[Confirmed: P6_FIXED_VERIFIED]` |
| P10 | `levelup` 命名空间 | ✅ 已修复（提交 `4121811`） | `[Confirmed: P10_NAMESPACE_FIXED]` |
| P11 | `/reload` 时 CTD 重置 | ✅ 已修复（提交 `05137da`） | `[Confirmed: P11_FIXED]` |

---

## 仍存在的问题汇总

| 严重程度 | 编号 | 文件 | 说明 | 确认标签 |
|:--------:|:----:|------|------|:--------:|
| 🔴 严重 | **P14** | 4 个音效文件 | `@s` 导致倒计时音效全部无声 | `[Pending: P14]` |
| 🔴 严重 | **P8** (回归) | `press_start_button` | 防重复点击保护被移除 | `[Pending: P8_REGRESSION]` |
| 🟡 中等 | **P15** | `press_start_button` | 点击后无即时音效反馈 | `[Pending: P15]` |
| 🟡 中等 | **P17** | `interaction/start/redeploy` | 每 tick 无条件 `data merge response` | `[Pending: P17]` |
| 🟢 轻微 | **P13** | `start_button_l` line 26 | 无 `game_state` 过滤，每 tick 冗余执行 | `[Pending: P13]` |
| 🟢 轻微 | **P12** | `redeploy_tick` | 重部署完成时无音效反馈 | `[Pending: P12]` |
| 🟢 轻微 | **P16** | `start_button_l` CTD=20 | 极端时序风险（极小概率） | `[Pending: P16]` |
| 🟢 轻微 | **P18** | `load_scoreboard_settings` | 缺少 CTD 初始化移除的注释说明 | `[Pending: P18]` |

---

## 已忽略的问题（仍存在于代码库中，不再重复审查）

| 问题 | 文件 | 说明 | 状态 |
|:----:|------|------|:----:|
| P2 | `pack.mcmeta` | `max_format: [101, 1]` 格式 | 🟡 已忽略 |
| P3 | `帮助/项目概览.md` | 文档与实际不匹配 | 🟡 已忽略 |
| P4 | `press_start_button.mcfunction` | 无队伍过滤开始按钮 | 🟡 已忽略 |
| P5 | `detect_redeploy_button.mcfunction` | 无队伍过滤重部署按钮 | 🟡 已忽略 |
| P9 | `start_button_l.mcfunction` | 首次进入职业标题未显示 | 🟢 已忽略 |

> 上述问题如需修复可参考 [dubag_v1.md](./dubag_v1.md) 中的方案。

---

## 总结

**核心发现**: 

1. 🔴 **P14 是"点击开始游戏后音效没有正常播放"的根因** — 工作区未提交的修改将音效目标从 `@a` 回退为 `@s`，而 `start_button_l.mcfunction` 在服务端 tick 上下文中调用音效函数，`@s` 不匹配任何玩家，导致所有倒计时音效（7 次）全部无声。

2. 🔴 **P8 防重复点击保护被回退** — `press_start_button.mcfunction` 中 `if score CTD game_start_ctd matches 0` 检查被移除，玩家可重复点击重置倒计时。

3. ✅ **P11 `/reload` 时 CTD 重置问题已修复** — `load_scoreboard_settings.mcfunction` 中的 `CTD=0` 初始化行已移除。

4. ✅ **P10 `levelup` 命名空间前缀问题已在提交中修复** — 但工作区修改覆盖了 `@a`。

| 严重程度 | 数量 | 问题编号 |
|:--------:|:----:|:--------:|
| ✅ 已修复（本次确认） | 4 | P0, P6, P10, P11 |
| 🔴 严重（当前活跃） | 2 | **P14**, **P8(回归)** |
| 🟡 中等（当前活跃） | 2 | **P15**, **P17** |
| 🟢 轻微（当前活跃） | 4 | **P12**, **P13**, **P16**, **P18** |
| 🟡 已忽略 | 4 | P2, P3, P4, P5 |
| 🟢 已忽略 | 1 | P9 |

**建议修复优先级**: P14 → P8 → P15 → P17 → P13 → P12 → P16 → P18
