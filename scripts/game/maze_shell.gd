extends Control
## Deadbicycle maze shell — page view + location screens + footer tools.

signal location_requested(screen_id: String)

const LocationScreenScene := preload("res://scenes/game/location_screen.tscn")

@onready var _page_host: Control = %PageHost
@onready var _location_host: Control = %LocationHost
@onready var _page_view: Control = %MazePageView
@onready var _footer: HBoxContainer = %MazeFooter
@onready var _overlay: Label = %OverlayBanner

var _location_screen: LocationScreen
var _location_screen_id := ""

func _ready() -> void:
	_footer.tool_pressed.connect(_on_tool)
	MazeStore.overlay_message.connect(_show_overlay)
	MazeStore.room_changed.connect(_on_room_changed)
	_page_view.navigate.connect(_on_navigate)
	_on_room_changed(MazeStore.current_id)

func _on_room_changed(page_id: String) -> void:
	var loc := MazeStore.location_screen_for(page_id)
	if loc != "" and ScreenData.get_screen(loc).size() > 0:
		_show_location(loc)
	else:
		_location_screen_id = ""
		_show_maze_page(page_id)

func _show_location(screen_id: String) -> void:
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
	_location_host.add_child(_location_screen)
	_location_screen.setup(screen_id)

func _show_maze_page(page_id: String) -> void:
	_location_host.visible = false
	_page_host.visible = true
	_page_view.show_page(page_id)

func _on_navigate(dest: String) -> void:
	DoomMusic.unlock()
	MazeStore.go(dest)

func _on_location_hotspot(hotspot: Dictionary) -> void:
	DoomMusic.unlock()
	var action: String = str(hotspot.get("action", "prompt"))
	match action:
		"goto":
			_go_hotspot_target(hotspot)
		"collect":
			_try_collect(hotspot)
		_:
			GameState.message_requested.emit(str(hotspot.get("text", "...")))

func _go_hotspot_target(hotspot: Dictionary) -> void:
	var target: String = str(hotspot.get("target", ""))
	if target.is_empty():
		GameState.message_requested.emit(str(hotspot.get("text", "...")))
		return
	if MazeStore.has_page(target):
		MazeStore.go(target)
	elif ScreenData.get_screen(target).size() > 0:
		MazeStore.go(target)
	else:
		location_requested.emit(target)

func _try_collect(hotspot: Dictionary) -> void:
	var hotspot_id := str(hotspot.get("id", ""))
	var cid: String = str(hotspot.get("collectible_id", ""))
	var data := CollectibleData.lookup(cid)
	var item_name: String = str(data.get("name", hotspot.get("item", "thing")))
	if not GameState.is_repeat_collect_available(_location_screen_id, hotspot_id):
		GameState.message_requested.emit(str(hotspot.get("miss_text", "nothing there right now.")))
		return
	if cid != "":
		GameState.add_collectible_stack(cid)
	else:
		GameState.add_item_stack(item_name)
	GameState.consume_repeat_collect(_location_screen_id, hotspot_id)
	var pickup: String = str(hotspot.get("pickup_text", hotspot.get("text", "something went in your pocket.")))
	GameState.message_requested.emit(pickup)
	if _location_screen and _location_screen_id != "":
		_location_screen.setup(_location_screen_id)

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
