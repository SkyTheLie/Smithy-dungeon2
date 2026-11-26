class_name House
extends RefCounted
## The player's house (the smithy) and its 5 upgrade levels (house.json "levels"): bigger smithy,
## display tables in the workshop, a shop annex and a bigger shop. The scenes ask `level` and show
## the matching building, room and tables (HouseLevelSwitch, HouseShopRoom).
## The own shop (`shop`) works like Nina's (ConsignmentShop) but with house.json "shop" numbers
## (no commission); its money waits in the cash box until the player takes it.
## Furniture is bought at the furniture trader (`owned`: id -> pieces not placed yet) and placed
## freely in the shop (`placed`); every placed piece raises the sale prices by its "bonus".
## Plant pots (house.json "planter") get a "uid" in `placed`: their soil and plants live under it
## in GameState.garden, also when the pot is moved. A pot with plants can't go into storage; its
## soil comes back into the inventory when it does.
## Storage boxes (house.json "storage" = slots, bought by reputation rank) get a "uid" too: their
## contents live in `boxes` under it, a box sign (item chest_sign) in `box_signs` (uid -> name).
## A box with something inside can't go into storage; its sign comes back into the inventory.
## Jewel case (house.json furniture with "jewel_slots", from house level 4): while one stands in the
## shop annex, the shop's jewel places are in use (rings and amulets, ConsignmentShop.JEWELRY). Only one
## can be bought ("max_owned"); taken into storage, what lies on it waits there until it stands again.
## Room designer (house.json "room_styles"): floors, walls and doors are bought once
## (`owned_styles`) and set per room (`room_design`, room key -> {kind -> style id}); RoomStyleLayer
## draws them over the room's picture. Styles in the shop raise its prices like furniture.
## Workshop upgrades (house.json "workshop_upgrades"): levels of anvil, smelter and forge bought at
## the builder (`workshop_levels`); get_upgrade_value() adds up their effects.
## Hall of fame (house.json "hall_of_fame"): built by the builder (story flag HALL_FLAG); every
## trophy standing in it brings reputation each morning (hall_morning).
## Lives in GameState.house and saves itself.

## Level, furniture or placements changed.
signal changed
## A box sign was put on, taken off or renamed (not `changed`: that rebuilds the furniture).
signal box_sign_changed(uid: String)

const MAX_LEVEL: int = 5
## Display places of `shop`: on level 3 the two workshop tables (0, 1); from level 4 the tables of the
## shop (0 ..), the workshop tables are gone and what lay on them is on the first shop tables.

## Room key of furniture in the shop (only there it raises the prices). Other rooms: the
## HouseEditor's room ("smithy_small", "smithy_big", "bedroom").
const SHOP_ROOM: String = "shop"
## Rooms that only exist at some house levels [from, to]: their furniture goes back into storage
## when the house leaves that range (the small workshop is gone after the first upgrade).
const ROOM_LEVELS: Dictionary = {"smithy_small": [1, 1], "smithy_big": [2, 5]}
## Room key of the greenhouse (plant pots stand there).
const GREENHOUSE_ROOM: String = "greenhouse"
## Room key of the hall of fame and the story flag once it is built.
const HALL_ROOM: String = "hall"
const HALL_FLAG: String = "hall_of_fame_built"
## Why the builder takes no new job while one is not done yet (get_builder_job).
const BUSY_TEXT: String = "Eins nach dem anderen! Erst mache ich fertig, was ich gerade baue. Morgen früh hab ich wieder Zeit."
## What the room designer can change (house.json "room_styles" "kind").
const STYLE_KINDS: Array[String] = ["floor", "wall", "door"]
const STYLE_KIND_NAMES: Dictionary = {"floor": "Boden", "wall": "Wand", "door": "Tür"}

