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
var _session_started := false
var _hooked_event_id := ""
var _music_unlocked := false

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
	if _music_unlocked:
		return
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
	_apply_offline(elapsed_offline)
	_last_save_unix = now

func _apply_offline(elapsed_sec: float) -> void:
	if elapsed_sec < 2.0:
		_offline_banner = "RETURN BUT DIFFERENT"
		return
	var steps := int(elapsed_sec * RbdConstants.ACTIVE_STEPS_PER_SECOND)
	steps = mini(steps, RbdConstants.OFFLINE_MAX_STEPS)
	world.run_steps(steps, influence)
	influence.prune(clock.elapsed_sec + elapsed_sec)
	clock.elapsed_sec += elapsed_sec
	memory.process_offline(elapsed_sec, regions, world, clock, history)
	if world.offline_delta_metric >= RbdConstants.OFFLINE_SIGNIFICANCE:
		_offline_banner = "IT CHANGED WHILE YOU WERE AWAY"
		history.log(clock, "THE WORLD CHANGED WHILE YOU WERE AWAY")
	else:
		_offline_banner = "RETURN BUT DIFFERENT"
	if not memory._last_notification.is_empty() and elapsed_sec >= 120.0:
		_offline_banner = memory._last_notification

func _process(delta: float) -> void:
	if not _session_started:
		return
	clock.tick(delta)
	_shimmer += delta
	_sim_accum += delta
	var steps := int(_sim_accum * RbdConstants.ACTIVE_STEPS_PER_SECOND)
	if steps > 0:
		_sim_accum -= float(steps) / RbdConstants.ACTIVE_STEPS_PER_SECOND
		world.run_steps(steps, influence)
	influence.prune(clock.elapsed_sec)
	_visual_accum += delta
	if _visual_accum >= 1.0 / RbdConstants.VISUAL_TICK_HZ:
		_visual_accum = 0.0
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
			var reg := regions.get_by_name(n)
			memory.on_region_emerged(reg, clock, history)
		events.check_history_milestones(regions, clock, history)
		if not events.has_event():
			events.try_generate(world, regions, clock, history)
		_hook_pending_event_memory()
	memory.tick(clock, regions, world, history)
	_autosave_accum += delta
	if _autosave_accum > 8.0:
		_autosave_accum = 0.0
		_save()
	_refresh_ui()

func _refresh_ui() -> void:
	_clock.text = clock.format()
	_banner.text = _offline_banner if not _offline_banner.is_empty() else "RETURN BUT DIFFERENT"
	if events.has_event():
		var ev: RbdEvents.PendingEvent = events.current
		_event_head.text = ev.headline
		_btn_a.text = ev.choice_a
		_btn_b.text = ev.choice_b
		_btn_a.visible = true
		_btn_b.visible = true
	else:
		_event_head.text = "The world is evolving."
		_btn_a.visible = false
		_btn_b.visible = false
	var fragments := memory.recent_fragments(4)
	if fragments.is_empty():
		_memory_feed.text = ""
	else:
		_memory_feed.text = "\n".join(fragments)
	if _history_panel.visible:
		_history_text.text = "\n\n".join(history.format_lines(120))

func _resolve_event(choice: int) -> void:
	var effect := ""
	var region_id := ""
	if events.current != null:
		effect = events.current.effect
		region_id = events.current.region_a_id
	events.resolve(choice, world, regions, clock, history, influence)
	memory.on_player_decision(effect, region_id, regions, clock, history)
	_refresh_ui()

func _hook_pending_event_memory() -> void:
	if not events.has_event():
		_hooked_event_id = ""
		return
	var ev: RbdEvents.PendingEvent = events.current
	if ev.id == _hooked_event_id:
		return
	_hooked_event_id = ev.id
	if not regions.regions.has(ev.region_a_id):
		return
	var region: RbdRegions.Region = regions.regions[ev.region_a_id]
	memory.on_world_headline(ev.headline, region, clock, history)
	if ev.effect == "contact" and regions.regions.has(ev.region_b_id):
		var other: RbdRegions.Region = regions.regions[ev.region_b_id]
		memory.on_region_contact(region, other, clock, history)

func _on_influence_button(mode_name: StringName) -> void:
	match str(mode_name):
		"Attract":
			_influence_mode = RbdConstants.InfluenceMode.ATTRACT
		"Repel":
			_influence_mode = RbdConstants.InfluenceMode.REPEL
		"Brighten":
			_influence_mode = RbdConstants.InfluenceMode.BRIGHTEN
		"Darken":
			_influence_mode = RbdConstants.InfluenceMode.DARKEN
		"History":
			_history_panel.visible = not _history_panel.visible
			_refresh_ui()
			return
		"Origin":
			_camera_rig.focus_origin()
			return
		"World":
			_camera_rig.focus_world()
			return
	var vp := get_viewport()
	if vp == null:
		return
	var screen_center := vp.get_visible_rect().size * 0.5
	var world_pos := _camera_rig.screen_to_world(screen_center)
	var cell := Vector2i(
		clampi(int(world_pos.x + RbdConstants.WORLD_SIZE * 0.5), 0, RbdConstants.WORLD_SIZE - 1),
		clampi(int(world_pos.y + RbdConstants.WORLD_SIZE * 0.5), 0, RbdConstants.WORLD_SIZE - 1)
	)
	influence.place(_influence_mode, cell, clock.elapsed_sec)
	var reg := regions.region_at_point(cell)
	if reg:
		_region_label.text = reg.name
	else:
		_region_label.text = "UNCLAIMED TERRITORY"

func _save() -> void:
	_last_save_unix = Time.get_unix_time_from_system()
	RbdSave.save_session({
		"version": 2,
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
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save()
