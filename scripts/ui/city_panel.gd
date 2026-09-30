class_name CityPanel
extends PanelBase
## 城池面板：城市概况、产出/消耗、建筑列表与升级。


var _info: VBoxContainer = null
var _buildings_box: VBoxContainer = null


func _init() -> void:
	super()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)

	v.add_child(make_title("城池"))
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 4)
	v.add_child(_info)

	var sep := HSeparator.new()
	v.add_child(sep)

	v.add_child(make_label("建筑", 24, "e8c880"))
	_buildings_box = VBoxContainer.new()
	_buildings_box.add_theme_constant_override("separation", 6)
	v.add_child(_buildings_box)


func refresh() -> void:
	clear(_info)
	clear(_buildings_box)

	var c: City = Game.main_city()
	var trait_name: String = c.city_trait().get("name", "无")
	_info.add_child(make_label("城市：%s（特性：%s）" % [c.name, trait_name]))
	_info.add_child(make_label("平民：%d / %d" % [c.civilians, c.population_cap()]))
	_info.add_child(make_label("士兵：%d（步 %d / 骑 %d / 弓 %d）" % [c.total_soldiers(), c.soldiers.get("步兵", 0), c.soldiers.get("骑兵", 0), c.soldiers.get("弓兵", 0)]))
	_info.add_child(make_label("每回合产粮：%d　产钱：%d" % [int(c.grain_output()), int(c.coin_output())]))
	var sc := c.soldier_consumption()
	_info.add_child(make_label("每回合耗粮：%d　耗钱：%d" % [int(c.civilian_consumption() + float(sc.get("grain", 0.0))), int(float(sc.get("coin", 0.0)))]))

	for bid in Game.buildings.keys():
		_buildings_box.add_child(_building_row(bid))


func _building_row(bid: String) -> Control:
	var b: Dictionary = Game.buildings[bid]
	var c: City = Game.main_city()
	var level := c.building_level(bid)
	var max_level := int(b.get("max_level", 5))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := make_label("%s  Lv.%d/%d" % [b.get("name", bid), level, max_level])
	name_label.custom_minimum_size.x = 200
	row.add_child(name_label)

	var desc := make_label(str(b.get("desc", "")), 18, "9a8f7a")
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(desc)

	if level < max_level:
		var btn := make_button("升级 %d铜钱" % c.upgrade_cost(bid))
		btn.disabled = not c.can_upgrade(bid)
		btn.pressed.connect(_on_upgrade.bind(bid))
		row.add_child(btn)
	else:
		row.add_child(make_label("已满级", 18, "6a6a6a"))

	return row


func _on_upgrade(bid: String) -> void:
	if Game.main_city().upgrade(bid):
		Game.state_changed.emit()
