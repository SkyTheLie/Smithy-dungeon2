class_name HarborAttackCutscene
extends StoryCutscene
## The night attack on the harbour of Eisquell (dialogues "kahn_refuses" and "harbor_subar"):
## - hall_night (Kahn's hall): Kahn, Subar and Torgai go, the player walks to a straw bed at the
##   side of the hall, lies down and it gets dark
## - harbor_horn (Kahn's hall): a horn in the night, the sky over the harbour glows red; with
##   hall_wake the player wakes up and gets up from the straw bed
## - harbor_burning (Eisquell): the camera looks down to the canal, boats burn at the quay, dark
##   archers and mages of the Finster army shoot fire into the boats from the quay
## - harbor_lake: the camera looks out to the sea, Lake stands on an ice ship, looks over, then
##   turns away and the ship drifts off
## The burning boats (children of `boats`) and the crates, barrels and nets at the quay (children of
## `wreckage`, both in a StoryProp harbor_attacked » harbor_saved) keep burning.

## Holder of the burning boats (their flames are drawn here while it is visible).
@export var boats: NodePath
## Holder of the burning crates, barrels and nets at the quay (flames like the boats).
@export var wreckage: NodePath
## Where the Finster archers and mages stand at the quay (map coordinates; archer, mage, archer …).
@export var shooter_spots: PackedVector2Array = []
## Where the camera looks for the boats and for the ship (map coordinates).
@export var canal_view: Vector2 = Vector2(0, -10)
@export var sea_view: Vector2 = Vector2(300, 520)
## Where the ice ship lies (map coordinates, its keel).
@export var ship_at: Vector2 = Vector2(330, 600)

## Kahn's hall: where the player sleeps (map coordinates, his feet).
@export var sleep_spot: Vector2 = Vector2.ZERO
## Kahn's hall: who leaves for the night (Kahn, Subar, Torgai).
@export var leave_for_night: Array[NodePath] = []
## Kahn's hall: how far down they walk before they are gone (map y of the door).
@export var hall_door_y: float = 200.0

const STRAW_BED: String = "res://assets/sprites/finster/straw_bed.png"
const NIGHT: Color = Color(0.02, 0.03, 0.12, 0.0)
const SHIP: String = "res://assets/sprites/water/ice_ship.png"
const FIRE: Color = Color(1.0, 0.55, 0.2)
const RED_SKY: Color = Color(0.85, 0.15, 0.05, 0.0)

## Resident sheets of the shooters at the quay: archer, mage.
const SHOOTERS: Array[String] = ["finster_archer", "finster_mage"]
## Seconds a fire arrow / fire ball flies.
const SHOT_FLIGHT: float = 0.4

var _shooters: Array[Sprite2D] = []
## The boat each shooter aims at (same index as _shooters).
var _aims: Array[Node2D] = []
## Kahn's hall at night: the dark over the hall and where the player's figure stood before he lay down.
var _night: ColorRect
var _figure_home: Vector2


func _ready() -> void:
	super._ready()
	_light_boats.call_deferred()


func _play_beat(id: String) -> bool:
	match id:
		"hall_night":
			_hall_night()
		"hall_wake":
			_hall_wake()
		"harbor_horn":
			_horn()
		"harbor_burning":
			_burning()
		"harbor_lake":
			_lake()
		_:
			return false
	return true


func _map(point: Vector2) -> Vector2:
	var parent := get_parent() as Node2D
	return parent.to_global(point) if parent else point


