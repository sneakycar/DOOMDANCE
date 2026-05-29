extends Control
## Deadbicycle maze shell — page view + location screens + footer tools.

signal location_requested(screen_id: String)
signal view_mode_changed(in_location: bool, screen_id: String)
signal location_empty_tapped
signal transit_requested
signal sell_requested(venue: String)
signal hotspot_action_requested(hotspot: Dictionary)

const LocationScreenScene := preload("res://scenes/game/location_screen.tscn")

@onready var _page_host: Control = %PageHost
@onready var _location_host: Control = %LocationHost
@onready var _page_view: Control = %MazePageView
@onready var _footer: HBoxContainer = %MazeFooter
@onready var _overlay: Label = %OverlayBanner

var _location_screen: LocationScreen
var _location_screen_id := ""
var _started := false

func _ready() -> void:
	_footer.tool_pressed.connect(_on_tool)
	MazeStore.overlay_message.connect(_show_overlay)
	MazeStore.room_changed.connect(_on_room_changed)
	_page_view.navigate.connect(_on_navigate)

func start_game() -> void:
	if _started:
		return
	_started = true
	MazeStore.begin_session()

func _on_room_changed(page_id: String) -> void:
	if not _started:
		return
	var loc := MazeStore.location_screen_for(page_id)
	if loc != "" and ScreenData.get_screen(loc).size() > 0:
		_show_location(loc)
	else:
		_location_screen_id = ""
		_show_maze_page(page_id)
		view_mode_changed.emit(false, page_id)

func travel_to_location(screen_id: String) -> void:
	if ScreenData.get_screen(screen_id).is_empty():
		return
	_show_location(screen_id)

func _show_location(screen_id: String) -> void:
	if _leaving_panhandle_site(_location_screen_id, screen_id):
		GameState.stop_panhandle()
	if _leaving_concert_site(_location_screen_id, screen_id):
		GameState.stop_concert()
	_location_screen_id = screen_id
	_location_host.visible = true
	_page_host.visible = false
	if _location_screen:
		_location_screen.queue_free()
	GameState.mark_location_visit(screen_id)
	GameState.prepare_location_collects(screen_id)
	_location_screen = LocationScreenScene.instantiate()
	_location_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_location_screen.hotspot_pressed.connect(_on_location_hotspot)
	_location_screen.empty_tapped.connect(_on_location_empty_tap)
	_location_host.add_child(_location_screen)
	_location_screen.setup(screen_id)
	view_mode_changed.emit(true, screen_id)

func _show_maze_page(page_id: String) -> void:
	if ScreenData.is_panhandle_site(_location_screen_id) and GameState.is_panhandling_active():
		GameState.stop_panhandle()
	if ScreenData.is_concert_site(_location_screen_id) and GameState.is_concert_active():
		GameState.stop_concert()
	DoomAmbience.clear_room()
	_location_host.visible = false
	_page_host.visible = true
	_page_view.show_page(page_id)

func _on_navigate(dest: String) -> void:
	DoomMusic.unlock()
	MazeStore.go(dest)

func _on_location_hotspot(hotspot: Dictionary) -> void:
	DoomMusic.unlock()
	hotspot_action_requested.emit(hotspot.duplicate())

