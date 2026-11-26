class_name JoiningField
extends Control
## Drawing of the workbench minigame (WorkbenchMinigame): both parts swing along curves around
## the same centre (below the field), the upper part (blade, head, plate ...) above, the lower part
## (handle, shaft, leather ...) on a smaller curve, both pointing away from the centre. When the
## upper part comes down it moves straight towards the centre onto the lower part; how far apart
## the two middles are then decides the grade (strip widths green_width / yellow_width, not drawn
## on the item icons or the crystal; only the grey placeholder shapes show them).
## With set_part_icons the parts are the item icons of what is joined (turned upright).
## The minigame sets the angles; this script only draws. Coordinates are for a 200 × 155 field.
## With `crystal_style` (enchanting table, crystal into a staff) the upper part is a gem in
## `crystal_color` and the lower part the round head of the staff (PixelLab, drawn in iron and
## recoloured with the colours of `staff_material` from materials.json); the gem lands in the
## setting in the middle of the head.
## With `bow_style` (bow table, string onto a bow frame) the lower part is the bow frame, drawn as a
## picture (PixelLab, steel, recoloured into `bow_material`), swinging along the lower curve like a handle
## (lower_angle); the upper part is the string, tied to the frame's lower tip: its upper end slides
## along the top and comes down onto the frame's upper tip (string_x, grade from how far apart).

const COLOR_METAL: Color = Color(0.62, 0.63, 0.67)
const COLOR_METAL_DARK: Color = Color(0.3, 0.3, 0.34)
const COLOR_GREEN: Color = TimingBar.COLOR_GREEN
const COLOR_YELLOW: Color = TimingBar.COLOR_YELLOW
const COLOR_FAIL: Color = Color(0.9, 0.3, 0.25)

const FIELD_WIDTH: float = 200.0
## Centre of both swing curves (below the field).
const ARC_CENTER: Vector2 = Vector2(100, 215)
## Upper part: swings along a curve around ARC_CENTER, standing on its lower end (the joint).
const UPPER_TIP_RADIUS: float = 142.0
const BLADE_LENGTH: float = 56.0
## How far the upper part swings to each side (radians).
const UPPER_SWING_HALF_ANGLE: float = 0.36
## Lower part: swings along a smaller curve; its joint lies at LOWER_JOINT_RADIUS.
const LOWER_JOINT_RADIUS: float = 115.0
const LOWER_SWING_HALF_ANGLE: float = 0.42
const GUARD_SIZE: Vector2 = Vector2(52, 7)
const GRIP_LENGTH: float = 24.0
## Crystal style: the staff head (iron) and the gem (white), made by
## assets/_reference/staff_joining/bake.py; centre of the empty setting in the head picture; scale.
const STAFF_HEAD: Texture2D = preload("res://assets/sprites/forging/staff_head.png")
const STAFF_GEM: Texture2D = preload("res://assets/sprites/forging/staff_gem.png")
const STAFF_SETTING: Vector2 = Vector2(11, 11)
const STAFF_SCALE: float = 2.0
## Bow style: the frame's lower tip sits on a ring (BOW_BOTTOM_RADIUS) around ARC_CENTER, its upper
## tip BOW_HEIGHT further out, both turned with lower_angle like a handle. The picture is made by
## assets/_reference/bow_joining/bake.py; BOW_TIP_TOP / BOW_TIP_BOTTOM are its nocks (pixels, one
## above the other), drawn BOW_SCALE times as big. The upper end of the string slides
## BOW_STRING_RANGE to both sides of the upper tip, BOW_STRING_LIFT above it.
const BOW_FRAME: Texture2D = preload("res://assets/sprites/forging/bow_frame.png")
const BOW_TIP_TOP: Vector2 = Vector2(19.5, 2.0)
const BOW_TIP_BOTTOM: Vector2 = Vector2(19.5, 45.0)
const BOW_SCALE: float = 2.0
const BOW_HEIGHT: float = (BOW_TIP_BOTTOM.y - BOW_TIP_TOP.y) * BOW_SCALE
const BOW_BOTTOM_RADIUS: float = 70.0
const BOW_STRING_RANGE: float = 55.0
const BOW_STRING_LIFT: float = 28.0
## The string: dark core with a light strand, tied with a knot at the lower tip.
const COLOR_STRING: Color = Color(0.93, 0.78, 0.52)
const COLOR_STRING_DARK: Color = Color(0.45, 0.3, 0.17)
## Room between a part's yellow strips and its edge.
const PART_MARGIN: float = 3.0
## Item icons of the parts (set_part_icons): turned upright only if their long side is this many
## times longer than their short side (spread of the pixels) and slanted by at least ICON_MIN_TURN;
## a turn this close to a multiple of 45° becomes exactly that (clean diagonals stay clean).
const ICON_ELONGATION: float = 2.0
const ICON_MIN_TURN: float = 0.14
const ICON_SNAP_TURN: float = 0.12
## Both parts are drawn with one whole-number scale (every pixel the same size) up to this,
## as big as fits: the upper part may reach this far above the joint, the lower part this far below.
const ICON_MAX_SCALE: int = 3
const ICON_UPPER_REACH: float = 70.0
const ICON_LOWER_REACH: float = 52.0
## Only one picture (the other missing): its scale range, placed on its own as before.
const ICON_MIN_SCALE: float = 1.0

