shader_type canvas_item;

uniform float shimmer_phase = 0.0;
uniform float zoom_level = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float n = sin((UV.x + UV.y) * 48.0 + shimmer_phase) * 0.015;
	vec3 col = base.rgb + vec3(n, n * 0.6, n * 1.1);
	float glow = smoothstep(0.55, 0.95, base.r) * 0.12;
	col += vec3(glow);
	if (zoom_level < 2.0) {
		col = mix(col, col * 0.85 + vec3(0.04, 0.06, 0.09), 0.35);
	}
	COLOR = vec4(col, 1.0);
}
