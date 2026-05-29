extends Button
## Minimal speaker toggle — arcs when audible, silent when muted.

const ICON_COLOR := Color(0.92, 0.9, 0.86, 0.55)
const ICON_HOVER := Color(0.95, 0.93, 0.88, 0.82)

var _audible := true

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(26, 18)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)
	pressed.connect(_on_pressed)
	DoomMusic.mute_changed.connect(_on_mute_changed)
	_refresh(DoomMusic.is_muted())

func _on_pressed() -> void:
	DoomMusic.toggle_mute()
	if not DoomMusic.is_muted():
		DoomMusic.unlock()

func _on_mute_changed(muted: bool) -> void:
	_refresh(muted)

func _refresh(muted: bool) -> void:
	_audible = not muted
	queue_redraw()

func _draw() -> void:
	var color := ICON_HOVER if is_hovered() else ICON_COLOR
	var ox := 2.0
	var oy := size.y * 0.5
	_draw_speaker(Vector2(ox, oy), color)
	if _audible:
		_draw_waves(Vector2(ox + 11.0, oy), color)

func _draw_speaker(origin: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		origin + Vector2(0, -3),
		origin + Vector2(4, -3),
		origin + Vector2(7, -5),
		origin + Vector2(7, 5),
		origin + Vector2(4, 3),
		origin + Vector2(0, 3),
	])
	draw_colored_polygon(body, color)
	draw_rect(Rect2(origin.x, origin.y - 4.5, 1.5, 9.0), color)

func _draw_waves(origin: Vector2, color: Color) -> void:
	_draw_arc(origin, 3.0, -PI * 0.35, PI * 0.35, color)
	_draw_arc(origin, 5.5, -PI * 0.32, PI * 0.32, color)

func _draw_arc(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color) -> void:
	var points := PackedVector2Array()
	var steps := 8
	for i in steps + 1:
		var t := float(i) / float(steps)
		var angle := lerpf(angle_from, angle_to, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	for i in steps:
		draw_line(points[i], points[i + 1], color, 1.2)
