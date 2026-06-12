# 🔍 Attack-Defense 数据包代码审查报告 v2

| 项目 | 内容 |
|------|------|
| **数据包版本** | Minecraft 1.21.1 (pack_format 48) |
| **审查日期** | 2026-06-12 |
| **审查范围** | 全部 `.mcfunction`、`pack.mcmeta`、标签 JSON |
| **审查类型** | 仅提示潜在问题，不进行修复 |
| **参考上一份** | `dubag/dubag_v1.md` (2026-06-12 v1) |

---

## 上一轮问题修复状态总览

### ✅ 已修复（本轮仅作简单提示）

以下问题在 v1 报告中被标记，经比对当前代码已修复：

| 编号 | 问题简述 | 修复方案参考 |
|:----:|---------|------------|
| #1 | `start_button_l.mcfunction` 分数比较旧语法 `= N obj` | 改用 `matches N` 语法 ✅ |
| #2 | `game_start_ctd.mcfunction` 与 `tick.mcfunction` 时序冲突导致倒计时卡死 | 改为每 tick 递减 1，并调整执行顺序 ✅ |
| #4 | `join_unselected.mcfunction` 中 `@a[tag=unselected]` 应为 `@a[team=unselected]` | 移除该 give 命令 ✅ |
| #5 | `detect_redeploy_button.mcfunction` 攻击方重部署按钮 response 未重置 | 在 `interaction/redeploy.mcfunction` 中添加了双方重置 ✅ |
| #6 | `spawnpoint` 脱离 `execute` 作用域 | 移入 `execute run` 内部 ✅ |
| #8 | 文件夹名 `interation/` 拼写错误 | 已重命名为 `interaction/` ✅ |

### ❌ 仍未修复

| 编号 | 问题简述 | 严重程度 |
|:----:|---------|:--------:|
| #3 | `join_defender.mcfunction` 缺少 `@s` — 防守方无法加入队伍 | 🔴 |
| #7 | `pack.mcmeta` 中 `min_format`/`max_format` 冗余 | 🟢 |
| #9 | `帮助/项目概览.md` 引用的 `show_team_actionbar` 文件不存在 | 🟢 |
| #10 | `load.mcfunction` 加载时执行 `join_unselected`，`@a` 可能为空 | 🟢 |

---

## 🔴 严重问题（大概率会导致功能异常）

### 1. [续 v1#3] `join_defender.mcfunction` — 仍缺少 `@s`

**文件**: `data/game/function/teams/join_defender.mcfunction`

```mcfunction
function game:sounds/exp_orb_pickup
team join defender                        # ← 仍然没有 @s
tellraw @s {"translate":"team.defender.join","color":"blue"}
```

**对比** `join_attacker.mcfunction`：
```mcfunction
function game:sounds/exp_orb_pickup
team join attacker @s                     # ← 有 @s
tellraw @s {"translate":"team.attacker.join","color":"red"}
```

**影响**: 防守方点击队伍选择器后，仅播放音效、显示消息，但**实际未加入任何队伍**。攻击方可正常加入。

**可能的修复方案**:
```mcfunction
team join defender @s
```

---

### 2. [NEW] `redeploy_click.mcfunction` — `on target` 无法切换执行上下文到玩家

**文件**: `data/game/function/redeploy/redeploy_click.mcfunction`
**关联文件**: `data/game/function/redeploy/detect_redeploy_button.mcfunction`

**问题描述**:

`detect_redeploy_button.mcfunction` 中的调用链：

```mcfunction
# 第 1 行
execute as @e[type=interaction,tag=attacker_redeploy] at @s on target if score state game_state matches 1 run function game:redeploy/redeploy_click
```

在 Minecraft 1.21.1 中，`execute on target` 的 `target` 指向实体的 **攻击目标（AI Target）**，而非点击 interaction 实体的玩家。对于 `interaction` 实体而言：
- 它没有 AI，没有攻击目标
- `target` NBT 字段默认不存在
- 因此 `on target` **不会改变执行上下文**

结果是：`redeploy_click.mcfunction` 中的 `@s` **仍然是 interaction 实体本身**，而非点击的玩家。

`redeploy_click.mcfunction` 内容：
```mcfunction
execute unless score @s redeploy_ctd matches 1.. run scoreboard players set @s redeploy_ctd 100
execute if score @s redeploy_ctd matches 100 run title @s title {"text":"5","color":"gold","bold":true}
```

