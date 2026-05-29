extends Node2D

## Full-screen grayscale pass (no per-sprite edits). Do not use CanvasGroup — it breaks the camera.
@export var grayscale_world := false
## Gray-tint HUD text (not true desaturation; leave off for yellow labels).
@export var grayscale_ui := false

@onready var player: Player = %Player
@onready var segments: SegmentManager = $SegmentManager
@onready var _grayscale_post: CanvasLayer = $GrayscalePost
@onready var clock: GameClock = $GameClock
@onready var touch: Control = $UI/TouchControls
@onready var phase_label: Label = $UI/HUD/PhaseLabel
@onready var segment_label: Label = $UI/HUD/SegmentLabel
@onready var log_label: Label = $UI/HUD/LogLabel
@onready var bag_label: Label = $UI/HUD/BagLabel
@onready var dialogue: PanelContainer = $UI/Dialogue
@onready var dialogue_text: Label = $UI/Dialogue/DialogueText

var _bag: Array[String] = []
var _state_hash := -1
var _touch_hold_dir := 0.0

func _ready() -> void:
	_apply_grayscale()
	_fit_window()
	AlleyData.load_all()
	clock.alley_state = segments.alley_state
	touch.walk_hold_changed.connect(_on_walk_hold_changed)
	touch.interact_pressed.connect(_on_interact)
	clock.phase_changed.connect(_on_phase_changed)
	segments.segment_changed.connect(_on_segment_changed)
	_log("Hold left or right to stroll · Hand to interact")
	_refresh_hud()

func _fit_window() -> void:
	if OS.has_feature("mobile"):
		return
	get_window().size = Vector2i(1920, 1080)

func _process(_delta: float) -> void:
	var state := segments.get_alley_state()
	if state != null and state.get_state_hash() != _state_hash:
		_state_hash = state.get_state_hash()
		segments.refresh_moods()
	_apply_stroll_input()
	_refresh_hud()

func _apply_stroll_input() -> void:
	var dir := _touch_hold_dir
	if dir == 0.0:
		if Input.is_action_pressed("move_left"):
			dir = -1.0
		elif Input.is_action_pressed("move_right"):
			dir = 1.0
	player.set_hold_direction(dir)

func _on_walk_hold_changed(direction: float) -> void:
	_touch_hold_dir = direction

func _apply_grayscale() -> void:
	_grayscale_post.visible = grayscale_world
	$UI/HUD.modulate = Color(1, 1, 1, 1) if not grayscale_ui else Color(0.82, 0.82, 0.82, 1)

func set_grayscale(enabled: bool, include_ui: bool = false) -> void:
	grayscale_world = enabled
	grayscale_ui = include_ui
	_apply_grayscale()

func _on_interact() -> void:
	var npc := player.get_nearest_npc()
	if npc != null and npc.has_method("get_line"):
		_show_dialogue(npc.get_line(AlleyData.phase_key(clock.phase)))
		return
	var pickup := player.get_nearest_pickup()
	if pickup != null and pickup.has_method("try_pickup"):
		var label: String = pickup.def.get("label", "Item") if pickup.get("def") else "Item"
		pickup.collected.connect(func(item_name: String): _on_collected(item_name), CONNECT_ONE_SHOT)
		pickup.try_pickup()
		return
	_log("Nothing nearby.")

func _on_collected(item_name: String) -> void:
	if item_name not in _bag:
		_bag.append(item_name)
	_log("Picked up %s." % item_name)
	_refresh_hud()

func _on_phase_changed(phase: int, phase_name: String) -> void:
	segments.set_phase(phase)
	_log("It is now %s. New spawns ahead." % phase_name)
	_refresh_hud()

func _on_segment_changed(name: String) -> void:
	segment_label.text = name

func _show_dialogue(text: String) -> void:
	dialogue.visible = true
	dialogue_text.text = text
	await get_tree().create_timer(2.8).timeout
	dialogue.visible = false

func _log(message: String) -> void:
	log_label.text = message

func _refresh_hud() -> void:
	var state := segments.get_alley_state()
	phase_label.text = "%s (%.0f%%) | luck %.2f" % [
		clock.phase_name(),
		clock.phase_progress() * 100.0,
		state.luck if state else 0.5,
	]
	if _bag.is_empty():
		bag_label.text = "Bag: empty"
	else:
		bag_label.text = "Bag: " + ", ".join(_bag)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_on_interact()
	if event.is_action_pressed("time_skip"):
		clock.advance_phase()