func execute_hotspot(hotspot: Dictionary) -> void:
	var action: String = str(hotspot.get("action", "prompt"))
	match action:
		"goto":
			_go_hotspot_target(hotspot)
		"collect":
			_try_collect(hotspot)
		"document":
			var doc_path: String = str(hotspot.get("document", ""))
			var doc_title: String = str(hotspot.get("document_title", hotspot.get("label", "READ.ME")))
			GameState.document_requested.emit(doc_path, doc_title)
		"buy":
			_try_buy(hotspot)
		"panhandle":
			if GameState.can_start_panhandle():
				GameState.start_panhandle(_location_screen_id)
				if _location_screen:
					_location_screen.refresh_hotspots()
		"stop_panhandle":
			GameState.stop_panhandle()
			if _location_screen:
				_location_screen.refresh_hotspots()
		"collect_panhandle":
			if not GameState.can_collect_panhandle_at(_location_screen_id):
				GameState.message_requested.emit(CopyData.lookup("panhandle/away", "come back where you sat."))
			elif GameState.collect_panhandle() and _location_screen:
				_location_screen.refresh_hotspots()
		"concert_offer":
			if GameState.can_start_concert():
				GameState.start_concert(_location_screen_id)
				if _location_screen:
					_location_screen.refresh_hotspots()
			else:
				GameState.message_requested.emit(CopyData.lookup("concert/blocked", "not now."))
		"stop_concert":
			GameState.stop_concert()
			if _location_screen:
				_location_screen.refresh_hotspots()
		"collect_concert":
			if not GameState.can_collect_concert_at(_location_screen_id):
				GameState.message_requested.emit(CopyData.lookup("concert/away", "come back where you stood."))
			elif GameState.collect_concert() and _location_screen:
				_location_screen.refresh_hotspots()
		"transit":
			transit_requested.emit()
		"sell":
			sell_requested.emit(str(hotspot.get("venue", "pawn")))
		"prompt":
			GameState.message_requested.emit(str(hotspot.get("text", "...")))
		_:
			GameState.message_requested.emit(str(hotspot.get("text", "...")))

func _try_buy(hotspot: Dictionary) -> void:
	var cid: String = str(hotspot.get("collectible_id", ""))
	var cost: int = int(hotspot.get("cost", 0))
	if cid.is_empty() or cost <= 0:
		GameState.message_requested.emit(str(hotspot.get("text", "...")))
		return
	GameState.buy_collectible(cid, cost, _location_screen_id)

func _leaving_panhandle_site(from_id: String, to_id: String) -> bool:
	return (
		from_id != ""
		and from_id != to_id
		and ScreenData.is_panhandle_site(from_id)
		and GameState.is_panhandling_active()
	)

func _leaving_concert_site(from_id: String, to_id: String) -> bool:
	return (
		from_id != ""
		and from_id != to_id
		and ScreenData.is_concert_site(from_id)
		and GameState.is_concert_active()
	)

func _on_location_empty_tap() -> void:
	location_empty_tapped.emit()

func _go_hotspot_target(hotspot: Dictionary) -> void:
	var target: String = str(hotspot.get("target", ""))
	if target.is_empty():
		GameState.message_requested.emit(str(hotspot.get("text", "...")))
		return
	if MazeStore.has_page(target):
		MazeStore.go(target)
	elif ScreenData.get_screen(target).size() > 0:
		_show_location(target)
	else:
		location_requested.emit(target)

func _try_collect(hotspot: Dictionary) -> void:
	var hotspot_id := str(hotspot.get("id", ""))
	var cid: String = str(hotspot.get("collectible_id", ""))
	if bool(hotspot.get("collect_once", false)) and cid != "" and cid in GameState.seen_collectibles:
		GameState.message_requested.emit(str(hotspot.get("miss_text", "already taken.")))
		return
	var data := CollectibleData.lookup(cid)
	var item_name: String = str(data.get("name", hotspot.get("item", "thing")))
	if not GameState.is_repeat_collect_available(_location_screen_id, hotspot_id):
		GameState.message_requested.emit(str(hotspot.get("miss_text", "nothing this time.")))
		return
	if cid != "":
		GameState.add_collectible_stack(cid)
	else:
		GameState.add_item_stack(item_name)
	GameState.consume_repeat_collect(_location_screen_id, hotspot_id)
	var pickup: String = str(hotspot.get("pickup_text", hotspot.get("text", "something went in your pocket.")))
	GameState.message_requested.emit(pickup)

func _on_tool(tool: String) -> void:
	DoomMusic.unlock()
	match tool:
		"BACK":
			MazeStore.go_back()
		"LOST":
			MazeStore.go_lost()
		"RND":
			MazeStore.go_random()
		"DIG":
			MazeStore.dig()
		"TEST":
			if OS.is_debug_build():
				MazeStore.go("broadcastpanic")

func _show_overlay(text: String) -> void:
	_overlay.text = text.to_upper()
	_overlay.visible = true
	_overlay.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.8)
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.35)
	tw.finished.connect(func() -> void: _overlay.visible = false)
