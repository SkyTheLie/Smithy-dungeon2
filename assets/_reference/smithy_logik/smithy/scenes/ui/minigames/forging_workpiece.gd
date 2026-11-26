class_name ForgingWorkpiece
extends Control
## The glowing workpiece of the forging minigame and its strike spots: the current one green and
## pulsing, the coming ones as faint rings, the struck ones marked (green = hit, yellow = half,
## red = missed).
## The picture is the icon of the item being forged (e.g. the copper pickaxe head), as big as fits
## in whole pixels: it starts red-hot and cools a bit with every strike, until the finished piece
## shows its real colours (set_cooling). The spots are spread over the icon (_spots_on_icon).
## Items without an own icon use their ForgingPattern instead (glowing picture + spots from
## forging_patterns.json, drawn SCALE times as big).
## The spots light up in a random order (new for every forging, never the same spot twice in a
## row), so the player can't learn the sequence by heart.
## A left click emits `struck` with whether it was inside the current spot. On the phone the spots
## are bigger and a tap counts a bit around them (MobileUi).
## Every strike gets some weight (burst): sparks fly from the spot, its quality points float up,
## and the picture shakes a little (strong on green, weak on yellow, a dull jolt on a miss).

signal struck(on_spot: bool)

## Size of the pattern pictures (no icon) on screen.
const SCALE: float = 2.0
## Room kept free around the icon (anvil face below, frame at the sides).
const ICON_MARGIN: Vector2 = Vector2(16, 18)
## Spots spread over an icon and their size on screen.
const ICON_SPOT_COUNT: int = 5
const ICON_SPOT_SIZE: Vector2 = Vector2(16, 14)
## Icon pixels with fewer opaque neighbours (of 8) are edges and get no spot.
const ICON_SPOT_NEIGHBOURS: int = 6
## Glow colours of the hot icon, from dark to bright parts.
const HEAT_MID: Color = ItemIcons.HEAT_MID
const HEAT_BRIGHT: Color = ItemIcons.HEAT_BRIGHT
const COOL_SECONDS: float = 0.35
const POP_DURATION: float = 0.12
const PULSE_SPEED: float = 6.0
const COLOR_BACKGROUND: Color = Color(0.2, 0.19, 0.22)
const COLOR_ANVIL: Color = Color(0.35, 0.35, 0.4)
const COLOR_SPOT: Color = Color(0.35, 0.85, 0.35)
const COLOR_SPOT_BORDER: Color = Color(0.1, 0.35, 0.12)
const COLOR_UPCOMING: Color = Color(0.35, 0.85, 0.35, 0.35)
const COLOR_HIT: Color = Color(0.45, 1.0, 0.45, 0.8)
const COLOR_HALF: Color = Color(1.0, 0.85, 0.3, 0.8)
const COLOR_MISS: Color = Color(1.0, 0.3, 0.25, 0.8)
const COLOR_FLASH: Color = Color(1.6, 1.4, 1.2)
## Sparks per strike (green, yellow), how long they live, their speed and how fast they fall.
const SPARKS_GREEN: int = 16
const SPARKS_YELLOW: int = 7
const SPARK_SECONDS: float = 0.45
const SPARK_SPEED: Vector2 = Vector2(50, 130)
const SPARK_GRAVITY: float = 320.0
## Shake of the picture in pixels per zone (green, yellow, miss) and how fast it settles (per second).
const SHAKE_GREEN: float = 3.0
const SHAKE_YELLOW: float = 1.5
const SHAKE_MISS: float = 1.0
const SHAKE_DECAY: float = 14.0
## Floating texts (quality points, combo): seconds on screen and how far they rise.
const FLOAT_SECONDS: float = 0.8
const FLOAT_RISE: float = 18.0
const FONT_SIZE: int = 11

## Glowing picture (hot icon or pattern image) and, for an icon, the cold one in real colours.
var _hot: Texture2D
var _cold: Texture2D
## Screen pixels per picture pixel.
var _scale: float = SCALE
## Strike spots in pixels of the picture.
var _spots: Array[Rect2] = []
## 0 = glowing, 1 = cooled to the real colours (only with an icon).
var _cooling: float = 0.0
## Index of the spot to strike now (-1 = none).
var _current: int = -1
## How many strikes this forging has in total (spots after the last one are faint rings).
var _strike_count: int = 0
## Strike index -> spot index (random order, see _roll_order).
var _order: Array[int] = []
## Strike index -> TimingBar.Zone of the strikes done.
var _results: Dictionary = {}
var _time: float = 0.0
## 0..1 while the current spot pops up.
var _pop: float = 1.0
var _flash: Color = Color.WHITE
## Flying sparks: {"pos", "vel", "age"} in screen pixels.
var _sparks: Array[Dictionary] = []
## Floating texts: {"pos", "text", "color", "age"}.
var _floats: Array[Dictionary] = []
## Current shake strength in pixels (settles to 0).
var _shake: float = 0.0


