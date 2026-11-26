class_name ConsignmentShop
extends RefCounted
## Nina's shop at the market: the player puts things on display (weapons; after the expansion
## also armor on a dummy, see `slot_types`), they are sold at random while the shop is open and the money waits with Nina (pending_gold) until the
## player picks it up. Whatever is still waiting in the morning goes into the loot chest.
## Lives in GameState.nina_shop and is ticked there. Numbers: economy.json "shop" (docs/CONTENT.md).
## The player's own shop (House.shop) is the same with other numbers (`overrides`, house.json
## "shop": no commission), a price bonus from the furniture and only `active_slots` in use.
## Nina's expansion (story, economy.json "shop.expansion"): more weapon places, an armor dummy
## with one place per armor type, and at least `min_sales_per_day` sales per day.
##
##   price  = value (material cost) × price_factor
##            × (1 + rarity_bonus_per_step × tiers above R1)
##            × (1 + reputation bonus: rank "shop_bonus", see Reputation)
##            × (1 + price_bonus + skill "Verkaufstalent")
##   (a ring or amulet: its crystal counts with economy.json "jewelry.shop_crystal_factor"
##    instead of price_factor, see Economy)
##   payout = price × (1 - commission)

## slot_types entry of the places of the jewel case.
const JEWELRY: String = "jewelry"

## Display slots, sold items or the pending gold changed.
signal changed
## Something was sold; `payout` = what the player gets (after Nina's commission).
signal item_sold(stack: InventorySlot, payout: int)

## What is on display (empty slots = free places).
var slots: Array[InventorySlot] = []
## Money from sales that the player has not picked up yet.
var pending_gold: int = 0
## How many things were sold so far (the story waits for it).
var sold_count: int = 0
## Pieces sold so far per item id, e.g. {"sword": 2} (story.json "shop_goal").
var sold_items: Dictionary = {}
## Sum of all sale prices so far (Nina gives a calendar at economy.json "shop.calendar_gift_sales").
var total_sales: int = 0
## Extra factor on the sale price (own shop: furniture), 0.1 = +10 %.
var price_bonus: float = 0.0
## Display slots that are in use (the rest exists but shows nothing and sells nothing).
var active_slots: int = 0
## What each display place takes: "" = a weapon, JEWELRY = a ring or amulet (jewel case of the own
## shop), else an item type (e.g. "helmet", dummy places).
var slot_types: Array[String] = []
## Nina's shop is expanded (expand()): all places in use, at least `min_sales_per_day` sales.
var expanded: bool = false
## The dummy places are in use even when they lie beyond `active_slots` (own shop: armor stand
## from house level 3, House._apply_level).
var dummy_active: bool = false
## The jewel places are in use (own shop: a jewel case stands in the house, House._apply_level).
var jewel_active: bool = false
## Values that differ from economy.json "shop" (key -> number), e.g. {"commission": 0.0}.
var _overrides: Dictionary = {}
## Day of `_sold_today` (for the minimum of sales per day).
var _sales_day: int = -1
var _sold_today: int = 0
## Last full hour (day × 24 + hour) the sales were rolled for.
var _last_hour_key: int = -1
## See take_overflow.
var _overflow: Array[InventorySlot] = []


## `slot_count` < 0: economy.json "shop.slots" (Nina's shop).
func _init(slot_count: int = -1, overrides: Dictionary = {}) -> void:
	_overrides = overrides
	if slot_count < 0:
		slot_count = int(setting("slots", 4))
	for i in slot_count:
		slots.append(InventorySlot.new())
		slot_types.append("")
	active_slots = slot_count


## Nina's shop: adds the places of the expansion (economy.json "shop.expansion": "weapon_slots",
## "dummy" = item types of the dummy). They stay unused until expand().
func add_expansion_slots() -> void:
	var expansion: Dictionary = ContentDB.economy("shop").get("expansion", {})
	while slots.size() < int(expansion.get("weapon_slots", slots.size())):
		slots.append(InventorySlot.new())
		slot_types.append("")
	add_dummy_slots()


## Adds one place per armor type of the dummy (economy.json "shop.expansion.dummy") at the end.
func add_dummy_slots() -> void:
	for type_key: String in ContentDB.economy("shop").get("expansion", {}).get("dummy", []):
		slots.append(InventorySlot.new())
		slot_types.append(type_key)


## Adds `count` places for rings and amulets (the jewel case of the own shop) at the end.
func add_jewel_slots(count: int) -> void:
	for i in count:
		slots.append(InventorySlot.new())
		slot_types.append(JEWELRY)


## Name of a dummy place's item type (economy.json "shop.expansion.dummy"), e.g. "Helm".
static func get_dummy_name(type_key: String) -> String:
	return str(ContentDB.economy("shop").get("expansion", {}).get("dummy", {}).get(type_key, type_key))


