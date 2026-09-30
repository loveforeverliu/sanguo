# 模块 01 · 核心框架 — 设计文档

> 状态：✅ 完成并验证
> 定位：项目骨架，所有模块挂靠其上。

## 一、定位与目标
提供运行外壳：Godot 项目配置、全局单例 `Game`、静态数据加载、UI 外壳（资源条 + 导航 + 面板容器）、主题/字体。其它模块在此骨架上扩展。

## 二、技术栈
- Godot 4.7.1，GL Compatibility，1920×1080 canvas_items stretch（缩放自适应）。
- GDScript（非 C#）；UI 用 Control 节点代码生成，不手写 .tscn 布局。
- 中文 SystemFont 回退：微软雅黑 / SimHei / 思源黑体（`main.gd._make_theme()`）。

## 三、核心结构
- `scripts/autoload/game.gd` — autoload "Game"（`extends Node`）。全局状态唯一持有者：config/buildings/generals_roster/roster_by_id/enemies、turn/coin/grain/cities/player_generals。信号 `state_changed`。
- `scripts/main.gd` — 主场景根（`extends Control`）。`_build_shell()` 建顶部资源条 + 左侧导航 + `_content`；`_panels` 字典（导航名 → 面板）；`_switch(key)` 切换；`_on_state_changed` 刷新。
- `scripts/ui/panel_base.gd` — `class_name PanelBase extends PanelContainer`，提供 `make_label/make_button/make_title/clear`，子类实现 `refresh()`。
- `scenes/main.tscn` — 根 Control 挂 `main.gd`。

## 四、状态刷新模式
模型方法静默改状态 → UI 面板操作成功后 `Game.state_changed.emit()` → `main.gd._on_state_changed` 刷新资源条 + 当前面板（`call_deferred` 延迟重建，避免在按钮回调里 free 该按钮）。

## 五、数据分层约定
- 静态数据：`data/*.json`，运行时 `FileAccess` + `JSON.parse_string`。
- 模型：`class_name ... extends RefCounted`（City/General/Battle）。
- 全局状态：autoload `Game`。
- **系数集中在 `data/config.json`**，代码无魔法数字。

## 六、全局约束
- warning 当 error：`:=` 不能从 Variant 推断（`Dictionary.get` / 下标返回 Variant，需显式标类型）。

## 七、测试方式
- godot-ai MCP：`game_eval` 跑 GDScript 断言、`filesystem_manage(scan)` 注册 class_name、`project_run` 启动。
