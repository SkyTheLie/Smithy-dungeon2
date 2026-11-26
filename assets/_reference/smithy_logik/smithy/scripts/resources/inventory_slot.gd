class_name InventorySlot
extends Resource
## One inventory slot (or a stack of items in general): item type, amount, quality, rarity
## the random bonus attributes rolled for this specific item and, for composed items
## (e.g. a sword), the parts it was built from. Name, icon and stats are derived from that.
## Equipment can carry up to MAX_SOCKETS sockets (Socket, bonuses from sockets.json); their
## bonuses are part of the stats below, so heroes and fights use them automatically. An
## enchantment (enchanting potion, see Enchanting) works like one more socket, only one per item.
## Upgrades (upgrade table, see Upgrading): the material used and its rarity, e.g. a rat venom
## fang R1 = +1-2 poison per hit and 10 % chance to poison (UpgradeData). Quivers hold stacks of
## arrows in `contents` (ItemData.quiver_slots). Jewels from the jewel table remember their crystal
## and the one effect it gave them (Jewelry), e.g. a ruby ring with lifesteal. Watering cans carry
## their water (`water`, filled at the water tap, see Garden).

## Most sockets one item can have.
const MAX_SOCKETS: int = 4
## Quivers: order in which the places are shot (place 1 = right one first, then 0 = left, then the
## 3rd and 4th place) and their names (same index as the places, see HeroWindow).
const QUIVER_SHOT_ORDER: Array[int] = [1, 0, 2, 3]
const QUIVER_PLACE_NAMES: Array[String] = ["links", "rechts", "3. Platz", "4. Platz"]

@export var item: ItemData
@export var amount: int = 0
## Quality 0-100 from the forging minigame. 0 = no quality (e.g. ores, ingots).
@export var quality: int = 0
## Rarity of this stack (inherited when crafting, raised by the forging minigame).
@export var rarity: Rarity.Tier = Rarity.Tier.COMMON
## Random attributes from the rarity (weapons/armor only, rolled when the item is made).
@export var bonus_attributes: Array[ItemAttribute] = []
## Parts of a composed item, in recipe order (e.g. [blade, handle]). Empty = normal item.
@export var components: Array[ItemData] = []
## Glowing right after forging on the anvil; must be cooled in the water trough before it
## can be assembled or equipped.
@export var hot: bool = false
## Sharpened at the grindstone (each item only once, see Sharpening).
@export var sharpened: bool = false
## A quality potion (Mondglanz-Trank) was poured over it (each item only once, see Enchanting).
@export var quality_potion_used: bool = false
## Assembled by the player (workbench/bow table), not bought: such weapons sell for more
## (Economy.get_crafted_bonus).
@export var crafted: bool = false
## Filled sockets (at most MAX_SOCKETS).
@export var sockets: Array[Socket] = []
## Enchantment from a potion (enchanting table), null = none. Counts like a socket.
@export var enchantment: Socket
## Material this item was upgraded with at the upgrade table (null = not upgraded) and its rarity.
@export var upgrade_item: ItemData
@export var upgrade_rarity: Rarity.Tier = Rarity.Tier.COMMON
## Quivers: one stack of arrows per place (empty slots for free places), the first is shot first.
@export var contents: Array[InventorySlot] = []
## Story of a weapon the player made (docs/BINDUNG.md Paket 4): {"day": day it was made, "kills":
## monsters it killed, "foes": {enemy id: kills}, "bosses": [boss names]}. {} = none. From
## economy.json "weapon_history" "nickname_kills" kills on it gets a nickname (get_nickname).
@export var history: Dictionary = {}
## Jewel table (Jewelry): the crystal set into this ring / amulet (null = none) and its effect id
## (Jewelry.STATS, e.g. "lifesteal"); the value comes from the crystal and the rarity (get_jewel_value).
@export var jewel_crystal: ItemData
@export var jewel_effect: String = ""
## Watering cans: water left, one charge waters one field (at most get_water_capacity()).
@export var water: int = 0


