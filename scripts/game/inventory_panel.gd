extends PanelContainer

signal closed()

@onready var _list: VBoxContainer = %ItemList

func _ready() -> void:
	visible = false
	_apply_style()
	%CloseButton.custom_minimum_size = Vector2(0, 32)
	%CloseButton.focus_mode = Control.FOCUS_NONE
	DoomTypography.stamp_mono(%Title, 13)
	DoomTypography.stamp_mono(%CloseButton, 11)
	%Title.text = "INVENTORY"
	GameState.inventory_changed.connect(_refresh)
	%CloseButton.pressed.connect(_on_close)

func _apply_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0, 0, 0, 0.68)
	panel.set_content_margin_all(16)
	panel.set_corner_radius_all(1)
	add_theme_stylebox_override("panel", panel)

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	if GameState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "—"
		DoomTypography.stamp_mono(empty, 11, true)
		_list.add_child(empty)
		return
	for item in GameState.inventory:
		var lbl := Label.new()
		lbl.text = DoomTypography.format_item_label(str(item))
		DoomTypography.stamp_mono(lbl, 11)
		_list.add_child(lbl)

func _on_close() -> void:
	visible = false
	closed.emit()
