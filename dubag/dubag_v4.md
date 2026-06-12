# Attack-Defense 数据包代码审查报告 v4

| 项目 | 内容 |
|------|------|
| **数据包版本** | Minecraft 1.21.1 (pack_format 48) |
| **审查日期** | 2026-06-12 |
| **审查模式** | 增量审查（仅检查变更文件 + 引用文件） |
| **当前 HEAD** | `bb6bd88` (Merge branch 'main') |
| **变更 commit** | `f6dc2c2` (修正按键交互逻辑，简化开始按钮的执行条件) |
| **参考上一份** | `dubag/dubag_v3.md` (基线 `a9e2610`) |
| **对比基线** | `dubag/函数健康基线记录.md` |

---

## 本轮变更文件

```
git diff a9e2610..HEAD --name-only -- data/ pack.mcmeta
```

**变更文件（1 个）：**
- `data/game/function/game/press_start_button.mcfunction`

**变更摘要：** 移除 `@e` 选择器中冗余的 `scores={game_state=0}` 条件（修复 v2#6 / v3#6 "双重 game_state 检查"问题）。

### 引用关系链 → 一同审查的文件

```
press_start_button.mcfunction
  └── 调用方: tick.mcfunction 第 2 行
  └── 被设置者: CTD game_start_ctd → game_start_ctd.mcfunction
  └── 后续处理: start_button_l.mcfunction 读取 CTD
```

---

## 已修复问题（本轮仅简单提示）

| 编号 | 源报告 | 问题简述 | 修复方式 |
|:----:|:------:|---------|---------|
| #6 | v2#6, v3#6 | `press_start_button.mcfunction` 中 `@e[scores={game_state=0}]` 与 `if score state game_state matches 0` 双重冗余检查 | 移除了 `scores={game_state=0}`，仅保留 `if score` 条件 ✅ |

---

## 仍未修复的已知问题

以下问题自上一报告以来**未发生任何变更**，仍存在。如需完整描述请参阅 `dubag/dubag_v3.md` 或 `dubag/dubag_v2.md`。

### 🔴 严重问题（3 项）

| # | 文件 | 问题 | 首次报告 |
|:-:|------|------|:-------:|
| 1 | `teams/join_defender.mcfunction:2` | **缺少 `@s`** — `team join defender` 未指定目标，防守方点击后不会加入队伍 | v1#3 |
| 2 | `redeploy/detect_redeploy_button.mcfunction` + `redeploy_click.mcfunction` | **`on target` 在 interaction 实体上无效** — `@s` 指向 interaction 实体而非玩家，重部署系统完全失效 | v2#2 |
| 3 | `game/start_button_l.mcfunction:24` | **旧语法遗漏** — `>= 20 game_start_ctd` 仍未改用 `matches 20..`，倒计时在 CTD>20 时每 tick 重置 | v2#3 |

### 🟡 中等问题（1 项）

| # | 文件 | 问题 | 首次报告 |
|:-:|------|------|:-------:|
| 4 | `game/start_button_l.mcfunction:17-18` | 防守方 tp Y=199 vs spawnpoint Y=200 不一致，可能卡入地面 | v1#6 |

### 🟢 轻微 / 建议性问题（5 项）

| # | 文件 | 问题 | 首次报告 |
|:-:|------|------|:-------:|
| 5 | `pack.mcmeta` | `min_format`/`max_format` 字段与 `supported_formats` 重复 | v1#7 |
| 6 | `帮助/项目概览.md` | 引用 `show_team_actionbar` 文件在 `data/` 下不存在 | v1#9 |
| 7 | `load.mcfunction` | `@a` 在加载时可能为空，`join_unselected` 执行无效 | v1#10 |
| 8 | `redeploy/redeploy_tick.mcfunction` | 职业标签 (`assault`/`scout`/`medic`/`support`) 依赖模组赋予 | v2#10 |
| 9 | `sounds/` | 声音事件命名空间前缀风格不一致 (`minecraft:` 前缀时有时无) | v2#11 |

---

## 本轮新发现的潜在问题

### ⚠️ 1. `press_start_button.mcfunction` — 缺少文件末尾换行符

**文件**: `data/game/function/game/press_start_button.mcfunction`

`git diff` 显示文件末尾标记为 `\ No newline at end of file`。MC 函数文件以换行符结尾虽非强制要求，但 POSIX 工具（如 `cat` 拼接、部分文本编辑器）可能产生意外行为，且 `git` 会持续标记此差异。

