class_name Bag
extends RefCounted
## The bag of a run (Tab): loot from the dungeon (data/loot.json "materials") on a grid of cells,
## like a backpack game. The base bag has columns × rows cells (data/meta.json "bag"); backpacks
## the player attached at home add cells (add_backpacks, BagLayout). Every piece of loot takes
## BagLayout.loot_size cells (a rat fur 2×2, a staff 4×1, a ruby 3×3) and can be turned by 90
## degrees. Besides the bag lies the safe place (its own little grid, meta.json bag.safe; the
## skill Geheimtasche makes it wider): what lies there stays when the player dies (lose_unsafe).
## Otherwise it is a part of the bag like any other: what lies there counts, is used (bombs,
## keys, gold), stacks and takes new loot once the bag is full.
## The gold of the run is in here too (material "gold", GOLD, only from selling loot in the
## dungeon shop): it stacks (loot.json "stack"), RunState.coins only counts it.
##
## A place (one piece of loot) is {"id", "count", "x", "y", "rot"}: x, y = its top left cell.
## A piece of gear, a relic or a potion brought from the stash at home (is_piece) is a place too,
## with its own fields (rarity / relic, left / potion) and count 1; it never stacks, its size is
## ShopGoods.piece_size. Put in with put_place / add_piece, not with add / put_at.
## Places are addressed by their index in `places`; it changes when a place is taken out.
## Cells of the safe place lie far right of the bag (SAFE_ORIGIN), so nothing reaches over both.

signal changed

## The material id of the run's gold (data/loot.json).
const GOLD: String = "gold"
## Bombs and the fragile keys of the dungeon are loot in the bag too (data/loot.json).
const BOMB: String = "bomb"
const KEY: String = "key"
const MAIN: String = "main"
const SAFE: String = "safe"
## The safe place's top left cell (far away from every backpack, see BagLayout.board_rect).
const SAFE_ORIGIN := Vector2i(1000, 0)

## Cell -> what it belongs to: "" = the base bag, a backpack id, or SAFE.
var cells: Dictionary[Vector2i, String] = {}
var places: Array[Dictionary] = []
var stack_limit: int = 1
## Width and height of the safe place in cells.
var safe_size := Vector2i(2, 2)


func _init() -> void:
	var settings: Dictionary = BagLayout.settings()
	stack_limit = maxi(1, int(settings.get("stack", 1)))
	for cell: Vector2i in BagLayout.base_cells():
		cells[cell] = ""
	var safe: Array = settings.get("safe", [2, 2])
	safe_size = Vector2i(maxi(1, int(safe[0])), maxi(1, int(safe[1]))) if safe.size() >= 2 else Vector2i(2, 2)
	_build_safe()


func _build_safe() -> void:
	for y in safe_size.y:
		for x in safe_size.x:
			cells[SAFE_ORIGIN + Vector2i(x, y)] = SAFE


## The backpacks attached at home (MetaState.backpacks): their cells join the bag. Invalid
## placements (BagLayout.is_valid) are ignored as a whole.
func add_backpacks(placements: Array) -> void:
	if placements.is_empty() or not BagLayout.is_valid(placements):
		return
	for entry: Variant in placements:
		for cell: Vector2i in BagLayout.cells_of(entry):
			cells[cell] = String((entry as Dictionary)["id"])
	changed.emit()


## The safe place gets `extra_columns` more columns (skill Geheimtasche).
func grow_safe(extra_columns: int) -> void:
	if extra_columns <= 0:
		return
	safe_size.x += extra_columns
	_build_safe()
	changed.emit()


# --- Cells ------------------------------------------------------------------------

## MAIN or SAFE for a cell of the bag ("" = not a cell of the bag).
func section_of(cell: Vector2i) -> String:
	if not cells.has(cell):
		return ""
	return SAFE if cells[cell] == SAFE else MAIN


## Every cell of `section` (MAIN: bag and backpacks, SAFE: the safe place).
func section_cells(section: String) -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if section_of(cell) == section:
			list.append(cell)
	return list


## Width × height of place `place` as it lies (turned or not).
static func footprint(place: Dictionary) -> Vector2i:
	return BagLayout.turned(size_of(place), bool(place.get("rot", false)))


## Width × height of a place, not turned: pieces by ShopGoods.piece_size, loot by loot.json size.
static func size_of(place: Dictionary) -> Vector2i:
	return ShopGoods.piece_size(place) if is_piece(place) else BagLayout.loot_size(String(place.get("id", "")))


