extends Control

signal walk_hold_changed(direction: float)
signal interact_pressed

@onready var _walk_tap: Control = $WalkTap
@onready var _interact: Button = $InteractButton

var _hold_side := 0

func _ready() -> void:
	_walk_tap.gui_input.connect(_on_walk_tap)
	_interact.pressed.connect(func(): interact_pressed.emit())

func _on_walk_tap(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_hold(event.position)
		else:
			_end_hold()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_hold(event.position)
		else:
			_end_hold()

func _begin_hold(screen_pos: Vector2) -> void:
	var half := _walk_tap.size.x * 0.5
	if half < 1.0:
		half = get_viewport().get_visible_rect().size.x * 0.5
	_hold_side = -1 if screen_pos.x < half else 1
	walk_hold_changed.emit(float(_hold_side))

func _end_hold() -> void:
	if _hold_side == 0:
		return
	_hold_side = 0
	walk_hold_changed.emit(0.0)
