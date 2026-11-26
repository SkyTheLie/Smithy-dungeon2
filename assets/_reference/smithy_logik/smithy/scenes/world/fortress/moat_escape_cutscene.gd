class_name MoatEscapeCutscene
extends StoryCutscene
## End of the flight from the Finsterburg (step carry_mage), outside in the west moat. The narrator
## escape_exit talks by itself on arrival (escape_out); each part starts with the story action
## "cutscene:<id>" (Events.cutscene_requested):
## - moat_lead: the player (Aurelius at his side) walks to the middle by himself (auto_walk, around
##   the pillars); Faelan keeps beside the group, a little ahead (GUIDE_OFFSET from the player)
## - moat_meet: the walk ends (whoever clicked faster is put on the meet point, Faelan next to him)
## - moat_surround: guards come from the sally port on the left and from the east end of the moat,
##   each along its row below the pillars (`guard_rows`), and close a ring; while they come the
##   group looks around in every direction, then each one faces a side of the ring
## - moat_teleport: Aurelius spends his last spark: white light, everyone vanishes, the screen
##   stays white until the dialogue ends (then the story wakes the player on Aurelius' clearing)

## The player's way to the middle (scene coordinates); the last point is where he stops next to
## Faelan, and the guards' ring faces it.
@export var player_path: PackedVector2Array = []
## Faelan (a Sprite2D with his resident sheet): walks with the group, GUIDE_OFFSET from the player.
@export var guide: NodePath
## Aurelius (Companion): looks around with the others when the guards come.
@export var companion: NodePath
## Where each guard comes from and where he stops in the ring (scene coordinates, same order).
## Each walks start » (start.x, row) » (stop.x, row) » stop, with his row from `guard_rows`, so the
## paths stay on open floor (rows below the pillars, clear of crates and rocks).
@export var guard_starts: PackedVector2Array = []
@export var guard_stops: PackedVector2Array = []
@export var guard_rows: PackedFloat32Array = []
## PixelLab sheets of the guards (assets/sprites/residents/<id>.png), used in turn.
@export var guard_residents: PackedStringArray = ["finster_warden_a", "finster_warden_b"]
## Figures that vanish in the light besides the player (Faelan, the horses, Aurelius).
@export var vanishing: Array[NodePath] = []

const GUARD_SPEED: float = 110.0
const LEAD_SPEED: float = 70.0
## Where Faelan walks relative to the player (a little ahead and to the side).
const GUIDE_OFFSET: Vector2 = Vector2(26, -6)
const LOOK_DIRECTIONS: Array[String] = ["left", "up", "right", "down"]
const COLOR_LIGHT: Color = Color(0.85, 0.95, 1.0)

var _guards: Array[AnimatedSprite2D] = []
## True while the group walks to the middle (Faelan keeps up with the player).
var _leading: bool = false
## Guards still on their way to the ring (the group looks around until it is 0).
var _guards_walking: int = 0


func _ready() -> void:
	super()


func _play_beat(id: String) -> bool:
	match id:
		"moat_lead":
			_lead()
		"moat_meet":
			_meet()
		"moat_surround":
			_surround()
		"moat_teleport":
			_teleport()
		_:
			return false
	return true


func _map() -> Node2D:
	return get_parent() as Node2D


func _player() -> Player:
	return get_tree().get_first_node_in_group(Player.GROUP) as Player


func meet_point() -> Vector2:
	return player_path[player_path.size() - 1] if not player_path.is_empty() else Vector2.ZERO


## Faelan's place at the end of the walk (scene coordinates).
func guide_spot() -> Vector2:
	return meet_point() + GUIDE_OFFSET


func _lead() -> void:
	var smith := _player()
	if smith == null or player_path.is_empty():
		return
	smith.auto_walk(_global_path(player_path), "right", LEAD_SPEED)
	var faelan := get_node_or_null(guide) as Sprite2D
	if faelan:
		_leading = true
		_keep_up(faelan, smith)


