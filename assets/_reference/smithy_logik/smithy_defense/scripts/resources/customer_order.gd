class_name CustomerOrder
extends RefCounted
## An order from a customer (see Customers): a composed item with exactly these parts (e.g. a
## sword with iron blade and copper handle) in at least this rarity, until the end of
## `deadline_day`. Gold and EXP are fixed when the order is made (see Economy).
## Handed in at the order board in front of the smithy.

## Unique number (also in save files).
var id: int = 0
var customer_name: String = ""
## Look of the customer (generated, see Appearance).
var appearance: Appearance = Appearance.new()
## PixelLab sheet instead of the look (assets/sprites/residents/, e.g. Ritter Edmund), "" = none.
var resident: String = ""
## Item id from items.json, e.g. "sword".
var item: ItemData
## The wanted parts, in recipe order (e.g. [iron_blade, copper_handle]).
var parts: Array[ItemData] = []
## Lowest rarity that is accepted.
var rarity: Rarity.Tier = Rarity.Tier.COMMON
## Last day on which it can be handed in.
var deadline_day: int = 1
var gold: int = 0
var experience: int = 0
## Set for orders the story creates (e.g. "first_customer"): they don't expire, and handing
## them in sets the story flag "order_done_<tag>".
var story_tag: String = ""
## Rush order (Customers: shorter deadline, more gold), "Eilauftrag" in its title.
var rush: bool = false
## "big" (more gold, rarer, best metal), "normal" or "small" (hardly worth it), see
## Customers.create_order; big and small ones have a word in their title (Customers.get_kind_title).
var kind: String = "normal"
## Orders of the knight (Customers.create_knight_order, title "Stadtwache"): extras the piece may
## have for `bonus_gold` more - a random attribute of at least `wanted_attribute_value`
## (`wanted_attribute` = ItemAttribute.Type, -1 = none) and/or an enchantment (`wanted_enchant` =
## socket bonus id, e.g. "enchant_fire", "" = none). Without them the knight still pays `gold`.
var knight: bool = false
var wanted_attribute: int = -1
var wanted_attribute_value: int = 0
var wanted_enchant: String = ""
var bonus_gold: int = 0


## Name of the wanted item, e.g. "Eisenschwert" (like a crafted one, see InventorySlot).
func get_item_name() -> String:
	if parts.is_empty() or parts[0].material_name == "":
		return item.display_name
	return Language.compose_name(parts[0].material_name, item.display_name)


## "Klinge: Eisenklinge, Griff: Kupfergriff"; with extras "... · Bonus +300 Gold: Beweglichkeit +4".
func get_parts_text() -> String:
	var texts: Array[String] = []
	for part in parts:
		texts.append("%s: %s" % [Language.translate(ItemData.PART_TYPE_NAMES[part.part_type]), part.display_name])
	var text: String = ", ".join(texts)
	if has_extras():
		text += " · " + get_extras_text()
	return text


func has_extras() -> bool:
	return wanted_attribute >= 0 or not wanted_enchant.is_empty()


## "Bonus +300 Gold: Beweglichkeit +4, Feuerzauber".
func get_extras_text() -> String:
	var wanted: Array[String] = []
	if wanted_attribute >= 0:
		wanted.append("%s +%d" % [Language.translate(ItemAttribute.NAMES[wanted_attribute]), wanted_attribute_value])
	if not wanted_enchant.is_empty():
		var bonus: SocketBonus = ContentDB.socket_bonus(wanted_enchant) if ContentDB.has_socket_bonus(wanted_enchant) else null
		wanted.append(bonus.display_name if bonus else wanted_enchant)
	return Language.translate("Bonus +%d Gold: %s") % [bonus_gold, ", ".join(wanted)]


## Whether `slot` has every extra of the order (then the knight pays bonus_gold on top).
func extras_met(slot: InventorySlot) -> bool:
	if not has_extras():
		return false
	if wanted_attribute >= 0 and not slot.get_attributes().any(func(attribute: ItemAttribute) -> bool:
			return attribute.type == wanted_attribute and attribute.value >= wanted_attribute_value):
		return false
	return wanted_enchant.is_empty() or (slot.enchantment != null and String(slot.enchantment.bonus.id) == wanted_enchant)


