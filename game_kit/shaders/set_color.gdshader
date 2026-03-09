shader_type canvas_item;

uniform bool active = false;
uniform vec3 color: source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
    if (active) {
		 COLOR = vec4(color.x, color.y, color.z, texture(TEXTURE, UV).a);
    } else {
        COLOR = texture(TEXTURE, UV);
    }
}