func is_empty() -> bool:
	return item == null or amount <= 0


## Whether the quality 0-100 (ForgeQuality) matters for this stack: forged or made things
## (parts, equipment, ingots) or anything that has a quality.
func has_quality() -> bool:
	if is_empty():
		return false
	return quality > 0 or item.part_type != ItemData.PartType.NONE or item.is_equipment() \
			or item.type == ItemData.ItemType.INGOT


func clear() -> void:
	item = null
	amount = 0
	quality = 0
	rarity = Rarity.Tier.COMMON
	bonus_attributes = []
	components = []
	hot = false
	sharpened = false
	quality_potion_used = false
	crafted = false
	sockets = []
	enchantment = null
	upgrade_item = null
	upgrade_rarity = Rarity.Tier.COMMON
	contents = []
	history = {}
	jewel_crystal = null
	jewel_effect = ""
	water = 0


## Copy of this stack with another amount.
func copy_with_amount(new_amount: int) -> InventorySlot:
	var copy := InventorySlot.new()
	copy.item = item
	copy.amount = new_amount
	copy.quality = quality
	copy.rarity = rarity
	copy.bonus_attributes = bonus_attributes.duplicate()
	copy.components = components.duplicate()
	copy.hot = hot
	copy.sharpened = sharpened
	copy.quality_potion_used = quality_potion_used
	copy.crafted = crafted
	copy.sockets = sockets.duplicate()
	copy.enchantment = enchantment
	copy.upgrade_item = upgrade_item
	copy.upgrade_rarity = upgrade_rarity
	copy.contents = _copy_contents()
	copy.history = history.duplicate(true)
	copy.jewel_crystal = jewel_crystal
	copy.jewel_effect = jewel_effect
	copy.water = water
	return copy


## Takes over item, quality, rarity and attributes of `other` (amount is set separately).
func copy_properties_from(other: InventorySlot) -> void:
	item = other.item
	quality = other.quality
	rarity = other.rarity
	bonus_attributes = other.bonus_attributes.duplicate()
	components = other.components.duplicate()
	hot = other.hot
	sharpened = other.sharpened
	quality_potion_used = other.quality_potion_used
	crafted = other.crafted
	sockets = other.sockets.duplicate()
	enchantment = other.enchantment
	upgrade_item = other.upgrade_item
	upgrade_rarity = other.upgrade_rarity
	contents = other._copy_contents()
	history = other.history.duplicate(true)
	jewel_crystal = other.jewel_crystal
	jewel_effect = other.jewel_effect
	water = other.water


## Most pieces of this stack in one slot: glowing pieces never stack (one per slot).
func get_max_stack() -> int:
	return 1 if hot else item.max_stack


## Only items with the same type, quality, rarity, bonus attributes and parts stack; glowing
## pieces never do.
func can_stack_with(other: InventorySlot) -> bool:
	if hot or other.hot:
		return false
	if item != other.item or rarity != other.rarity:
		return false
	# Arrows of the same kind and rarity stack whatever their quality (see add_from).
	if quality != other.quality and item.type != ItemData.ItemType.ARROWS:
		return false
	if components != other.components or hot != other.hot or sharpened != other.sharpened \
			or quality_potion_used != other.quality_potion_used:
		return false
	if not history.is_empty() or not other.history.is_empty():
		return false
	if not sockets.is_empty() or not other.sockets.is_empty() or enchantment or other.enchantment:
		return false
	if upgrade_item != other.upgrade_item or (upgrade_item and upgrade_rarity != other.upgrade_rarity):
		return false
	if not contents.is_empty() or not other.contents.is_empty():
		return false
	if jewel_crystal != other.jewel_crystal or jewel_effect != other.jewel_effect:
		return false
	if water != other.water:
		return false
	if bonus_attributes.size() != other.bonus_attributes.size():
		return false
	for i in bonus_attributes.size():
		var mine: ItemAttribute = bonus_attributes[i]
		var theirs: ItemAttribute = other.bonus_attributes[i]
		if mine.type != theirs.type or mine.value != theirs.value:
			return false
	return true


