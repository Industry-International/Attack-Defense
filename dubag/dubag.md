# Attack-Defense 数据包代码审查报告 v5

| 项目 | 内容 |
|------|------|
| **数据包版本** | Minecraft 1.21.1 (pack_format 48) |
| **审查日期** | 2026-06-12 |
| **审查模式** | 增量审查（仅检查变更文件 + 引用文件） |
| **当前 HEAD** | `bb6bd88` (未提交的工作树变更) |
| **变更来源** | 工作树未暂存修改 |
| **参考上一份** | `dubag/dubag_v4.md` (v4) |
| **对比基线** | `dubag/函数健康基线记录.md` (commit `a9e2610`) + `dubag/函数健康记录_v4.md` (commit `bb6bd88`) |

---

## 本轮变更文件

```
git diff HEAD --name-only -- data/
```

**变更文件（1 个）：**
- `data/game/function/teams/join_defender.mcfunction`

**变更摘要：** 在 `team join defender` 后添加了 `@s`，修复了长期存在的防守方无法加入队伍的问题（已报告于 v1#3 → v2#1 → v3#1 → v4#1）。

### 变更 diff

```diff
-team join defender
+team join defender @s
```

### 引用分析

```
join_defender.mcfunction
  └── 调用方: 未在 data/ 中找到直接引用（推测由 KubeJS 或其他外部模组触发）
  └── 对比参照: join_attacker.mcfunction (有 @s) / join_spectator.mcfunction (有 @s)
```

---

## 已修复问题（本轮仅简单提示 + 引用）

| 编号 | 源报告链 | 问题简述 | 修复方式 |
|:----:|:--------:|---------|---------|
| #1 | v1#3 → v2#1 → v3#1 → v4#1 | **`join_defender.mcfunction` 缺少 `@s`** | `team join defender` → `team join defender @s` ✅ |

---

## 仍未修复的已知问题（来自 v4）

以下问题自 v4 报告以来**未发生任何变更**，仍存在。完整描述请参阅 `dubag/dubag_v4.md`。

### 🔴 严重问题（2 项）

| # | 文件 | 问题 | 源报告 |
|:-:|------|------|:------:|
| 1 | `redeploy/detect_redeploy_button.mcfunction` + `redeploy_click.mcfunction` | **`on target` 在 interaction 实体上无效** — 重部署系统完全失效 | v2#2 |
| 2 | `game/start_button_l.mcfunction:24` | **旧语法遗漏** — `>= 20 game_start_ctd` 仍未改用 `matches 20..`，CTD>20 时每 tick 重置倒计时 | v2#3 |

### 🟡 中等问题（1 项）

| # | 文件 | 问题 | 源报告 |
|:-:|------|------|:------:|
| 3 | `game/start_button_l.mcfunction:17-18` | 防守方 tp Y=199 vs spawnpoint Y=200 不一致 | v1#6 |

### 🟢 轻微 / 建议性问题（7 项）

| # | 文件 | 问题 | 源报告 |
|:-:|------|------|:------:|
| 4 | `press_start_button.mcfunction:1` | `on target` 模式与 redeploy 一致，行为待验证 | v4#P2 |
| 5 | `press_start_button.mcfunction` | 缺少文件末尾换行符 | v4#P1 |
| 6 | `press_start_button.mcfunction:2` | interaction 数据每 tick 无条件清除（含 game_state=1 时） | v4#P3 |
| 7 | `pack.mcmeta` | `min_format`/`max_format` 字段冗余 | v1#7 |
| 8 | `帮助/项目概览.md` | 引用 `show_team_actionbar` 不存在 | v1#9 |
| 9 | `redeploy/redeploy_tick.mcfunction` | 职业标签依赖模组，无回退机制 | v2#10 |
| 10 | `sounds/` | 声音事件命名空间前缀风格不一致 | v2#11 |

> 注：`load.mcfunction` 中 `@a` 加载时可能为空的问题（v1#10）已在 v4 中被确认影响很小，已从本表移除，但仍可在旧报告中查阅。

---

## 本轮新发现的潜在问题

### ⚠️ 1. `join_defender.mcfunction` — 缺少文件末尾换行符

**文件**: `data/game/function/teams/join_defender.mcfunction`

`git diff` 显示文件末尾标记为 `\ No newline at end of file`。第三行后无换行符。

此问题与 `press_start_button.mcfunction`（v4#P1）相同，不影响功能但 git 会持续标记差异。

**可能的修复方案**: 在文件末尾添加一个空行。

---

### ⚠️ 2. `join_defender.mcfunction` — 修复仅限于语法，未涉及调用方验证

**文件**: `data/game/function/teams/join_defender.mcfunction`

此文件在数据包内**没有任何 `.mcfunction` 显式调用它**（通过 `function game:teams/join_defender`）。

| 函数 | 被数据包内调用？ |
|------|:--------------:|
| `join_attacker` | ❌ 也未在数据包内找到显式调用 |
| `join_defender` | ❌ 未找到显式调用 |
| `join_spectator` | ❌ 未找到显式调用 |
| `leave_team` | ❌ 未找到显式调用 |

所有队伍加入函数均疑似由**外部模组**（如 KubeJS 物品交互脚本）通过 `function game:teams/join_defender` 调用。如果外部模组未正确配置调用，或传入的 `@s` 上下文不正确，修复 `@s` 本身可能不足以解决问题。

**建议**: 确认外部模组（KubeJS 等）的触发脚本正确调用了 `function game:teams/join_defender`，且执行上下文为点击物品的玩家。

---

## 执行顺序链（当前状态）

```
tick.json → game:tick
  ├── teams/join_unselected
  ├── game/press_start_button
  ├── redeploy/detect_redeploy_button
  ├── redeploy/redeploy_tick
  ├── game/start_button_l
  ├── interaction/redeploy
  ├── interaction/start
  └── scoreboard/game_start_ctd

（注: join_defender/attacker/spectator/leave 等不在此链中，由外部模组触发调用）
```

---

## 📊 问题状态总览

| 类别 | 数量 | 编号 |
|:----:|:----:|:----:|
| 本轮已修复 | 1 | 原 v4#1 (v1#3 → ... → v4#1) |
| 🔴 未修复严重问题 | 2 | #1, #2 |
| 🟡 未修复中等问题 | 1 | #3 |
| 🟢 未修复轻微问题 | 5 | #5~#10 (v4#P1~P3 转入轻微) |
| ⚠️ 本轮新发现 | 2 | #N1, #N2 |

---

## 📎 文件归档状态

```
dubag/
├── dubag.md                  ← v5（本轮，新报告）
├── dubag_v4.md               ← v4 归档
├── dubag_v3.md               ← v3 归档
├── dubag_v2.md               ← v2 归档
├── dubag_v1.md               ← v1 归档
├── 函数健康基线记录.md        ← 基线记录
├── 函数健康记录_v4.md         ← v4 健康记录
```

共 **5 份 dubag.md**（已达上限），后续 dubag 将轮替最旧的 `dubag_v1.md`。

---

*本报告由 Deep Code 自动审查生成。*
