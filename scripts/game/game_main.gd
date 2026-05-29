extends Control

@onready var _screen_host: Control = %ScreenHost
@onready var _fade: ColorRect = %Fade
@onready var _transition_label: Label = %TransitionLabel
@onready var _play_button: Button = %PlayButton
@onready var _splash_layer: Control = %SplashLayer
@onready var _splash_image: TextureRect = %SplashImage
@onready var _hud_panel: PanelContainer = %HudPanel
@onready var _fragment: PanelContainer = %FragmentBar
@onready var _inventory_panel: Control = %InventoryPanel
@onready var _collections_panel: Control = %CollectionsPanel
@onready var _observation_panel: PanelContainer = %ObservationPanel
@onready var _dos_reader: DosReader = %DosReader
@onready var _transit_picker: TransitPicker = %TransitPicker
@onready var _sell_picker: SellPicker = %SellPicker

const MazeShellScene := preload("res://scenes/game/maze_shell.tscn")
const ArchiveLore := preload("res://scripts/game/archive_lore.gd")
const SPLASH_FADE_IN := 1.35
const SPLASH_HOLD := 2.75
const SPLASH_FADE_OUT := 0.9
const PANHANDLE_LORE_FIRST := 9.0
const PANHANDLE_LORE_MIN := 14.0
const PANHANDLE_LORE_MAX := 22.0

var _maze_shell: Control
var _fade_busy := false
var _intro_ready := false
var _game_started := false
var _intro_watchdog: SceneTreeTimer
var _intro_tween: Tween
var _in_location := false
var _panhandle_lore_timer: SceneTreeTimer
var _recent_lore_ids: Array[String] = []

func _ready() -> void:
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_transition_label()
	_style_play_button()
	%MuteButton.visible = true
	_hud_panel.visible = false
	%LocationBadge.visible = false
	_observation_panel.visible = false
	%CollectionsPanel.visible = false
	%InventoryPanel.visible = false
	%MessageLabel.visible = false
	GameState.message_requested.connect(_show_fragment)
	GameState.document_requested.connect(_on_document_requested)
	GameState.player_died.connect(_on_player_died)
	GameState.the_end_unlocked.connect(_on_the_end_unlocked)
	GameState.collections_changed.connect(_refresh_collections_unlock)
	_hud_panel.inventory_requested.connect(_toggle_inventory)
	_hud_panel.collections_requested.connect(_toggle_collections)
	_mount_maze()
	_splash_layer.gui_input.connect(_on_splash_input)
	GameState.panhandle_changed.connect(_on_panhandle_changed)
	_refresh_collections_unlock()
	_play_opening_intro()

func _mount_maze() -> void:
	_maze_shell = MazeShellScene.instantiate()
	_maze_shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	_maze_shell.view_mode_changed.connect(_on_view_mode_changed)
	_maze_shell.location_empty_tapped.connect(_on_location_empty_tapped)
	_maze_shell.transit_requested.connect(_on_transit_requested)
	_maze_shell.sell_requested.connect(_on_sell_requested)
	_maze_shell.hotspot_action_requested.connect(_on_hotspot_action_requested)
	_screen_host.add_child(_maze_shell)
	_transit_picker.route_selected.connect(_on_transit_route)
	_sell_picker.item_selected.connect(_on_sell_item)
	_observation_panel.action_confirmed.connect(_on_hotspot_confirmed)

func _play_opening_intro() -> void:
	_intro_ready = false
	_fade_busy = true
	_splash_layer.visible = true
	_splash_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_label.visible = false
	_play_button.visible = false
	_splash_image.modulate.a = 0.0
	_fade.color = Color(0, 0, 0, 1)
	_arm_intro_watchdog()
	var tween := create_tween()
	_intro_tween = tween
	tween.tween_property(_splash_image, "modulate:a", 1.0, SPLASH_FADE_IN)
	tween.tween_interval(SPLASH_HOLD)
	tween.tween_callback(func() -> void:
		_intro_ready = true
		_splash_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	)
	tween.tween_property(_splash_image, "modulate:a", 0.0, SPLASH_FADE_OUT)
	tween.parallel().tween_property(_fade, "color:a", 0.0, SPLASH_FADE_OUT + 0.15)
	tween.tween_callback(func() -> void:
		_splash_layer.visible = false
	)
	tween.finished.connect(_finish_game_start)

