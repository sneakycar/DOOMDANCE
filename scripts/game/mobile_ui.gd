extends Node
## Touch / mobile web layout helpers (autoload).

const MIN_TAP_PX := 52.0
const MIN_TAP_RATIO := 0.11

static var is_touch_device := false

func _ready() -> void:
	is_touch_device = _detect_touch()

func _detect_touch() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		return true
	if OS.has_feature("mobile"):
		return true
	return false

static func min_hotspot_size(view_size: Vector2) -> Vector2:
	var by_ratio := Vector2(
		view_size.x * MIN_TAP_RATIO,
		view_size.y * MIN_TAP_RATIO
	)
	return Vector2(
		maxf(MIN_TAP_PX, by_ratio.x),
		maxf(MIN_TAP_PX, by_ratio.y)
	)

static func expand_rect_to_min_tap(rect: Rect2, view_size: Vector2) -> Rect2:
	var min_size := min_hotspot_size(view_size)
	var out := rect
	if out.size.x < min_size.x:
		var dx := (min_size.x - out.size.x) * 0.5
		out.position.x -= dx
		out.size.x = min_size.x
	if out.size.y < min_size.y:
		var dy := (min_size.y - out.size.y) * 0.5
		out.position.y -= dy
		out.size.y = min_size.y
	out.position.x = clampf(out.position.x, 0.0, maxf(0.0, view_size.x - out.size.x))
	out.position.y = clampf(out.position.y, 0.0, maxf(0.0, view_size.y - out.size.y))
	return out
