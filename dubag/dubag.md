# 🔍 Attack-Defense 数据包代码审查报告

| 项目 | 内容 |
|------|------|
| **数据包版本** | Minecraft 1.21.1 (pack_format 48) |
| **审查日期** | 2026-06-12 |
| **审查范围** | 全部 `.mcfunction`、`pack.mcmeta`、标签 JSON |
| **审查类型** | 仅提示潜在问题，不进行修复 |

---

## 🔴 严重问题（大概率会导致功能异常）

### 1. `start_button_l.mcfunction` — 分数比较语法错误

**文件**: `data/game/function/game/start_button_l.mcfunction`

**涉及行**: 第 2~21 行

**问题描述**:

```mcfunction
execute if score CTD game_start_ctd = 140 game_start_ctd run ...
```

在 Minecraft 中，`execute if score A obj1 = B obj2` 是比较 **两个实体/假玩家的分数值**，而非与整数直接比较。

- `= 140 game_start_ctd` 中的 `140` 被当作**假玩家名（fake player name）**
- 不存在名为 `140` 的实体，且它在 `game_start_ctd` 计分板中也没有分数，默认值为 **0**
- 因此条件等效于 `CTD == 0`，**永远无法匹配** CTD=140、120、100... 这些值

同理，第 21 行：
```mcfunction
execute if score CTD game_start_ctd >= 20 game_start_ctd run ...
```
也是比较 CTD 与假玩家 `20` 的分数（默认 0），而非与整数 20 比较。

**影响**: 所有触发条件全部失效，游戏无法正常开始。

---

### 2. `game_start_ctd.mcfunction` × `tick.mcfunction` — 时序冲突导致倒计时卡死

**文件**: `data/game/function/scoreboard/game_start_ctd.mcfunction`
**关联文件**: `data/game/function/tick.mcfunction`

**问题描述**:

`tick.mcfunction` 中每 tick 的执行顺序如下：

```
function game:scoreboard/game_start_ctd    ← 第 1 步
...
function game:game/start_button_l           ← 第 2 步
```

每 tick 的实际流程：

| Tick | 步骤 | 操作 | CTD 值 |
|:---:|:---:|------|:------:|
| 1 | 1 | `game_start_ctd`: 若非 -1 则设为 140 | **140** |
| 1 | 2 | `start_button_l` 第 1 行: CTD 减 1 | **139** |
| 2 | 1 | `game_start_ctd`: CTD=139 非 -1，设为 140 | **140** |
| 2 | 2 | `start_button_l` 第 1 行: CTD 减 1 | **139** |
| 3 | 1 | `game_start_ctd`: 再次设为 140 | **140** |
| 3 | 2 | 再次减 1 | **139** |
| ... | ... | ... | **循环往复** |

**CTD 永远在 139↔140 之间摆动，永远到不了 120、100、80... 更低的值。** 整个倒计时逻辑完全无法推进。

> 根源：`game_start_ctd` 在每 tick 无条件重置 CTD 的逻辑，与 `start_button_l` 的递减逻辑形成了冲突。

---

### 3. `join_defender.mcfunction` — 缺少 `@s`

**文件**: `data/game/function/teams/join_defender.mcfunction`

```mcfunction
team join defender      # ← 缺少 @s
tellraw @s {"translate":"team.defender.join","color":"blue"}
```

**对比** `join_attacker.mcfunction`：
```mcfunction
team join attacker @s   # ← 有 @s
tellraw @s {"translate":"team.attacker.join","color":"red"}
```

`team join` 命令如果不指定实体目标，**不会添加任何玩家**。因此防守方加入功能完全失效。

---

### 4. `join_unselected.mcfunction` — `tag` 与 `team` 混淆

**文件**: `data/game/function/teams/join_unselected.mcfunction`

```mcfunction
team join unselected @a[team=!attacker,team=!defender,team=!spectator,team=!unselected]
give @a[tag=unselected] kubejs:team_selector     # ← 应为 team=unselected
```

- 第 1 行：正确地将无队伍玩家加入 `unselected` 队伍 ✅
- 第 2 行：`@a[tag=unselected]` 匹配的是带有 `unselected` **标签（tag）** 的玩家
- 但没有任何玩家被赋予过 `unselected` 标签，`unselected` 是**队伍名（team）**而非标签
- 因此 `kubejs:team_selector` 物品**永远不会发放**给任何玩家

> 应为 `@a[team=unselected]`。

---

## 🟡 中等问题（部分功能受影响或逻辑缺陷）

### 5. `detect_redeploy_button.mcfunction` — 攻击方重部署按钮 response 未重置

**文件**: `data/game/function/redeploy/detect_redeploy_button.mcfunction`

```mcfunction
execute as @e[type=interaction,tag=attacker_redeploy] at @s on target if score state game_state matches 1 run function game:redeploy/redeploy_click
execute as @e[type=interaction,tag=attacker_redeploy] if data entity @s interaction run data remove entity @s interaction
data merge entity @e[type=interaction,tag=defender_redeploy,limit=1] {response:1b}                    # ← 仅有防守方
execute as @e[type=interaction,tag=defender_redeploy] at @s on target if score state game_state matches 1 run function game:redeploy/redeploy_click
execute as @e[type=interaction,tag=defender_redeploy] if data entity @s interaction run data remove entity @s interaction
```