## Current upgrade level (1 = small smithy).
var level: int = 1
## A bought level is being built: the next morning `level` goes up, until then the yard shows the
## building site (house_build_site.gd) and the house stays usable.
var upgrading: bool = false
## The own shop: all tables of all levels (only the ones of the current level are in use).
var shop: ConsignmentShop
## Furniture in storage: id -> pieces (bought, not placed).
var owned: Dictionary = {}
## Furniture standing in the rooms: [{"id", "x", "y", "room"}, plant pots also "uid", turned pieces
## also "facing" (Facing direction, missing = south)].
var placed: Array[Dictionary] = []
## Number of the next plant pot (its uid "pot_<n>").
var next_planter: int = 1
## Storage boxes: uid ("box_<n>") -> Inventory with the box's slots.
var boxes: Dictionary = {}
## Box signs: uid -> name on the sign ("" = no name yet). Boxes without a sign are missing.
var box_signs: Dictionary = {}
## Number of the next storage box (its uid "box_<n>").
var next_box: int = 1
## Stations, tables and decoration the player moved or turned (HouseEditor): room key -> {node path
## -> [x, y, facing]} (older saves: [x, y]).
var moved: Dictionary = {}
## Bought stations the player put into storage (economy.json "stations" ids, Station.get_store_id).
var stored_stations: Array[String] = []
## Decoration of a room the player put into storage (house.json "decorations"): room key -> [node
## path relative to the room's HouseEditor].
var stored_decor: Dictionary = {}
## Room designer: bought styles and what each room uses (room key -> {kind -> style id}).
var owned_styles: Array[String] = []
var room_design: Dictionary = {}
## Workshop upgrades: station id ("anvil", "smelter", "forge") -> levels bought.
var workshop_levels: Dictionary = {}


func _init() -> void:
	var max_tables: int = 0
	for data: Dictionary in get_levels():
		max_tables = maxi(max_tables, int(data.get("smithy_displays", 0)) + int(data.get("shop_displays", 0)))
	var numbers: Dictionary = {}
	var settings: Dictionary = ContentDB.house("shop")
	for key: String in settings:
		if settings[key] is float or settings[key] is int:
			numbers[key] = settings[key]
	shop = ConsignmentShop.new(max_tables, numbers)
	# The armor stand: one place per armor type after all tables.
	shop.add_dummy_slots()
	# The jewel case: its places after the armor stand.
	shop.add_jewel_slots(get_jewel_slot_count())
	_apply_level()


static func get_levels() -> Array:
	return ContentDB.house("levels")


## Entry of house.json "levels" for a level 1..MAX_LEVEL.
static func get_level_data(for_level: int) -> Dictionary:
	var levels: Array = get_levels()
	return levels[for_level - 1] if for_level >= 1 and for_level <= levels.size() else {}


static func get_furniture(id: String) -> Dictionary:
	return ContentDB.house("furniture").get(id, {})


## Fields per side of a plant pot (house.json "planter"), 0 = not a pot.
static func get_planter_size(id: String) -> int:
	return int(get_furniture(id).get("planter", 0))


## Slots of a storage box (house.json "storage"), 0 = not a box.
static func get_storage_size(id: String) -> int:
	return int(get_furniture(id).get("storage", 0))


## The piece may stand in `room` (house.json "rooms"; without = everywhere).
static func can_stand_in(id: String, room: String) -> bool:
	var rooms: Array = get_furniture(id).get("rooms", [])
	return rooms.is_empty() or rooms.has(room)


func get_level_name() -> String:
	return str(get_level_data(level).get("name", Language.translate("Stufe %d") % level))


## Display tables in the workshop at the current level.
func get_smithy_tables() -> int:
	return int(get_level_data(level).get("smithy_displays", 0))


## Display tables in the shop annex at the current level.
func get_shop_tables() -> int:
	return int(get_level_data(level).get("shop_displays", 0))


## true once the house has the armor stand for selling armor (house.json level "armor_stand").
func has_armor_stand() -> bool:
	return bool(get_level_data(level).get("armor_stand", false))


## Places of the jewel case (the largest house.json "jewel_slots" of all furniture).
static func get_jewel_slot_count() -> int:
	var count: int = 0
	var furniture: Dictionary = ContentDB.house("furniture")
	for id: String in furniture:
		count = maxi(count, int(furniture[id].get("jewel_slots", 0)))
	return count


