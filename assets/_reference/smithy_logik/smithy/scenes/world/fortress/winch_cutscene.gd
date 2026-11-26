class_name WinchCutscene
extends StoryCutscene
## The winch room in the gatehouse of the Finsterburg (dialogue "lever_pull"):
## - lever_crank: the player pulls the lever, the gears grind, the drum winds up the chain
##   (fortress/winch_turn.png), the counterweight sinks with a rumble
## - lever_jam: the player swings the hammer at the pawl by the lever, sparks, the winch stops dead
## - winch_strain: two bone guards tug at the winch, it only jerks and does not turn
## - guards_rush: the other bone guards (`rushers`, StoryNpcs) run out along their leave_path to the
##   gate and are gone
## - knight_leaves: the Finsterritter (`knight`) walks out along his leave_path and is gone
## (the flag gatehouse_cleared at the end of the talk keeps them away from then on)

@export var winch: NodePath
@export var lever: NodePath
@export var lever_down: Texture2D
## The two guards left at the winch: they jerk along while they tug at it (winch_strain).
@export var pullers: Array[NodePath] = []
## StoryNpcs that run out of the gatehouse (guards_rush); their way is their leave_path.
@export var rushers: Array[NodePath] = []
## The Finsterritter at the door (knight_leaves); his way is his leave_path.
@export var knight: NodePath

const RUSH_SPEED: float = 120.0
const KNIGHT_SPEED: float = 70.0

const TURN: String = "res://assets/sprites/fortress/winch_turn.png"
const TURN_FRAMES: int = 8
## npc_id of the lever's talk spot (the hammer gesture walks beside it).
const LEVER_NPC: String = "fortress_lever"

var _still: Texture2D
## Raised to stop a running _turn.
var _turn_token: int = 0


func _play_beat(id: String) -> bool:
	match id:
		"lever_crank":
			_crank()
		"lever_jam":
			_jam()
		"winch_strain":
			_strain()
		"guards_rush":
			for path in rushers:
				_walk_out(node2d(path), RUSH_SPEED)
		"knight_leaves":
			_walk_out(node2d(knight), KNIGHT_SPEED)
		_:
			return false
	return true


func _winch_sprite() -> Sprite2D:
	var body := node2d(winch)
	return body.get_node_or_null("Sprite2D") as Sprite2D if body else null


## Shows the turn sheet on the winch; `frames` steps at `fps` (negative fps = backwards).
func _turn(steps: int, fps: float) -> void:
	var sprite := _winch_sprite()
	if sprite == null:
		return
	if _still == null:
		_still = sprite.texture
	sprite.texture = load(TURN)
	sprite.hframes = TURN_FRAMES
	_turn_token += 1
	var token: int = _turn_token
	for i in steps:
		if token != _turn_token or not is_instance_valid(sprite):
			return
		sprite.frame = posmod(i if fps > 0.0 else -i, TURN_FRAMES)
		if not await wait(1.0 / absf(fps)):
			return


func _crank() -> void:
	var handle := node2d(lever)
	if handle:
		var sprite := handle.get_node_or_null("Sprite2D") as Sprite2D
		if sprite and lever_down:
			sprite.texture = lever_down
		fx.spawn("impact", handle.global_position + Vector2(0, -20), Color.WHITE)
	AudioManager.play_sound("rock_break", 0.5)
	var body := node2d(winch)
	shake(1.8, 1.0)
	if body:
		for i in 3:
			fx.spawn("earth_hit", body.global_position + Vector2(randf_range(-40, 40), randf_range(-6, 6)), Color.WHITE)
	await _turn(18, 9.0)
	if is_inside_tree():
		AudioManager.play_sound("rock_break", 0.9)
		if body:
			fx.spawn("area_quake", body.global_position + Vector2(0, 8), Color.WHITE)
		_turn(80, 9.0)


## The pawl sits in the lever's housing (the winch is behind the wall): the player steps beside the
## lever and swings the hammer at it (gesture "hammer", fight pose), then the winch stops dead.
func _jam() -> void:
	var body := player()
	if body:
		await NpcActing.play(body, "hammer", LEVER_NPC)
	if not is_inside_tree():
		return
	var handle := node2d(lever)
	if handle:
		fx.spawn("crit", handle.global_position + Vector2(0, -18), Color(1.0, 0.85, 0.4))
	AudioManager.play_sound("anvil_perfect", 0.8)
	shake(0.3, 2.0)
	# the winch stops dead where it is
	_turn_token += 1


func _strain() -> void:
	var sprite := _winch_sprite()
	if sprite == null:
		return
	var home: Vector2 = sprite.position
	# the guards' figures (SneakGuard: an AnimatedSprite2D child) lean back with every tug
	var figures: Array[Node2D] = []
	var figure_homes: Array[Vector2] = []
	for path in pullers:
		var guard := node2d(path)
		var figure := guard.get_node_or_null("AnimatedSprite2D") as Node2D if guard else null
		if figure == null and guard:
			for child in guard.get_children():
				if child is AnimatedSprite2D:
					figure = child
		if figure:
			figures.append(figure)
			figure_homes.append(figure.position)
	for i in 6:
		sprite.position = home + Vector2(1 if i % 2 == 0 else -1, 0)
		for k in figures.size():
			if is_instance_valid(figures[k]):
				figures[k].position = figure_homes[k] + Vector2(0, 2 if i % 2 == 0 else 0)
		AudioManager.play_sound("pickaxe_hit", 0.4)
		if not await wait(0.18):
			return
	sprite.position = home
	for k in figures.size():
		if is_instance_valid(figures[k]):
			figures[k].position = figure_homes[k]


## `npc` walks its leave_path (map coordinates) and is hidden at the end.
func _walk_out(npc: Node2D, speed: float) -> void:
	if npc == null or not npc.visible:
		return
	var points := PackedVector2Array()
	for point in npc.get("leave_path") as PackedVector2Array:
		points.append((npc.get_parent() as Node2D).to_global(point))
	await walk_npc(npc, points, speed)
	if is_instance_valid(npc):
		npc.hide()
