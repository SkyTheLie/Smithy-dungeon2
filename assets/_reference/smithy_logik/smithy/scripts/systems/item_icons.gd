class_name ItemIcons
extends RefCounted
## Builds the icon of a composed item (e.g. sword = handle + blade) by layering the icons of
## its parts. Convention: all parts of one item kind are drawn on the same canvas size,
## each at its final position (rest transparent), so the layers can simply be stacked.
## Parts are stacked by ItemData.layer_order; results are cached.
## mold() builds the 24x24 icon of a mold (icon area of a slot): a frame in the colour of the metal
## (materials.json "colors") with what it makes in the middle (assets/sprites/molds/<part type>.png,
## drawn from the item icons by assets/_reference/molds/make_mold_icons24.py).

## Glow colours of hot pictures (anvil minigame, hot blanks), from dark to bright parts.
const HEAT_DARK: Color = Color(0.5, 0.07, 0.03)
const HEAT_MID: Color = Color(1.0, 0.42, 0.08)
const HEAT_BRIGHT: Color = Color(1.0, 0.88, 0.5)
## Brightness of the pixel that glows darkest, and the range up to the brightest glow.
const HEAT_LIGHT_FROM: float = 0.12
const HEAT_LIGHT_RANGE: float = 0.75
const MOLD_SIZE: int = 24
const MOLD_SILHOUETTE: String = "res://assets/sprites/molds/%s.png"
const JEWEL_ICON: String = "res://assets/sprites/items/jewelry/%s_%s.png"
const MOLD_OUTLINE: Color = Color("#21131e")
## Frame colours without a metal (e.g. an unknown mold of no metal), light to dark like materials.json.
const MOLD_NEUTRAL_COLORS: Array[String] = ["#d6d0c4", "#a59c8d", "#928778", "#766967", "#4c5262"]

static var _cache: Dictionary = {}
static var _mold_cache: Dictionary = {}


## Icon of the mold for `part` (e.g. copper_blade: copper frame with a sword).
static func mold(part: ItemData) -> Texture2D:
	var kind: String = ItemData.PartType.keys()[part.part_type].to_lower()
	if part.part_type == ItemData.PartType.NONE and not part.mold_shape.is_empty():
		kind = part.mold_shape
	return mold_of(kind, part.material_id)


