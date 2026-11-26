class_name DesertMaze
extends RefCounted
## The desert south of the south road (data/content/desert.json): a maze of screens that all look
## the same (scenes/world/desert/desert.tscn). Named places (the sign at the start, the skeleton,
## the chests, the town Sahrim) are joined by routes like "S S O O N"; every step of a route is a
## field of its own. A route can be walked both ways, every other direction means the player got
## lost: some hours pass and he stands at the sign again (first time: flag "desert_lost_once",
## the side task to ask Aurelius). The desert compass (CompassOverlay) shows the first step to the
## town and to every chest that is still closed; the sand map (DesertMapWindow) shows the steps
## the player has walked. Lives in GameState.desert.

## Exit side -> step on the grid (O = east, the German "Osten").
const DIRECTIONS: Array[String] = ["N", "O", "S", "W"]
const OPPOSITE: Dictionary = {"N": "S", "S": "N", "O": "W", "W": "O"}
## Spawn marker of a desert scene for arriving on this side ("N" = at the north edge, i.e. after
## walking south).
const SPAWNS: Dictionary = {"N": &"FromNorth", "O": &"FromEast", "S": &"FromSouth", "W": &"FromWest"}
## Spawn marker for coming in from the south road (starts the maze at the sign).
const ENTRY_SPAWN: StringName = &"FromSouthRoad"
## Spawn marker after getting lost (next to the sign).
const LOST_SPAWN: StringName = &"FromLost"
const DESERT_SCENE: String = "res://scenes/world/desert/desert.tscn"
## Item id of the desert compass (same as ItemSlotUI.COMPASS_ITEM).
const COMPASS_ITEM: StringName = &"desert_compass"

## Field the player stands on ("" = not in the desert yet).
var current: String = ""
## Fields the player has stood on (field -> true), drawn on the sand map.
var visited: Dictionary = {}
## How often the player got lost.
var lost_count: int = 0

## field -> {direction: field}, built once from desert.json "routes".
static var _graph: Dictionary = {}
## "field|direction" -> story flag the step needs (routes with "required_flag", e.g. the storm paths
## to the temple: without the storm map that way means getting lost).
static var _link_flags: Dictionary = {}
## "field|direction" -> rarity the carried compass needs at least (routes with "required_compass",
## e.g. 6 = Legendär for the valley of the pyramids; without it that way means getting lost).
static var _link_compass: Dictionary = {}
## [{"from", "to", "moves": Array[String], "fields": Array[String] (from, steps ..., to)}]
static var _routes: Array[Dictionary] = []


static func data() -> Dictionary:
	return ContentDB.desert()


static func start_field() -> String:
	return str(data().get("start", "start"))


## Field -> {direction: neighbour field}. Two routes leaving one field the same way are an error.
static func graph() -> Dictionary:
	if not _graph.is_empty():
		return _graph
	_routes.clear()
	_link_flags.clear()
	_link_compass.clear()
	for route: Dictionary in data().get("routes", []):
		var from: String = route.get("from", "")
		var to: String = route.get("to", "")
		var flag: String = str(route.get("required_flag", ""))
		var compass: int = int(route.get("required_compass", -1))
		var moves: Array[String] = []
		for move: String in str(route.get("moves", "")).split(" ", false):
			if not OPPOSITE.has(move):
				push_error("desert.json: route %s -> %s: unknown direction '%s' (N, O, S, W)." % [from, to, move])
				continue
			moves.append(move)
		var fields: Array[String] = [from]
		for i in range(1, moves.size()):
			fields.append("%s_%s_%d" % [from, to, i])
		fields.append(to)
		for i in moves.size():
			_link(fields[i], moves[i], fields[i + 1])
			_link(fields[i + 1], OPPOSITE[moves[i]], fields[i])
			if not flag.is_empty():
				_link_flags["%s|%s" % [fields[i], moves[i]]] = flag
				_link_flags["%s|%s" % [fields[i + 1], OPPOSITE[moves[i]]]] = flag
			if compass >= 0:
				_link_compass["%s|%s" % [fields[i], moves[i]]] = compass
				_link_compass["%s|%s" % [fields[i + 1], OPPOSITE[moves[i]]]] = compass
		_routes.append({"from": from, "to": to, "moves": moves, "fields": fields, "required_flag": flag,
				"required_compass": compass})
	return _graph


static func _link(from: String, direction: String, to: String) -> void:
	var exits: Dictionary = _graph.get_or_add(from, {})
	if exits.has(direction) and exits[direction] != to:
		push_error("desert.json: two ways lead %s out of '%s' (%s and %s)." % [direction, from, exits[direction], to])
		return
	exits[direction] = to