## Puts `count` pieces like `other` onto this stack (call can_stack_with first). Arrows of a
## different quality take the average quality, weighted by the amounts (90 and 50 -> 70).
func add_from(other: InventorySlot, count: int) -> void:
	if count <= 0:
		return
	if quality != other.quality:
		quality = roundi(float(quality * amount + other.quality * count) / float(amount + count))
	amount += count


## Name shown in the UI: composed items take the material of their first part,
## e.g. "Eisen" + "Schwert" -> "Eisenschwert"; a famous weapon adds its nickname
## ("Kupferschwert „Rattenbeißer“"); jewels take their crystal ("Rubin" + "Ring" -> "Rubinring").
func get_display_name() -> String:
	var nickname: String = get_nickname()
	var base: String = item.display_name
	if jewel_crystal:
		base = Language.compose_name(jewel_crystal.display_name, item.display_name)
	elif not components.is_empty() and components[0].material_name != "":
		base = Language.compose_name(components[0].material_name, item.display_name)
	return base if nickname.is_empty() else "%s „%s“" % [base, nickname]


# --- Weapon history -------------------------------------------------------------------

## Starts the story of a piece the player just made on `day`.
func start_history(day: int) -> void:
	history = {"day": day, "kills": 0, "foes": {}, "bosses": []}


## A monster this weapon killed (only weapons with a history count).
func record_kill(enemy_id: String, boss_name: String = "") -> void:
	if history.is_empty():
		return
	history["kills"] = int(history.get("kills", 0)) + 1
	var foes: Dictionary = history.get("foes", {})
	foes[enemy_id] = int(foes.get(enemy_id, 0)) + 1
	history["foes"] = foes
	var bosses: Array = history.get("bosses", [])
	if not boss_name.is_empty() and not bosses.has(boss_name):
		bosses.append(boss_name)
	history["bosses"] = bosses


func get_kills() -> int:
	return int(history.get("kills", 0))


## The enemy id it killed most ("" = none).
func get_main_foe() -> String:
	var best: String = ""
	var foes: Dictionary = history.get("foes", {})
	for foe: String in foes:
		if best.is_empty() or int(foes[foe]) > int(foes[best]):
			best = foe
	return best


## Nickname once it killed enough (economy.json "weapon_history"): the one of the family it
## killed most ("nicknames", key = enemy id or a part of it like "rat", "wolf"), else "default".
func get_nickname() -> String:
	var settings: Dictionary = ContentDB.economy("weapon_history")
	if history.is_empty() or get_kills() < int(settings.get("nickname_kills", 25)):
		return ""
	var foe: String = get_main_foe()
	var nicknames: Dictionary = settings.get("nicknames", {})
	if nicknames.has(foe):
		return nicknames[foe]
	for family: String in nicknames:
		if foe.begins_with(family + "_") or foe.ends_with("_" + family):
			return nicknames[family]
	return str(settings.get("default_nickname", Language.translate("Monsterschreck")))


## Tooltip lines: when it was made, how many monsters (and which most), bosses.
func get_history_lines() -> Array[String]:
	var lines: Array[String] = []
	if history.is_empty():
		return lines
	lines.append(Language.translate("Geschmiedet am %s") % GameCalendar.get_short_text(int(history.get("day", 1))))
	var kills: int = get_kills()
	if kills > 0:
		var foe: String = get_main_foe()
		var foe_name: String = ContentDB.enemy(foe).display_name if ContentDB.has_enemy(foe) else foe
		lines.append(Language.translate("%d Monster besiegt (meist %s)") % [kills, foe_name] if kills > 1 else Language.translate("1 Monster besiegt (%s)") % foe_name)
	for boss: String in history.get("bosses", []):
		lines.append(Language.translate("Hat %s besiegt") % boss)
	return lines


