shader_type canvas_item;
// Drifting fog over the dark city (FinsterFog). Two layers of noise move with the wind in steps,
// the density falls off in a few hard bands with an ordered dither between them, so it stays
// pixel art. `holes` clear the fog around the player and every burning light.

uniform vec4 fog_color : source_color = vec4(0.36, 0.35, 0.43, 1.0);
// north of this line (world y) the fog thins out by `clear_above_amount` (the castle stays visible)
uniform float clear_above_y = -470.0;
uniform float clear_above_amount = 0.5;
uniform float max_alpha = 0.94;
uniform float density = 0.95;
uniform sampler2D noise : repeat_enable, filter_nearest;
// pixels per second the two layers drift
uniform vec2 wind = vec2(7.0, 1.5);
uniform float pixel_size = 2.0;
uniform float steps_per_second = 8.0;
// 0 = full fog, 1 = gone (cutscenes thin it out)
uniform float thin = 0.0;
// x, y (world), radius, strength 0..1; the first hole is the player
uniform vec4 holes[24];
uniform int hole_count = 0;
// beyond this distance from the player the fog closes in (thicker towards view_radius * 2)
uniform float view_radius = 150.0;
uniform float far_density = 1.7;

varying vec2 world;


void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0 - 0.5;
}


void fragment() {
	vec2 cell = floor(world / pixel_size);
	vec2 p = cell * pixel_size;
	float t = floor(TIME * steps_per_second) / steps_per_second;
	float a = texture(noise, (p + wind * t) / 640.0).r;
	float b = texture(noise, (p * 1.6 - vec2(wind.y, wind.x) * t * 1.4) / 640.0 + vec2(0.37, 0.11)).r;
	float d = density * (0.45 + 0.4 * a + 0.3 * b);
	if (hole_count > 0) {
		float far = smoothstep(view_radius, view_radius * 2.0, distance(p, holes[0].xy));
		d *= mix(1.0, far_density, far);
	}
	d *= 1.0 - clear_above_amount * smoothstep(clear_above_y, clear_above_y - 50.0, p.y);
	float clear = 1.0;
	for (int i = 0; i < hole_count; i++) {
		vec4 h = holes[i];
		float k = smoothstep(h.z * 0.4, h.z, distance(p, h.xy));
		clear = min(clear, mix(1.0, k, h.w));
	}
	d *= clear * (1.0 - thin);
	d = floor(d * 5.0 + 0.5 + bayer4(cell) * 0.9) / 5.0;
	COLOR = vec4(fog_color.rgb, clamp(d, 0.0, 1.0) * max_alpha);
}
