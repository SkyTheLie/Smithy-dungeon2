class_name FennFlightCutscene
extends StoryCutscene
## Fenn's maiden flight at the airfield of Sylvaris (dialogue "fenn_maiden_flight"):
## - flight_wings: the machine trembles, then beats its wings by itself (elves/flying_machine_flap.png)
## - flight_takeoff: Fenn and the player climb in, the machine pushes off the platform and rises
##   over the crowns; behind the black of the fade it stands on the field again
## Side quest "Fenns Flugmaschine":
## - wings_spread: the new wings spread and catch the wind, the machine tugs at its rope
## - orb_spins: the wind orb sits in the middle of the frame, spins and whistles, nothing moves

@export var machine: NodePath
@export var fenn: NodePath

const FLAP: String = "res://assets/sprites/elves/flying_machine_flap.png"
const FLAP_FRAMES: int = 8
## The flap sheet's cell sits this far from the still picture's centre.
const FLAP_SHIFT: Vector2 = Vector2(0, -7)

var _still: Texture2D
var _still_offset: Vector2
var _flapping: bool = false


func _play_beat(id: String) -> bool:
	match id:
		"flight_wings":
			_wings()
		"flight_takeoff":
			_takeoff()
		"wings_spread":
			_wings_spread()
		"orb_spins":
			_orb_spins()
		_:
			return false
	return true


func _sprite() -> Sprite2D:
	var body := node2d(machine)
	return body.get_node_or_null("Sprite2D") as Sprite2D if body else null


func _wings() -> void:
	var sprite := _sprite()
	if sprite == null:
		return
	# it trembles first
	var home: Vector2 = sprite.position
	for i in 8:
		sprite.position = home + Vector2(1 if i % 2 == 0 else -1, 0)
		if not await wait(0.05):
			return
	sprite.position = home
	AudioManager.play_sound("skill_used", 0.7)
	_start_flap()


func _start_flap() -> void:
	var sprite := _sprite()
	if sprite == null or _flapping:
		return
	_still = sprite.texture
	_still_offset = sprite.offset
	sprite.texture = load(FLAP)
	sprite.hframes = FLAP_FRAMES
	sprite.offset = _still_offset + FLAP_SHIFT
	_flapping = true
	var time: float = 0.0
	while _flapping and is_inside_tree() and is_instance_valid(sprite):
		time += get_process_delta_time()
		sprite.frame = int(time * 10.0) % FLAP_FRAMES
		await get_tree().process_frame


func _stop_flap() -> void:
	_flapping = false
	var sprite := _sprite()
	if sprite and _still:
		sprite.texture = _still
		sprite.hframes = 1
		sprite.frame = 0
		sprite.offset = _still_offset


func _takeoff() -> void:
	var body := node2d(machine)
	var sprite := _sprite()
	if body == null or sprite == null:
		return
	_start_flap()
	var seat: Vector2 = body.global_position + Vector2(0, 6)
	var inventor := node2d(fenn)
	walk_player(PackedVector2Array([seat + Vector2(14, 14), seat]), "up", 0.9)
	if inventor:
		walk_npc(inventor, PackedVector2Array([seat + Vector2(-14, 14), seat + Vector2(-6, 0)]), 70.0, "up")
	if not await wait(1.0):
		return
	# the two sit in the boat: hidden, they ride along
	var riders: Array[CanvasItem] = []
	for rider: Node2D in [player(), inventor]:
		if rider and rider.visible:
			rider.hide()
			riders.append(rider)
	AudioManager.play_sound("title_door", 0.6)
	fx.spawn("air_hit", body.global_position, Color.WHITE)
	var home: Vector2 = sprite.position
	var rise := create_tween().set_parallel()
	rise.tween_property(sprite, "position", home + Vector2(30, -170), 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rise.tween_property(sprite, "scale", Vector2(1.25, 1.25), 2.2)
	if not await wait(1.6):
		return
	GameState.run_story_action("cutscene:fade")
	# behind the black: landed again
	if not await wait(0.9):
		return
	rise.kill()
	sprite.position = home
	sprite.scale = Vector2.ONE
	_stop_flap()
	for rider in riders:
		if is_instance_valid(rider):
			rider.show()
	var body_player := player()
	if body_player:
		body_player.global_position = seat + Vector2(22, 18)
		face_player("left")
	if inventor:
		inventor.global_position = seat + Vector2(-22, 18)
		face_npc(inventor, "right")


func _wings_spread() -> void:
	var sprite := _sprite()
	if sprite == null:
		return
	_start_flap()
	AudioManager.play_sound("skill_used", 0.6)
	var home: Vector2 = sprite.position
	for i in 6:
		fx.spawn("air_hit", sprite.global_position + Vector2(-30 if i % 2 == 0 else 30, -30), Color.WHITE)
		var tug := create_tween()
		tug.tween_property(sprite, "position", home + Vector2(0, -3), 0.12)
		tug.tween_property(sprite, "position", home, 0.12)
		if not await wait(0.26):
			return
	_stop_flap()


func _orb_spins() -> void:
	var body := node2d(machine)
	if body == null:
		return
	var orb := Sprite2D.new()
	orb.texture = NpcActing.icon("wind_orb")
	orb.scale = Vector2(0.7, 0.7)
	orb.z_index = 2
	add_child(orb)
	orb.global_position = body.global_position + Vector2(0, -30)
	AudioManager.play_sound("skill_used", 0.5)
	var spin := create_tween()
	spin.tween_property(orb, "rotation", TAU * 3.0, 1.4)
	for i in 4:
		fx.spawn("air_hit", orb.global_position, Color(0.85, 1.0, 0.95))
		if not await wait(0.35):
			break
	if is_instance_valid(orb):
		var away := create_tween()
		away.tween_property(orb, "modulate:a", 0.0, 0.2)
		away.tween_callback(orb.queue_free)
