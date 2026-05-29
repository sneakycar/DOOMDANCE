extends Node2D
class_name CorridorSegment

const WIDTH := CorridorLibrary.SEGMENT_WIDTH
const FLOOR_Y := CorridorLibrary.SEGMENT_FLOOR_Y

var segment_index: int = 0
var segment_type: StringName = CorridorLibrary.TYPE_BRICK

var _ctx: CorridorContext

@onready var _visuals: Node2D = $Visuals
@onready var _floor: StaticBody2D = $Floor
@onready var _floor_shape: CollisionShape2D = $Floor/CollisionShape2D

func configure(index: int, type: StringName, ctx: CorridorContext) -> void:
	segment_index = index
	segment_type = type
	_ctx = ctx
	position.x = float(index) * WIDTH
	if is_node_ready():
		_apply()

func _ready() -> void:
	if _ctx == null:
		_ctx = CorridorContext.new()
	_apply()

func _apply() -> void:
	_build_floor()
	_build_visuals(_ctx)

func _build_floor() -> void:
	var shape := _floor_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		_floor_shape.shape = shape
	shape.size = Vector2(WIDTH, 15.0)
	_floor.position = Vector2(WIDTH * 0.5, FLOOR_Y)

func _build_visuals(ctx: CorridorContext) -> void:
	for child in _visuals.get_children():
		child.queue_free()
	_add_sky(ctx)
	_add_ground(ctx)
	match segment_type:
		CorridorLibrary.TYPE_DUMPSTER:
			_build_dumpster(ctx)
		CorridorLibrary.TYPE_FENCE:
			_build_fence(ctx)
		CorridorLibrary.TYPE_DOCK:
			_build_dock(ctx)
		CorridorLibrary.TYPE_GARAGE:
			_build_garage(ctx)
		CorridorLibrary.TYPE_BOARDED:
			_build_boarded(ctx)
		CorridorLibrary.TYPE_VACANT:
			_build_vacant(ctx)
		CorridorLibrary.TYPE_GRAFFITI:
			_build_graffiti(ctx)
		CorridorLibrary.TYPE_SEPTA:
			_build_septa(ctx)
		_:
			_build_brick(ctx)

