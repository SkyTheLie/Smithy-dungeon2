class_name HarborAttackCutscene
extends StoryCutscene
## The night attack on the harbour of Eisquell (dialogues "kahn_refuses" and "harbor_subar"):
## - harbor_horn (Kahn's hall): a horn in the night, the sky over the harbour glows red
## - harbor_burning (Eisquell): the camera looks down to the canal, boats burn at the quay, dark
##   knights flash between the piers
## - harbor_lake: the camera looks out to the sea, Lake stands on an ice ship, looks over, then
##   turns away and the ship drifts off
## The burning boats (children of `boats`, StoryProp harbor_attacked » harbor_saved) keep burning.

## Holder of the burning boats (their flames are drawn here while it is visible).
@export var boats: NodePath
## Where the dark knights stand at the quay (map coordinates).
@export var knight_spots: PackedVector2Array = []
## Where the camera looks for the boats and for the ship (map coordinates).
@export var canal_view: Vector2 = Vector2(0, -10)
@export var sea_view: Vector2 = Vector2(300, 520)
## Where the ice ship lies (map coordinates, its keel).
@export var ship_at: Vector2 = Vector2(330, 600)

const SHIP: String = "res://assets/sprites/water/ice_ship.png"
const FIRE: Color = Color(1.0, 0.55, 0.2)
const RED_SKY: Color = Color(0.85, 0.15, 0.05, 0.0)

var _knights: Array[Sprite2D] = []


func _ready() -> void:
	super._ready()
	_light_boats.call_deferred()


func _play_beat(id: String) -> bool:
	match id:
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


## Flames on every boat (while the holder is shown).
func _light_boats() -> void:
	var holder := node2d(boats)
	if holder == null:
		return
	for boat in holder.get_children():
		if boat is Node2D:
			fx.add_loop(boat as Node2D, "aura_burn", FIRE, Vector2(0, -4))


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


func _burning() -> void:
	await _look(_map(canal_view), 0.8)
	if not is_inside_tree():
		return
	for spot in knight_spots:
		var knight := extra("finster_knight", _map(spot), "down")
		_knights.append(knight)
	AudioManager.play_sound("wood_break", 0.6)
	for i in 6:
		if not _knights.is_empty():
			var knight: Sprite2D = _knights[i % _knights.size()]
			if is_instance_valid(knight):
				fx.spawn("slash", knight.global_position + Vector2(8, -14), Color(0.7, 0.7, 0.8))
				knight.region_rect = CharacterBaker.get_frame_rect(["left", "right"][i % 2])
		var holder := node2d(boats)
		if holder and holder.get_child_count() > 0:
			var boat := holder.get_child(i % holder.get_child_count()) as Node2D
			fx.spawn("fire_hit", boat.global_position + Vector2(randf_range(-10, 10), -6), Color.WHITE)
		if not await wait(0.25):
			return
	_look_back(0.7)


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
