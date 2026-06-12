# Dubag 审查报告 — v2

- **审查时间**: 2026-06-12
- **Git HEAD**: `b805cbb`
- **Minecraft 版本**: 1.21.1 (pack_format 48)
- **审查触发变更**: `start_button_l.mcfunction` 和 `click_button.mcfunction` 被修改

> **对照上一份报告**: [dubag_v1.md](./dubag_v1.md)

---

## 变更概览

根据 `git diff`，本次有两个文件发生变更：

| 文件 | 变更说明 | 关联旧问题 |
|------|---------|:--------:|
| `data/game/function/game/start_button_l.mcfunction` | 第24行: `>= 20 game_start_ctd` → `matches 20..` | [P1](#) |
| `data/game/function/sounds/click_button.mcfunction` | `ui.button.click` → `minecraft:ui.button.click` | [P6](#) |

**审查范围**: 上述两个变更文件 + 它们引用的关联文件（`tick.mcfunction`、`press_start_button.mcfunction`、`game_start_ctd.mcfunction` 等）。

---

## 已确认修复的问题

### ✅ P6. `click_button.mcfunction` — 音效命名空间已统一

[P6 详情见 v1 报告](./dubag_v1.md#P6-click_buttonmcfunction--音效命名空间不统一)

- **旧**: `playsound ui.button.click master @s ~ ~ ~ 1 1`
- **新**: `playsound minecraft:ui.button.click master @s ~ ~ ~ 1 1`
- **状态**: ✅ **已正确修复**。添加了 `minecraft:` 前缀，与项目中其他音效文件风格一致。

---

## 仍在修复中的问题

### 本次修复不完整 ⚠️ P0. `start_button_l.mcfunction` — 第24行 `matches 20..` 逻辑仍存在严重缺陷

[P1 原始问题见 v1 报告](./dubag_v1.md#P1-start_button_lmcfunction--第24行分数比较语法错误)

**文件**: `data/game/function/game/start_button_l.mcfunction`  
**行号**: 24  
**代码**:
```mcfunction
execute if score CTD game_start_ctd matches 20.. run scoreboard players reset CTD game_start_ctd
```

**问题描述**:

语法上 `matches 20..` 是有效的，但 **逻辑上仍然有严重问题**：

- `matches 20..` 表示匹配 **≥20 的所有数值**（含 140, 139, ..., 21, 20）
- 当 CTD 被 `press_start_button` 设为 140 后，**同一 tick** 中 `start_button_l` 第24行条件满足 → 立即 `reset`
- 而 CTD 递减操作 (`game_start_ctd`) 在 `tick.mcfunction` 中排在 `start_button_l` **之后**执行

**tick 执行顺序加剧了此问题**:
```mcfunction
tick.mcfunction:
  5. function game:game/start_button_l    ← 第24行 `matches 20..` 立即重置 CTD
  8. function game:scoreboard/game_start_ctd  ← 递减永无机会执行
```

**完整执行追踪**:
| Tick | CTD 初始值 | `start_button_l` 操作 | `game_start_ctd` 操作 | CTD 终值 |
|:----:|:----------:|:---------------------:|:--------------------:|:--------:|
| 1 | 140 (刚被 `press_start_button` 设置) | Line 1: ✅ 显示标题 + 音效; Line 24: ❌ **重置** | 条件 `1..140` 不满足 → 跳过 | **0** |
| 2 | 0 | 所有条件不满足 → 无操作 | 条件 `1..140` 不满足 → 跳过 | 0 |
| 3+ | 0 | 所有条件不满足 → 无操作 | 条件 `1..140` 不满足 → 跳过 | 0 |

**结果**: 倒计时（5→4→3→2→1 标题 + 音效）**完全不执行**。点击开始按钮后，标题闪现瞬间即被重置。

**影响**: 🔴 **严重** — 游戏倒计时核心逻辑完全失效，游戏无法正常开始。

**可能的修复方案**:

将 `matches 20..` 改为 `matches 20`（只匹配精确值 20，在倒计时结束后的那一刻执行重置）：
```mcfunction
execute if score CTD game_start_ctd matches 20 run scoreboard players reset CTD game_start_ctd
```

---

## 之前报告中未修复的问题（P2-P5 已忽略）

以下问题在 v1 报告中指出，**根据要求忽略**（P2-P5，认为不重要且在预期中）：

| 问题编号 | 文件 | 说明 | 状态 |
|:-------:|------|------|:----:|
| P2 | `pack.mcmeta` | `max_format: [101, 1]` 格式争议 | 🟡 已忽略 |
| P3 | `帮助/项目概览.md` | 文档与实际文件不匹配 | 🟡 已忽略 |
| P4 | `press_start_button.mcfunction` | 无队伍过滤开始按钮 | 🟡 已忽略 |
| P5 | `detect_redeploy_button.mcfunction` | 无队伍过滤重部署按钮 | 🟡 已忽略 |

> 上述问题仍然存在于代码库中，如需修复可参考 [dubag_v1.md](./dubag_v1.md) 中的方案。

---

## 仍应关注的次要问题

以下问题在 v1 报告中提出，**不在 P2-P5 范围内**，且当前版本中仍未修复：

### 🟢 P8. `press_start_button.mcfunction` — 倒计时期间防重复点击保护

[P8 详情见 v1 报告](./dubag_v1.md#P8-倒计时期间无防重复点击保护)

- 当倒计时进行中（CTD 为 139~21），任意玩家再次点击按钮会把 CTD 重置为 140
- **注意**: 在当前状态下（P0 问题导致倒计时永不执行），P8 暂时不体现；一旦 P0 修复，P8 便会显现

**可能的修复方案**:
```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 if score CTD game_start_ctd matches 0 run scoreboard players set CTD game_start_ctd 140
```

### 🟢 P9. 首次进入游戏 vs 重生时职业标题行为不一致

[P9 详情见 v1 报告](./dubag_v1.md#P9-首次进入游戏时职业标题未显示)

- `redeploy_tick.mcfunction` 中当 `redeploy_ctd=0` 时会显示职业标题
- `start_button_l.mcfunction` 中倒计时结束（CTD=20）发放职业选择器后，**不显示职业标题**
- 同上，P0 修复后此问题才会显现

**可能的修复方案**:
在 `start_button_l.mcfunction` 中 CTD=20 时添加职业标题显示逻辑，或在玩家实际使用职业选择器后触发。

---

## 本次审查未发现新问题

除上述 P0（P1 修复不完整）外，其他关联文件（`tick.mcfunction`、`press_start_button.mcfunction`、`game_start_ctd.mcfunction`、`redeploy_*` 系列等）在本次变更范围内未发现新的语法或逻辑缺陷。

---

## 总结

| 严重程度 | 数量 | 问题编号 |
|:--------:|:----:|:--------:|
| 🔴 严重 | 1 | **P0**（原 P1 修复不完整） |
| 🟢 轻微 | 2 | P8, P9（仍存在） |
| 🟡 已忽略 | 4 | P2, P3, P4, P5 |

**核心发现**: v1 中建议的 `matches 20..` 修复方案本身有逻辑缺陷，应改为 `matches 20`。这是本次审查最重要的发现。
