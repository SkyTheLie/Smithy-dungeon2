class_name Pickup
extends Node3D
## Something lying on the floor: a coin, a heart, a bomb or a key. Walking over it picks it up
## (a heart only if the player is hurt). Pops out of the floor when it appears.

const KINDS: Dictionary[String, String] = {
	"coin": "res://assets/sprites/ui/slot/coin.png",
	"heart": "res://assets/sprites/items/arena_heart.png",
	"bomb": "res://assets/sprites/skills/smoke_bomb.png",
	"key": "res://assets/sprites/items/smithy_key.png",
}
const PICK_DISTANCE: float = 0.8
const HEIGHT: float = 0.55

var kind: String = "coin"
var run: RunState
var player: Node3D

var _sprite: Sprite3D
var _time: float = 0.0
var _ready_to_take: float = 0.4


static func icon(kind_name: String) -> Texture2D:
	return load(KINDS.get(kind_name, KINDS["coin"])) as Texture2D


func setup(kind_name: String, run_state: RunState, the_player: Node3D) -> void:
	kind = kind_name
	run = run_state
	player = the_player


func _ready() -> void:
	_sprite = Fx.billboard(icon(kind), HEIGHT)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(_sprite)
	_sprite.position.y = 1.0
	var pop := create_tween()
	pop.tween_property(_sprite, "position:y", HEIGHT / 2.0 + 0.05, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	_time = randf() * TAU


func _physics_process(delta: float) -> void:
	_time += delta
	_ready_to_take -= delta
	if _ready_to_take > 0.0 or player == null or run == null:
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	# Magnet: pickups fly to the player.
	if run.stats.has("magnet"):
		var effects: Dictionary = Content.player().get("effects", {})
		if offset.length() < float(effects.get("magnet_range", 4.0)):
			global_position += offset.normalized() * minf(offset.length(), float(effects.get("magnet_speed", 7.0)) * delta)
	if offset.length() < PICK_DISTANCE and _take():
		Fx.puff(get_parent() as Node3D, global_position + Vector3(0, 0.3, 0), "spark", 0.3)
		queue_free()


## Gives the thing to the player; false if it cannot be taken (full life).
func _take() -> bool:
	match kind:
		"coin":
			run.add_coins(1)
			AudioManager.play_sound("coin")
			return true
		"heart":
			if not run.heal(run.heart_value()):
				return false
		"bomb":
			run.add_bombs(1)
		"key":
			run.add_keys(1)
	AudioManager.play_sound("pickup")
	return true