## Kahn's hall: the others go, the player walks to the straw bed (straight lines), lies down, dark.
func _hall_night() -> void:
	for path in leave_for_night:
		_leave_hall(node2d(path))
	var smith := player()
	if smith == null or sleep_spot == Vector2.ZERO:
		return
	var bed := Sprite2D.new()
	bed.texture = load(STRAW_BED)
	bed.modulate.a = 0.0
	smith.get_parent().add_child(bed)
	# a little above his feet: drawn behind him (y sort)
	bed.global_position = _map(sleep_spot + Vector2(0, -3))
	create_tween().tween_property(bed, "modulate:a", 1.0, 0.4)
	var at: Vector2 = (get_parent() as Node2D).to_local(smith.global_position)
	walk_player(PackedVector2Array([_map(Vector2(at.x, sleep_spot.y)), _map(sleep_spot)]), "down", 3.0)
	# by time, not frames (240 frames are gone in under 2 s on a fast screen, he lay down on the way)
	var walked: float = 0.0
	await get_tree().process_frame
	while is_inside_tree() and is_instance_valid(smith) and smith.call("is_auto_walking") and walked < 8.0:
		walked += get_process_delta_time()
		await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(smith):
		return
	var figure := NpcActing.figure_of(smith)
	if figure:
		_figure_home = figure.position
	_night = world_tint(NIGHT, 3)
	create_tween().tween_property(_night, "color:a", 0.75, 1.4)
	await NpcActing.play(smith, "sleep")


## Kahn's hall: a figure walks down to the door (straight, beside the carpet) and fades there.
func _leave_hall(npc: Node2D) -> void:
	if npc == null:
		return
	var at: Vector2 = (get_parent() as Node2D).to_local(npc.global_position)
	var lane: float = at.x if absf(at.x) >= 30.0 else -30.0
	await walk_npc(npc, PackedVector2Array([_map(Vector2(lane, at.y)), _map(Vector2(lane, hall_door_y))]), 70.0)
	if is_instance_valid(npc) and is_inside_tree():
		create_tween().tween_property(npc, "modulate:a", 0.0, 0.4)


## Kahn's hall: the horn wakes the player, he gets up from the straw bed.
func _hall_wake() -> void:
	if _night:
		create_tween().tween_property(_night, "color:a", 0.35, 0.5)
	var smith := player()
	var figure := NpcActing.figure_of(smith) if smith else null
	if figure == null:
		return
	if not await wait(0.4):
		return
	if not is_instance_valid(figure):
		return
	var up := create_tween()
	up.tween_property(figure, "rotation", 0.0, 0.3)
	up.parallel().tween_property(figure, "position", _figure_home, 0.3)
	await up.finished
	if is_instance_valid(smith):
		face_player("down")


## Flames on every boat and on the burning things at the quay (while their holder is shown).
func _light_boats() -> void:
	for pair: Array in [[boats, Vector2(0, -4)], [wreckage, Vector2(0, -14)]]:
		var holder := node2d(pair[0])
		if holder == null:
			continue
		for burning in holder.get_children():
			if burning is Node2D:
				fx.add_loop(burning as Node2D, "aura_burn", FIRE, pair[1])


func _horn() -> void:
	AudioManager.play_sound("title_door", 0.4)
	var sky := world_tint(RED_SKY, 3)
	var glow := create_tween()
	glow.tween_property(sky, "color:a", 0.35, 0.6)
	glow.tween_property(sky, "color:a", 0.2, 0.5)
	glow.tween_property(sky, "color:a", 0.35, 0.5)
	glow.tween_property(sky, "color:a", 0.0, 0.8)
	glow.tween_callback(sky.queue_free)
	shake(0.6, 1.0)