## Story: Nina expanded her shop, every place is in use.
func expand() -> void:
	expanded = true
	active_slots = slots.size()
	changed.emit()


## Places that take weapons / the dummy places (indexes, also the ones not in use yet).
func get_weapon_slots() -> Array[int]:
	return _slots_where(func(type_key: String) -> bool: return type_key.is_empty())


func get_dummy_slots() -> Array[int]:
	return _slots_where(func(type_key: String) -> bool: return not type_key.is_empty() and type_key != JEWELRY)


## Places of the jewel case (rings and amulets).
func get_jewel_slots() -> Array[int]:
	return _slots_where(func(type_key: String) -> bool: return type_key == JEWELRY)


## Whether display place `index` is in use (shows and sells something).
func is_active(index: int) -> bool:
	if index < 0 or index >= slots.size():
		return false
	if slot_types[index] == JEWELRY:
		return jewel_active
	return index < active_slots or (dummy_active and not slot_types[index].is_empty())


func _slots_where(test: Callable) -> Array[int]:
	var list: Array[int] = []
	for i in slots.size():
		if test.call(slot_types[i]):
			list.append(i)
	return list


## true once Nina's dummy wears a piece on every place (side task "Die Rüstungspuppe").
func is_dummy_full() -> bool:
	var dummy: Array[int] = get_dummy_slots()
	return expanded and not dummy.is_empty() and dummy.all(func(i: int) -> bool: return not slots[i].is_empty())


## A number of economy.json "shop" (Nina's shop).
static func setting(key: String, default: float) -> float:
	return float(ContentDB.economy("shop").get(key, default))


## A number of this shop: its override, otherwise economy.json "shop".
func get_setting(key: String, default: float) -> float:
	return float(_overrides.get(key, setting(key, default)))


## Sale price of one piece in this shop (with its price factor, furniture bonus and the player's
## skill "Verkaufstalent").
func price_of(stack: InventorySlot, reputation_bonus: float) -> int:
	var bonus: float = price_bonus + GameState.player_stats.get_sell_price_bonus()
	return get_price(stack, reputation_bonus, get_setting("price_factor", 1.5), bonus)


## What the player gets for one piece in this shop (after the commission, if any).
func payout_of(stack: InventorySlot, reputation_bonus: float) -> int:
	return maxi(1, roundi(price_of(stack, reputation_bonus) * (1.0 - get_setting("commission", 0.15))))


## Whether `stack` may lie on display place `index`: a cooled weapon, or on a dummy place a cooled
## piece of that type (e.g. a helmet).
func can_place(index: int, stack: InventorySlot) -> bool:
	if not is_active(index) or stack.is_empty() or stack.hot:
		return false
	var type_key: String = slot_types[index]
	if type_key.is_empty():
		return stack.item.is_weapon()
	if type_key == JEWELRY:
		return stack.item.type in [ItemData.ItemType.RING, ItemData.ItemType.NECKLACE]
	return ItemData.ItemType.keys()[stack.item.type] == type_key.to_upper()


## Sale price of one piece with the reputation's price bonus (0.05 = +5 %) and `bonus` (furniture,
## skill). `price_factor` < 0: economy.json (Nina's shop).
static func get_price(stack: InventorySlot, reputation_bonus: float, price_factor: float = -1.0, bonus: float = 0.0) -> int:
	# Every tier above R1 counts (not only above the material's own rarity), so a better metal
	# (iron is R2 already) is worth more than a cheaper one of the same rarity.
	var steps: int = maxi(0, stack.rarity)
	var factor: float = price_factor if price_factor >= 0.0 else setting("price_factor", 1.5)
	var crystal: float = Economy.get_crystal_value(stack)
	var base: float = (Economy.get_value(stack) - crystal) * factor + crystal * Economy.jewelry_setting("shop_crystal_factor", 1.0)
	base *= 1.0 + Economy.price("rarity_bonus_per_step", 0.25) * steps
	base *= 1.0 + reputation_bonus
	base *= 1.0 + bonus
	return maxi(1, roundi(base)) + Economy.get_crafted_bonus(stack)


## Puts one piece of the inventory stack at `inventory_index` into display slot `index`.
## Returns false if that is not possible (slot taken, item not allowed).
func place(index: int, inventory: Inventory, inventory_index: int) -> bool:
	var source: InventorySlot = inventory.slots[inventory_index]
	if not can_place(index, source) or not slots[index].is_empty():
		return false
	slots[index] = source.copy_with_amount(1)
	inventory.remove_from_slot(inventory_index, 1)
	changed.emit()
	return true


## Takes a displayed item back into the inventory (stays if there is no room).
func take_back(index: int, inventory: Inventory) -> bool:
	var stack: InventorySlot = slots[index]
	if stack.is_empty() or inventory.get_free_space(stack) < stack.amount:
		return false
	inventory.add_stack(stack)
	slots[index] = InventorySlot.new()
	changed.emit()
	return true


