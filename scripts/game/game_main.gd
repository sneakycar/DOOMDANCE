extends Control

@onready var _screen_host: Control = %ScreenHost
@onready var _fade: ColorRect = %Fade
@onready var _message_label: Label = %MessageLabel
@onready var _collections: PanelContainer = %CollectionsPanel

const LocationScreenScene := preload("res://scenes/game/location_screen.tscn")

var _current_screen: LocationScreen
var _current_id: String = ""
var _fade_busy := false

func _ready() -> void:
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_hud_typography()
	GameState.money_changed.connect(_on_hud_refresh)
	GameState.time_changed.connect(_on_hud_refresh)
	GameState.inventory_changed.connect(_on_hud_refresh)
	GameState.message_requested.connect(_show_message)
	GameState.panhandle_changed.connect(_on_panhandle_changed)
	%CollectionsButton.pressed.connect(func() -> void: _collections.toggle())
	_on_hud_refresh()
	_go_to_screen("impound_lot", instant: true)

func _apply_hud_typography() -> void:
	DoomTypography.stamp_mono(%TimeLabel, 13)
	DoomTypography.stamp_mono(%MoneyLabel, 14)
	DoomTypography.stamp_mono(%InventoryLabel, 11)
	DoomTypography.stamp_observation(%MessageLabel, 13)
	DoomTypography.stamp_mono(%TapHintLabel, 12)
	%InventoryLabel.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	%CollectionsButton.add_theme_font_override("font", DoomTypography.mono)
	%CollectionsButton.add_theme_font_size_override("font_size", 12)

func _on_hud_refresh(_value = null) -> void:
	%MoneyLabel.text = GameState.money_display()
	%TimeLabel.text = GameState.time_display()
	%InventoryLabel.text = GameState.inventory_display()

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
	_fade_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var do_swap := func() -> void:
		if _current_id != "" and _current_id != screen_id:
			GameState.advance_time()
		_swap_screen(screen_id)
		var tween := create_tween()
		tween.tween_property(_fade, "color:a", 0.0, 0.35)
		tween.finished.connect(func() -> void:
			_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fade_busy = false
		)

	if instant:
		_swap_screen(screen_id)
		_fade.color.a = 0.0
		_fade_busy = false
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	var tween_in := create_tween()
	tween_in.tween_property(_fade, "color:a", 1.0, 0.35)
	tween_in.finished.connect(do_swap)

func _swap_screen(screen_id: String) -> void:
	if _current_screen:
		_current_screen.queue_free()
		_current_screen = null
	_current_id = screen_id
	GameState.mark_screen_visited(screen_id)
	var screen: LocationScreen = LocationScreenScene.instantiate()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.hotspot_pressed.connect(_on_hotspot)
	screen.tap_hint_changed.connect(_on_tap_hint)
	_screen_host.add_child(screen)
	screen.setup(screen_id)
	_current_screen = screen

func _on_tap_hint(text: String) -> void:
	if MobileUI.is_touch_device and text.is_empty():
		return
	%TapHintLabel.text = text
	%TapHintLabel.visible = not text.is_empty()

func _on_hotspot(hotspot: Dictionary) -> void:
	if MobileUI.is_touch_device:
		var hint := hotspot.get("label", "")
		if not hint.is_empty():
			_on_tap_hint(hint)
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				if is_instance_valid(self):
					%TapHintLabel.visible = false
			)
	var action: String = hotspot.get("action", "")
	match action:
		"goto":
			_go_to_screen(hotspot.get("target", "alley"))
		"message":
			_show_message(hotspot.get("text", ""))
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