## true while a jewel case stands in the shop annex (from house level 4).
func has_jewel_display() -> bool:
	if not has_shop():
		return false
	return placed.any(func(entry: Dictionary) -> bool:
			return entry.get("room", SHOP_ROOM) == SHOP_ROOM and int(get_furniture(str(entry["id"])).get("jewel_slots", 0)) > 0)


## Pieces of furniture `id` the player has, in storage and standing (house.json "max_owned").
func count_owned_total(id: String) -> int:
	return get_owned(id) + placed.filter(func(entry: Dictionary) -> bool: return entry["id"] == id).size()


## true once a piece with "max_owned" can't be bought any more.
func is_furniture_maxed(id: String) -> bool:
	var most: int = int(get_furniture(id).get("max_owned", 0))
	return most > 0 and count_owned_total(id) >= most


## true once the shop annex exists (level 4+).
func has_shop() -> bool:
	return get_shop_tables() > 0


## Price of the next level, -1 = already the highest.
func get_next_price() -> int:
	if level >= MAX_LEVEL:
		return -1
	return int(get_level_data(level + 1).get("price", 0))


## Buys the next level with the player's gold. false = not enough gold, nothing left or the
## builder is still busy with another job.
func buy_next_level() -> bool:
	var price: int = get_next_price()
	if price < 0 or is_builder_busy() or not GameState.spend_gold(price):
		return false
	start_upgrade()
	return true


## The builder starts: the new level stands the next morning (finish_upgrade).
func start_upgrade() -> void:
	upgrading = true
	changed.emit()


func is_upgrading() -> bool:
	return upgrading


## New morning: the bought level is done. Returns whether something was finished.
func finish_upgrade() -> bool:
	if not upgrading:
		return false
	set_level(level + 1)
	return true


## What the builder is still building (house.json "builder_jobs"): "house" while a bought level
## is being built, otherwise the first job whose "ordered_flag" is set but not yet its
## "done_flag" (hall of fame, greenhouse). "" = he is free. He takes one job at a time.
func get_builder_job() -> String:
	if upgrading:
		return "house"
	var jobs: Dictionary = ContentDB.house("builder_jobs")
	for job: String in jobs:
		var ordered: String = str(jobs[job].get("ordered_flag", ""))
		if not ordered.is_empty() and GameState.story.has_flag(ordered) 				and not GameState.story.has_flag(str(jobs[job].get("done_flag", ""))):
			return job
	return ""


func is_builder_busy() -> bool:
	return not get_builder_job().is_empty()


## Sets the level directly (test switch at the builder). Things on tables that do not exist on
## the new level stay on them and come back when the level does.
func set_level(new_level: int) -> void:
	level = clampi(new_level, 1, MAX_LEVEL)
	upgrading = false
	_store_furniture_of_missing_rooms()
	_apply_level()
	changed.emit()


func _store_furniture_of_missing_rooms() -> void:
	for index in range(placed.size() - 1, -1, -1):
		var range_of_room: Array = ROOM_LEVELS.get(placed[index].get("room", SHOP_ROOM), [1, MAX_LEVEL])
		if level < int(range_of_room[0]) or level > int(range_of_room[1]):
			# What lay in a box goes into the loot chest, nothing is lost.
			var box: Inventory = get_box(str(placed[index].get("uid", "")))
			if box:
				for slot in box.slots:
					if not slot.is_empty():
						GameState.put_stack_into_reward_chest(slot)
						slot.clear()
			release_piece(str(placed[index].get("uid", "")))
			add_owned(placed[index]["id"])
			placed.remove_at(index)


func _apply_level() -> void:
	shop.active_slots = get_smithy_tables() + get_shop_tables()
	shop.dummy_active = has_armor_stand()
	shop.jewel_active = has_jewel_display()
	shop.price_bonus = get_price_bonus()
	shop.changed.emit()


