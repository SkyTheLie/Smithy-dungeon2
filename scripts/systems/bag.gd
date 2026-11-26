class_name Bag
extends RefCounted
## The bag of a run (Tab): loot from the dungeon (data/loot.json "materials"). A fixed number of
## places (data/meta.json "bag": slots) plus safe places (safe_slots) at the end. Dying empties
## the bag except the safe places (lose_unsafe). The gold of the run is in here too (material
## "gold", GOLD, only from selling loot in the dungeon shop): it stacks higher (loot.json
## "stack"), can be dropped and put into the safe place like everything else; RunState.coins
## only counts it.
##
## A place is {} (empty) or {"id": String, "count": int}. Indices 0 .. slots - 1 are normal,
## slots .. size() - 1 are safe.

signal changed

var places: Array[Dictionary] = []
var normal_count: int = 12
var stack_limit: int = 20

## The material id of the run's gold (data/loot.json).
const GOLD: String = "gold"


func _init() -> void:
	var settings: Dictionary = Content.meta("bag")
	normal_count = maxi(1, int(settings.get("slots", 12)))
	stack_limit = maxi(1, int(settings.get("stack", 20)))
	var total: int = normal_count + maxi(0, int(settings.get("safe_slots", 1)))
	for i in total:
		places.append({})


## More places (skills: Größerer Rucksack, Geheimtasche): normal ones before the safe ones.
func grow(extra_normal: int, extra_safe: int) -> void:
	for i in maxi(0, extra_normal):
		places.insert(normal_count, {})
		normal_count += 1
	for i in maxi(0, extra_safe):
		places.append({})
	changed.emit()


func size() -> int:
	return places.size()


func is_safe(index: int) -> bool:
	return index >= normal_count and index < places.size()


func get_place(index: int) -> Dictionary:
	if index < 0 or index >= places.size():
		return {}
	return places[index]


## How many of `id` fit on one place: data/loot.json "stack" of the material, else meta.json.
func stack_of(id: String) -> int:
	return maxi(1, int(Content.material(id).get("stack", stack_limit)))


## How many of `id` are in the bag (normal and safe places).
func count_of(id: String) -> int:
	var total: int = 0
	for place: Dictionary in places:
		if not place.is_empty() and String(place["id"]) == id:
			total += int(place["count"])
	return total


## Takes `amount` of `id` out (normal places first, then the safe ones). false (nothing taken) if
## there is not that much or the amount is <= 0.
func remove(id: String, amount: int) -> bool:
	if amount <= 0 or count_of(id) < amount:
		return false
	var left: int = amount
	for i in places.size():
		if left <= 0:
			break
		if places[i].is_empty() or String(places[i]["id"]) != id:
			continue
		var taken: int = mini(left, int(places[i]["count"]))
		places[i]["count"] = int(places[i]["count"]) - taken
		left -= taken
		if int(places[i]["count"]) <= 0:
			places[i] = {}
	changed.emit()
	return true


## How many of `id` would still fit into the normal places (stacks first, then empty places).
func room_for(id: String) -> int:
	var room: int = 0
	for i in normal_count:
		if places[i].is_empty():
			room += stack_of(id)
		elif String(places[i]["id"]) == id:
			room += stack_of(id) - int(places[i]["count"])
	return room


## Puts `amount` of `id` into the normal places (onto stacks of the same thing first).
## Returns how many did not fit (0 = all in). Unknown ids and amounts <= 0 are refused.
func add(id: String, amount: int) -> int:
	if amount <= 0 or Content.material(id).is_empty():
		return maxi(amount, 0)
	var left: int = amount
	for i in normal_count:
		if left > 0 and not places[i].is_empty() and String(places[i]["id"]) == id:
			var put: int = mini(left, stack_of(id) - int(places[i]["count"]))
			places[i]["count"] = int(places[i]["count"]) + put
			left -= put
	for i in normal_count:
		if left > 0 and places[i].is_empty():
			var put: int = mini(left, stack_of(id))
			places[i] = {"id": id, "count": put}
			left -= put
	if left < amount:
		changed.emit()
	return left


## Puts `count` of `id` onto the empty place `index` (also a safe one). false (nothing changes)
## if the place is taken, the index is wrong, the id unknown or the count <= 0.
func put(index: int, id: String, count: int) -> bool:
	if index < 0 or index >= places.size() or not places[index].is_empty():
		return false
	if count <= 0 or Content.material(id).is_empty():
		return false
	places[index] = {"id": id, "count": count}
	changed.emit()
	return true


## Drag and drop from place `from` to place `to`: the same thing stacks (what does not fit stays),
## otherwise the two places swap. Works between normal and safe places.
func move(from: int, to: int) -> void:
	if from == to or from < 0 or to < 0 or from >= places.size() or to >= places.size():
		return
	var source: Dictionary = places[from]
	if source.is_empty():
		return
	var target: Dictionary = places[to]
	if not target.is_empty() and String(target["id"]) == String(source["id"]):
		var put: int = mini(int(source["count"]), stack_of(String(source["id"])) - int(target["count"]))
		target["count"] = int(target["count"]) + put
		source["count"] = int(source["count"]) - put
		if int(source["count"]) <= 0:
			places[from] = {}
	else:
		places[from] = target
		places[to] = source
	changed.emit()


## Takes the whole place out (to drop it on the floor). Returns what was there ({} if empty).
func take(index: int) -> Dictionary:
	var place: Dictionary = get_place(index)
	if place.is_empty():
		return {}
	places[index] = {}
	changed.emit()
	return place


## Death: everything outside the safe places is gone. Returns what stays (the safe places).
func lose_unsafe() -> Array[Dictionary]:
	for i in normal_count:
		places[i] = {}
	changed.emit()
	return safe_contents()


func safe_contents() -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	for i in range(normal_count, places.size()):
		if not places[i].is_empty():
			kept.append(places[i].duplicate())
	return kept


## Everything in the bag (normal and safe), as a list of copies.
func contents() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for place: Dictionary in places:
		if not place.is_empty():
			all.append(place.duplicate())
	return all


## Gold the merchant pays for all of it (data/loot.json "value").
func total_value() -> int:
	var total: int = 0
	for place: Dictionary in places:
		if not place.is_empty():
			total += int(Content.material(String(place["id"])).get("value", 0)) * int(place["count"])
	return total
