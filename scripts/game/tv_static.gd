extends Control
class_name TvStatic
## Live CRT snow — shader noise + scanlines over the baked screen area.

const SHADER_CODE := """
shader_type canvas_item;
uniform float time;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	float t = time;
	float n = hash(uv * vec2(920.0, 540.0) + vec2(t * 19.0, floor(t * 11.0)));
	n = mix(n, hash(uv * 1300.0 - t * 15.0), 0.42);
	float scan = 0.84 + 0.16 * sin(uv.y * 680.0 + t * 31.0);
	float pop = step(0.988, hash(vec2(uv.y * 5.0, floor(t * 4.0))));
	n = mix(n, 1.0, pop * 0.4);
	float lines = mix(0.88, 1.0, step(0.5, fract(uv.y * 150.0)));
	COLOR = vec4(vec3(n * scan * lines), 1.0);
}
"""

var _material: ShaderMaterial
var _fill: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = shader
	_fill = ColorRect.new()
	_fill.material = _material
	_fill.color = Color(1, 1, 1, 1)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)
	resized.connect(_sync_fill)
	_sync_fill()
	set_process(true)

func _sync_fill() -> void:
	_fill.position = Vector2.ZERO
	_fill.size = size

func _process(_delta: float) -> void:
	_material.set_shader_parameter("time", Time.get_ticks_msec() * 0.001)
