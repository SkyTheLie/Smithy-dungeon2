class_name GuideOutline
extends Node2D
## Golden, pulsing outline around a thing in the world plus a small bouncing arrow above it
## (Guide: "go here next"). Sits on the picture of its target: as child of a Sprite2D it draws
## the sprite's picture 1 px larger in gold behind it; without a sprite `shape_getter` gives the
## picture ({"texture", "rect"} in the parent's coordinates, {} = only the arrow).
## Shown while `condition` returns true (asked a few times a second). Station adds one to every
## station by itself (Station.is_guide_target).

const COLOR: Color = Color(1.0, 0.82, 0.3)
const ARROW_DARK: Color = Color("21131e")
## Frames between two checks of the condition (12 = 0.2 s at 60 fps).
const CHECK_FRAMES: int = 12
## Arrow: gap above the picture, how far it bounces, bounces per second (times TAU).
const ARROW_GAP: float = 4.0
const ARROW_BOUNCE: float = 3.0
const ARROW_SPEED: float = 4.0
## Arrow without a picture: this high above the node.
const ARROW_DEFAULT_TOP: float = -28.0
const OFFSETS: Array[Vector2] = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1),
		Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
## Draws the picture as a flat golden silhouette that pulses.
const SHADER_CODE: String = """
shader_type canvas_item;
uniform vec4 glow : source_color = vec4(1.0, 0.82, 0.3, 1.0);
void fragment() {
	float pulse = 0.65 + 0.35 * sin(TIME * 5.0);
	COLOR = vec4(glow.rgb, texture(TEXTURE, UV).a * glow.a * pulse);
}
"""

static var _shader: Shader

var condition: Callable
var shape_getter: Callable
var _sprite: Sprite2D
var _arrow: Node2D = Node2D.new()
var _next_check: int = 0


## Puts an outline on `target`: on its first Sprite2D child, otherwise on the target itself
## (then `shape` gives the picture).
static func attach(target: Node2D, show_when: Callable, shape: Callable = Callable()) -> GuideOutline:
	var outline := GuideOutline.new()
	outline.condition = show_when
	outline.shape_getter = shape
	var sprite: Sprite2D = null
	if not shape.is_valid():
		for child in target.get_children():
			if child is Sprite2D:
				sprite = child
				break
	outline._sprite = sprite
	(sprite if sprite else target).add_child(outline)
	return outline


func _ready() -> void:
	show_behind_parent = true
	visible = false
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = _shader
	material = shader_material
	# The arrow stands above everything around it.
	_arrow.z_index = 20
	_arrow.draw.connect(_draw_arrow)
	add_child(_arrow)


func _process(_delta: float) -> void:
	var now: int = Engine.get_process_frames()
	if now >= _next_check:
		_next_check = now + CHECK_FRAMES
		var shown: bool = condition.is_valid() and bool(condition.call())
		if shown != visible:
			visible = shown
	if visible:
		queue_redraw()
		_arrow.queue_redraw()


## {"texture", "rect", "region"} of the picture, {} = none.
func _get_shape() -> Dictionary:
	if _sprite:
		if _sprite.texture == null or not _sprite.visible:
			return {}
		return {"texture": _sprite.texture, "rect": _sprite.get_rect(), "region": _get_sprite_region()}
	if shape_getter.is_valid():
		return shape_getter.call()
	return {}


## The part of the sprite's texture it shows (region or the current frame of a sheet).
func _get_sprite_region() -> Rect2:
	if _sprite.region_enabled:
		return _sprite.region_rect
	var frame_size: Vector2 = _sprite.texture.get_size() / Vector2(_sprite.hframes, _sprite.vframes)
	var coords := Vector2(_sprite.frame % _sprite.hframes, _sprite.frame / _sprite.hframes)
	return Rect2(coords * frame_size, frame_size)


func _draw() -> void:
	var shape: Dictionary = _get_shape()
	if shape.is_empty():
		return
	var texture: Texture2D = shape.get("texture")
	if texture == null:
		return
	var rect: Rect2 = shape["rect"]
	var region: Rect2 = shape.get("region", Rect2(Vector2.ZERO, texture.get_size()))
	for offset in OFFSETS:
		draw_texture_rect_region(texture, Rect2(rect.position + offset, rect.size), region)


## A small golden arrow pointing down at the picture, bouncing.
func _draw_arrow() -> void:
	var shape: Dictionary = _get_shape()
	var rect: Rect2 = shape.get("rect", Rect2(0, ARROW_DEFAULT_TOP, 0, 0))
	var bounce: float = (0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * ARROW_SPEED)) * ARROW_BOUNCE
	var tip := Vector2(rect.get_center().x, rect.position.y - ARROW_GAP - bounce)
	var outer := PackedVector2Array([tip + Vector2(0, 1), tip + Vector2(-5, -5), tip + Vector2(5, -5)])
	var inner := PackedVector2Array([tip + Vector2(0, -1), tip + Vector2(-3, -4), tip + Vector2(3, -4)])
	_arrow.draw_colored_polygon(outer, ARROW_DARK)
	_arrow.draw_colored_polygon(inner, COLOR)
