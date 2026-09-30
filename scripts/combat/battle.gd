class_name Battle
extends RefCounted
## 战斗结算器：回合制自动战斗，兵种克制 + 先手 + 战法。
## 双方 side 字典：{troops, wuli, tongshuai, int, speed, main_type}


const MAX_ROUNDS := 20


static func resolve(a: Dictionary, d: Dictionary) -> Dictionary:
	var at: Dictionary = a.duplicate(true)
	var dt: Dictionary = d.duplicate(true)
	var a_first := float(a.get("speed", 0.0)) >= float(d.get("speed", 0.0))
	var rounds := 0
	var log: Array = []
	while float(at.get("troops", 0.0)) > 0.0 and float(dt.get("troops", 0.0)) > 0.0 and rounds < MAX_ROUNDS:
		rounds += 1
		if a_first:
			dt["troops"] = float(dt.get("troops", 0.0)) - _damage(at, dt, rounds == 1)
			if float(dt.get("troops", 0.0)) > 0.0:
				at["troops"] = float(at.get("troops", 0.0)) - _damage(dt, at, false)
		else:
			at["troops"] = float(at.get("troops", 0.0)) - _damage(dt, at, rounds == 1)
			if float(at.get("troops", 0.0)) > 0.0:
				dt["troops"] = float(dt.get("troops", 0.0)) - _damage(at, dt, false)
		log.append("回合%d：我方剩 %d / 敌方剩 %d" % [rounds, int(maxf(float(at.get("troops", 0.0)), 0.0)), int(maxf(float(dt.get("troops", 0.0)), 0.0))])

	var a_left := int(maxf(float(at.get("troops", 0.0)), 0.0))
	var d_left := int(maxf(float(dt.get("troops", 0.0)), 0.0))
	return {
		"winner": "attacker" if a_left > 0 else "defender",
		"rounds": rounds,
		"attacker_troops_left": a_left,
		"defender_troops_left": d_left,
		"log": log,
	}


static func _damage(att: Dictionary, df: Dictionary, first: bool) -> float:
	var cfg: Dictionary = Game.combat
	var troops := float(att.get("troops", 0.0))
	# 基础攻击 = 兵力 × (1 + 武力 × attack_per_wuli)
	var power := troops * (1.0 + float(att.get("wuli", 0.0)) * float(cfg.get("attack_per_wuli", 0.01)))
	# 兵种克制
	power *= _counter(str(att.get("main_type", "")), str(df.get("main_type", "")), float(cfg.get("counter_bonus", 0.15)))
	# 战法附加 = 兵力 × (skill_base + 智力 × skill_per_int) × skill_damage_mult
	power += troops * (float(cfg.get("skill_base", 0.2)) + float(att.get("int", 0.0)) * float(cfg.get("skill_per_int", 0.003))) * float(cfg.get("skill_damage_mult", 1.5))
	# 防御减免 = 1 - 统率 × defense_per_tongshuai
	power *= maxf(0.0, 1.0 - float(df.get("tongshuai", 0.0)) * float(cfg.get("defense_per_tongshuai", 0.008)))
	# 先手加成
	if first:
		power *= 1.0 + float(cfg.get("speed_first_strike_bonus", 0.1))
	return power


static func _counter(a: String, d: String, bonus: float) -> float:
	# 骑克弓、弓克步、步克骑
	if a == "骑兵" and d == "弓兵":
		return 1.0 + bonus
	if a == "弓兵" and d == "步兵":
		return 1.0 + bonus
	if a == "步兵" and d == "骑兵":
		return 1.0 + bonus
	return 1.0
