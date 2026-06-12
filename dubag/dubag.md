# Dubag 审查报告 — v3

- **审查时间**: 2026-06-12
- **Git HEAD**: `7f84ea9`
- **Minecraft 版本**: 1.21.1 (pack_format 48)
- **审查触发变更**: 提交 `7f84ea9` — `start_button_l.mcfunction`、`press_start_button.mcfunction` 被修改

> **对照上一份报告**: [dubag_v2.md](./dubag_v2.md)

---

## 变更概览

根据 `git diff b805cbb..7f84ea9`，本次有三个代码文件发生变更：

| 文件 | 变更说明 | 关联旧问题 |
|------|---------|:--------:|
| `data/game/function/game/start_button_l.mcfunction` | 第24行: `matches 20..` → `matches 0..20` | **P0** |
| `data/game/function/game/press_start_button.mcfunction` | 第1行: 新增 `if score CTD game_start_ctd matches 0` | P8 |
| `data/game/function/sounds/click_button.mcfunction` | 已添加 `minecraft:` 前缀（与 v2 相同，未再变更） | P6 |

**审查范围**: 上述变更文件 + 被引用的音效文件与 tick 编排。

---

## 已确认修复的问题

### ✅ P0/P1. `start_button_l.mcfunction` 第24行 — 逻辑已修正

[P0 详情见 v2 报告](./dubag_v2.md#本次修复不完整-⚠️-P0-start_button_lmcfunction--第24行-matches-20-逻辑仍存在严重缺陷)

- **旧**: `execute if score CTD game_start_ctd matches 20.. run scoreboard players reset CTD game_start_ctd`（匹配 ≥20，立即重置）
- **新**: `execute if score CTD game_start_ctd matches 0..20 run scoreboard players reset CTD game_start_ctd`（匹配 0~20，倒计时结束后才重置）
- **状态**: ✅ **已正确修复**。`matches 0..20` 仅在 CTD 降至 0~20 区间时触发重置，倒计时（140→20）可正常进行。配合 tick 顺序：`start_button_l`(第24行重置) → `game_start_ctd`(条件 1..140 不满足→跳过) 逻辑完整。

确认标签: `[Confirmed: P0_FIXED]`

### ✅ P6. `click_button.mcfunction` — 音效命名空间已统一

[P6 详情见 v1 报告](./dubag_v1.md#P6-click_buttonmcfunction--音效命名空间不统一)

- **状态**: ✅ **已在 v2 中修复**，本次无变更。`minecraft:` 前缀已正确添加。

确认标签: `[Confirmed: P6_FIXED]`

### ✅ P8. `press_start_button.mcfunction` — 防重复点击保护已添加

[P8 详情见 v1 报告](./dubag_v1.md#P8-倒计时期间无防重复点击保护)

- **旧**: `execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140`
- **新**: `execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 if score CTD game_start_ctd matches 0 run scoreboard players set CTD game_start_ctd 140`
- **状态**: ✅ **已正确修复**。新增 `if score CTD game_start_ctd matches 0` 条件，仅在 CTD 为 0 时允许设置倒计时，防止玩家多次点击重置倒计时。

确认标签: `[Confirmed: P8_FIXED]`

---

## 已忽略的问题（按用户要求）

| 问题编号 | 文件 | 说明 | 状态 |
|:-------:|------|------|:----:|
| P2 | `pack.mcmeta` | `max_format: [101, 1]` 格式 | 🟡 已忽略 |
| P3 | `帮助/项目概览.md` | 文档与实际不匹配 | 🟡 已忽略 |
| P4 | `press_start_button.mcfunction` | 无队伍过滤开始按钮 | 🟡 已忽略 |
| P5 | `detect_redeploy_button.mcfunction` | 无队伍过滤重部署按钮 | 🟡 已忽略 |
| P9 | `start_button_l.mcfunction` | 首次进入职业标题未显示 | 🟢 已忽略（预期设计） |

> 上述问题仍存在于代码库中，如需修复可参考 [dubag_v1.md](./dubag_v1.md) 中的方案。

---

## 本次审查发现的潜在问题

### 🟢 P10. `levelup.mcfunction` — 缺少 `minecraft:` 命名空间前缀

**文件**: `data/game/function/sounds/levelup.mcfunction`
**行号**: 1
**代码**:
```mcfunction
playsound entity.player.levelup master @s ~ ~ ~ 0.5 1
```

**问题描述**:
该音效未使用 `minecraft:` 命名空间前缀。当前项目中所有音效文件的命名空间使用情况如下：

| 音效文件 | 有 `minecraft:` 前缀？ |
|----------|:---------------------:|
| `click_button.mcfunction` | ✅ 已修复 |
| `exp_orb_pickup.mcfunction` | ✅ `minecraft:entity.experience_orb.pickup` |
| `villager_no.mcfunction` | ✅ `minecraft:entity.villager.no` |
| **`levelup.mcfunction`** | ❌ **`entity.player.levelup`** |

与已修复的 P6 问题属于同一类型。虽然不加前缀在默认 Minecraft 中也能解析，但：
1. **风格不一致** — 项目中其他 3 个音效文件均已使用 `minecraft:` 前缀
2. **模组兼容性** — 在部分模组环境中，缺少命名空间可能导致音效无法播放

**可能的修复方案**:
```mcfunction
playsound minecraft:entity.player.levelup master @s ~ ~ ~ 0.5 1
```

**严重程度**: 🟢 **轻微** — 风格一致性问题

确认标签: `[Pending: P10]`

---

## 本次审查未发现其他新问题

变更文件引用的关联文件（`tick.mcfunction`、`sounds/exp_orb_pickup.mcfunction`、`sounds/levelup.mcfunction`、`scoreboard/game_start_ctd.mcfunction`）经审查，除 **P10** 外未发现其他语法或逻辑缺陷。

tick 编排顺序验证通过（`press_start_button` → `start_button_l` → `game_start_ctd`），CTD 生命周期完整。

---

## 总结

| 严重程度 | 数量 | 问题编号 |
|:--------:|:----:|:--------:|
| ✅ 已修复 | 3 | **P0**, **P6**, **P8** |
| 🟢 轻微（新） | 1 | **P10** |
| 🟡 已忽略 | 4 | P2, P3, P4, P5 |
| 🟢 已忽略 | 1 | P9 |

**核心发现**: 本次提交成功修复了 v2 报告的 P0（`matches 20..` 逻辑）、P8（防重复点击）和已修复的 P6（命名空间）。仅有一条新的风格一致性发现 P10（`levelup.mcfunction` 缺少 `minecraft:` 前缀）。
