extends PanelContainer

signal closed()

@onready var _list: VBoxContainer = %CollectionList

func _ready() -> void:
	visible = false
	%CloseButton.custom_minimum_size = Vector2(120, 48)
	DoomTypography.stamp_signage(%Title, 16)
	DoomTypography.stamp_mono(%CloseButton, 12)
	%Title.text = CopyData.lookup("hud/collections_title", "COLLECTIONS")
	GameState.collections_changed.connect(_refresh)
	%CloseButton.pressed.connect(_on_close)

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var summary := GameState.collections_summary()
	for cat in ["liquor", "items"]:
		var row: Dictionary = summary.get(cat, {})
		var lbl := Label.new()
		var cat_label := str(row.get("label", cat)).to_upper()
		lbl.text = "%s\n%d / %d" % [cat_label, row.get("found", 0), row.get("total", 0)]
		DoomTypography.stamp_mono(lbl, 13)
		_list.add_child(lbl)
		for entry in CollectibleData.all_in_category(cat):
			var id: String = entry.get("id", "")
			var name: String = entry.get("name", id)
			var item_lbl := Label.new()
			var mark := "X" if id in GameState.discovered_collectibles else "—"
			item_lbl.text = "%s  %s" % [mark, DoomTypography.format_item_label(name)]
			DoomTypography.stamp_mono(item_lbl, 11, id not in GameState.discovered_collectibles)
			item_lbl.modulate = Color(1, 1, 1, 0.9 if id in GameState.discovered_collectibles else 0.45)
			_list.add_child(item_lbl)

func _on_close() -> void:
	visible = false
	closed.emit()
