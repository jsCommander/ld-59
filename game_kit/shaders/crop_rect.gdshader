shader_type canvas_item;

uniform vec4 crop_rect;

void fragment() {
    vec2 uv = UV;

    if (uv.x < crop_rect.x || uv.x > crop_rect.x + crop_rect.z ||
        uv.y < crop_rect.y || uv.y > crop_rect.y + crop_rect.w) {
        COLOR.a = 0.0;
    } else {
        COLOR = texture(TEXTURE, uv);
    }
}