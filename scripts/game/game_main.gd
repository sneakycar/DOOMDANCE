extends Control

@onready var _screen_host: Control = %ScreenHost
@onready var _fade: ColorRect = %Fade
@onready var _message_label: Label = %MessageLabel
@onready var _collections: PanelContainer = %CollectionsPanel
@onready var _inventory: PanelContainer = %InventoryPanel
@onready var _observation: PanelContainer = %ObservationPanel
@onready var _location_label: Label = %LocationLabel
@onready var _transition_label: Label = %TransitionLabel
@onready var _hud: PanelContainer = %HudPanel

const LocationScreenScene := preload("res://scenes/game/location_screen.tscn")

var _current_screen: LocationScreen
var _current_id: String = ""
var _fade_busy := false

func _ready() -> void:
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_corner_ui()
	_apply_location_badge()
	_apply_transition_label()
	GameState.message_requested.connect(_show_message)
	GameState.panhandle_changed.connect(_on_panhandle_changed)
	_hud.inventory_requested.connect(_on_inventory_pressed)
	_hud.collections_requested.connect(_on_collections_pressed)
	_inventory.closed.connect(_on_overlay_closed)
	_collections.closed.connect(_on_overlay_closed)
	_observation.action_confirmed.connect(_execute_hotspot)
	_go_to_screen("impound_lot", true)