## true for a piece of gear, a relic or a potion (not loot).
static func is_piece(place: Dictionary) -> bool:
	return place.has("rarity") or ShopGoods.is_relic(place) or ShopGoods.is_potion(place)


## true if the bag may hold `place`: loot of loot.json, or gear / a relic / a potion that exists.
static func is_known(place: Dictionary) -> bool:
	var id: String = String(place.get("id", ""))
	if ShopGoods.is_relic(place):
		return (Content.relics().get("items", {}) as Dictionary).has(id)
	if ShopGoods.is_potion(place):
		return not Content.potion(id).is_empty()
	if place.has("rarity"):
		return ShopGoods.is_gear(id)
	return not Content.material(id).is_empty()


static func cells_of_place(place: Dictionary) -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	var span: Vector2i = footprint(place)
	var at := Vector2i(int(place.get("x", 0)), int(place.get("y", 0)))
	for y in span.y:
		for x in span.x:
			list.append(at + Vector2i(x, y))
	return list


## The index of the place lying on `cell` (-1 = free or not a cell).
func place_at_cell(cell: Vector2i) -> int:
	for i in places.size():
		if cells_of_place(places[i]).has(cell):
			return i
	return -1


## true if loot `id` (turned when `rot`) fits with its top left at `at`: every cell is a cell of
## one section and free (the places in `ignore` do not count).
func fits(id: String, at: Vector2i, rot: bool, ignore: Array[int] = []) -> bool:
	return fits_piece({"id": id}, at, rot, ignore)


## Like fits, for any place (loot or a piece; its size by size_of).
func fits_piece(piece: Dictionary, at: Vector2i, rot: bool, ignore: Array[int] = []) -> bool:
	var probe: Dictionary = piece.duplicate()
	probe.merge({"x": at.x, "y": at.y, "rot": rot}, true)
	var section: String = ""
	var mine: Array[Vector2i] = cells_of_place(probe)
	for cell: Vector2i in mine:
		var here: String = section_of(cell)
		if here.is_empty() or (not section.is_empty() and here != section):
			return false
		section = here
	for i in places.size():
		if ignore.has(i):
			continue
		for cell: Vector2i in cells_of_place(places[i]):
			if mine.has(cell):
				return false
	return true


## The first free spot for loot `id` in `section` (rows from the top, then turned): {"x", "y",
## "rot"} or {} when it does not fit anywhere.
func free_spot(id: String, section: String = MAIN) -> Dictionary:
	return free_spot_for({"id": id}, section)


## Like free_spot, for any place (loot or a piece).
func free_spot_for(piece: Dictionary, section: String = MAIN) -> Dictionary:
	var list: Array[Vector2i] = section_cells(section)
	list.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	var span: Vector2i = size_of(piece)
	var turns: Array[bool] = [false]
	if span.x != span.y:
		turns.append(true)
	for rot: bool in turns:
		for cell: Vector2i in list:
			if fits_piece(piece, cell, rot):
				return {"x": cell.x, "y": cell.y, "rot": rot}
	return {}


## The first free spot for `piece`: in the bag, else in the safe place ({} = nowhere).
func _first_free(piece: Dictionary) -> Dictionary:
	var spot: Dictionary = free_spot_for(piece, MAIN)
	return spot if not spot.is_empty() else free_spot_for(piece, SAFE)


## Indices of the places: those in the bag first, then those in the safe place.
func _bag_first() -> Array[int]:
	var order: Array[int] = []
	for i in places.size():
		if not is_safe(i):
			order.append(i)
	for i in places.size():
		if is_safe(i):
			order.append(i)
	return order


# --- Places -----------------------------------------------------------------------

func size() -> int:
	return places.size()


func is_safe(index: int) -> bool:
	if index < 0 or index >= places.size():
		return false
	return section_of(Vector2i(int(places[index]["x"]), int(places[index]["y"]))) == SAFE


func get_place(index: int) -> Dictionary:
	if index < 0 or index >= places.size():
		return {}
	return places[index]


## How many of `id` fit on one place: data/loot.json "stack" of the material, else meta.json.
func stack_of(id: String) -> int:
	return maxi(1, int(Content.material(id).get("stack", stack_limit)))


## How many of `id` are in the bag (bag and safe place).
func count_of(id: String) -> int:
	var total: int = 0
	for place: Dictionary in places:
		if String(place["id"]) == id:
			total += int(place["count"])
	return total


