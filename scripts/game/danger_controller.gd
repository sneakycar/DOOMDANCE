extends Node
class_name DangerController

signal danger_triggered(message: String)

@export var min_walk_before_danger: float = 120.0
@export_range(0.0, 1.0) var danger_roll_chance: float = 0.012
@export var danger_cooldown: float = 45.0

var _walk_distance: float = 0.0
var _cooldown_left: float = 0.0
var _last_player_x: float = NAN
var _active: bool = false

@onready var _player: CharacterBody2D = %Player

func _ready() -> void:
	await get_tree().process_frame
	_last_player_x = _player.global_position.x

func _process(delta: float) -> void:
	if _active:
		return
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	var px := _player.global_position.x
	if not is_nan(_last_player_x):
		_walk_distance += absf(px - _last_player_x)
	_last_player_x = px
	if _walk_distance < min_walk_before_danger or _cooldown_left > 0.0:
		return
	if _player.velocity.length() < 4.0:
		return
	if randf() > danger_roll_chance:
		return
	_trigger_danger()

func _trigger_danger() -> void:
	_active = true
	_cooldown_left = danger_cooldown
	var messages := [
		"A dog chases you down the alley.",
		"Someone yells. You run.",
		"A car horn. You slip on wet brick.",
		"Trash cans clatter. You stumble.",
	]
	danger_triggered.emit(messages[randi() % messages.size()])

func finish_danger() -> void:
	_active = false
	_walk_distance = 0.0

func is_active() -> bool:
	return _active