func _rect(x: float, y: float, w: float, h: float, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visuals.add_child(r)
	return r

func _poly(points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	_visuals.add_child(p)
	return p

func _add_sky(ctx: CorridorContext) -> void:
	_rect(0, 0, WIDTH, 118, ctx.get_sky_bottom())
	_rect(0, 0, WIDTH, 52, ctx.get_sky_top())

func _add_ground(ctx: CorridorContext) -> void:
	_rect(0, 138, WIDTH, 132, ctx.get_ground_color())
	_rect(0, 196, WIDTH, 8, ctx.get_ground_highlight())

func _add_brick_wall(x: float, w: float, h: float, ctx: CorridorContext) -> void:
	_rect(x, 72, w, 126, ctx.get_wall_brick())
	_rect(x + 2, 74, w - 4, 4, ctx.get_wall_dark())
	_rect(x + 2, 90, w - 4, 3, ctx.get_wall_dark())
	_rect(x + 2, 108, w - 4, 3, ctx.get_wall_dark())

func _add_lamp(x: float, ctx: CorridorContext) -> void:
	_rect(x, 88, 3, 28, ctx.get_wall_dark())
	_rect(x - 4, 86, 11, 10, ctx.get_sodium())
	var spill := ctx.get_sodium()
	spill.a = 0.12
	_rect(x - 2, 108, 18, 40, spill)

func _build_brick(_ctx: CorridorContext) -> void:
	_add_brick_wall(0, 34, 126, _ctx)
	_add_brick_wall(WIDTH - 34, 34, 126, _ctx)
	_poly(PackedVector2Array([34, 198, WIDTH - 34, 198, WIDTH - 48, 138, 48, 138]), _ctx.get_wall_dark())

func _build_dumpster(ctx: CorridorContext) -> void:
	_add_brick_wall(0, 40, 126, ctx)
	_poly(PackedVector2Array([52, 198, 108, 198, 112, 168, 48, 168]), Color(0.14, 0.16, 0.14, 1))
	_rect(46, 160, 68, 8, Color(0.1, 0.11, 0.1, 1))
	_add_lamp(18, ctx)

func _build_fence(ctx: CorridorContext) -> void:
	_add_brick_wall(0, 28, 126, ctx)
	for i in 6:
		var x := 98 + i * 8
		_rect(x, 100, 2, 98, Color(0.42, 0.44, 0.48, 1))
	_rect(94, 100, 58, 4, Color(0.42, 0.44, 0.48, 1))
	_rect(94, 130, 58, 4, Color(0.42, 0.44, 0.48, 1))
	_rect(94, 160, 58, 4, Color(0.42, 0.44, 0.48, 1))
	_add_lamp(12, ctx)

func _build_dock(ctx: CorridorContext) -> void:
	_add_brick_wall(0, 30, 126, ctx)
	_poly(PackedVector2Array([70, 198, WIDTH - 8, 198, WIDTH - 8, 152, 70, 152]), Color(0.2, 0.2, 0.24, 1))
	_rect(72, 146, WIDTH - 82, 6, Color(0.72, 0.62, 0.2, 1))
	_rect(78, 158, 24, 40, Color(0.16, 0.17, 0.2, 1))

func _build_garage(ctx: CorridorContext) -> void:
	_add_brick_wall(0, 32, 126, ctx)
	_rect(36, 108, 108, 90, Color(0.1, 0.1, 0.12, 1))
	_rect(40, 112, 100, 4, Color(0.18, 0.18, 0.22, 1))
	_rect(48, 88, 72, 14, ctx.get_sodium())
	_rect(52, 91, 64, 8, Color(0.08, 0.08, 0.1, 1))

func _build_boarded(ctx: CorridorContext) -> void:
	_add_brick_wall(0, 36, 126, ctx)
	_rect(44, 96, 72, 72, Color(0.14, 0.13, 0.18, 1))
	for row in 3:
		for col in 2:
			var wx := 48 + col * 34
			var wy := 102 + row * 22
			_rect(wx, wy, 28, 16, Color(0.22, 0.2, 0.26, 1))
			_rect(wx, wy + 1, 28, 2, Color(0.32, 0.24, 0.18, 1))
			_rect(wx, wy + 13, 28, 2, Color(0.32, 0.24, 0.18, 1))
	_add_lamp(14, ctx)

func _build_vacant(ctx: CorridorContext) -> void:
	_rect(0, 118, WIDTH, 12, ctx.get_wall_dark())
	for i in 8:
		_rect(20 + i * 16, 178, 2, 2, Color(0.22, 0.28, 0.18, 1))
	_poly(PackedVector2Array([0, 198, WIDTH, 198, WIDTH, 168, 0, 162]), ctx.get_ground_color().darkened(0.08))
	_add_lamp(WIDTH - 22, ctx)

func _build_graffiti(ctx: CorridorContext) -> void:
	_add_brick_wall(WIDTH - 38, 38, 126, ctx)
	_rect(0, 82, 46, 116, ctx.get_wall_brick())
	_rect(6, 100, 28, 20, Color(0.62, 0.22, 0.42, 1))
	_rect(8, 128, 24, 14, Color(0.22, 0.48, 0.58, 1))
	_rect(10, 152, 20, 18, Color(0.78, 0.68, 0.18, 1))
	_add_lamp(58, ctx)

func _build_septa(ctx: CorridorContext) -> void:
	_rect(0, 0, WIDTH, 92, Color(0.05, 0.05, 0.08, 1))
	_rect(-8, 68, WIDTH + 16, 28, Color(0.08, 0.08, 0.1, 1))
	_rect(24, 72, 12, 126, Color(0.1, 0.1, 0.12, 1))
	_rect(WIDTH - 36, 72, 12, 126, Color(0.1, 0.1, 0.12, 1))
	for i in 4:
		_rect(40 + i * 28, 24, 2, 2, ctx.get_teal_glow())
	_build_brick(ctx)
