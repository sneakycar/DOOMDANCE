extends Control
## Soft neon tube glow — gentle buzz on colored additive spots.

@export var buzz_seed: float = 0.0
@export var base_color: Color = Color(0.95, 0.2, 0.45, 1.0)

var _intensity := 0.92
var _hum := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	set_process(true)
	_gentle_step()

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	_hum = sin(t * 8.5 + buzz_seed * 4.1) * 0.016 + sin(t * 21.0 + buzz_seed * 1.9) * 0.008
	queue_redraw()

func _set_intensity(value: float) -> void:
	_intensity = value
	queue_redraw()

func _gentle_step() -> void:
	if not is_inside_tree():
		return
	var roll := randf()
	var tween := create_tween()
	if roll < 0.14:
		tween.tween_method(_set_intensity, _intensity, 0.76 + randf() * 0.08, 0.035 + randf() * 0.025)
		tween.tween_method(_set_intensity, _intensity, 0.9 + randf() * 0.08, 0.07 + randf() * 0.05)
	elif roll < 0.3:
		for _i in 2:
			tween.tween_method(_set_intensity, _intensity, 0.84 + randf() * 0.05, 0.018)
			tween.tween_method(_set_intensity, _intensity, 0.93 + randf() * 0.05, 0.022)
	else:
		tween.tween_method(_set_intensity, _intensity, 0.86 + randf() * 0.08, 0.14 + randf() * 0.18)
		tween.tween_method(_set_intensity, _intensity, 0.92 + randf() * 0.06, 0.1 + randf() * 0.08)
	tween.tween_interval(0.4 + randf() * 0.9 + buzz_seed * 0.15)
	tween.finished.connect(_gentle_step)

func _draw() -> void:
	var tex: ImageTexture = LampFlicker.glow_texture()
	var strength := clampf(_intensity + _hum, 0.0, 1.1)
	var hot := base_color
	hot.r = clampf(hot.r + _hum * 1.8, 0.0, 1.0)
	hot.g = clampf(hot.g + _hum * 1.2, 0.0, 1.0)
	hot.b = clampf(hot.b + _hum * 2.2, 0.0, 1.0)
	var center := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var tint := Color(hot.r, hot.g, hot.b, clampf(strength * 0.72, 0.0, 1.0))
	var diameter := r * 2.15
	draw_texture_rect(
		tex,
		Rect2(center - Vector2(diameter, diameter) * 0.5, Vector2(diameter, diameter)),
		false,
		tint
	)
