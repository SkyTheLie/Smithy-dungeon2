class_name CrystalMapView
extends Control
## The world map, painted with PixelLab (ui/world_map_painted.png, layout from world_map.json after
## the sketch weltmap.png): the land of the humans with the village and Leonheim, the Lavaberg in the
## north, the land of the half-demons with the Finsterburg, the swamp below it, the elves' forest, the
## water people's coast with the ice wall in the east and the desert in the south.
## Every region shows up once the player has its map piece (region "flag", story flags map_piece_1
## to map_piece_5); regions still missing are covered with blank parchment (ui/world_map_parchment.png)
## and a question mark. Places the painting doesn't show (towns, castles, huts ...) and the element crystals (lost = crossed out, found = ring) are drawn on the regions that show.
## Teleport mode (TeleportMenu): set_spots() puts a crystal on the map for every awake teleporter,
## the mouse picks one (spot_hovered / spot_pressed); spots show even on regions still missing.

signal spot_hovered(spot_id: String)
signal spot_pressed(spot_id: String)

const MAP_WIDTH: float = 300.0
const PARCHMENT: Texture2D = preload("res://assets/sprites/ui/world_map_parchment.png")
const PAINTED: Texture2D = preload("res://assets/sprites/ui/world_map_painted.png")
## Place kinds the painted map already shows (no extra marker on top).
const PAINTED_KINDS: Array[String] = ["volcano", "forest", "tree", "dunes", "waves", "ice_wall"]
const COLOR_PARCHMENT: Color = Color(0.86, 0.78, 0.6)
const COLOR_PARCHMENT_DARK: Color = Color(0.62, 0.52, 0.36)
const COLOR_INK: Color = Color(0.25, 0.18, 0.12)
const COLOR_SPOT: Color = Color(0.45, 0.95, 1.0)
const COLOR_SPOT_OFF: Color = Color(0.5, 0.55, 0.6)
## How close (view pixels) the mouse has to be to pick a teleporter spot.
const PICK_DISTANCE: float = 9.0
const FONT_SIZE: int = 11

## Teleport mode: [{"id", "at" (map units), "enabled"}]; empty = the plain crystal map.
var _spots: Array[Dictionary] = []
var _hovered: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(MAP_WIDTH, MAP_WIDTH * get_map_size().y / get_map_size().x).round()
	mouse_filter = Control.MOUSE_FILTER_STOP if not _spots.is_empty() else Control.MOUSE_FILTER_IGNORE


static func data() -> Dictionary:
	return ContentDB.world_map()


static func get_map_size() -> Vector2:
	var size_entry: Array = data().get("size", [1180, 600])
	return Vector2(size_entry[0], size_entry[1])


## true once the player has the map piece of the region.
static func is_region_shown(region_id: String) -> bool:
	var region: Dictionary = data().get("regions", {}).get(region_id, {})
	return not region.is_empty() and GameState.story.has_flag(str(region.get("flag", "")))


## Map pieces in the game and how many of them the player has (one flag can show several regions).
static func count_pieces() -> int:
	return _piece_flags().filter(func(flag: String) -> bool: return GameState.story.has_flag(flag)).size()


static func total_pieces() -> int:
	return _piece_flags().size()


static func _piece_flags() -> Array[String]:
	var flags: Array[String] = []
	for region: Dictionary in data().get("regions", {}).values():
		var flag: String = str(region.get("flag", ""))
		if not flag.is_empty() and not flags.has(flag):
			flags.append(flag)
	return flags


static func flag_set(flag: String) -> bool:
	return not flag.is_empty() and GameState.story.has_flag(flag)


static func is_owned(crystal: Dictionary) -> bool:
	return flag_set(str(crystal.get("owned_flag", ""))) and not flag_set(str(crystal.get("gone_flag", "")))


## The crystals on regions the player can see, in file order.
static func shown_crystals() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for crystal: Dictionary in data().get("crystals", []):
		if is_region_shown(str(crystal.get("region", ""))):
			result.append(crystal)
	return result


