class_name HiResTexture
extends Texture2D
## A texture with more pixels than game pixels: reports `texture` divided by `factor` as its size
## and draws all of its pixels into that size. Used for detailed item icons (a 32x32 picture
## shown on 16x16, see ContentDB; currently no icon uses it, 12x12 to 24x24 icons are drawn 1:1): everything that draws item icons (slots, lists, the display
## stand ...) keeps working with the game size, and at 2x window scale every picture pixel is one
## screen pixel. get_image() can't be overridden by a script and gives null: use full_image().

## Pixels of the picture per game pixel.
const ICON_FACTOR: int = 2
## Pictures wider than this (icon area of an item slot, 24x24) count as detailed.
const NORMAL_MAX_SIZE: int = 24

var texture: Texture2D
var factor: int = ICON_FACTOR


static func of(source: Texture2D, source_factor: int = ICON_FACTOR) -> HiResTexture:
	var result := HiResTexture.new()
	result.texture = source
	result.factor = source_factor
	return result


## Pixels of any texture; for a HiResTexture the full picture (ItemIcons.compose layers those).
static func full_image(source: Texture2D) -> Image:
	return source.texture.get_image() if source is HiResTexture else source.get_image()


## Item icons bigger than a normal slot are detailed pictures: wrapped, others unchanged.
static func for_item_icon(source: Texture2D) -> Texture2D:
	if source == null or source is HiResTexture or source.get_width() <= NORMAL_MAX_SIZE:
		return source
	return of(source)


func _get_width() -> int:
	return floori(texture.get_width() / float(factor))


func _get_height() -> int:
	return floori(texture.get_height() / float(factor))


func _get_rid() -> RID:
	return texture.get_rid()


func _has_alpha() -> bool:
	return texture.has_alpha()


func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	texture.draw_rect(to_canvas_item, Rect2(pos, get_size()), false, modulate, transpose)


func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	texture.draw_rect(to_canvas_item, rect, tile, modulate, transpose)


func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color,
		transpose: bool, clip_uv: bool) -> void:
	var source := Rect2(src_rect.position * factor, src_rect.size * factor)
	texture.draw_rect_region(to_canvas_item, rect, source, modulate, transpose, clip_uv)
