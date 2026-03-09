shader_type canvas_item;

/**
 * Shader for creating transparent holes in textures
 *
 * Sets alpha channel to 0 for pixels within specified area,
 * creating a hole effect. Works in UV coordinates (0,0 = top-left, 1,1 = bottom-right).
 * Uses distance calculation to determine hole boundaries.
 */

uniform bool show_hole = false;               // Enable/disable hole effect
uniform vec2 hole_position = vec2(0.5, 0.5);  // Center position of hole in UV coordinates
uniform float hole_radius = 0.1;              // Hole radius in UV units

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (show_hole) {
        // Calculate distance from current pixel to hole center
        float dist = distance(UV, hole_position);

        if (dist < hole_radius) {
            COLOR.a = 0.0;  // Make pixel transparent (create hole)
        } else {
            COLOR = tex;    // Keep pixel as is
        }
    } else {
        COLOR = tex;        // Show normal texture without changes
    }
}