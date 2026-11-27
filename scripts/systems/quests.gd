class_name Quests
extends RefCounted
## Egon's quests (data/quests.json), only rules: a quest is open while its dungeon is open and it
## is not done; then the end boss of that dungeon drops its stone (loot.json, quest: true) unless
## the player has it already (stash or bag). Handing the stone in (MetaState.deliver_quest) opens
## the dungeons with unlock {"quest": id}, Egon moves on (location) and pays gold. What is done and
## where Egon is lives in MetaState.


static func all() -> Dictionary:
	return Content.get_file("quests").get("quests", {})


static func data(id: String) -> Dictionary:
	return all().get(id, {})


## Egon's place before any quest is done.
static func start() -> String:
	return String(Content.get_file("quests").get("start", ""))


## {name, background} of location `id` (data/quests.json locations).
static func location_data(id: String) -> Dictionary:
	return (Content.get_file("quests").get("locations", {}) as Dictionary).get(id, {})


## Open quests (their dungeon is open, not done yet), in data order.
static func open_quests() -> Array[String]:
	var list: Array[String] = []
	for id: String in all():
		if not MetaState.quest_done(id) and MetaState.is_dungeon_open(String(data(id).get("dungeon", ""))):
			list.append(id)
	return list


## true for a quest stone (loot.json "quest": true).
static func is_stone(item_id: String) -> bool:
	return bool(Content.material(item_id).get("quest", false))


## The open quest that wants stone `item_id` ("" = none).
static func quest_of_stone(item_id: String) -> String:
	for id: String in open_quests():
		if String(data(id).get("item", "")) == item_id:
			return id
	return ""


## What the end boss of dungeon `dungeon_id` drops for Egon's quest ("" = nothing): the stone of
## the open quest of that dungeon, if it is neither in the stash nor in `bag`.
static func drop_for(dungeon_id: String, bag: Bag) -> String:
	for id: String in open_quests():
		if String(data(id).get("dungeon", "")) != dungeon_id:
			continue
		var stone: String = String(data(id).get("item", ""))
		if bag != null and bag.count_of(stone) > 0:
			return ""
		for piece: Dictionary in MetaState.stash() + MetaState.bag_places():
			if String(piece.get("id", "")) == stone:
				return ""
		return stone
	return ""


## true if a stone of an open quest lies in the bag at home.
static func stone_in_bag() -> int:
	var places: Array[Dictionary] = MetaState.bag_places()
	for i in places.size():
		if not quest_of_stone(String(places[i].get("id", ""))).is_empty():
			return i
	return -1


## The stash place of a stone that can be handed in now (-1 = none).
static func deliverable_index() -> int:
	var own: Array[Dictionary] = MetaState.stash()
	for i in own.size():
		if not quest_of_stone(String(own[i].get("id", ""))).is_empty():
			return i
	return -1