- **第 3 行**：防守方重部署按钮每 tick 重置 `response:1b`，可重复点击 ✅
- **缺少对应行**：攻击方重部署按钮**没有**每 tick 重置 response
- 攻击方玩家点击一次重部署后，`interaction` 实体的 response 变为 `false`，之后再也无法点击

---

### 6. `start_button_l.mcfunction` — `spawnpoint` 脱离 `execute` 作用域

**文件**: `data/game/function/game/start_button_l.mcfunction` 第 13、15 行

```mcfunction
# 第 12 行：在 execute 内部
execute if score CTD game_start_ctd = 20 game_start_ctd run execute as @a[team=attacker] at @s run tp @s -1481.33 200.00 1874.86
# 第 13 行：脱离 execute，无条件执行
spawnpoint @a[team=attacker] -1481 200 1874
```

- 第 13 行的 `spawnpoint` **不在**第 12 行的 `execute` 的 `run` 范围内
- 虽然 `spawnpoint` 本身会在每个满足条件的 tick 执行一次（因为第 20 行会重置 CTD），但风格不一致，阅读时易误解
- 同理第 15 行也有同样问题

> 注：此问题在当前受问题 #1 和 #2 影响无法显现，但在修复倒计时后需要注意。

---

## 🟢 轻微 / 建议性问题

### 7. `pack.mcmeta` — `min_format`/`max_format` 冗余

**文件**: `pack.mcmeta`

```json
{
  "pack_format": 48,
  "supported_formats": [48, 101],
  "min_format": 48,
  "max_format": [101, 1]
}
```

- `supported_formats` 已经声明了兼容范围（48~101）
- 额外 `min_format`/`max_format` 在此上下文中冗余
- `max_format: [101, 1]` 的数组格式（feature 版本号）对纯数据包意义不大
- 建议仅保留 `supported_formats`

---

### 8. 文件夹命名疑似拼写错误

**路径**: `data/game/function/interation/`

- 文件夹名 `interation` 疑似应为 `interaction`
- 与内容无关，但影响项目整洁度

---

### 9. 项目概览中引用的 `show_team_actionbar.mcfunction` 不存在

**文件**: `帮助/项目概览.md`

- 项目概览中描述了 `show_team_actionbar` 函数并绘制在数据流图中
- 但 `data/game/function/teams/` 目录下**没有该文件**
- 可能导致 `tick.mcfunction` 未来计划引用此函数时出错

---

### 10. `load.mcfunction` 中执行 `join_unselected`

**文件**: `data/game/function/load.mcfunction`

```mcfunction
function game:teams/join_unselected
```

- 数据包加载时，`@a` 选择器可能为空（玩家尚未完全加入世界）
- `team join unselected @a[...]` 当目标不存在时无效果，无害但无效
- `give @a[tag=unselected]` 结合问题 #4，确定无效

---

## 📊 问题优先级总览

| 优先级 | 编号 | 文件 | 问题简述 |
|:---:|:---:|------|---------|
| 🔴 致命 | #1 | `start_button_l.mcfunction` | 分数比较语法错误，所有触发条件失效 |
| 🔴 致命 | #2 | `game_start_ctd.mcfunction` + `tick.mcfunction` | CTD 每 tick 被重置，倒计时无法推进 |
| 🔴 致命 | #3 | `join_defender.mcfunction` | 缺少 `@s`，防守方无法加入队伍 |
| 🔴 致命 | #4 | `join_unselected.mcfunction` | `tag=unselected` 应为 `team=unselected` |
| 🟡 严重 | #5 | `detect_redeploy_button.mcfunction` | 攻击方重部署按钮 response 未重置 |
| 🟡 中等 | #6 | `start_button_l.mcfunction` | `spawnpoint` 脱离 execute 作用域 |
| 🟢 轻微 | #7 | `pack.mcmeta` | `min_format`/`max_format` 冗余 |
| 🟢 轻微 | #8 | 文件夹命名 | `interation/` 疑似拼写错误 |
| 🟢 轻微 | #9 | `帮助/项目概览.md` | 引用的 `show_team_actionbar` 文件不存在 |
| 🟢 轻微 | #10 | `load.mcfunction` | 加载时执行队伍归位可能无效 |

---

## 🔧 技术细节补充

### 1.21.1 语法要点

| 操作 | 正确语法 | 错误语法 |
|------|---------|---------|
| 与整数比较 | `if score A obj matches 140` | `if score A obj = 140 obj` |
| 与范围比较 | `if score A obj matches 1..` | `if score A obj >= 1 obj` |
| 指定队伍加入者 | `team join attacker @s` | `team join attacker` |

### 执行顺序链

```
load.json → game:load
  ├── teams/join_unselected       (时机过早，@a 可能为空)
  ├── scoreboard/create_scoreboards
  └── scoreboard/load_scoreboard_settings

tick.json → game:tick
  ├── teams/join_unselected
  ├── game/press_start_button     (依赖 interaction 实体)
  ├── game/start_button_l         (倒计时递减 + 触发条件)
  ├── scoreboard/game_start_ctd   (重置 CTD → 与上一条冲突)
  ├── redeploy/detect_redeploy_button
  ├── redeploy/redeploy_tick
  └── interation/redeploy         (每次 tick 设置 response:1b)
```

---

*本报告由 Deep Code 自动审查生成。*
