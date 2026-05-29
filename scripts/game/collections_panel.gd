extends PanelContainer

signal closed()

@onready var _list: VBoxContainer = %CollectionList

func _ready() -> void:
	visible = false
	%CloseButton.custom_minimum_size = Vector2(120, 48)
	%CloseButton.focus_mode = Control.FOCUS_NONE
	DoomTypography.stamp_signage(%Title, 16)
	DoomTypography.stamp_mono(%CloseButton, 12)
	%Title.text = CopyData.lookup("hud/collections_title", "COLLECTIONS")
	GameState.collections_changed.connect(_refresh)
	%CloseButton.pressed.connect(_on_close)

func has_any() -> bool:
	return not GameState.discovered_collectibles.is_empty()

func toggle() -> void:
	if not has_any():
		return
	visible = not visible
	if visible:
		_refresh()

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var any := false
	for cat in ["liquor", "items"]:
		var owned: Array = []
		for entry in CollectibleData.all_in_category(cat):
			var id: String = entry.get("id", "")
			if id in GameState.discovered_collectibles:
				owned.append(entry)
		if owned.is_empty():
			continue
		any = true
		var header := Label.new()
		header.text = CollectibleData.category_label(cat).to_upper()
		DoomTypography.stamp_mono(header, 13)
		_list.add_child(header)
		for entry in owned:
			var name: String = entry.get("name", entry.get("id", ""))
			var item_lbl := Label.new()
			item_lbl.text = DoomTypography.format_item_label(name)
			DoomTypography.stamp_mono(item_lbl, 11)
			_list.add_child(item_lbl)
	if not any:
		visible = false

func _on_close() -> void:
	visible = false
	closed.emit()