## Teleport mode: the spots to show ([{"id", "at": Vector2 in map units, "enabled": bool}]).
func set_spots(spots: Array[Dictionary]) -> void:
	_spots = spots
	_hovered = ""
	mouse_filter = Control.MOUSE_FILTER_STOP if not _spots.is_empty() else Control.MOUSE_FILTER_IGNORE
	queue_redraw()


## Map units -> view pixels.
func to_view(at: Vector2) -> Vector2:
	return (at * size.x / get_map_size().x).round()


func _point(entry: Array) -> Vector2:
	return to_view(Vector2(entry[0], entry[1]))


# --- Drawing ------------------------------------------------------------------------

func _draw() -> void:
	draw_texture_rect(PAINTED, Rect2(Vector2.ZERO, size), false)
	var regions: Dictionary = data().get("regions", {})
	for region_id: String in regions:
		_draw_region(region_id, regions[region_id])
	for place: Dictionary in data().get("places", []):
		if is_region_shown(str(place.get("region", ""))):
			_draw_place(place)
	for crystal: Dictionary in shown_crystals():
		_draw_crystal(_point(crystal["at"]), Color(str(crystal.get("color", "#ffffff"))),
				flag_set(str(crystal.get("gone_flag", ""))), is_owned(crystal))
	for spot: Dictionary in _spots:
		_draw_spot(spot)
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_INK, false, 1.0)


func _region_points(region: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	if region.has("circle"):
		var circle: Array = region["circle"]
		var center: Vector2 = Vector2(circle[0], circle[1])
		for i in 20:
			points.append(to_view(center + Vector2.from_angle(i * TAU / 20.0) * float(circle[2])))
	else:
		for entry: Array in region.get("polygon", []):
			points.append(_point(entry))
	return points


## A region still missing is covered with blank parchment and a "?"; a shown one gets its name.
func _draw_region(region_id: String, region: Dictionary) -> void:
	var points: PackedVector2Array = _region_points(region)
	if points.size() < 3:
		return
	var shown: bool = is_region_shown(region_id)
	if not shown:
		var uvs := PackedVector2Array()
		for point in points:
			uvs.append(point / size)
		draw_colored_polygon(points, Color.WHITE, uvs, PARCHMENT)
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, COLOR_PARCHMENT_DARK.darkened(0.2), 1.0)
	if not region.has("label"):
		return
	var at: Vector2 = _point(region["label"])
	var font: Font = get_theme_default_font()
	var text: String = Language.translate(str(region.get("name", ""))) if shown else "?"
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var text_at: Vector2 = at - Vector2(width / 2.0, -4.0)
	if shown:
		draw_string_outline(font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, COLOR_PARCHMENT)
	draw_string(font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE,
			COLOR_INK if shown else COLOR_PARCHMENT_DARK.darkened(0.35))


