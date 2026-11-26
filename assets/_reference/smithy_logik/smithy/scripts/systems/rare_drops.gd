class_name RareDrops
extends RefCounted
## Rare drops that come from counting kills, not from a chance per kill (combat.json "rare_drops",
## RareDropRule), e.g. soul shards: every monster in the dungeons of the chapter counts, after about
## 50 kills one drops (sometimes earlier, sometimes later). The count goes on across adventures and
## is saved. Luck and hard modes make a kill count more (Adventure._roll_loot).

## Item id -> kills counted since the last drop (weighted).
var progress: Dictionary[String, float] = {}
## Item id -> kills needed for the next drop (rolled after each drop).
var targets: Dictionary[String, float] = {}


## A monster in `dungeon` died; `weight` = how much the kill counts (1 = normal). Returns one
## ItemData per rare drop that happened.
func count_kill(dungeon: DungeonData, weight: float = 1.0) -> Array[ItemData]:
	var dropped: Array[ItemData] = []
	if weight <= 0.0:
		return dropped
	for rule: RareDropRule in ContentDB.rare_drops():
		if not rule.covers(dungeon):
			continue
		var id: String = String(rule.item.id)
		if not targets.has(id):
			targets[id] = rule.roll_target()
		progress[id] = progress.get(id, 0.0) + weight
		if progress[id] >= targets[id]:
			progress[id] -= targets[id]
			targets[id] = rule.roll_target()
			dropped.append(rule.item)
	return dropped


func to_save_data() -> Dictionary:
	# Plain dictionaries: a loaded save (JSON) has no types either.
	var saved_progress: Dictionary = {}
	saved_progress.merge(progress)
	var saved_targets: Dictionary = {}
	saved_targets.merge(targets)
	return {"progress": saved_progress, "targets": saved_targets}


func load_save_data(data: Dictionary) -> void:
	progress.clear()
	targets.clear()
	for id: String in data.get("progress", {}):
		progress[id] = float(data["progress"][id])
	for id: String in data.get("targets", {}):
		targets[id] = float(data["targets"][id])
