shader_type canvas_item;

uniform float size : hint_range(1.0, 20.0) = 5.0;
uniform float intensity : hint_range(0.0, 3.0) = 1.5;

void fragment() {
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	vec4 glow_sum = vec4(0.0);

	for (float x = -size; x <= size; x += 1.0) {
		for (float y = -size; y <= size; y += 1.0) {
			glow_sum += texture(TEXTURE, UV + vec2(x, y) * pixel);
		}
	}
	glow_sum /= (size * 2.0 + 1.0) * (size * 2.0 + 1.0);

	vec4 tex = texture(TEXTURE, UV);
	vec4 glow_result = vec4(glow_sum.rgb * intensity, glow_sum.a);
	COLOR = mix(glow_result, tex, tex.a);
}
