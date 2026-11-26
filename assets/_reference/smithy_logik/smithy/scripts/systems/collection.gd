class_name Collection
extends RefCounted
## The collection book (tab "Sammelbuch" of the lexicon): every kind of weapon and armour × metal ×
## rarity the player has built, as a grid, e.g. "Schwerter: 34/56". A piece counts once it was
## finished (GameState.item_revealed: workbench, bow table, enchanting table, grindstone ...) in its
## head metal (Hero.get_gear_material: blade, plate; the handle or the leather lining don't count).
## Rows: the weapon types (weapon_types.json) and armour slots that can be made of a cast metal,
## each with the metals its recipes allow (get_rows, cached until ContentDB.reload).
## Rewards (economy.json "collection"): "milestones" by total percent (gold, a story flag that opens
## a piece of furniture, a random unknown mold) and "row_gold" for every complete row. Paid once
## each (claim_rewards; saved: `rewarded`, `rows_done`). The achievement "Sammelbuch" reads the
## percent (counter "collection", computed by GameState).

signal changed

## Parts that are the grip, not the head (as Hero.get_gear_material).
const GRIP_PARTS: Array = [ItemData.PartType.HANDLE, ItemData.PartType.SHAFT, ItemData.PartType.LEATHER]
## Stations whose finished pieces are collected.
const STATIONS: Array[StringName] = [&"workbench", &"bow_table", &"enchanting_table"]
const TIERS: int = 8
## Armour rows (no weapon type): item type -> [row key, heading].
const ARMOR_ROWS: Dictionary = {
	ItemData.ItemType.HELMET: ["helmet", "Helme"],
	ItemData.ItemType.SHOULDERS: ["shoulders", "Schulterstücke"],
	ItemData.ItemType.ARMOR: ["armor", "Brustpanzer"],
	ItemData.ItemType.GLOVES: ["gloves", "Handschuhe"],
	ItemData.ItemType.LEGS: ["legs", "Beinschutz"],
	ItemData.ItemType.BOOTS: ["boots", "Stiefel"],
	ItemData.ItemType.CLOAK: ["cloak", "Umhänge"],
	ItemData.ItemType.SHIELD: ["shield", "Schilde"],
}

## "row|metal|tier" -> true for every collected cell.
var pieces: Dictionary = {}
## Milestone percents already paid.
var rewarded: Array[int] = []
## Row keys whose complete-row gold was paid.
var rows_done: Array[String] = []

## Content cache (not game state): the rows, rebuilt after ContentDB.reload.
static var _rows: Array[Dictionary] = []
static var _cache_generation: int = -1


# --- Rows -------------------------------------------------------------------------------

## [{"key", "name", "item": ItemData (for the icon), "metals": Array[String]}] in the order of
## weapon_types.json, then the armour slots.
static func get_rows() -> Array[Dictionary]:
	if _cache_generation == ContentDB.generation and not _rows.is_empty():
		return _rows
	_cache_generation = ContentDB.generation
	_rows.clear()
	var metals_order: Array[String] = ContentDB.get_cast_metals()
	var found: Dictionary = {}
	for station: StringName in STATIONS:
		for recipe: RecipeData in ContentDB.get_station_recipes(station):
			var item: ItemData = recipe.result
			if item == null or not (item.is_weapon() or item.is_armor() or item.type == ItemData.ItemType.SHIELD):
				continue
			var key: String = get_row_key(item)
			if key.is_empty():
				continue
			if not found.has(key):
				found[key] = {"key": key, "name": _row_name(item), "item": item, "metals": []}
			var metals: Array = found[key]["metals"]
			for ingredient: Ingredient in recipe.ingredients:
				if ingredient.part_type == ItemData.PartType.NONE or GRIP_PARTS.has(ingredient.part_type):
					continue
				for candidate: ItemData in ingredient.get_candidates():
					if ingredient.matches(candidate) and metals_order.has(candidate.material_id) \
							and not metals.has(candidate.material_id):
						metals.append(candidate.material_id)
	var order: Array[String] = []
	for weapon_type: WeaponType in ContentDB.get_all_weapon_types():
		order.append(String(weapon_type.id))
	for entry: Array in ARMOR_ROWS.values():
		if not order.has(entry[0]):
			order.append(entry[0])
	for key: String in order:
		if found.has(key) and not (found[key]["metals"] as Array).is_empty():
			var row: Dictionary = found[key]
			(row["metals"] as Array).sort_custom(func(a: String, b: String) -> bool:
				return metals_order.find(a) < metals_order.find(b))
			_rows.append(row)
	return _rows


## Row of an item: its weapon type id ("sword"), or its armour slot ("helmet"); "" = none.
static func get_row_key(item: ItemData) -> String:
	if item.weapon_type != null:
		return String(item.weapon_type.id)
	return str(ARMOR_ROWS.get(item.type, [""])[0])


static func _row_name(item: ItemData) -> String:
	if item.weapon_type != null:
		return item.weapon_type.display_name
	return Language.translate(str(ARMOR_ROWS.get(item.type, ["", ""])[1]))


