shader_type canvas_item;
// A lit pillar of the Altar of the Nine (AltarElements): energy runs up its glowing veins.
// Veins = pixels that differ from the unlit pillar (`base_tex`); the stone stays as it is.
// Waves of `glow_color` move from the foot to the top and the whole vein pulses gently.

uniform sampler2D base_tex : filter_nearest;
uniform vec4 glow_color : source_color = vec4(1.0);
uniform float speed = 0.55;
uniform float waves = 2.5;
uniform float offset = 0.0;

void fragment() {
	vec4 lit = texture(TEXTURE, UV);
	vec4 base = texture(base_tex, UV);
	float vein = smoothstep(0.12, 0.3, distance(lit.rgb, base.rgb)) * lit.a;
	// whole texels only, so the waves stay pixel art
	float y = floor(UV.y / TEXTURE_PIXEL_SIZE.y) * TEXTURE_PIXEL_SIZE.y;
	float wave = 0.5 + 0.5 * sin((y * waves + TIME * speed + offset) * 6.2832);
	wave = pow(wave, 4.0);
	float pulse = 0.85 + 0.15 * sin(TIME * 2.3 + offset * 6.2832);
	vec3 color = lit.rgb * mix(1.0, pulse, vein);
	color += glow_color.rgb * vein * wave * 0.55;
	COLOR = vec4(min(color, vec3(1.0)), lit.a);
}
