class_name FloatingStoneRing
extends Node2D
## The grey stones around the middle island at the top of Sylvaris, in three orbits around it:
## inside two stones side by side (a short piece of path) clockwise, in the middle orbit one big
## stone counterclockwise, outside a heap of small stones (SMALL_STONES) clockwise. When somebody
## comes to the edge of one of the gaps (the player, or a story figure walking along its leave_path),
## all of them leave their orbit at the same moment and arrive together as a bridge over that gap,
## close enough to look like a path (nobody walks through the air): the two from inside next to the
## middle island, the big one after them, the small ones on to the far island. Once it stands, the walls at both ends of the gap open. When nobody is near any more,
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
## Story figures walk faster than the stones fly (StoryNpc.WALK_SPEED * FLY_SECONDS is about 57 px):
## while they walk they call the bridge from further away, so it stands before their first step onto it.
@export var walker_reach: float = 80.0

## How far before the edge of a gap a story figure stops to wait for its bridge.
const EDGE_WAIT: float = 12.0
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
const HEAP_SPREAD: Vector2 = Vector2(4.5, 3)
const BOB: float = 1.5
## Small stones in the heap: with the three others they lie edge to edge on the longest bridge
## (about 270 px), so the bridge looks like a path and not like steps in the air.
const SMALL_STONES: int = 17
## Where the first and the last stone land on the bridge (share of its length); the others in
## between at the same distance: two inner, the big one, then the small ones in a line.
const FIRST_SLOT: float = 0.04
const LAST_SLOT: float = 0.96

## One per stone: {"sprite", "radius" (its orbit), "speed", "angle" (where it is in the orbit),
## "offset" (inside the heap)}.
var _stones: Array[Dictionary] = []
## Per bridge: the two walls at its ends.
var _walls: Array = []
var _walkers: Array[Node2D] = []
## Last direction each walker moved in (instance id -> Vector2), to know which gap it is heading into.
var _headings: Dictionary[int, Vector2] = {}
var _last_spots: Dictionary[int, Vector2] = {}
var _time: float = 0.0
## Bridge the stones form or formed last (-1 = none) and how far they are on their way (0 = orbit, 1 = bridge).
var _active: int = -1
var _t: float = 0.0


func _ready() -> void:
	_add_stone(inner_texture, inner_radius, INNER_SPEED, 0.0, Vector2.ZERO)
	_add_stone(inner_texture, inner_radius, INNER_SPEED, -INNER_GAP, Vector2.ZERO)
	_add_stone(big_texture, middle_radius, MIDDLE_SPEED, PI * 0.8, Vector2.ZERO)
	# the heap: a little spiral (golden angle), the further out the further from its middle
	for k in SMALL_STONES:
		var spot: Vector2 = Vector2.from_angle(k * 2.4) * sqrt(float(k))
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


## Bridges somebody stands on or near one of its ends: the player (`with_player`) and/or the
## story figures walking along their leave_path (`with_walkers`).
func _needed_bridges(with_player: bool, with_walkers: bool) -> Array[int]:
	var bodies: Array[Node2D] = []
	var reaches: Array[float] = []
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player and with_player:
		bodies.append(player)
		reaches.append(reach)
	for walker in _walkers:
		if with_walkers and is_instance_valid(walker) and walker.is_visible_in_tree():
			bodies.append(walker)
			reaches.append(walker_reach if (walker as StoryNpc).is_walking() else reach)
	var needed: Array[int] = []
	for i in starts.size():
		var direction: Vector2 = (ends[i] - starts[i]).normalized()
		var length: float = starts[i].distance_to(ends[i])
		for b in bodies.size():
			var local: Vector2 = to_local(bodies[b].global_position) - starts[i]
			var along: float = local.dot(direction)
			var r: float = reaches[b]
			if along > -r and along < length + r and absf(local.cross(direction)) < width / 2.0 + r * 0.6:
				needed.append(i)
				break
	return needed


## true if the player stands over gap `index` (not just near its ends).
func _player_on_gap(index: int) -> bool:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player == null or index < 0:
		return false
	var direction: Vector2 = (ends[index] - starts[index]).normalized()
	var local: Vector2 = to_local(player.global_position) - starts[index]
	var along: float = local.dot(direction)
	return along > 0.0 and along < starts[index].distance_to(ends[index]) and absf(local.cross(direction)) < width


func _process(delta: float) -> void:
	_time += delta
	var needed: Array[int] = _needed_bridges(true, true)
	# The bridge that stands stays while somebody needs it; otherwise the first one asked for.
	# Story figures on their way go first: a bridge only the player stands near (not on) gives way
	# to one they wait for, or they would wait for ever while the player stays there.
	var for_walkers: Array[int] = _needed_bridges(false, true)
	var wanted: int = _active if needed.has(_active) else (needed[0] if not needed.is_empty() else -1)
	if not for_walkers.is_empty() and not for_walkers.has(_active) and not _player_on_gap(_active):
		wanted = for_walkers[0]
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
	_hold_walkers()


## A story figure at the edge of a gap waits there until the stones of that gap stand (only one
## bridge stands at a time: while others still cross another gap, nobody walks into the air).
func _hold_walkers() -> void:
	for walker in _walkers:
		if not is_instance_valid(walker) or not walker.is_visible_in_tree():
			continue
		var id: int = walker.get_instance_id()
		var spot: Vector2 = to_local(walker.global_position)
		if _last_spots.has(id) and spot.distance_to(_last_spots[id]) > 0.01:
			_headings[id] = (spot - _last_spots[id]).normalized()
		_last_spots[id] = spot
		var heading: Vector2 = _headings.get(id, Vector2.ZERO)
		var held: bool = false
		if (walker as StoryNpc).is_walking():
			for i in starts.size():
				if is_bridge_open(i):
					continue
				var direction: Vector2 = (ends[i] - starts[i]).normalized()
				var length: float = starts[i].distance_to(ends[i])
				var local: Vector2 = spot - starts[i]
				var along: float = local.dot(direction)
				if absf(local.cross(direction)) > width / 2.0 + 8.0:
					continue
				var at_start: bool = along > -EDGE_WAIT and along < 3.0 and heading.dot(direction) > 0.0
				var at_end: bool = along > length - 3.0 and along < length + EDGE_WAIT and heading.dot(direction) < 0.0
				if at_start or at_end:
					held = true
		(walker as StoryNpc).walk_held = held


## true while the walls of bridge `index` are open (all stones have arrived there).
func is_bridge_open(index: int) -> bool:
	return index == _active and _t >= 1.0


## Where stone `stone` lies in bridge `index`.
func get_slot(index: int, stone: int) -> Vector2:
	var share: float = lerpf(FIRST_SLOT, LAST_SLOT, float(stone) / float(maxi(_stones.size() - 1, 1)))
	return starts[index].lerp(ends[index], share)


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
