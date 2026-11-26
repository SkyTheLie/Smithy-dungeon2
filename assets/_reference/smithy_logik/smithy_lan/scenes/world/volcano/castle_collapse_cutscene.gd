class_name CastleCollapseCutscene
extends Node
## The end of the goblin castle (part 2, chapter 8): after the player took the fire crystal the
## dragon wakes one last time and brings the castle down with himself. The dialogue lines start
## each part with the story action "cutscene:<id>" (Events.cutscene_requested) and wait for it.
## - dragon_wake: the dragon glows red hot and trembles
## - castle_collapse: the whole room shakes and turns lava red; the dialogue then fades out to the
##   deep mine (travel_fade)

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


func _ready() -> void:
	Events.cutscene_requested.connect(_on_cutscene)


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"dragon_wake":
			_wake_dragon()
		"castle_collapse":
			_collapse()


func _wake_dragon() -> void:
	if dragon_sprite:
		create_tween().tween_property(dragon_sprite, "modulate", COLOR_HOT, WAKE_TIME)
	if dragon_glow:
		create_tween().tween_property(dragon_glow, "energy", 3.0, WAKE_TIME)
	if dragon_sprite:
		var home: Vector2 = dragon_sprite.offset
		var end_time: float = Time.get_ticks_msec() / 1000.0 + WAKE_TIME
		while Time.get_ticks_msec() / 1000.0 < end_time and is_instance_valid(dragon_sprite):
			dragon_sprite.offset = home + Vector2(randf_range(-WAKE_SHAKE, WAKE_SHAKE), 0).round()
			await get_tree().process_frame
		if is_instance_valid(dragon_sprite):
			dragon_sprite.offset = home


## The camera shakes and a lava red veil covers the screen.
func _collapse() -> void:
	AudioManager.play_sound("rock_break", 0.6)
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color(COLOR_LAVA, 0.0)
	layer.add_child(veil)
	create_tween().tween_property(veil, "color", COLOR_LAVA, COLLAPSE_TIME)
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var home: Vector2 = camera.offset
	var end_time: float = Time.get_ticks_msec() / 1000.0 + COLLAPSE_TIME
	while Time.get_ticks_msec() / 1000.0 < end_time and is_instance_valid(camera):
		camera.offset = home + Vector2(randf_range(-COLLAPSE_SHAKE, COLLAPSE_SHAKE), randf_range(-COLLAPSE_SHAKE, COLLAPSE_SHAKE)).round()
		await get_tree().process_frame
	if is_instance_valid(camera):
		camera.offset = home