## Icon shown in the UI: composed items layer the icons of their parts. Leather and feathers are
## not drawn (armor shows its plate, arrows tip and shaft). Items with "part_icons" show the picture
## of their first matching part instead (the leather cloak per leather, the backpack per frame).
func get_icon() -> Texture2D:
	if item.own_icon:
		return item.icon
	for part in components:
		if item.part_icons.has(part.id):
			return item.part_icons[part.id]
	if jewel_crystal:
		var band: ItemData = components[0] if not components.is_empty() else null
		var jewel_icon: Texture2D = ItemIcons.jewel(jewel_crystal, band, Jewelry.get_kind(band))
		if jewel_icon:
			return jewel_icon
	var drawn: Array[ItemData] = []
	for part in components:
		if part.part_type not in [ItemData.PartType.LEATHER, ItemData.PartType.FLETCHING]:
			drawn.append(part)
	if not drawn.is_empty():
		var composed: Texture2D = ItemIcons.compose(drawn)
		if composed:
			return composed
	return item.icon


## Mining damage of a pickaxe: its own plus that of its parts (e.g. the copper pickaxe head).
func get_mining_damage() -> int:
	var total: int = item.mining_damage
	for part in components:
		total += part.mining_damage
	return total


## Damage on trees of a lumber axe: its own plus that of its parts (e.g. the copper head).
func get_chopping_damage() -> int:
	var total: int = item.chopping_damage
	for part in components:
		total += part.chopping_damage
	return total


## Backpacks: extra inventory slots, its own plus those of its parts (the frame decides the size).
func get_inventory_slots() -> int:
	var total: int = item.inventory_slots
	for part in components:
		total += part.inventory_slots
	return total


## Watering cans: charges of one filling, its own plus those of its parts (the can body decides).
func get_water_capacity() -> int:
	var total: int = item.water_charges
	for part in components:
		total += part.water_charges
	return total


## Shoes: walking speed bonus in percent, e.g. leather shoes R1 10, R2 12, R3 14 (0 = none).
func get_move_speed() -> int:
	if item.move_speed <= 0:
		return 0
	return item.move_speed + 2 * rarity


## Damage with the socket bonuses (extra damage and +% damage), e.g. 10 + 20 % = 12.
func get_damage_min() -> int:
	return _with_damage_sockets(get_base_damage_min())


func get_damage_max() -> int:
	return _with_damage_sockets(get_base_damage_max())


## Damage of the item, its parts and its rarity, without sockets. Armor (e.g. a shield with a
## handle) never deals damage.
func get_base_damage_min() -> int:
	if item.is_armor():
		return 0
	var total: int = item.damage_min + _get_rarity_stat_bonus()
	for part in components:
		total += part.damage_min
	return _arrow_scaled(total)


func get_base_damage_max() -> int:
	if item.is_armor():
		return 0
	var total: int = item.damage_max + _get_rarity_stat_bonus()
	for part in components:
		total += part.damage_max
	return _arrow_scaled(total)


## Arrows: the damage of tip, shaft and fletching x combat.json "arrow_damage_factor" (3), so
## better arrows make a ranger clearly stronger (the parts alone show their plain damage).
func _arrow_scaled(total: int) -> int:
	if item.type != ItemData.ItemType.ARROWS:
		return total
	return roundi(total * CombatRules.value("arrow_damage_factor", 3.0))


func get_armor() -> int:
	var total: int = item.armor + _get_rarity_stat_bonus()
	for part in components:
		total += part.armor
	return total + roundi(total * get_socket_total(SocketBonus.Effect.ARMOR_PERCENT) / 100.0)


func get_magic_resistance() -> int:
	var total: int = item.magic_resistance
	for part in components:
		total += part.magic_resistance
	return total + roundi(get_socket_total(SocketBonus.Effect.MAGIC_RESISTANCE))


# --- Upgrade (upgrade table) --------------------------------------------------------

func get_upgrade() -> UpgradeData:
	return upgrade_item.upgrade if upgrade_item else null