# --- Furniture ----------------------------------------------------------------------

## Sum of the bonuses of all placed pieces, at most house.json "shop.max_furniture_bonus".
## Without a shop the furniture is not on show (no bonus).
func get_price_bonus() -> float:
	if not has_shop():
		return 0.0
	var bonus: float = 0.0
	for entry in placed:
		if entry.get("room", SHOP_ROOM) == SHOP_ROOM:
			bonus += float(get_furniture(entry["id"]).get("bonus", 0.0))
	for kind: String in STYLE_KINDS:
		bonus += float(get_style(get_room_style(SHOP_ROOM, kind)).get("bonus", 0.0))
	return minf(bonus, float(ContentDB.house("shop").get("max_furniture_bonus", 0.5)))


func get_owned(id: String) -> int:
	return int(owned.get(id, 0))


func add_owned(id: String, amount: int = 1) -> void:
	owned[id] = get_owned(id) + amount
	changed.emit()


## Pieces standing in a room.
func count_placed(room: String) -> int:
	return placed.filter(func(entry: Dictionary) -> bool: return entry.get("room", SHOP_ROOM) == room).size()


## Places a piece from storage at `position` in `room`, turned to `facing`. false = none in
## storage. A plant pot or storage box keeps `uid` (when it was moved) or gets a new one.
func place_furniture(id: String, position: Vector2, room: String = SHOP_ROOM, uid: String = "",
		facing: int = Facing.SOUTH) -> bool:
	if get_owned(id) <= 0:
		return false
	owned[id] = get_owned(id) - 1
	if owned[id] <= 0:
		owned.erase(id)
	var entry: Dictionary = {"id": id, "x": roundi(position.x), "y": roundi(position.y), "room": room}
	if facing != Facing.SOUTH:
		entry["facing"] = facing
	if get_planter_size(id) > 0:
		if uid.is_empty():
			uid = "pot_%d" % next_planter
			next_planter += 1
		entry["uid"] = uid
	elif get_storage_size(id) > 0:
		if uid.is_empty():
			uid = "box_%d" % next_box
			next_box += 1
		entry["uid"] = uid
		if not boxes.has(uid):
			boxes[uid] = Inventory.new(get_storage_size(id))
	placed.append(entry)
	_apply_level()
	changed.emit()
	return true


## Why the placed piece number `index` can't go into storage ("" = it can).
func get_store_blocker(index: int) -> String:
	if index < 0 or index >= placed.size():
		return ""
	return get_piece_blocker(str(placed[index].get("uid", "")))


## Why the plant pot or box with this uid can't go into storage ("" = it can).
func get_piece_blocker(uid: String) -> String:
	if GameState.garden.has_plants(uid):
		return Language.translate("Im Topf wächst noch etwas. Erst ernten, dann einlagern.")
	var box: Inventory = get_box(uid)
	if box and box.slots.any(func(slot: InventorySlot) -> bool: return not slot.is_empty()):
		return Language.translate("In der Kiste liegt noch etwas. Erst ausräumen, dann einlagern.")
	return ""


## Puts the placed piece number `index` back into storage (false = it can't, see
## get_store_blocker). The soil of a plant pot goes back into the inventory, so does a box sign.
func pick_up_furniture(index: int) -> bool:
	if index < 0 or index >= placed.size() or not get_store_blocker(index).is_empty():
		return false
	release_piece(str(placed[index].get("uid", "")))
	add_owned(placed[index]["id"])
	placed.remove_at(index)
	_apply_level()
	changed.emit()
	return true


## Takes the placed piece number `index` up to move it (it counts as in storage until it is placed
## again with its uid); returns its entry ({} = none). A plant pot keeps its soil and plants.
func lift_furniture(index: int) -> Dictionary:
	if index < 0 or index >= placed.size():
		return {}
	var entry: Dictionary = placed[index]
	add_owned(entry["id"])
	placed.remove_at(index)
	_apply_level()
	changed.emit()
	return entry


