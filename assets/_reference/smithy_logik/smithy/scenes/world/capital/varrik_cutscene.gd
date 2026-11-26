class_name VarrikCutscene
extends StoryCutscene
## Varrik's sentence in the throne room of Leonheim (dialogue "varrik_sentenced"):
## - varrik_dragged: the player steps aside, the two guards haul Varrik up and drag him out of the
##   hall (he struggles, still facing the throne), far below a dungeon door falls shut; then flag
##   varrik_jailed (the three are gone)

@export var varrik: NodePath
@export var guard_west: NodePath
@export var guard_east: NodePath
## Where they leave the hall (map coordinates).
@export var exit: Vector2 = Vector2(0, 230)


func _play_beat(id: String) -> bool:
	if id != "varrik_dragged":
		return false
	_drag()
	return true


func _drag() -> void:
	var prisoner := node2d(varrik)
	var west := node2d(guard_west)
	var east := node2d(guard_east)
	if prisoner == null:
		GameState.run_story_action("set_flag:varrik_jailed")
		return
	var body := player()
	if body:
		walk_player(PackedVector2Array([body.global_position + Vector2(44, -6)]), "left", 0.6)
	# hauled up by the shoulders
	for guard: Node2D in [west, east]:
		if guard:
			face_npc(guard, "right" if guard == west else "left")
	var figure := figure_of(prisoner)
	if figure:
		var haul := create_tween()
		haul.tween_property(figure, "position:y", figure.position.y - 4.0, 0.15)
		haul.tween_property(figure, "position:y", figure.position.y, 0.15)
	AudioManager.play_sound("step", 0.8)
	if not await wait(0.6):
		return
	var parent := get_parent() as Node2D
	var out: Vector2 = parent.to_global(exit) if parent else exit
	# dragged backwards: Varrik keeps facing the throne and jerks to and fro
	_struggle(prisoner)
	if west:
		walk_npc(west, PackedVector2Array([Vector2(out.x - 22, out.y)]), 70.0)
	if east:
		walk_npc(east, PackedVector2Array([Vector2(out.x + 22, out.y)]), 70.0)
	while is_inside_tree() and is_instance_valid(prisoner) and prisoner.global_position.distance_to(Vector2(out.x, out.y - 4)) > 1.0:
		prisoner.global_position += (Vector2(out.x, out.y - 4) - prisoner.global_position).limit_length(70.0 * get_process_delta_time())
		await get_tree().process_frame
	if not is_inside_tree():
		return
	# out of the hall: gone (without the walk back to their leave_path)
	for npc: Node2D in [prisoner, west, east]:
		if npc and is_instance_valid(npc) and npc.has_method("_hide_body"):
			npc.call("_hide_body")
	AudioManager.play_sound("door", 0.5)
	shake(0.2, 1.0)
	GameState.run_story_action("set_flag:varrik_jailed")


func _struggle(prisoner: Node2D) -> void:
	var figure := figure_of(prisoner)
	if figure == null:
		return
	face_npc(prisoner, "up")
	var home_x: float = figure.position.x
	var step: int = 0
	while is_inside_tree() and is_instance_valid(figure) and prisoner.visible:
		step += 1
		figure.position.x = home_x + (1.0 if step % 2 == 0 else -1.0)
		if not await wait(0.2):
			return