func _draw_place(place: Dictionary) -> void:
	var at: Vector2 = _point(place["at"])
	if not PAINTED_KINDS.has(str(place.get("kind", ""))):
		_draw_place_marker(place, at)
	if place.get("label", false):
		var font: Font = get_theme_default_font()
		var text: String = Language.translate(str(place.get("name", "")))
		draw_string_outline(font, at + Vector2(7, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, COLOR_PARCHMENT)
		draw_string(font, at + Vector2(7, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_INK)


func _draw_place_marker(place: Dictionary, at: Vector2) -> void:
	match str(place.get("kind", "")):
		"village":
			for offset: Vector2 in [Vector2(-4, -1), Vector2(1, -2), Vector2(-1, 2)]:
				draw_rect(Rect2(at + offset, Vector2(3, 2)), COLOR_INK)
		"city", "castle":
			var color: Color = COLOR_INK if place.get("kind") == "city" else Color(0.18, 0.1, 0.2)
			draw_rect(Rect2(at + Vector2(-5, -2), Vector2(10, 5)), color)
			for x in [-5, -1, 3]:
				draw_rect(Rect2(at + Vector2(x, -5), Vector2(2, 3)), color)
		"hut":
			draw_rect(Rect2(at + Vector2(-2, -1), Vector2(4, 3)), COLOR_INK)
			draw_colored_polygon(PackedVector2Array([at + Vector2(-3, -1), at + Vector2(0, -4), at + Vector2(3, -1)]), COLOR_INK)
		"water_city":
			for x in [-5, -1, 3]:
				draw_rect(Rect2(at + Vector2(x, -2), Vector2(3, 2)), COLOR_INK)
				draw_line(at + Vector2(x + 1, 0), at + Vector2(x + 1, 3), COLOR_INK, 1.0)
		"dome_city":
			draw_arc(at + Vector2(0, 2), 6.0, PI, TAU, 10, COLOR_INK, 1.0)
			draw_line(at + Vector2(-7, 2), at + Vector2(7, 2), COLOR_INK, 1.0)
			draw_line(at + Vector2(-2, -2), at + Vector2(2, -2), COLOR_INK, 1.0)
		"tent_city", "camp":
			for x in [-5, 0, 5]:
				draw_colored_polygon(PackedVector2Array([at + Vector2(x - 2, 2), at + Vector2(x, -2), at + Vector2(x + 2, 2)]),
						COLOR_INK if place.get("kind") == "tent_city" else Color(0.55, 0.2, 0.15))
		"temple":
			for x in [-4, -1, 2]:
				draw_rect(Rect2(at + Vector2(x, -3), Vector2(2, 6)), COLOR_INK)
		"altar":
			for i in 9:
				draw_rect(Rect2(at + Vector2.from_angle(i * TAU / 9.0) * 5.0, Vector2(1, 1)), COLOR_INK)
		"mine":
			draw_arc(at, 3.0, PI, TAU, 6, COLOR_INK, 1.0)
			draw_line(at + Vector2(-3, 0), at + Vector2(3, 0), COLOR_INK, 1.0)


## A crystal as a small diamond; one that was taken is crossed out, one the player has gets a ring.
func _draw_crystal(at: Vector2, color: Color, taken: bool, owned: bool) -> void:
	var points := PackedVector2Array([at + Vector2(0, -4), at + Vector2(3, 0), at + Vector2(0, 4), at + Vector2(-3, 0)])
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, COLOR_INK, 1.0)
	if taken:
		draw_line(at + Vector2(-4, -4), at + Vector2(4, 4), COLOR_INK, 1.0)
		draw_line(at + Vector2(4, -4), at + Vector2(-4, 4), COLOR_INK, 1.0)
	if owned:
		draw_arc(at, 6.0, 0.0, TAU, 14, color, 1.0)


## A teleporter in teleport mode: a glowing crystal, brighter under the mouse, grey if it can't be picked.
func _draw_spot(spot: Dictionary) -> void:
	var at: Vector2 = to_view(spot["at"])
	var color: Color = COLOR_SPOT if spot.get("enabled", true) else COLOR_SPOT_OFF
	if spot["id"] == _hovered:
		draw_circle(at, 7.0, Color(color, 0.35))
	var points := PackedVector2Array([at + Vector2(0, -5), at + Vector2(3, 0), at + Vector2(0, 5), at + Vector2(-3, 0)])
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, COLOR_INK, 1.0)


# --- Teleport mode: the mouse -------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if _spots.is_empty():
		return
	if event is InputEventMouseMotion:
		var hovered: String = spot_at((event as InputEventMouseMotion).position)
		if hovered != _hovered:
			_hovered = hovered
			spot_hovered.emit(hovered)
			queue_redraw()
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var picked: String = spot_at(click.position)
		if not picked.is_empty():
			accept_event()
			spot_pressed.emit(picked)


## Id of the spot under `at` (view pixels), the closest one within PICK_DISTANCE; "" = none.
func spot_at(at: Vector2) -> String:
	var best: String = ""
	var best_distance: float = PICK_DISTANCE
	for spot: Dictionary in _spots:
		var distance: float = to_view(spot["at"]).distance_to(at)
		if distance <= best_distance:
			best = spot["id"]
			best_distance = distance
	return best