## A plant pot or storage box goes into storage (see get_piece_blocker first).
func release_piece(uid: String) -> void:
	release_planter(uid)
	release_box(uid)


## A plant pot goes into storage: its soil comes back into the inventory (plants must be gone).
func release_planter(uid: String) -> void:
	if uid.is_empty():
		return
	var soil: ItemData = GameState.garden.clear_pot(uid)
	if soil:
		GameState.give_items(String(soil.id))


# --- Storage boxes --------------------------------------------------------------------

## Item id of the box sign.
const SIGN_ITEM: String = "chest_sign"
## Longest name on a box sign.
const SIGN_MAX_LENGTH: int = 16


## Contents of the box with this uid (null = no such box).
func get_box(uid: String) -> Inventory:
	return boxes.get(uid) if not uid.is_empty() else null


## The contents of every box (the stations take ingredients and fuel from them too).
func get_all_boxes() -> Array[Inventory]:
	var all: Array[Inventory] = []
	for uid: String in boxes:
		all.append(boxes[uid])
	return all


## An empty box goes into storage: its contents are gone (must be empty), the sign comes back.
func release_box(uid: String) -> void:
	if not boxes.has(uid):
		return
	boxes.erase(uid)
	if box_signs.has(uid):
		box_signs.erase(uid)
		GameState.give_items(SIGN_ITEM)


func has_sign(uid: String) -> bool:
	return box_signs.has(uid)


func get_sign_name(uid: String) -> String:
	return str(box_signs.get(uid, ""))


## Puts a box sign from the inventory on the box. false = no sign in the inventory (or already one).
func attach_sign(uid: String) -> bool:
	if not boxes.has(uid) or has_sign(uid) or not GameState.inventory.remove_item(ContentDB.item(SIGN_ITEM), 1):
		return false
	box_signs[uid] = ""
	box_sign_changed.emit(uid)
	return true


## Takes the sign off again, it goes back into the inventory.
func remove_sign(uid: String) -> void:
	if not has_sign(uid):
		return
	box_signs.erase(uid)
	GameState.give_items(SIGN_ITEM)
	box_sign_changed.emit(uid)


func set_sign_name(uid: String, sign_name: String) -> void:
	if not has_sign(uid):
		return
	box_signs[uid] = sign_name.strip_edges().left(SIGN_MAX_LENGTH).strip_edges()
	box_sign_changed.emit(uid)


## What the sign shows: a stack of the item with the most pieces in the box (null = empty).
func get_box_main_stack(uid: String) -> InventorySlot:
	var box: Inventory = get_box(uid)
	if box == null:
		return null
	var counts: Dictionary = {}
	var best: InventorySlot = null
	for slot in box.slots:
		if slot.is_empty():
			continue
		counts[slot.item] = int(counts.get(slot.item, 0)) + slot.amount
		if best == null or counts[slot.item] > counts[best.item]:
			best = slot
	return best


# --- Room designer ------------------------------------------------------------------

static func get_style(id: String) -> Dictionary:
	return ContentDB.house("room_styles").get(id, {})


## Style ids of one kind ("floor", "wall", "door"), cheapest first.
static func get_styles(kind: String) -> Array[String]:
	var ids: Array[String] = []
	var styles: Dictionary = ContentDB.house("room_styles")
	for id: String in styles:
		if str(styles[id].get("kind", "")) == kind:
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool: return int(styles[a].get("price", 0)) < int(styles[b].get("price", 0)))
	return ids


## The style can be bought already (its "unlock_flag" is set).
static func is_style_unlocked(id: String) -> bool:
	var flag: String = str(get_style(id).get("unlock_flag", ""))
	return flag.is_empty() or GameState.story.has_flag(flag)


func owns_style(id: String) -> bool:
	return owned_styles.has(id)


## A style that can't be bought, only won (house.json "tournament_only": forge themes of the
## league tournaments).
static func is_tournament_style(id: String) -> bool:
	return bool(get_style(id).get("tournament_only", false))


