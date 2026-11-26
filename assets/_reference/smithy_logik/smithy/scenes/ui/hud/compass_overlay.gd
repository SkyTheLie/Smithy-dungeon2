class_name CompassOverlay
extends Control
## The desert compass on screen (bottom left, above the gold): a brass ring with N/O/S/W and a
## needle. In the desert maze the needle points to the first step towards the town and towards
## every chest that is still closed (DesertMaze.get_compass_directions); with two or more
## directions it swings from one to the next and rests there a few seconds. Outside the desert it
## points the way there: in the maps of the village region (desert.json "outside_way") at the door
## towards the desert, anywhere else at the map's teleporter (travel home first). In the desert's
## own maps (Sahrim, the temple ...) and where nothing fits it turns slowly, looking for its way. A right click on the compass in the inventory shows or hides
## it (Events.compass_requested); it stays shown from map to map until the player hides it or
## no longer carries it. Drawn in code, no picture needed.

const SIZE: float = 60.0
## Seconds the needle rests on one direction before it swings to the next.
const REST_SECONDS: float = 2.6
## How fast the needle turns towards its direction (higher = faster).
const TURN_SPEED: float = 5.0
## Turning speed while it searches (radians per second).
const SEARCH_SPEED: float = 0.9
## Seconds between two looks at the maze (the directions change only when a chest opens).
const REFRESH_SECONDS: float = 0.5
const ANGLES: Dictionary = {"N": -PI / 2.0, "O": 0.0, "S": PI / 2.0, "W": PI}
## Maps of the desert itself (Sahrim, temple, pyramids): no way to point at there.
const DESERT_FOLDER: String = "res://scenes/world/desert/"
const LETTERS: Dictionary = {"N": "Norden", "O": "Osten", "S": "Süden", "W": "Westen"}

const COLOR_RIM_DARK: Color = Color(0.36, 0.22, 0.1)
const COLOR_RIM: Color = Color(0.78, 0.56, 0.24)
const COLOR_RIM_LIGHT: Color = Color(0.95, 0.8, 0.45)
const COLOR_FACE: Color = Color(0.93, 0.86, 0.68)
const COLOR_TICK: Color = Color(0.45, 0.32, 0.2)
const COLOR_NEEDLE: Color = Color(0.78, 0.16, 0.12)
const COLOR_NEEDLE_BACK: Color = Color(0.3, 0.3, 0.36)

## Shown or hidden by the player; kept while the HUD is rebuilt on every new map.
static var shown: bool = false

var _angle: float = -PI / 2.0
var _directions: Array[String] = []
var _index: int = 0
var _rest_left: float = REST_SECONDS
var _refresh_left: float = 0.0
var _time: float = 0.0
## Outside the desert: the door or teleporter the needle points at (null = none).
var _target: Node2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 6.0
	offset_right = 6.0 + SIZE
	offset_top = -32.0 - SIZE
	offset_bottom = -32.0
	Events.compass_requested.connect(_toggle)
	_refresh()
	if not _directions.is_empty():
		_angle = ANGLES[_directions[0]]
	visible = shown and _has_compass()


func _toggle() -> void:
	shown = not shown
	visible = shown and _has_compass()
	GameState.show_message(Language.translate("Du steckst den Kompass weg.") if not shown else Language.translate("Du nimmst den Kompass in die Hand."))


func _has_compass() -> bool:
	return GameState.inventory.slots.any(func(slot: InventorySlot) -> bool:
			return not slot.is_empty() and slot.item.id == ItemSlotUI.COMPASS_ITEM)


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		visible = shown and _has_compass()
		# Looking for the way searches the whole map: only while the compass is in the hand.
		if visible:
			_refresh()
	if not visible:
		return
	_time += delta
	if not is_instance_valid(_target):
		_target = null
	var player: Node2D = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if _target and player:
		var target_angle: float = (_target.global_position - player.global_position).angle() + sin(_time * 7.0) * 0.04
		_angle = lerp_angle(_angle, target_angle, minf(1.0, TURN_SPEED * delta))
	elif _directions.is_empty():
		_angle = wrapf(_angle + SEARCH_SPEED * delta, -PI, PI)
	else:
		if _directions.size() > 1:
			_rest_left -= delta
			if _rest_left <= 0.0:
				_rest_left = REST_SECONDS
				_index = (_index + 1) % _directions.size()
		_index = mini(_index, _directions.size() - 1)
		# A small tremble, like a real needle.
		var target: float = ANGLES[_directions[_index]] + sin(_time * 7.0) * 0.04
		_angle = lerp_angle(_angle, target, minf(1.0, TURN_SPEED * delta))
	queue_redraw()