## Takes `amount` of `id` out (bag first, then the safe place). false (nothing taken) if there
## is not that much or the amount is <= 0.
func remove(id: String, amount: int) -> bool:
	if amount <= 0 or count_of(id) < amount:
		return false
	var left: int = amount
	var order: Array[int] = _bag_first()
	var emptied: Array[int] = []
	for i: int in order:
		if left <= 0:
			break
		if String(places[i]["id"]) != id:
			continue
		var taken: int = mini(left, int(places[i]["count"]))
		places[i]["count"] = int(places[i]["count"]) - taken
		left -= taken
		if int(places[i]["count"]) <= 0:
			emptied.append(i)
	emptied.sort()
	emptied.reverse()
	for i: int in emptied:
		places.remove_at(i)
	changed.emit()
	return true


## How many of `id` would still fit into the bag (onto stacks, then into free spots).
func room_for(id: String) -> int:
	if Content.material(id).is_empty():
		return 0
	var room: int = 0
	for i in places.size():
		if String(places[i]["id"]) == id:
			room += stack_of(id) - int(places[i]["count"])
	# Fill a copy with full stacks until nothing fits any more.
	var saved: Array[Dictionary] = places.duplicate(true)
	var spot: Dictionary = _first_free({"id": id})
	while not spot.is_empty():
		places.append({"id": id, "count": stack_of(id), "x": spot["x"], "y": spot["y"], "rot": spot["rot"]})
		room += stack_of(id)
		spot = _first_free({"id": id})
	places = saved
	return room


## Puts `amount` of `id` into the bag (onto stacks of the same thing first, then into the first
## free spots). The safe place is a part of the bag like any other: its stacks fill up too, and
## once the bag is full new things go there (the bag first, so the safe place stays free for
## what the player puts there by hand). Returns how many did not fit (0 = all in). Unknown ids
## and amounts <= 0 are refused.
func add(id: String, amount: int) -> int:
	if amount <= 0 or Content.material(id).is_empty():
		return maxi(amount, 0)
	var left: int = amount
	for i: int in _bag_first():
		if left > 0 and String(places[i]["id"]) == id:
			var put: int = mini(left, stack_of(id) - int(places[i]["count"]))
			places[i]["count"] = int(places[i]["count"]) + put
			left -= put
	while left > 0:
		var spot: Dictionary = _first_free({"id": id})
		if spot.is_empty():
			break
		var put: int = mini(left, stack_of(id))
		places.append({"id": id, "count": put, "x": int(spot["x"]), "y": int(spot["y"]), "rot": bool(spot["rot"])})
		left -= put
	if left < amount:
		changed.emit()
	return left


## Puts `count` of `id` with its top left on `cell` (also in the safe place). false (nothing
## changes) if it does not fit there, the id is unknown or the count <= 0.
func put_at(cell: Vector2i, id: String, count: int, rot: bool = false) -> bool:
	if count <= 0 or Content.material(id).is_empty() or not fits(id, cell, rot):
		return false
	places.append({"id": id, "count": count, "x": cell.x, "y": cell.y, "rot": rot})
	changed.emit()
	return true


## Puts `place` (loot or a piece, with "x", "y", "rot") onto its cells. A piece keeps its own
## fields and gets count 1. false (nothing changes) if it does not fit or is unknown.
func put_place(place: Dictionary) -> bool:
	var at := Vector2i(int(place.get("x", -9999)), int(place.get("y", -9999)))
	var rot: bool = bool(place.get("rot", false))
	if not is_piece(place):
		return put_at(at, String(place.get("id", "")), int(place.get("count", 1)), rot)
	if not is_known(place) or not fits_piece(place, at, rot):
		return false
	var copy: Dictionary = place.duplicate()
	copy.merge({"count": 1, "x": at.x, "y": at.y, "rot": rot}, true)
	places.append(copy)
	changed.emit()
	return true


## A piece into the first free spot of the bag (the safe place when the bag is full).
## false = no room / unknown.
func add_piece(piece: Dictionary) -> bool:
	if not is_piece(piece) or not is_known(piece):
		return false
	var spot: Dictionary = _first_free(piece)
	if spot.is_empty():
		return false
	var placed: Dictionary = piece.duplicate()
	placed.merge(spot, true)
	return put_place(placed)


