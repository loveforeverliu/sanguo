# 数据与系数规范（开发规则）

> 核心原则：**每个模块的数据与数值系数，独立存放在该模块专属文件；改数值只改对应文件，不全局检索、不在代码里散落魔法数字。**

## 一、规则
1. 每个模块的静态数据（定义表）与数值系数（比例/成本/加成），放在 `data/` 下该模块专属的文件。
2. 改某个模块的数值 → 打开该模块文件直接改，不改代码、不全局搜索。
3. 代码里不放魔法数字；任何可调数值都落到对应模块的数据文件。
4. 新增模块时，同步新增其数据文件。
5. 数据文件用 JSON，运行时 `FileAccess` + `JSON.parse_string` 加载。

## 二、文件映射
| 模块 | 数据文件 | 内容 |
|------|---------|------|
| 01 核心框架 | `data/config.json` | 全局/开局设置（起始资源、初始回合等非模块专属项） |
| 02 经济与人口 | `data/economy.json` | 产出/消耗/人口/征兵/存储/税率系数 |
| 03 城池与建筑 | `data/buildings.json`、`data/city_traits.json` | 建筑定义、城池特性 |
| 04 武将系统 | `data/generals.json`、`data/general_growth.json` | 名将数据、成长+忠诚系数 |
| 05 谋士与策略 | `data/advisors.json` | 谋士类型、城市策略 |
| 06 战斗系统 | `data/combat.json`、`data/enemies.json` | 战斗系数、敌人 |
| 07 世界与扩张 | `data/factions.json`、`data/cities.json` | 势力、城池 |
| 08 存档与加载 | （无静态数据，运行时写 user://） | — |
| 09 玩家与势力 | `data/player.json` | 影响力/自立/统一/官爵系数 |

## 三、当前状态（已拆分）
- `data/config.json` — 全局/开局设置（start_coin / start_grain）
- `data/economy.json` — 经济系数
- `data/general_growth.json` — 武将成长 + 忠诚系数
- `data/city_traits.json` — 城池特性
- `data/combat.json` — 战斗系数

## 四、命名约定
- 文件名：`data/<模块名>.json`（小写英文，snake_case）。
- 键名语义化（如 `combat.counter_bonus`、`economy.tax_rate`）。
- 等级系数表用 0 基数组，下标即等级（如 `farm_level_coeff[3]` = 3 级农田系数）。
