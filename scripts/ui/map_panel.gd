class_name MapPanel
extends PanelBase
## 地图面板：顶部势力图例 + 缩放提示 + 地图视图。


var _map: MapView = null


func _init() -> void:
	super()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)

	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 16)
	v.add_child(legend)
	for fid in ["wei", "shu", "wu", "qun"]:
		var f: Dictionary = Game.factions.get(fid, {})
		var l := make_label(str(f.get("name", fid)), 16, str(f.get("color", "ffffff")).substr(1))
		legend.add_child(l)
	var hint := make_label("滚轮缩放 · 拖拽平移 · 点击城市查看", 14, "9a8f7a")
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	legend.add_child(hint)

	_map = MapView.new()
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.city_clicked.connect(_on_city_clicked)
	v.add_child(_map)


func refresh() -> void:
	_map.set_selected(Game.selected_city_id)


func _on_city_clicked(id: String) -> void:
	Game.select_city(id)
	_map.set_selected(id)
