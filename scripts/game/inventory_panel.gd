extends PanelContainer

signal closed()

@onready var _list: VBoxContainer = %ItemList

func _ready() -> void:
	visible = false
	%CloseButton.custom_minimum_size = Vector2(120, 48)
	DoomTypography.stamp_signage(%Title, 16)
	DoomTypography.stamp_mono(%CloseButton, 12)
	%Title.text = "INVENTORY"
	GameState.inventory_changed.connect(_refresh)
	%CloseButton.pressed.connect(_on_close)

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
		DoomTypography.stamp_mono(empty, 12, true)
		_list.add_child(empty)
		return
	for item in GameState.inventory:
		var lbl := Label.new()
		lbl.text = DoomTypography.format_item_label(str(item))
		DoomTypography.stamp_mono(lbl, 12)
		_list.add_child(lbl)

func _on_close() -> void:
	visible = false
	closed.emit()
