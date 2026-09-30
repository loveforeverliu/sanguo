# 模块 04 · 武将系统 — 设计文档

> 状态：🟡 部分（成长/酒馆/名将数据完成；拜访/俘虏/劝降/忠诚未做）
> 定位：武将成长 + 名将系统。

## 一、定位与目标
武将成长（等级/经验/加点/练兵）+ 名将（品质/特性/忠诚/拜访/俘虏劝降）。

## 二、四维属性
武力(attack) / 统率(defense+leadership) / 智力(skill) / 速度(first-strike)

## 三、成长系统（data/general_growth.json）
- 等级上限 100
- 品质点表：普通{1固定, 2自由} 优秀{2, 2} 稀有{3, 2} 史诗{4, 2} 传奇{5, 2}
- 经验曲线：exp_to_next = exp_base(100) × exp_growth(1.2)^(level−1)
- 升级：等级+1、固定点按「固定点/级」自动平均分配、自由点存入 free_points
- 练兵：消耗 tier 化铜钱/粮草，得 drill_exp(100)
- 战斗经验：battle_exp_base(20) + 杀敌数 × battle_exp_per_kill(0.1)

## 四、名将系统
- 21 名将（data/generals.json）：id / name / quality / faction / troop_type / initial_loyalty / trait{name, desc} / base_attrs
- 品质：普通/优秀/稀有/史诗/传奇；酒馆随机仅出 普通60%/优秀25%/稀有15%（史诗传奇仅名将）
- 特性 trait（战斗触发，接 06）

## 五、忠诚度（data/general_growth.json#loyalty，未接入逻辑）
- 0~100；升：官职/赏赐/连胜；降：闲置/战败/被劝降；低忠诚有叛逃风险
- 拜访 / 俘虏劝降（未做）

## 六、接口
- `General`：from_data / get_attr / exp_to_next / gain_exp / spend_free_point / _auto_fixed
- `Game`：generate_random_general / recruit_from_tavern / drill / _drill_tier / _random_name

## 七、UI
- general_panel（加点/练兵）、tavern_panel（酒馆）

## 八、待办
1. 拜访（派使者招揽在野名将）
2. 俘虏劝降（攻占后按品质概率俘虏 → 劝降/释放/处决）
3. 忠诚度变动 + 叛逃
4. 特性战斗触发（接 06）
