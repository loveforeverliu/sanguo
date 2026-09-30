# 模块 08 · 存档与加载 — 设计文档

> 状态：⬜ 未做
> 定位：游戏状态序列化到 user://，读档恢复，存档兼容。

## 一、定位与目标
完整状态持久化：存档/读档 + 版本迁移。

## 二、范围
序列化 `Game` 的：turn / coin / grain / cities / player_generals（+ 09 的 Player）。

## 三、数据结构
- 模型加 `to_dict()` / `from_dict()`（City/General 已有 from_data，需补 to_dict；Player 接 09）
- 存档字段加 `version`，结构变更做迁移

## 四、接口
- `Game.save_to(path)` / `Game.load_from(path)`：JSON 落盘 user://

## 五、UI
- 主界面加「存档/读档」按钮

## 六、依赖
几乎全部模块（要序列化所有状态，尤其 09 的 Player）
