class_name Enchanting
extends RefCounted
## Mortar and enchanting at the enchanting table (data/content/mortar.json, docs/CONTENT.md).
## Mortar (tab "Mörser"): 3 ingredient slots and 1 slot for a vial.
##   - One ingredient alone, no vial: crushed into its dust (DustData, e.g. ruby -> ruby dust),
##     with the same rarity.
##   - A crystal (or its dust) + a potion plant (or its dust) + a vial: the enchanting potion of
##     that crystal and plant (PotionData; moon lily = element damage / ward, nightshade = curse,
##     sunflower = blessing). Its rarity is mixed from the ingredients like armor
##     (Crafting.roll_mixed_rarity). The third slot: the same crystal again = a strong potion
##     (STRONG_TIERS better); two different crystals + the plant = a combo potion, if mortar.json
##     has one (e.g. ruby + topaz + moon lily = magma), else it fails.
##   - Brewed on a full moon (GameCalendar.is_full_moon) an enchanting potion is FULL_MOON_TIERS
##     better. Every mix with a vial is stirred first (StirringMinigame): its grade adds -1, 0 or
##     +1 tier (STIR_TIERS; never below the item's own rarity).
##   - Secret potions (other plants, combos: PotionData.is_secret) show in the books only once
##     brewed (flag "potion_found_<id>", is_known).
##   - A brew (mortar.json "brews", BrewData): its exact ingredients (or their dust) + a vial, e.g.
##     chamomile + sage = IQ potion; rarity from its "rarity_from" ingredient (the lowest of them).
##   - Anything else with a vial fails: the ingredients and the vial are used up, 1 ash remains
##     (fertilizer, see Garden).
## Enchanting (tab "Verzaubern"): a potion on a weapon or armor piece gives it the potion's bonus
## (sockets.json, InventorySlot.enchantment) at the level of the potion's rarity (R1 = level 1).
## An item carries one enchantment; a new potion replaces the old one.
## A quality potion (ItemData.quality_points, brewed from 3 moon lilies) is poured over a weapon or
## armor piece in the same tab: it gains that many quality points (100 = one rarity tier more).
## Reroll potions (ItemData.reroll) in the same tab: "attributes" rolls new random attribute types
## (Rarity.roll_attributes, values from the rarity), "sockets" rolls every socket anew
## (Socket.roll_for: bonus and level). As often as you like, one potion per roll.
## Story flags (set by the window): "potion_made", "item_enchanted". Achievement counters: "potion", "enchant",
## "enchant:legendary" (potion of legendary rarity or better).

const MAX_INGREDIENTS: int = 3
## Kinds of reroll potions (mortar.json brews "reroll").
const REROLLS: Array[String] = ItemData.REROLLS
## Tiers more for a potion with its crystal twice, and for one brewed on a full moon.
const STRONG_TIERS: int = 1
const FULL_MOON_TIERS: int = 1
## Grade of the stirring minigame -> tiers more or less.
enum Stir { BAD, GOOD, PERFECT }
const STIR_TIERS: Dictionary = {Stir.BAD: -1, Stir.GOOD: 0, Stir.PERFECT: 1}
const STIR_NAMES: Dictionary = {Stir.BAD: "Klumpig", Stir.GOOD: "Gut gerührt", Stir.PERFECT: "Perfekt gerührt"}
## Story flag of a brewed potion (secret recipes show in the books from then on).
const FOUND_FLAG: String = "potion_found_%s"
## Flag of Aurelius' notes (the recipes are listed at the table and in the recipe book).
const BOOK_FLAG: String = "enchanting_book_owned"


## Item the ingredient counts as in a potion: a dust counts as its source (ruby dust = ruby).
static func get_base(item: ItemData) -> ItemData:
	var dust_data: DustData = ContentDB.dust_of_item(item)
	return dust_data.source if dust_data else item


## The potion made of these ingredients (empty slots left out, vial not included), or null.
static func find_potion(items: Array[ItemData]) -> PotionData:
	return find_potion_plan(items).get("potion")


