class_name RaidPlunderCutscene
extends StoryCutscene
## The undead plunder the smithy during the raid (dialogue "raid_looter_spare"):
## - raid_plunder: two undead shuffle into the smithy, chests splinter and shelves crash inside,
##   then they come out with the loot over their heads (gold, ore, ingots) and stand ready;
##   the next line sets raid_spared and they all leave east along their leave_path with it

@export var looters: Array[NodePath] = []
## The smithy door they go into (global position of the node).
@export var door: NodePath

const LOOT: Array[String] = ["res://assets/sprites/items/coin_purse.png", "res://assets/sprites/items/iron_ore.png",
		"res://assets/sprites/items/copper_ingot.png", "res://assets/sprites/items/iron_ingot.png"]


func _play_beat(id: String) -> bool:
	if id != "raid_plunder":
		return false
	_plunder()
	return true


func _plunder() -> void:
	var entrance := node2d(door)
	if entrance == null:
		return
	var at: Vector2 = entrance.global_position
	var homes: Dictionary = {}
	var index: int = 0
	for path in looters:
		var undead := node2d(path)
		if undead == null:
			continue
		homes[undead] = undead.global_position
		_go_in(undead, at + Vector2(-6 + 12 * index, 4), 0.3 * index)
		index += 1
	if not await wait(1.5):
		return
	# inside: chests splinter, shelves crash
	for sound in ["wood_break", "rock_break", "wood_break", "chest_open", "wood_break"]:
		AudioManager.play_sound(sound, randf_range(0.6, 0.9))
		fx.spawn("earth_hit", at + Vector2(randf_range(-30, 30), randf_range(-40, -14)), Color.WHITE)
		shake(0.15, 1.0)
		if not await wait(0.3):
			return
	# out again with the loot over their heads
	index = 0
	for undead: Node2D in homes.keys():
		if not is_instance_valid(undead):
			continue
		_carry(undead, index)
		var figure := figure_of(undead)
		if figure:
			create_tween().tween_property(figure, "modulate:a", 1.0, 0.2)
		walk_npc(undead, PackedVector2Array([homes[undead]]), 34.0, "down")
		index += 1


func _go_in(undead: Node2D, target: Vector2, delay: float) -> void:
	if delay > 0.0 and not await wait(delay):
		return
	await walk_npc(undead, PackedVector2Array([Vector2(undead.global_position.x, target.y + 10), target]), 38.0, "up")
	var figure := figure_of(undead)
	if figure and is_instance_valid(figure):
		create_tween().tween_property(figure, "modulate:a", 0.0, 0.2)


## Two pieces of loot stacked over the head (children of the figure, they leave with it).
func _carry(undead: Node2D, index: int) -> void:
	for i in 2:
		var icon := Sprite2D.new()
		icon.texture = load(LOOT[(index * 2 + i) % LOOT.size()])
		icon.scale = Vector2(0.75, 0.75)
		icon.position = Vector2(-3 + 6 * i, -36 - 5 * i)
		undead.add_child(icon)
