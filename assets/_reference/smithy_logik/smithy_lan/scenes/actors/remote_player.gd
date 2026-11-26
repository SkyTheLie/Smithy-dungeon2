class_name RemotePlayer
extends Node2D
## The figure of the other player in LAN play (Net): no keys, no camera, no collision, no story.
## Net puts it beside the own figure on the same map and moves it ~20 times a second (move_to);
## between two updates it glides there, so it doesn't jump. Above the head stands the name.

## How fast the figure catches up with the last place it got (share of the way per second).
const FOLLOW_RATE: float = 14.0
## Further away than this (pixels) it jumps there at once (e.g. a door on the same map).
const SNAP_DISTANCE: float = 96.0

var _target: Vector2 = Vector2.ZERO
var _has_target: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _name_label: Label = $NameLabel


## Look and name, once before it enters the scene.
func setup(player_name: String, look: Appearance) -> void:
	if not is_node_ready():
		await ready
	_name_label.text = player_name
	_sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(look))
	_sprite.scale = Vector2.ONE * look.get_scale()
	_sprite.play("idle_down")


## The last known place and animation of the other player (from Net).
func move_to(at: Vector2, animation: String, speed: float) -> void:
	if not _has_target or global_position.distance_to(at) > SNAP_DISTANCE:
		global_position = at
	_target = at
	_has_target = true
	# Mining and chopping animations are not in the baked frames here: then he just stands.
	var shown: StringName = StringName(animation)
	if _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(shown):
		shown = &"idle_down"
	if _sprite.sprite_frames and _sprite.animation != shown and _sprite.sprite_frames.has_animation(shown):
		_sprite.play(shown)
	_sprite.speed_scale = speed


func _process(delta: float) -> void:
	if _has_target:
		global_position = global_position.lerp(_target, minf(FOLLOW_RATE * delta, 1.0))