func _process(delta: float) -> void:
	GameState.tick_xp(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		DoomMusic.unlock()
	elif event is InputEventScreenTouch and event.pressed:
		DoomMusic.unlock()

func _apply_corner_ui() -> void:
	var receipt := StyleBoxFlat.new()
	receipt.bg_color = Color(0, 0, 0, 0.62)
	receipt.set_corner_radius_all(1)
	receipt.set_content_margin_all(8)
	var overlay := receipt.duplicate()
	overlay.bg_color = Color(0, 0, 0, 0.68)
	_observation.add_theme_stylebox_override("panel", overlay)
	_collections.add_theme_stylebox_override("panel", overlay)
	_inventory.add_theme_stylebox_override("panel", overlay)
	DoomTypography.stamp_happening(_message_label, 12)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _apply_location_badge() -> void:
	var badge := StyleBoxFlat.new()
	badge.bg_color = Color(0, 0, 0, 0.55)
	badge.set_corner_radius_all(1)
	badge.set_content_margin_all(6)
	%LocationBadge.add_theme_stylebox_override("panel", badge)
	DoomTypography.stamp_game(_location_label, 12)
	_location_label.uppercase = true
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _apply_transition_label() -> void:
	_transition_label.visible = false
	_transition_label.modulate.a = 0.0
	_transition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DoomTypography.stamp_transition(_transition_label, 32)

func _on_inventory_pressed() -> void:
	_inventory.toggle()
	if _collections.visible:
		_collections.visible = false
	_hud.visible = not _inventory.visible

func _on_collections_pressed() -> void:
	_collections.toggle()
	if _inventory.visible:
		_inventory.visible = false
	_hud.visible = not _collections.visible

func _on_overlay_closed() -> void:
	if not _inventory.visible and not _collections.visible:
		_hud.visible = true

func _on_panhandle_changed() -> void:
	if _current_id == "alley" and _current_screen:
		_current_screen.setup("alley")

func _show_message(text: String) -> void:
	_message_label.text = text.strip_edges()
	_message_label.visible = true
	var tween := create_tween()
	tween.tween_interval(2.8)
	tween.tween_callback(func() -> void: _message_label.visible = false)

func _go_to_screen(screen_id: String, instant: bool = false) -> void:
	if _fade_busy and not instant:
		return
	_observation.hide_panel()
	_inventory.visible = false
	_collections.visible = false
	_hud.visible = true
	_fade_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	GameState.persist()

	var do_swap := func() -> void:
		if _current_id != "" and _current_id != screen_id:
			GameState.advance_time()
		_swap_screen(screen_id)
		var tween := create_tween()
		tween.tween_property(_fade, "color:a", 0.0, 0.35)
		tween.parallel().tween_property(_transition_label, "modulate:a", 0.0, 0.22)
		tween.finished.connect(func() -> void:
			_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fade_busy = false
			_transition_label.visible = false
		)

	if instant:
		_swap_screen(screen_id)
		_fade.color.a = 0.0
		_fade_busy = false
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_transition_label.visible = false
		return

	_transition_label.text = DoomTypography.header_for_screen(screen_id)
	_transition_label.visible = true
	_transition_label.modulate.a = 0.0
	var tween_in := create_tween()
	tween_in.tween_property(_fade, "color:a", 1.0, 0.35)
	tween_in.parallel().tween_property(_transition_label, "modulate:a", 1.0, 0.28).set_delay(0.1)
	tween_in.finished.connect(do_swap)

func _swap_screen(screen_id: String) -> void:
	if _current_screen:
		_current_screen.queue_free()
		_current_screen = null
	_current_id = screen_id
	GameState.mark_screen_visited(screen_id)
	_location_label.text = DoomTypography.header_for_screen(screen_id)
	var screen: LocationScreen = LocationScreenScene.instantiate()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.hotspot_pressed.connect(_on_hotspot)
	_screen_host.add_child(screen)
	screen.setup(screen_id)
	_current_screen = screen

func _on_hotspot(hotspot: Dictionary) -> void:
	DoomMusic.unlock()
	_observation.show_hotspot(hotspot)

func _execute_hotspot(hotspot: Dictionary) -> void:
	var action: String = hotspot.get("action", "")
	match action:
		"goto":
			_go_to_screen(hotspot.get("target", "alley"))
		"message":
			pass
		"buy":
			_try_buy(hotspot)
		"collect":
			_try_collect(hotspot)
		"pay_message":
			_try_pay_message(hotspot)
		"panhandle":
			if GameState.can_start_panhandle():
				GameState.start_panhandle()
				if _current_screen:
					_current_screen.setup("alley")
			else:
				_show_message(CopyData.lookup("panhandle/blocked", "NOT NOW."))
		"collect_panhandle":
			GameState.collect_panhandle()
			if _current_screen:
				_current_screen.setup("alley")
		_:
			_show_message(CopyData.lookup("affordance/nothing_happens", "—"))

func _try_buy(hotspot: Dictionary) -> void:
	var cost: int = int(hotspot.get("cost", 0))
	var cid: String = hotspot.get("collectible_id", "")
	var data := CollectibleData.lookup(cid)
	var name: String = data.get("name", hotspot.get("item", "Item"))
	if cid != "" and cid in GameState.discovered_collectibles and GameState.has_item(name):
		_show_message(CopyData.lookup("affordance/already_have", "ALREADY HAVE."))
		return
	if not GameState.can_afford(cost):
		_show_message(CopyData.lookup("affordance/no_money", "SHORT."))
		return
	GameState.spend(cost)
	if cid != "":
		GameState.add_collectible(cid)
	else:
		GameState.add_item(name)
	var label := DoomTypography.format_item_label(name)
	_show_message(CopyData.lookup("commerce/bought", "$%d.\n%s.") % [cost, label])

func _try_collect(hotspot: Dictionary) -> void:
	var flag: String = hotspot.get("flag", "")
	var cid: String = hotspot.get("collectible_id", "")
	var data := CollectibleData.lookup(cid)
	var name: String = data.get("name", hotspot.get("item", "Item"))
	if flag != "" and GameState.is_collected(flag):
		_show_message(CopyData.lookup("affordance/nothing_here", "NOTHING."))
		return
	if cid != "" and GameState.has_item(name):
		_show_message(CopyData.lookup("affordance/already_taken", "GONE."))
		return
	if cid != "":
		GameState.add_collectible(cid)
	else:
		GameState.add_item(name)
	if flag != "":
		GameState.mark_collected(flag)
	_show_message(CopyData.lookup("commerce/picked_up", "%s.") % DoomTypography.format_item_label(name))
	if _current_screen:
		_current_screen.setup(_current_id)

func _try_pay_message(hotspot: Dictionary) -> void:
	var cost: int = int(hotspot.get("cost", 0))
	if not GameState.can_afford(cost):
		_show_message(CopyData.lookup("affordance/no_money", "SHORT."))
		return
	GameState.spend(cost)
	_show_message(hotspot.get("text", ""))
