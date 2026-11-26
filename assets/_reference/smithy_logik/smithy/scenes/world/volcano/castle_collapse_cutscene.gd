class_name CastleCollapseCutscene
extends StoryCutscene
## The end of the goblin castle (part 2, chapter 8): after the player took the fire crystal the
## dragon wakes one last time and brings the castle down with himself. The dialogue lines start
## each part with the story action "cutscene:<id>" (Events.cutscene_requested) and wait for it.
## - dragon_wake: the dragon glows red hot and trembles
## - castle_collapse: the whole room shakes and turns lava red (a veil over the map, under the
##   HUD and the dialogue box)
## - castle_escape: the player runs to the door, stones rain down, behind him the dragon sinks
##   into the lava and the room goes black; the dialogue then fades out to the deep mine
##   (travel_fade)

## Seconds the dragon trembles / the room shakes.
const WAKE_TIME: float = 2.0
const COLLAPSE_TIME: float = 3.0
## How far the dragon / the camera jumps while shaking (pixels).
const WAKE_SHAKE: float = 2.0
const COLLAPSE_SHAKE: float = 6.0
const COLOR_HOT: Color = Color(1.6, 0.75, 0.5)
const COLOR_LAVA: Color = Color(1.0, 0.3, 0.05, 0.55)

@export var dragon_sprite: AnimatedSprite2D
@export var dragon_glow: PointLight2D
## Where the player runs to (map coordinates), just in front of the door.
@export var escape_point: Vector2 = Vector2(0, 205)

## Seconds of the escape run; how deep the dragon sinks meanwhile (pixels).
const ESCAPE_TIME: float = 2.4
const SINK_DEPTH: float = 60.0
## Seconds for the run itself (from the foot of the gold mountain to the door).
const RUN_TIME: float = 0.8

var _veil: ColorRect


func _ready() -> void:
	super()


func _play_beat(id: String) -> bool:
	match id:
		"dragon_wake":
			_wake_dragon()
		"castle_collapse":
			_collapse()
		"castle_escape":
			_escape()
		_:
			return false
	return true


func _wake_dragon() -> void:
	if dragon_sprite:
		create_tween().tween_property(dragon_sprite, "modulate", COLOR_HOT, WAKE_TIME)
	if dragon_glow:
		create_tween().tween_property(dragon_glow, "energy", 3.0, WAKE_TIME)
	if dragon_sprite:
		var home: Vector2 = dragon_sprite.offset
		var left: float = WAKE_TIME  # game time, like the tweens above
		while left > 0.0 and is_instance_valid(dragon_sprite) and is_inside_tree():
			dragon_sprite.offset = home + Vector2(randf_range(-WAKE_SHAKE, WAKE_SHAKE), 0).round()
			await get_tree().process_frame
			left -= get_process_delta_time()
		if is_instance_valid(dragon_sprite):
			dragon_sprite.offset = home


## The camera shakes and a lava red veil covers the map (in the world: HUD and box stay clear).
func _collapse() -> void:
	AudioManager.play_sound("rock_break", 0.6)
	_veil = world_tint(Color(COLOR_LAVA, 0.0))
	create_tween().tween_property(_veil, "color", COLOR_LAVA, COLLAPSE_TIME)
	await shake(COLLAPSE_TIME, COLLAPSE_SHAKE)


## The player runs for the door while the castle comes down behind him.
func _escape() -> void:
	var smith := player()
	var parent := get_parent() as Node2D
	var exit: Vector2 = parent.to_global(escape_point) if parent else escape_point
	if smith:
		walk_player(PackedVector2Array([exit]), "down", RUN_TIME)
	shake(ESCAPE_TIME + 0.6, COLLAPSE_SHAKE)
	if dragon_sprite:
		var sink := create_tween().set_parallel()
		sink.tween_property(dragon_sprite, "offset:y", dragon_sprite.offset.y + SINK_DEPTH, ESCAPE_TIME) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		sink.tween_property(dragon_sprite, "modulate", Color(1.6, 0.4, 0.1, 0.0), ESCAPE_TIME)
	if dragon_glow:
		create_tween().tween_property(dragon_glow, "energy", 0.0, ESCAPE_TIME)
	# stones rain down around the player and in the room behind him
	var rocks: int = 9
	for i in rocks:
		var near: Vector2 = smith.global_position if smith else exit
		AudioManager.play_sound("rock_break", randf_range(0.5, 0.9))
		fx.spawn("impact" if i % 2 == 0 else "glow", near + Vector2(randf_range(-60, 60), randf_range(-90, -10)),
				Color(1.0, 0.55, 0.25))
		if not await wait(ESCAPE_TIME / rocks):
			return
	# the room goes dark behind him
	var black := world_tint(Color(0, 0, 0, 0), 4)
	var out := create_tween()
	out.tween_property(black, "color", Color(0, 0, 0, 1), 0.6)
