class_name TavernPanel
extends PanelBase
## 酒馆面板：消耗铜钱招募随机武将，展示麾下武将。


var _box: VBoxContainer = null


func _init() -> void:
	super()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	v.add_child(make_title("酒馆"))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	v.add_child(_box)


func refresh() -> void:
	clear(_box)
	var cost := int(Game.economy.get("tavern_recruit_cost", 200))
	var btn := make_button("招募武将（%d铜钱）" % cost)
	btn.disabled = Game.coin < float(cost)
	btn.pressed.connect(_on_recruit)
	_box.add_child(btn)
	_box.add_child(make_label("酒馆只能招募普通/优秀/稀有武将，名将需拜访或俘虏劝降（后续版本）", 18, "9a8f7a"))
	for g in Game.player_generals:
		_box.add_child(make_label("· %s（%s）Lv.%d" % [g.display_name, g.quality, g.level], 20))


func _on_recruit() -> void:
	var g: General = Game.recruit_from_tavern()
	if g != null:
		Game.state_changed.emit()
