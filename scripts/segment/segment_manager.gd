extends Node2D
class_name SegmentManager

signal segment_changed(name: String)

const SEGMENT_SCENE := preload("res://scenes/segment/alley_segment.tscn")
const SEGMENT_COUNT := 7
const START_INDEX := 3

@export var alley_state: AlleyState

var _segments: Array[AlleySegment] = []
var _min_index := 0
var _max_index := 0
var _player_index := START_INDEX
var _rng := RandomNumberGenerator.new()
var _current_name := ""
var _clock: GameClock
var _painted_deck := PaintedSegmentDeck.new()

@onready var _ground: StaticBody2D = $Ground
@onready var _ground_shape: CollisionShape2D = $Ground/CollisionShape2D

func _ready() -> void:
	if alley_state == null:
		alley_state = AlleyState.new()
	_rng.randomize()
	_clock = get_tree().get_first_node_in_group("game_clock") as GameClock
	_reload_painted_deck()
	call_deferred("_bootstrap")

func _process(_delta: float) -> void:
	_check_scroll()

func _reload_painted_deck() -> void:
	if SegmentLibrary.BACKDROP_MODE != SegmentLibrary.BackdropMode.PAINTED:
		return
	var phase := _clock.phase if _clock else GameClock.Phase.NIGHT
	var dir := SegmentLibrary.painted_dir_for_phase(phase)
	var n := _painted_deck.load_folder(dir)
	if n == 0:
		push_warning("SegmentManager: no painted segments in %s — drop PNGs in assets/segments/painted/incoming/ and run tools/import_painted_segments.sh" % dir)
	else:
		print("PaintedSegmentDeck: %d slices loaded from %s" % [n, dir])

func _bootstrap() -> void:
	_min_index = 0
	_max_index = SEGMENT_COUNT - 1
	for i in range(SEGMENT_COUNT):
		_spawn_segment(i)
	var player := _player()
	player.global_position = Vector2(
		START_INDEX * SegmentLibrary.SEGMENT_W + SegmentLibrary.SEGMENT_W * 0.5,
		SegmentLibrary.FLOOR_Y
	)
	_player_index = START_INDEX
	_update_ground()
	_emit_current(player.global_position.x)

func refresh_moods() -> void:
	for seg in _segments:
		seg.apply_mood(alley_state)

func set_phase(_phase: int) -> void:
	_reload_painted_deck()
	refresh_moods()

func _check_scroll() -> void:
	var px := _player().global_position.x
	var idx := int(floor(px / float(SegmentLibrary.SEGMENT_W)))
	if idx == _player_index:
		return
	if idx > _player_index:
		_shift_right()
	else:
		_shift_left()
	_player_index = idx
	_update_ground()
	_emit_current(px)

func _shift_right() -> void:
	_remove_segment_index(_min_index)
	_min_index += 1
	_max_index += 1
	_spawn_segment(_max_index)

func _shift_left() -> void:
	_remove_segment_index(_max_index)
	_max_index -= 1
	_min_index -= 1
	_spawn_segment(_min_index)

func _spawn_segment(index: int) -> void:
	var seg: AlleySegment = SEGMENT_SCENE.instantiate()
	add_child(seg)
	_segments.append(seg)
	var art := _pick_painted_art()
	seg.setup(index, alley_state, art)
	var phase := _clock.phase if _clock else GameClock.Phase.NIGHT
	PropSpawner.populate_segment(seg, _rng, alley_state, phase)
	_sort_segments()

func _pick_painted_art() -> Dictionary:
	if SegmentLibrary.BACKDROP_MODE == SegmentLibrary.BackdropMode.PAINTED and _painted_deck.has_art():
		return _painted_deck.pick()
	return {}

func _remove_segment_index(index: int) -> void:
	for i in _segments.size():
		if _segments[i].segment_index == index:
			_segments[i].queue_free()
			_segments.remove_at(i)
			return

func _sort_segments() -> void:
	_segments.sort_custom(func(a: AlleySegment, b: AlleySegment) -> bool:
		return a.segment_index < b.segment_index
	)

func _update_ground() -> void:
	var left := float(_min_index * SegmentLibrary.SEGMENT_W)
	var right := float((_max_index + 1) * SegmentLibrary.SEGMENT_W)
	var shape := _ground_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		_ground_shape.shape = shape
	shape.size = Vector2(right - left, 20.0)
	_ground.position = Vector2((left + right) * 0.5, SegmentLibrary.FLOOR_Y)
	_ground_shape.position = Vector2.ZERO

func _emit_current(player_x: float) -> void:
	var name := "—"
	for seg in _segments:
		if seg.contains_world_x(player_x):
			name = seg.display_name
			break
	if name != _current_name:
		_current_name = name
		segment_changed.emit(name)

func get_segment_count() -> int:
	return _segments.size()

func get_current_segment_name() -> String:
	return _current_name

func get_alley_state() -> AlleyState:
	return alley_state

func get_segment_center_x_at(world_x: float) -> float:
	for seg in _segments:
		if seg.contains_world_x(world_x):
			return seg.get_center_x()
	return world_x

func _player() -> CharacterBody2D:
	return %Player
