class_name AureliusCutscene
extends StoryCutscene
## Aurelius comes and goes (dialogues "king_fire_crystal_given" and "mage_stones_legend"):
## - aurelius_rushes_in (throne room): the hall door flies open, he hurries in out of breath
##   (flag aurelius_at_court); his hurrying out later is his leave_path
## - aurelius_wind (deep forest): he murmurs, a gust whirls up the leaves around him and he is
##   gone (flag mage_left_for_lich)
## - faelan_off (deep forest, dialogue "aurelius_wake"): Faelan nods, walks off down the path and is
##   gone before the conversation goes on (flag faelan_left_clearing)

@export var aurelius: NodePath
## Faelan at the edge of the clearing, for faelan_off.
@export var faelan: NodePath
## Where Faelan walks to before he fades (relative to where he stands), for faelan_off.
@export var faelan_way: PackedVector2Array = [Vector2(0, 45), Vector2(50, 45)]
## Where he comes in (map coordinates), for aurelius_rushes_in.
@export var door: Vector2 = Vector2(0, 230)

const LEAF: Color = Color(0.55, 0.85, 0.35)


func _play_beat(id: String) -> bool:
	match id:
		"aurelius_rushes_in":
			_rush_in()
		"aurelius_wind":
			_wind()
		"faelan_off":
			_faelan_off()
		_:
			return false
	return true


func _rush_in() -> void:
	var mage := node2d(aurelius)
	if mage == null:
		GameState.run_story_action("set_flag:aurelius_at_court")
		return
	# to the door in the same frame the flag shows him, so he never stands at his place first
	var spot: Vector2 = mage.global_position
	GameState.run_story_action("set_flag:aurelius_at_court")
	var parent := get_parent() as Node2D
	var entry: Vector2 = parent.to_global(door) if parent else door
	mage.global_position = entry
	await get_tree().process_frame
	if not is_instance_valid(mage):
		return
	AudioManager.play_sound("door", 0.9)
	shake(0.2, 1.0)
	await walk_npc(mage, PackedVector2Array([Vector2(entry.x, spot.y + 20), spot]), 95.0, "up")
	# out of breath
	var figure := figure_of(mage)
	if figure and is_instance_valid(figure):
		var pant := create_tween().set_loops(3)
		pant.tween_property(figure, "position:y", figure.position.y + 1.0, 0.18)
		pant.tween_property(figure, "position:y", figure.position.y, 0.18)


func _wind() -> void:
	var mage := node2d(aurelius)
	if mage == null:
		GameState.run_story_action("set_flag:mage_left_for_lich")
		return
	var at: Vector2 = mage.global_position
	AudioManager.play_sound("skill_used", 0.6)
	fx.spawn("air_hit", at + Vector2(0, -14), Color.WHITE)
	fx.spawn("area_storm", at, LEAF)
	_leaves(at)
	if not await wait(0.5):
		return
	var figure := figure_of(mage)
	if figure:
		var spin := create_tween().set_parallel()
		spin.tween_property(figure, "modulate:a", 0.0, 0.6)
		spin.tween_property(figure, "scale:x", 0.2, 0.6)
		await spin.finished
		if is_instance_valid(figure):
			figure.scale.x = 1.0
	if mage.has_method("_hide_body") and is_instance_valid(mage):
		mage.call("_hide_body")
	GameState.run_story_action("set_flag:mage_left_for_lich")


func _faelan_off() -> void:
	var elf := node2d(faelan)
	if elf == null or not elf.visible:
		GameState.run_story_action("set_flag:faelan_left_clearing")
		return
	await NpcActing.play(elf, "nod")
	if not is_inside_tree() or not is_instance_valid(elf):
		return
	var way := PackedVector2Array()
	for step in faelan_way:
		way.append(elf.global_position + step)
	await walk_npc(elf, way, 70.0)
	if not is_instance_valid(elf):
		return
	var fade := create_tween()
	fade.tween_property(elf, "modulate:a", 0.0, 0.3)
	await fade.finished
	# gone for good: the figure vanishes with the flag (vanish_on_leave)
	GameState.run_story_action("set_flag:faelan_left_clearing")


## A whirl of little leaves around `at` that flies up and fades.
func _leaves(at: Vector2) -> void:
	for i in 12:
		var leaf := Polygon2D.new()
		leaf.polygon = PackedVector2Array([Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0), Vector2(0, 1)])
		leaf.color = LEAF.darkened(randf_range(0.0, 0.4))
		leaf.z_index = 2
		leaf.z_as_relative = false
		add_child(leaf)
		var angle: float = TAU * i / 12.0
		leaf.global_position = at + Vector2(cos(angle), sin(angle) * 0.5) * 10.0
		var whirl := create_tween()
		whirl.tween_method(func(t: float) -> void:
			if is_instance_valid(leaf):
				var a: float = angle + t * 8.0
				leaf.global_position = at + Vector2(cos(a) * (10.0 + t * 14.0), sin(a) * (5.0 + t * 6.0) - 6.0 - t * 34.0)
				leaf.modulate.a = 1.0 - t,
			0.0, 1.0, 1.4)
		whirl.tween_callback(leaf.queue_free)
