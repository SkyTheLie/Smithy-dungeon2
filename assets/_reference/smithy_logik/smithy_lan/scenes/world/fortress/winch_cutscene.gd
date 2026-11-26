class_name WinchCutscene
extends StoryCutscene
## The winch room in the gatehouse of the Finsterburg (dialogue "lever_pull"):
## - lever_crank: the player pulls the lever, the gears grind, the drum winds up the chain
##   (fortress/winch_turn.png), the counterweight sinks with a rumble
## - lever_jam: a hammer blow on the pawl, sparks, the winch stops dead
## - winch_strain: two bone guards tug at the winch, it only jerks and does not turn

@export var winch: NodePath
@export var lever: NodePath
@export var lever_down: Texture2D

const TURN: String = "res://assets/sprites/fortress/winch_turn.png"
const TURN_FRAMES: int = 8

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


func _jam() -> void:
	var body := node2d(winch)
	var at: Vector2 = body.global_position if body else global_position
	walk_player(PackedVector2Array([at + Vector2(40, 18)]), "left", 0.5)
	if not await wait(0.55):
		return
	AudioManager.play_sound("anvil_perfect", 0.8)
	fx.spawn("hit_hammer", at + Vector2(30, -20), Color.WHITE)
	fx.spawn("crit", at + Vector2(30, -20), Color(1.0, 0.85, 0.4))
	shake(0.3, 2.0)
	# the winch stops dead where it is
	_turn_token += 1


func _strain() -> void:
	var sprite := _winch_sprite()
	if sprite == null:
		return
	var home: Vector2 = sprite.position
	for i in 6:
		sprite.position = home + Vector2(1 if i % 2 == 0 else -1, 0)
		AudioManager.play_sound("pickaxe_hit", 0.4)
		if not await wait(0.18):
			return
	sprite.position = home
