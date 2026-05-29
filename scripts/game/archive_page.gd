extends PanelContainer
## Hidden broken page — rumors, scraps, things you weren't supposed to find.

signal closed()

@onready var _body: Label = %ArchiveBody
@onready var _close: Button = %ArchiveClose

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_style()
	DoomTypography.stamp_fragment(_body, 12)
	_close.pressed.connect(_on_close)
	_close.text = "ok"
	_style_close()

func _apply_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.93, 0.91, 0.86, 1.0)
	panel.border_color = Color(0.55, 0.52, 0.48, 1.0)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(16)
	add_theme_stylebox_override("panel", panel)

func _style_close() -> void:
	_close.flat = true
	_close.focus_mode = Control.FOCUS_NONE
	DoomTypography.stamp_fragment(_close, 11)
	var empty := StyleBoxEmpty.new()
	_close.add_theme_stylebox_override("normal", empty)
	_close.add_theme_stylebox_override("hover", empty)
	_close.add_theme_stylebox_override("pressed", empty)

func open() -> void:
	_body.text = _build_body()
	visible = true

func _build_body() -> String:
	var lines: PackedStringArray = []
	lines.append("<html><body bgcolor=#eeeecc>")
	lines.append("kensington archive (broken mirror)")
	lines.append("")
	if GameState.discovered_rumors.is_empty() and GameState.inventory.is_empty():
		lines.append("nothing cached yet.")
		lines.append("keep clicking.")
	else:
		if not GameState.discovered_rumors.is_empty():
			lines.append("rumors:")
			for rumor in GameState.discovered_rumors:
				lines.append("  · %s" % str(rumor).to_lower())
		if not GameState.inventory.is_empty():
			lines.append("")
			lines.append("pockets:")
			for item in GameState.inventory:
				lines.append("  · %s" % str(item).to_lower())
		if GameState.discovered_collectibles.size() > 0:
			lines.append("")
			lines.append("logged: %d things" % GameState.discovered_collectibles.size())
	lines.append("")
	lines.append("<!-- last seen: %s -->" % _time_stamp())
	lines.append("</body></html>")
	return "\n".join(lines)

func _time_stamp() -> String:
	return DoomTypography.format_time(GameState.clock_minutes).to_lower()

func _on_close() -> void:
	visible = false
	closed.emit()