## The piece to forge: the icon of `item` if it has one, otherwise the glowing `pattern`.
func set_item(item: ItemData, pattern: ForgingPattern, strike_count: int) -> void:
	_strike_count = strike_count
	_cooling = 0.0
	_cold = null
	var icon: Image = _icon_image(item)
	if icon:
		_cold = ImageTexture.create_from_image(icon)
		_hot = ImageTexture.create_from_image(_heated(icon))
		var room: Vector2 = custom_minimum_size.max(size) - ICON_MARGIN
		_scale = maxf(1.0, floorf(minf(room.x / icon.get_width(), room.y / icon.get_height())))
		_spots = _spots_on_icon(icon)
	else:
		_hot = pattern.image if pattern else null
		_scale = SCALE
		_spots = pattern.spots.duplicate() if pattern else []
	_roll_order()
	_results.clear()
	_sparks.clear()
	_floats.clear()
	_shake = 0.0
	_current = -1
	queue_redraw()


## How far the piece has cooled (0..1), shown with a short fade.
func set_cooling(value: float) -> void:
	create_tween().tween_property(self, "_cooling", clampf(value, 0.0, 1.0), COOL_SECONDS)


## Lights up the spot of strike `index` (with a short pop-up).
func show_strike(index: int) -> void:
	_current = index
	_pop = 0.0
	queue_redraw()


## Where the spot of strike `index` lies, in the coordinates of this Control (ForgingTutorial).
func get_spot_rect(index: int) -> Rect2:
	return _screen_spot(index)


func hide_strike() -> void:
	_current = -1
	queue_redraw()


## Marks a done strike (TimingBar.Zone) and lets the iron flash on a hit.
func mark(index: int, zone: TimingBar.Zone) -> void:
	_results[index] = zone
	if zone != TimingBar.Zone.MISS:
		_flash = COLOR_FLASH
		create_tween().tween_property(self, "_flash", Color.WHITE, 0.15)
	queue_redraw()


## Weight of strike `index`: sparks from its spot, its quality `points` floating up and a shake;
## from `combo` 2 on (green strikes in a row) also "x2", "x3" ...
func burst(index: int, zone: TimingBar.Zone, points: int, combo: int) -> void:
	var center: Vector2 = _screen_spot(index).get_center()
	var count: int = SPARKS_GREEN if zone == TimingBar.Zone.GREEN else (SPARKS_YELLOW if zone == TimingBar.Zone.YELLOW else 0)
	for i in count:
		# Mostly upwards, spread to both sides.
		var angle: float = -PI / 2.0 + randf_range(-1.2, 1.2)
		_sparks.append({"pos": center, "vel": Vector2.from_angle(angle) * randf_range(SPARK_SPEED.x, SPARK_SPEED.y), "age": 0.0})
	var color: Color = COLOR_HIT if zone == TimingBar.Zone.GREEN else (COLOR_HALF if zone == TimingBar.Zone.YELLOW else COLOR_MISS)
	_floats.append({"pos": center + Vector2(0, -10), "text": "%+d" % points, "color": Color(color, 1.0), "age": 0.0})
	if combo >= 2:
		_floats.append({"pos": center + Vector2(0, -22), "text": "x%d" % combo, "color": HEAT_BRIGHT, "age": 0.0})
	_shake = SHAKE_GREEN if zone == TimingBar.Zone.GREEN else (SHAKE_YELLOW if zone == TimingBar.Zone.YELLOW else SHAKE_MISS)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_pop = minf(_pop + delta / POP_DURATION, 1.0)
	_shake = maxf(0.0, _shake - SHAKE_DECAY * delta)
	for spark in _sparks:
		spark["age"] += delta
		spark["vel"] += Vector2(0, SPARK_GRAVITY * delta)
		spark["pos"] += spark["vel"] * delta
	_sparks.assign(_sparks.filter(func(spark: Dictionary) -> bool: return spark["age"] < SPARK_SECONDS))
	for text in _floats:
		text["age"] += delta
	_floats.assign(_floats.filter(func(text: Dictionary) -> bool: return text["age"] < FLOAT_SECONDS))
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and _current >= 0:
		var spot: Rect2 = _screen_spot(_current)
		# Phone: a finger is less exact than a mouse, a tap a bit outside the spot still counts.
		if MobileUi.active():
			spot = _scaled(spot, MobileUi.FORGE_HIT_SCALE)
		struck.emit(_is_inside(spot, click.position))
		accept_event()


