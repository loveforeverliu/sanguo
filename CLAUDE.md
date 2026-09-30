# 三国时代（sanguo）

单机三国回合制策略/经营游戏，Godot 4.7 + GDScript，目标 Steam。项目根 `H:\godotWork\sanguo\`。

## 开工前必读
- 模块拆分与全局约定：`docs/README.md`（先读这个）。
- 各模块文档：`docs/01-core.md` … `docs/08-save.md`。

## 关键约定（速记）
- 数据/系数按模块分文件：改数值只改对应模块文件（见 `docs/data-convention.md`），代码里不放魔法数字。
- warning 当 error：`:=` 不能从 Variant 推断，Dictionary.get / 下标要显式标类型。
- autoload `Game`（`scripts/autoload/game.gd`），信号 `state_changed`。
- UI 代码生成，面板继承 `PanelBase`。
- 开发/测试用 godot-ai MCP（game_eval / scan / project_run）。

## 设计源文档
`H:\三国时代.md`（武将成长 + 名将系统 + 游戏设计设定集）。