## {"potion": PotionData, "strong": bool} for these ingredients, {} = no potion. Exactly one
## potion plant; one crystal, the same crystal twice (strong) or two different ones (combo).
static func find_potion_plan(items: Array[ItemData]) -> Dictionary:
	var given: Array = items.filter(func(item: ItemData) -> bool: return item != null)
	if given.size() < 2 or given.size() > 3:
		return {}
	var plants: Array[ItemData] = ContentDB.get_potion_plants()
	var plant: ItemData = null
	var crystals: Array[ItemData] = []
	for item: ItemData in given:
		var base: ItemData = get_base(item)
		if plants.has(base) and plant == null:
			plant = base
		else:
			crystals.append(base)
	if plant == null:
		return {}
	if crystals.size() == 1:
		var single: PotionData = ContentDB.potion_from_crystal(crystals[0], plant)
		return {"potion": single, "strong": false} if single else {}
	if crystals[0] == crystals[1]:
		var strong: PotionData = ContentDB.potion_from_crystal(crystals[0], plant)
		return {"potion": strong, "strong": true} if strong else {}
	var combo: PotionData = ContentDB.potion_from_crystal(crystals[0], plant, crystals[1])
	return {"potion": combo, "strong": false} if combo else {}


## Whether the player knows the recipe of `potion` (ordinary ones always, secret ones once brewed;
## `story` = GameState.story).
static func is_known(potion: PotionData, story: Story) -> bool:
	return not potion.is_secret() or story.has_flag(FOUND_FLAG % potion.id)


## The brew made of these ingredients (empty slots left out, vial not included), or null.
static func find_brew(items: Array[ItemData]) -> BrewData:
	var given: Array[ItemData] = []
	given.assign(items.filter(func(item: ItemData) -> bool: return item != null))
	for brew in ContentDB.get_brews():
		if brew.is_known() and brew.matches(given):
			return brew
	return null


## Rarity of a brew: the lowest rarity of its "rarity_from" ingredient among the placed stacks
## (three moon lilies R2, R2, R3 = R2), without one the item's own rarity.
static func get_brew_rarity(brew: BrewData, ingredients: Array[InventorySlot]) -> Rarity.Tier:
	var rarity: int = -1
	for stack in ingredients:
		if not stack.is_empty() and brew.rarity_from and get_base(stack.item) == brew.rarity_from:
			rarity = int(stack.rarity) if rarity < 0 else mini(rarity, int(stack.rarity))
	return (rarity if rarity >= 0 else int(brew.item.base_rarity)) as Rarity.Tier


## What the mortar makes of the placed stacks: {"kind": "dust"/"potion"/"fail"/"", "dust" or
## "potion": the data, "text": why nothing happens}. `ingredients`: the 3 ingredient slots.
static func get_mortar_plan(ingredients: Array[InventorySlot], vial: InventorySlot) -> Dictionary:
	var items: Array[ItemData] = []
	for stack in ingredients:
		if not stack.is_empty():
			items.append(stack.item)
	if vial.is_empty():
		if items.is_empty():
			return {"kind": "", "text": Language.translate("Leg etwas in den Mörser.")}
		if items.size() > 1:
			return {"kind": "", "text": Language.translate("Zum Zerkleinern nur eine Zutat hineinlegen, für einen Trank eine Phiole dazu.")}
		var dust_data: DustData = ContentDB.dust_from(items[0])
		if dust_data == null:
			return {"kind": "", "text": Language.translate("%s lässt sich nicht zerkleinern.") % items[0].display_name}
		return {"kind": "dust", "dust": dust_data}
	if items.is_empty():
		return {"kind": "", "text": Language.translate("Leg die Zutaten für den Trank dazu.")}
	var potion_plan: Dictionary = find_potion_plan(items)
	if not potion_plan.is_empty():
		return {"kind": "potion", "potion": potion_plan["potion"], "strong": potion_plan["strong"]}
	var brew: BrewData = find_brew(items)
	if brew:
		return {"kind": "brew", "brew": brew}
	return {"kind": "fail"}


## Uses up one piece of each placed stack and the vial; returns the result (dust, potion or ash),
## null if nothing can be made. The caller makes room for it first. `stir`: grade of the stirring
## minigame (potions and brews), `day`: the day it is brewed (full moon).
static func grind(ingredients: Array[InventorySlot], vial: InventorySlot, stir: Stir, day: int) -> InventorySlot:
	var plan: Dictionary = get_mortar_plan(ingredients, vial)
	var result := InventorySlot.new()
	result.amount = 1
	match plan["kind"]:
		"dust":
			var source: InventorySlot = ingredients.filter(func(stack: InventorySlot) -> bool: return not stack.is_empty())[0]
			result.item = (plan["dust"] as DustData).item
			result.rarity = source.rarity
		"potion":
			var groups: Array = []
			for stack in ingredients:
				if not stack.is_empty():
					groups.append([int(stack.rarity)])
			result.item = (plan["potion"] as PotionData).item
			var tiers: int = get_potion_bonus_tiers(plan.get("strong", false), day) + STIR_TIERS[stir]
			result.rarity = _shift(Crafting.roll_mixed_rarity(groups), tiers, result.item.base_rarity)
		"brew":
			var brew: BrewData = plan["brew"]
			result.item = brew.item
			result.rarity = _shift(get_brew_rarity(brew, ingredients), STIR_TIERS[stir], result.item.base_rarity)
		"fail":
			result.item = ContentDB.mortar_item("failed")
			result.rarity = result.item.base_rarity
		_:
			return null
	for stack in ingredients:
		_use_one(stack)
	_use_one(vial)
	return result