## Strip widths in pixels (set by the minigame from PlayerStats).
var green_width: float = 6.0
var yellow_width: float = 5.0
## Swing angle of the lower part (0 = straight up, negative = left).
var lower_angle: float = 0.0:
	set(value):
		lower_angle = value
		queue_redraw()
## Swing angle of the upper part.
var upper_angle: float = 0.0:
	set(value):
		upper_angle = value
		queue_redraw()
## 0 = upper part on its curve, 1 = set down on the lower part's curve.
var drop: float = 0.0:
	set(value):
		drop = value
		queue_redraw()
## Crystal into a staff instead of a blade onto a handle (see top).
var crystal_style: bool = false
var crystal_color: Color = Color(0.4, 0.8, 1.0)
## Metal of the staff (materials.json id): colour of the head.
var staff_material: String = "iron":
	set(value):
		staff_material = value
		_staff_head = null
		queue_redraw()
## String onto a bow frame instead of a blade onto a handle (see top).
var bow_style: bool = false
## Material of the bow frame (materials.json id): colour of the frame.
var bow_material: String = "wood":
	set(value):
		bow_material = value
		_bow_frame = null
		queue_redraw()
## How far the middle of the string swings sideways (it twangs after a good hook, set per frame).
var string_wobble: float = 0.0:
	set(value):
		string_wobble = value
		queue_redraw()
## X of the upper end of the string.
var string_x: float = ARC_CENTER.x:
	set(value):
		string_x = value
		queue_redraw()
## false = only the frame is there (first phase), true = the string hangs from its lower tip.
var string_attached: bool = false:
	set(value):
		string_attached = value
		queue_redraw()
## true = the parts did not fit (drawn with a red joint).
var failed: bool = false:
	set(value):
		failed = value
		queue_redraw()
## true = the upper part has come down and sits on the lower part (settle): it takes the lower
## part's angle and is only shifted sideways by `settle_shift` (0 on a perfect hit).
var settled: bool = false:
	set(value):
		settled = value
		queue_redraw()
var settle_shift: float = 0.0

## Item icons of the two parts (set_part_icons): {"texture", "transform"} placing the picture in
## the part's local space (joint at 0, 0); empty = the drawn placeholder shapes. With both pictures
## the two transforms are the same: set down without offset they give the finished item's icon.
var _upper_icon: Dictionary = {}
var _lower_icon: Dictionary = {}
## Size of one picture pixel in the field (whole number with both pictures, else 1).
var _icon_scale: float = 1.0
## Drawing order of the two parts (ItemData.layer_order, like ItemIcons.compose).
var _upper_on_top: bool = true
## STAFF_HEAD in the colours of staff_material (made when first drawn).
var _staff_head: Texture2D
## BOW_FRAME in the colours of bow_material (made when first drawn).
var _bow_frame: Texture2D