## Why the style can't be bought now ("" = it can).
func get_style_blocker(id: String) -> String:
	var style: Dictionary = get_style(id)
	if style.is_empty():
		return Language.translate("Diesen Stil gibt es nicht.")
	if owns_style(id):
		return Language.translate("Schon gekauft.")
	if is_tournament_style(id):
		return Language.translate("Gibt es nur als Preis der Liga-Turniere.")
	if not is_style_unlocked(id):
		return Language.translate("Gibt es erst, wenn du weiter herumgekommen bist.")
	if GameState.gold < int(style.get("price", 0)):
		return Language.translate("Dafür fehlen dir %d Gold.") % (int(style.get("price", 0)) - GameState.gold)
	return ""


# --- Forge themes (sets of styles, prizes of the league tournaments) ------------------------

## Style ids of a theme (house.json room_styles with this "set").
static func get_theme_styles(theme: String) -> Array[String]:
	var ids: Array[String] = []
	var styles: Dictionary = ContentDB.house("room_styles")
	for id: String in styles:
		if str(styles[id].get("set", "")) == theme:
			ids.append(id)
	return ids


## Shown name of a theme (house.json "theme_name", already translated by ContentDB).
static func get_theme_name(theme: String) -> String:
	for id: String in get_theme_styles(theme):
		return str(get_style(id).get("theme_name", theme))
	return theme


## true once every style of the theme is owned (an unknown theme counts as owned: nothing to win).
func owns_theme(theme: String) -> bool:
	return get_theme_styles(theme).all(owns_style)


## Gives every style of a theme (a tournament prize, no gold). false = unknown or owned already.
func grant_theme(theme: String) -> bool:
	var granted: bool = false
	for id: String in get_theme_styles(theme):
		if not owns_style(id):
			owned_styles.append(id)
			granted = true
	if granted:
		changed.emit()
	return granted


func buy_style(id: String) -> bool:
	if not get_style_blocker(id).is_empty() or not GameState.spend_gold(int(get_style(id).get("price", 0))):
		return false
	owned_styles.append(id)
	changed.emit()
	return true


## Style of `kind` in `room` ("" = the room's own picture).
func get_room_style(room: String, kind: String) -> String:
	return str(room_design.get(room, {}).get(kind, ""))


## Sets a bought style in a room ("" = back to the room's own picture). false = not owned.
func set_room_style(room: String, kind: String, id: String) -> bool:
	if not id.is_empty() and (not owns_style(id) or str(get_style(id).get("kind", "")) != kind):
		return false
	if not room_design.has(room):
		room_design[room] = {}
	if id.is_empty():
		room_design[room].erase(kind)
	else:
		room_design[room][kind] = id
	changed.emit()
	return true


# --- Workshop upgrades -----------------------------------------------------------------

static func get_upgrade_stations() -> Array:
	return ContentDB.house("workshop_upgrades").keys()


static func get_upgrade_data(station: String) -> Dictionary:
	return ContentDB.house("workshop_upgrades").get(station, {})


func get_workshop_level(station: String) -> int:
	return int(workshop_levels.get(station, 0))


## The next level of a station ({} = all bought).
func get_next_upgrade(station: String) -> Dictionary:
	var levels: Array = get_upgrade_data(station).get("levels", [])
	var bought: int = get_workshop_level(station)
	return levels[bought] if bought < levels.size() else {}


## Why the next level of a station can't be bought ("" = it can).
func get_upgrade_blocker(station: String) -> String:
	var next: Dictionary = get_next_upgrade(station)
	if next.is_empty():
		return Language.translate("Mehr geht nicht.")
	if is_builder_busy():
		return Language.translate(BUSY_TEXT)
	var flag: String = str(next.get("unlock_flag", ""))
	if not flag.is_empty() and not GameState.story.has_flag(flag):
		return Language.translate("Dafür fehlt mir noch das Wissen. Komm wieder, wenn du mehr erlebt hast.")
	if GameState.gold < int(next.get("price", 0)):
		return Language.translate("Dir fehlen noch %d Gold.") % (int(next.get("price", 0)) - GameState.gold)
	if not GameState.has_items(str(next.get("items", ""))):
		return Language.translate("Dir fehlt Material.")
	return ""


