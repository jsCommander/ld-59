shader_type canvas_item;

/**
 * Shader for creating perfectly circular transparent holes in textures
 *
 * Same as hole_mask.gdshader but corrects for texture aspect ratio
 * to ensure holes are always circular, not elliptical on rectangular textures.
 * Works in UV coordinates (0,0 = top-left, 1,1 = bottom-right).
 */

uniform bool show_hole = false;               // Enable/disable hole effect
uniform vec2 hole_position = vec2(0.5, 0.5);  // Center position of hole in UV coordinates
uniform float hole_radius = 0.1;              // Hole radius in UV units

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (show_hole) {
        // Get texture dimensions to calculate aspect ratio
        vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
        float aspect_ratio = texture_size.x / texture_size.y;

        // Correct coordinates to compensate for texture aspect ratio
        // This ensures holes are circular instead of elliptical
        vec2 corrected_uv = UV;
        vec2 corrected_pos = hole_position;

        if (aspect_ratio > 1.0) {
            // Wide texture - stretch X coordinate
            corrected_uv.x *= aspect_ratio;
            corrected_pos.x *= aspect_ratio;
        } else {
            // Tall texture - stretch Y coordinate
            corrected_uv.y /= aspect_ratio;
            corrected_pos.y /= aspect_ratio;
        }

        // Calculate distance in aspect-corrected space
        float dist = distance(corrected_uv, corrected_pos);

        if (dist < hole_radius) {
            COLOR.a = 0.0;  // Make pixel transparent (create hole)
        } else {
            COLOR = tex;    // Keep pixel as is
        }
    } else {
        COLOR = tex;        // Show normal texture without changes
    }
}