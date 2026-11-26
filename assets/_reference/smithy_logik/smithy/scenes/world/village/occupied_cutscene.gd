class_name OccupiedCutscene
extends StoryCutscene
## The village square while the dark knights hold it (dialogue "village_occupied"):
## - lotte_shakes: Lotte at the well looks at the player for a moment and shakes her head
## - occupied_leave: Lotte walks slowly to the north road and waves behind her back
##   (residents/emma_wave_back.png), the knights go into the inn, the player slips after Lotte
##   along the houses; then flag knights_in_village

@export var lotte: NodePath
@export var knights: Array[NodePath] = []
## Inn door and the north road (map coordinates).
@export var inn_door: Vector2 = Vector2(-272, -96)
@export var north: Vector2 = Vector2(0, -330)

const WAVE: String = "res://assets/sprites/residents/emma_wave_back.png"
const WAVE_FRAMES: int = 7


func _play_beat(id: String) -> bool:
	match id:
		"lotte_shakes":
			_shake_head()
		"occupied_leave":
			_leave()
		_:
			return false
	return true


func _map(point: Vector2) -> Vector2:
	var parent := get_parent() as Node2D
	return parent.to_global(point) if parent else point


func _shake_head() -> void:
	var girl := node2d(lotte)
	var body := player()
	if girl == null:
		return
	var toward: String = "down"
	if body:
		var offset: Vector2 = body.global_position - girl.global_position
		toward = ("right" if offset.x > 0.0 else "left") if absf(offset.x) > absf(offset.y) else ("down" if offset.y > 0.0 else "up")
	face_npc(girl, toward)
	if not await wait(0.4):
		return
	for direction in ["left", "right", "left", toward]:
		face_npc(girl, direction)
		if not await wait(0.14):
			return


func _leave() -> void:
	var girl := node2d(lotte)
	var road: Vector2 = _map(north)
	# the knights to the inn
	var door: Vector2 = _map(inn_door)
	var index: int = 0
	for path in knights:
		var knight := node2d(path)
		if knight:
			_to_inn(knight, door + Vector2(-8 + 16 * index, 0))
		index += 1
	# the player slips along the houses on the right
	var body := player()
	if body:
		var side: Vector2 = Vector2(road.x + 70, body.global_position.y)
		walk_player(PackedVector2Array([side, Vector2(side.x, road.y + 40), road + Vector2(20, 40)]), "up", 7.0)
	if girl == null:
		return
	await walk_npc(girl, PackedVector2Array([Vector2(road.x, girl.global_position.y), Vector2(road.x, girl.global_position.y - 40)]), 40.0, "up")
	if not is_inside_tree() or not is_instance_valid(girl):
		return
	# a little wave behind her back
	await play_sheet(girl, WAVE, 48, 0, WAVE_FRAMES - 1, 0.7)
	if not await wait(0.4) or not is_instance_valid(girl):
		return
	await play_sheet(girl, WAVE, 48, WAVE_FRAMES - 1, 0, 0.5)
	if not is_instance_valid(girl):
		return
	var figure := figure_of(girl)
	if figure:
		figure.texture = CharacterBaker.get_resident_sheet("emma")
	await walk_npc(girl, PackedVector2Array([road]), 80.0, "up")
	_done()


func _to_inn(knight: Node2D, door: Vector2) -> void:
	await walk_npc(knight, PackedVector2Array([Vector2(knight.global_position.x, door.y + 30), Vector2(door.x, door.y + 30), door]), 60.0, "up")
	if is_instance_valid(knight):
		var figure := figure_of(knight)
		if figure:
			create_tween().tween_property(figure, "modulate:a", 0.0, 0.3)


func _done() -> void:
	for path in knights + [lotte]:
		var npc := node2d(path)
		if npc and npc.has_method("_hide_body"):
			npc.call("_hide_body")
	GameState.run_story_action("set_flag:knights_in_village")