## Shows the real pictures of the parts (e.g. copper blade on copper handle) instead of the drawn
## shapes. Pass the pictures at their place on the shared canvas (ItemData.layer_icon, as
## ItemIcons.compose layers them), not the centred inventory icons. Both are turned by the same
## angle, the one that stands the lower part (handle, shaft) upright along its long side (or the
## upper part, if the lower one is not long), and scaled by the same whole number; the joint is the
## top of the lower part. So both parts keep their places from the canvas: set down without offset
## they are exactly the finished item's icon (overlaps and all), a pickaxe head lies across its shaft.
## `upper_on_top`: upper part drawn over the lower one (layer_order). null = keep the drawn shape.
func set_part_icons(upper: Texture2D, lower: Texture2D, upper_on_top: bool = true) -> void:
	_upper_on_top = upper_on_top
	var placed: Dictionary = place_part_icons(upper, lower)
	_upper_icon = placed["upper"]
	_lower_icon = placed["lower"]
	_icon_scale = placed["scale"]
	queue_redraw()


## Placement of both part pictures (see set_part_icons): {"upper", "lower" ({"texture",
## "transform"} or empty), "scale" (size of a picture pixel)}.
static func place_part_icons(upper: Texture2D, lower: Texture2D) -> Dictionary:
	var upper_image: Image = _icon_image(upper)
	var lower_image: Image = _icon_image(lower)
	var upper_pixels: Dictionary = _analyse_icon(upper_image)
	var lower_pixels: Dictionary = _analyse_icon(lower_image)
	var turn: float = float(lower_pixels.get("turn", 0.0))
	if not lower_pixels.get("elongated", false):
		turn = float(upper_pixels.get("turn", 0.0))
	if upper_pixels.is_empty() or lower_pixels.is_empty():
		# Only one picture: placed on its own, as long as the drawn shape.
		return {"upper": _place_icon(upper_pixels, turn, BLADE_LENGTH, true),
				"lower": _place_icon(lower_pixels, turn, GUARD_SIZE.y + GRIP_LENGTH, false), "scale": 1.0}
	# One canvas: a smaller picture sits in the middle of the bigger one (like ItemIcons.compose).
	var canvas: Vector2i = upper_image.get_size().max(lower_image.get_size())
	var upper_offset: Vector2 = (Vector2(canvas - upper_image.get_size()) / 2.0).floor()
	var lower_offset: Vector2 = (Vector2(canvas - lower_image.get_size()) / 2.0).floor()
	var pivot: Vector2 = Vector2(canvas) / 2.0
	# Both parts turned upright around the middle of the canvas.
	var upper_top: float = INF
	var upper_bottom: float = -INF
	for point: Vector2 in upper_pixels["points"]:
		var y: float = (point + upper_offset - pivot).rotated(turn).y
		upper_top = minf(upper_top, y - 0.5)
		upper_bottom = maxf(upper_bottom, y + 0.5)
	var lower_top: float = INF
	var lower_bottom: float = -INF
	var lower_x: float = 0.0
	for point: Vector2 in lower_pixels["points"]:
		var turned: Vector2 = (point + lower_offset - pivot).rotated(turn)
		lower_top = minf(lower_top, turned.y - 0.5)
		lower_bottom = maxf(lower_bottom, turned.y + 0.5)
		lower_x += turned.x
	lower_x /= (lower_pixels["points"] as Array).size()
	# The joint: top of the lower part, in the middle of it. A part lying across the other one
	# (pickaxe head) may reach below it; only what sticks out above / below decides the scale.
	var joint := Vector2(lower_x, lower_top)
	var upper_reach: float = maxf(1.0, joint.y - upper_top)
	var lower_reach: float = maxf(1.0, lower_bottom - joint.y)
	var whole: int = clampi(floori(minf(ICON_UPPER_REACH / upper_reach, ICON_LOWER_REACH / lower_reach)), 1, ICON_MAX_SCALE)
	var icon_scale := float(whole)
	var shared := Transform2D(0.0, Vector2(icon_scale, icon_scale), 0.0, -joint * icon_scale) \
			* Transform2D(turn, Vector2.ZERO) * Transform2D(0.0, -pivot)
	return {"upper": {"texture": ImageTexture.create_from_image(upper_pixels["image"]),
				"transform": shared * Transform2D(0.0, upper_offset)},
			"lower": {"texture": ImageTexture.create_from_image(lower_pixels["image"]),
				"transform": shared * Transform2D(0.0, lower_offset)},
			"scale": icon_scale}


