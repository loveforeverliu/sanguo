extends Control
## 主界面外壳：顶部资源条 + 左侧导航 + 中央内容面板。


const NAV_ITEMS := ["城池", "武将", "征兵", "酒馆", "出征"]

var _content: Control = null
var _panels: Dictionary = {}
var _current: String = ""
var _res_labels: Dictionary = {}


func _ready() -> void:
	theme = _make_theme()
	_build_shell()
	Game.state_changed.connect(_on_state_changed)
	_refresh_resources()
	_switch("城池")


func _make_theme() -> Theme:
	var t := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei", "SimHei", "PingFang SC", "Noto Sans CJK SC", "sans-serif",
	])
	t.default_font = font
	t.default_font_size = 20

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("2a2118")
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(12)
	t.set_stylebox("panel", "PanelContainer", panel)

	var btn := StyleBoxFlat.new()
	btn.bg_color = Color("3a2e22")
	btn.set_corner_radius_all(4)
	btn.set_content_margin_all(8)
	t.set_stylebox("normal", "Button", btn)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color("4a3a2a")
	btn_hover.set_corner_radius_all(4)
	btn_hover.set_content_margin_all(8)
	t.set_stylebox("hover", "Button", btn_hover)

	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color("2a2218")
	btn_pressed.set_corner_radius_all(4)
	btn_pressed.set_content_margin_all(8)
	t.set_stylebox("pressed", "Button", btn_pressed)
	return t


func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = Color("1a1410")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	root.add_child(_build_top_bar())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	root.add_child(body)

	body.add_child(_build_nav())

	_content = Control.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_content)

	_panels["城池"] = CityPanel.new()
	_panels["武将"] = GeneralPanel.new()
	_panels["征兵"] = RecruitPanel.new()
	_panels["酒馆"] = TavernPanel.new()
	_panels["出征"] = BattlePanel.new()
	for key in _panels:
		var p: Control = _panels[key]
		p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		p.visible = false
		_content.add_child(p)


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 60
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	bar.add_child(h)

	for key in ["turn", "coin", "grain", "civ", "soldier"]:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", Color("e8c880"))
		_res_labels[key] = l
		h.add_child(l)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)

	var end_btn := Button.new()
	end_btn.text = "结束回合"
	end_btn.add_theme_font_size_override("font_size", 20)
	end_btn.pressed.connect(_on_end_turn)
	h.add_child(end_btn)
	return bar


func _build_nav() -> Control:
	var nav := PanelContainer.new()
	nav.custom_minimum_size.x = 150
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	nav.add_child(v)
	for key in NAV_ITEMS:
		var b := Button.new()
		b.text = key
		b.pressed.connect(_switch.bind(key))
		v.add_child(b)
	return nav


func _switch(key: String) -> void:
	_current = key
	for k in _panels:
		_panels[k].visible = (k == key)
	if _panels.has(key):
		_panels[key].refresh()


func _refresh_resources() -> void:
	var c: City = Game.main_city()
	_res_labels["turn"].text = "回合 %d" % Game.turn
	_res_labels["coin"].text = "铜钱 %d" % int(Game.coin)
	_res_labels["grain"].text = "粮草 %d" % int(Game.grain)
	_res_labels["civ"].text = "平民 %d" % c.civilians
	_res_labels["soldier"].text = "士兵 %d" % c.total_soldiers()


func _on_state_changed() -> void:
	_refresh_resources()
	call_deferred("_refresh_current_panel")


func _refresh_current_panel() -> void:
	if _panels.has(_current):
		_panels[_current].refresh()


func _on_end_turn() -> void:
	Game.end_turn()
