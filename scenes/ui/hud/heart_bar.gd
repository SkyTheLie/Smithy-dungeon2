class_name HeartBar
extends Control
## The hearts at the top left: full, half and empty (dark) red hearts of RunState, then the blue
## hearts, then the white shield hearts from the equipment (full or half).

const HEART: Texture2D = preload("res://assets/sprites/items/arena_heart.png")
const SIZE: float = 28.0
const STEP: float = 27.0
const BLUE := Color(0.45, 0.7, 1.0)
const EMPTY := Color(0.18, 0.12, 0.14, 0.9)

var run: RunState
## The heart picture in white (made once from HEART: brightness kept, colour taken out).
static var _white_heart: Texture2D


func setup(run_state: RunState) -> void:
	run = run_state
	if _white_heart == null:
		_white_heart = _make_white_heart()
	run.changed.connect(_on_changed)
	_on_changed()


static func _make_white_heart() -> Texture2D:
	var image: Image = HEART.get_image()
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			var light: float = clampf(maxf(pixel.r, maxf(pixel.g, pixel.b)) * 0.7 + 0.35, 0.0, 1.0)
			image.set_pixel(x, y, Color(light, light, light * 0.97, pixel.a))
	return ImageTexture.create_from_image(image)


func _shield_count() -> int:
	return ceili(run.shield / 2.0)


func _blue_count() -> int:
	return ceili(run.blue / 2.0)


func _on_changed() -> void:
	custom_minimum_size = Vector2(STEP * (run.max_hearts + _blue_count() + _shield_count()) + 2.0, SIZE)
	queue_redraw()


func _draw() -> void:
	if run == null:
		return
	for i in run.max_hearts:
		var rect := Rect2(Vector2(i * STEP, 0), Vector2(SIZE, SIZE))
		# empty heart first (dark), the filled part (half = left half) over it
		draw_texture_rect(HEART, rect, false, EMPTY)
		_draw_part(rect, clampi(run.health - i * 2, 0, 2), Color.WHITE)
	for i in _blue_count():
		var rect := Rect2(Vector2((run.max_hearts + i) * STEP, 0), Vector2(SIZE, SIZE))
		_draw_part(rect, clampi(run.blue - i * 2, 0, 2), BLUE)
	for i in _shield_count():
		var rect := Rect2(Vector2((run.max_hearts + _blue_count() + i) * STEP, 0), Vector2(SIZE, SIZE))
		_draw_part(rect, clampi(run.shield - i * 2, 0, 2), Color.WHITE, _white_heart)


## `filled`: 2 = whole heart, 1 = left half.
func _draw_part(rect: Rect2, filled: int, tint: Color, picture: Texture2D = HEART) -> void:
	var texture_size: Vector2 = picture.get_size()
	if filled == 2:
		draw_texture_rect(picture, rect, false, tint)
	elif filled == 1:
		var half := Rect2(rect.position, Vector2(SIZE / 2.0, SIZE))
		draw_texture_rect_region(picture, half, Rect2(Vector2.ZERO, Vector2(texture_size.x / 2.0, texture_size.y)), tint)
