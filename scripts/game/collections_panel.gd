extends PanelContainer

signal closed()

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
	var held := GameState.inventory_counts()
	_add_section_header("HELD")
	if held.is_empty():
		_add_line("—")
	else:
		for item_name in held.keys():
			var cid := CollectibleData.id_for_name(item_name)
			var suffix := " x%d" % held[item_name] if int(held[item_name]) > 1 else ""
			_add_line("• %s%s" % [DoomTypography.format_item_label(item_name), suffix], true)
	for cat in CollectibleData.category_keys():
		var entries := _seen_lines_for_category(cat, held)
		if entries.is_empty():
			continue
		_add_section_header(CollectibleData.category_label(cat))
		for line in entries:
			_add_line(line)
	if not GameState.discovered_rumors.is_empty():
		_add_section_header("RUMORS")
		for rumor_id in GameState.discovered_rumors:
			_add_line(RumorData.label_for(str(rumor_id)))
	if not GameState.visited_places().is_empty():
		_add_section_header("PLACES")
		for screen_id in GameState.visited_places():
			var req := ProgressionData.location_visits_required(screen_id)
			var count := GameState.location_visit_count(screen_id)
			var mark := "✓" if count >= req else "%d/%d" % [count, req]
			_add_line("%s  %s" % [DoomTypography.header_for_screen(screen_id), mark])

func _seen_lines_for_category(category: String, held: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for entry in CollectibleData.all_in_category(category):
		var id: String = entry.get("id", "")
		if id not in GameState.seen_collectibles:
			continue
		var name: String = entry.get("name", id)
		if held.has(name):
			continue
		out.append("  %s" % DoomTypography.format_item_label(name))
	return out

func _add_section_header(text: String) -> void:
	var header := Label.new()
	header.text = text
	DoomTypography.stamp_mono(header, 11, true)
	_list.add_child(header)

func _add_line(text: String, bright: bool = false) -> void:
	var item_lbl := Label.new()
	item_lbl.text = text
	DoomTypography.stamp_mono(item_lbl, 11, not bright)
	_list.add_child(item_lbl)

func _on_close() -> void:
	visible = false
	closed.emit()
