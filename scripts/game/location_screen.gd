extends Control
class_name LocationScreen

signal hotspot_pressed(hotspot: Dictionary)
signal tap_hint_changed(text: String)

@onready var _background: TextureRect = %Background
@onready var _overlay_layer: Control = %OverlayLayer
@onready var _event_layer: Control = %EventLayer
@onready var _hotspot_layer: Control = %HotspotLayer
@onready var _location_header: Label = %LocationHeader
@onready var _status_label: Label = %StatusLabel

var screen_id: String = ""
var _pending_data: Dictionary = {}
var _hotspot_rects: Dictionary = {}

func _ready() -> void:
	resized.connect(_on_resized)
	GameState.world_event_changed.connect(_refresh_world_events)
	if not _pending_data.is_empty():
		_apply_setup(_pending_data)
		_pending_data.clear()

func _exit_tree() -> void:
	if GameState.world_event_changed.is_connected(_refresh_world_events):
		GameState.world_event_changed.disconnect(_refresh_world_events)

func setup(id: String) -> void:
	screen_id = id
	var data: Dictionary = ScreenData.get_screen(id)
	if not is_node_ready():
		_pending_data = data
		return
	_apply_setup(data)

func _apply_setup(data: Dictionary) -> void:
	_location_header.text = DoomTypography.header_for_screen(screen_id)
	DoomTypography.stamp_signage(_location_header, 20)
	DoomTypography.stamp_mono(_status_label, 11)
	_status_label.add_theme_color_override("font_color", DoomTypography.COLOR_DIM)
	var bg_path: String = data.get("background", "")
	var tex: Texture2D = load(bg_path) as Texture2D
	if tex:
		_background.texture = tex
		_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		push_warning("Missing background: %s" % bg_path)
	_build_overlays(data.get("overlays", []))
	_rebuild_hotspots(data)
	_refresh_alley_status()
	_refresh_world_events()

func _on_resized() -> void:
	_relayout_hotspots()
	var data := ScreenData.get_screen(screen_id)
	_build_overlays(data.get("overlays", []))

func _process(_delta: float) -> void:
	if screen_id == "alley":
		_refresh_alley_status()

func _refresh_alley_status() -> void:
	if screen_id != "alley":
		_status_label.visible = false
		return
	var line := GameState.panhandle_status_line()
	_status_label.visible = not line.is_empty()
	_status_label.text = line

func _refresh_world_events() -> void:
	for child in _event_layer.get_children():
		child.queue_free()
	if screen_id != "alley":
		return
	if not GameState.is_fence_man_visible():
		return
	var layer_size := _event_layer.size
	if layer_size.x < 2.0:
		return
	var man := ColorRect.new()
	man.name = "FenceMan"
	man.mouse_filter = Control.MOUSE_FILTER_IGNORE
	man.color = Color(0.08, 0.08, 0.12, 0.88)
	man.position = Vector2(layer_size.x * 0.52, layer_size.y * 0.38)
	man.size = Vector2(layer_size.x * 0.11, layer_size.y * 0.34)
	_event_layer.add_child(man)
	if not GameState.fence_man_seen:
		get_tree().create_timer(2.5).timeout.connect(func() -> void:
			if is_instance_valid(self) and GameState.is_fence_man_visible():
				GameState.note_fence_man_witnessed()
				_refresh_world_events()
		)

func _build_overlays(names: Array) -> void:
	var size := _overlay_layer.size
	if size.x < 2.0:
		size = get_viewport_rect().size
	ScreenOverlays.build(_overlay_layer, names, size)

func _rebuild_hotspots(data: Dictionary) -> void:
	for child in _hotspot_layer.get_children():
		_hotspot_layer.remove_child(child)
		child.queue_free()
	_hotspot_rects.clear()
	call_deferred("_finish_rebuild_hotspots", data)

func _finish_rebuild_hotspots(data: Dictionary) -> void:
	var hotspots: Array = data.get("hotspots", [])
	for h in hotspots:
		var hotspot: Dictionary = h
		if _should_skip_hotspot(hotspot):
			continue
		_add_hotspot_button(hotspot)

	if screen_id == "alley":
		_add_alley_panhandle_hotspots()

	_relayout_hotspots()

func _should_skip_hotspot(hotspot: Dictionary) -> bool:
	if hotspot.get("action", "") == "collect":
		var flag: String = hotspot.get("flag", "")
		if flag != "" and GameState.is_collected(flag):
			return true
	return false

func _add_alley_panhandle_hotspots() -> void:
	if GameState.is_panhandle_ready_to_collect():
		_add_hotspot_button({
			"id": "collect_earnings",
			"label": "Collect Earnings",
			"rect": [0.02, 0.62, 0.28, 0.28],
			"action": "collect_panhandle"
		})
	elif GameState.can_start_panhandle():
		_add_hotspot_button({
			"id": "panhandle",
			"label": "PANHANDLE",
			"rect": [0.02, 0.62, 0.28, 0.28],
			"action": "panhandle"
		})

func _add_hotspot_button(hotspot: Dictionary) -> void:
	var id: String = hotspot.get("id", "unknown")
	_hotspot_rects[id] = hotspot.get("rect", [])
	var label_text: String = str(hotspot.get("label", "???")).to_upper()
	var btn := Button.new()
	btn.name = "Hotspot_%s" % id
	btn.text = label_text if MobileUI.is_touch_device else ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.flat = not MobileUI.is_touch_device
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.38 if MobileUI.is_touch_device else 0.28)
	style.border_color = Color(1, 1, 1, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.2, 0.18, 0.12, 0.65)
	pressed.border_color = Color(1, 0.9, 0.5, 0.85)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_font_size_override("font_size", 12 if MobileUI.is_touch_device else 11)
	if DoomTypography.mono:
		btn.add_theme_font_override("font", DoomTypography.mono)
	if not MobileUI.is_touch_device:
		var hover := style.duplicate()
		hover.bg_color = Color(0.15, 0.14, 0.2, 0.55)
		hover.border_color = Color(1, 0.9, 0.5, 0.65)
		btn.add_theme_stylebox_override("hover", hover)
		btn.mouse_entered.connect(func() -> void: tap_hint_changed.emit(label_text))
		btn.mouse_exited.connect(func() -> void: tap_hint_changed.emit(""))
	btn.button_down.connect(func() -> void: tap_hint_changed.emit(label_text))
	btn.pressed.connect(_on_hotspot_pressed.bind(hotspot.duplicate()))
	_hotspot_layer.add_child(btn)

func _relayout_hotspots() -> void:
	var layer_size := _hotspot_layer.size
	if layer_size.x <= 1.0 or layer_size.y <= 1.0:
		return
	for child in _hotspot_layer.get_children():
		if not child is Button:
			continue
		var id := child.name.replace("Hotspot_", "")
		var rect_norm: Array = _hotspot_rects.get(id, [])
		if rect_norm.is_empty():
			continue
		var rect := Rect2(
			Vector2(rect_norm[0], rect_norm[1]) * layer_size,
			Vector2(rect_norm[2], rect_norm[3]) * layer_size
		)
		rect = MobileUI.expand_rect_to_min_tap(rect, layer_size)
		child.position = rect.position
		child.size = rect.size

func _on_hotspot_pressed(hotspot: Dictionary) -> void:
	hotspot_pressed.emit(hotspot)