## Tiers an enchanting potion gets before stirring: its crystal twice, brewed on a full moon.
static func get_potion_bonus_tiers(strong: bool, day: int) -> int:
	return (STRONG_TIERS if strong else 0) + (FULL_MOON_TIERS if GameCalendar.is_full_moon(day) else 0)


## `rarity` moved by `tiers` (up to mythic), never below `lowest`.
static func _shift(rarity: Rarity.Tier, tiers: int, lowest: Rarity.Tier) -> Rarity.Tier:
	return clampi(int(rarity) + tiers, int(lowest), Rarity.Tier.MYTHIC) as Rarity.Tier


static func _use_one(stack: InventorySlot) -> void:
	if stack.is_empty():
		return
	stack.amount -= 1
	if stack.amount <= 0:
		stack.clear()


# --- Enchanting -------------------------------------------------------------------

## Level of the enchantment a potion of this rarity gives (R1 = 1).
static func get_level(rarity: Rarity.Tier) -> int:
	return int(rarity) + 1


## Enchanting potions and quality potions (both go into the potion slot of the tab).
## True if `item` does something in the mortar: it grinds into a dust, is a dust, a potion plant
## or crystal, or an ingredient of a brew (for the mortar's picker list; any other item still
## fits the slot and gives ash with a vial).
static func is_mortar_ingredient(item: ItemData) -> bool:
	if item == null:
		return false
	if ContentDB.dust_from(item) or ContentDB.dust_of_item(item):
		return true
	for potion in ContentDB.get_potions():
		if item in [potion.crystal, potion.crystal2, potion.plant]:
			return true
	for brew in ContentDB.get_brews():
		if brew.ingredients.has(item):
			return true
	return false


static func is_potion(item: ItemData) -> bool:
	return ContentDB.potion_of_item(item) != null or is_quality_potion(item) or is_reroll_potion(item)


static func is_quality_potion(item: ItemData) -> bool:
	return item != null and item.quality_points > 0


static func is_reroll_potion(item: ItemData) -> bool:
	return item != null and not item.reroll.is_empty()


## Rolls `target` anew with a reroll potion of this kind (no potion is used up here).
static func reroll(target: InventorySlot, kind: String) -> void:
	match kind:
		"attributes":
			target.bonus_attributes = Rarity.roll_attributes(target.rarity)
		"sockets":
			for i in target.sockets.size():
				var socket: Socket = Socket.roll_for(target.item)
				if socket != null:
					target.sockets[i] = socket


## "Stärke +4, Weisheit +2" / "Wucht 3: …, Glut 1: …" for the preview and the status text.
static func describe_rolled(target: InventorySlot, kind: String) -> String:
	var parts: PackedStringArray = []
	if kind == "attributes":
		for attribute: ItemAttribute in target.bonus_attributes:
			parts.append("%s %+d" % [Language.translate(ItemAttribute.NAMES[attribute.type]), attribute.value])
	else:
		for socket: Socket in target.sockets:
			parts.append(socket.get_text())
	return ", ".join(parts)


