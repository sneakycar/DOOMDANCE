extends CharacterBody2D
class_name Player

const INTERACT_RADIUS := 48.0
const GRAVITY := 980.0
## Feet at body origin; sprite extends upward (28×52, ~19% of frame height).
const SPRITE_HEIGHT := 52.0
const WALK_BOB := 1.0

# Meandering stroll (~14 px/s): ~34s to cross one screen.
const PIXELS_PER_STEP := 3
const STEP_INTERVAL := 0.21
const TAP_NUDGE_STEPS := 4
const MAX_QUEUED_STEPS := 24
const WALK_FRAME_COUNT := 4

@export var sprite_brightness := 1.12

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var _facing := 1
var _base_sprite_y := -SPRITE_HEIGHT
var _frozen := false
var _steps_left := 0
var _walk_direction := 0.0
var _step_timer := 0.0
var _walk_frame := 0
var _hold_direction := 0.0

func _ready() -> void:
	camera.make_current()
	sprite.modulate = Color(sprite_brightness, sprite_brightness, sprite_brightness * 1.04, 1.0)
	sprite.position.y = _base_sprite_y
	_show_idle()

func set_frozen(value: bool) -> void:
	_frozen = value
	if value:
		_stop_walk()

func set_hold_direction(direction: float) -> void:
	if _frozen:
		return
	_hold_direction = signf(direction)

func walk_burst(direction: float) -> void:
	if _frozen:
		return
	var dir := signf(direction)
	if dir == 0.0:
		return
	_walk_direction = dir
	_facing = int(dir)
	sprite.flip_h = _facing < 0
	var was_idle := _steps_left == 0 and _hold_direction == 0.0
	_steps_left = mini(_steps_left + TAP_NUDGE_STEPS, MAX_QUEUED_STEPS)
	if was_idle:
		_step_timer = STEP_INTERVAL
		_start_walk_anim()

func is_walking() -> bool:
	return (_steps_left > 0 or _hold_direction != 0.0) and not _frozen

func _stop_walk() -> void:
	_steps_left = 0
	_hold_direction = 0.0
	_step_timer = 0.0
	velocity = Vector2.ZERO
	_show_idle()

func _show_idle() -> void:
	sprite.play(&"idle")
	sprite.pause()
	sprite.frame = 0
	sprite.position.y = _base_sprite_y

func _start_walk_anim() -> void:
	sprite.play(&"walk")
	sprite.pause()

func _advance_walk_frame() -> void:
	_walk_frame = (_walk_frame + 1) % WALK_FRAME_COUNT
	sprite.frame = _walk_frame
	var bob := 0.0 if _walk_frame % 2 == 0 else -WALK_BOB
	sprite.position.y = _base_sprite_y + bob

func _physics_process(delta: float) -> void:
	if _frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		move_and_collide(Vector2(0.0, GRAVITY * delta))

	var strolling := _hold_direction != 0.0
	if strolling:
		_walk_direction = _hold_direction
		_facing = int(_hold_direction)
		sprite.flip_h = _facing < 0
		if _steps_left == 0:
			_start_walk_anim()

	if _steps_left > 0 or strolling:
		_step_timer += delta
		while _step_timer >= STEP_INTERVAL and (_steps_left > 0 or strolling):
			_step_timer -= STEP_INTERVAL
			_take_step(strolling)
	else:
		_show_idle()

	_snap_to_pixel_grid()

func _take_step(from_hold: bool) -> void:
	if not from_hold:
		_steps_left -= 1
	_advance_walk_frame()
	move_and_collide(Vector2(_walk_direction * PIXELS_PER_STEP, 0.0))
	if not from_hold and _steps_left <= 0 and _hold_direction == 0.0:
		_show_idle()

func _snap_to_pixel_grid() -> void:
	global_position = global_position.round()

func get_nearest_pickup() -> Node:
	return _nearest_in_group("pickup")

func get_nearest_npc() -> Node:
	return _nearest_in_group("npc")

func _nearest_in_group(group: String) -> Node:
	var nearest: Node = null
	var nearest_dist := INTERACT_RADIUS
	for node in get_tree().get_nodes_in_group(group):
		if not node is Node2D:
			continue
		var dist := global_position.distance_to((node as Node2D).global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node
	return nearest
