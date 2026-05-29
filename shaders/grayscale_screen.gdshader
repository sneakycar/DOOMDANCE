shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float contrast : hint_range(0.5, 2.0) = 1.08;

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	g = (g - 0.5) * contrast + 0.5;
	COLOR = vec4(vec3(clamp(g, 0.0, 1.0)), 1.0);
}
