// Forge defense: a coloured glow at the edges of the screen (the smithy is hit: red).
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0, 0.1, 0.05, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 from_middle = (UV - vec2(0.5)) * 2.0;
	float edge = smoothstep(0.45, 1.25, length(from_middle));
	COLOR = vec4(tint.rgb, tint.a * amount * edge);
}