## Buys the next level of a station: gold and material. false = not possible.
func buy_upgrade(station: String) -> bool:
	if not get_upgrade_blocker(station).is_empty():
		return false
	var next: Dictionary = get_next_upgrade(station)
	if not GameState.spend_gold(int(next.get("price", 0))):
		return false
	GameState.take_items(str(next.get("items", "")))
	workshop_levels[station] = get_workshop_level(station) + 1
	changed.emit()
	return true


## Sum of an effect ("forge_quality", "smelt_speed", "heat_bonus") over all bought levels.
func get_upgrade_value(key: String) -> float:
	var total: float = 0.0
	for station: String in get_upgrade_stations():
		var levels: Array = get_upgrade_data(station).get("levels", [])
		for i in mini(get_workshop_level(station), levels.size()):
			total += float(levels[i].get(key, 0.0))
	return total


# --- Hall of fame ----------------------------------------------------------------------

static func get_hall_data() -> Dictionary:
	return ContentDB.house("hall_of_fame")


func is_hall_built() -> bool:
	return GameState.story.has_flag(HALL_FLAG)


## Trophies (furniture "trophy_*") standing in the hall.
func count_hall_trophies() -> int:
	return placed.filter(func(entry: Dictionary) -> bool:
			return entry.get("room", "") == HALL_ROOM and str(entry.get("id", "")).begins_with("trophy_")).size()


## Reputation the hall brings this morning (house.json "hall_of_fame").
func get_hall_reputation() -> int:
	if not is_hall_built():
		return 0
	var data: Dictionary = get_hall_data()
	return mini(count_hall_trophies(), int(data.get("max_trophies_counted", 14))) * int(data.get("reputation_per_trophy", 2))


# --- Saving -------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"level": level, "upgrading": upgrading, "shop": shop.to_save_data(), "owned": owned.duplicate(), "placed": placed.duplicate(true),
			"next_planter": next_planter, "boxes": _boxes_to_save_data(), "box_signs": box_signs.duplicate(), "next_box": next_box,
			"moved": moved.duplicate(true), "stored_stations": stored_stations.duplicate(),
			"stored_decor": stored_decor.duplicate(true), "owned_styles": owned_styles.duplicate(),
			"room_design": room_design.duplicate(true), "workshop_levels": workshop_levels.duplicate()}


func load_save_data(data: Dictionary) -> void:
	level = clampi(int(data.get("level", 1)), 1, MAX_LEVEL)
	upgrading = bool(data.get("upgrading", false))
	shop.load_save_data(data.get("shop", {}))
	owned.clear()
	var saved_owned: Dictionary = data.get("owned", {})
	for id: String in saved_owned:
		if not get_furniture(id).is_empty():
			owned[id] = int(saved_owned[id])
	placed.clear()
	for entry: Dictionary in data.get("placed", []):
		if not get_furniture(str(entry.get("id", ""))).is_empty():
			var loaded: Dictionary = {"id": str(entry["id"]), "x": int(entry.get("x", 0)), "y": int(entry.get("y", 0)),
					"room": str(entry.get("room", SHOP_ROOM))}
			if entry.has("uid"):
				loaded["uid"] = str(entry["uid"])
			if int(entry.get("facing", Facing.SOUTH)) != Facing.SOUTH:
				loaded["facing"] = clampi(int(entry["facing"]), Facing.SOUTH, Facing.WEST)
			placed.append(loaded)
	next_planter = int(data.get("next_planter", 1))
	_load_boxes(data.get("boxes", {}))
	box_signs.clear()
	var saved_signs: Dictionary = data.get("box_signs", {})
	for uid: String in saved_signs:
		if boxes.has(uid):
			box_signs[uid] = str(saved_signs[uid]).left(SIGN_MAX_LENGTH)
	next_box = int(data.get("next_box", 1))
	moved =data.get("moved", {}).duplicate(true)
	stored_stations.clear()
	for id: String in data.get("stored_stations", []):
		if not Economy.get_station_offer(id).is_empty() and not stored_stations.has(id):
			stored_stations.append(id)
	stored_decor = data.get("stored_decor", {}).duplicate(true)
	owned_styles.clear()
	for id: String in data.get("owned_styles", []):
		if not get_style(id).is_empty() and not owned_styles.has(id):
			owned_styles.append(id)
	room_design.clear()
	var saved_design: Dictionary = data.get("room_design", {})
	for room: String in saved_design:
		room_design[room] = {}
		for kind: String in saved_design[room]:
			if owned_styles.has(str(saved_design[room][kind])):
				room_design[room][kind] = str(saved_design[room][kind])
	workshop_levels.clear()
	var saved_levels: Dictionary = data.get("workshop_levels", {})
	for station: String in saved_levels:
		if not get_upgrade_data(station).is_empty():
			workshop_levels[station] = clampi(int(saved_levels[station]), 0, (get_upgrade_data(station).get("levels", []) as Array).size())
	_apply_level()
	changed.emit()