- `scoreboard players set @s redeploy_ctd 100` → 分数被设置到 **interaction 实体** 上
- `title @s` → 试图向 interaction 实体发送标题（无效果）

而 `redeploy_tick.mcfunction` 中操作的是 **玩家**：
```mcfunction
scoreboard players remove @a[scores={redeploy_ctd=1..}] redeploy_ctd 1   # ← @a 玩家
execute as @a[scores={redeploy_ctd=0},team=attacker] at @s run tp @s ... # ← @a 玩家
```

**影响**: 分数在 interaction 实体上，递减操作在玩家上。**整个重部署系统完全失效**——玩家点击重部署按钮后什么也不会发生。

**可能的修复方案**:

方案一：移除 `on target`，在 `redeploy_click.mcfunction` 中用 `@p` 或 `@a` 定位点击的玩家
```mcfunction
# detect_redeploy_button.mcfunction
execute as @e[type=interaction,tag=attacker_redeploy] at @s if data entity @s interaction if score state game_state matches 1 run function game:redeploy/redeploy_click

# redeploy_click.mcfunction
execute unless score @p redeploy_ctd matches 1.. run scoreboard players set @p redeploy_ctd 100
execute if score @p redeploy_ctd matches 100 run title @p title {"text":"5","color":"gold","bold":true}
```

方案二：利用 interaction 实体的 `interaction` NBT 提取玩家 UUID，用 `execute as` 切换
（较复杂，方案一更直接）

---

### 3. [NEW] `start_button_l.mcfunction` 第 24 行 — 旧分数比较语法遗漏

**文件**: `data/game/function/game/start_button_l.mcfunction`

**第 24 行**:
```mcfunction
execute if score CTD game_start_ctd >= 20 game_start_ctd run scoreboard players reset CTD game_start_ctd
```

此行的 `>= 20 game_start_ctd` 仍是 v1 报告中指出的**旧语法**：
- `20` 被当作假玩家名，比较的是 CTD 与假玩家 `20` 在 `game_start_ctd` 上的分数
- 假玩家 `20` 的分数从未设置，默认 **0**
- 只要 CTD > 0，条件**恒为真**，每 tick 都会重置 CTD

但前 23 行已全部改为正确的 `matches N` 语法，唯此行遗漏。

**影响**: 倒计时每 tick 走到第 24 行时都会触发 `scoreboard players reset CTD game_start_ctd`，移除 CTD 的分数。下一 tick `game_start_ctd.mcfunction` 中 `matches 1..140` 无法匹配（分数已被移除），倒计时停止递减。但 `press_start_button.mcfunction` 需要再次点击才能重新设置 CTD=140——整个倒计时变得不可预测。

> 注：在第 14 行（matches 20）设置 `state game_state 1` 后，开始按钮不再响应，所以实际上这个 bug 在第一次倒计时结束后影响较小。但**语法不一致**仍需要修正。

**可能的修复方案**:
```mcfunction
execute if score CTD game_start_ctd matches 20.. run scoreboard players reset CTD game_start_ctd
```

---

## 🟡 中等问题（部分功能受影响或逻辑缺陷）

### 4. [NEW] `redeploy_click.mcfunction` — 缺少 interaction 数据清除

**文件**: `data/game/function/redeploy/redeploy_click.mcfunction`

**问题描述**:

对比 `press_start_button.mcfunction` 的处理方式：
```mcfunction
# press_start_button.mcfunction
execute as @e[type=interaction,tag=start_button,scores={game_state=0}] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140
execute as @e[type=interaction,tag=start_button] if data entity @s interaction run data remove entity @s interaction
```

开始按钮分两行：
1. 检测 interaction + 执行逻辑
2. 清除 interaction 数据

而 `detect_redeploy_button.mcfunction` 中：
```mcfunction
execute as @e[type=interaction,tag=attacker_redeploy] at @s on target if score state game_state matches 1 run function game:redeploy/redeploy_click
execute as @e[type=interaction,tag=attacker_redeploy] if data entity @s interaction run data remove entity @s interaction
```

这里的 `data remove` 是独立于 `redeploy_click` 的，无论 `redeploy_click` 是否实际执行了操作，interaction 数据都会被清除。**问题在于 `redeploy_click` 本身的逻辑也可能依赖于 interaction 数据**——如果先清除了 interaction 数据再执行 `redeploy_click`（或反过来），逻辑上存在潜在的竞态。

