# 模块 02 · 经济与人口 — 设计文档

> 状态：✅ 完成并验证（数值逐项核对过）
> 定位：铜钱/粮草/人口三大资源的产出、消耗、回合结算、人口增长。

## 一、定位与目标
经营核心：资源生产与消耗的回合循环 + 人口增长模型。所有系数进 `data/economy.json`。

## 二、资源模型
- 铜钱：官府产出，用于升级建筑 / 招募武将 / 征兵。
- 粮草：农田产出，用于平民消耗 / 士兵驻扎 / 征兵。
- 人口：房屋提供上限 + 官府等级基础，粮食盈余自然增长；征兵时平民 → 士兵。

## 三、核心公式（对应 data/economy.json）
- 粮食产出 = 平民 × `farm_level_coeff[农田级]` × (1 + 特性 grain_bonus)
- 铜钱产出 = 平民 × `tax_rate` × `government_level_coeff[官府级]` × (1 + 特性 coin_bonus)
- 平民消耗 = 平民 × `civilian_grain_per_turn`(1.0)
- 士兵消耗 = 总兵 × `soldier_grain_per_turn`(1.0) + 总兵 × `soldier_coin_per_turn`(0.5)
- 人口上限 = `population_base`(500) + 官府级×`population_per_government`(200) + 房屋级×`population_per_house`(200)，×(1 + 特性 cap_bonus)
- 人口增长 = `population_growth_base`(3.0) × 粮草系数 × (上限 − 当前)/上限

## 四、关键系数（data/economy.json）
- start_coin 1000、start_grain 2000、tax_rate 0.25
- farm_level_coeff [0, 1.2, 1.5, 1.8, 2.2, 2.5]、government_level_coeff [0, 1.0, 1.3, 1.6, 2.0, 2.5]
- civilian_grain_per_turn 1.0、soldier_grain_per_turn 1.0、soldier_coin_per_turn 0.5
- population_base 500、population_per_government 200、population_per_house 200
- population_growth_base 3.0、population_growth_food_factor 0.5
- recruit_cost_grain 3.0、recruit_cost_coin 2.0
- grain_storage_per_government 5000、grain_storage_per_farm 500

## 五、城池特性加成（data/city_traits.json）
沃土(粮+) / 商贸(钱+) / 险要(防+驻军−) / 丰饶(人口上限+增长+) / 矿脉(器械+) / 边陲(征兵−人口增长−)

## 六、接口
- `City`：grain_output / coin_output / civilian_consumption / soldier_consumption / grow_population / population_cap / recruit_unit_cost / recruit / can_recruit
- `Game.end_turn()` / `_tick_city()`：回合结算（产出 → 消耗 → 增长，clamp ≥ 0）

## 七、待办
- 粮食存储上限（系数已留未启用）
- 科技加成、谋士加成（接 05）