## What the upgrade does in a fight: {"kind", "damage_min", "damage_max", "chance", "effect"};
## {} = not upgraded.
func get_upgrade_values() -> Dictionary:
	var upgrade: UpgradeData = get_upgrade()
	if upgrade == null:
		return {}
	var values: Dictionary = upgrade.get_values(upgrade_rarity)
	return {
		"kind": upgrade.damage_kind,
		"damage_min": int(values.get("damage_min", 0)),
		"damage_max": int(values.get("damage_max", 0)),
		"chance": float(values.get("chance", 0.0)),
		"effect": upgrade.get_effect(),
		"resistance_kind": upgrade.resistance_kind,
		"resistance": float(values.get("resistance", 0.0)),
	}


# --- Quiver -----------------------------------------------------------------------

func is_quiver() -> bool:
	return not is_empty() and item.quiver_slots > 0


## The places of a quiver, filled up with empty slots to quiver_slots.
func get_quiver_slots() -> Array[InventorySlot]:
	while contents.size() < item.quiver_slots:
		contents.append(InventorySlot.new())
	return contents


## Indices of the quiver places in the order they are shot (right, left, 3rd, 4th).
func get_quiver_shot_order() -> Array[int]:
	var order: Array[int] = []
	for index in QUIVER_SHOT_ORDER:
		if index < item.quiver_slots:
			order.append(index)
	for index in range(QUIVER_SHOT_ORDER.size(), item.quiver_slots):
		order.append(index)
	return order


## The arrows shot next from this quiver (null = empty).
func get_next_quiver_arrows() -> InventorySlot:
	var places: Array[InventorySlot] = get_quiver_slots()
	for index in get_quiver_shot_order():
		if not places[index].is_empty():
			return places[index]
	return null


## Arrows in all places of a quiver.
func get_arrow_count() -> int:
	var total: int = 0
	for stack in contents:
		if not stack.is_empty():
			total += stack.amount
	return total


## Puts arrows into a quiver: onto the same arrows first, then into a free place (in shot order).
## Returns how many went in (the rest stays in `arrows`, which is reduced).
func add_to_quiver(arrows: InventorySlot) -> int:
	if not is_quiver() or arrows.is_empty() or arrows.item.type != ItemData.ItemType.ARROWS:
		return 0
	var moved: int = 0
	for stack in get_quiver_slots():
		if arrows.amount <= 0:
			break
		if not stack.is_empty() and stack.can_stack_with(arrows):
			var amount: int = mini(arrows.amount, stack.item.max_stack - stack.amount)
			stack.add_from(arrows, amount)
			arrows.amount -= amount
			moved += amount
	for i in get_quiver_shot_order():
		if arrows.amount <= 0:
			break
		if contents[i].is_empty():
			contents[i] = arrows.copy_with_amount(arrows.amount)
			moved += arrows.amount
			arrows.amount = 0
	return moved


func _copy_contents() -> Array[InventorySlot]:
	var result: Array[InventorySlot] = []
	for stack in contents:
		result.append(stack.copy_with_amount(stack.amount) if not stack.is_empty() else InventorySlot.new())
	return result


# --- Sockets ----------------------------------------------------------------------

## Puts a socket into this item. false if it is full or the bonus does not fit this item.
func add_socket(socket: Socket) -> bool:
	if socket == null or sockets.size() >= MAX_SOCKETS or not socket.bonus.fits(item):
		return false
	sockets.append(socket)
	return true


## The sockets and the enchantment: everything whose bonus counts. A combo bonus counts as its
## parts, each at the combo's factor (e.g. magma: fire and earth damage at 70 %).
func get_active_sockets() -> Array[Socket]:
	var active: Array[Socket] = []
	for socket: Socket in sockets + ([enchantment] if enchantment else []):
		if socket.bonus.effect != SocketBonus.Effect.COMBO:
			active.append(socket)
			continue
		for part in socket.bonus.combo:
			var piece: Socket = Socket.create(part, socket.level)
			piece.factor = socket.bonus.combo_factor
			active.append(piece)
	return active


