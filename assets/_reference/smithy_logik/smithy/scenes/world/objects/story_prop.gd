class_name StoryProp
extends Node2D
## Decoration that comes and goes with the story (e.g. the rubble in the mine, the rats behind it,
## the crowd at the spring festival). Visible once `required_flag` is set (empty = from the start)
## and until `hidden_when_flag` is set (empty = for good). While hidden, the collision shapes
## below it are switched off too. Put the sprites (and bodies) as children of this node.
## With `walk_out` the figures (Sprite2D children with a resident sheet) walk out of the map along
## `leave_path` when `hidden_when_flag` is set while the player watches, instead of vanishing.

## Story flag from which it is there. Empty = always.
@export var required_flag: String = ""
## Story flag from which it is gone again. Empty = never.
@export var hidden_when_flag: String = ""
## The figures walk out of the map instead of vanishing on the spot (e.g. the festival crowd).
@export var walk_out: bool = false
## The way out (scene coordinates of the map, the last point outside its edge). Between the points
## they go around obstacles if the map has VillageRoads.
@export var leave_path: PackedVector2Array = []

## Walking speed (pixels per second, like the villagers) and how much it varies per figure.
const WALK_SPEED: float = 36.0
const SPEED_SPREAD: float = 8.0
## Seconds the last figure waits before it sets off (they leave one after another).
const MAX_DELAY: float = 3.0
## Figures don't walk exactly in each other's footsteps (pixels).
const PATH_SPREAD: float = 4.0

## Figures on their way out: {sprite, path (global), point, delay, speed, time}.
var _walkers: Array[Dictionary] = []


func _ready() -> void:
	GameState.story.changed.connect(_update)
	_update(true)


func _update(instant: bool = false) -> void:
	var story: Story = GameState.story
	var shown: bool = story.has_flag(required_flag) and (hidden_when_flag.is_empty() or not story.has_flag(hidden_when_flag))
	if shown == visible or not _walkers.is_empty():
		return
	for shape in find_children("*", "CollisionShape2D", true, false):
		(shape as CollisionShape2D).set_deferred("disabled", not shown)
	if not shown and walk_out and not instant and is_visible_in_tree():
		_start_walking()
		if not _walkers.is_empty():
			return
	visible = shown


func _start_walking() -> void:
	var roads: VillageRoads = _find_roads()
	var map := owner as Node2D
	var way := PackedVector2Array()
	for point in leave_path:
		way.append(map.to_global(point) if map else point)
	for child in get_children():
		var sprite := child as Sprite2D
		if way.is_empty() or sprite == null or not sprite.visible or not _has_walk_frames(sprite):
			continue
		var path: PackedVector2Array = roads.plan_through(sprite.global_position, way) if roads else way.duplicate()
		var shift := Vector2(randf_range(-PATH_SPREAD, PATH_SPREAD), randf_range(-PATH_SPREAD, PATH_SPREAD))
		for i in path.size() - 1:
			path[i] += shift
		_walkers.append({"sprite": sprite, "path": path, "point": 0, "time": 0.0,
				"delay": randf_range(0.0, MAX_DELAY), "speed": WALK_SPEED + randf_range(-SPEED_SPREAD, SPEED_SPREAD)})


func _process(delta: float) -> void:
	if _walkers.is_empty():
		return
	for walker in _walkers.duplicate():
		if walker["delay"] > 0.0:
			walker["delay"] -= delta
			continue
		var sprite: Sprite2D = walker["sprite"]
		var path: PackedVector2Array = walker["path"]
		if walker["point"] >= path.size():
			sprite.hide()
			_walkers.erase(walker)
			continue
		var offset: Vector2 = path[walker["point"]] - sprite.global_position
		if offset.length() <= 1.0:
			walker["point"] += 1
			continue
		sprite.global_position += offset.limit_length(walker["speed"] * delta)
		walker["time"] += delta
		var frame: int = 1 + int(walker["time"] * CharacterBaker.WALK_SPEED) % (CharacterBaker.COLUMNS - 1)
		var direction: String
		if absf(offset.x) > absf(offset.y):
			direction = "right" if offset.x > 0.0 else "left"
		else:
			direction = "down" if offset.y > 0.0 else "up"
		sprite.region_rect = CharacterBaker.get_frame_rect(direction, frame)
	if _walkers.is_empty():
		visible = false


## Only figures on a full walk sheet (7 frames x 4 directions, like the residents) can walk.
func _has_walk_frames(sprite: Sprite2D) -> bool:
	return sprite.texture != null and sprite.region_enabled \
			and sprite.texture.get_width() == CharacterBaker.FRAME * CharacterBaker.COLUMNS \
			and sprite.texture.get_height() == CharacterBaker.FRAME * CharacterBaker.DIRECTIONS.size()


func _find_roads() -> VillageRoads:
	if owner == null:
		return null
	for child in owner.get_children():
		if child is VillageRoads:
			return child
	return null

