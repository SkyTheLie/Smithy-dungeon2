class_name DepthLayer
extends Node2D
## A layer far below the walkable ground (e.g. the canyon floor of the Lavaberg): it moves slower
## than the camera, so it looks deep down. `factor` 1 = moves like the ground, 0 = stays on screen.
## When the camera centre is at `anchor` (scene pixels), the layer sits exactly where it was placed.

@export_range(0.0, 1.0) var factor: float = 0.8
@export var anchor: Vector2 = Vector2.ZERO


func _ready() -> void:
	# after the camera has moved this frame
	process_priority = 100
	_follow_camera()


func _process(_delta: float) -> void:
	_follow_camera()


func _follow_camera() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	# whole pixels, so the pixel art stays sharp
	position = ((camera.get_screen_center_position() - anchor) * (1.0 - factor)).round()