## Status effects the weapon's hits may cause (ON_HIT bonuses, e.g. a fire curse):
## [{"effect": StatusEffectData, "chance": 0-1}].
func get_socket_on_hit() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for socket in get_active_sockets():
		if socket.bonus.effect == SocketBonus.Effect.ON_HIT and ContentDB.has_status_effect(socket.bonus.status_id):
			result.append({"effect": ContentDB.status_effect(socket.bonus.status_id), "chance": socket.get_value() / 100.0})
	return result


## Sum of all socket values with this effect (and `kind`, if given).
func get_socket_total(effect: SocketBonus.Effect, kind: String = "") -> float:
	var total: float = 0.0
	for socket in get_active_sockets():
		if socket.bonus.effect == effect and (kind.is_empty() or socket.bonus.kind == kind):
			total += socket.get_value()
	return total


## Extra damage from sockets in percent per DamageKinds id, e.g. {"blunt": 20.0}.
func get_socket_extra_damage() -> Dictionary:
	var extra: Dictionary = {}
	for socket in get_active_sockets():
		if socket.bonus.effect == SocketBonus.Effect.EXTRA_DAMAGE:
			extra[socket.bonus.kind] = extra.get(socket.bonus.kind, 0.0) + socket.get_value()
	return extra


func _with_damage_sockets(base: int) -> int:
	if sockets.is_empty() and enchantment == null:
		return base
	var percent: float = get_socket_total(SocketBonus.Effect.DAMAGE_PERCENT) + get_socket_total(SocketBonus.Effect.EXTRA_DAMAGE)
	return base + roundi(base * percent / 100.0)


## All attributes: fixed ones of the item and its parts plus the random rarity attributes.
## Attributes of the same type are added up. Socket and enchantment bonuses are included unless
## `include_sockets` is false (the tooltip lists them on their own line).
func get_attributes(include_sockets: bool = true) -> Array[ItemAttribute]:
	var totals: Dictionary = {}
	var sources: Array = [item.attributes]
	for part in components:
		sources.append(part.attributes)
	sources.append(bonus_attributes)
	for source in sources:
		for attribute: ItemAttribute in source:
			totals[attribute.type] = totals.get(attribute.type, 0) + attribute.value
	for socket in get_active_sockets() if include_sockets else []:
		if socket.bonus.effect == SocketBonus.Effect.ATTRIBUTE:
			totals[socket.bonus.attribute] = totals.get(socket.bonus.attribute, 0) + roundi(socket.get_value())
	var result: Array[ItemAttribute] = []
	for attribute_type in totals:
		result.append(ItemAttribute.create(attribute_type, totals[attribute_type]))
	return result


## The rarity bonus only counts for finished weapons and armor, not for parts.
func _get_rarity_stat_bonus() -> int:
	if item.is_weapon() or item.is_armor():
		return Rarity.get_stat_bonus(rarity)
	return 0


## Magic damage of a staff (with its parts); a rarer staff gets the rarity bonus like the physical
## damage of weapons, so casters grow with better forged staffs.
func get_magic_damage_min() -> int:
	var total: int = item.magic_damage_min
	for part in components:
		total += part.magic_damage_min
	return total + _get_rarity_stat_bonus() if total > 0 else total


func get_magic_damage_max() -> int:
	var total: int = item.magic_damage_max
	for part in components:
		total += part.magic_damage_max
	return total + _get_rarity_stat_bonus() if total > 0 else total


