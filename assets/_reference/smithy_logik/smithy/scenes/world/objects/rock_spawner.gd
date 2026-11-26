class_name RockSpawner
extends Node2D
## Spawns farmable resources (ore rocks, trees, plants) at random positions inside `area`.
## They are generated once per day (see ResourceFields): mined ones stay gone for the rest of
## the day, the next day the rest expires and a new set appears.
## With `walls` set, only at spots right next to the cave walls.
## Each rock gets a random kind from `rock_types`. Keep y_sort_enabled on, so the rocks
## are sorted with the player.

@export var rock_scene: PackedScene
@export var rock_types: Array[RockData] = []
## Optional: own chances per rock type (same order as rock_types, e.g. [35, 35, 30]) instead of
## RockData.spawn_weight.
@export var weights: Array[float] = []
@export var rock_count: int = 14
## If higher than rock_count: a random count between rock_count and this each day.
@export var rock_count_max: int = -1
## Name under which the day's resources are stored. Empty = scene path + node name.
@export var area_id: String = ""
## Area (relative to this node) in which rocks may appear.
@export var area: Rect2 = Rect2(-360, -240, 720, 420)
## Minimum distance between two rocks.
@export var min_distance: float = 40.0
## Optional: only place rocks at the walls of this cave (positions relative to the cave).
@export var walls: CaveWalls
## No rocks in this area (e.g. around the entrance).
@export var keep_clear: Rect2 = Rect2()
## More areas without rocks (e.g. roads and decoration on an outdoor map).
@export var more_keep_clear: Array[Rect2] = []
## Optional: only use these places (the Marker2D children of this node), e.g. free-standing spots
## for trees on clearings. Each day a random choice of them is used; `area` is then ignored.
@export var spots: Node2D
## Tip (story.json "hints") shown once when the last rock of the day is gone, e.g. "mine_empty".
@export var empty_hint: String = ""

const MAX_ATTEMPTS_PER_ROCK: int = 20
## Wall spots are rare compared to the whole area, so they need more tries.
const MAX_ATTEMPTS_PER_WALL_ROCK: int = 400


func _ready() -> void:
	if rock_types.is_empty():
		return
	var day: int = GameState.day_cycle.day
	var nodes: Variant = GameState.resource_fields.get_nodes(_get_area_id(), day)
	if nodes == null:
		nodes = _generate_nodes()
		GameState.resource_fields.set_nodes(_get_area_id(), day, nodes)
	for entry: Dictionary in nodes:
		var rock_data := SaveSystem.load_resource(entry.get("kind", "")) as RockData
		if rock_data == null:
			continue
		var rock: OreRock = rock_scene.instantiate()
		rock.data = rock_data
		rock.field_entry = entry
		rock.position = Vector2(entry["x"], entry["y"])
		rock.broken.connect(_on_rock_broken.bind(nodes, entry))
		add_child(rock)


func _on_rock_broken(nodes: Array, entry: Dictionary) -> void:
	nodes.erase(entry)
	if nodes.is_empty() and not empty_hint.is_empty():
		GameState.story.show_hint(empty_hint)


## Today's set: positions and kinds, all at full health.
func _generate_nodes() -> Array:
	var nodes: Array = []
	for spawn_position in _pick_positions():
		nodes.append({"kind": _pick_weighted().resource_path, "x": spawn_position.x, "y": spawn_position.y, "health": -1})
	return nodes


func _get_area_id() -> String:
	if not area_id.is_empty():
		return area_id
	return "%s/%s" % [owner.scene_file_path if owner else "", name]


func _get_count() -> int:
	return randi_range(rock_count, rock_count_max) if rock_count_max > rock_count else rock_count


## Random rock kind; RockData.spawn_weight (or `weights`) makes rare ores appear less often.
func _pick_weighted() -> RockData:
	var total: float = 0.0
	for i in rock_types.size():
		total += _get_weight(i)
	var roll: float = randf() * total
	for i in rock_types.size():
		roll -= _get_weight(i)
		if roll <= 0.0:
			return rock_types[i]
	return rock_types.back()


func _get_weight(index: int) -> float:
	var rock: RockData = rock_types[index]
	if rock.required_flag != "" and not GameState.story.has_flag(rock.required_flag):
		return 0.0
	return weights[index] if index < weights.size() else rock.spawn_weight


func _pick_positions() -> Array[Vector2]:
	if spots:
		return _pick_spots()
	var positions: Array[Vector2] = []
	var attempts: int = 0
	var count: int = _get_count()
	var max_attempts: int = count * (MAX_ATTEMPTS_PER_WALL_ROCK if walls else MAX_ATTEMPTS_PER_ROCK)
	while positions.size() < count and attempts < max_attempts:
		attempts += 1
		var candidate: Vector2 = area.position + Vector2(randf() * area.size.x, randf() * area.size.y)
		if keep_clear.has_point(candidate) or more_keep_clear.any(func(r: Rect2) -> bool: return r.has_point(candidate)):
			continue
		if walls and not walls.is_wall_spot(candidate + position - walls.position):
			continue
		if _is_free(candidate, positions):
			positions.append(candidate)
	return positions


## A random choice of the spot markers (positions relative to this node).
func _pick_spots() -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	for marker in spots.get_children():
		if marker is Node2D:
			candidates.append(to_local((marker as Node2D).global_position))
	candidates.shuffle()
	return candidates.slice(0, mini(_get_count(), candidates.size()))


func _is_free(candidate: Vector2, taken: Array[Vector2]) -> bool:
	for other in taken:
		if other.distance_to(candidate) < min_distance:
			return false
	return true