## Full picture of an icon as RGBA8 (all pixels of a HiResTexture), null = none.
static func _icon_image(texture: Texture2D) -> Image:
	if texture == null:
		return null
	var image: Image = HiResTexture.full_image(texture)
	if image == null:
		return null
	image = image.duplicate()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	return image


## Opaque pixels of a picture: {"image", "points", "center", "elongated" (long side clearly longer),
## "turn" (angle that makes the long side point up)}; empty = no picture.
static func _analyse_icon(image: Image) -> Dictionary:
	if image == null:
		return {}
	var points: Array[Vector2] = []
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				points.append(Vector2(x + 0.5, y + 0.5))
	if points.size() < 2:
		return {}
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= points.size()
	# Covariance of the pixels: its main axis is the long side of the picture.
	var xx: float = 0.0
	var yy: float = 0.0
	var xy: float = 0.0
	for point in points:
		var d: Vector2 = point - center
		xx += d.x * d.x
		yy += d.y * d.y
		xy += d.x * d.y
	var spread: float = sqrt(pow(xx - yy, 2.0) + 4.0 * xy * xy)
	var elongated: bool = (xx + yy + spread) > ICON_ELONGATION * (xx + yy - spread)
	var turn: float = 0.0
	if elongated:
		var axis := Vector2.from_angle(0.5 * atan2(2.0 * xy, xx - yy))
		if axis.y > 0.0:
			axis = -axis
		turn = -PI / 2.0 - axis.angle()
		var eighth: float = snappedf(turn, PI / 4.0)
		if absf(turn - eighth) < ICON_SNAP_TURN:
			turn = eighth
		if absf(turn) < ICON_MIN_TURN:
			turn = 0.0
	return {"image": image, "points": points, "center": center, "elongated": elongated, "turn": turn}


## Placement of an analysed icon turned by `turn`, scaled to `length` along "up", the joint end at
## (0, 0): the bottom end for the upper part, the top end otherwise.
static func _place_icon(pixels: Dictionary, turn: float, length: float, joint_at_bottom: bool) -> Dictionary:
	if pixels.is_empty():
		return {}
	var center: Vector2 = pixels["center"]
	var top: float = INF
	var bottom: float = -INF
	for point: Vector2 in pixels["points"]:
		var y: float = (point - center).rotated(turn).y
		top = minf(top, y - 0.5)
		bottom = maxf(bottom, y + 0.5)
	var icon_scale: float = clampf(length / (bottom - top), ICON_MIN_SCALE, ICON_MAX_SCALE)
	var shift := Vector2(0, -bottom * icon_scale if joint_at_bottom else -top * icon_scale)
	var placement := Transform2D(turn, Vector2(icon_scale, icon_scale), 0.0, shift) * Transform2D(0.0, -center)
	return {"texture": ImageTexture.create_from_image(pixels["image"]), "transform": placement}


## Sideways distance between the middles of both parts where they meet (what the grade depends on).
func get_joint_offset() -> float:
	if bow_style:
		return string_x - get_bow_tips()[0].x
	return (upper_angle - lower_angle) * LOWER_JOINT_RADIUS


## The upper part has come down (not for the bow): it takes the lower part's angle, so both pictures
## line up pixel for pixel; `perfect` = no offset at all, else the real sideways offset, rounded to
## whole picture pixels (one sees how far off it was).
func settle(perfect: bool) -> void:
	settle_shift = 0.0 if perfect else roundf(get_joint_offset() / _icon_scale) * _icon_scale
	settled = true


## Bow style: from where to where the upper end of the string slides (x, around the frame).
func get_string_range() -> Vector2:
	var tip_x: float = get_bow_tips()[0].x
	return Vector2(maxf(4.0, tip_x - BOW_STRING_RANGE), minf(FIELD_WIDTH - 4.0, tip_x + BOW_STRING_RANGE))


