class_name LevelTable
extends Resource
## Experience needed per level (data/hero_level_table.tres). Entry i = experience to get from
## level i+1 to level i+2, so the table has (max level - 1) entries. The values grow
## exponentially (about +8 % per level) and can be balanced directly in the .tres file.

@export var experience_to_next: Array[int] = []


func get_max_level() -> int:
	return experience_to_next.size() + 1


## Experience needed to get from `level` to the next level. 0 at the max level.
func get_experience_to_next(level: int) -> int:
	if level < 1 or level >= get_max_level():
		return 0
	return experience_to_next[level - 1]