## "Eisenschwert (Solide)", a rush order "Eilauftrag: Eisenschwert (Solide)", a big one
## "Großauftrag: Eisenschwert (Selten)".
func get_title() -> String:
	var prefix: String = Customers.get_kind_title(kind, knight)
	if rush:
		prefix = Language.translate("Eilauftrag") if prefix.is_empty() else Language.translate("Eilauftrag, ") + prefix
	return "%s%s (%s)" % [prefix + ": " if not prefix.is_empty() else "", get_item_name(), Rarity.get_display_name(rarity)]


## true if this stack can be handed in: same item, same parts in the same order, rarity high
## enough, cooled down.
func matches(slot: InventorySlot) -> bool:
	if slot.is_empty() or slot.hot or slot.item != item or slot.rarity < rarity:
		return false
	if slot.components.size() != parts.size():
		return false
	for i in parts.size():
		if slot.components[i] != parts[i]:
			return false
	return true


func days_left(today: int) -> int:
	return deadline_day - today


## "noch 3 Tage", "noch 1 Tag", "heute letzter Tag", "überfällig" (story orders don't expire).
static func get_days_left_text(days: int) -> String:
	if days < 0:
		return Language.translate("überfällig")
	if days == 0:
		return Language.translate("heute letzter Tag")
	return Language.translate("noch 1 Tag") if days == 1 else Language.translate("noch %d Tage") % days


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {
		"id": id,
		"customer": customer_name,
		"appearance": appearance.to_save_data(),
		"resident": resident,
		"item": String(item.id),
		"parts": parts.map(func(part: ItemData) -> String: return String(part.id)),
		"rarity": int(rarity),
		"deadline_day": deadline_day,
		"gold": gold,
		"experience": experience,
		"story_tag": story_tag,
		"rush": rush,
		"kind": kind,
		"knight": knight,
		"wanted_attribute": wanted_attribute,
		"wanted_attribute_value": wanted_attribute_value,
		"wanted_enchant": wanted_enchant,
		"bonus_gold": bonus_gold,
	}


## null if an item of the order no longer exists.
static func from_save_data(data: Dictionary) -> CustomerOrder:
	var order := CustomerOrder.new()
	if not ContentDB.has_item(data.get("item", "")):
		return null
	order.item = ContentDB.item(data["item"])
	for part_id: String in data.get("parts", []):
		if not ContentDB.has_item(part_id):
			return null
		order.parts.append(ContentDB.item(part_id))
	order.id = int(data.get("id", 0))
	order.customer_name = data.get("customer", "")
	# Older saves had no look yet: they get a random one.
	order.appearance = Appearance.from_save_data(data["appearance"]) if data.has("appearance") else Appearance.create_random()
	order.resident = data.get("resident", "")
	# Orders saved before the knight had his own figure.
	var knight: Dictionary = ContentDB.economy("knight_orders")
	if order.resident.is_empty() and order.customer_name == str(knight.get("name", "")):
		order.resident = str(knight.get("resident", ""))
	order.rarity = clampi(int(data.get("rarity", 0)), 0, Rarity.Tier.MYTHIC) as Rarity.Tier
	order.deadline_day = int(data.get("deadline_day", 1))
	order.gold = int(data.get("gold", 0))
	order.experience = int(data.get("experience", 0))
	order.story_tag = str(data.get("story_tag", ""))
	order.rush = bool(data.get("rush", false))
	order.kind = str(data.get("kind", "normal"))
	order.knight = bool(data.get("knight", false))
	order.wanted_attribute = int(data.get("wanted_attribute", -1))
	order.wanted_attribute_value = int(data.get("wanted_attribute_value", 0))
	order.wanted_enchant = str(data.get("wanted_enchant", ""))
	order.bonus_gold = int(data.get("bonus_gold", 0))
	return order
