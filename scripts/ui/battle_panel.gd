class_name BattlePanel
extends PanelBase
## 出征面板：选武将、配兵力、挑战敌人，展示战斗结果。


var _general_opt: OptionButton = null
var _enemy_opt: OptionButton = null
var _spin: Dictionary = {}   # 兵种 -> SpinBox
var _result: Label = null


func _init() -> void:
	super()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	v.add_child(make_title("出征"))

	v.add_child(make_label("武将", 20, "e8c880"))
	_general_opt = OptionButton.new()
	v.add_child(_general_opt)

	v.add_child(make_label("敌人", 20, "e8c880"))
	_enemy_opt = OptionButton.new()
	v.add_child(_enemy_opt)

	v.add_child(make_label("兵力", 20, "e8c880"))
	for t in ["步兵", "骑兵", "弓兵"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		v.add_child(row)
		var name_label := make_label(t, 18)
		name_label.custom_minimum_size.x = 60
		row.add_child(name_label)
		var sb := SpinBox.new()
		sb.min_value = 0
		sb.step = 10
		sb.custom_minimum_size.x = 140
		_spin[t] = sb
		row.add_child(sb)

	var fight := make_button("出征")
	fight.pressed.connect(_on_fight)
	v.add_child(fight)

	_result = make_label("", 18, "e8c880")
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_result)


func refresh() -> void:
	var gi := _general_opt.selected
	_general_opt.clear()
	for g in Game.player_generals:
		_general_opt.add_item("%s（%s Lv.%d）" % [g.display_name, g.quality, g.level])
	if Game.player_generals.size() > 0:
		_general_opt.selected = clampi(gi, 0, Game.player_generals.size() - 1)

	var ei := _enemy_opt.selected
	_enemy_opt.clear()
	for eid in Game.enemies.keys():
		var enemy: Dictionary = Game.enemies[eid]
		_enemy_opt.add_item("%s（%s）" % [enemy.get("name", eid), _troop_str(enemy.get("troops", {}))])
	if Game.enemies.size() > 0:
		_enemy_opt.selected = clampi(ei, 0, Game.enemies.size() - 1)

	var c: City = Game.main_city()
	for t in _spin.keys():
		var sb: SpinBox = _spin[t]
		sb.max_value = int(c.soldiers.get(t, 0))
		sb.value = mini(int(sb.value), int(c.soldiers.get(t, 0)))


func _troop_str(troops: Dictionary) -> String:
	var parts: Array = []
	for t in troops:
		if int(troops[t]) > 0:
			parts.append("%s%d" % [t, int(troops[t])])
	return " ".join(parts) if parts.size() > 0 else "空"


func _on_fight() -> void:
	if Game.player_generals.size() == 0:
		_result.text = "没有可出战的武将"
		return
	if Game.enemies.size() == 0:
		_result.text = "没有可挑战的敌人"
		return
	var g: General = Game.player_generals[_general_opt.selected]
	var eid: String = Game.enemies.keys()[_enemy_opt.selected]
	var troops := {
		"步兵": int(_spin["步兵"].value),
		"骑兵": int(_spin["骑兵"].value),
		"弓兵": int(_spin["弓兵"].value),
	}
	var r := Game.battle(eid, g, troops)
	if not bool(r.get("ok", false)):
		_result.text = str(r.get("reason", "出征失败"))
		return
	var lines: Array = []
	if bool(r.get("win", false)):
		lines.append("【胜利】%d 回合击败敌人" % int(r.get("rounds", 0)))
		lines.append("我方剩余兵力：%d" % int(r.get("survived", 0)))
		lines.append("缴获：铜钱 +%d，粮草 +%d" % [int(r.get("loot_coin", 0)), int(r.get("loot_grain", 0))])
		lines.append("武将获得经验 +%d" % int(r.get("exp", 0)))
	else:
		lines.append("【战败】……")
		lines.append("我方剩余兵力：%d，敌方剩余：%d" % [int(r.get("survived", 0)), int(r.get("enemy_left", 0))])
	_result.text = "\n".join(lines)
	Game.state_changed.emit()
