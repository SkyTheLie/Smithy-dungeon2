class_name ForgeSignBoard
extends NinePatchRect
## The board of the forge sign: the theme's picture (house.json forge_sign.themes "texture",
## stretched as a nine-patch) with the name on it, as wide as the name. Used outside on the smithy
## (ForgeSignWall) and as the preview in the name window (ForgeSignMenu).

## Space between the name and the board's edge (left/right, top/bottom).
const PADDING := Vector2(6, 1)
const MIN_SIZE := Vector2(24, 14)

@onready var _label: Label = $Label


## Shows `text` on the board of `theme` and sizes the board to fit.
func show_sign(text: String, theme: String) -> void:
	var entry: Dictionary = ForgeSign.get_theme_data(theme)
	var path: String = str(entry.get("texture", ""))
	texture = load(path) if ResourceLoader.exists(path) else null
	var margin: int = int(ForgeSign.data().get("margin", 4))
	patch_margin_left = margin
	patch_margin_right = margin
	patch_margin_top = margin
	patch_margin_bottom = margin
	_label.text = text
	_label.add_theme_color_override("font_color", Color.from_string(str(entry.get("text_color", "#ffffff")), Color.WHITE))
	var font: Font = _label.get_theme_font("font")
	var font_size: int = _label.get_theme_font_size("font_size")
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var board := Vector2(ceilf(text_size.x) + PADDING.x * 2.0, ceilf(font.get_height(font_size)) + PADDING.y * 2.0)
	size = board.max(MIN_SIZE)
	custom_minimum_size = size
