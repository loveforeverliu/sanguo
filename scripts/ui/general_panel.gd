class_name GeneralPanel
extends PanelBase
## 武将面板：展示麾下武将，自由加点与练兵。


var _box: VBoxContainer = null


func _init() -> void:
	super()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	v.add_child(make_title("武将"))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	v.add_child(_box)


func refresh() -> void:
	clear(_box)
	for g in Game.player_generals:
		_box.add_child(_general_card(g))


func _general_card(g: General) -> Control:
	var card := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	head.add_child(make_label("%s（%s）" % [g.display_name, g.quality], 24, "e8c880"))
	head.add_child(make_label("Lv.%d  %d/%d经验" % [g.level, g.exp, g.exp_to_next()], 18, "9a8f7a"))
	head.add_child(make_label("特性：%s" % (g.trait_name if g.trait_name != "" else "无"), 18, "9a8f7a"))

	var attrs := HBoxContainer.new()
	attrs.add_theme_constant_override("separation", 16)
	v.add_child(attrs)
	for a in General.ATTRS:
		attrs.add_child(make_label("%s %d" % [a, g.get_attr(a)], 20))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	v.add_child(actions)
	actions.add_child(make_label("自由点：%d" % g.free_points, 20, "e8c880"))
	for a in General.ATTRS:
		var b := make_button("+" + a)
		b.disabled = g.free_points <= 0
		b.pressed.connect(_on_add_point.bind(g, a))
		actions.add_child(b)
	var drill := make_button("练兵")
	drill.pressed.connect(_on_drill.bind(g))
	actions.add_child(drill)

	return card


func _on_add_point(g: General, a: String) -> void:
	if g.spend_free_point(a):
		Game.state_changed.emit()


func _on_drill(g: General) -> void:
	if Game.drill(g):
		Game.state_changed.emit()
