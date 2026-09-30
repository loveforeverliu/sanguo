class_name General
extends RefCounted
## 武将：等级/经验/四维/品质/忠诚，负责升级、加点与属性计算。


const ATTRS := ["武力", "统率", "智力", "速度"]

var id: String = ""
var display_name: String = ""
var quality: String = "普通"        # 普通/优秀/稀有/史诗/传奇
var faction: String = ""
var troop_type: String = "步兵"     # 步兵/骑兵/弓兵/全能
var trait_name: String = ""
var trait_desc: String = ""

var level: int = 1
var exp: int = 0
var loyalty: int = 60

var base_attrs: Dictionary = {}     # 初始四维
var allocated: Dictionary = {}      # 玩家手动分配的自由点
var free_points: int = 0            # 待分配自由点


func _init() -> void:
	for a in ATTRS:
		base_attrs[a] = 50
		allocated[a] = 0


static func from_data(d: Dictionary) -> General:
	var g := General.new()
	g.id = str(d.get("id", ""))
	g.display_name = str(d.get("name", ""))
	g.quality = str(d.get("quality", "普通"))
	g.faction = str(d.get("faction", ""))
	g.troop_type = str(d.get("troop_type", "步兵"))
	var t: Dictionary = d.get("trait", {})
	g.trait_name = str(t.get("name", ""))
	g.trait_desc = str(t.get("desc", ""))
	var attrs: Dictionary = d.get("base_attrs", {})
	for a in ATTRS:
		g.base_attrs[a] = int(attrs.get(a, 50))
	g.loyalty = int(d.get("initial_loyalty", 60))
	return g


# ---- 成长 ----
func quality_table() -> Dictionary:
	var table: Dictionary = Game.general_growth.get("quality_points", {})
	return table.get(quality, {"fixed": 1, "free": 2})


func fixed_per_level() -> int:
	return int(quality_table().get("fixed", 1))


func free_per_level() -> int:
	return int(quality_table().get("free", 2))


func total_fixed_points() -> int:
	return fixed_per_level() * (level - 1)


## 固定属性点自动分配到四维（平均分配，余数按顺序补到武力/统率/智力/速度）。
func _auto_fixed(a: String) -> int:
	var total := total_fixed_points()
	var each := total / ATTRS.size()
	var rem := total % ATTRS.size()
	var idx := ATTRS.find(a)
	return each + (1 if idx < rem else 0)


func get_attr(a: String) -> int:
	return int(base_attrs.get(a, 0)) + _auto_fixed(a) + int(allocated.get(a, 0))


func exp_to_next() -> int:
	var g: Dictionary = Game.general_growth
	var base: float = float(g.get("exp_base", 100.0))
	var growth: float = float(g.get("exp_growth", 1.2))
	return int(base * pow(growth, level - 1))


func gain_exp(amount: int) -> void:
	exp += amount
	var cap := int(Game.general_growth.get("level_cap", 100))
	while level < cap and exp >= exp_to_next():
		exp -= exp_to_next()
		level += 1
		free_points += free_per_level()


func spend_free_point(a: String) -> bool:
	if free_points <= 0 or not a in ATTRS:
		return false
	allocated[a] = int(allocated[a]) + 1
	free_points -= 1
	return true