不过在当前执行顺序下：
- 第 1 行：检测并执行 `redeploy_click`（如果 state=1）
- 第 2 行：清除 interaction 数据

这是正确的顺序。所以此问题级别较低，但代码风格上与开始按钮不一致。

---

### 5. [续 v1#6] `start_button_l.mcfunction` — spawnpoint 与传送的 Z 坐标不一致

**文件**: `data/game/function/game/start_button_l.mcfunction`

```mcfunction
# 第 15 行（matches 20 时的传送）
execute if score CTD game_start_ctd matches 20 run execute as @a[team=attacker] at @s run tp @s -1481.33 200.00 1874.86
# 第 16 行（spawnpoint）
execute if score CTD game_start_ctd matches 20 run spawnpoint @a[team=attacker] -1481 200 1874

# 第 17 行（防守方传送）
execute if score CTD game_start_ctd matches 20 run execute as @a[team=defender] at @s run tp @s -1485.70 199.00 1911.36
# 第 18 行（防守方 spawnpoint）
execute if score CTD game_start_ctd matches 20 run spawnpoint @a[team=defender] -1485 200 1911
```

- 防守方传送坐标 `Y=199.00`，但 spawnpoint 坐标 `Y=200` — **不一致**
- 如果玩家被传送到 `199.00`（半格高度），可能卡入地面或受到掉落伤害

**可能的修复方案**: 统一 tp 与 spawnpoint 的 Y 坐标，建议都使用 `200`。

---

### 6. [NEW] `press_start_button.mcfunction` — `scores={game_state=0}` 选择器可能过早失效

**文件**: `data/game/function/game/press_start_button.mcfunction`

```mcfunction
execute as @e[type=interaction,tag=start_button,scores={game_state=0}] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140
```

`scores={game_state=0}` 作为 `@e` 选择器的条件：
- `game_state` 是计分板目标名
- `game_state` 同时也是假玩家 `state` 所在的计分板
- interaction 实体在 `game_state` 计分板上**没有显式设置分数**，默认值视同 0

行为分析：
| 时间点 | state (假玩家) | interaction 实体 (game_state) | 选择器是否匹配 |
|:------:|:--------------:|:-----------------------------:|:-------------:|
| 初始 | 0 | 0（默认） | ✅ 匹配 |
| 游戏开始后 | 1 | 0（从未被改变） | ✅ 仍匹配 |
| 游戏开始后 | 1 | 0 | ✅ 仍匹配 |

但 `if score state game_state matches 0` 在 `state=1` 后会阻止执行，所以**双重检查是冗余但安全的**。此问题级别较低。

---

## 🟢 轻微 / 建议性问题

### 7. [续 v1#7] `pack.mcmeta` — 字段冗余

**文件**: `pack.mcmeta`（未更改）

```json
{
    "pack_format": 48,
    "supported_formats": [48, 101],
    "min_format": 48,
    "max_format": [101, 1]
}
```

- `supported_formats` 已声明兼容范围（48~101）
- `min_format`/`max_format` 在此上下文中冗余
- `max_format: [101, 1]` 的数组格式对纯数据包意义不大

**可能的修复方案**: 仅保留 `supported_formats: [48, 101]`。

---

### 8. [续 v1#9] `show_team_actionbar.mcfunction` 不存在

**文件**: `帮助/项目概览.md` 中引用了此函数，但 `data/game/function/teams/` 下没有该文件。当前 `tick.mcfunction` 也未引用它，所以暂时无实际影响。

---

### 9. [续 v1#10] `load.mcfunction` 执行时机

**文件**: `data/game/function/load.mcfunction`

```mcfunction
function game:teams/load_team_settings
function game:teams/join_unselected
function game:scoreboard/create_scoreboards
function game:scoreboard/load_scoreboard_settings
```

- 数据包加载时 `@a` 可能为空（玩家尚未完全进入世界）
- `team join unselected @a[...]` 在目标不存在时无效果，无害但无效
- 但是 `load_team_settings` 在 `join_unselected` **之前**执行，确保队伍已存在 ✅

---

### 10. [NEW] `redeploy_tick.mcfunction` — 职业标签来源不透明

**文件**: `data/game/function/redeploy/redeploy_tick.mcfunction`

```mcfunction
execute as @a[scores={redeploy_ctd=0},tag=assault] run title @s title ...
execute as @a[scores={redeploy_ctd=0},tag=scout] run title @s title ...
execute as @a[scores={redeploy_ctd=0},tag=medic] run title @s title ...
execute as @a[scores={redeploy_ctd=0},tag=support] run title @s title ...
```

