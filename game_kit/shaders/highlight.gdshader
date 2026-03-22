shader_type canvas_item;

uniform bool enabled = false;
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (enabled && col.a > 0.1) {
		col.rgb = mix(col.rgb, highlight_color.rgb, highlight_color.a);
	}
	COLOR = col;
}