# --- Picture ------------------------------------------------------------------------

## The item's own icon, cut to its used pixels (null = none, use the pattern).
static func _icon_image(item: ItemData) -> Image:
	if item == null or item.icon == null or item.layer_icon and item.layer_icon.resource_path == ContentDB.DEFAULT_ITEM_ICON:
		return null
	var image: Image = HiResTexture.full_image(item.icon)
	if image == null:
		return null
	image = image.duplicate()
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var used: Rect2i = image.get_used_rect()
	return image.get_region(used) if used.has_area() else null


## The icon glowing (ItemIcons.heated_image).
static func _heated(icon: Image) -> Image:
	return ItemIcons.heated_image(icon)


## ICON_SPOT_COUNT spots spread over the icon: inner pixels (enough opaque neighbours), each new
## one as far as possible from the ones taken (the first one random).
func _spots_on_icon(icon: Image) -> Array[Rect2]:
	var inner: Array[Vector2] = []
	var opaque: Array[Vector2] = []
	for y in icon.get_height():
		for x in icon.get_width():
			if icon.get_pixel(x, y).a < 0.5:
				continue
			var center := Vector2(x + 0.5, y + 0.5)
			opaque.append(center)
			if _opaque_neighbours(icon, x, y) >= ICON_SPOT_NEIGHBOURS:
				inner.append(center)
	var candidates: Array[Vector2] = inner if inner.size() >= ICON_SPOT_COUNT else opaque
	var centers: Array[Vector2] = []
	if not candidates.is_empty():
		centers.append(candidates.pick_random())
	while centers.size() < mini(ICON_SPOT_COUNT, candidates.size()):
		var best: Vector2 = candidates[0]
		var best_distance: float = -1.0
		for point in candidates:
			var nearest: float = INF
			for taken in centers:
				nearest = minf(nearest, point.distance_squared_to(taken))
			if nearest > best_distance:
				best_distance = nearest
				best = point
		centers.append(best)
	var spot_size: Vector2 = ICON_SPOT_SIZE / _scale
	var spots: Array[Rect2] = []
	for center in centers:
		spots.append(Rect2(center - spot_size / 2.0, spot_size))
	return spots


static func _opaque_neighbours(icon: Image, x: int, y: int) -> int:
	var count: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx: int = x + dx
			var ny: int = y + dy
			if (dx != 0 or dy != 0) and nx >= 0 and ny >= 0 and nx < icon.get_width() and ny < icon.get_height() \
					and icon.get_pixel(nx, ny).a >= 0.5:
				count += 1
	return count


# --- Drawing ------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	# Everything but the background shakes after a strike.
	if _shake > 0.0:
		draw_set_transform(Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)).round())
	# Anvil face under the workpiece.
	draw_rect(Rect2(Vector2(8, size.y - 10), Vector2(size.x - 16, 10)), COLOR_ANVIL)
	if _hot == null:
		return
	var picture := Rect2(_origin(), _picture_size() * _scale)
	draw_texture_rect(_hot, picture, false, _flash)
	if _cold and _cooling > 0.0:
		draw_texture_rect(_cold, picture, false, Color(1, 1, 1, _cooling))
	# Coming spots (only as many as there are strikes), then the done ones, then the current one.
	for i in range(_strike_count):
		if i != _current and not _results.has(i) and i < _spots.size():
			_draw_ellipse(_screen_spot(i), COLOR_UPCOMING, false)
	for i: int in _results:
		var zone: TimingBar.Zone = _results[i]
		var color: Color = COLOR_HIT if zone == TimingBar.Zone.GREEN else (COLOR_HALF if zone == TimingBar.Zone.YELLOW else COLOR_MISS)
		_draw_ellipse(_screen_spot(i).grow(-2.0), color, false)
	if _current >= 0:
		var spot: Rect2 = _screen_spot(_current)
		var grow: float = sin(_time * PULSE_SPEED) * 1.0
		spot = Rect2(spot.get_center() - spot.size * _pop / 2.0, spot.size * _pop).grow(grow)
		_draw_ellipse(spot, COLOR_SPOT, true)
		_draw_ellipse(spot, COLOR_SPOT_BORDER, false)
	_draw_effects()


