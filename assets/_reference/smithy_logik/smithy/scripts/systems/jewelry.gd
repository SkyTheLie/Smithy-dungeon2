class_name Jewelry
extends RefCounted
## Jewel table: a crystal (items.json "jewel", e.g. a ruby) is set into a ring band or an amulet band
## (silver ring / silver amulet). Rings get one offensive effect, amulets one defensive effect,
## picked at random from the (up to 3) effects the crystal has for that kind, e.g. a ruby ring:
## lifesteal, crit damage or element damage. The jewel's rarity comes from band and crystal like at
## the workbench (Crafting.roll_mixed_rarity, 50/50 rule), its quality from the band; the effect is
## the crystal's value times the rarity factor (economy.json "jewelry" "rarity_factor": R1 x1 ... R8 x4).
## Effects are hero passive values (Hero.get_passive_value), so fights use them like passive skills.
## Settings: economy.json "jewelry" (result items, rarity factors).

const KINDS: Array[String] = ["ring", "amulet"]
## Effect id (= hero passive value) -> text with the value (%s). Rings: offensive, amulets: defensive.
const STATS: Dictionary = {
	"lifesteal": "Lebensraub +%s %%",
	"armor_pen": "Rüstungsdurchdringung +%s %%",
	"magic_pen": "Magiedurchdringung +%s %%",
	"crit_chance": "Krit-Chance +%s %%",
	"crit_damage": "Krit-Schaden +%s %%",
	"stun_chance": "Betäubungs-Chance +%s %%",
	"cooldown": "Abklingzeiten −%s %%",
	"pet_damage": "Schaden der Beschwörungen +%s %%",
	"damage_element": "Elementschaden +%s %%",
	"damage_poison": "Giftschaden +%s %%",
	"damage_slash": "Schnittschaden +%s %%",
	"damage_blunt": "Stumpfschaden +%s %%",
	"mana_regen": "Mana +%s/s",
	"debuff_chance": "Debuff-Chance +%s %%",
	"tenacity": "Zähigkeit +%s %%",
	"evasion": "Ausweichen +%s %%",
	"health_regen": "Erholung +%s %% Leben/s",
	"max_health": "Max. Leben +%s %%",
	"armor": "Rüstung +%s %%",
	"heal_power": "Heilkraft +%s %%",
	"shield_power": "Schildkraft +%s %%",
	"element_resist": "Element-Resistenzen +%s",
	"buff_duration": "Buff-Dauer +%s %%",
}
## Short names for lists (the jewel table), same ids as STATS.
const STAT_NAMES: Dictionary = {
	"lifesteal": "Lebensraub", "armor_pen": "Rüstungsdurchdringung", "magic_pen": "Magiedurchdringung",
	"crit_chance": "Krit-Chance", "crit_damage": "Krit-Schaden", "stun_chance": "Betäubung",
	"cooldown": "Abklingzeiten", "pet_damage": "Beschwörungs-Schaden", "damage_element": "Elementschaden",
	"damage_poison": "Giftschaden", "damage_slash": "Schnittschaden", "damage_blunt": "Stumpfschaden",
	"mana_regen": "Mana pro Sekunde", "debuff_chance": "Debuff-Chance", "tenacity": "Zähigkeit",
	"evasion": "Ausweichen", "health_regen": "Erholung", "max_health": "Max. Leben", "armor": "Rüstung",
	"heal_power": "Heilkraft", "shield_power": "Schildkraft", "element_resist": "Element-Resistenzen",
	"buff_duration": "Buff-Dauer",
}


static func settings() -> Dictionary:
	return ContentDB.economy("jewelry")


## "ring" for ring bands, "amulet" for amulet bands, "" for anything else.
static func get_kind(band: ItemData) -> String:
	if band == null:
		return ""
	match band.part_type:
		ItemData.PartType.RING_BAND:
			return "ring"
		ItemData.PartType.AMULET_BAND:
			return "amulet"
	return ""


static func is_band(item: ItemData) -> bool:
	return get_kind(item) != ""


static func is_crystal(item: ItemData) -> bool:
	return item != null and not item.jewel_effects.is_empty()


## The finished item for a band kind (economy.json "jewelry" "ring_item" / "amulet_item").
static func get_result_item(kind: String) -> ItemData:
	var id: String = str(settings().get(kind + "_item", "jewel_" + kind))
	return ContentDB.item(id) if ContentDB.has_item(id) else null