## How the weapon's damage is split into kinds: the item's own split, otherwise the first part
## with one, otherwise its damage type (e.g. blade = 100 % slash), otherwise physical.
## Extra damage from sockets is added as its own share: slash 100 % + Wucht 20 % =
## {"slash": 0.83, "blunt": 0.17} (12-18 damage instead of 10-15).
func get_damage_split() -> Dictionary:
	var extra: Dictionary = get_socket_extra_damage()
	if extra.is_empty():
		return get_base_damage_split()
	var base: Dictionary = DamageKinds.normalized(get_base_damage_split())
	var scale: float = 1.0 + get_socket_total(SocketBonus.Effect.DAMAGE_PERCENT) / 100.0
	var split: Dictionary = {}
	for kind: String in base:
		split[kind] = base[kind] * scale
	for kind: String in extra:
		split[kind] = split.get(kind, 0.0) + extra[kind] / 100.0
	return DamageKinds.normalized(split)


## Split without socket extra damage.
func get_base_damage_split() -> Dictionary:
	if not item.damage_split.is_empty():
		return item.damage_split
	for part in components:
		if not part.damage_split.is_empty():
			return part.damage_split
	return {DamageKinds.from_damage_type(get_damage_type()): 1.0}


## Resistances of the item and its parts added up: DamageKinds id -> value.
func get_resistances() -> Dictionary:
	var totals: Dictionary = {}
	for source: ItemData in [item] + components:
		for kind: String in source.resistances:
			totals[kind] = totals.get(kind, 0.0) + source.resistances[kind]
	for socket in get_active_sockets():
		if socket.bonus.effect == SocketBonus.Effect.RESISTANCE:
			totals[socket.bonus.kind] = totals.get(socket.bonus.kind, 0.0) + socket.get_value()
	# Crystal from the upgrade table (e.g. ruby: fire +2).
	var upgrade: Dictionary = get_upgrade_values()
	if not upgrade.is_empty() and not upgrade["resistance_kind"].is_empty() and upgrade["resistance"] != 0.0:
		totals[upgrade["resistance_kind"]] = totals.get(upgrade["resistance_kind"], 0.0) + upgrade["resistance"]
	return totals


func get_crit_chance() -> float:
	var total: float = item.crit_chance
	for part in components:
		total += part.crit_chance
	return total + get_socket_total(SocketBonus.Effect.CRIT_CHANCE) / 100.0


func get_crit_damage() -> float:
	var total: float = item.crit_damage
	for part in components:
		total += part.crit_damage
	return total + get_socket_total(SocketBonus.Effect.CRIT_DAMAGE) / 100.0


## Armor / magic penetration of the item and its parts (CombatRules.penetration).
func get_penetration() -> Dictionary:
	var total: Dictionary = {}
	for source: ItemData in [item] + components:
		total = CombatRules.add_penetration(total, source.penetration)
	return total


## Damage type of the item itself, otherwise of the first part that has one (e.g. the blade).
func get_damage_type() -> DamageType.Type:
	if item.damage_type != DamageType.Type.NONE:
		return item.damage_type
	for part in components:
		if part.damage_type != DamageType.Type.NONE:
			return part.damage_type
	return DamageType.Type.NONE


## Element of the item itself, otherwise of the first part that has one.
func get_element() -> Element.Type:
	if item.element != Element.Type.NONE:
		return item.element
	for part in components:
		if part.element != Element.Type.NONE:
			return part.element
	return Element.Type.NONE


# --- Jewels -----------------------------------------------------------------------

## Value of the jewel's effect (Jewelry.get_value), 0 for anything else.
func get_jewel_value() -> float:
	if jewel_crystal == null or jewel_effect.is_empty() or components.is_empty():
		return 0.0
	return Jewelry.get_value(jewel_crystal, Jewelry.get_kind(components[0]), jewel_effect, rarity, components[0])


## The jewel's value for this effect id (e.g. "lifesteal"), 0 if it has another one.
func get_jewel_stat(stat: String) -> float:
	return get_jewel_value() if jewel_effect == stat else 0.0


# --- Saving -----------------------------------------------------------------------

