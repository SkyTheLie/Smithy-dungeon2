shader_type canvas_item;
// Water in a baked ground picture: only pixels in the colours of the pond tiles move, shore and
// meadow stay as they are. Rows drift sideways by whole pixels and small glints come and go, in
// steps like an animation drawn frame by frame.

uniform float frames_per_second = 6.0;
uniform float drift = 1.0;
uniform float glint_density = 0.005;
uniform vec3 glint_color = vec3(0.36, 0.66, 0.66);


bool is_water(vec3 c) {
	return c.g > c.r * 1.7 && c.b > c.r * 1.7 && c.b >= c.g - 0.02 && c.r < 0.3;
}


float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (is_water(color.rgb)) {
		vec2 pixel = floor(UV / TEXTURE_PIXEL_SIZE);
		float step_time = floor(TIME * frames_per_second);
		float shift = round(drift * sin(pixel.y * 0.45 + step_time * 0.32));
		vec4 moved = texture(TEXTURE, UV + vec2(shift * TEXTURE_PIXEL_SIZE.x, 0.0));
		if (is_water(moved.rgb)) {
			color = moved;
		}
		vec2 cell = floor(pixel / vec2(2.0, 1.0));
		if (hash(cell + floor(step_time / 5.0) * 0.17) < glint_density) {
			color.rgb = glint_color;
		}
	}
	COLOR = color;
}
