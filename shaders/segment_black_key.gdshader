shader_type canvas_item;

uniform float black_threshold : hint_range(0.0, 0.2, 0.01) = 0.07;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = max(tex.r, max(tex.g, tex.b));
	if (lum < black_threshold) {
		discard;
	}
	COLOR = tex;
}
