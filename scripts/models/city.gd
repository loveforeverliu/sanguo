class_name City
extends RefCounted
## 城池：平民/士兵/建筑/特性，负责产出消耗、征兵、建筑升级。


var id: String = ""
var name: String = ""
var trait_id: String = ""            # 城池特性 id，见 data/city_traits.json
var civilians: int = 500             # 平民
var soldiers: Dictionary = {"步兵": 0, "骑兵": 0, "弓兵": 0}
var buildings: Dictionary = {}       # building_id -> level
var advisor_id: String = ""          # 谋士 id（后续版本）
var policy: String = "normal"        # 城市策略
var faction_id: String = ""          # 所属势力，见 data/factions.json
var tier: int = 1                    # 城池等级（待细化）
var x: float = 0.0                   # 地图坐标 x
var y: float = 0.0                   # 地图坐标 y
var state_id: String = ""            # 所属州 id
var seat_name: String = ""           # 郡治县名


func total_soldiers() -> int:
	var n := 0
	for k in soldiers:
		n += int(soldiers[k])
	return n


func city_trait() -> Dictionary:
	return Game.city_traits.get(trait_id, {})


func population_cap() -> int:
	var e: Dictionary = Game.economy
	var gov := int(buildings.get("government", 0))
	var house := int(buildings.get("house", 0))
	var cap := int(e.get("population_base", 500))
	cap += gov * int(e.get("population_per_government", 200))
	cap += house * int(e.get("population_per_house", 200))
	cap = int(float(cap) * (1.0 + float(city_trait().get("population_cap_bonus", 0.0))))
	return cap


func _level_coeff(key: String, level: int) -> float:
	var arr: Array = Game.economy.get(key, [0.0])
	level = clampi(level, 0, arr.size() - 1)
	return float(arr[level])


func farm_coeff() -> float:
	return _level_coeff("farm_level_coeff", int(buildings.get("farm", 0)))


func gov_coeff() -> float:
	return _level_coeff("government_level_coeff", int(buildings.get("government", 0)))


func grain_output() -> float:
	var out := float(civilians) * farm_coeff()
	out *= 1.0 + float(city_trait().get("grain_bonus", 0.0))
	return out


func coin_output() -> float:
	var e: Dictionary = Game.economy
	var rate := float(e.get("tax_rate", 0.25))
	var out := float(civilians) * rate * gov_coeff()
	out *= 1.0 + float(city_trait().get("coin_bonus", 0.0))
	return out


func civilian_consumption() -> float:
	var per := float(Game.economy.get("civilian_grain_per_turn", 1.0))
	return float(civilians) * per


func soldier_consumption() -> Dictionary:
	var e: Dictionary = Game.economy
	var g := float(e.get("soldier_grain_per_turn", 1.0))
	var c := float(e.get("soldier_coin_per_turn", 0.5))
	var n := total_soldiers()
	return {"grain": float(n) * g, "coin": float(n) * c}


func grow_population() -> void:
	var e: Dictionary = Game.economy
	var base := float(e.get("population_growth_base", 3.0))
	var food_factor := 1.0
	if Game.grain <= 0.0:
		food_factor = 0.0
	elif Game.grain < civilian_consumption():
		food_factor = float(e.get("population_growth_food_factor", 0.5))
	var cap := population_cap()
	var cap_factor := 0.0
	if cap > 0:
		cap_factor = clampf(float(cap - civilians) / float(cap), 0.0, 1.0)
	var growth := base * food_factor * cap_factor
	growth *= 1.0 + float(city_trait().get("population_growth_bonus", 0.0))
	civilians = clampi(civilians + int(growth), 0, cap)


func recruit_unit_cost(res: String) -> float:
	var e: Dictionary = Game.economy
	var key := "recruit_cost_grain" if res == "grain" else "recruit_cost_coin"
	var base := float(e.get(key, 1.0))
	base *= 1.0 - float(city_trait().get("recruit_cost_reduce", 0.0))
	return base


func can_recruit(count: int) -> bool:
	if count <= 0 or count > civilians:
		return false
	var cost_g := recruit_unit_cost("grain") * float(count)
	var cost_c := recruit_unit_cost("coin") * float(count)
	return Game.grain >= cost_g and Game.coin >= cost_c


func recruit(troop_type: String, count: int) -> bool:
	if not can_recruit(count):
		return false
	var cost_g := recruit_unit_cost("grain") * float(count)
	var cost_c := recruit_unit_cost("coin") * float(count)
	Game.grain -= cost_g
	Game.coin -= cost_c
	civilians -= count
	soldiers[troop_type] = int(soldiers.get(troop_type, 0)) + count
	return true


func building_def(building_id: String) -> Dictionary:
	return Game.buildings.get(building_id, {})


func building_level(building_id: String) -> int:
	return int(buildings.get(building_id, 0))


func upgrade_cost(building_id: String) -> int:
	var b := building_def(building_id)
	var base := float(b.get("base_cost", 100))
	var mult := float(b.get("cost_mult", 1.7))
	return int(base * pow(mult, building_level(building_id)))


func can_upgrade(building_id: String) -> bool:
	var b := building_def(building_id)
	if b.is_empty():
		return false
	if building_level(building_id) >= int(b.get("max_level", 5)):
		return false
	return Game.coin >= float(upgrade_cost(building_id))


func upgrade(building_id: String) -> bool:
	if not can_upgrade(building_id):
		return false
	Game.coin -= float(upgrade_cost(building_id))
	buildings[building_id] = building_level(building_id) + 1
	return true
