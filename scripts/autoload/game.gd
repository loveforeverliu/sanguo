extends Node
## 全局状态单例：加载静态数据，持有资源/城池/武将，负责结束回合结算。


signal state_changed

const CONFIG_PATH := "res://data/config.json"
const ECONOMY_PATH := "res://data/economy.json"
const GENERAL_GROWTH_PATH := "res://data/general_growth.json"
const CITY_TRAITS_PATH := "res://data/city_traits.json"
const COMBAT_PATH := "res://data/combat.json"
const BUILDINGS_PATH := "res://data/buildings.json"
const GENERALS_PATH := "res://data/generals.json"
const ENEMIES_PATH := "res://data/enemies.json"

var config: Dictionary = {}          # 全局/开局设置
var economy: Dictionary = {}         # 经济系数
var general_growth: Dictionary = {}  # 武将成长 + 忠诚系数
var city_traits: Dictionary = {}     # 城池特性
var combat: Dictionary = {}          # 战斗系数
var buildings: Dictionary = {}       # building_id -> 定义
var generals_roster: Array = []      # 名将静态数据
var roster_by_id: Dictionary = {}    # 名将 id -> 定义
var enemies: Dictionary = {}         # 敌人 id -> 定义

var turn: int = 1
var coin: float = 0.0                # 铜钱（全局）
var grain: float = 0.0               # 粮草（全局）
var cities: Array = []               # City
var player_generals: Array = []      # General


func _ready() -> void:
	_load_data()
	new_game()


func _load_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("无法打开文件: " + path)
		return {}
	var data = JSON.parse_string(f.get_as_text())
	if data == null:
		push_error("JSON 解析失败: " + path)
		return {}
	return data


func _load_data() -> void:
	config = _load_json(CONFIG_PATH)
	economy = _load_json(ECONOMY_PATH)
	general_growth = _load_json(GENERAL_GROWTH_PATH)
	city_traits = _load_json(CITY_TRAITS_PATH)
	combat = _load_json(COMBAT_PATH)
	var blist = _load_json(BUILDINGS_PATH)
	buildings = {}
	if blist is Array:
		for b in blist:
			buildings[str(b.get("id", ""))] = b
	var roster = _load_json(GENERALS_PATH)
	generals_roster = roster if roster is Array else []
	roster_by_id = {}
	for g in generals_roster:
		roster_by_id[str(g.get("id", ""))] = g
	var elist = _load_json(ENEMIES_PATH)
	enemies = {}
	if elist is Array:
		for e in elist:
			enemies[str(e.get("id", ""))] = e


func new_game() -> void:
	turn = 1
	coin = float(config.get("start_coin", 1000.0))
	grain = float(config.get("start_grain", 2000.0))

	var city := City.new()
	city.id = "luoyang"
	city.name = "洛阳"
	city.trait_id = "fertile"
	city.civilians = 500
	city.buildings = {
		"government": 1,
		"farm": 1,
		"tavern": 1,
		"infantry_camp": 1,
	}
	cities = [city]

	player_generals = []
	var starter := General.new()
	starter.id = "starter"
	starter.display_name = "无名氏"
	starter.quality = "普通"
	starter.base_attrs = {"武力": 50, "统率": 50, "智力": 50, "速度": 50}
	player_generals.append(starter)

	state_changed.emit()


func main_city() -> City:
	return cities[0] if cities.size() > 0 else null


func end_turn() -> void:
	for city in cities:
		_tick_city(city)
	turn += 1
	state_changed.emit()


func _tick_city(city: City) -> void:
	grain += city.grain_output()
	coin += city.coin_output()
	grain -= city.civilian_consumption()
	var s := city.soldier_consumption()
	grain -= float(s.get("grain", 0.0))
	coin -= float(s.get("coin", 0.0))
	city.grow_population()
	grain = maxf(grain, 0.0)
	coin = maxf(coin, 0.0)


func get_general(id: String) -> General:
	for g in player_generals:
		if g.id == id:
			return g
	return null


func changed() -> void:
	state_changed.emit()


func _random_name() -> String:
	var surnames := ["赵", "钱", "孙", "李", "周", "吴", "郑", "王", "冯", "陈", "褚", "卫", "蒋", "沈", "韩", "杨", "朱", "秦", "许", "何"]
	var givens := ["忠", "勇", "义", "智", "信", "仁", "德", "武", "文", "威", "刚", "毅", "明", "亮", "虎", "龙", "豹", "彪", "骏", "杰"]
	var s: String = surnames[randi() % surnames.size()]
	var g: String = givens[randi() % givens.size()]
	return s + g + (g if randi() % 2 == 0 else "")


func generate_random_general() -> General:
	var r := randf()
	var quality := "普通"
	if r > 0.85:
		quality = "稀有"
	elif r > 0.6:
		quality = "优秀"
	var g := General.new()
	g.id = "rnd_%d_%d" % [turn, randi()]
	g.display_name = _random_name()
	g.quality = quality
	var base := 50
	match quality:
		"优秀":
			base = 60
		"稀有":
			base = 70
	for a in General.ATTRS:
		g.base_attrs[a] = clampi(base + randi_range(-8, 8), 30, 90)
	g.loyalty = randi_range(50, 70)
	return g


