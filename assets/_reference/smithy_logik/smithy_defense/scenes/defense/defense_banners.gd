class_name DefenseBanners
extends Node2D
## The buildings (tavern, barracks, temple; defense.json buildings) as banners at the smithy instead
## of small houses: a pole with a cloth in the building's colour and its crystal on it, at its foot
## a ring that fills until the next crystal comes. When one comes the banner flares up (`flash`).
## A child of the smithy picture: positions are relative to the smithy. Drawn in one _draw.

## Where the banners stand (feet), in the order the buildings are built.
const SPOTS: Array[Vector2] = [Vector2(-64, 30), Vector2(64, 30), Vector2(0, 60)]
const POLE_HEIGHT: float = 42.0
const POLE := Color(0.32, 0.2, 0.12)
const KNOB := Color(1.0, 0.82, 0.35)
const RING_RADIUS: float = 9.0
const RING_BACK := Color(0, 0, 0, 0.45)
const ICON_SIZE: float = 11.0
const FLASH_TIME: float = 0.6

## Each banner: [colour, crystal icon (or null for a random one), filled part 0..1, flash left].
var _banners: Array[Array] = []


## The built buildings: one [colour, icon] per building, in SPOTS order (more than SPOTS: the rest
## is not shown).
func set_buildings(entries: Array) -> void:
	_banners.clear()
	for entry: Array in entries.slice(0, SPOTS.size()):
		_banners.append([entry[0], entry[1], 1.0, 0.0])
	queue_redraw()


func count() -> int:
	return _banners.size()


## How full the ring of banner `index` is (0 = just fired, 1 = next crystal now).
func set_part(index: int, part: float) -> void:
	if index >= 0 and index < _banners.size():
		_banners[index][2] = clampf(part, 0.0, 1.0)


## The building laid a crystal: its banner flares up.
func flash(index: int) -> void:
	if index >= 0 and index < _banners.size():
		_banners[index][3] = FLASH_TIME


## Where the crystal of banner `index` starts its flight (top of the cloth), relative to the smithy.
func banner_top(index: int) -> Vector2:
	return SPOTS[clampi(index, 0, SPOTS.size() - 1)] + Vector2(8, -POLE_HEIGHT)


func _process(delta: float) -> void:
	if _banners.is_empty():
		return
	for banner: Array in _banners:
		banner[3] = maxf(float(banner[3]) - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	for i in _banners.size():
		var foot: Vector2 = SPOTS[i]
		var color: Color = _banners[i][0]
		var icon: Texture2D = _banners[i][1]
		var part: float = _banners[i][2]
		var glow: float = float(_banners[i][3]) / FLASH_TIME
		var top: Vector2 = foot + Vector2(0, -POLE_HEIGHT)
		# Ring at the foot (flat ellipse): dark, filling clockwise in the banner's colour.
		draw_set_transform(foot, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 24, RING_BACK, 3.0)
		if part > 0.0:
			draw_arc(Vector2.ZERO, RING_RADIUS, -PI / 2.0, -PI / 2.0 + TAU * part, 24, color.lightened(0.2), 2.5)
		if glow > 0.0:
			draw_circle(Vector2.ZERO, RING_RADIUS * (1.0 + glow), Color(color, 0.35 * glow))
		draw_set_transform(Vector2.ZERO)
		# Pole with a golden knob.
		draw_line(foot, top, POLE, 2.0)
		draw_circle(top, 2.0, KNOB)
		# Cloth with a swallowtail, brighter while it flares.
		var cloth: Color = color.lerp(Color.WHITE, 0.6 * glow)
		var x0: float = top.x + 1.0
		var points := PackedVector2Array([Vector2(x0, top.y + 2), Vector2(x0 + 16, top.y + 2), Vector2(x0 + 16, top.y + 26),
				Vector2(x0 + 8, top.y + 21), Vector2(x0, top.y + 26)])
		draw_colored_polygon(points, cloth.darkened(0.15))
		points.append(points[0])
		draw_polyline(points, cloth.darkened(0.55), 1.0)
		var middle := Vector2(x0 + 8, top.y + 12)
		if icon != null:
			draw_texture_rect(icon, Rect2(middle - Vector2(ICON_SIZE, ICON_SIZE) / 2.0, Vector2(ICON_SIZE, ICON_SIZE)), false)
		else:
			# A random crystal (tavern): a white diamond.
			draw_colored_polygon(PackedVector2Array([middle + Vector2(0, -5), middle + Vector2(4, 0), middle + Vector2(0, 5),
					middle + Vector2(-4, 0)]), Color(1, 1, 1, 0.9))