**可能的修复方案**: 在文件末尾添加一个空行。

---

### ⚠️ 2. `press_start_button.mcfunction` — `on target` 模式与 redeploy 一致性问题

**文件**: `data/game/function/game/press_start_button.mcfunction:1`

```mcfunction
execute as @e[type=interaction,tag=start_button] at @s on target if score state game_state matches 0 run scoreboard players set CTD game_start_ctd 140
```

此模式与 `detect_redeploy_button.mcfunction` 完全相同（v2#2 报告的问题）。如果 v2#2 的分析正确 —— `execute on target` 在 interaction 实体上无法切换到点击它的玩家上下文 —— 那么此命令中的 `run scoreboard players set CTD game_start_ctd 140` **也不会执行**。

然而，用户的 commit 记录表明开始按钮功能正在工作，这存在两种可能：

| 可能性 | 含义 | 对 redeploy 的影响 |
|:------:|------|:-----------------:|
| `on target` 在 1.21.1 中对 interaction 实体**确实有效** | start_button 功能正常 ✅ | v2#2 关于 redeploy 的原因判定可能不准确，问题另有根源 |
| `on target` 无效，但 CTD 被其他机制设置 | start_button 实际上也未正常工作 | 整个开始流程都有问题 |

由于**本 commit 未修改 `on target` 部分**，仅移除了冗余的 scores 过滤，此问题未在本轮得到验证或修复。

**建议**: 在实际服务器上测试开始按钮是否能正常启动倒计时，以判断 `on target` 的实际行为。

---

### ⚠️ 3. `press_start_button.mcfunction` — interaction 数据每 tick 无条件清除

**文件**: `data/game/function/game/press_start_button.mcfunction:2`

```mcfunction
execute as @e[type=interaction,tag=start_button] if data entity @s interaction run data remove entity @s interaction
```

第 2 行**每 tick** 都会清除 start_button 的 interaction 数据，无论游戏状态如何（`game_state = 0` 或 `1`）：

| 游戏状态 | 第 1 行 (设置 CTD) | 第 2 行 (清除 interaction) |
|:-------:|:------------------:|:--------------------------:|
| `state=0` (未开始) | ✅ 执行 | ✅ 执行 |
| `state=1` (游戏中) | ❌ 不执行 | ✅ **仍执行** |

在 `state=1` 时，清除 interaction 数据是**无意义的操作**（因为第 1 行不会设置 CTD），但仍消耗性能。对于每 tick 执行的数据包来说，这是低效但不影响功能正确性的问题。

**可能的修复方案**: 将第 2 行也加上 game_state 条件过滤：
```mcfunction
execute as @e[type=interaction,tag=start_button] if data entity @s interaction if score state game_state matches 0 run data remove entity @s interaction
```

> 注：`detect_redeploy_button.mcfunction` 也有相同的模式（第 2 行和第 4 行无条件清除 interaction 数据），建议一并考虑。

---

## 执行顺序链（当前 HEAD）

```
tick.json → game:tick
  ├── teams/join_unselected
  ├── game/press_start_button     ← 本轮变更
  ├── redeploy/detect_redeploy_button
  ├── redeploy/redeploy_tick
  ├── game/start_button_l
  ├── interaction/redeploy
  ├── interaction/start
  └── scoreboard/game_start_ctd
```

---

## 📊 问题状态总览

| 类别 | 数量 | 编号 |
|:----:|:----:|:----:|
| 本轮已修复 | 1 | #F1 (原 v2#6) |
| 🔴 未修复严重问题 | 3 | #1, #2, #3 |
| 🟡 未修复中等问题 | 1 | #4 |
| 🟢 未修复轻微问题 | 5 | #5~#9 |
| ⚠️ 本轮新发现 | 3 | #P1, #P2, #P3 |

---

## 📎 文件归档状态

```
dubag/
├── dubag.md                  ← v4（本轮，新报告）
├── dubag_v3.md               ← v3 归档（原 dubag.md）
├── dubag_v2.md               ← v2 归档
├── dubag_v1.md               ← v1 归档
├── 函数健康基线记录.md        ← 基线记录
```

共 **5 份文件**（已达上限），后续 dubag 将轮替最旧的版本。

---

*本报告由 Deep Code 自动审查生成。*
