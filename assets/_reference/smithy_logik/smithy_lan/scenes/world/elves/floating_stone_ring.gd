class_name FloatingStoneRing
extends Node2D
## The grey stones around the middle island at the top of Sylvaris, in three orbits around it:
## inside two stones side by side (a short piece of path) clockwise, in the middle orbit one big
## stone counterclockwise, outside a little heap of five small stones clockwise. When somebody comes
## to the edge of one of the gaps (the player, or a story figure walking along its leave_path), all
## eight leave their orbit at the same moment and arrive together as a bridge over that gap: the
## two from inside next to the middle island, the big one in the middle, the small ones at the far
## island. Once it stands, the walls at both ends of the gap open. When nobody is near any more,
## they fly back to the spots where they left their orbits and circle on. The gaps themselves must
## be walkable in the mask of the map (CaveWalls).

## Ends of each bridge (scene coordinates of this node): `starts` on the edge of the middle island,
## `ends` on the edge of the other island, same index = same bridge.
@export var starts: PackedVector2Array = []
@export var ends: PackedVector2Array = []
## The three orbits around this node's position (the middle of the island).
@export var inner_radius: Vector2 = Vector2(150, 96)
@export var middle_radius: Vector2 = Vector2(182, 120)
@export var outer_radius: Vector2 = Vector2(218, 146)
@export var inner_texture: Texture2D
@export var big_texture: Texture2D
@export var small_texture: Texture2D
## Width of a bridge (the walls at its ends are a little wider).
@export var width: float = 22.0
## How far beyond its ends (onto the islands) somebody makes a bridge appear.
@export var reach: float = 30.0

## Seconds every stone needs between its orbit and the bridge (all the same, so they arrive together).
const FLY_SECONDS: float = 0.6
## How high a stone arcs while it flies.
const FLY_ARC: float = 14.0
## Radians per second of each orbit (positive = clockwise on screen).
const INNER_SPEED: float = 0.35
const MIDDLE_SPEED: float = -0.25
const OUTER_SPEED: float = 0.18
## The two inner stones lie this far apart in their orbit (radians), the heap of small ones spreads this much.
const INNER_GAP: float = 0.17
const HEAP_SPREAD: Vector2 = Vector2(9, 6)
const BOB: float = 1.5
## Where along the bridge each stone lands (share of its length): two inner, the big one, then the
## five small ones in a line.
const SLOTS: Array[float] = [0.07, 0.2, 0.37, 0.55, 0.645, 0.74, 0.835, 0.93]

## One per stone: {"sprite", "radius" (its orbit), "speed", "angle" (where it is in the orbit),
## "offset" (inside the heap)}.
var _stones: Array[Dictionary] = []
## Per bridge: the two walls at its ends.
var _walls: Array = []
var _walkers: Array[Node2D] = []
var _time: float = 0.0
## Bridge the stones form or formed last (-1 = none) and how far they are on their way (0 = orbit, 1 = bridge).
var _active: int = -1
var _t: float = 0.0


func _ready() -> void:
	_add_stone(inner_texture, inner_radius, INNER_SPEED, 0.0, Vector2.ZERO)
	_add_stone(inner_texture, inner_radius, INNER_SPEED, -INNER_GAP, Vector2.ZERO)
	_add_stone(big_texture, middle_radius, MIDDLE_SPEED, PI * 0.8, Vector2.ZERO)
	var heap: Array[Vector2] = [Vector2(0, 0), Vector2(-1, -1), Vector2(1, -0.6), Vector2(-0.8, 0.9), Vector2(0.9, 0.8)]
	for spot in heap:
		_add_stone(small_texture, outer_radius, OUTER_SPEED, PI * 1.45, spot * HEAP_SPREAD)
	var body := StaticBody2D.new()
	add_child(body)
	for i in starts.size():
		var direction: Vector2 = (ends[i] - starts[i]).normalized()
		var across: Vector2 = Vector2(-direction.y, direction.x) * (width / 2.0 + 8.0)
		var pair: Array[CollisionShape2D] = []
		for point: Vector2 in [starts[i], ends[i]]:
			var shape := CollisionShape2D.new()
			var segment := SegmentShape2D.new()
			segment.a = point - across
			segment.b = point + across
			shape.shape = segment
			body.add_child(shape)
			pair.append(shape)
		_walls.append(pair)
	_find_walkers.call_deferred()
	_place_stones()


