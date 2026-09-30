class_name MapView
extends Control
## 可缩放平移的三国地图视图。读 Game.world / Game.factions，按缩放分层绘制（LOD）。
## 最小缩放：势力色块 + 简称；放大依次出现 州名、郡名、县名 + 道路。


signal city_clicked(id: String)

const MIN_ZOOM := 0.35
const MAX_ZOOM := 4.0
const LOD_FACTION := 0.7      # 势力简称层上限
const LOD_STATE := 1.3        # 州层上限
const LOD_COMMANDERY := 2.0   # 郡层上限（之上为县 + 道路）
const FADE := 0.12            # 层级淡入淡出宽度

var _zoom := 0.42
var _cam := Vector2(1200.0, 900.0)
var _font: SystemFont = null
var _dragging := false
var _dragged := false
var _drag_last := Vector2.ZERO
var _drag_start := Vector2.ZERO
var _hover_id := ""
var _selected_id := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = SystemFont.new()
	_font.font_names = PackedStringArray([
		"Microsoft YaHei", "SimHei", "PingFang SC", "Noto Sans CJK SC", "sans-serif",
	])
	_center_cam()
	queue_redraw()


func set_selected(id: String) -> void:
	if _selected_id != id:
		_selected_id = id
		queue_redraw()


func reset_view() -> void:
	_zoom = MIN_ZOOM
	_center_cam()
	queue_redraw()


func _center_cam() -> void:
	var w: Dictionary = Game.world.get("world", {})
	_cam = Vector2(float(w.get("width", 2400.0)) / 2.0, float(w.get("height", 1800.0)) / 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(mb.position, 1.2)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(mb.position, 1.0 / 1.2)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_dragged = false
				_drag_start = mb.position
				_drag_last = mb.position
			else:
				_dragging = false
				if not _dragged:
					_on_click(mb.position)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging:
			if (mm.position - _drag_start).length() > 4.0:
				_dragged = true
			if _dragged:
				_cam -= (mm.position - _drag_last) / _zoom
				_drag_last = mm.position
				queue_redraw()
		else:
			_update_hover(mm.position)


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _screen_to_world(screen_pos)
	_zoom = clampf(_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	var after := _screen_to_world(screen_pos)
	_cam += before - after
	queue_redraw()


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - size / 2.0) / _zoom + _cam


func _to_screen(p: Vector2) -> Vector2:
	return (p - _cam) * _zoom + size / 2.0


func _on_click(screen_pos: Vector2) -> void:
	var id := _hit_commandery(screen_pos)
	if id != "":
		_selected_id = id
		queue_redraw()
		city_clicked.emit(id)


func _update_hover(screen_pos: Vector2) -> void:
	var id := _hit_commandery(screen_pos)
	if id != _hover_id:
		_hover_id = id
		queue_redraw()


func _hit_commandery(screen_pos: Vector2) -> String:
	var best := ""
	var best_d := 24.0 * 24.0
	for cd in Game.world.get("commanderies", []):
		var p := _to_screen(Vector2(float(cd.get("x", 0.0)), float(cd.get("y", 0.0))))
		var d := p.distance_squared_to(screen_pos)
		if d < best_d:
			best_d = d
			best = str(cd.get("id", ""))
	return best


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("141d26"))
	var z := _zoom
	var a_faction := _layer_alpha(z, MIN_ZOOM, LOD_FACTION)
	var a_state := _layer_alpha(z, LOD_FACTION, LOD_STATE)
	var a_com := _layer_alpha(z, LOD_STATE, LOD_COMMANDERY)
	var a_county := _layer_alpha(z, LOD_COMMANDERY, MAX_ZOOM)
	if a_faction > 0.01:
		_draw_faction(a_faction)
	if a_state > 0.01:
		_draw_state(a_state)
	if a_com > 0.01:
		_draw_commandery(a_com)
	if a_county > 0.01:
		_draw_county(a_county)


func _layer_alpha(z: float, lo: float, hi: float) -> float:
	if z <= lo or z >= hi:
		return 0.0
	if z < lo + FADE:
		return (z - lo) / FADE
	if z > hi - FADE:
		return (hi - z) / FADE
	return 1.0


