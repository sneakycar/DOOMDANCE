extends Control
class_name LocationScreen

signal hotspot_pressed(hotspot: Dictionary)
signal empty_tapped

@onready var _background: TextureRect = %Background
@onready var _overlay_layer: Control = %OverlayLayer
@onready var _decay_layer: Control = %DecayLayer
@onready var _event_layer: Control = %EventLayer
@onready var _panhandle_overlay: Control = %PanhandleOverlay
@onready var _hotspot_layer: Control = %HotspotLayer
@onready var _status_label: Label = %StatusLabel
@onready var _dialogue: PanelContainer = %DialogueBox
@onready var _dialogue_text: Label = %DialogueText
@onready var _dialogue_dismiss: Button = %DialogueDismiss

var screen_id: String = ""
var _pending_data: Dictionary = {}
var _hotspot_rects: Dictionary = {}
var _showing_night: bool = false
var _last_minute_check := -1
var _inverted := false

func _ready() -> void:
	resized.connect(_on_resized)
	GameState.world_event_changed.connect(_refresh_world_events)
	_hotspot_layer.gui_input.connect(_on_hotspot_layer_input)
	_style_dialogue()
	_dialogue_dismiss.pressed.connect(_hide_dialogue)
	if not _pending_data.is_empty():
		_apply_setup(_pending_data)
		_pending_data.clear()

func _exit_tree() -> void:
	if GameState.world_event_changed.is_connected(_refresh_world_events):
		GameState.world_event_changed.disconnect(_refresh_world_events)
	if screen_id != "":
		DoomAmbience.clear_room()

func setup(id: String) -> void:
	screen_id = id
	var data: Dictionary = ScreenData.get_screen(id)
	if not is_node_ready():
		_pending_data = data
		return
	_apply_setup(data)

func _apply_setup(data: Dictionary) -> void:
	DoomTypography.stamp_mono(_status_label, 11)
	_status_label.add_theme_color_override("font_color", DoomTypography.COLOR_DIM)
	_inverted = false
	modulate = Color(1, 1, 1, 1)
	_hide_dialogue()
	_showing_night = DayNight.is_night()
	if screen_id == "impound_lot" and GameState.consume_aftermath():
		_status_label.visible = true
		_status_label.text = "ground zero."
		GameState.message_requested.emit("still raining.")
	_apply_background(data)
	_build_overlays(_overlays_for(data), data)
	_rebuild_hotspots(data)
	_apply_on_enter(data)
	_apply_decay(data)
	_refresh_world_events()
	_refresh_panhandle_status()
	_bind_panhandle_overlay()
	DoomAmbience.set_room(screen_id)

func _bind_panhandle_overlay() -> void:
	if _panhandle_overlay.has_method("bind_screen"):
		_panhandle_overlay.bind_screen(screen_id)

func _apply_decay(data: Dictionary) -> void:
	if not bool(data.get("decay", false)):
		_background.modulate = Color(1, 1, 1, 1)
		_clear_decay_layer()
		return
	var visits := GameState.location_visit_count(screen_id)
	var size := _decay_layer_size()
	ScreenDecay.apply(_decay_layer, _background, visits, size)
	var line := ScreenDecay.status_line(visits)
	_status_label.visible = not line.is_empty()
	_status_label.text = line
	if visits > 1:
		var whisper := ScreenDecay.whisper(visits)
		if whisper != "":
			GameState.message_requested.emit(whisper)
	var erosion := ScreenDecay.life_erosion(visits)
	if erosion < 0.0:
		GameState.adjust_life(erosion)

func _clear_decay_layer() -> void:
	for child in _decay_layer.get_children():
		child.queue_free()

func _decay_layer_size() -> Vector2:
	var layer_size := _decay_layer.size
	if layer_size.x > 1.0 and layer_size.y > 1.0:
		return layer_size
	return get_viewport_rect().size

