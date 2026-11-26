class_name StoryCutscene
extends Node2D
## Base for the story cut scenes that play while the dialogue box is hidden (a line with "hide_for"
## and "cutscene:<id>", see DialogueBox). A subclass overrides _play_beat(id) -> bool (true = the id
## was its own) and uses the helpers here: effects (WorldVfx), walking figures, sheets, shaking.

var fx: WorldVfx


func _ready() -> void:
	Events.cutscene_requested.connect(_on_cutscene_requested)
	fx = WorldVfx.new()
	add_child(fx)


func _on_cutscene_requested(cutscene_id: String) -> void:
	if is_inside_tree():
		_play_beat(cutscene_id)


## Override: plays the beat `id`; false if the id is not one of this cut scene.
func _play_beat(_id: String) -> bool:
	return false


func node2d(path: NodePath) -> Node2D:
	return get_node_or_null(path) as Node2D if not path.is_empty() else null


func player() -> Node2D:
	return get_tree().get_first_node_in_group(&"player") as Node2D


func figure_of(npc: Node2D) -> Sprite2D:
	return npc.get_node_or_null("Figure") as Sprite2D if npc else null


## Waits `seconds`; false if the cut scene left the tree meanwhile (stop the beat then).
func wait(seconds: float) -> bool:
	if not is_inside_tree():
		return false
	await get_tree().create_timer(seconds, false).timeout
	return is_inside_tree()


## The player walks along `points` (global) by himself, `seconds` for the whole way.
func walk_player(points: PackedVector2Array, facing: String, seconds: float) -> void:
	var body := player()
	if body == null or not body.has_method("auto_walk") or points.is_empty():
		return
	var length: float = body.global_position.distance_to(points[0])
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
	body.call("auto_walk", points, facing, maxf(40.0, length / maxf(0.1, seconds)))


## Turns the player to `facing` where he stands.
func face_player(facing: String) -> void:
	var body := player()
	if body and body.has_method("auto_walk"):
		body.call("auto_walk", PackedVector2Array([body.global_position]), facing)


## A StoryNpc (or anything with _walk_step/_face) walks along `points` (global) at `speed`,
## through everything; looks at `facing` at the end ("" = as it walked). Awaitable.
func walk_npc(npc: Node2D, points: PackedVector2Array, speed: float, facing: String = "") -> void:
	if npc == null or not npc.has_method("_walk_step"):
		return
	var shape := npc.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)
	# a newer walk of the same figure takes over (the older one stops)
	var token: int = int(npc.get_meta(&"cutscene_walk", 0)) + 1
	npc.set_meta(&"cutscene_walk", token)
	for target in points:
		while is_inside_tree() and is_instance_valid(npc) and npc.global_position.distance_to(target) > 1.0:
			if int(npc.get_meta(&"cutscene_walk", 0)) != token:
				return
			npc.call("_walk_step", target - npc.global_position, speed, get_process_delta_time())
			await get_tree().process_frame
		if not is_instance_valid(npc) or int(npc.get_meta(&"cutscene_walk", 0)) != token:
			return
		npc.global_position = target
	if not facing.is_empty() and is_instance_valid(npc):
		npc.set("facing", facing)
		npc.call("_face", facing)


## Turns a StoryNpc to `facing`.
func face_npc(npc: Node2D, facing: String) -> void:
	if npc and npc.has_method("_face"):
		npc.set("facing", facing)
		npc.call("_face", facing)


## Shows frame `index` of a one-row sheet with square cells of `cell` px on the figure of `npc`.
func show_frame(npc: Node2D, path: String, cell: int, index: int) -> void:
	var figure := figure_of(npc)
	if figure == null or not ResourceLoader.exists(path):
		return
	figure.texture = load(path)
	figure.region_enabled = true
	figure.region_rect = Rect2(index * cell, 0, cell, cell)


## Plays frames `from`..`to` of a sheet on `npc` in `seconds`. Awaitable.
func play_sheet(npc: Node2D, path: String, cell: int, from: int, to: int, seconds: float) -> void:
	if npc == null:
		return
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		if is_instance_valid(npc):
			show_frame(npc, path, cell, int(round(value))),
		float(from), float(to), seconds)
	await tween.finished