func _arm_intro_watchdog() -> void:
	if _intro_watchdog:
		_intro_watchdog.timeout.disconnect(_on_intro_watchdog)
	_intro_watchdog = get_tree().create_timer(14.0)
	_intro_watchdog.timeout.connect(_on_intro_watchdog)

func _on_intro_watchdog() -> void:
	if _game_started or not _fade_busy:
		return
	_skip_intro()

func _on_splash_input(event: InputEvent) -> void:
	if not _intro_ready or _game_started or not _fade_busy:
		return
	if _is_user_gesture(event):
		_skip_intro()

func _skip_intro() -> void:
	if _game_started or not _fade_busy:
		return
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = null
	_fade_busy = true
	_splash_image.modulate.a = 0.0
	_splash_layer.visible = false
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.55)
	tween.finished.connect(_finish_game_start)

func _finish_game_start() -> void:
	if _game_started:
		return
	if _intro_watchdog:
		_intro_watchdog.timeout.disconnect(_on_intro_watchdog)
		_intro_watchdog = null
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = null
	_fade.color.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_busy = false
	_splash_layer.visible = false
	_game_started = true
	_hud_panel.visible = true
	DoomMusic.unlock()
	if GameState.is_fresh_run():
		MazeStore.return_to_ground_zero(false)
	GameState.mark_game_started()
	_maze_shell.start_game()

func _on_view_mode_changed(in_location: bool, _screen_id: String) -> void:
	_in_location = in_location
	_observation_panel.visible = in_location
	if in_location:
		if GameState.is_panhandling_active():
			_sync_panhandle_lore()
		else:
			_observation_panel.show_passive("tap what catches you.", 2.8)
	else:
		_stop_panhandle_lore()

func _on_panhandle_changed() -> void:
	_sync_panhandle_lore()

func _sync_panhandle_lore() -> void:
	_stop_panhandle_lore()
	if not _game_started or not _in_location or not GameState.is_panhandling_active():
		if not GameState.is_panhandling_active():
			_observation_panel.clear_reading()
		return
	_schedule_panhandle_lore(PANHANDLE_LORE_FIRST)

func _schedule_panhandle_lore(delay: float) -> void:
	_stop_panhandle_lore_timer_only()
	_panhandle_lore_timer = get_tree().create_timer(delay)
	_panhandle_lore_timer.timeout.connect(_show_panhandle_lore)

func _show_panhandle_lore() -> void:
	_panhandle_lore_timer = null
	if not _game_started or not _in_location or not GameState.is_panhandling_active():
		return
	var lore: Dictionary = ArchiveLore.random_fragment(_recent_lore_ids)
	_recent_lore_ids.append(str(lore.get("id", "")))
	if _recent_lore_ids.size() > 10:
		_recent_lore_ids.pop_front()
	_observation_panel.show_reading(str(lore.get("title", "archive")), str(lore.get("body", "")))
	_schedule_panhandle_lore(randf_range(PANHANDLE_LORE_MIN, PANHANDLE_LORE_MAX))

func _stop_panhandle_lore() -> void:
	_stop_panhandle_lore_timer_only()
	_observation_panel.clear_reading()

func _stop_panhandle_lore_timer_only() -> void:
	if _panhandle_lore_timer == null:
		return
	if _panhandle_lore_timer.timeout.is_connected(_show_panhandle_lore):
		_panhandle_lore_timer.timeout.disconnect(_show_panhandle_lore)
	_panhandle_lore_timer = null

