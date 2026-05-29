extends Node2D
class_name CorridorDrift

signal segment_entered(segment_type: StringName, label: String)

const SEGMENT_SCENE := preload("res://scenes/corridor/corridor_segment.tscn")

@export var segments_ahead := 3
@export var segments_behind := 2
@export var context: CorridorContext

var _segments: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _last_type: StringName = CorridorLibrary.TYPE_BRICK
var _last_player_index: int = 0

func _ready() -> void:
	if context == null:
		context = CorridorContext.new()
	_rng.randomize()
	await get_tree().process_frame
	var player := _get_player()
	var start_index := _index_for_x(player.global_position.x)
	for i in range(start_index - segments_behind, start_index + segments_ahead + 1):
		_spawn(i)

func _get_player() -> CharacterBody2D:
	return %Player

func _process(_delta: float) -> void:
	_maintain_corridor()

func _maintain_corridor() -> void:
	var player_index := _index_for_x(_get_player().global_position.x)
	if player_index != _last_player_index:
		_last_player_index = player_index
		if _segments.has(player_index):
			var seg: CorridorSegment = _segments[player_index]
			segment_entered.emit(seg.segment_type, CorridorLibrary.label_for(seg.segment_type))

	var min_index := player_index - segments_behind
	var max_index := player_index + segments_ahead

	for i in range(min_index, max_index + 1):
		if not _segments.has(i):
			_spawn(i)

	var stale: Array[int] = []
	for key in _segments.keys():
		if key < min_index or key > max_index:
			stale.append(key)
	for key in stale:
		_despawn(key)

func _index_for_x(world_x: float) -> int:
	return int(floor(world_x / CorridorLibrary.SEGMENT_WIDTH))

func _spawn(index: int) -> void:
	if _segments.has(index):
		return
	var segment_type := CorridorLibrary.pick_type(context, _last_type, _rng)
	_last_type = segment_type
	var seg: CorridorSegment = SEGMENT_SCENE.instantiate()
	seg.name = "Seg_%d" % index
	add_child(seg)
	seg.configure(index, segment_type, context)
	_segments[index] = seg
	if index == _last_player_index:
		segment_entered.emit(segment_type, CorridorLibrary.label_for(segment_type))

func _despawn(index: int) -> void:
	if not _segments.has(index):
		return
	var seg: CorridorSegment = _segments[index]
	_segments.erase(index)
	seg.queue_free()

func get_active_segment_count() -> int:
	return _segments.size()

func get_player_block_index() -> int:
	return _index_for_x(_get_player().global_position.x)