func _add_stone(texture: Texture2D, radius: Vector2, speed: float, angle: float, offset: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.z_index = -1
	add_child(sprite)
	_stones.append({"sprite": sprite, "radius": radius, "speed": speed, "angle": angle, "offset": offset})


## Figures of the scene that may walk across (StoryNpc with a leave_path).
func _find_walkers() -> void:
	var root: Node = owner if owner else get_parent()
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is StoryNpc and not (node as StoryNpc).leave_path.is_empty():
			_walkers.append(node)
		pending.append_array(node.get_children())


## Bridges somebody stands on or near one of its ends.
func _needed_bridges() -> Array[int]:
	var bodies: Array[Node2D] = []
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player:
		bodies.append(player)
	for walker in _walkers:
		if is_instance_valid(walker) and walker.is_visible_in_tree():
			bodies.append(walker)
	var needed: Array[int] = []
	for i in starts.size():
		var direction: Vector2 = (ends[i] - starts[i]).normalized()
		var length: float = starts[i].distance_to(ends[i])
		for body in bodies:
			var local: Vector2 = to_local(body.global_position) - starts[i]
			var along: float = local.dot(direction)
			if along > -reach and along < length + reach and absf(local.cross(direction)) < width / 2.0 + reach * 0.6:
				needed.append(i)
				break
	return needed


func _process(delta: float) -> void:
	_time += delta
	var needed: Array[int] = _needed_bridges()
	# The bridge that stands stays while somebody needs it; otherwise the first one asked for.
	var wanted: int = _active if needed.has(_active) else (needed[0] if not needed.is_empty() else -1)
	var goal: float = 1.0 if wanted == _active and wanted >= 0 else 0.0
	if _t == 0.0 and wanted != _active:
		_active = wanted
		goal = 1.0 if wanted >= 0 else 0.0
	if goal != _t and (_t == 0.0 or _t == 1.0):
		AudioManager.play_sound("skill_used", 0.25)
	_t = move_toward(_t, goal, delta / FLY_SECONDS)
	# Only stones at home keep circling, so they come back to the spot where they left.
	if _t == 0.0:
		for stone in _stones:
			stone["angle"] += stone["speed"] * delta
	var closed: bool = _t < 1.0
	for i in _walls.size():
		var open: bool = not closed and i == _active
		for wall: CollisionShape2D in _walls[i]:
			if wall.disabled == open:
				continue
			wall.set_deferred("disabled", open)
	_place_stones()


## true while the walls of bridge `index` are open (all stones have arrived there).
func is_bridge_open(index: int) -> bool:
	return index == _active and _t >= 1.0


## Where stone `stone` lies in bridge `index`.
func get_slot(index: int, stone: int) -> Vector2:
	return starts[index].lerp(ends[index], SLOTS[stone])


func _place_stones() -> void:
	var eased: float = _t * _t * (3.0 - 2.0 * _t)
	for i in _stones.size():
		var stone: Dictionary = _stones[i]
		var radius: Vector2 = stone["radius"]
		var angle: float = stone["angle"]
		var spot: Vector2 = Vector2(cos(angle) * radius.x, sin(angle) * radius.y) + stone["offset"]
		spot.y += sin(_time * 2.0 + i * 1.7) * BOB
		if _active >= 0 and _t > 0.0:
			var slot: Vector2 = get_slot(_active, i)
			spot = spot.lerp(slot, eased)
			spot.y -= sin(PI * _t) * FLY_ARC
		(stone["sprite"] as Sprite2D).position = spot.round()