## The walk ends; if the dialogue was clicked on faster than the walk, both are put at the end.
func _meet() -> void:
	_leading = false
	var smith := _player()
	if smith == null or player_path.is_empty():
		return
	var spot: Vector2 = _map().to_global(meet_point())
	if smith.global_position.distance_to(spot) > 1.0:
		smith.global_position = spot
	smith.auto_walk(PackedVector2Array([spot]), "right")
	var faelan := get_node_or_null(guide) as Sprite2D
	if faelan:
		faelan.global_position = _map().to_global(guide_spot())
		faelan.region_rect = CharacterBaker.get_frame_rect("left")


func _global_path(points: PackedVector2Array) -> PackedVector2Array:
	var way := PackedVector2Array()
	for point in points:
		way.append(_map().to_global(point))
	return way


## Faelan walks with the group: each frame towards his place next to the player (walk frames of his
## sheet), standing still when he is there, until the walk ends (_leading false).
func _keep_up(faelan: Sprite2D, smith: Node2D) -> void:
	var frame: int = 0
	var facing: String = "right"
	while _leading and is_inside_tree() and is_instance_valid(faelan) and is_instance_valid(smith):
		var step: Vector2 = smith.global_position + GUIDE_OFFSET - faelan.global_position
		if step.length() > 1.5:
			frame += 1
			facing = _direction(step)
			faelan.region_rect = CharacterBaker.get_frame_rect(facing, 1 + (frame / 6) % 6)
			faelan.global_position += step.limit_length(LEAD_SPEED * 1.3 * get_physics_process_delta_time())
		else:
			faelan.region_rect = CharacterBaker.get_frame_rect(facing)
		await get_tree().physics_frame


## The player, Faelan and Aurelius turn this way and that while the guards come, each to another
## side; once the ring is closed they stand back to back (left, right, down).
func _look_around() -> void:
	var smith := _player()
	var faelan := get_node_or_null(guide) as Sprite2D
	var mage := get_node_or_null(companion)
	var turn: int = 0
	while _guards_walking > 0 and is_inside_tree():
		turn += 1
		_face_all(smith, faelan, mage, [LOOK_DIRECTIONS[(turn + randi() % 2) % 4],
				LOOK_DIRECTIONS[(turn + 2) % 4], LOOK_DIRECTIONS[(turn + 1 + randi() % 3) % 4]])
		await wait(randf_range(0.35, 0.6))
	if is_inside_tree():
		_face_all(smith, faelan, mage, ["left", "right", "down"])


func _face_all(smith: Player, faelan: Sprite2D, mage: Node, directions: Array) -> void:
	if is_instance_valid(smith):
		smith.auto_walk(PackedVector2Array([smith.global_position]), directions[0])
	if is_instance_valid(faelan):
		faelan.region_rect = CharacterBaker.get_frame_rect(directions[1])
	if is_instance_valid(mage) and mage.has_method("face"):
		mage.face(directions[2])


## The way of guard `index` (scene coordinates): down/up to his row, along it, then to his place.
func guard_path(index: int) -> PackedVector2Array:
	var start: Vector2 = guard_starts[index]
	var stop: Vector2 = guard_stops[index]
	var row: float = guard_rows[index] if index < guard_rows.size() else stop.y
	return PackedVector2Array([start, Vector2(start.x, row), Vector2(stop.x, row), stop])


## The guards walk in one after another and stand in a ring around the group, looking at it.
func _surround() -> void:
	AudioManager.play_sound("door", 0.7)
	var center: Vector2 = _map().to_global(meet_point())
	_guards_walking = mini(guard_starts.size(), guard_stops.size())
	_look_around()
	for index in range(mini(guard_starts.size(), guard_stops.size())):
		var guard := _make_guard(guard_residents[index % guard_residents.size()])
		if guard == null:
			_guards_walking -= 1
			continue
		var way: PackedVector2Array = _global_path(guard_path(index))
		guard.global_position = way[0]
		_walk_guard(guard, way, center)
		if not is_inside_tree():
			return
		if not await wait(0.15):
			return