static func get_total_cells() -> int:
	var total: int = 0
	for row: Dictionary in get_rows():
		total += (row["metals"] as Array).size() * TIERS
	return total


# --- Collecting -------------------------------------------------------------------------

## Notes a finished piece. Returns true if it filled a new cell.
func note(slot: InventorySlot) -> bool:
	if slot == null or slot.is_empty() or slot.components.is_empty():
		return false
	var key: String = get_row_key(slot.item)
	var metal: String = Hero.get_gear_material(slot, true)
	var row: Dictionary = _find_row(key)
	if row.is_empty() or not (row["metals"] as Array).has(metal):
		return false
	var cell: String = "%s|%s|%d" % [key, metal, int(slot.rarity)]
	if pieces.has(cell):
		return false
	pieces[cell] = true
	changed.emit()
	return true


func has_piece(row_key: String, metal: String, tier: int) -> bool:
	return pieces.has("%s|%s|%d" % [row_key, metal, tier])


## Collected cells of a row.
func get_row_count(row: Dictionary) -> int:
	var count: int = 0
	for metal: String in row["metals"]:
		for tier in TIERS:
			if has_piece(row["key"], metal, tier):
				count += 1
	return count


func get_count() -> int:
	var count: int = 0
	for row: Dictionary in get_rows():
		count += get_row_count(row)
	return count


## Percent of all cells (rounded down, 100 only when every one is collected).
func get_percent() -> int:
	return floori(100.0 * get_count() / maxf(get_total_cells(), 1))


static func _find_row(key: String) -> Dictionary:
	for row: Dictionary in get_rows():
		if row["key"] == key:
			return row
	return {}


# --- Rewards ----------------------------------------------------------------------------

static func get_settings() -> Dictionary:
	return ContentDB.economy("collection")


## The next milestone not paid yet ({} = all paid).
func get_next_milestone() -> Dictionary:
	for milestone: Dictionary in get_settings().get("milestones", []):
		if not rewarded.has(int(milestone.get("percent", 0))):
			return milestone
	return {}


## "500 Gold, eine neue Gussform, Sammlervitrine" for a milestone.
static func describe_reward(milestone: Dictionary) -> String:
	var parts: Array[String] = []
	if int(milestone.get("gold", 0)) > 0:
		parts.append(Language.translate("%d Gold") % int(milestone["gold"]))
	if milestone.get("mold", false):
		parts.append(Language.translate("eine neue Gussform"))
	if not str(milestone.get("reward_name", "")).is_empty():
		parts.append(str(milestone["reward_name"]))
	return ", ".join(parts)


## Pays every milestone and complete row reached and not paid yet, through `state` (GameState:
## add_gold, story flags, unlock_mold). Returns the lines for the message.
func claim_rewards(state: Node) -> Array[String]:
	var lines: Array[String] = []
	var percent: int = get_percent()
	for milestone: Dictionary in get_settings().get("milestones", []):
		var at: int = int(milestone.get("percent", 0))
		if percent < at or rewarded.has(at):
			continue
		rewarded.append(at)
		var gold: int = int(milestone.get("gold", 0))
		if gold > 0:
			state.add_gold(gold)
		if not str(milestone.get("flag", "")).is_empty():
			state.story.set_flag(str(milestone["flag"]))
		if milestone.get("mold", false):
			_unlock_random_mold(state)
		lines.append(Language.translate("Sammelbuch %d %%: %s") % [at, describe_reward(milestone)])
	var row_gold: int = int(get_settings().get("row_gold", 0))
	for row: Dictionary in get_rows():
		if rows_done.has(row["key"]) or get_row_count(row) < (row["metals"] as Array).size() * TIERS:
			continue
		rows_done.append(row["key"])
		if row_gold > 0:
			state.add_gold(row_gold)
		lines.append(Language.translate("Sammelbuch: %s komplett! %d Gold") % [row["name"], row_gold])
	if not lines.is_empty():
		changed.emit()
	return lines


## A random mold the player does not know yet, of a metal the story has reached (none left: nothing).
static func _unlock_random_mold(state: Node) -> void:
	var unknown: Array[RecipeData] = []
	for metal: String in ContentDB.get_cast_metals():
		if state.is_metal_unlocked(metal):
			unknown.append_array(state.get_unknown_molds(metal))
	if not unknown.is_empty():
		state.unlock_mold(unknown.pick_random())


# --- Saving -----------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"pieces": pieces.keys(), "rewarded": rewarded.duplicate(), "rows_done": rows_done.duplicate()}


func load_save_data(data: Dictionary) -> void:
	pieces.clear()
	for cell: Variant in data.get("pieces", []):
		pieces[str(cell)] = true
	rewarded.clear()
	for at: Variant in data.get("rewarded", []):
		rewarded.append(int(at))
	rows_done.clear()
	for key: Variant in data.get("rows_done", []):
		rows_done.append(str(key))
	changed.emit()
