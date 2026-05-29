extends Control
## Soft sodium glow — radial falloff, buzz, brownout. No hard edges.

enum Kind { STREET, BULB, WINDOW }

const GLOW_TEX_SIZE := 128

static var _glow_tex: ImageTexture

@export var buzz_seed: float = 0.0
@export var glow_kind: Kind = Kind.STREET
@export var base_color: Color = Color(1.0, 0.74, 0.38, 1.0)

var _intensity := 0.72
var _hum := 0.0

static func glow_texture() -> ImageTexture:
	if _glow_tex != null:
		return _glow_tex
	var img := Image.create(GLOW_TEX_SIZE, GLOW_TEX_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(GLOW_TEX_SIZE * 0.5, GLOW_TEX_SIZE * 0.5)
	var max_r := GLOW_TEX_SIZE * 0.5
	for y in GLOW_TEX_SIZE:
		for x in GLOW_TEX_SIZE:
			var d := Vector2(x, y).distance_to(center) / max_r
			if d > 1.0:
				continue
			var a := pow(1.0 - d, 2.6) * 0.62
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_glow_tex = ImageTexture.create_from_image(img)
	return _glow_tex

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	blend_mode = CanvasItem.BLEND_MODE_ADD
	set_process(true)
	_buzz_step()

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	_hum = sin(t * 17.0 + buzz_seed * 6.3) * 0.012 + sin(t * 43.0 + buzz_seed * 2.1) * 0.006
	queue_redraw()

func _set_intensity(value: float) -> void:
	_intensity = value
	queue_redraw()

func _buzz_step() -> void:
	if not is_inside_tree():
		return
	var roll := randf()
	var tween := create_tween()
	if roll < 0.2:
		tween.tween_method(_set_intensity, _intensity, 0.01, 0.035 + randf() * 0.025)
		tween.tween_method(_set_intensity, 0.01, 0.48 + randf() * 0.22, 0.1 + buzz_seed * 0.04)
	elif roll < 0.46:
		for _i in 3:
			tween.tween_method(_set_intensity, _intensity, 0.22 + randf() * 0.35, 0.014)
			tween.tween_method(_set_intensity, _intensity, 0.62 + randf() * 0.28, 0.018)
	else:
		tween.tween_method(_set_intensity, _intensity, 0.45 + randf() * 0.18, 0.05 + randf() * 0.04)
		tween.tween_method(_set_intensity, _intensity, 0.68 + randf() * 0.18, 0.05)
	tween.tween_interval(0.12 + randf() * 0.45 + buzz_seed * 0.12)
	tween.finished.connect(_buzz_step)

func _draw() -> void:
	var tex := glow_texture()
	var strength := clampf(_intensity + _hum, 0.0, 1.15)
	var hot := base_color
	hot.r = clampf(hot.r + _hum * 2.0, 0.82, 1.0)
	var center := size * 0.5
	var r := minf(size.x, size.y) * 0.5

	match glow_kind:
		Kind.STREET:
			_blit_glow(tex, center, r * 2.1, hot, strength * 0.85)
			_draw_spill(center, r, hot, strength * 0.38)
		Kind.BULB:
			_blit_glow(tex, center, r * 1.65, hot, strength)
		Kind.WINDOW:
			var warm := Color(1.0, 0.8, 0.48, 1.0)
			_blit_glow(tex, center, r * 1.5, warm, strength * 0.55)

func _blit_glow(tex: Texture2D, center: Vector2, diameter: float, color: Color, strength: float) -> void:
	var tint := Color(color.r, color.g, color.b, clampf(strength, 0.0, 1.0))
	var rect := Rect2(center - Vector2(diameter, diameter) * 0.5, Vector2(diameter, diameter))
	draw_texture_rect(tex, rect, false, tint)

func _draw_spill(origin: Vector2, radius: float, color: Color, strength: float) -> void:
	for i in 5:
		var t := float(i) / 5.0
		var dy := radius * (0.55 + t * 1.35)
		var spread := radius * (0.28 + t * 0.55)
		var a := strength * (1.0 - t) * 0.055
		_draw_soft_ellipse(origin + Vector2(0, dy), Vector2(spread, spread * 0.28), Color(color.r, color.g, color.b, a))

func _draw_soft_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var steps := 14
	for ring in steps:
		var t := float(ring) / float(steps)
		var rx := radii.x * (1.0 - t * 0.85)
		var ry := radii.y * (1.0 - t * 0.85)
		var a := color.a * (1.0 - t) * (1.0 - t)
		if a < 0.002:
			continue
		var points := PackedVector2Array()
		for i in 17:
			var ang := TAU * float(i) / 16.0
			points.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
		draw_colored_polygon(points, Color(color.r, color.g, color.b, a))