func _apply_on_enter(data: Dictionary) -> void:
	var on_enter: Variant = data.get("on_enter", {})
	if typeof(on_enter) != TYPE_DICTIONARY:
		return
	var oe: Dictionary = on_enter
	var flag: String = str(oe.get("flag", ""))
	if flag != "" and GameState.is_collected(flag):
		return
	var msg: String = str(oe.get("message", ""))
	if msg != "":
		GameState.message_requested.emit(msg.to_upper())
	if oe.has("life_delta"):
		GameState.adjust_life(float(oe.get("life_delta", 0.0)))
	if oe.has("xp"):
		GameState.award_xp(float(oe.get("xp", 0.0)))
	var rumor: String = str(oe.get("discover_rumor", ""))
	if rumor != "":
		GameState.discover_rumor(rumor)
	if flag != "":
		GameState.mark_collected(flag)

func _overlays_for(data: Dictionary) -> Array:
	if DayNight.is_night():
		return data.get("overlays_night", data.get("overlays", []))
	return data.get("overlays_day", [])

func _apply_background(data: Dictionary) -> void:
	var bg_path := ScreenData.background_path(data)
	var tex: Texture2D = load(bg_path) as Texture2D
	if tex:
		_background.texture = tex
		_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_background.stretch_mode = TextureRect.STRETCH_SCALE
	elif not bg_path.is_empty():
		push_warning("Missing background: %s" % bg_path)

func _on_resized() -> void:
	_relayout_hotspots()
	var data := ScreenData.get_screen(screen_id)
	_build_overlays(_overlays_for(data), data)
	if bool(data.get("decay", false)):
		var visits := GameState.location_visit_count(screen_id)
		if visits > 0:
			ScreenDecay.apply(_decay_layer, _background, visits, _decay_layer_size())

func _process(_delta: float) -> void:
	var now := Time.get_datetime_dict_from_system()
	var minute_key: int = int(now.hour) * 60 + int(now.minute)
	if minute_key != _last_minute_check:
		_last_minute_check = minute_key
		var night := DayNight.is_night()
		if night != _showing_night:
			_showing_night = night
			if not screen_id.is_empty():
				var data := ScreenData.get_screen(screen_id)
				_apply_background(data)
				_build_overlays(_overlays_for(data), data)
				if bool(data.get("decay", false)):
					var visits := GameState.location_visit_count(screen_id)
					if visits > 0:
						ScreenDecay.apply(_decay_layer, _background, visits, _decay_layer_size())
		if screen_id == "panhandle" or ScreenData.is_activity_site(screen_id):
			_refresh_activity_status()

func _refresh_activity_status() -> void:
	if not ScreenData.is_activity_site(screen_id):
		return
	var line := GameState.activity_status_line()
	_status_label.visible = not line.is_empty()
	_status_label.text = line

func _refresh_panhandle_status() -> void:
	_refresh_activity_status()

func _refresh_alley_status() -> void:
	_refresh_panhandle_status()

func _refresh_world_events() -> void:
	for child in _event_layer.get_children():
		child.queue_free()
	if screen_id != "panhandle":
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

func _build_overlays(names: Array, data: Dictionary = {}) -> void:
	var size := _overlay_layer.size
	if size.x < 2.0:
		size = get_viewport_rect().size
	var extras := {
		"lamp_spots": data.get("lamp_spots", []),
		"neon_spots": data.get("neon_spots", []),
		"tv_static_rect": data.get("tv_static_rect", []),
		"tv_static_rects": data.get("tv_static_rects", []),
		"tv_baseball_rect": data.get("tv_baseball_rect", []),
	}
	ScreenOverlays.build(_overlay_layer, names, size, extras)

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

	await get_tree().process_frame
	_relayout_hotspots()
	if _hotspot_layer.get_child_count() > 0:
		call_deferred("_relayout_hotspots")

