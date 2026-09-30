# 三国时代 · 开发文档

单机三国回合制策略/经营游戏（Godot 4.7 + GDScript，目标 Steam）。本目录按模块拆分，每个模块一份文档；开发某模块时**只读本文档 + 对应模块文档**即可开工，无需背负全部历史上下文。

## 模块地图

| # | 模块 | 状态 | 文档 | 核心文件 |
|---|------|------|------|----------|
| 01 | 核心框架 | ✅ 完成 | [01-core.md](01-core.md) | `scripts/autoload/game.gd`、`scripts/main.gd`、`scripts/ui/panel_base.gd` |
| 02 | 经济与人口 | ✅ 完成 | [02-economy.md](02-economy.md) | `scripts/models/city.gd`（经济方法）、`data/economy.json` |
| 03 | 城池与建筑 | ✅ 完成 | [03-city.md](03-city.md) | `scripts/models/city.gd`、`data/buildings.json`、`data/city_traits.json`、`scripts/ui/city_panel.gd` |
| 04 | 武将系统 | 🟡 部分 | [04-generals.md](04-generals.md) | `scripts/models/general.gd`、`data/generals.json`、`data/general_growth.json` |
| 05 | 谋士与策略 | ⬜ 未做 | [05-advisors.md](05-advisors.md) | 待建 |
| 06 | 战斗系统 | ✅ 基础完成 | [06-combat.md](06-combat.md) | `scripts/combat/battle.gd`、`data/enemies.json`、`data/combat.json`、`scripts/ui/battle_panel.gd` |
| 07 | 世界与扩张 | ⬜ 未做 | [07-world.md](07-world.md) | 待建 |
| 08 | 存档与加载 | ⬜ 未做 | [08-save.md](08-save.md) | 待建 |
| 09 | 玩家与势力 | 🟡 设计大纲 | [09-player.md](09-player.md) | 待建（依赖 07） |

状态图例：✅ 完成并验证 · 🟡 部分完成/设计大纲 · ⬜ 未开始

## 全局约定（所有模块都要遵守）

- **数据/系数按模块分文件**：每个模块的数据与系数在 `data/` 下独立文件，改数值只改对应文件、不全局检索（详见 `docs/data-convention.md`）；代码里不放魔法数字。
- **warning 当 error**：项目设置把警告当错误。`:=` 不能从 Variant 推断 —— `Dictionary.get()`、`Array/Dictionary` 下标返回 Variant，必须显式标类型（如 `var x: String = arr[i]`）。
- **数据分层**：静态数据放 `data/*.json`（运行时 `FileAccess` 读）；模型是 `class_name ... extends RefCounted`（City/General/Battle）；全局状态在 autoload `Game`。
- **UI 代码生成**：不手写 .tscn 布局；面板继承 `PanelBase`（提供 `make_label/make_button/make_title/clear`），实现 `refresh()`。
- **状态刷新模式**：模型方法静默改状态；UI 面板在操作成功后 `Game.state_changed.emit()`；`main.gd` 的 `_on_state_changed` 刷新资源条 + 当前面板（面板重建用 `call_deferred`，避免在按钮回调里 `free()` 那个按钮）。
- **中文**：`SystemFont` 回退（微软雅黑/SimHei/思源黑体），theme 在 `main.gd` 的 `_make_theme()`。
- **测试**：godot-ai MCP 的 `game_eval` 跑 GDScript 断言；`filesystem_manage(scan)` 注册 class_name；`project_run` 启动。

## 原始设计文档

设计源文档在 `H:\三国时代.md`（三份 Word 合并：武将成长 / 名将系统 / 游戏设计设定集）。各模块文档已提炼对应部分，冲突时以模块文档为准。