## Factor on a crystal's value for this rarity (economy.json "jewelry" "rarity_factor").
static func get_rarity_factor(rarity: int) -> float:
	var factors: Array = settings().get("rarity_factor", [1.0])
	return float(factors[clampi(rarity, 0, factors.size() - 1)])


## Factor on a crystal's value for the metal of the band (economy.json "jewelry" "metal_factor",
## e.g. silver 1, palladium 1.6); 1 without a band or for a metal that is not listed.
static func get_metal_factor(band: ItemData) -> float:
	if band == null:
		return 1.0
	return float(settings().get("metal_factor", {}).get(band.material_id, 1.0))


## Value of an effect on a jewel of this rarity and band, rounded to one decimal (0 = the crystal
## does not have this effect for this kind).
static func get_value(crystal: ItemData, kind: String, stat: String, rarity: int, band: ItemData = null) -> float:
	var base: float = float(crystal.jewel_effects.get(kind, {}).get(stat, 0.0))
	return snappedf(base * get_rarity_factor(rarity) * get_metal_factor(band), 0.1)


## "Lebensraub +3 %"
static func format(stat: String, value: float) -> String:
	return str(Language.translate(STATS[stat])) % DamageKinds.format_number(value) if STATS.has(stat) else "%s +%s" % [stat, DamageKinds.format_number(value)]


## Why the two can't be joined ("" = they can).
static func get_blocker(band: InventorySlot, crystal: InventorySlot) -> String:
	if band.is_empty():
		return Language.translate("Leg links eine Ring- oder Amulettfassung hinein.")
	if not is_band(band.item):
		return Language.translate("Links gehört eine Ring- oder Amulettfassung hinein.")
	if band.hot:
		return Language.translate("Erst im Wassertrog abkühlen.")
	if crystal.is_empty():
		return Language.translate("Leg rechts einen Kristall hinein (z. B. einen Rubin).")
	if not is_crystal(crystal.item):
		return Language.translate("Das ist kein Kristall für Schmuck.")
	if crystal.item.jewel_effects.get(get_kind(band.item), {}).is_empty():
		return Language.translate("%s passt nicht in diese Fassung.") % crystal.item.display_name
	if get_result_item(get_kind(band.item)) == null:
		return Language.translate("Unbekanntes Schmuckstück.")
	return ""


## Chances of the jewel's rarity: {tier: probability 0-1} (50/50 rule of band and crystal).
static func get_rarity_chances(band: InventorySlot, crystal: InventorySlot) -> Dictionary:
	return Crafting.get_mixed_rarity_chances([[int(band.rarity)], [int(crystal.rarity)]])


## What the jewel can get, for the table: one line per effect with the values for the lowest and
## highest possible rarity, e.g. ["Lebensraub +2,5–3 %", ...], each effect equally likely.
static func describe_options(band: InventorySlot, crystal: InventorySlot) -> Array[String]:
	var lines: Array[String] = []
	var kind: String = get_kind(band.item)
	var tiers: Array = get_rarity_chances(band, crystal).keys()
	tiers.sort()
	for stat: String in crystal.item.jewel_effects.get(kind, {}):
		var low: float = get_value(crystal.item, kind, stat, tiers.front(), band.item)
		var high: float = get_value(crystal.item, kind, stat, tiers.back(), band.item)
		var number: String = DamageKinds.format_number(low)
		if not is_equal_approx(low, high):
			number += "–" + DamageKinds.format_number(high)
		if not STATS.has(stat):
			push_error("Jewelry: unknown stat '%s' in jewel_effects of %s." % [stat, crystal.item.id])
			continue
		lines.append(str(Language.translate(STATS[stat])) % number)
	return lines


## Joins one band and one crystal (both used up) into a ring or amulet with a random effect of the
## crystal. Returns the new jewel (not yet in the inventory), null if it is not possible.
static func make(band: InventorySlot, crystal: InventorySlot) -> InventorySlot:
	if get_blocker(band, crystal) != "":
		return null
	var kind: String = get_kind(band.item)
	var rarity: Rarity.Tier = Crafting.roll_mixed_rarity([[int(band.rarity)], [int(crystal.rarity)]])
	var components: Array[ItemData] = [band.item]
	var jewel: InventorySlot = Crafting.create_result(get_result_item(kind), 1, band.quality, rarity, components)
	jewel.jewel_crystal = crystal.item
	jewel.jewel_effect = crystal.item.jewel_effects[kind].keys().pick_random()
	jewel.crafted = true
	for stack: InventorySlot in [band, crystal]:
		stack.amount -= 1
		if stack.amount <= 0:
			stack.clear()
	return jewel
