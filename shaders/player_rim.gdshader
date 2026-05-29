shader_type canvas_item;

render_mode blend_mix;

uniform vec4 cool_rim : source_color = vec4(0.35, 0.58, 0.95, 1.0);
uniform vec4 warm_rim : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 1.1;
uniform float rim_width : hint_range(0.0, 0.5) = 0.08;
uniform float light_side : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.001) {
		discard;
	}

	vec2 px = TEXTURE_PIXEL_SIZE;
	float a_l = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float a_r = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float a_u = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float a_d = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	float edge = max(max(a_l, a_r), max(a_u, a_d)) - tex.a;
	edge = clamp(edge / max(rim_width, 0.001), 0.0, 1.0);

	vec3 base = tex.rgb * 1.22 + vec3(0.06);
	float warm_mix = smoothstep(-0.1, 0.9, UV.x * light_side);
	vec3 rim = mix(cool_rim.rgb, warm_rim.rgb, warm_mix) * edge * rim_strength;

	COLOR = vec4(clamp(base + rim, vec3(0.0), vec3(1.0)), tex.a);
}
