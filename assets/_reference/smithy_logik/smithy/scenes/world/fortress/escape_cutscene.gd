class_name EscapeCutscene
extends StoryCutscene
## Flight from the Finsterburg (step carry_mage). The dialogue lines start each part with the
## story action "cutscene:<id>" (Events.cutscene_requested):
## - escape_hide: the player (with Aurelius) runs from the keep door behind a wall
## - escape_lake_out: the dark Lake bursts out of the keep door and looks around
## - escape_lake_runs: he runs south, to the main gate, and is gone
## - sally_out: at the sally port (bottom left) Faelan waits; after the talk he slips out first and the
##   player (Aurelius at his side) follows by himself, then the story travels on into the west moat
##   (MoatEscapeCutscene)
## The intro (escape_start) is a side dialogue of the narrator that ends with escape_intro_done, so
## it does not play again when a guard sends the player back to the start.

## Where the player hides (scene coordinates, walked one after another).
@export var hide_path: PackedVector2Array = []
## The keep door the dark Lake comes out of, and his way to the main gate (scene coordinates).
@export var lake_door: Vector2 = Vector2.ZERO
@export var lake_path: PackedVector2Array = []
## The dark Lake (a Sprite2D with the resident sheet lake_dark, hidden until he comes out).
@export var dark_lake: Sprite2D
## Faelan at the sally port (a Sprite2D with his resident sheet): leads the way out at "sally_out".
@export var guide: NodePath
## The way out through the sally port (scene coordinates), walked by Faelan and then the player.
@export var sally_path: PackedVector2Array = []
## The Companion (Aurelius) that fades out with the player in the sally port.
@export var companion: NodePath

const LAKE_SPEED: float = 110.0
const GUIDE_SPEED: float = 70.0


func _ready() -> void:
	super()
	if dark_lake:
		dark_lake.hide()


func _play_beat(id: String) -> bool:
	match id:
		"escape_hide":
			_hide()
		"escape_lake_out":
			_lake_out()
		"escape_lake_runs":
			_lake_runs()
		"sally_out":
			_sally_out()
		_:
			return false
	return true


func _map() -> Node2D:
	return get_parent() as Node2D


func _hide() -> void:
	var smith := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if smith == null or hide_path.is_empty():
		return
	var way := PackedVector2Array()
	for point in hide_path:
		way.append(_map().to_global(point))
	smith.auto_walk(way, "right")


func _lake_out() -> void:
	if dark_lake == null:
		return
	dark_lake.global_position = _map().to_global(lake_door)
	dark_lake.region_rect = CharacterBaker.get_frame_rect("down")
	dark_lake.modulate.a = 0.0
	dark_lake.show()
	create_tween().tween_property(dark_lake, "modulate:a", 1.0, 0.25)
	AudioManager.play_sound("door", 0.8)
	# he looks around the yard
	for direction in ["left", "down", "left", "down"]:
		if not is_inside_tree():
			return
		if not await wait(0.45):
			return
		if not is_instance_valid(dark_lake):
			return
		dark_lake.region_rect = CharacterBaker.get_frame_rect(direction)


func _lake_runs() -> void:
	if dark_lake == null or not dark_lake.visible:
		return
	var frame: int = 0
	for point in lake_path:
		var target: Vector2 = _map().to_global(point)
		while is_inside_tree() and is_instance_valid(dark_lake) and dark_lake.global_position.distance_to(target) > 1.0:
			var step: Vector2 = target - dark_lake.global_position
			var direction: String = ("right" if step.x > 0.0 else "left") if absf(step.x) > absf(step.y) \
					else ("down" if step.y > 0.0 else "up")
			frame += 1
			dark_lake.region_rect = CharacterBaker.get_frame_rect(direction, 1 + (frame / 5) % 6)
			dark_lake.global_position += step.limit_length(LAKE_SPEED * get_physics_process_delta_time())
			await get_tree().physics_frame
	if is_instance_valid(dark_lake):
		var tween := create_tween()
		tween.tween_property(dark_lake, "modulate:a", 0.0, 0.3)
		tween.tween_callback(dark_lake.hide)


## Faelan walks out through the sally port and fades; the player (Aurelius along) follows by himself
## and fades in the gate as well.
func _sally_out() -> void:
	var faelan := get_node_or_null(guide) as Sprite2D
	var way := PackedVector2Array()
	for point in sally_path:
		way.append(_map().to_global(point))
	if faelan:
		_walk_sprite(faelan, way)
	if not is_inside_tree():
		return
	if not await wait(0.5):
		return
	var smith := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if smith and not way.is_empty():
		smith.auto_walk(way, "left", GUIDE_SPEED)
	if not is_inside_tree():
		return
	if not await wait(1.2):
		return
	var mage := get_node_or_null(companion) as Node2D
	for node: Node2D in [smith, mage]:
		if is_instance_valid(node):
			create_tween().tween_property(node, "modulate:a", 0.0, 0.4)


## A resident Sprite2D walks along `way` (global points) with walk frames, then fades out.
func _walk_sprite(sprite: Sprite2D, way: PackedVector2Array) -> void:
	var frame: int = 0
	for target in way:
		while is_inside_tree() and is_instance_valid(sprite) and sprite.global_position.distance_to(target) > 1.0:
			var step: Vector2 = target - sprite.global_position
			var direction: String = ("right" if step.x > 0.0 else "left") if absf(step.x) > absf(step.y) 					else ("down" if step.y > 0.0 else "up")
			frame += 1
			sprite.region_rect = CharacterBaker.get_frame_rect(direction, 1 + (frame / 6) % 6)
			sprite.global_position += step.limit_length(GUIDE_SPEED * get_physics_process_delta_time())
			await get_tree().physics_frame
	if is_instance_valid(sprite):
		create_tween().tween_property(sprite, "modulate:a", 0.0, 0.3)
