# 🔍 Attack-Defense 数据包代码审查报告 v3

| 项目 | 内容 |
|------|------|
| **数据包版本** | Minecraft 1.21.1 (pack_format 48) |
| **审查日期** | 2026-06-12 |
| **审查模式** | 增量审查（仅检查变更文件） |
| **参考上一份** | `dubag/dubag_v2.md` |
| **对比基线** | `dubag/函数健康基线记录.md` (commit `a9e2610`) |

---

## ⏳ 本轮变更分析

### 文件变更检查

```
git diff a9e2610 HEAD --name-only -- data/ pack.mcmeta
```

**结果：无输出 → 源文件无任何变更。**

自 v2 dubag 以来，所有数据包源文件 (`data/` 目录和 `pack.mcmeta`) 均未发生任何修改。因此此轮 dubag **没有新的代码变更需要审查**。

### 引用链检查

由于无文件变更，引用链也无需重新扫描。

---

## 已知问题状态（与 v2 完全一致）

以下问题均未获得修复，详情请参阅 `dubag/dubag_v2.md`：

### 🔴 仍存在的严重问题（3 项）

| # | 文件 | 问题 | 首次报告 |
|:-:|------|------|:-------:|
| 1 | `teams/join_defender.mcfunction` | **缺少 `@s`** — 防守方无法加入队伍 | v1#3 |
| 2 | `redeploy/detect_redeploy_button.mcfunction` + `redeploy_click.mcfunction` | **`on target` 无效** — 重部署系统完全失效，分数被设置在 interaction 实体上而非玩家 | v2#2 |
| 3 | `game/start_button_l.mcfunction:24` | **旧语法遗漏** — `>= 20 game_start_ctd` 仍未改用 `matches 20..`，倒计时异常重置 | v2#3 |

### 🟡 仍存在的中等问题（2 项）

| # | 文件 | 问题 | 首次报告 |
|:-:|------|------|:-------:|
| 4 | `redeploy/redeploy_click.mcfunction` | interaction 数据处理风格与开始按钮不一致 | v2#4 |
| 5 | `game/start_button_l.mcfunction:17-18` | 防守方 tp Y=199 vs spawnpoint Y=200 不一致 | v1#6 |

### 🟢 仍存在的轻微问题（6 项）

| # | 文件 | 问题 | 首次报告 |
|:-:|------|------|:-------:|
| 6 | `game/press_start_button.mcfunction` | 双重 game_state 检查，冗余但安全 | v2#6 |
| 7 | `pack.mcmeta` | 字段冗余 | v1#7 |
| 8 | 帮助/项目概览.md | 引用 `show_team_actionbar` 文件不存在 | v1#9 |
| 9 | `load.mcfunction` | 加载时执行时机可能过早 | v1#10 |
| 10 | `redeploy/redeploy_tick.mcfunction` | 职业标签依赖模组，无回退机制 | v2#10 |
| 11 | `sounds/` | 声音事件命名空间前缀风格不一致 | v2#11 |

---

## 📋 基线参考

已创建 `dubag/函数健康基线记录.md`，包含：
- **基线 commit**: `a9e26108b501c80148aab9c8917b973867f6c066`
- 15 个无已知问题的函数 ✅
- 4 个存在已知问题的函数 ⚠️
- 3 个轻微建议的函数 🟡
- 后续 dubag 使用说明

### 后续 dubag 流程

```
1. git diff <基线HASH> HEAD --name-only -- data/ pack.mcmeta
   ↓
2. 有变更? → 仅审查变更文件 + 引用文件
   无变更? → 报告无变更，引用上一份 dubag
   ↓
3. 更新 dubag.md（保留最多5份）
```

---

## 📎 文件归档状态

```
dubag/
├── dubag.md                  ← v3（本轮，无变更报告）
├── dubag_v2.md               ← v2 归档
├── dubag_v1.md               ← v1 归档
├── 函数健康基线记录.md        ← 基线记录（新增）
```

共 **4 份文件**（上限 5 份），后续 dubag 将继续轮替。

*本报告由 Deep Code 自动审查生成。*
