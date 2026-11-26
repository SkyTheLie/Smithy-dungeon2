class_name HouseLevelGate
extends Node2D
## Shows its children only at some levels of the player's house (GameState.house.level, see
## House): from `min_level` up to `max_level`. At other levels the node removes itself with
## everything below it (pictures, collisions, doors, spawn points, stations).
## Put gates above the Player in the scene: they take their spawn points out of the group
## "spawn_points" in _ready, before the player looks for his spawn point.
## The level only changes by buying or the builder's test switch, both reload the scene.

@export_range(1, 5) var min_level: int = 1
@export_range(1, 5) var max_level: int = 5


func _ready() -> void:
	if is_active():
		return
	_leave_groups(self)
	hide()
	queue_free()


func is_active() -> bool:
	var level: int = GameState.house.level
	return level >= min_level and level <= max_level


func _leave_groups(node: Node) -> void:
	for group in node.get_groups():
		if not String(group).begins_with("_"):
			node.remove_from_group(group)
	for child in node.get_children():
		_leave_groups(child)
