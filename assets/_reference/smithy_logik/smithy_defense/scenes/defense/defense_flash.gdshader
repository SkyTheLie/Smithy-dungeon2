// Forge defense figures: a hit flashes the picture pure white instead of only brighter.
// One shared material for all enemies and units (they stay batched): the flash comes in through
// the modulate colour. Are all three channels above 1 (e.g. Color(2, 2, 2)), the picture turns
// white by that much (2 = fully white); normal tints (shiny gold 1.5/1.25/0.45) stay as they are.
shader_type canvas_item;

void fragment() {
	vec4 tint = COLOR;
	vec4 picture = texture(TEXTURE, UV);
	float flash = clamp(min(tint.r, min(tint.g, tint.b)) - 1.0, 0.0, 1.0);
	vec3 tinted = picture.rgb * tint.rgb;
	COLOR = vec4(mix(tinted, vec3(1.0), flash), picture.a * tint.a);
}