## A sprite of a one-row sheet (`frames` cells) at `at` (global), above the figures; loops at `fps`
## while it lives (fps 0 = stands still on frame 0).
func add_sheet_sprite(path: String, frames: int, at: Vector2, fps: float = 8.0, z: int = 1) -> AnimatedSheet:
	var sprite := AnimatedSheet.new()
	sprite.texture = load(path)
	sprite.hframes = maxi(1, frames)
	sprite.fps = fps
	sprite.z_index = z
	sprite.z_as_relative = false
	add_child(sprite)
	sprite.global_position = at
	return sprite


## An extra figure for the cut scene only: a resident sheet (residents/<name>.png, 48 px frames,
## rows down/up/left/right) standing at `at` (global, feet) and looking at `facing`.
func extra(resident: String, at: Vector2, facing: String = "down") -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = CharacterBaker.get_resident_sheet(resident)
	sprite.region_enabled = true
	sprite.region_rect = CharacterBaker.get_frame_rect(facing)
	sprite.offset = Vector2(0, -13)
	sprite.set_meta(&"facing", facing)
	var holder := get_parent() if get_parent() is Node2D and (get_parent() as Node2D).y_sort_enabled else self
	holder.add_child(sprite)
	sprite.global_position = at
	return sprite


## An extra (see extra()) walks along `points` (global) at `speed` with its walk frames, then
## looks at `facing` ("" = as it walked); `free_at_end` removes it there. Awaitable.
func walk_extra(sprite: Sprite2D, points: PackedVector2Array, speed: float, facing: String = "", free_at_end: bool = false) -> void:
	var time: float = 0.0
	for target in points:
		while is_inside_tree() and is_instance_valid(sprite) and sprite.global_position.distance_to(target) > 1.0:
			var delta: float = get_process_delta_time()
			var offset: Vector2 = target - sprite.global_position
			sprite.global_position += offset.limit_length(speed * delta)
			time += delta
			var direction: String
			if absf(offset.x) > absf(offset.y):
				direction = "right" if offset.x > 0.0 else "left"
			else:
				direction = "down" if offset.y > 0.0 else "up"
			sprite.set_meta(&"facing", direction)
			sprite.region_rect = CharacterBaker.get_frame_rect(direction,
					1 + int(time * CharacterBaker.WALK_SPEED) % (CharacterBaker.COLUMNS - 1))
			await get_tree().process_frame
		if not is_instance_valid(sprite):
			return
		sprite.global_position = target
	if free_at_end:
		sprite.queue_free()
		return
	var look: String = facing if not facing.is_empty() else str(sprite.get_meta(&"facing", "down"))
	sprite.region_rect = CharacterBaker.get_frame_rect(look)


## A rectangle of `color` over the whole map (in the world, so the dialogue box stays above it),
## drawn at `z` (figures are around 0..2).
func world_tint(color: Color, z: int = 3) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(6000, 6000)
	rect.z_index = z
	rect.z_as_relative = false
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	rect.global_position = Vector2(-3000, -3000)
	return rect


## A flash of `color` over the map that fades in `seconds`.
func flash(color: Color, seconds: float) -> void:
	var rect := world_tint(color)
	var fade := create_tween()
	fade.tween_property(rect, "modulate:a", 0.0, seconds)
	fade.tween_callback(rect.queue_free)


## Shakes the camera for `seconds` by up to `strength` px. Awaitable.
func shake(seconds: float, strength: float = 2.0) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var home: Vector2 = camera.offset
	var end_time: float = Time.get_ticks_msec() / 1000.0 + seconds
	while Time.get_ticks_msec() / 1000.0 < end_time and is_instance_valid(camera) and is_inside_tree():
		camera.offset = home + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round()
		await get_tree().process_frame
	if is_instance_valid(camera):
		camera.offset = home


## A sprite that loops the frames of its sheet (hframes) at `fps`.
class AnimatedSheet extends Sprite2D:
	var fps: float = 8.0
	var _time: float = 0.0

	func _process(delta: float) -> void:
		if fps <= 0.0 or hframes <= 1:
			return
		_time += delta
		frame = int(_time * fps) % hframes
