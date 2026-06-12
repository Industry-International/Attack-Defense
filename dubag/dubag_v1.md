# Dubag 审查报告 — v1（首次审查）

- **审查时间**: 2026-06-12
- **Git HEAD**: `b805cbb`
- **Minecraft 版本**: 1.21.1 (pack_format 48)
- **审查范围**: 全量代码（因上一份 dubag 报告已在 commit `b805cbb` 中被删除，此为全新基线审查）

> 上一份 dubag 报告: **无**（已被清理删除，无法引用）

---

## 本次审查发现的潜在问题

### P1. `start_button_l.mcfunction` — 第24行分数比较语法错误

**文件**: `data/game/function/game/start_button_l.mcfunction`
**行号**: 24
**代码**:
```mcfunction
execute if score CTD game_start_ctd >= 20 game_start_ctd run scoreboard players reset CTD game_start_ctd
```

**问题描述**:
`if score` 语法要求两个操作数都是 **计分板持有者（score holder）**，无法直接与 **字面量整数** 比较。这里的 `20` 被视为一个名为 `"20"` 的虚拟玩家。由于 `"20"` 从未被赋予 `game_start_ctd` 分数，其默认值为 `0`。因此条件实际变为 `CTD >= 0`，**永远为真**。

**影响**:
每次 tick 执行到此处时，`CTD` 的 `game_start_ctd` 分数都会被立即重置（`reset`），导致倒计时进度丢失。整个倒计时动画（5→4→3→2→1 标题）无法正常运作。

**可能的修复方案**:
将第24行改为使用 `matches` 进行字面量范围比较：
```mcfunction
execute if score CTD game_start_ctd matches 20.. run scoreboard players reset CTD game_start_ctd
```

**严重程度**: 🔴 **严重** — 核心倒计时逻辑失效

---

### P2. `pack.mcmeta` — `max_format` 的数组格式疑似错误

**文件**: `pack.mcmeta`
**行号**: 7
**代码**:
```json
"max_format": [101, 1]
```

**问题描述**:
在 Minecraft 1.21+ 数据包中，`max_format` 使用 `[major, minor]` 版本数组格式。`[101, 1]` 表示版本 **101.1**，而 `supported_formats` 为 `[48, 101]` 表示范围 48~101。此处 `max_format: [101, 1]` 的 `minor` 值为 `1`，不清楚是笔误还是特意指向一个不存在的未来版本。通常应使用 `101`（整数）或 `[101, 2147483647]`（表示无限向上兼容）。

**可能的修复方案**:
- 如果仅需兼容到 pack_format 101：将 `max_format` 改为 `101`（整数）
- 如果需要兼容到未来版本：改为 `[101, 2147483647]`

**严重程度**: 🟡 **中等** — 不影响当前游戏运行，但兼容性声明不准确

---

### P3. 项目概览中声明的文件与实际文件系统不匹配

**文件**: `帮助/项目概览.md`
**问题描述**:
概览文档中声明了以下文件，但在实际文件系统中 **不存在**：
1. `data/game/function/teams/show_team_actionbar.mcfunction` — 文档的 tick 数据流图和功能清单中均提到此函数
2. 多语言文件目录 `lang/`（`zh_cn.json`, `en_us.json`, `lzh.json`, `lolcat.json`）— 文档声称已支持 4 种语言

**影响**:
- `show_team_actionbar` 缺失意味着 `tick.mcfunction` 中未显示队伍 actionbar（文档声称已实现的功能实际上未生效）
- 缺少语言文件意味着所有 `{"translate":"..."}` 组件会回退显示原始翻译键，如 `team.attacker.join`，而非易读的文本

**可能的修复方案**:
- 创建 `show_team_actionbar.mcfunction` 并加入 `tick.mcfunction` 调用链
- 添加 `lang/` 目录和对应的语言文件
- 或更新 `帮助/项目概览.md` 使其与实际代码一致

**严重程度**: 🟡 **中等** — 文档与实现脱节，玩家体验受影响

---

### P4. `press_start_button.mcfunction` — 未限制点击玩家的队伍身份

**文件**: `data/game/function/game/press_start_button.mcfunction`
**行号**: 1
**代码**:
```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140
```

**问题描述**:
此命令仅检查 `game_state == 0`，未限制只有特定队伍（如 `attacker` 或 `defender`）的玩家才能点击开始按钮。任意玩家（包括 `spectator`、`unselected`，乃至未加入任何队伍的玩家）都可以触发游戏开始。

此外，命令中使用了 `on target` 定位到交互实体所朝向的目标，但没有通过 `as @p` 将执行上下文切换到点击的玩家，后续 `run` 的上下文仍然是 interaction 实体本身（而非玩家）。

**可能的修复方案**:
添加队伍过滤条件，例如：
```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 if entity @p[team=attacker] run scoreboard players set CTD game_start_ctd 140
```
或使用 `as @p` 切换到玩家上下文。

**严重程度**: 🟡 **中等** — 权限控制缺失

---

### P5. `detect_redeploy_button.mcfunction` — 未校验点击者与按钮队伍匹配

**文件**: `data/game/function/redeploy/detect_redeploy_button.mcfunction`
**行号**: 1-4
**代码**:
```mcfunction
execute as @e[type=interaction,tag=attacker_redeploy] at @s on target if score state game_state matches 1 run function game:redeploy/redeploy_click
execute as @e[type=interaction,tag=defender_redeploy] at @s on target if score state game_state matches 1 run function game:redeploy/redeploy_click
```