## Moves the camera to look at `point` (global) in `seconds`; awaitable.
func _look(point: Vector2, seconds: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var pan := create_tween()
	pan.tween_property(camera, "offset", point - camera.global_position, seconds).set_trans(Tween.TRANS_SINE)
	await pan.finished


func _look_back(seconds: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		create_tween().tween_property(camera, "offset", Vector2.ZERO, seconds).set_trans(Tween.TRANS_SINE)


## The quay: archers and mages of the Finster army shoot fire arrows and fire balls into the boats
## (archers turned sideways to their boat so the bow shows, mages facing the water with the staff).
func _burning() -> void:
	await _look(_map(canal_view), 0.8)
	if not is_inside_tree():
		return
	var holder := node2d(boats)
	var targets: Array[Node2D] = []
	if holder:
		for boat in holder.get_children():
			if boat is Node2D:
				targets.append(boat as Node2D)
	if targets.is_empty():
		_look_back(0.7)
		return
	# played again (e.g. the dialogue once more): the old shooters go first
	for old in _shooters:
		if is_instance_valid(old):
			old.queue_free()
	_shooters.clear()
	_aims.clear()
	# each one shoots at the boat nearest to it (archers turn towards it)
	for i in shooter_spots.size():
		var at: Vector2 = _map(shooter_spots[i])
		var boat: Node2D = targets[0]
		for other in targets:
			if absf(other.global_position.x - at.x) < absf(boat.global_position.x - at.x):
				boat = other
		var mage: bool = i % 2 == 1
		var facing: String = "down"
		if not mage:
			facing = "right" if boat.global_position.x >= at.x else "left"
		_shooters.append(extra(SHOOTERS[1] if mage else SHOOTERS[0], at, facing))
		_aims.append(boat)
	AudioManager.play_sound("wood_break", 0.6)
	if _shooters.is_empty():
		_look_back(0.7)
		return
	for i in 6:
		var index: int = i % _shooters.size()
		var shooter: Sprite2D = _shooters[index]
		var boat: Node2D = _aims[index]
		if is_instance_valid(shooter) and is_instance_valid(boat):
			_shoot(shooter, boat, index % 2 == 1)
		if not await wait(0.35):
			return
	if await wait(0.4):
		_look_back(0.7)


## One shot from the quay into a boat: a fire arrow (archer) or a fire ball (mage), flames where it hits.
func _shoot(shooter: Sprite2D, boat: Node2D, mage: bool) -> void:
	var facing: String = str(shooter.get_meta(&"facing", "down"))
	var side: float = -1.0 if facing == "left" else 1.0
	var from: Vector2 = shooter.global_position + (Vector2(0, -22) if mage else Vector2(10 * side, -12))
	var hit: Vector2 = boat.global_position + Vector2(randf_range(-14, 14), -10)
	# a little recoil, then back
	var recoil := create_tween()
	recoil.tween_property(shooter, "offset:x", -2.0 * side, 0.06)
	recoil.tween_property(shooter, "offset:x", 0.0, 0.12)
	if mage:
		fx.spawn("fire_bolt", hit, Color.WHITE, side, from, SHOT_FLIGHT)
	else:
		fx.spawn("arrow", hit, FIRE, side, from, SHOT_FLIGHT)
	if await wait(SHOT_FLIGHT):
		fx.spawn("fire_hit", hit, Color.WHITE)


func _lake() -> void:
	var ship := Sprite2D.new()
	ship.texture = load(SHIP)
	ship.offset = Vector2(0, -ship.texture.get_height() / 2.0)
	ship.z_index = 0
	add_child(ship)
	ship.global_position = _map(ship_at)
	# Lake on the deck, looking over to the harbour (up), then turning away (down)
	var lake := Sprite2D.new()
	lake.texture = CharacterBaker.get_resident_sheet("lake_dark")
	lake.region_enabled = true
	lake.region_rect = CharacterBaker.get_frame_rect("up")
	lake.offset = Vector2(0, -13)
	lake.position = Vector2(8, -10)
	ship.add_child(lake)
	await _look(_map(sea_view), 1.0)
	if not await wait(0.7):
		return
	lake.region_rect = CharacterBaker.get_frame_rect("right")
	if not await wait(0.25):
		return
	lake.region_rect = CharacterBaker.get_frame_rect("down")
	# the ship drifts off and fades into the dark
	var drift := create_tween().set_parallel()
	drift.tween_property(ship, "global_position", ship.global_position + Vector2(120, 0), 3.0)
	drift.tween_property(ship, "modulate:a", 0.0, 3.0).set_delay(0.8)
	drift.chain().tween_callback(ship.queue_free)
	if not await wait(0.5):
		return
	_look_back(0.9)