## Why `target` can't be enchanted with `potion` ("" = it can).
static func get_blocker(target: InventorySlot, potion: InventorySlot) -> String:
	if target.is_empty():
		return Language.translate("Leg links eine Waffe oder ein Rüstungsteil hinein.")
	if not (target.item.is_weapon() or target.item.is_armor()):
		return Language.translate("Nur Waffen und Rüstung lassen sich verzaubern.")
	if target.hot:
		return Language.translate("Erst im Wassertrog abkühlen.")
	if potion.is_empty():
		return Language.translate("Leg rechts einen Verzauberungstrank hinein.")
	if is_reroll_potion(potion.item):
		if potion.item.reroll == "attributes" and target.bonus_attributes.is_empty():
			return Language.translate("%s hat keine Zufalls-Attribute (die gibt es ab Ungewöhnlich).") % target.get_display_name()
		if potion.item.reroll == "sockets" and target.sockets.is_empty():
			return Language.translate("%s hat keinen Sockel.") % target.get_display_name()
		return ""
	if is_quality_potion(potion.item):
		var top: int = Rarity.Tier.MYTHIC * ForgeQuality.POINTS_PER_TIER + ForgeQuality.MAX_QUALITY
		return Language.translate("%s ist schon so gut wie möglich.") % target.get_display_name() if ForgeQuality.get_total(target) >= top else ""
	var potion_data: PotionData = ContentDB.potion_of_item(potion.item)
	if potion_data == null:
		return Language.translate("Das ist kein Verzauberungstrank.")
	var bonus: SocketBonus = potion_data.get_bonus_for(target.item)
	if bonus == null or not bonus.fits(target.item):
		return Language.translate("%s wirkt nicht auf %s.") % [potion_data.display_name, target.item.display_name]
	return ""


## The enchantment `potion` would give `target` (null = not possible).
static func preview(target: InventorySlot, potion: InventorySlot) -> Socket:
	if get_blocker(target, potion) != "":
		return null
	var bonus: SocketBonus = ContentDB.potion_of_item(potion.item).get_bonus_for(target.item)
	return Socket.create(bonus, get_level(potion.rarity))


## Enchants `target` (replacing an older enchantment) and uses up one potion. false = not possible.
## The caller counts the achievements (get_counters) and sets the story flag.
static func enchant(target: InventorySlot, potion: InventorySlot) -> bool:
	var socket: Socket = preview(target, potion)
	if socket == null:
		return false
	target.enchantment = socket
	_use_one(potion)
	return true


## Achievement counters of one enchanting with a potion of this rarity.
static func get_counters(rarity: Rarity.Tier) -> Array[String]:
	var counters: Array[String] = ["enchant"]
	if rarity >= Rarity.Tier.LEGENDARY:
		counters.append("enchant:legendary")
	return counters


## Text of the tab's preview: the enchantment (and the one it replaces) or what a quality potion
## gives ("Qualität +115: Fein · Qualität 30 » Ungewöhnlich · Qualität 45"); else why not.
static func get_preview_text(target: InventorySlot, potion: InventorySlot) -> String:
	var blocker: String = get_blocker(target, potion)
	if blocker != "":
		return blocker
	if is_reroll_potion(potion.item):
		var text: String = Language.translate("Attribute neu würfeln. Jetzt: %s") if potion.item.reroll == "attributes" 				else Language.translate("Sockel neu würfeln. Jetzt: %s")
		return text % describe_rolled(target, potion.item.reroll)
	if is_quality_potion(potion.item):
		var after: InventorySlot = target.copy_with_amount(1)
		ForgeQuality.add(after, potion.item.get_quality_points(potion.rarity))
		return Language.translate("Qualität %+d: %s » %s") % [potion.item.get_quality_points(potion.rarity),
				ForgeQuality.describe(target.rarity, target.quality), ForgeQuality.describe(after.rarity, after.quality)]
	var text: String = preview(target, potion).get_text()
	if target.enchantment:
		text += "\nErsetzt: %s" % target.enchantment.get_text()
	return text


## Uses the potion on `target`: enchants it or (quality potion) raises its quality. Returns the
## status text, "" if it is not possible.
static func use_potion(target: InventorySlot, potion: InventorySlot) -> String:
	if is_reroll_potion(potion.item):
		if get_blocker(target, potion) != "":
			return ""
		var kind: String = potion.item.reroll
		reroll(target, kind)
		_use_one(potion)
		return Language.translate("Neu gewürfelt: %s") % describe_rolled(target, kind)
	if is_quality_potion(potion.item):
		if get_blocker(target, potion) != "":
			return ""
		var gained: int = ForgeQuality.add(target, potion.item.get_quality_points(potion.rarity))
		_use_one(potion)
		return Language.translate("%s: Qualität %+d, jetzt %s.") % [target.get_display_name(), gained, ForgeQuality.describe(target.rarity, target.quality)]
	if not enchant(target, potion):
		return ""
	return Language.translate("%s ist jetzt verzaubert: %s") % [target.get_display_name(), target.enchantment.get_text()]