## Plain data for the save file (items as resource paths). Empty slot = {}.
func to_save_data() -> Dictionary:
	if is_empty():
		return {}
	var attributes: Array = []
	for attribute in bonus_attributes:
		attributes.append([attribute.type, attribute.value])
	var parts: Array = []
	for part in components:
		parts.append(String(part.id))
	var saved_sockets: Array = []
	for socket in sockets:
		saved_sockets.append(socket.to_save_data())
	return {
		"item": String(item.id),
		"amount": amount,
		"quality": quality,
		"rarity": rarity,
		"attributes": attributes,
		"components": parts,
		"hot": hot,
		"sharpened": sharpened,
		"quality_potion_used": quality_potion_used,
		"crafted": crafted,
		"sockets": saved_sockets,
		"enchantment": enchantment.to_save_data() if enchantment else [],
		"upgrade": String(upgrade_item.id) if upgrade_item else "",
		"upgrade_rarity": upgrade_rarity,
		"contents": contents.map(func(stack: InventorySlot) -> Dictionary: return stack.to_save_data()),
		"history": history.duplicate(true),
		"jewel_crystal": String(jewel_crystal.id) if jewel_crystal else "",
		"jewel_effect": jewel_effect,
		"water": water,
	}


## Opposite of to_save_data(). Returns an empty slot if the item no longer exists.
static func from_save_data(data: Dictionary) -> InventorySlot:
	var slot := InventorySlot.new()
	if data.is_empty():
		return slot
	# Item ids (older saves: resource paths, ContentDB converts them).
	var item_id: String = data.get("item", "")
	if not ContentDB.has_item(item_id):
		push_warning("Save refers to a missing item: %s" % item_id)
		return slot
	var loaded_item: ItemData = ContentDB.item(item_id)
	slot.item = loaded_item
	slot.amount = int(data.get("amount", 1))
	slot.quality = int(data.get("quality", 0))
	slot.rarity = int(data.get("rarity", 0)) as Rarity.Tier
	slot.hot = bool(data.get("hot", false))
	slot.sharpened = bool(data.get("sharpened", false))
	slot.quality_potion_used = bool(data.get("quality_potion_used", false))
	# Older saves: composed items count as made by the player.
	slot.crafted = bool(data.get("crafted", not data.get("components", []).is_empty()))
	for attribute: Array in data.get("attributes", []):
		slot.bonus_attributes.append(ItemAttribute.create(int(attribute[0]) as ItemAttribute.Type, int(attribute[1])))
	for path: String in data.get("components", []):
		if ContentDB.has_item(path):
			slot.components.append(ContentDB.item(path))
	# Backpacks built at the workbench before 2026-10-26 kept no parts (and so gave no places):
	# they count as copper backpacks, the frame is not known any more.
	if loaded_item.type == ItemData.ItemType.BACKPACK and slot.components.is_empty() \
			and ContentDB.has_item("copper_backpack_frame") and ContentDB.has_item("leather"):
		slot.components.assign([ContentDB.item("copper_backpack_frame"), ContentDB.item("leather")])
	for saved: Array in data.get("sockets", []):
		var socket: Socket = Socket.from_save_data(saved)
		if socket and slot.sockets.size() < MAX_SOCKETS:
			slot.sockets.append(socket)
	slot.enchantment = Socket.from_save_data(data.get("enchantment", []))
	var upgrade_id: String = data.get("upgrade", "")
	if not upgrade_id.is_empty() and ContentDB.has_item(upgrade_id):
		slot.upgrade_item = ContentDB.item(upgrade_id)
		slot.upgrade_rarity = int(data.get("upgrade_rarity", 0)) as Rarity.Tier
	for saved: Dictionary in data.get("contents", []):
		slot.contents.append(InventorySlot.from_save_data(saved))
	slot.history = (data.get("history", {}) as Dictionary).duplicate(true)
	var crystal_id: String = data.get("jewel_crystal", "")
	if not crystal_id.is_empty() and ContentDB.has_item(crystal_id):
		slot.jewel_crystal = ContentDB.item(crystal_id)
		slot.jewel_effect = data.get("jewel_effect", "")
	slot.water = int(data.get("water", 0))
	return slot
