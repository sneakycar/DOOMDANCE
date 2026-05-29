extends Node2D
class_name AlleySegment

var segment_index: int = 0
var display_name: String = ""
var painted_art: Dictionary = {}

@onready var _backdrop: Sprite2D = $Backdrop
@onready var _sky: Sprite2D = $Layers/Sky
@onready var _buildings: Sprite2D = $Layers/Buildings
@onready var _walls: Node2D = $Layers/Walls
@onready var _sidewalks: Node2D = $Layers/Sidewalks
@onready var _street: ColorRect = $Layers/Street
@onready var _street_tiles: Node2D = $Layers/StreetTiles
@onready var _props: Node2D = $Props
@onready var _debug_label: Label = $DebugLabel

func setup(index: int, state: AlleyState, art: Dictionary = {}) -> void:
	segment_index = index
	painted_art = art
	display_name = str(art.get("label", SegmentLibrary.name_for_index(index)))
	position = Vector2(index * SegmentLibrary.SEGMENT_W, 0.0)
	if is_node_ready():
		_apply(state)
	else:
		set_meta("pending_state", state)

func get_props_root() -> Node2D:
	return _props

func contains_world_x(world_x: float) -> bool:
	var left := float(segment_index * SegmentLibrary.SEGMENT_W)
	return world_x >= left and world_x < left + SegmentLibrary.SEGMENT_W

func get_center_x() -> float:
	return float(segment_index * SegmentLibrary.SEGMENT_W) + SegmentLibrary.SEGMENT_W * 0.5

func _ready() -> void:
	if has_meta("pending_state"):
		_apply(get_meta("pending_state"))
		remove_meta("pending_state")

func _apply(state: AlleyState) -> void:
	_build_visuals()
	_debug_label.text = "#%d  %s" % [segment_index, display_name]
	_apply_mood(state)

func apply_mood(state: AlleyState) -> void:
	_apply_mood(state)

func _apply_mood(state: AlleyState) -> void:
	var modulate := state.get_scene_modulate()
	_backdrop.modulate = modulate
	_sky.modulate = modulate
	_buildings.modulate = modulate
	for c in _walls.get_children():
		c.modulate = modulate
	for c in _sidewalks.get_children():
		c.modulate = modulate
	for c in _street_tiles.get_children():
		c.modulate = modulate

func _build_visuals() -> void:
	match SegmentLibrary.BACKDROP_MODE:
		SegmentLibrary.BackdropMode.PAINTED:
			_build_painted()
		SegmentLibrary.BackdropMode.ABANDON_CITY:
			_build_abandon_city()
		_:
			_build_tiled_layers()

func _build_painted() -> void:
	_hide_tile_layers()
	_backdrop.visible = true
	var path := str(painted_art.get("path", ""))
	var tex := SegmentLibrary.load_texture(path)
	if tex == null:
		_backdrop.visible = false
		_build_tiled_layers()
		return
	_backdrop.texture = tex
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_backdrop.centered = false
	_backdrop.position = Vector2.ZERO

func _hide_tile_layers() -> void:
	_sky.visible = false
	_buildings.visible = false
	_clear_children(_walls)
	_clear_children(_sidewalks)
	_street.visible = false
	_clear_children(_street_tiles)

func _build_abandon_city() -> void:
	_hide_tile_layers()
	_backdrop.visible = true
	_backdrop.texture = SegmentLibrary.backdrop_for_index(segment_index)
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_backdrop.centered = false
	_backdrop.position = Vector2.ZERO

func _build_tiled_layers() -> void:
	_backdrop.visible = false
	_clear_children(_walls)
	_clear_children(_sidewalks)
	_clear_children(_street_tiles)
	_sky.visible = true
	_buildings.visible = true
	_street.visible = true
	_sky.texture = SegmentLibrary.SKY_TEX
	_sky.position = Vector2.ZERO
	_sky.centered = false
	_sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_buildings.texture = SegmentLibrary.BUILDINGS_TEX
	_buildings.position = Vector2(0.0, 56.0)
	_buildings.centered = false
	_buildings.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_street.size = Vector2(SegmentLibrary.SEGMENT_W, SegmentLibrary.SEGMENT_H - SegmentLibrary.SIDEWALK_TOP - 18.0)
	_street.position = Vector2(0.0, SegmentLibrary.SIDEWALK_TOP + 18.0)
	_street.color = Color(0.06, 0.07, 0.1, 1.0)
	var x := 0.0
	while x < SegmentLibrary.SEGMENT_W:
		var wall := Sprite2D.new()
		wall.texture = SegmentLibrary.WALL_TEX
		wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall.centered = false
		wall.position = Vector2(x, SegmentLibrary.WALL_TOP)
		_walls.add_child(wall)
		var walk := Sprite2D.new()
		walk.texture = SegmentLibrary.SIDEWALK_TEX
		walk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		walk.centered = false
		walk.position = Vector2(x, SegmentLibrary.SIDEWALK_TOP)
		_sidewalks.add_child(walk)
		var road := Sprite2D.new()
		road.texture = SegmentLibrary.STREET_TEX
		road.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		road.centered = false
		road.position = Vector2(x, SegmentLibrary.SIDEWALK_TOP + 18.0)
		_street_tiles.add_child(road)
		x += SegmentLibrary.TILE_W

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
