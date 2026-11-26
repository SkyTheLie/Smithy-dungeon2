// Forge defense: the picture loses its colour and darkens (the smithy falls).
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 picture = texture(screen, SCREEN_UV).rgb;
	float gray = dot(picture, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(picture, vec3(gray) * 0.75, amount), 1.0);
}