func _draw_faction(alpha: float) -> void:
	var capital := {"wei": "luoyang", "shu": "chengdu", "wu": "jianye", "qun": "xiangping"}
	for cd in Game.world.get("commanderies", []):
		var col := _faction_color(str(cd.get("faction", "")))
		col.a = 0.26 * alpha
		var p := _to_screen(Vector2(float(cd.get("x", 0.0)), float(cd.get("y", 0.0))))
		draw_circle(p, 55.0 * _zoom, col)
	for fid in Game.factions:
		var cap_id := str(capital.get(fid, ""))
		var cap := Game.world_county(cap_id)
		if cap.is_empty():
			continue
		var p := _to_screen(Vector2(float(cap.get("x", 0.0)), float(cap.get("y", 0.0))))
		var col := _faction_color(fid)
		col.a = alpha
		var abbr := str(Game.factions.get(fid, {}).get("abbr", fid))
		_draw_text(p + Vector2(0.0, -34.0), abbr, 40, col)


func _draw_state(alpha: float) -> void:
	for cd in Game.world.get("commanderies", []):
		var col := _faction_color(str(cd.get("faction", "")))
		col.a = 0.5 * alpha
		var p := _to_screen(Vector2(float(cd.get("x", 0.0)), float(cd.get("y", 0.0))))
		draw_circle(p, 3.0, col)
	for s in Game.world.get("states", []):
		var p := _to_screen(Vector2(float(s.get("x", 0.0)), float(s.get("y", 0.0))))
		var col := Color("e8dcc0")
		col.a = alpha
		_draw_text(p, str(s.get("name", "")), 26, col)


func _draw_commandery(alpha: float) -> void:
	for cd in Game.world.get("commanderies", []):
		var p := _to_screen(Vector2(float(cd.get("x", 0.0)), float(cd.get("y", 0.0))))
		if not _on_screen(p):
			continue
		var id := str(cd.get("id", ""))
		var col := _faction_color(str(cd.get("faction", "")))
		col.a = alpha
		var highlight := id == _selected_id or id == _hover_id
		var r := 6.0 if highlight else 4.0
		draw_circle(p, r, col)
		if highlight:
			draw_arc(p, r + 3.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, alpha), 2.0)
		var nc := Color("e8dcc0")
		nc.a = alpha
		_draw_text(p + Vector2(0.0, 14.0), str(cd.get("name", "")), 13, nc)


func _draw_county(alpha: float) -> void:
	# 道路
	for r in Game.world.get("roads", []):
		var ca: Dictionary = Game.world_county(str(r[0]))
		var cb: Dictionary = Game.world_county(str(r[1]))
		if ca.is_empty() or cb.is_empty():
			continue
		var pa := _to_screen(Vector2(float(ca.get("x", 0.0)), float(ca.get("y", 0.0))))
		var pb := _to_screen(Vector2(float(cb.get("x", 0.0)), float(cb.get("y", 0.0))))
		if not _on_screen(pa, 20.0) and not _on_screen(pb, 20.0):
			continue
		draw_line(pa, pb, Color(0.42, 0.36, 0.24, alpha * 0.9), 1.5)
	# 郡图标 + 名字（小）
	for cd in Game.world.get("commanderies", []):
		var p := _to_screen(Vector2(float(cd.get("x", 0.0)), float(cd.get("y", 0.0))))
		if not _on_screen(p):
			continue
		var id := str(cd.get("id", ""))
		var col := _faction_color(str(cd.get("faction", "")))
		col.a = alpha
		var r := 5.0 if id == _selected_id else 3.5
		draw_circle(p, r, col)
		if id == _selected_id:
			draw_arc(p, r + 3.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, alpha), 2.0)
		var nc := Color("e8dcc0")
		nc.a = alpha
		_draw_text(p + Vector2(0.0, -11.0), str(cd.get("name", "")), 12, nc)
	# 县图标 + 名字
	for c in Game.world.get("counties", []):
		var p := _to_screen(Vector2(float(c.get("x", 0.0)), float(c.get("y", 0.0))))
		if not _on_screen(p):
			continue
		draw_circle(p, 2.0, Color(0.78, 0.72, 0.56, alpha))
		var nc := Color("d8cfa8")
		nc.a = alpha
		_draw_text(p + Vector2(0.0, 9.0), str(c.get("name", "")), 9, nc)


func _on_screen(p: Vector2, margin: float = 60.0) -> bool:
	return p.x >= -margin and p.x <= size.x + margin and p.y >= -margin and p.y <= size.y + margin


func _faction_color(fid: String) -> Color:
	var f: Dictionary = Game.factions.get(fid, {})
	return _hex(str(f.get("color", "#888888")))


func _hex(s: String) -> Color:
	return Color(s)


func _draw_text(pos: Vector2, text: String, size_px: int, col: Color) -> void:
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, size_px, col)