func _make_guard(resident: String) -> AnimatedSprite2D:
	var sheet: Texture2D = CharacterBaker.get_resident_sheet(resident)
	if sheet == null:
		return null
	var guard := AnimatedSprite2D.new()
	guard.sprite_frames = CharacterBaker.make_frames(sheet)
	guard.offset = Vector2(0, -13)
	var people := _map().get_node_or_null("People")
	(people if people else _map()).add_child(guard)
	_guards.append(guard)
	return guard


func _walk_guard(guard: AnimatedSprite2D, way: PackedVector2Array, center: Vector2) -> void:
	for target in way:
		while is_inside_tree() and is_instance_valid(guard) and guard.global_position.distance_to(target) > 1.0:
			var step: Vector2 = target - guard.global_position
			guard.play(StringName("walk_" + _direction(step)))
			guard.global_position += step.limit_length(GUARD_SPEED * get_physics_process_delta_time())
			await get_tree().physics_frame
	_guards_walking -= 1
	if is_instance_valid(guard):
		guard.play(StringName("idle_" + _direction(center - guard.global_position)))


func _direction(step: Vector2) -> String:
	if absf(step.x) > absf(step.y):
		return "right" if step.x > 0.0 else "left"
	return "down" if step.y > 0.0 else "up"


## Aurelius' last spark: sparks rise, two flashes, the group fades away in the light, the guards
## stagger back, and the screen stays white.
func _teleport() -> void:
	var center: Vector2 = _map().to_global(meet_point())
	_sparks(center)
	AudioManager.play_sound("unlock", 0.8)
	if not is_inside_tree():
		return
	if not await wait(0.6):
		return
	_flash(0.85, true)
	var figures: Array[Node2D] = []
	var smith := _player()
	if smith:
		figures.append(smith)
	for path in vanishing:
		var node := get_node_or_null(path) as Node2D
		if node:
			figures.append(node)
	for figure in figures:
		create_tween().tween_property(figure, "modulate:a", 0.0, 0.5)
	for guard in _guards:
		if is_instance_valid(guard):
			var away: Vector2 = (guard.global_position - center).normalized() * 14.0
			create_tween().tween_property(guard, "global_position", guard.global_position + away, 0.3) \
					.set_ease(Tween.EASE_OUT)
	if not is_inside_tree():
		return
	if not await wait(0.35):
		return
	_flash(1.0, false)


## Little white squares that rise around the group (no particle scene needed).
func _sparks(center: Vector2) -> void:
	for index in 18:
		var spark := ColorRect.new()
		spark.size = Vector2(2, 2)
		spark.color = COLOR_LIGHT
		spark.z_index = 5
		_map().add_child(spark)
		spark.global_position = center + Vector2(randf_range(-26.0, 26.0), randf_range(-6.0, 10.0))
		var tween := create_tween()
		tween.tween_interval(randf_range(0.0, 0.5))
		tween.tween_property(spark, "global_position:y", spark.global_position.y - randf_range(18.0, 34.0), 0.7)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.7)
		tween.tween_callback(spark.queue_free)


## A white veil over the screen: fades out again, or (`fade_out` false) stays fully white until
## the scene changes. It lies in the world (above every figure), not in a CanvasLayer, so the
## dialogue box stays readable on top of it; the Gloom of the map is lifted so the white is white.
func _flash(strength: float, fade_out: bool) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var view: Vector2 = get_viewport().get_visible_rect().size
	var veil := ColorRect.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_as_relative = false
	veil.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	veil.size = view * 2.0
	var center: Vector2 = camera.get_screen_center_position() if camera else _map().to_global(meet_point())
	veil.color = Color(COLOR_LIGHT, strength if fade_out else 0.0)
	_map().add_child(veil)
	veil.global_position = center - view
	var tween: Tween = create_tween()
	if fade_out:
		tween.tween_property(veil, "color:a", 0.0, 0.5)
		tween.tween_callback(veil.queue_free)
		return
	tween.tween_property(veil, "color:a", strength, 0.6)
	var gloom := _map().get_node_or_null("Gloom") as CanvasModulate
	if gloom:
		create_tween().tween_property(gloom, "color", Color.WHITE, 0.6)
