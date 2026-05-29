extends PanelContainer

signal closed()

const COLLECTION_SECTIONS := [
	{"key": "liquor", "label": "LIQUOR", "type": "collectibles"},
	{"key": "items", "label": "ITEMS", "type": "collectibles"},
	{"key": "rumors", "label": "RUMORS", "type": "rumors"},
	{"key": "places", "label": "PLACES", "type": "places"},
]

@onready var _list: VBoxContainer = %CollectionList

func _ready() -> void:
	visible = false
	_apply_style()
	%CloseButton.custom_minimum_size = Vector2(0, 32)
	%CloseButton.focus_mode = Control.FOCUS_NONE
	DoomTypography.stamp_mono(%Title, 13)
	DoomTypography.stamp_mono(%CloseButton, 11)
	%Title.text = "COLLECTIONS"
	GameState.collections_changed.connect(_refresh)
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
	for section in COLLECTION_SECTIONS:
		var entries := _entries_for_section(section)
		if entries.is_empty():
			continue
		var header := Label.new()
		header.text = section.label
		DoomTypography.stamp_mono(header, 11, true)
		_list.add_child(header)
		for line in entries:
			var item_lbl := Label.new()
			item_lbl.text = line
			DoomTypography.stamp_mono(item_lbl, 11)
			_list.add_child(item_lbl)

func _entries_for_section(section: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	match section.type:
		"collectibles":
			for entry in CollectibleData.all_in_category(section.key):
				var id: String = entry.get("id", "")
				if id in GameState.discovered_collectibles:
					out.append(DoomTypography.format_item_label(entry.get("name", id)))
		"rumors":
			for rumor_id in GameState.discovered_rumors:
				out.append(DoomTypography.format_item_label(str(rumor_id).replace("_", " ")))
		"places":
			for screen_id in GameState.visited_places():
				out.append(DoomTypography.header_for_screen(screen_id))
	return out

func _on_close() -> void:
	visible = false
	closed.emit()
