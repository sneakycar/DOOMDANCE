extends Control
## RETURN BUT DIFFERENT — iPhone-first living world prototype.

@onready var _title: Label = %TitleLabel
@onready var _clock: Label = %ClockLabel
@onready var _banner: Label = %BannerLabel
@onready var _event_head: Label = %EventHeadline
@onready var _btn_a: Button = %ChoiceA
@onready var _btn_b: Button = %ChoiceB
@onready var _history_panel: PanelContainer = %HistoryPanel
@onready var _history_text: RichTextLabel = %HistoryText
@onready var _world_sprite: Sprite2D = %WorldSprite
@onready var _camera: Camera2D = %WorldCamera
@onready var _camera_rig: RbdCameraRig = %CameraRig
@onready var _world_viewport: SubViewportContainer = %WorldViewport
@onready var _influence_bar: HBoxContainer = %InfluenceBar
@onready var _region_label: Label = %RegionLabel
@onready var _memory_feed: Label = %MemoryFeed

var world := RbdWorld.new()
var clock := RbdClock.new()
var regions := RbdRegions.new()
var events := RbdEvents.new()
var history := RbdHistory.new()
var memory := RbdMemory.new()
var influence := RbdInfluence.new()
var world_tex := RbdWorldTexture.new()

var _sim_accum := 0.0
var _visual_accum := 0.0
var _region_accum := 0.0
var _shimmer := 0.0
var _last_save_unix := 0.0
var _autosave_accum := 0.0
var _influence_mode := RbdConstants.InfluenceMode.ATTRACT
var _offline_banner := ""
var _banner_ttl := 0.0
var _session_started := false
var _music_unlocked := false
var _offline_steps_pending := 0
var _offline_elapsed_pending := 0.0
var _offline_memory_pending := false

func _ready() -> void:
	_title.text = "RETURN BUT DIFFERENT"
	_world_sprite.texture = world_tex.texture
	_world_sprite.position = Vector2(-RbdConstants.WORLD_SIZE * 0.5, -RbdConstants.WORLD_SIZE * 0.5)
	if _world_sprite.material == null:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://return_but_different/shaders/world_display.gdshader")
		_world_sprite.material = mat
	_camera.enabled = true
	_camera.make_current()
	_camera_rig.camera = _camera
	_camera_rig.world_sprite = _world_sprite
	_btn_a.pressed.connect(func() -> void: _resolve_event(0))
	_btn_b.pressed.connect(func() -> void: _resolve_event(1))
	_wire_influence_buttons()
	_history_panel.visible = false
	_load_or_new()
	_refresh_ui()
	_session_started = true
	call_deferred("_start_soundtrack")

func _start_soundtrack() -> void:
	DoomMusic.unlock()

func _unhandled_input(event: InputEvent) -> void:
	if not _music_unlocked:
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			_music_unlocked = true
			DoomMusic.unlock()

func _wire_influence_buttons() -> void:
	for child in _influence_bar.get_children():
		if child is Button:
			child.pressed.connect(_on_influence_button.bind(child.name))

func _load_or_new() -> void:
	var data := RbdSave.load_session()
	var now := Time.get_unix_time_from_system()
	if data.is_empty():
		world.reset_world()
		memory.configure_from_world_seed(world.seed)
		regions.bootstrap_origin(clock)
		history.log(clock, "THE FIRST WHITE")
		_last_save_unix = now
		world_tex.refresh(world, 0.0, true)
		return
	clock.from_dict(data.get("clock", {}))
	world.from_save_dict(data.get("world", {}))
	regions.from_dict(data.get("regions", []))
	events.from_dict(data.get("events", {}))
	history.from_dict(data.get("history", []))
	memory.from_dict(data.get("memory", {}))
	influence.from_dict(data.get("influence", []))
	_last_save_unix = float(data.get("last_unix", now))
	var elapsed_offline := maxf(0.0, float(now - _last_save_unix))
	_queue_offline(elapsed_offline)
	_last_save_unix = now

func _queue_offline(elapsed_sec: float) -> void:
	if elapsed_sec < 2.0:
		_offline_banner = "RETURN BUT DIFFERENT"
		return
	var steps := int(elapsed_sec * RbdConstants.active_steps_per_second())
	_offline_steps_pending = mini(steps, RbdConstants.OFFLINE_MAX_STEPS)
	_offline_elapsed_pending = elapsed_sec
	_offline_memory_pending = elapsed_sec >= 120.0
	if _offline_steps_pending > 0:
		_offline_banner = "IT CHANGED WHILE YOU WERE AWAY"
		_banner_ttl = 14.0
	else:
		_offline_banner = "RETURN BUT DIFFERENT"

func _finish_offline_catchup() -> void:
	var elapsed := _offline_elapsed_pending
	if elapsed > 0.0:
		clock.elapsed_sec += elapsed
		influence.prune(clock.elapsed_sec)
		_offline_elapsed_pending = 0.0
	if _offline_memory_pending:
		memory.process_offline(elapsed, regions, world, clock, history)
		_offline_memory_pending = false
		var note := memory.get_last_notification()
		if not note.is_empty():
			_offline_banner = note
			_banner_ttl = 14.0
	var found := regions.scan(world, clock)
	for n in found:
		history.log(clock, n + " EMERGED")
		memory.on_region_emerged(regions.get_by_name(n), clock, history)

func _process_offline_batch() -> void:
	var batch := mini(_offline_steps_pending, RbdConstants.OFFLINE_STEPS_PER_FRAME)
	world.run_steps(batch, influence)
	_offline_steps_pending -= batch
	if _offline_steps_pending <= 0:
		_finish_offline_catchup()

