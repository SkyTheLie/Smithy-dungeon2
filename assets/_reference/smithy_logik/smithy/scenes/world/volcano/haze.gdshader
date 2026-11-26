shader_type canvas_item;
// Hot smoke drifting over the canyon of the Lavaberg (between the canyon floor and the plateau):
// thin dark-red veils whose thickness comes from slowly moving noise, in a few steps.

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 smoke_color : source_color = vec4(0.36, 0.17, 0.13, 1.0);
uniform float strength = 0.55;
uniform float speed = 0.008;

void fragment() {
	vec2 world = floor(UV * vec2(1024.0, 1280.0) / 2.0);
	float n1 = texture(noise_tex, world / 180.0 + vec2(TIME * speed, -TIME * speed * 0.4)).r;
	float n2 = texture(noise_tex, world / 97.0 + vec2(-TIME * speed * 0.7, -TIME * speed)).r;
	float n = floor((n1 * 0.6 + n2 * 0.4) * 5.0) / 5.0;
	COLOR = vec4(smoke_color.rgb, clamp((n - 0.3) * strength * 1.6, 0.0, strength));
}
