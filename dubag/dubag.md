# Dubag 审查报告 — v4

- **审查时间**: 2026-06-12
- **Git HEAD**: `e249485`
- **Minecraft 版本**: 1.21.1 (pack_format 48)
- **审查触发变更**: 提交 `e249485` — `load_scoreboard_settings.mcfunction` 被修改（新增 `CTD game_start_ctd 0` 初始化）

> **对照上一份报告**: [dubag_v3.md](./dubag_v3.md)
> 
> **对照函数健康基线**: [函数健康基线记录_v4.md](./函数健康基线记录_v4.md)

---

## 变更概览

根据 `git diff HEAD~1..HEAD`，本次仅有一个代码文件发生变更：

| 文件 | 变更说明 | 关联旧问题 |
|------|---------|:--------:|
| `data/game/function/scoreboard/load_scoreboard_settings.mcfunction` | 第4行: 新增 `scoreboard players set CTD game_start_ctd 0` | 无直接关联 |

**审查范围**: 该变更文件 + 引用它的 `load.mcfunction` + 所有引用 `CTD game_start_ctd` 的关联文件（`press_start_button.mcfunction`、`start_button_l.mcfunction`、`game_start_ctd.mcfunction`）。

---

## 已确认修复的问题

### ✅ P0. `start_button_l.mcfunction` 第24行 — 逻辑已正确修复