func _boxes_to_save_data() -> Dictionary:
	var data: Dictionary = {}
	for uid: String in boxes:
		data[uid] = (boxes[uid] as Inventory).to_save_data()
	return data


## Every placed box gets its slots (house.json "storage"), filled from the save. A saved box that
## is no longer placed keeps its contents too (saved while it was carried).
func _load_boxes(saved: Dictionary) -> void:
	boxes.clear()
	for entry: Dictionary in placed:
		var size: int = get_storage_size(str(entry["id"]))
		if size > 0 and entry.has("uid"):
			boxes[entry["uid"]] = Inventory.new(size)
	for uid: String in saved:
		if not boxes.has(uid):
			boxes[uid] = Inventory.new(0)
		(boxes[uid] as Inventory).load_save_data(saved[uid])


# --- Moved stations and decoration ----------------------------------------------------

## Saved position of a node the player moved, Vector2.INF = never moved.
func get_moved(room: String, path: String) -> Vector2:
	var saved: Array = moved.get(room, {}).get(path, [])
	return Vector2(saved[0], saved[1]) if saved.size() >= 2 else Vector2.INF


## Saved direction of a node the player turned (Facing, SOUTH = never turned).
func get_moved_facing(room: String, path: String) -> int:
	var saved: Array = moved.get(room, {}).get(path, [])
	return int(saved[2]) if saved.size() >= 3 else Facing.SOUTH


func is_station_stored(id: String) -> bool:
	return not id.is_empty() and stored_stations.has(id)


## Puts a bought station into storage (true) or takes it out again (false).
func set_station_stored(id: String, stored: bool) -> void:
	if id.is_empty() or stored == is_station_stored(id):
		return
	if stored:
		stored_stations.append(id)
	else:
		stored_stations.erase(id)
	changed.emit()


## Name and icon of a decoration (house.json "decorations", by node name), {} = can't be stored.
static func get_decoration(node_name: String) -> Dictionary:
	return ContentDB.house("decorations").get(node_name, {})


func is_decor_stored(room: String, path: String) -> bool:
	return stored_decor.get(room, []).has(path)


## Decoration paths of a room that are in storage.
func get_stored_decor(room: String) -> Array:
	return stored_decor.get(room, [])


## Puts a decoration of `room` into storage (true) or takes it out again (false).
func set_decor_stored(room: String, path: String, stored: bool) -> void:
	if stored == is_decor_stored(room, path):
		return
	if stored:
		if not stored_decor.has(room):
			stored_decor[room] = []
		stored_decor[room].append(path)
	else:
		stored_decor[room].erase(path)
	changed.emit()


func set_moved(room: String, path: String, position: Vector2, facing: int = Facing.SOUTH) -> void:
	if not moved.has(room):
		moved[room] = {}
	moved[room][path] = [roundi(position.x), roundi(position.y), facing]
