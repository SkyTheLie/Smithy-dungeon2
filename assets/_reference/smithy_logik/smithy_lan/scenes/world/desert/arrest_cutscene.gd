class_name ArrestCutscene
extends Node
## Arrest at the south gate of Sahrim (step desert_arrest). When the dialogue "desert_arrest" is
## closed, its "on_end" sends "cutscene:arrest_lock" (with the dialogue box shut): the two guards
## take the player between them and march him along the jail lane to the jail door, the player goes
## in, the door falls shut and is locked, then `then_actions` run (the next step and the night in
## the cell). The player can't walk or talk to the guards meanwhile.

## The two guards (story NPCs), walking north and south of the player.
@export var guard_north: NodePath
@export var guard_south: NodePath
## The lane in front of the jail (scene y) and the jail door (scene coordinates, its threshold).
@export var lane_y: float = 318.0
@export var jail_door: Vector2 = Vector2(290, 302)
## Story actions after the player is locked in.
@export var then_actions: String = ""

const SPEED: float = 55.0
## How far the guards walk beside the player (y).
const SIDE: float = 13.0

signal _walk_done

var _walk_started: bool = false
var _walk_finished: bool = false
var _locking: bool = false
## true from the start of the march until the player is in the cell: no own steps.
var _holding: bool = false


func _ready() -> void:
	Events.cutscene_requested.connect(_on_cutscene)


## While the cutscene runs the player stands still between the walks (an auto walk to the spot he
## stands on blocks the keys) and the guards can't be talked to.
func _physics_process(_delta: float) -> void:
	if not _holding:
		return
	var player := _player()
	if player and not player.is_auto_walking():
		player.auto_walk(PackedVector2Array([player.global_position]))


func _set_holding(holding: bool) -> void:
	_holding = holding
	for path in [guard_north, guard_south]:
		var guard := get_node_or_null(path)
		if guard:
			guard.set("blocked", holding)


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"arrest_walk":
			_march()
		"arrest_lock":
			_lock()


func _map() -> Node2D:
	return get_parent() as Node2D


func _player() -> Player:
	return get_tree().get_first_node_in_group(Player.GROUP) as Player


func _march() -> void:
	if _walk_started:
		return
	_walk_started = true
	_set_holding(true)
	var player := _player()
	var north := get_node_or_null(guard_north) as Node2D
	var south := get_node_or_null(guard_south) as Node2D
	if player == null:
		_finish_walk()
		return
	var start_x: float = clampf(_map().to_local(player.global_position).x, -20.0, jail_door.x - 40.0)
	# 1. the guards grab the player from both sides (on the lane in front of the gate)
	player.auto_walk(_global([Vector2(start_x, lane_y)]), "right", SPEED)
	await _together([
		_walk_npc.bind(north, [Vector2(start_x, lane_y - SIDE)], "right"),
		_walk_npc.bind(south, [Vector2(start_x, lane_y + SIDE)], "right"),
		_walk_player.bind(player),
	])
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.35, false).timeout
	if not is_inside_tree():
		return
	# 2. side by side along the jail lane to the door
	player = _player()
	if player:
		player.auto_walk(_global([Vector2(jail_door.x, lane_y)]), "right", SPEED)
	await _together([
		_walk_npc.bind(north, [Vector2(jail_door.x, lane_y - SIDE)], "right"),
		_walk_npc.bind(south, [Vector2(jail_door.x, lane_y + SIDE)], "right"),
		_walk_player.bind(player),
	])
	if not is_inside_tree():
		return
	# 3. the north guard steps aside, the south guard stays behind the player
	await _walk_npc(north, [Vector2(jail_door.x + 24.0, lane_y - SIDE)], "left")
	_finish_walk()


func _finish_walk() -> void:
	_walk_finished = true
	_walk_done.emit()


func _lock() -> void:
	if _locking:
		return
	_locking = true
	if not _walk_started:
		_march()
	if not _walk_finished:
		await _walk_done
	if not is_inside_tree():
		return
	var player := _player()
	if player:
		AudioManager.play_sound("door", 0.8)
		player.auto_walk(_global([jail_door]), "up", SPEED * 0.7)
		await _walk_player(player)
		if not is_inside_tree():
			return
		if is_instance_valid(player):
			var tween := create_tween()
			tween.tween_property(player, "modulate:a", 0.0, 0.35)
			await tween.finished
	if not is_inside_tree():
		return
	# the guard behind closes the door and turns the key
	var south := get_node_or_null(guard_south) as Node2D
	await _walk_npc(south, [Vector2(jail_door.x, lane_y + 2.0)], "up")
	if not is_inside_tree():
		return
	AudioManager.play_sound("door", 0.6)
	await get_tree().create_timer(0.45, false).timeout
	if not is_inside_tree():
		return
	AudioManager.play_sound("unlock", 0.7)
	await get_tree().create_timer(0.9, false).timeout
	if not is_inside_tree():
		return
	# the player stays invisible: the next scene (the cell) brings its own player
	_set_holding(false)
	GameState.run_story_action(then_actions)


func _global(points: Array) -> PackedVector2Array:
	var way := PackedVector2Array()
	for point: Vector2 in points:
		way.append(_map().to_global(point))
	return way


## Waits until the player has walked his auto_walk path.
func _walk_player(player: Player) -> void:
	if player != null and is_instance_valid(player) and player.is_auto_walking():
		await player.auto_walk_finished


## A story NPC walks along `points` (scene coordinates) with its walk frames, then turns to `facing`.
func _walk_npc(npc: Node2D, points: Array, facing: String) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	var body_shape := npc.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape:
		body_shape.set_deferred("disabled", true)
	for target: Vector2 in _global(points):
		while is_inside_tree() and is_instance_valid(npc) and npc.global_position.distance_to(target) > 1.0:
			var delta: float = get_physics_process_delta_time()
			npc.call("_walk_step", target - npc.global_position, SPEED, delta)
			await get_tree().physics_frame
		if is_instance_valid(npc):
			npc.global_position = target
	if is_instance_valid(npc):
		npc.call("_face", facing)


## Runs several walks (coroutines) at the same time and waits until all of them are done.
func _together(walks: Array[Callable]) -> void:
	var state: Dictionary = {"left": walks.size()}
	for walk in walks:
		_counted(walk, state)
	while is_inside_tree() and int(state["left"]) > 0:
		await get_tree().physics_frame


func _counted(walk: Callable, state: Dictionary) -> void:
	await walk.call()
	state["left"] = int(state["left"]) - 1
