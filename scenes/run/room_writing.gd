class_name RoomWriting
extends RefCounted
## Writing on a wall: a short line scratched there by an earlier adventurer (story about Egon and the
## dungeon). Lines: data/story.json "walls" (every dungeon) and "walls_<dungeon id>"; how often:
## floors.json "writings" (chance per normal room, at most max_per_floor on one floor).
## Pure looks, nothing to touch. Uses its own random numbers, so the dungeon's random order stays.

## Height of the text's middle on the wall (metres).
const HEIGHT: float = 1.35
## The text stands this far in front of the wall, so it never flickers into it.
const WALL_GAP: float = 0.03


## The lines that fit the dungeon `dungeon_id` ("" = the first one): the shared ones and its own.
static func lines_for(dungeon_id: String) -> Array[String]:
	var lines: Array[String] = []
	for key: String in ["walls", "walls_%s" % (dungeon_id if not dungeon_id.is_empty() else "glut")]:
		for line: Variant in Content.story(key):
			lines.append(String(line))
	return lines


## Picks which normal rooms of a floor get a line and which line (none twice on a floor).
## `cells`: the normal rooms; returns cell -> line (German key).
static func plan(cells: Array[Vector2i], lines: Array[String], rules: Dictionary, rng_seed: int) -> Dictionary[Vector2i, String]:
	var chosen: Dictionary[Vector2i, String] = {}
	if lines.is_empty() or cells.is_empty():
		return chosen
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var left: Array[String] = lines.duplicate()
	var most: int = int(rules.get("max_per_floor", 1))
	for cell: Vector2i in cells:
		if chosen.size() >= most or left.is_empty():
			break
		if rng.randf() >= float(rules.get("chance", 0.0)):
			continue
		chosen[cell] = left.pop_at(rng.randi() % left.size())
	return chosen


## Puts `line` on one of the short walls (east or west) of `room`, beside its doorway if it has one.
## `doors`: directions with a doorway. Returns the label (for tests).
static func add_writing(room: Node3D, line: String, doors: Array[Vector2i], rng_seed: int) -> Label3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var side: int = -1 if rng.randf() < 0.5 else 1
	var along: float = rng.randf_range(-1.2, 1.2)
	# A doorway sits in the middle of the wall: then the writing goes to one side of it.
	if Vector2i(side, 0) in doors:
		along = (2.8 if rng.randf() < 0.5 else -2.8)
	var label := Label3D.new()
	label.name = "Writing"
	label.text = Language.translate(line)
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var theme: Theme = ThemeDB.get_project_theme()
	if theme and theme.default_font:
		label.font = theme.default_font
	label.font_size = 24
	label.pixel_size = 0.008
	label.outline_size = 0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = 260.0
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.modulate = Color(0.86, 0.82, 0.72, 0.8)
	label.double_sided = false
	var x: float = side * (RoomBuilder.ROOM_W / 2.0 - RoomBuilder.WALL_T - WALL_GAP)
	label.position = Vector3(x, HEIGHT, along)
	# Faces into the room (a Label3D shows its front towards +Z).
	label.rotation.y = -PI / 2.0 * side
	label.rotation.z = deg_to_rad(rng.randf_range(-4.0, 4.0))
	room.add_child(label)
	return label
