extends PanelContainer
class_name TransitPicker

signal route_selected(route: Dictionary)
signal closed()

@onready var _title: Label = %TitleLabel
@onready var _subtitle: Label = %SubtitleLabel
@onready var _list: VBoxContainer = %RouteList
@onready var _close: Button = %CloseButton

func _ready() -> void:
	visible = false
	_apply_style()
	_close.pressed.connect(close_picker)

func _apply_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.08, 0.94)
	panel.border_color = Color(0.55, 0.52, 0.48, 0.55)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(14)
	panel.set_corner_radius_all(1)
	add_theme_stylebox_override("panel", panel)
	DoomTypography.stamp_game(_title, 14)
	DoomTypography.stamp_game(_subtitle, 11, true)
	_style_button(_close)
	_close.text = "[CLOSE]"

func _style_button(btn: Button) -> void:
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	DoomTypography.stamp_happening(btn, 12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.35)
	style.border_color = Color(1, 1, 1, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)

func open_picker() -> void:
	_title.text = TransitData.header_text()
	_subtitle.text = TransitData.subtitle_text()
	for child in _list.get_children():
		child.queue_free()
	var routes := TransitData.available_routes()
	if routes.is_empty():
		var empty := Label.new()
		empty.text = "no departures right now."
		DoomTypography.stamp_game(empty, 12, true)
		_list.add_child(empty)
	else:
		for route in routes:
			_list.add_child(_make_route_button(route))
	visible = true

func close_picker() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _make_route_button(route: Dictionary) -> Button:
	var btn := Button.new()
	var note: String = str(route.get("note", ""))
	var cost: int = TransitData.route_cost(route)
	btn.text = "%s  $%d" % [TransitData.route_label(route), cost]
	if note != "":
		btn.tooltip_text = note
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	_style_button(btn)
	btn.pressed.connect(func() -> void:
		route_selected.emit(route.duplicate())
		close_picker()
	)
	return btn
