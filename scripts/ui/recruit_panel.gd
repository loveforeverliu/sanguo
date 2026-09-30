class_name RecruitPanel
extends PanelBase
## 征兵面板：各兵种当前数量、成本、征兵按钮（需对应兵营）。


const TROOPS := [
	{"type": "步兵", "building": "infantry_camp"},
	{"type": "骑兵", "building": "cavalry_camp"},
	{"type": "弓兵", "building": "archer_camp"},
]

var _box: VBoxContainer = null


func _init() -> void:
	super()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	v.add_child(make_title("征兵"))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	v.add_child(_box)


func refresh() -> void:
	clear(_box)
	var c: City = Game.main_city()
	for t in TROOPS:
		_box.add_child(_troop_row(c, t["type"], t["building"]))


func _troop_row(c: City, troop_type: String, building: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var count := int(c.soldiers.get(troop_type, 0))
	var name_label := make_label("%s  %d" % [troop_type, count], 22)
	name_label.custom_minimum_size.x = 140
	row.add_child(name_label)

	var level := c.building_level(building)
	if level <= 0:
		var bname := str(Game.buildings.get(building, {}).get("name", building))
		row.add_child(make_label("需先建造「%s」" % bname, 18, "9a6a6a"))
	else:
		var gc := c.recruit_unit_cost("grain")
		var cc := c.recruit_unit_cost("coin")
		row.add_child(make_label("每兵 %d粮 %d钱" % [int(gc), int(cc)], 18, "9a8f7a"))
		for n in [10, 50, 100]:
			var btn := make_button("征%d" % n)
			btn.disabled = not c.can_recruit(n)
			btn.pressed.connect(_on_recruit.bind(troop_type, n))
			row.add_child(btn)
	return row


func _on_recruit(troop_type: String, count: int) -> void:
	if Game.main_city().recruit(troop_type, count):
		Game.state_changed.emit()
