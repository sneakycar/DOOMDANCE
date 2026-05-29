extends Control

@onready var _screen_host: Control = %ScreenHost
@onready var _fade: ColorRect = %Fade
@onready var _transition_label: Label = %TransitionLabel
@onready var _hud_panel: PanelContainer = %HudPanel
@onready var _fragment: PanelContainer = %FragmentBar
@onready var _inventory_panel: Control = %InventoryPanel
@onready var _collections_panel: Control = %CollectionsPanel

const MazeShellScene := preload("res://scenes/game/maze_shell.tscn")

var _maze_shell: Control
var _fade_busy := false

func _ready() -> void:
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_transition_label()
	%MuteButton.visible = true
	_hud_panel.visible = true
	%LocationBadge.visible = false
	%ObservationPanel.visible = false
	%CollectionsPanel.visible = false
	%InventoryPanel.visible = false
	%MessageLabel.visible = false
	GameState.message_requested.connect(_show_fragment)
	GameState.player_died.connect(_on_player_died)
	_hud_panel.inventory_requested.connect(_toggle_inventory)
	_hud_panel.collections_requested.connect(_toggle_collections)
	_mount_maze()
	_play_opening_intro()

func _mount_maze() -> void:
	_maze_shell = MazeShellScene.instantiate()
	_maze_shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	_maze_shell.offset_top = 28.0
	_screen_host.add_child(_maze_shell)

func _play_opening_intro() -> void:
	_fade.color.a = 1.0
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_busy = true
	DoomMusic.unlock()
	_transition_label.text = "KENSINGTON"
	_transition_label.visible = true
	_transition_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(_transition_label, "modulate:a", 1.0, 1.4)
	tween.tween_interval(0.85)
	tween.tween_property(_transition_label, "modulate:a", 0.0, 0.7)
	tween.parallel().tween_property(_fade, "color:a", 0.0, 0.9)
	tween.finished.connect(func() -> void:
		_transition_label.visible = false
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_busy = false
		if MazeStore.current_id == "" or not MazeStore.has_page(MazeStore.current_id):
			MazeStore.reset_maze()
	)

func _process(delta: float) -> void:
	GameState.tick_xp(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		DoomMusic.unlock()
	elif event is InputEventScreenTouch and event.pressed:
		DoomMusic.unlock()

func _apply_transition_label() -> void:
	DoomTypography.stamp_transition(_transition_label, 42)
	_transition_label.visible = false
	_transition_label.modulate.a = 0.0
	_transition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_fragment(text: String, duration: float = 3.2) -> void:
	_fragment.show_fragment(text, duration)

func _on_player_died() -> void:
	MazeStore.reset_to_beginning()
	_show_fragment("you died. beginning again.", 5.0)

func _toggle_inventory() -> void:
	_inventory_panel.visible = not _inventory_panel.visible
	if _inventory_panel.visible:
		_collections_panel.visible = false

func _toggle_collections() -> void:
	_collections_panel.visible = not _collections_panel.visible
	if _collections_panel.visible:
		_inventory_panel.visible = false
