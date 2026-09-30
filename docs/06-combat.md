# 模块 06 · 战斗系统 — 设计文档

> 状态：✅ 基础完成（克制/先手/战法/经验/胜负验证过）；器械/特性触发/伤兵未做
> 定位：出征 + 回合制自动战斗 + 结算。

## 一、定位与目标
回合制自动战斗：兵种克制、先手、战法、经验结算、战利品。后续加器械 / 武将特性 / 伤兵。

## 二、核心公式（data/combat.json）
- 基础攻击 = 兵力 × (1 + 武力×attack_per_wuli 0.01)
- 兵种克制：骑克弓、弓克步、步克骑 → ×(1 + counter_bonus 0.15)
- 战法附加 = 兵力 × (skill_base 0.2 + 智力×skill_per_int 0.003) × skill_damage_mult 1.5
- 防御减免 = 1 − 统率×defense_per_tongshuai 0.008
- 先手：速度高者先攻，首击 ×(1 + speed_first_strike_bonus 0.1)
- 经验 = battle_exp_base 20 + 杀敌数×battle_exp_per_kill 0.1（胜方）

## 三、数据结构
- `Battle`（class_name，static resolve / _damage / _counter），MAX_ROUNDS 20
- 双方 side 字典：`{troops, wuli, tongshuai, int, speed, main_type}`
- `data/enemies.json`：`{id, name, troops, leader, loot}`

## 四、战斗流程（Game.battle）
校验兵力 → 扣兵 → Battle.resolve → 按比例返还幸存 → 战利品 + 经验

## 五、UI
- battle_panel：选将 + 配兵力（步/骑/弓 SpinBox）+ 选敌 + 出征 + 结果

## 六、待办
1. 武将特性触发（接 04 trait：拖刀计/喝退/火攻…）
2. 器械（机械营地制造，攻城加成）
3. 伤兵（伤兵营恢复，非直接死亡）
4. 战斗过程 UI（resolve 的 log 未展示）
