shader_type canvas_item;
// The dark sea of the water maps (Eisquell, the water arena) in a baked ground picture: only pixels in
// one of the sea colours move, ice, walls and shores stay as they are. Like the pond water
// (pond_water.gdshader): rows drift sideways by whole pixels and small glints come and go, in
// steps like an animation drawn frame by frame. Waterfalls painted into the ground (`falls`:
// x, y, width, height in texture pixels; streaks repeat every `fall_period` pixels) scroll their
// streaks downwards instead.

uniform float frames_per_second = 6.0;
uniform float drift = 1.0;
uniform float glint_density = 0.004;
uniform vec3 glint_color = vec3(0.506, 0.675, 0.812);
uniform vec4 falls[4];
uniform int fall_count = 0;
uniform float fall_period = 24.0;
uniform float fall_speed = 30.0;
// The sea colours (eisquell_ground.png), darkest first.
const vec3 SEA[8] = vec3[8](
	vec3(0.039, 0.122, 0.290), vec3(0.071, 0.180, 0.353), vec3(0.125, 0.239, 0.424),
	vec3(0.173, 0.290, 0.475), vec3(0.235, 0.361, 0.541), vec3(0.314, 0.463, 0.643),
	vec3(0.408, 0.592, 0.761), vec3(0.506, 0.675, 0.812));


bool is_sea(vec3 c) {
	for (int i = 0; i < 8; i++) {
		if (distance(c, SEA[i]) < 0.012) {
			return true;
		}
	}
	return false;
}


float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 here = floor(UV / TEXTURE_PIXEL_SIZE);
	bool falling = false;
	for (int i = 0; i < fall_count; i++) {
		vec4 f = falls[i];
		if (here.x >= f.x && here.x < f.x + f.z && here.y >= f.y && here.y < f.y + f.w) {
			// the streak pattern moves down by whole pixels, wrapping inside one period
			float shift = floor(TIME * fall_speed);
			float y = f.y + mod(here.y - f.y - shift, fall_period);
			color = texture(TEXTURE, (vec2(here.x, y) + 0.5) * TEXTURE_PIXEL_SIZE);
			falling = true;
		}
	}
	if (!falling && is_sea(color.rgb)) {
		vec2 pixel = floor(UV / TEXTURE_PIXEL_SIZE);
		float step_time = floor(TIME * frames_per_second);
		float shift = round(drift * sin(pixel.y * 0.45 + step_time * 0.32));
		vec4 moved = texture(TEXTURE, UV + vec2(shift * TEXTURE_PIXEL_SIZE.x, 0.0));
		if (is_sea(moved.rgb)) {
			color = moved;
		}
		vec2 cell = floor(pixel / vec2(2.0, 1.0));
		if (hash(cell + floor(step_time / 5.0) * 0.17) < glint_density) {
			color.rgb = glint_color;
		}
	}
	COLOR = color;
}