func recruit_from_tavern() -> General:
	var cost := int(economy.get("tavern_recruit_cost", 200))
	if coin < float(cost):
		return null
	coin -= float(cost)
	var g := generate_random_general()
	player_generals.append(g)
	return g


func drill(g: General) -> bool:
	var tier := _drill_tier(g.level)
	var c := int(tier.get("coin", 50))
	var gr := int(tier.get("grain", 50))
	if coin < float(c) or grain < float(gr):
		return false
	coin -= float(c)
	grain -= float(gr)
	var exp_gain := int(general_growth.get("drill_exp", 100))
	g.gain_exp(exp_gain)
	return true


func _drill_tier(level: int) -> Dictionary:
	var tiers: Array = general_growth.get("drill_cost_tiers", [])
	for t in tiers:
		if level >= int(t.get("min", 1)) and level <= int(t.get("max", 100)):
			return t
	return {}


# ---- 战斗 ----


func _make_side(general: General, troops: Dictionary, leader: Dictionary) -> Dictionary:
	var total := 0
	var main_type := ""
	var max_n := -1
	for t in troops:
		var n := int(troops[t])
		total += n
		if n > max_n:
			max_n = n
			main_type = str(t)
	var wuli := 30.0
	var tong := 20.0
	var intelligence := 10.0
	var speed := 20.0
	if general != null:
		wuli = float(general.get_attr("武力"))
		tong = float(general.get_attr("统率"))
		intelligence = float(general.get_attr("智力"))
		speed = float(general.get_attr("速度"))
	elif not leader.is_empty():
		wuli = float(leader.get("wuli", 30.0))
		tong = float(leader.get("tongshuai", 20.0))
		intelligence = float(leader.get("int", 10.0))
		speed = float(leader.get("speed", 20.0))
	return {
		"troops": float(total),
		"wuli": wuli,
		"tongshuai": tong,
		"int": intelligence,
		"speed": speed,
		"main_type": main_type,
	}


func battle(enemy_id: String, general: General, troops: Dictionary) -> Dictionary:
	var c := main_city()
	for t in troops:
		var n := int(troops.get(t, 0))
		if n < 0:
			return {"ok": false, "reason": "兵力不能为负"}
		if n > int(c.soldiers.get(t, 0)):
			return {"ok": false, "reason": "兵力不足"}
	var enemy: Dictionary = enemies.get(enemy_id, {})
	if enemy.is_empty():
		return {"ok": false, "reason": "敌人不存在"}
	var e_troops: Dictionary = enemy.get("troops", {})
	var e_leader: Dictionary = enemy.get("leader", {})

	# 扣除出征兵力
	var sent := 0
	for t in troops:
		var n := int(troops.get(t, 0))
		c.soldiers[t] = int(c.soldiers.get(t, 0)) - n
		sent += n
	if sent <= 0:
		return {"ok": false, "reason": "未派出兵力"}

	var a := _make_side(general, troops, {})
	var d := _make_side(null, e_troops, e_leader)
	var result := Battle.resolve(a, d)

	var win := str(result.get("winner", "defender")) == "attacker"
	var survived := int(result.get("attacker_troops_left", 0))
	var enemy_left := int(result.get("defender_troops_left", 0))

	# 幸存兵力按比例返还各兵种
	var ratio := clampf(float(survived) / float(sent), 0.0, 1.0)
	var leftover := survived
	for t in troops:
		var n := int(troops.get(t, 0))
		var back := int(round(float(n) * ratio))
		back = mini(back, leftover)
		c.soldiers[t] = int(c.soldiers.get(t, 0)) + back
		leftover -= back

	# 战利品 & 经验
	var loot_coin := 0
	var loot_grain := 0
	var exp_gain := 0
	if win:
		var loot: Dictionary = enemy.get("loot", {})
		loot_coin = int(loot.get("coin", 0))
		loot_grain = int(loot.get("grain", 0))
		coin += float(loot_coin)
		grain += float(loot_grain)
		if general != null:
			var gcfg: Dictionary = general_growth
			var d_total := 0
			for t in e_troops:
				d_total += int(e_troops[t])
			var killed := d_total - enemy_left
			exp_gain = int(gcfg.get("battle_exp_base", 20)) + int(round(float(killed) * float(gcfg.get("battle_exp_per_kill", 0.1))))
			general.gain_exp(exp_gain)

	return {
		"ok": true,
		"win": win,
		"survived": survived,
		"enemy_left": enemy_left,
		"loot_coin": loot_coin,
		"loot_grain": loot_grain,
		"exp": exp_gain,
		"rounds": int(result.get("rounds", 0)),
		"log": result.get("log", []),
	}
