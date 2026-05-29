extends HBoxContainer

signal tool_pressed(tool: String)

const TOOLS := ["BACK", "LOST", "RND", "DIG"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	for tool in TOOLS:
		add_child(_make_button(tool))
	if OS.is_debug_build():
		add_child(_make_button("TEST"))
	_apply_bar_style()

func _apply_bar_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.04, 0.05, 0.92)
	panel.set_content_margin_all(4)
	add_theme_stylebox_override("panel", panel)

func _make_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label.to_lower()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 28)
	btn.pressed.connect(func() -> void: tool_pressed.emit(label))
	DoomTypography.stamp_game(btn, 11)
	btn.flat = true
	var empty := StyleBoxFlat.new()
	empty.bg_color = Color(1, 1, 1, 0.04)
	empty.set_corner_radius_all(1)
	empty.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	return btn