static func routes() -> Array[Dictionary]:
	graph()
	return _routes


## desert.json "places" entry of a named field ({} for the steps in between).
static func place(field: String) -> Dictionary:
	return data().get("places", {}).get(field, {})


## The scene of a field: the town has its own, everything else is the desert.
static func scene_of(field: String) -> String:
	return str(place(field).get("scene", DESERT_SCENE))


## Coming in from the south road: the maze starts at the sign.
func enter() -> void:
	current = start_field()
	visited[current] = true


## The player stands in this field's own scene (e.g. arrived in the town by teleporter).
func arrive_at(field: String) -> void:
	current = field
	visited[field] = true


## The player walks out of the screen on this side: next field of the route, out of the desert
## (desert.json "exits", e.g. north at the sign to the south road), or lost.
func walk(direction: String) -> void:
	var game_state: Node = _game_state()
	var exit: Dictionary = place(current).get("exits", {}).get(direction, {})
	if not exit.is_empty():
		game_state.travel_to(str(exit.get("scene", "")), StringName(exit.get("spawn", "")))
		return
	var next: String = graph().get(current, {}).get(direction, "")
	if next.is_empty() or not _can_pass(current, direction):
		_get_lost()
		return
	current = next
	visited[next] = true
	game_state.travel_to(scene_of(next), Language.translate(SPAWNS[OPPOSITE[direction]]))


## Whether the step from `field` in `direction` is open (routes with "required_flag" and
## "required_compass").
static func _can_pass(field: String, direction: String) -> bool:
	var key: String = "%s|%s" % [field, direction]
	var flag: String = str(_link_flags.get(key, ""))
	if not flag.is_empty() and not _game_state().story.has_flag(flag):
		return false
	return get_compass_rarity() >= int(_link_compass.get(key, -1))


## Rarity of the best desert compass the player carries (-1 = none).
static func get_compass_rarity() -> int:
	var best: int = -1
	for slot: InventorySlot in _game_state().inventory.slots:
		if not slot.is_empty() and slot.item.id == COMPASS_ITEM:
			best = maxi(best, int(slot.rarity))
	return best


## Wrong way: hours pass (never past nightfall), the screen goes dark and the player stands at
## the sign again.
func _get_lost() -> void:
	var game_state: Node = _game_state()
	lost_count += 1
	current = start_field()
	var settings: Dictionary = data()
	game_state.story.set_flag(str(settings.get("lost_flag", "desert_lost_once")))
	# The tip that sends the player to Aurelius (once, only while he hasn't told of the compass yet).
	if not game_state.story.has_flag(str(settings.get("lost_hint_until", ""))):
		game_state.story.show_hint(str(settings.get("lost_hint", "")))
	var cycle: DayCycle = game_state.day_cycle
	cycle.advance_to_hour(minf(cycle.get_hour() + float(settings.get("lost_hours", 1)),
			DayCycle.PHASE_START_HOURS[DayCycle.Phase.NIGHT]))
	game_state.pending_message = str(settings.get("lost_text", ""))
	game_state.travel_to(DESERT_SCENE, LOST_SPAWN, true)


## What stands on the current field: "sign", "bones", "ruins", "chest" or "" (only sand).
func get_mark() -> String:
	return str(place(current).get("mark", ""))


## Id of the chest on the current field ("" = none).
func get_chest() -> String:
	return str(place(current).get("chest", ""))


static func chest_data(chest_id: String) -> Dictionary:
	return data().get("chests", {}).get(chest_id, {})


func is_chest_open(chest_id: String) -> bool:
	return _game_state().story.has_flag(str(chest_data(chest_id).get("flag", "")))


## Whether a chest counts yet: desert.json "required_flag" (e.g. Zahir's lost charm only while
## his side task runs). Without it a chest is always there.
func is_chest_available(chest_id: String) -> bool:
	var required: String = str(chest_data(chest_id).get("required_flag", ""))
	return required.is_empty() or _game_state().story.has_flag(required)


## Opens a chest once: its item goes into the inventory (else the loot chest). Returns the text.
func open_chest(chest_id: String) -> String:
	var game_state: Node = _game_state()
	var chest: Dictionary = chest_data(chest_id)
	if chest.is_empty() or is_chest_open(chest_id):
		return str(data().get("empty_chest_text", ""))
	game_state.story.set_flag(str(chest.get("flag", "")))
	game_state.give_items(str(chest.get("item", "")))
	return str(chest.get("text", ""))