## Icon of a mold of part type `kind` ("blade", "boot_plate" ...; "unknown" = question mark) in the
## colours of `material_id` (empty / no colours = neutral).
static func mold_of(kind: String, material_id: String = "") -> Texture2D:
	var key: String = kind + "|" + material_id
	if _mold_cache.has(key):
		return _mold_cache[key]
	var colors: Array = ContentDB.material_colors(material_id) if not material_id.is_empty() else []
	if colors.size() < 5:
		colors = MOLD_NEUTRAL_COLORS
	var shades: Array[Color] = []
	for value in colors:
		shades.append(Color.from_string(str(value), Color.GRAY))
	var image: Image = Image.create_empty(MOLD_SIZE, MOLD_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(shades[2])
	var last: int = MOLD_SIZE - 1
	for i in MOLD_SIZE:
		for point: Vector2i in [Vector2i(i, 0), Vector2i(i, last), Vector2i(0, i), Vector2i(last, i)]:
			image.set_pixelv(point, MOLD_OUTLINE)
	# Bevel: light on top and left, dark on the bottom and right.
	for i in range(1, last):
		image.set_pixel(i, 1, shades[1])
		image.set_pixel(1, i, shades[1])
		image.set_pixel(i, last - 1, shades[3])
		image.set_pixel(last - 1, i, shades[3])
	var path: String = MOLD_SILHOUETTE % kind
	if not ResourceLoader.exists(path):
		path = MOLD_SILHOUETTE % "unknown"
	var silhouette: Image = (load(path) as Texture2D).get_image()
	if silhouette.is_compressed():
		silhouette.decompress()
	silhouette.convert(Image.FORMAT_RGBA8)
	image.blend_rect(silhouette, Rect2i(Vector2i.ZERO, silhouette.get_size()), (Vector2i(MOLD_SIZE, MOLD_SIZE) - silhouette.get_size()) / 2)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_mold_cache[key] = texture
	return texture


## Animated icon from a horizontal strip of `frames` frames of the same size, `fps` frames per second
## (items.json "icon_frames" / "icon_fps", e.g. the holy crystals with 48x48 frames). It plays by
## itself wherever it is drawn (slots, tooltips, sprites).
static func animated(strip: Texture2D, frames: int, fps: float) -> AnimatedTexture:
	# Each frame is its own texture: an AtlasTexture would not do, AnimatedTexture draws the whole
	# strip behind it (all frames squeezed into one icon).
	var image: Image = strip.get_image()
	if image.is_compressed():
		image.decompress()
	var frame_width: int = image.get_width() / frames
	var result := AnimatedTexture.new()
	result.frames = frames
	for i: int in frames:
		var frame: Image = image.get_region(Rect2i(i * frame_width, 0, frame_width, image.get_height()))
		result.set_frame_texture(i, ImageTexture.create_from_image(frame))
		result.set_frame_duration(i, 1.0 / fps)
	return result


## A picture glowing: every pixel coloured by its brightness, from dark red over orange to yellow
## (the outline stays the darkest red). Works on a copy.
static func heated_image(icon: Image) -> Image:
	var hot: Image = icon.duplicate()
	if hot.is_compressed():
		hot.decompress()
	hot.convert(Image.FORMAT_RGBA8)
	for y in hot.get_height():
		for x in hot.get_width():
			var color: Color = hot.get_pixel(x, y)
			if color.a == 0.0:
				continue
			var light: float = clampf((color.get_luminance() - HEAT_LIGHT_FROM) / HEAT_LIGHT_RANGE, 0.0, 1.0)
			var glow: Color = HEAT_DARK.lerp(HEAT_MID, light * 2.0) if light < 0.5 else HEAT_MID.lerp(HEAT_BRIGHT, light * 2.0 - 1.0)
			glow.a = color.a
			hot.set_pixel(x, y, glow)
	return hot


## `texture` glowing (heated_image), null if it has no picture.
static func heated(texture: Texture2D) -> Texture2D:
	var image: Image = HiResTexture.full_image(texture) if texture else null
	return ImageTexture.create_from_image(heated_image(image)) if image else null


## `texture` with its used pixels moved into the middle of its canvas (the same texture if they are
## there already, or 1 px off at most), e.g. a pickaxe head drawn at the top of its 24x24 canvas.
static func centered(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var image: Image = texture.get_image()
	if image == null:
		return texture
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var used: Rect2i = image.get_used_rect()
	var target: Vector2i = (image.get_size() - used.size) / 2
	if not used.has_area() or (absi(target.x - used.position.x) <= 1 and absi(target.y - used.position.y) <= 1):
		return texture
	var canvas: Image = Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	canvas.blit_rect(image, used, target)
	return ImageTexture.create_from_image(canvas)


## Icon of a ring / amulet from the jewel table: the band it was made of with the stone on top
## (assets/sprites/items/jewelry/<kind>_<crystal id>.png, the stone at its place on the band),
## null if there is no picture of the stone.
static func jewel(crystal: ItemData, band: ItemData, kind: String) -> Texture2D:
	var path: String = JEWEL_ICON % [kind, crystal.id]
	if not ResourceLoader.exists(path):
		return null
	var key: String = path + ":" + (String(band.id) if band else "")
	if not _cache.has(key):
		var stone: Image = (load(path) as Texture2D).get_image()
		stone.convert(Image.FORMAT_RGBA8)
		var canvas: Image = Image.create_empty(stone.get_width(), stone.get_height(), false, Image.FORMAT_RGBA8)
		if band:
			var layer: Image = HiResTexture.full_image(band.layer_icon if band.layer_icon else band.icon)
			if layer.is_compressed():
				layer.decompress()
			layer.convert(Image.FORMAT_RGBA8)
			canvas.blend_rect(layer, Rect2i(Vector2i.ZERO, layer.get_size()), Vector2i.ZERO)
		canvas.blend_rect(stone, Rect2i(Vector2i.ZERO, stone.get_size()), Vector2i.ZERO)
		_cache[key] = HiResTexture.for_item_icon(ImageTexture.create_from_image(canvas))
	return _cache[key]


static func compose(parts: Array[ItemData]) -> Texture2D:
	var key: String = ",".join(PackedStringArray(parts.map(func(part: ItemData) -> String: return String(part.id))))
	if _cache.has(key):
		return _cache[key]
	var sorted: Array[ItemData] = parts.duplicate()
	sorted.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.layer_order < b.layer_order)
	var has_shield_plate: bool = sorted.any(func(part: ItemData) -> bool: return part.part_type == ItemData.PartType.SHIELD_PLATE)
	var layers: Array[Image] = []
	var canvas_size := Vector2i.ZERO
	for part in sorted:
		# The handle of a shield is on its back: it would stick out below the plate.
		if has_shield_plate and part.part_type == ItemData.PartType.HANDLE:
			continue
		var layer: Texture2D = part.layer_icon if part.layer_icon else part.icon
		if layer == null:
			continue
		var image: Image = HiResTexture.full_image(layer)
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		layers.append(image)
		canvas_size = Vector2i(maxi(canvas_size.x, image.get_width()), maxi(canvas_size.y, image.get_height()))
	if layers.is_empty():
		return null
	var canvas: Image = Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	for image in layers:
		# Smaller layers are centered (normally all layers have the canvas size).
		var offset: Vector2i = (canvas_size - image.get_size()) / 2
		canvas.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), offset)
	# Detailed parts (e.g. 32x32 helmet plates) give a detailed item: drawn on half the size.
	var texture: Texture2D = HiResTexture.for_item_icon(ImageTexture.create_from_image(canvas))
	_cache[key] = texture
	return texture
