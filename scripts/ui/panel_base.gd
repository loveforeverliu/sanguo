class_name PanelBase
extends PanelContainer
## 面板基类：提供构建 UI 的辅助方法，子类实现 refresh()。


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func refresh() -> void:
	pass


func make_label(text: String, size: int = 20, color: String = "e8dcc0") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(color))
	return l


func make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	return b


func make_title(text: String) -> Label:
	return make_label(text, 30, "e8c880")


func clear(node: Node) -> void:
	for child in node.get_children():
		child.free()