## Drag and drop: place `index` goes with its top left onto `cell`, turned when `rot`. If it lands
## on exactly one other place: the same thing stacks (what does not fit stays), otherwise the two
## swap when the other one fits where the dragged one was. false = nothing changed.
func move_to(index: int, cell: Vector2i, rot: bool) -> bool:
	if index < 0 or index >= places.size():
		return false
	var source: Dictionary = places[index]
	var id: String = String(source["id"])
	if size_of(source).x == size_of(source).y:
		rot = false
	if fits_piece(source, cell, rot, [index]):
		source["x"] = cell.x
		source["y"] = cell.y
		source["rot"] = rot
		changed.emit()
		return true
	# What lies under it?
	var probe: Dictionary = source.duplicate()
	probe.merge({"x": cell.x, "y": cell.y, "rot": rot}, true)
	var under: Array[int] = []
	for c: Vector2i in cells_of_place(probe):
		if section_of(c).is_empty():
			return false
		var other: int = place_at_cell(c)
		if other >= 0 and other != index and not under.has(other):
			under.append(other)
	if under.size() != 1:
		return false
	var target: Dictionary = places[under[0]]
	if String(target["id"]) == id and stack_of(id) > 1 and not is_piece(source) and not is_piece(target):
		var put: int = mini(int(source["count"]), stack_of(id) - int(target["count"]))
		if put <= 0:
			return false
		target["count"] = int(target["count"]) + put
		source["count"] = int(source["count"]) - put
		if int(source["count"]) <= 0:
			places.remove_at(index)
		changed.emit()
		return true
	# Swap: the dragged one to `cell`, the other one to where the dragged one was.
	var old := Vector2i(int(source["x"]), int(source["y"]))
	var old_rot: bool = bool(source["rot"])
	var other_old := Vector2i(int(target["x"]), int(target["y"]))
	var other_rot: bool = bool(target["rot"])
	source["x"] = cell.x
	source["y"] = cell.y
	source["rot"] = rot
	target["x"] = -99999
	target["y"] = -99999
	for turn: bool in [other_rot, not other_rot]:
		if fits_piece(target, old, turn, [under[0]]) and _fits_with(under[0], old, turn):
			target["x"] = old.x
			target["y"] = old.y
			target["rot"] = turn
			changed.emit()
			return true
	source["x"] = old.x
	source["y"] = old.y
	source["rot"] = old_rot
	target["x"] = other_old.x
	target["y"] = other_old.y
	target["rot"] = other_rot
	return false


## true if place `index` at `at` (turned `rot`) covers no cell of the other places.
func _fits_with(index: int, at: Vector2i, rot: bool) -> bool:
	var probe: Dictionary = places[index].duplicate()
	probe.merge({"x": at.x, "y": at.y, "rot": rot}, true)
	var mine: Array[Vector2i] = cells_of_place(probe)
	for i in places.size():
		if i == index:
			continue
		for c: Vector2i in cells_of_place(places[i]):
			if mine.has(c):
				return false
	return true


## Takes the whole place out (to drop it on the floor or sell it). Returns what was there.
func take(index: int) -> Dictionary:
	if index < 0 or index >= places.size():
		return {}
	var place: Dictionary = places[index]
	places.remove_at(index)
	changed.emit()
	return place


## The bag brought home last time (MetaState.bag_places): every place goes back onto its cells
## (or, if they are gone, onto the first free spot). Returns what did not fit at all.
func restore(list: Array) -> Array[Dictionary]:
	var left: Array[Dictionary] = []
	for entry: Variant in list:
		if not entry is Dictionary:
			continue
		var place: Dictionary = entry
		var id: String = String(place.get("id", ""))
		var count: int = int(place.get("count", 1))
		if put_place(place):
			continue
		if is_piece(place):
			if not add_piece(place) and is_known(place):
				var lost: Dictionary = place.duplicate()
				for key: String in ["x", "y", "rot"]:
					lost.erase(key)
				left.append(lost)
			continue
		var over: int = add(id, count)
		if over > 0:
			left.append({"id": id, "count": over})
	return left


## Everything out (bag and safe place).
func clear() -> void:
	places.clear()
	changed.emit()


## Death: everything outside the safe place is gone. Returns what stays.
func lose_unsafe() -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	for i in places.size():
		if is_safe(i):
			kept.append(places[i])
	places = kept
	changed.emit()
	return safe_contents()


func safe_contents() -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	for i in places.size():
		if is_safe(i):
			kept.append(places[i].duplicate())
	return kept


## Everything in the bag (bag and safe place), as a list of copies.
func contents() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for place: Dictionary in places:
		all.append(place.duplicate())
	return all


## Gold the merchant pays for all of it (data/loot.json "value").
func total_value() -> int:
	var total: int = 0
	for place: Dictionary in places:
		total += int(Content.material(String(place["id"])).get("value", 0)) * int(place["count"])
	return total