- 依赖 `assault`、`scout`、`medic`、`support` 等标签（tag）来显示职业名称
- 这些标签假设由 `kubejs:profession_selector`（模组物品）设置
- 如果模组物品未正确设置标签，职业标题将不会显示
- 这是一个**隐式的外部依赖**，无模组时功能不可见

---

### 11. [NEW] 声音函数名不一致 — `exp_orb_pickup` vs `levelup`

**文件**: `data/game/function/sounds/`

- `exp_orb_pickup.mcfunction` 中使用命名空间前缀 `minecraft:entity.experience_orb.pickup`
- `levelup.mcfunction` 中 **省略** 了 `minecraft:` 前缀：`entity.player.levelup`
- 虽然 Minecraft 会自动补全 `minecraft:` 命名空间，但风格不一致

---

## 📊 问题优先级总览

| 优先级 | 编号 | 类型 | 文件 | 问题简述 |
|:-----:|:----:|:----:|------|---------|
| 🔴 | #1 | 续 v1#3 | `join_defender.mcfunction` | 仍缺少 `@s`，防守方无法加入 |
| 🔴 | #2 | NEW | `redeploy_click.mcfunction` | `on target` 无效，重部署系统完全失效 |
| 🔴 | #3 | NEW | `start_button_l.mcfunction:24` | 旧语法 `>= 20 obj` 遗漏，倒计时异常重置 |
| 🟡 | #4 | NEW | `redeploy_click.mcfunction` | 与开始按钮的 interaction 处理风格不一致 |
| 🟡 | #5 | 续 v1#6 | `start_button_l.mcfunction` | 防守方 tp Y=199 vs spawnpoint Y=200 不一致 |
| 🟢 | #6 | 建议 | `press_start_button.mcfunction` | 双重 game_state 检查，冗余但安全 |
| 🟢 | #7 | 续 v1#7 | `pack.mcmeta` | 字段冗余 |
| 🟢 | #8 | 续 v1#9 | 项目概览.md | `show_team_actionbar` 不存在 |
| 🟢 | #9 | 续 v1#10 | `load.mcfunction` | 加载时执行时机可能过早 |
| 🟢 | #10 | NEW | `redeploy_tick.mcfunction` | 职业标签依赖模组，无回退机制 |
| 🟢 | #11 | 建议 | `sounds/` | 声音事件命名空间前缀风格不一致 |

---

## ⚠️ 跨版本回归风险提示

| 问题 | 风险 |
|------|------|
| `execute on target` 在 interaction 实体上的行为 | 1.21.1 中无效，但未来版本可能改变 |
| `matches` 语法 | 1.21.1 中已稳定，1.20.5+ 引入 |
| `data merge entity @e[...] {response:1b}` | 确保 interaction 实体的 `response` NBT 存在，否则 merge 会出错 |

---

## 🔧 执行顺序链（当前）

```
load.json → game:load
  ├── teams/load_team_settings
  ├── teams/join_unselected       (时机可能过早)
  ├── scoreboard/create_scoreboards
  └── scoreboard/load_scoreboard_settings

tick.json → game:tick
  ├── teams/join_unselected
  ├── game/press_start_button     (检测开始按钮点击)
  ├── redeploy/detect_redeploy_button
  ├── redeploy/redeploy_tick      (重部署倒计时)
  ├── game/start_button_l         (开始倒计时 + 触发)
  ├── interaction/redeploy        (重置重部署按钮 response)
  ├── interaction/start           (重置开始按钮 response)
  └── scoreboard/game_start_ctd   (CTD 递减 1)
```

---

## 📎 与 v1 报告对照说明

| 维度 | v1 (dubag_v1.md) | v2 (本报告) |
|:---:|:-----------------:|:-----------:|
| 发现问题总数 | 10 | 11 |
| 严重问题 (🔴) | 4 | 3 |
| 中等问题 (🟡) | 2 | 2 |
| 轻微问题 (🟢) | 4 | 6 |
| 已修复 | — | 6 项 (#1,#2,#4,#5,#6,#8) |
| 未修复遗留 | — | 4 项 (续 v1:#3,#7,#9,#10) |
| 新发现 | — | 5 项 (#2,#3,#4,#10,#11) |

*本报告由 Deep Code 自动审查生成。*