func _should_skip_hotspot(hotspot: Dictionary) -> bool:
	var action := str(hotspot.get("action", ""))
	if action == "collect" and bool(hotspot.get("collect_once", false)):
		var cid: String = str(hotspot.get("collectible_id", ""))
		if cid != "" and cid in GameState.seen_collectibles:
			return true
	if action == "buy":
		var cid: String = str(hotspot.get("collectible_id", ""))
		var data := CollectibleData.lookup(cid)
		if not data.is_empty() and GameState.has_item(str(data.get("name", ""))):
			return true
	if not ScreenData.is_panhandle_site(screen_id):
		pass
	else:
		match str(hotspot.get("action", "")):
			"panhandle":
				return GameState.is_panhandling_active()
			"stop_panhandle":
				return not GameState.is_panhandling_active()
			"collect_panhandle":
				return not GameState.can_collect_panhandle_at(screen_id)
	if not ScreenData.is_concert_site(screen_id):
		return false
	match str(hotspot.get("action", "")):
		"concert_offer":
			return not GameState.can_start_concert()
		"stop_concert":
			return not GameState.is_concert_active()
		"collect_concert":
			return not GameState.can_collect_concert_at(screen_id)
	return false

func refresh_hotspots() -> void:
	if screen_id.is_empty():
		return
	_rebuild_hotspots(ScreenData.get_screen(screen_id))
	_refresh_panhandle_status()
	_bind_panhandle_overlay()

func _on_hotspot_layer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		empty_tapped.emit()
	elif event is InputEventScreenTouch and event.pressed:
		empty_tapped.emit()

func _add_hotspot_button(hotspot: Dictionary) -> void:
	var id: String = hotspot.get("id", "unknown")
	_hotspot_rects[id] = hotspot.get("rect", [])
	var btn := Button.new()
	btn.name = "Hotspot_%s" % id
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.flat = true
	var invisible := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", invisible)
	btn.add_theme_stylebox_override("hover", invisible)
	btn.add_theme_stylebox_override("pressed", invisible)
	btn.add_theme_stylebox_override("focus", invisible)
	btn.add_theme_stylebox_override("disabled", invisible)
	btn.modulate = Color(1, 1, 1, 0)
	btn.pressed.connect(_on_hotspot_pressed.bind(hotspot.duplicate()))
	_hotspot_layer.add_child(btn)

func _hotspot_layer_size() -> Vector2:
	var layer_size := _hotspot_layer.size
	if layer_size.x > 1.0 and layer_size.y > 1.0:
		return layer_size
	var host_size := size
	if host_size.x > 1.0 and host_size.y > 1.0:
		return host_size
	return get_viewport_rect().size

func _relayout_hotspots() -> void:
	var layer_size := _hotspot_layer_size()
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
	var action: String = str(hotspot.get("action", "prompt"))
	if action == "invert_page":
		_toggle_invert()
		return
	if action == "dialogue":
		_show_dialogue(str(hotspot.get("dialogue", hotspot.get("text", ""))))
		return
	if action == "document":
		var doc_path: String = str(hotspot.get("document", ""))
		var doc_title: String = str(hotspot.get("document_title", hotspot.get("label", "READ.ME")))
		GameState.document_requested.emit(doc_path, doc_title)
		return
	hotspot_pressed.emit(hotspot)

func _toggle_invert() -> void:
	_inverted = not _inverted
	modulate = Color(-1, -1, -1, 1) if _inverted else Color(1, 1, 1, 1)

func _style_dialogue() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.93, 0.91, 0.86, 0.96)
	panel.border_color = Color(0.55, 0.52, 0.48, 1.0)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(16)
	panel.set_corner_radius_all(1)
	_dialogue.add_theme_stylebox_override("panel", panel)
	DoomTypography.stamp_fragment(_dialogue_text, 13)
	_dialogue_dismiss.flat = true
	_dialogue_dismiss.focus_mode = Control.FOCUS_NONE
	DoomTypography.stamp_fragment(_dialogue_dismiss, 11)
	var empty := StyleBoxEmpty.new()
	_dialogue_dismiss.add_theme_stylebox_override("normal", empty)
	_dialogue_dismiss.add_theme_stylebox_override("hover", empty)
	_dialogue_dismiss.add_theme_stylebox_override("pressed", empty)
	_dialogue_dismiss.add_theme_stylebox_override("focus", empty)

func _show_dialogue(text: String) -> void:
	if text.is_empty():
		return
	_dialogue_text.text = text
	_dialogue.visible = true

func _hide_dialogue() -> void:
	_dialogue.visible = false
	_dialogue_text.text = ""