## Bow style: [upper tip, lower tip] of the frame (field coordinates).
func get_bow_tips() -> Array[Vector2]:
	return [_on_ring(BOW_BOTTOM_RADIUS + BOW_HEIGHT, lower_angle), _on_ring(BOW_BOTTOM_RADIUS, lower_angle)]


func _draw() -> void:
	if bow_style:
		_draw_bow()
		return
	if _upper_on_top:
		_draw_lower_part()
		_draw_upper_part()
	else:
		_draw_upper_part()
		_draw_lower_part()


func _draw_lower_part() -> void:
	var half: float = _get_part_half_width()
	# Local space: the joint at (0, 0), the grip hangs down (+y) towards the centre.
	draw_set_transform(_on_ring(LOWER_JOINT_RADIUS, lower_angle), lower_angle)
	if crystal_style:
		_draw_staff_top(half)
		draw_set_transform(Vector2.ZERO)
		return
	if not _lower_icon.is_empty():
		_draw_icon(_lower_icon, _on_ring(LOWER_JOINT_RADIUS, lower_angle), lower_angle)
		draw_set_transform(Vector2.ZERO)
		return
	var guard := Rect2(-GUARD_SIZE.x / 2.0, 0, GUARD_SIZE.x, GUARD_SIZE.y)
	var grip := Rect2(-half, GUARD_SIZE.y, half * 2.0, GRIP_LENGTH)
	for rect: Rect2 in [guard, grip]:
		draw_rect(rect, COLOR_METAL)
		draw_rect(rect, COLOR_METAL_DARK, false, 1.0)
	_draw_strips(1.0, GUARD_SIZE.y + GRIP_LENGTH - 1.0)
	draw_set_transform(Vector2.ZERO)


func _draw_upper_part() -> void:
	var half: float = _get_part_half_width()
	var radius: float = lerpf(UPPER_TIP_RADIUS, LOWER_JOINT_RADIUS, ease(drop, 2.0))
	var angle: float = upper_angle
	var joint: Vector2 = _on_ring(radius, upper_angle)
	if settled:
		# sitting on the lower part: its angle, shifted along its crosswise axis
		angle = lower_angle
		joint = _on_ring(LOWER_JOINT_RADIUS, lower_angle) + Vector2.from_angle(lower_angle) * settle_shift
	# Local space: the joint at (0, 0), the part points up (-y), away from the centre.
	draw_set_transform(joint, angle)
	if crystal_style:
		_draw_crystal(half)
	elif not _upper_icon.is_empty():
		_draw_icon(_upper_icon, joint, angle)
	else:
		var shape := PackedVector2Array([Vector2(-half, 0), Vector2(half, 0), Vector2(half, -BLADE_LENGTH + half),
				Vector2(0, -BLADE_LENGTH), Vector2(-half, -BLADE_LENGTH + half)])
		draw_colored_polygon(shape, COLOR_METAL)
		shape.append(shape[0])
		draw_polyline(shape, COLOR_METAL_DARK, 1.0)
		_draw_strips(-BLADE_LENGTH + half + 2.0, -1.0)
	if drop >= 1.0 and failed:
		draw_line(Vector2(-half - 4.0, 0), Vector2(half + 4.0, 0), COLOR_FAIL, 2.0)
	draw_set_transform(Vector2.ZERO)


## Draws a part icon (set_part_icons) at the part's joint `at`, turned by `angle`; afterwards
## the transform is the part's local space again (for the strips).
func _draw_icon(icon: Dictionary, at: Vector2, angle: float) -> void:
	var local := Transform2D(angle, at)
	draw_set_transform_matrix(local * (icon["transform"] as Transform2D))
	draw_texture(icon["texture"], Vector2.ZERO)
	draw_set_transform_matrix(local)


