# 模块 03 · 城池与建筑 — 设计文档

> 状态：✅ 完成（7 建筑；缺 3 建筑 + 建筑位限制）
> 定位：City 模型、建筑升级/成本、城池特性、建筑位。

## 一、定位与目标
城池是经营与扩张的基本单位。每城有固有特性 + 可升级建筑。

## 二、建筑体系（设计文档定义 10 种）
- 核心（占位）：官府、农田、步兵营、酒馆
- 发展（按路线）：房屋、骑兵营地、弓兵营地、机械营地、科研院、伤兵营
- 当前已实现 7 种：government / farm / tavern / infantry_camp / cavalry_camp / archer_camp / house
- 缺：siege_camp(机械营地)、research(科研院)、infirmary(伤兵营)

## 三、数据结构
- `data/buildings.json`：`{id, name, category, max_level, base_cost, cost_mult, effect, desc}`
- `data/city_traits.json`：6 种城池特性定义
- `City.buildings{}`：building_id → level

## 四、核心规则
- 升级成本 = base_cost × cost_mult^当前级（`upgrade_cost()`）
- 建筑位限制：文档要求「城市建筑位有限」，当前未实现
- 城池特性：6 种固有、不可改（`city_trait()`）

## 五、接口
- `City`：building_level / building_def / upgrade_cost / can_upgrade / upgrade / city_trait / population_cap / farm_coeff / gov_coeff

## 六、UI
- `city_panel.gd`：概况 + 建筑列表 + 升级按钮

## 七、待办
- 补 3 建筑（siege_camp / research / infirmary）
- 建筑位限制
- 城池等级（tier）字段（接 09）