func _process(delta: float) -> void:
	if not _session_started:
		return
	if _offline_steps_pending > 0:
		_process_offline_batch()
		_tick_banner(delta)
		_refresh_ui()
		return
	clock.tick(delta)
	_shimmer += delta
	_tick_banner(delta)
	_sim_accum += delta
	var rate := RbdConstants.active_steps_per_second()
	var steps := mini(int(_sim_accum * rate), RbdConstants.MAX_SIM_STEPS_PER_FRAME)
	if steps > 0:
		_sim_accum -= float(steps) / rate
		world.run_steps(steps, influence)
	influence.prune(clock.elapsed_sec)
	_visual_accum += delta
	var vis_hz := RbdConstants.visual_tick_hz()
	if _visual_accum >= 1.0 / vis_hz:
		_visual_accum = 0.0
		world_tex.set_stride(RbdConstants.visual_stride_for_zoom(_camera.zoom.x))
		world_tex.refresh(world, _shimmer, false)
		if _world_sprite.material is ShaderMaterial:
			_world_sprite.material.set_shader_parameter("shimmer_phase", _shimmer)
			_world_sprite.material.set_shader_parameter("zoom_level", _camera.zoom.x)
	_region_accum += delta
	if _region_accum >= RbdConstants.REGION_SCAN_INTERVAL:
		_region_accum = 0.0
		var found := regions.scan(world, clock)
		for n in found:
			history.log(clock, n + " EMERGED")
			memory.on_region_emerged(regions.get_by_name(n), clock, history)
		events.check_history_milestones(regions, clock, history)
		if not events.has_event():
			events.try_generate(world, regions, clock, history)
	memory.tick(clock, regions, world, history)
	_autosave_accum += delta
	if _autosave_accum > 10.0:
		_autosave_accum = 0.0
		_save()
	_refresh_ui()

func _tick_banner(delta: float) -> void:
	if _banner_ttl <= 0.0:
		return
	_banner_ttl -= delta
	if _banner_ttl <= 0.0:
		_offline_banner = ""

func _refresh_ui() -> void:
	_clock.text = clock.format()
	if _offline_banner.is_empty():
		_banner.text = "RETURN BUT DIFFERENT"
	else:
		_banner.text = _offline_banner
	if events.has_event():
		var ev: RbdEvents.PendingEvent = events.current
		_event_head.text = ev.headline
		_btn_a.text = ev.choice_a
		_btn_b.text = ev.choice_b
		_btn_a.visible = true
		_btn_b.visible = true
	else:
		_event_head.text = "THE WORLD IS EVOLVING."
		_btn_a.visible = false
		_btn_b.visible = false
	var fragments := memory.recent_fragments(4)
	_memory_feed.text = "" if fragments.is_empty() else "\n".join(fragments)
	if _history_panel.visible:
		_history_text.text = "\n\n".join(history.format_lines(120))

func _resolve_event(choice: int) -> void:
	var ev: RbdEvents.PendingEvent = events.current
	var effect := ""
	var region_id := ""
	if ev != null:
		effect = ev.effect
		region_id = ev.region_a_id
	events.resolve(choice, world, regions, clock, history, influence)
	if ev != null:
		memory.on_event_resolved(ev, choice, regions, clock, history)
	memory.on_player_decision(effect, region_id, regions, clock, history)
	_refresh_ui()

func _viewport_center_cell() -> Vector2i:
	if _world_viewport == null:
		return RbdConstants.ORIGIN
	var sv := _world_viewport.get_node_or_null("SubViewport") as SubViewport
	if sv == null or _world_viewport.size.x < 2.0:
		return RbdConstants.ORIGIN
	var scale := Vector2(sv.size) / _world_viewport.size
	var vp_pixel := _world_viewport.size * 0.5 * scale
	return _camera_rig.viewport_position_to_cell(vp_pixel)

func _place_influence_at_view_center() -> void:
	var cell := _viewport_center_cell()
	influence.place(_influence_mode, cell, clock.elapsed_sec)
	var reg := regions.region_at_point(cell)
	_region_label.text = reg.name if reg else "UNCLAIMED TERRITORY"

func _on_influence_button(mode_name: StringName) -> void:
	match str(mode_name):
		"Attract":
			_influence_mode = RbdConstants.InfluenceMode.ATTRACT
			_place_influence_at_view_center()
		"Repel":
			_influence_mode = RbdConstants.InfluenceMode.REPEL
			_place_influence_at_view_center()
		"Brighten":
			_influence_mode = RbdConstants.InfluenceMode.BRIGHTEN
			_place_influence_at_view_center()
		"Darken":
			_influence_mode = RbdConstants.InfluenceMode.DARKEN
			_place_influence_at_view_center()
		"History":
			_history_panel.visible = not _history_panel.visible
			_refresh_ui()
		"Origin":
			_camera_rig.focus_origin()
		"World":
			_camera_rig.focus_world()

func _save() -> void:
	_last_save_unix = Time.get_unix_time_from_system()
	RbdSave.save_session({
		"version": 3,
		"last_unix": _last_save_unix,
		"clock": clock.to_dict(),
		"world": world.to_save_dict(),
		"regions": regions.to_dict(),
		"events": events.to_dict(),
		"history": history.to_dict(),
		"memory": memory.to_dict(),
		"influence": influence.to_dict(),
	})

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		_start_soundtrack()
		var now := Time.get_unix_time_from_system()
		if _last_save_unix > 0.0:
			_queue_offline(maxf(0.0, float(now - _last_save_unix)))
		_last_save_unix = now
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save()
