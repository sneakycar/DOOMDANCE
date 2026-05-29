extends Control
## Single maze page — broken-web layout with animated fragments.

signal navigate(destination: String)

@onready var _scroll: ScrollContainer = %Scroll
@onready var _content: VBoxContainer = %Content
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _status: Label = %Status
@onready var _mutation: Label = %Mutation
@onready var _encounter: Label = %Encounter
@onready var _image_row: HBoxContainer = %ImageRow
@onready var _body: Label = %Body
@onready var _fragment_grid: GridContainer = %FragmentGrid
@onready var _link_box: VBoxContainer = %LinkBox

var _page_id := ""
var _unstable := false
var _pulse_tween: Tween
var _drift_tween: Tween

func _ready() -> void:
	_apply_typography()
	MazeStore.room_changed.connect(_on_room_changed)
	_start_ambient_motion()

func _apply_typography() -> void:
	DoomTypography.stamp_transition(_title, 26)
	_subtitle.add_theme_font_size_override("font_size", 10)
	DoomTypography.stamp_mono(_subtitle, 10, true)
	_subtitle.add_theme_color_override("font_color", Color(1, 0.15, 0.12, 0.78))
	DoomTypography.stamp_mono(_status, 9, true)
	DoomTypography.stamp_mono(_mutation, 10)
	DoomTypography.stamp_mono(_encounter, 10)
	DoomTypography.stamp_fragment(_body, 12)

func _start_ambient_motion() -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_title, "modulate", Color(1, 0.92, 0.9, 1), 0.55)
	_pulse_tween.tween_property(_title, "modulate", Color(1, 1, 1, 1), 0.55)

func show_page(page_id: String) -> void:
	_page_id = page_id
	var p: Dictionary = MazeStore.page(page_id)
	_unstable = bool(p.get("unstable", false))
	_title.text = str(p.get("title", page_id)).to_upper()
	_subtitle.text = str(p.get("subtitle", "")).to_upper()
	_subtitle.visible = not _subtitle.text.is_empty()
	_status.text = MazeStore.status_line(page_id).to_upper()
	var mut := MazeStore.mutation_line(page_id)
	_mutation.text = mut
	_mutation.visible = mut != ""
	var enc := MazeStore.encounter_line(page_id)
	_encounter.text = ("encounter: " + enc) if enc != "" else ""
	_encounter.visible = enc != ""
	_body.text = str(p.get("body", ""))
	_body.visible = not _body.text.is_empty()
	if page_id == "hidden":
		_body.add_theme_font_size_override("font_size", 16)
	else:
		_body.add_theme_font_size_override("font_size", 12)
	if page_id == "residue":
		_body.text = MazeStore.residue_text()
	_rebuild_images(p.get("images", []))
	_rebuild_fragments(MazeStore.filtered_fragments(page_id))
	_rebuild_links(MazeStore.filtered_links(page_id))
	_apply_unstable_drift()
	await get_tree().process_frame
	_scroll.scroll_vertical = 0

func _on_room_changed(page_id: String) -> void:
	show_page(page_id)

func _apply_unstable_drift() -> void:
	if _drift_tween:
		_drift_tween.kill()
	if not _unstable:
		_content.position.x = 0
		return
	_content.position.x = randf_range(-6, 6)
	_drift_tween = create_tween().set_loops()
	_drift_tween.tween_property(_content, "position:x", randf_range(-10, 10), 0.18)
	_drift_tween.tween_property(_content, "position:x", randf_range(-10, 10), 0.22)

func _rebuild_images(paths: Array) -> void:
	for c in _image_row.get_children():
		c.queue_free()
	for path in paths:
		_image_row.add_child(_make_image_tile(str(path)))

func _make_image_tile(path: String) -> Control:
	var wrap := AspectRatioContainer.new()
	wrap.custom_minimum_size = Vector2(120, 90)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		rect.texture = tex
	wrap.add_child(rect)
	_animate_tile(wrap, path.ends_with(".gif"))
	return wrap

func _animate_tile(node: Control, is_gif: bool) -> void:
	var tw := node.create_tween().set_loops()
	if is_gif:
		tw.tween_property(node, "modulate:a", 0.72, 0.08)
		tw.tween_property(node, "modulate:a", 1.0, 0.11)
		tw.tween_property(node, "scale", Vector2(1.02, 0.98), 0.14)
		tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.14)
	else:
		tw.tween_property(node, "modulate", Color(1, 1, 1, 0.88), 1.2)
		tw.tween_property(node, "modulate", Color(1, 0.95, 0.92, 1), 1.4)

func _rebuild_fragments(fragments: Array) -> void:
	for c in _fragment_grid.get_children():
		c.queue_free()
	for f in fragments:
		_fragment_grid.add_child(_make_fragment_button(f))

func _make_fragment_button(data: Dictionary) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(140, 110)
	var text: String = str(data.get("text", "???"))
	var img_path: String = str(data.get("image", ""))
	if img_path != "":
		var tex: Texture2D = load(img_path) as Texture2D
		if tex:
			btn.icon = tex
			btn.expand_icon = true
	btn.text = text.to_upper()
	btn.add_theme_font_size_override("font_size", 9)
	DoomTypography.stamp_game(btn, 9)
	var dest: String = str(data.get("destination", ""))
	btn.pressed.connect(func() -> void:
		if dest != "":
			navigate.emit(dest)
	)
	var tw := btn.create_tween().set_loops()
	tw.tween_property(btn, "modulate", Color(1, 0.9, 0.86, 1), randf_range(0.4, 1.2))
	tw.tween_property(btn, "modulate", Color(1, 1, 1, 1), randf_range(0.4, 1.2))
	return btn

func _rebuild_links(links: Array) -> void:
	for c in _link_box.get_children():
		c.queue_free()
	for l in links:
		var btn := LinkButton.new()
		btn.text = str(l.get("label", "link")).to_lower()
		btn.underline = LinkButton.UNDERLINE_MODE_ALWAYS
		btn.add_theme_font_size_override("font_size", 11)
		DoomTypography.stamp_fragment(btn, 11)
		var dest: String = str(l.get("destination", ""))
		btn.pressed.connect(func() -> void: navigate.emit(dest))
		_link_box.add_child(btn)
