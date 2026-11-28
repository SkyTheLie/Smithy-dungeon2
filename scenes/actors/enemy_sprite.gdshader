// Enemy picture: like the normal Sprite3D (unshaded, turns to the camera around the Y axis,
// alpha cut), but `flash` (0..1) paints it white for the hit flash. The sprite's modulate comes in
// as the vertex COLOR; the sheet is set by Enemy._set_sheet (a custom material does not get it).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D sprite_texture : source_color, filter_nearest;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Billboard around Y (as BaseMaterial3D.BILLBOARD_FIXED_Y), keeping the node's scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 picture = texture(sprite_texture, UV);
	ALBEDO = mix(picture.rgb * COLOR.rgb, vec3(1.0), flash);
	ALPHA = picture.a * COLOR.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