func _on_hotspot_action_requested(hotspot: Dictionary) -> void:
	if not _game_started:
		return
	_observation_panel.show_hotspot(hotspot)

func _on_hotspot_confirmed(hotspot: Dictionary) -> void:
	if _maze_shell:
		_maze_shell.execute_hotspot(hotspot)

func _on_location_empty_tapped() -> void:
	_observation_panel.show_passive("keep looking.", 2.2)

func _on_transit_requested() -> void:
	_transit_picker.open_picker()

func _on_sell_requested(venue: String) -> void:
	if venue == "record":
		_sell_picker.open_picker("record", RecordCatalog.header_text(), RecordCatalog.subtitle_text())
	else:
		_sell_picker.open_picker("pawn", PawnCatalog.header_text(), PawnCatalog.subtitle_text())

func _on_sell_item(collectible_id: String, venue: String) -> void:
	if venue == "record":
		GameState.sell_at_record_store(collectible_id)
	else:
		GameState.sell_at_pawn(collectible_id)

func _on_transit_route(route: Dictionary) -> void:
	var cost := TransitData.route_cost(route)
	if not GameState.buy_transit_pass(cost):
		return
	var target := str(route.get("target", ""))
	var target_type := str(route.get("target_type", "location"))
	if target_type == "maze":
		MazeStore.go(target)
	elif ScreenData.get_screen(target).size() > 0:
		_maze_shell.travel_to_location(target)
	else:
		GameState.message_requested.emit(CopyData.lookup("affordance/nothing_happens", "—"))
		return
	GameState.message_requested.emit(CopyData.lookup("commerce/transit", "septa. $%d.") % cost)

func _apply_transition_label() -> void:
	DoomTypography.stamp_transition(_transition_label, 42)
	_transition_label.visible = false
	_transition_label.modulate.a = 0.0
	_transition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _style_play_button() -> void:
	_play_button.visible = false
	_play_button.focus_mode = Control.FOCUS_NONE

func _show_fragment(text: String, duration: float = 3.2) -> void:
	_fragment.show_fragment(text, duration)

func _on_document_requested(path: String, title: String) -> void:
	_dos_reader.open_document(path, title)

func _on_player_died() -> void:
	if GameState.is_immortal():
		return
	MazeStore.return_to_ground_zero(true)
	_show_fragment("YOU DIED.", 4.0)

func _on_the_end_unlocked() -> void:
	if not _game_started:
		return
	_play_the_end_sequence()

func _play_the_end_sequence() -> void:
	_fade_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 1.4)
	tween.tween_callback(func() -> void:
		MazeStore.return_to_ground_zero(false)
		GameState.reset_life()
	)
	tween.tween_interval(0.65)
	tween.tween_callback(func() -> void:
		_show_fragment("everything fades.", 6.0)
	)
	tween.tween_property(_fade, "color:a", 0.0, 1.6)
	tween.tween_callback(func() -> void:
		_fade_busy = false
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)

func _toggle_inventory() -> void:
	_inventory_panel.visible = not _inventory_panel.visible
	if _inventory_panel.visible:
		_collections_panel.visible = false

func _toggle_collections() -> void:
	if not GameState.has_any_collectible():
		return
	_collections_panel.visible = not _collections_panel.visible
	if _collections_panel.visible:
		_inventory_panel.visible = false

func _refresh_collections_unlock() -> void:
	_hud_panel.set_collections_unlocked(GameState.has_any_collectible())

func _input(event: InputEvent) -> void:
	if _is_user_gesture(event):
		DoomMusic.unlock()

func _unhandled_input(event: InputEvent) -> void:
	if _is_user_gesture(event):
		DoomMusic.unlock()

func _is_user_gesture(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed:
		return true
	if event is InputEventScreenTouch and event.pressed:
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return true
	return false