**问题描述**:
`attacker_redeploy` 按钮可以被任何队伍（包括 `defender`、`spectator`）的玩家点击触发。同理 `defender_redeploy` 按钮也没有限制点击者队伍。可能导致玩家被传送到错误队伍的重生点。

**可能的修复方案**:
在检测交互时加入队伍过滤：
```mcfunction
execute as @e[type=interaction,tag=attacker_redeploy] at @s on target if score state game_state matches 1 if entity @p[team=attacker] run function game:redeploy/redeploy_click
execute as @e[type=interaction,tag=defender_redeploy] at @s on target if score state game_state matches 1 if entity @p[team=defender] run function game:redeploy/redeploy_click
```

**严重程度**: 🟡 **中等** — 跨队伍误触导致传送到错误位置

---

### P6. `click_button.mcfunction` — 音效命名空间不统一

**文件**: `data/game/function/sounds/click_button.mcfunction`
**代码**:
```mcfunction
playsound ui.button.click master @s ~ ~ ~ 1 1
```

**问题描述**:
此音效未使用 `minecraft:` 命名空间前缀，而其他音效文件（`exp_orb_pickup`, `levelup`, `villager_no`）都使用了完整的 `minecraft:` 前缀。虽然 `ui.button.click` 在不加前缀时默认也能解析，但风格不一致，且在部分模组环境中可能因命名空间解析异常而无声。

**可能的修复方案**:
统一添加 `minecraft:` 前缀：
```mcfunction
playsound minecraft:ui.button.click master @s ~ ~ ~ 1 1
```

**严重程度**: 🟢 **轻微** — 仅风格问题，当前不影响功能

---

### P7. `load.mcfunction` — 初始化时未自动归入 unselected 队伍

**文件**: `data/game/function/load.mcfunction`
**代码**:
```mcfunction
function game:teams/load_team_settings
function game:teams/join_unselected
function game:scoreboard/create_scoreboards
function game:scoreboard/load_scoreboard_settings
```

*（注意：当前代码中已存在 `join_unselected` 调用，但在此指出是为了说明其重要性——如果有读者查阅旧版 load.mcfunction 没有此行的情况）*

**实际当前代码已包含 `join_unselected`。无问题。**

---

### P8. 倒计时期间无防重复点击保护

**文件**: `data/game/function/game/press_start_button.mcfunction`
**行号**: 1
**问题描述**:
当倒计时正在进行中（CTD 为 139~21）时，任意玩家再次点击开始按钮会重新设置 `CTD = 140`，导致倒计时被重置延长。多个玩家反复点击可无限推迟游戏开始。

**可能的修复方案**:
添加状态检查，仅在 CTD 为 0 或未设置时才允许设置：
```mcfunction
execute ... if score CTD game_start_ctd matches 0 run scoreboard players set CTD game_start_ctd 140
```

**严重程度**: 🟢 **轻微** — 非破坏性问题，但影响预期流程

---

### P9. 首次进入游戏时职业标题未显示

**对比**: 当玩家通过 `start_button_l` 首次进入游戏（CTD=140 倒计时结束）时，职业选择器被发放但职业标题不显示。而在 `redeploy_tick` 中重生（redeploy_ctd=0）时会显示职业标题。两者行为不一致。

**文件**: `data/game/function/game/start_button_l.mcfunction`（第 20-24 行）
**文件**: `data/game/function/redeploy/redeploy_tick.mcfunction`（第 8-15 行）

**可能的修复方案**:
在首次发放职业选择器后，也触发职业标题显示（或等玩家实际选择职业后再显示）。

**严重程度**: 🟢 **轻微** — 用户体验不一致

---

## 已确认无问题的文件

以下文件经过审查，未发现逻辑错误或潜在风险：

| 文件 | 状态 |
|------|:----:|
| `data/game/function/load.mcfunction` | ✅ |
| `data/game/function/tick.mcfunction` | ✅ |
| `data/game/function/scoreboard/create_scoreboards.mcfunction` | ✅ |
| `data/game/function/scoreboard/load_scoreboard_settings.mcfunction` | ✅ |
| `data/game/function/scoreboard/game_start_ctd.mcfunction` | ✅ |
| `data/game/function/teams/load_team_settings.mcfunction` | ✅ |
| `data/game/function/teams/join_attacker.mcfunction` | ✅ |
| `data/game/function/teams/join_defender.mcfunction` | ✅ |
| `data/game/function/teams/join_spectator.mcfunction` | ✅ |
| `data/game/function/teams/join_unselected.mcfunction` | ✅ |
| `data/game/function/teams/leave_team.mcfunction` | ✅ |
| `data/game/function/redeploy/redeploy_click.mcfunction` | ✅ |
| `data/game/function/redeploy/redeploy_tick.mcfunction` | ✅（除 P9 提到的一致性差） |
| `data/game/function/sounds/*.mcfunction`（全部 4 个） | ✅（除 P6 风格问题） |
| `data/minecraft/tags/function/load.json` | ✅ |
| `data/minecraft/tags/function/tick.json` | ✅ |

---

## 总结

| 严重程度 | 数量 | 问题编号 |
|:--------:|:----:|:--------:|
| 🔴 严重 | 1 | P1 |
| 🟡 中等 | 4 | P2, P3, P4, P5 |
| 🟢 轻微 | 3 | P6, P8, P9 |

**共发现 8 个潜在问题**，其中最严重的是 `start_button_l.mcfunction` 第 24 行的分数比较语法错误（P1），直接导致倒计时逻辑无法正常工作。