## Sparks (bright, cooling to orange) and the floating texts, on top of everything.
func _draw_effects() -> void:
	draw_set_transform(Vector2.ZERO)
	for spark in _sparks:
		var life: float = float(spark["age"]) / SPARK_SECONDS
		var color: Color = HEAT_BRIGHT.lerp(HEAT_MID, life)
		color.a = 1.0 - life * life
		draw_rect(Rect2((spark["pos"] as Vector2).round(), Vector2(2, 2) if life < 0.5 else Vector2.ONE), color)
	var font: Font = get_theme_default_font()
	for text in _floats:
		var life: float = float(text["age"]) / FLOAT_SECONDS
		var color: Color = text["color"]
		color.a = 1.0 if life < 0.6 else 1.0 - (life - 0.6) / 0.4
		var pos: Vector2 = (text["pos"] as Vector2 + Vector2(-20, -FLOAT_RISE * life)).round()
		draw_string_outline(font, pos, text["text"], HORIZONTAL_ALIGNMENT_CENTER, 40, FONT_SIZE, 3, Color(0, 0, 0, color.a))
		draw_string(font, pos, text["text"], HORIZONTAL_ALIGNMENT_CENTER, 40, FONT_SIZE, color)


## Random spot for every strike: each spot once in random order; with more strikes than spots
## it starts over (shuffled again), but never with the spot that was just struck.
func _roll_order() -> void:
	_order.clear()
	var spot_count: int = _spots.size()
	if spot_count == 0:
		return
	var round_spots: Array[int] = []
	while _order.size() < _strike_count:
		if round_spots.is_empty():
			for i in spot_count:
				round_spots.append(i)
			round_spots.shuffle()
			if spot_count > 1 and not _order.is_empty() and round_spots[0] == _order.back():
				round_spots.reverse()
		_order.append(round_spots.pop_front())


## Picture size in its own pixels (the icon, or ForgingPattern.IMAGE_SIZE for a pattern).
func _picture_size() -> Vector2:
	return _cold.get_size() if _cold else ForgingPattern.IMAGE_SIZE


## Top left corner of the picture (an icon centred above the anvil face, a pattern centred).
func _origin() -> Vector2:
	var area := Vector2(size.x, size.y - 10.0) if _cold else size
	return ((area - _picture_size() * _scale) / 2.0).round()


## Spot of strike `index` on screen (on the phone MobileUi.FORGE_SPOT_SCALE times as big, same centre).
func _screen_spot(index: int) -> Rect2:
	var spot := Rect2(_picture_size() / 2.0 - Vector2(4, 4), Vector2(8, 8))
	if not _spots.is_empty():
		spot = _spots[(_order[index] if index < _order.size() else index) % _spots.size()]
	var on_screen := Rect2(_origin() + spot.position * _scale, spot.size * _scale)
	if MobileUi.active():
		on_screen = _scaled(on_screen, MobileUi.FORGE_SPOT_SCALE)
	return on_screen


## The lit spot on screen (local to this control); empty if none is lit.
func get_current_spot() -> Rect2:
	return _screen_spot(_current) if _current >= 0 else Rect2()


## `rect` `factor` times as big around the same centre.
static func _scaled(rect: Rect2, factor: float) -> Rect2:
	var grown: Vector2 = rect.size * factor
	return Rect2(rect.get_center() - grown / 2.0, grown)


func _is_inside(spot: Rect2, point: Vector2) -> bool:
	var radius: Vector2 = spot.size / 2.0
	var offset: Vector2 = (point - spot.get_center()) / radius
	return offset.length_squared() <= 1.0


func _draw_ellipse(rect: Rect2, color: Color, filled: bool) -> void:
	# The current spot starts at size 0 when it pops up (nothing to draw yet).
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	var points := PackedVector2Array()
	var steps: int = 20
	for i in steps + 1:
		var angle: float = TAU * i / steps
		points.append(rect.get_center() + Vector2(cos(angle) * rect.size.x / 2.0, sin(angle) * rect.size.y / 2.0))
	if filled:
		draw_colored_polygon(points, color)
	else:
		draw_polyline(points, color, 1.0)