## Fields the compass looks for: desert.json "goals" (the town; a goal can also be
## {"place", "flag", "until"}: only from that story flag on, until the other one) and every chest
## still closed.
func get_goal_fields() -> Array[String]:
	var goals: Array[String] = []
	var story: Story = _game_state().story
	for goal: Variant in data().get("goals", []):
		if goal is Dictionary:
			var flag: String = str(goal.get("flag", ""))
			var until: String = str(goal.get("until", ""))
			var compass: int = int(goal.get("compass", -1))
			if (flag.is_empty() or story.has_flag(flag)) and (until.is_empty() or not story.has_flag(until)) 					and get_compass_rarity() >= compass:
				goals.append(str(goal.get("place", "")))
		else:
			goals.append(str(goal))
	var places: Dictionary = data().get("places", {})
	for field: String in places:
		var chest_id: String = str(places[field].get("chest", ""))
		if not chest_id.is_empty() and not is_chest_open(chest_id) and is_chest_available(chest_id):
			goals.append(field)
	return goals


## First step towards each goal from the current field, without doubles, the town's first
## (e.g. ["S", "W"] at the skeleton: south to the town, west to the chest). Empty outside the
## maze or when the player stands on the only goal.
func get_compass_directions() -> Array[String]:
	var directions: Array[String] = []
	if not graph().has(current):
		return directions
	for goal in get_goal_fields():
		var direction: String = first_step(current, goal)
		if not direction.is_empty() and not directions.has(direction):
			directions.append(direction)
	return directions


## First direction of the shortest way from `from` to `to` ("" = already there or no way).
static func first_step(from: String, to: String) -> String:
	if from == to:
		return ""
	var exits: Dictionary = graph()
	# Breadth-first search; each field remembers the direction of the first step.
	var first: Dictionary = {from: ""}
	var queue: Array[String] = [from]
	while not queue.is_empty():
		var field: String = queue.pop_front()
		for direction: String in exits.get(field, {}):
			var next: String = exits[field][direction]
			if first.has(next) or not _can_pass(field, direction):
				continue
			first[next] = direction if field == from else first[field]
			if next == to:
				return first[next]
			queue.append(next)
	return ""


## For the sand map: one entry per route whose start the player has seen: {"from", "to" (place
## names, "?" while unseen), "from_mark", "to_mark", "moves" (directions), "known" (Array[bool]:
## the player walked this step, i.e. stood on both ends)}.
func get_map_routes() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for route in routes():
		var fields: Array = route["fields"]
		var flag: String = route.get("required_flag", "")
		# A route that needs a flag (the storm paths) is drawn completely once the player has it.
		var given: bool = not flag.is_empty() and _game_state().story.has_flag(flag)
		if not flag.is_empty() and not given:
			continue
		# The way to the pyramids shows up only once walked (the compass finds it, no map).
		if int(route.get("required_compass", -1)) >= 0 and not visited.has(fields.back()):
			continue
		if not (given or visited.has(fields[0]) or visited.has(fields.back())):
			continue
		var known: Array[bool] = []
		for i in (route["moves"] as Array).size():
			known.append(given or (visited.has(fields[i]) and visited.has(fields[i + 1])))
		list.append({
			"from": _map_name(route["from"]),
			"to": _map_name(route["to"]),
			"from_mark": _map_mark(route["from"]),
			"to_mark": _map_mark(route["to"]),
			"moves": route["moves"],
			"known": known,
		})
	return list


## Name on the sand map: "?" until the player stood there or has the place's "map_flag" (e.g. the
## temple, drawn on the storm map).
func _map_name(field: String) -> String:
	var flag: String = str(place(field).get("map_flag", ""))
	var known: bool = visited.has(field) or (not flag.is_empty() and _game_state().story.has_flag(flag))
	return str(place(field).get("name", field)) if known else "?"


## Mark of a place for the map: its "mark", "town" for the town, "open" for an opened chest.
func _map_mark(field: String) -> String:
	if not visited.has(field):
		return ""
	var info: Dictionary = place(field)
	if info.has("scene"):
		return "town"
	if info.get("mark", "") == "chest" and is_chest_open(str(info.get("chest", ""))):
		return "open"
	return str(info.get("mark", ""))


func to_save_data() -> Dictionary:
	return {"current": current, "visited": visited.keys(), "lost": lost_count}


func load_save_data(saved: Dictionary) -> void:
	current = str(saved.get("current", ""))
	visited.clear()
	for field: String in saved.get("visited", []):
		visited[field] = true
	lost_count = int(saved.get("lost", 0))


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
