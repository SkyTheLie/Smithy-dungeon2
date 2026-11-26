class_name ResourceFields
extends RefCounted
## Farmable resources (ore rocks, trees, plants) of every area for the current day.
## A spawner asks for its area: on the first visit of a day new resources are generated and
## stored here; mined ones are removed, damaged ones keep their health, so leaving and coming
## back changes nothing. On the next day the stored list no longer matches the day, so the
## rest expires and the spawner generates a fresh set. Lives in GameState.resource_fields.
## Each entry: {"kind": RockData path, "x": float, "y": float, "health": int (-1 = full)}.

## area id -> {"day": int, "nodes": Array of entries}
var _areas: Dictionary = {}


## Entries of the area for `day`, or null if they still have to be generated.
func get_nodes(area_id: String, day: int) -> Variant:
	var area: Dictionary = _areas.get(area_id, {})
	if area.is_empty() or int(area.get("day", -1)) != day:
		return null
	return area["nodes"]


func set_nodes(area_id: String, day: int, nodes: Array) -> void:
	_areas[area_id] = {"day": day, "nodes": nodes}


func to_save_data() -> Dictionary:
	return _areas.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	_areas = data.duplicate(true)
