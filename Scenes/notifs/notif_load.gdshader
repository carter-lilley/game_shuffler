shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.1, 0.1, 0.1, 1.0); // First checker color
uniform vec4 color2 : source_color = vec4(0.9, 0.9, 0.9, 1.0); // Second checker color
uniform float checker_size = 10.0; // Size of each checker square
uniform vec2 scroll_direction = vec2(1.0, 0.0); // Scroll direction (UV space)
uniform float scroll_speed = 1.0; // Speed of the scrolling
uniform float transition_completeness : hint_range(0.0, 1.0) = 0.0; // Transition completeness

void fragment() {
// TRANSITION
	vec2 uv = UV;
    // Calculate the thresholds for the top and bottom
    float top_threshold = 0.5 + (0.5 * transition_completeness);
    float bottom_threshold = 0.5 - (0.5 * transition_completeness);

    // Determine the color based on the vertical position relative to the thresholds
    float transition_alpha = 1.0 - (step(bottom_threshold, uv.y) * step(uv.y, top_threshold));

// CHECKERS
    // Get the aspect ratio of the parent
    float aspect_ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    // Adjust the UV to ensure the checkerboard remains square by correcting the Y coordinate
    uv.y *= aspect_ratio;
    // Apply scrolling by modifying the UV based on time
    uv += scroll_direction * scroll_speed * TIME;
    // Scale UVs to control checkerboard size
    uv *= checker_size;
    // Calculate the checkerboard pattern
    vec2 check = floor(uv);
    float pattern = mod(check.x + check.y, 2.0);
    // Mix the two colors based on the checker pattern
    vec4 checkers = mix(color1, color2, pattern);

	checkers.a *= transition_alpha;
    //// Output the color
    COLOR = checkers;
}