func _refresh() -> void:
	var directions: Array[String] = []
	if _in_maze():
		directions = GameState.desert.get_compass_directions()
		_target = null
	else:
		_target = _find_way_out()
	if directions != _directions:
		_directions = directions
		_index = 0
		_rest_left = REST_SECONDS


## Outside the desert: the door of this map that leads one map closer to the desert (desert.json
## "outside_way"), else the map's teleporter. null in the desert's own maps and where neither is.
func _find_way_out() -> Node2D:
	var scene: Node = get_tree().current_scene
	if scene == null or scene.scene_file_path.begins_with(DESERT_FOLDER):
		return null
	var next: String = str(DesertMaze.data().get("outside_way", {}).get(scene.scene_file_path, ""))
	# In the village region the door one map closer, elsewhere the teleporter (the nearest one).
	var node_type: String = "StaticBody2D" if next.is_empty() else "Area2D"
	var player: Node2D = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var best: Node2D = null
	for node: Node in scene.find_children("*", node_type, true, false):
		var fits: bool = node is Teleporter if next.is_empty() else (node is Door and (node as Door).target_scene == next)
		if not fits or not (node as Node2D).is_visible_in_tree():
			continue
		if best == null or player == null or _distance(player, node) < _distance(player, best):
			best = node
	return best


static func _distance(from: Node2D, to: Node) -> float:
	return from.global_position.distance_squared_to((to as Node2D).global_position)


## Only in the desert scenes the needle finds its way (elsewhere it searches).
func _in_maze() -> bool:
	var scene: Node = get_tree().current_scene
	return scene != null and scene.is_in_group(&"desert_maze")


func _draw() -> void:
	var center := Vector2(SIZE, SIZE) / 2.0
	var radius: float = SIZE / 2.0 - 1.0
	draw_circle(center, radius, COLOR_RIM_DARK)
	draw_circle(center, radius - 1.0, COLOR_RIM)
	draw_arc(center, radius - 2.0, PI * 1.05, PI * 1.6, 12, COLOR_RIM_LIGHT, 1.0)
	draw_circle(center, radius - 4.0, COLOR_RIM_DARK)
	draw_circle(center, radius - 5.0, COLOR_FACE)
	# Ticks: long ones at the four directions, short ones in between.
	for i in 16:
		var angle: float = i * TAU / 16.0
		var outer: float = radius - 6.0
		var inner: float = outer - (4.0 if i % 4 == 0 else 2.0)
		draw_line(center + Vector2.from_angle(angle) * inner, center + Vector2.from_angle(angle) * outer, COLOR_TICK, 1.0)
	var font: Font = get_theme_default_font()
	for key: String in ANGLES:
		var spot: Vector2 = center + Vector2.from_angle(ANGLES[key]) * (radius - 15.0)
		var text: String = Language.translate(LETTERS[key]).left(1)
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		draw_string(font, spot + Vector2(-text_size.x / 2.0, text_size.y / 2.0 - 3.0), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_NEEDLE if key == "N" else COLOR_TICK)
	# Needle: red tip towards the way, grey tail.
	var forward := Vector2.from_angle(_angle)
	var side := forward.orthogonal() * 3.0
	var tip: Vector2 = center + forward * (radius - 9.0)
	var tail: Vector2 = center - forward * (radius - 13.0)
	draw_colored_polygon(PackedVector2Array([tip, center + side, center - side]), COLOR_NEEDLE)
	draw_colored_polygon(PackedVector2Array([tail, center - side, center + side]), COLOR_NEEDLE_BACK)
	draw_circle(center, 2.5, COLOR_RIM_DARK)
	draw_circle(center, 1.5, COLOR_RIM_LIGHT)