## Bow style: the frame as a curve with a knob at each tip, the string from the lower tip to its
## upper end (coming down onto the upper tip with `drop`).
func _draw_bow() -> void:
	if _bow_frame == null:
		_bow_frame = recolor_metal(BOW_FRAME, bow_material)
	var tips: Array[Vector2] = get_bow_tips()
	draw_set_transform(tips[1], lower_angle, Vector2(BOW_SCALE, BOW_SCALE))
	draw_texture(_bow_frame, -BOW_TIP_BOTTOM)
	draw_set_transform(Vector2.ZERO)
	if not string_attached:
		return
	var top := Vector2(string_x, lerpf(tips[0].y - BOW_STRING_LIFT, tips[0].y, ease(drop, 2.0)))
	var along: Vector2 = top - tips[1]
	var middle: Vector2 = tips[1] + along / 2.0 + along.orthogonal().normalized() * string_wobble
	var line := PackedVector2Array([tips[1], middle, top])
	draw_polyline(line, COLOR_STRING_DARK, 3.0)
	draw_polyline(line, COLOR_STRING, 1.0)
	# knot at the lower nock, loop at the upper end
	draw_circle(tips[1], 2.5, COLOR_STRING_DARK)
	draw_circle(tips[1], 1.2, COLOR_STRING)
	draw_arc(top, 2.5, 0.0, TAU, 10, COLOR_STRING_DARK, 1.5)
	if drop >= 1.0 and failed:
		draw_line(top - Vector2(6, 0), top + Vector2(6, 0), COLOR_FAIL, 2.0)


## Upper part in crystal style: the gem, its middle at the joint (local space).
func _draw_crystal(_half: float) -> void:
	var gem_size: Vector2 = STAFF_GEM.get_size() * STAFF_SCALE
	draw_texture_rect(STAFF_GEM, Rect2(-gem_size / 2.0, gem_size), false, crystal_color)


## Lower part in crystal style: the head of the staff, the middle of its setting at the joint, the rod
## hanging down towards the centre (local space).
func _draw_staff_top(_half: float) -> void:
	if _staff_head == null:
		_staff_head = recolor_metal(STAFF_HEAD, staff_material)
	draw_texture_rect(_staff_head, Rect2(-STAFF_SETTING * STAFF_SCALE, _staff_head.get_size() * STAFF_SCALE), false)


## An iron picture in the colours of another metal (materials.json "colors", 5 shades light » dark):
## every greyish pixel takes the shade of `material_id` at the place of the nearest iron shade (by
## brightness); outline and coloured pixels stay. Unknown material = the picture as it is.
static func recolor_metal(texture: Texture2D, material_id: String) -> Texture2D:
	var iron: Array = ContentDB.material_colors("iron")
	var target: Array = ContentDB.material_colors(material_id)
	if material_id == "iron" or iron.size() != 5 or target.size() != 5:
		return texture
	# a copy: get_image() may hand out the texture's own image
	var image: Image = texture.get_image().duplicate()
	image.convert(Image.FORMAT_RGBA8)
	var iron_light: Array[float] = []
	for color: String in iron:
		iron_light.append(Color(color).get_luminance())
	for y in image.get_height():
		for x in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a <= 0.0 or maxf(pixel.r, maxf(pixel.g, pixel.b)) - minf(pixel.r, minf(pixel.g, pixel.b)) > 40.0 / 255.0:
				continue
			var light: float = pixel.get_luminance()
			if light < 40.0 / 255.0:
				continue  # outline
			var best: int = 0
			for i in 5:
				if absf(iron_light[i] - light) < absf(iron_light[best] - light):
					best = i
			var shade := Color(target[best] as String)
			shade.a = pixel.a
			image.set_pixel(x, y, shade)
	return ImageTexture.create_from_image(image)


## Green strip in the middle, yellow strips on both sides, from y `from` to y `to` (local).
func _draw_strips(from: float, to: float) -> void:
	var top: float = minf(from, to)
	var height: float = absf(to - from)
	var yellow_half: float = green_width / 2.0 + yellow_width
	draw_rect(Rect2(-yellow_half, top, yellow_half * 2.0, height), COLOR_YELLOW)
	draw_rect(Rect2(-green_width / 2.0, top, green_width, height), COLOR_GREEN)


func _get_part_half_width() -> float:
	return green_width / 2.0 + yellow_width + PART_MARGIN


## Point on a ring around ARC_CENTER (angle 0 = straight up).
func _on_ring(radius: float, angle: float) -> Vector2:
	return ARC_CENTER + Vector2(sin(angle), -cos(angle)) * radius