## How many pieces of item `item_id` lie on display right now.
func count_displayed(item_id: String) -> int:
	var count: int = 0
	for i in slots.size():
		if is_active(i) and not slots[i].is_empty() and String(slots[i].item.id) == item_id:
			count += 1
	return count


## Pays out the pending gold. Returns how much it was.
func collect() -> int:
	var amount: int = pending_gold
	pending_gold = 0
	changed.emit()
	return amount


## Rolls the sales for every full hour that passed while the shop was open.
func tick(day: int, minutes: float, reputation_bonus: float) -> void:
	var hour_key: int = day * 24 + floori(minutes / 60.0)
	if _last_hour_key < 0 or hour_key < _last_hour_key:
		_last_hour_key = hour_key
		return
	while _last_hour_key < hour_key:
		_last_hour_key += 1
		var hour: int = _last_hour_key % 24
		var until: int = int(get_setting("open_until_hour", 20))
		if hour >= int(get_setting("open_from_hour", 8)) and hour < until:
			_roll_sales(_last_hour_key / 24, reputation_bonus, hour == until - 1)


## Sales of one open hour. In the last hour of an expanded shop it sells until the minimum of the
## day is reached (as long as something is on display).
func _roll_sales(day: int, reputation_bonus: float, last_hour: bool) -> void:
	if day != _sales_day:
		_sales_day = day
		_sold_today = 0
	for i in slots.size():
		if is_active(i) and not slots[i].is_empty() and randf() < get_setting("sale_chance_per_hour", 0.2):
			_sell(i, reputation_bonus)
	if not (last_hour and expanded):
		return
	var minimum: int = int(ContentDB.economy("shop").get("expansion", {}).get("min_sales_per_day", 0))
	while _sold_today < minimum:
		var filled: Array = range(slots.size()).filter(func(i: int) -> bool: return is_active(i) and not slots[i].is_empty())
		if filled.is_empty():
			return
		_sell(filled.pick_random(), reputation_bonus)


func _sell(index: int, reputation_bonus: float) -> void:
	var sold: InventorySlot = slots[index]
	var payout: int = payout_of(sold, reputation_bonus)
	total_sales += price_of(sold, reputation_bonus)
	slots[index] = InventorySlot.new()
	pending_gold += payout
	sold_count += 1
	sold_items[String(sold.item.id)] = int(sold_items.get(String(sold.item.id), 0)) + 1
	_sold_today += 1
	item_sold.emit(sold, payout)
	changed.emit()


# --- Saving -----------------------------------------------------------------------

## Wares of the last load_save_data that found no place (the shop has fewer places of their kind
## than the save). Returned once.
func take_overflow() -> Array[InventorySlot]:
	var wares: Array[InventorySlot] = _overflow
	_overflow = []
	return wares


func to_save_data() -> Dictionary:
	return {"slots": slots.map(func(slot: InventorySlot) -> Dictionary: return slot.to_save_data()),
			"slot_types": slot_types.duplicate(),
			"pending_gold": pending_gold, "sold_count": sold_count, "sold_items": sold_items.duplicate(),
			"total_sales": total_sales, "expanded": expanded}


func load_save_data(data: Dictionary) -> void:
	var saved: Array = data.get("slots", [])
	var saved_types: Array = data.get("slot_types", [])
	for i in slots.size():
		slots[i] = InventorySlot.new()
	_overflow.clear()
	# The number of places comes from the JSON and can change between versions: every ware goes to
	# a place of its kind (the n-th helmet place of the save to the n-th helmet place of today),
	# not to its old index. Older saves without "slot_types" are read by index as before.
	var next_place: Dictionary = {}
	for i in saved.size():
		var stack: InventorySlot = InventorySlot.from_save_data(saved[i])
		var index: int = i
		if saved_types.size() == saved.size():
			var type_key: String = str(saved_types[i])
			var places: Array[int] = _slots_where(func(key: String) -> bool: return key == type_key)
			var number: int = int(next_place.get(type_key, 0))
			next_place[type_key] = number + 1
			index = places[number] if number < places.size() else -1
		if index >= 0 and index < slots.size():
			slots[index] = stack
		elif not stack.is_empty():
			# no place of that kind any more: nothing is lost, GameState puts it into the loot chest
			_overflow.append(stack)
	pending_gold = int(data.get("pending_gold", 0))
	sold_count = int(data.get("sold_count", 0))
	# Older saves only counted all sales: early on those were swords.
	sold_items = data.get("sold_items", {"sword": sold_count} if sold_count > 0 else {}).duplicate()
	total_sales = int(data.get("total_sales", 0))
	if data.get("expanded", false):
		expand()
	elif expanded:
		# Another save was loaded before: back to Nina's small shop.
		expanded = false
		active_slots = int(setting("slots", 4))
	_last_hour_key = -1
	changed.emit()