[P0 详情见 v2 报告](./dubag_v2.md#本次修复不完整-⚠️-P0-start_button_lmcfunction--第24行-matches-20-逻辑仍存在严重缺陷)

- **旧**: `matches 20..`（匹配 ≥20，立即重置）
- **新 (v3)**: `matches 0..20`（倒计时结束才重置）
- **本次验证**: ✅ 经完整 tick 流程追踪，CTD 从 140→139→...→21→20（游戏开始+重置）→0 流程完整正确。tick 顺序 `press_start_button → start_button_l → game_start_ctd` 无误。
- **状态**: ✅ **已正确修复，本次未再变更**

确认标签: `[Confirmed: P0_FIXED_VERIFIED]`

### ✅ P6. `click_button.mcfunction` — 音效命名空间已统一

[P6 详情见 v1 报告](./dubag_v1.md#P6-click_buttonmcfunction--音效命名空间不统一)

- **状态**: ✅ **已在 v2 中修复**，后续版本未再变更。确认 `minecraft:ui.button.click` 前缀完整。

确认标签: `[Confirmed: P6_FIXED_VERIFIED]`

### ✅ P8. `press_start_button.mcfunction` — 防重复点击保护已添加

[P8 详情见 v1 报告](./dubag_v1.md#P8-倒计时期间无防重复点击保护)

- **状态**: ✅ **已在 v3 中修复**，本次未变更。`if score CTD game_start_ctd matches 0` 条件完整。

确认标签: `[Confirmed: P8_FIXED_VERIFIED]`

---

## 仍存在的旧问题（未修复）

### 🟢 P10. `levelup.mcfunction` — 缺少 `minecraft:` 命名空间前缀

[P10 详情见 v3 报告](./dubag_v3.md#-P10-levelupmcfunction--缺少-minecraft-命名空间前缀)

**文件**: `data/game/function/sounds/levelup.mcfunction`
**当前代码**:
```mcfunction
playsound entity.player.levelup master @s ~ ~ ~ 0.5 1
```

- **状态**: ❌ **仍未修复**。项目中其他 3 个音效文件均已使用 `minecraft:` 前缀，此文件至今未更新。

**可能的修复方案**:
```mcfunction
playsound minecraft:entity.player.levelup master @s ~ ~ ~ 0.5 1
```

确认标签: `[Pending: P10]`

---

## 本次审查发现的新问题

### 🟡 P11. `/reload` 时 `load_scoreboard_settings` 无条件重置 CTD，可能中断倒计时

**文件**: `data/game/function/scoreboard/load_scoreboard_settings.mcfunction`
**行号**: 4
**代码**:
```mcfunction
scoreboard players set CTD game_start_ctd 0
```

**问题描述**:

本变更新增了 CTD 的初始化 `=0`，这在世界加载时是正确的。但 `load.mcfunction` 会在 **每次 `/reload`** 时被重新执行：

```
load.mcfunction:
  → teams/load_team_settings
  → teams/join_unselected
  → scoreboard/create_scoreboards
  → scoreboard/load_scoreboard_settings  ← CTD 被无条件置 0
```

如果在游戏进行中、倒计时正在运行时（game_state=0, CTD 为 139~21）管理员执行 `/reload`，CTD 会被瞬间重置为 0，导致：
1. 倒计时标题和音效链中断
2. 已进行的倒计时进度丢失
3. 游戏永远无法开始（因为 game_state 仍是 0，但 CTD=0，`press_start_button` 需要重新点击）

**影响链路**:
```
game_state=0, CTD=80 (倒计时中)
    → admin /reload
    → CTD 被置 0
    → start_button_l 所有条件不满足（140/120/.../20/0..20 范围检查）
    → game_start_ctd matches 1..140 不满足 → 不递减
    → CTD 停留在 0
    → 倒计时永久停滞
```

**严重程度**: 🟡 **中等** — 仅 `/reload` 场景触发，但一旦触发后果较严重（游戏卡死）

**可能的修复方案**:

方案一 — 检查 CTD 当前值，只有为 0 时才初始化：
```mcfunction
execute if score CTD game_start_ctd matches 0 run scoreboard players set CTD game_start_ctd 0
```
（但由于未初始化的分数也是 0，此方案无效）

方案二 — 引入独立初始化标记 `game_initialized`，避免重复初始化：
在 `load.mcfunction` 中：
```mcfunction
execute unless score state game_initialized matches 1 run function game:scoreboard/init_ctd
execute if score state game_initialized matches 1 run scoreboard players set state game_initialized 1
```

方案三 — 最简单：在 `load_scoreboard_settings.mcfunction` 中添加 game_state 检查，只在 game_state=0 时初始化 CTD：
```mcfunction
execute if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 0
```

确认标签: `[Pending: P11]`

---

### 🟢 P12. `redeploy_tick.mcfunction` 重部署完成时无音效反馈

**文件**: `data/game/function/redeploy/redeploy_tick.mcfunction`
**行号**: 6-16

**问题描述**:

`start_button_l.mcfunction` 在倒计时结束（CTD=20, 游戏开始）时会播放 `levelup` 音效：
```mcfunction
execute if score CTD game_start_ctd matches 20 run function game:sounds/levelup
```

但 `redeploy_tick.mcfunction` 在 `redeploy_ctd=0`（重部署倒计时结束，玩家被传送）时 **没有任何音效反馈**：
```mcfunction
execute as @a[scores={redeploy_ctd=0},team=attacker] at @s run tp @s -265.43 109.00 -30.04
execute as @a[scores={redeploy_ctd=0},team=defender] at @s run tp @s -633.99 114.00 -24.56
execute as @a[scores={redeploy_ctd=0}] run scoreboard players set @s redeploy_ctd -1
```

**影响**:
- 玩家重部署等待 5 秒倒计时后，结束瞬间没有声音提示
- 与游戏开始倒计时结束的行为不一致（开始结束有 `levelup` 音效）
- 玩家可能不确定自己是否已被传送

**可能的修复方案**:

在 `redeploy_tick.mcfunction` 的 `redeploy_ctd=0` 行中增加音效调用（与 `start_button_l` 风格一致）：

在传送行之前/之后添加：
```mcfunction
execute as @a[scores={redeploy_ctd=0}] at @s run playsound minecraft:entity.player.levelup master @s ~ ~ ~ 0.5 1
```

或使用现有的 `levelup.mcfunction`（需先修复 P10）：
```mcfunction
execute as @a[scores={redeploy_ctd=0}] at @s run function game:sounds/levelup
```

**严重程度**: 🟢 **轻微** — 一致性问题，不影响功能

确认标签: `[Pending: P12]`

---

### 🟢 P13. `start_button_l.mcfunction` 第24行 — `matches 0..20` 在游戏进行中仍每 tick 执行

**文件**: `data/game/function/game/start_button_l.mcfunction`
**行号**: 24
**代码**:
```mcfunction
execute if score CTD game_start_ctd matches 0..20 run scoreboard players reset CTD game_start_ctd
```

**问题描述**:

当 game_state=1（游戏已开始）后，CTD 在倒计时结束时已被重置为 0。但 line 24 **没有检查 game_state**，所以每 tick 仍会执行：
1. `if score CTD game_start_ctd matches 0..20` → CTD=0 匹配 → 通过
2. `run scoreboard players reset CTD game_start_ctd` → 重置已为 0 的分数（无害，但冗余）

虽然当前逻辑对功能无影响（CTD 已为 0，reset 不改变任何数值），但：
1. 每 tick 执行不必要的分数操作
2. 在存在模组命令的环境中，可能与其他模组对 `CTD` 分数玩家的操作冲突（reset 会移除分数持有者而非仅置 0）

**可能的修复方案**:

为 line 24 添加 `game_state` 检查，仅在游戏未开始时执行：
```mcfunction
execute if score state game_state matches 0 if score CTD game_start_ctd matches 0..20 run scoreboard players reset CTD game_start_ctd
```

**严重程度**: 🟢 **轻微** — 冗余操作，当前不影响功能

确认标签: `[Pending: P13]`

---

## 本次审查发现的语法/运行确认

### ✅ `game_start_ctd.mcfunction` — 与新初始化的 CTD 兼容

```
execute if score CTD game_start_ctd matches 1..140 run scoreboard players remove CTD game_start_ctd 1
```

- CTD=0 时 `matches 1..140` 不匹配 → 不递减 ✅
- CTD=140 时递减正常 ✅
- 范围 `1..140` 完整覆盖所有倒计时值 ✅

### ✅ `press_start_button.mcfunction` — 与新初始化的 CTD 兼容

```
if score CTD game_start_ctd matches 0
```

- CTD 初始化为 0 → `matches 0` 匹配 → 允许开始 ✅
- CTD 被设为 140 后 → `matches 0` 不匹配 → 防重复 ✅
- CTD 重置后为 0 → `matches 0` 匹配（但 game_state=1 阻止）✅

### ✅ `start_button_l.mcfunction` line 1-3 — 与新初始化的 CTD 兼容

```
if score state game_state matches 0 if score CTD game_start_ctd matches 140
```

- CTD=0 时 `matches 140` 不匹配 → 不触发 ✅
- CTD=140 时 `matches 140` 匹配 → 正确 ✅

---

## 已忽略的问题（仍存在于代码库中，不再重复审查）

| 问题编号 | 文件 | 说明 | 状态 |
|:-------:|------|------|:----:|
| P2 | `pack.mcmeta` | `max_format: [101, 1]` 格式 | 🟡 已忽略 |
| P3 | `帮助/项目概览.md` | 文档与实际不匹配 | 🟡 已忽略 |
| P4 | `press_start_button.mcfunction` | 无队伍过滤开始按钮 | 🟡 已忽略 |
| P5 | `detect_redeploy_button.mcfunction` | 无队伍过滤重部署按钮 | 🟡 已忽略 |
| P9 | `start_button_l.mcfunction` | 首次进入职业标题未显示 | 🟢 已忽略（预期设计） |

> 上述问题如需修复可参考 [dubag_v1.md](./dubag_v1.md) 中的方案。

---

## 总结

| 严重程度 | 数量 | 问题编号 |
|:--------:|:----:|:--------:|
| ✅ 已修复并验证 | 3 | **P0**, **P6**, **P8** |
| 🟡 中等（新） | 1 | **P11** |
| 🟢 轻微（新） | 2 | **P12**, **P13** |
| 🟢 轻微（继承未修复） | 1 | **P10** |
| 🟡 已忽略 | 4 | P2, P3, P4, P5 |
| 🟢 已忽略 | 1 | P9 |

**核心发现**: 本次新增的 CTD 初始化 `=0` 在正常流程中无问题，但引入了 `/reload` 时倒计时被意外重置的风险（**P11**）。此外存在两个一致性问题：重部署无声反馈（**P12**）和 line 24 无 game_state 过滤（**P13**）。P10（`levelup` 命名空间）仍未修复。
