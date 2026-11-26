class_name CageCutscene
extends StoryCutscene
## The cell at the south gate of Sahrim (dialogues "cage_morning" and "desert_lord_cage"):
## - camel_arrives: the loaded camel and Ulrich come in through the south gate (props/draft_camel_walk.png)
## - lord_arrives: Ssarok, two spear warriors and Ulrich walk up from the gate to the cell
## - cell_open: a guard draws back the bolt, the door opens, the player steps out stiffly

@export var camel: NodePath
@export var ulrich: NodePath
@export var lord: NodePath
@export var guard_a: NodePath
@export var guard_b: NodePath
@export var escort: NodePath
## The open door over the jail house (hidden until the bolt is drawn).
@export var door_open: NodePath
## Where the south gate is (map coordinates).
@export var gate: Vector2 = Vector2(-12, 345)

const CAMEL_WALK: String = "res://assets/sprites/props/draft_camel_walk.png"
const CAMEL_FRAMES: int = 8

## Seconds without an open dialogue before the figure the locked-in player waits for talks again
## (the player closed its dialogue with "x" and can't walk over to it).
const RETALK_DELAY: float = 2.5

## Where each of Ssarok's group stands at the cell (they start at the gate).
var _homes: Dictionary = {}
## true once the group walked up to the cell (lord_arrives played).
var _arrived: bool = false
## Seconds the locked-in player has waited without an open dialogue.
var _idle: float = 0.0


func _ready() -> void:
	super._ready()
	# Ssarok's group waits at the gate until the beat walks them up (they appear with the flag)
	if _group_waits():
		_to_gate.call_deferred()
	# Ulrich's talk sets the flag while the scene is open: straight to the gate, not first at the cell
	GameState.story.changed.connect(func() -> void:
		if _homes.is_empty() and _group_waits():
			_to_gate())


func _group_waits() -> bool:
	var story: Story = GameState.story
	return story.has_flag("ulrich_went_to_lord") and not story.has_flag("storm_map_owned")


## The player can't leave the cell: whoever has to talk to him next starts again by himself.
func _process(delta: float) -> void:
	var door := get_node_or_null(door_open) as CanvasItem
	if GameState.story.step != "desert_cage" or (door and door.visible):
		return
	for npc in get_tree().get_nodes_in_group(StoryNpc.GROUP):
		var box := npc.get_node_or_null("DialogueBox") as CanvasItem
		if box and box.visible:
			_idle = 0.0
			return
	_idle += delta
	if _idle < RETALK_DELAY:
		return
	_idle = 0.0
	for path in [lord, ulrich]:
		var npc := node2d(path)
		if npc and npc.visible and GameState.story.npc_has_news(str(npc.get("npc_id"))) and npc.has_method("talk"):
			npc.call("talk")
			return


func _play_beat(id: String) -> bool:
	match id:
		"camel_arrives":
			_camel_arrives()
		"lord_arrives":
			_lord_arrives()
		"cell_open":
			_cell_open()
		_:
			return false
	return true


func _gate() -> Vector2:
	var parent := get_parent() as Node2D
	return parent.to_global(gate) if parent else gate


func _group() -> Array[Node2D]:
	var people: Array[Node2D] = []
	for path in [lord, guard_a, guard_b, escort]:
		var npc := node2d(path)
		if npc:
			people.append(npc)
	return people


func _to_gate() -> void:
	var i: int = 0
	for npc in _group():
		_homes[npc] = npc.global_position
		npc.global_position = _gate() + Vector2(-18 + 12 * i, 10 + 4 * (i % 2))
		face_npc(npc, "up")
		i += 1


func _camel_arrives() -> void:
	var body := node2d(camel)
	var sprite := body.get_node_or_null("Sprite2D") as Sprite2D if body else null
	var merchant := node2d(ulrich)
	var start: Vector2 = _gate()
	if merchant:
		var merchant_home: Vector2 = merchant.global_position
		merchant.global_position = start + Vector2(-26, 6)
		walk_npc(merchant, PackedVector2Array([start + Vector2(-26, -30), Vector2(merchant_home.x, start.y - 30),
				merchant_home]), 80.0, "up")
	if body == null or sprite == null:
		return
	var home: Vector2 = body.global_position
	var still: Texture2D = sprite.texture
	body.global_position = start + Vector2(0, -6)
	sprite.texture = load(CAMEL_WALK)
	sprite.hframes = CAMEL_FRAMES
	sprite.flip_h = true  # the sheet walks to the left, the camel goes right
	var walked: float = 0.0
	while is_inside_tree() and is_instance_valid(body) and body.global_position.distance_to(home) > 1.0:
		var delta: float = get_process_delta_time()
		body.global_position += (home - body.global_position).limit_length(42.0 * delta)
		walked += delta
		sprite.frame = int(walked * 9.0) % CAMEL_FRAMES
		await get_tree().process_frame
	if not is_instance_valid(body):
		return
	body.global_position = home
	sprite.texture = still
	sprite.hframes = 1
	sprite.frame = 0
	sprite.flip_h = false


func _lord_arrives() -> void:
	if _arrived:
		return  # the dialogue started again (closed with "x"): they already stand at the cell
	_arrived = true
	if _homes.is_empty():
		_to_gate()
	var i: int = 0
	for npc in _group():
		var home: Vector2 = _homes.get(npc, npc.global_position)
		var turn := Vector2(npc.global_position.x, home.y + 26)
		var facing: String = "left" if npc == node2d(escort) else "up"
		_walk_late(npc, PackedVector2Array([turn, Vector2(home.x, turn.y), home]), facing, 0.2 * i)
		i += 1


func _walk_late(npc: Node2D, points: PackedVector2Array, facing: String, delay: float) -> void:
	if delay > 0.0 and not await wait(delay):
		return
	walk_npc(npc, points, 90.0, facing)


func _cell_open() -> void:
	var guard := node2d(guard_b)
	var door := get_node_or_null(door_open) as CanvasItem
	var door_spot: Vector2 = (door as Node2D).global_position if door is Node2D else global_position
	if door and door.visible:
		return  # the dialogue started again after the cell was opened: the player is out already
	if guard:
		# beside the door on the right, so the player steps out in front of the door next to Ulrich
		await walk_npc(guard, PackedVector2Array([Vector2(door_spot.x + 22, guard.global_position.y),
				door_spot + Vector2(22, 44)]), 60.0, "left")
	AudioManager.play_sound("door", 0.8)
	shake(0.15, 1.0)
	if door:
		door.show()
	if not await wait(0.4):
		return
	var body := player()
	if body:
		# out of the cell, through the door and a step onto the lane, stiff and slow
		walk_player(PackedVector2Array([Vector2(door_spot.x, body.global_position.y), door_spot + Vector2(0, 30),
				door_spot + Vector2(0, 46)]), "left", 2.0)
