class_name ItemTooltip
extends RefCounted
## Builds the hover tooltip of an item slot:
## name (rarity color), rarity, how it is held (weapon type), damage (weapons, in the colour of its damage kind) or armor,
## magic damage, crit, resistances, attributes, effect, sockets, quality, description, value.
## Holding Shift shows the details: how the damage is split and what each part brings.

const WIDTH: float = 140.0
const FONT_SIZE: int = 11
const SMALL_FONT_SIZE: int = 11
const COLOR_STAT: Color = Color(0.92, 0.9, 0.82)
const COLOR_ATTRIBUTE: Color = Color(0.55, 0.85, 0.45)
const COLOR_EFFECT: Color = Color(0.95, 0.75, 0.35)
## Weapon history lines (warm parchment colour).
const COLOR_HISTORY: Color = Color(0.95, 0.8, 0.55)
const COLOR_MUTED: Color = Color(0.62, 0.6, 0.56)
const COLOR_SOCKET: Color = Color(0.55, 0.8, 0.95)
const COLOR_UPGRADE: Color = Color(0.49, 0.76, 0.35)
const COLOR_ENCHANT: Color = Color(0.78, 0.6, 1.0)
## Effect of a jewel from the jewel table (and what a crystal can give there).
const COLOR_JEWEL: Color = Color(1.0, 0.62, 0.78)
const COLOR_NEXT: Color = Color(0.85, 0.72, 0.5)
## Names of the stations in the "Weiter:" hint (RecipeData.station -> name).
const STATION_NAMES: Dictionary = {
	&"forge": "Gussofen", &"anvil": "Amboss", &"workbench": "Werkbank",
	&"enchanting_table": "Zaubertisch", &"bow_table": "Bogentisch",
}
## At most this many results are named per station ("Werkbank: Schwert, Dolch, Axt ...").
const MAX_NEXT_RESULTS: int = 3


## `extra`: BBCode lines added at the end (e.g. a merchant's price).
static func create(slot: InventorySlot, extra: String = "") -> Control:
	var details: String = build_text(slot, true) if has_details(slot) else ""
	var normal: String = build_text(slot)
	if not extra.is_empty():
		normal += "\n" + extra
		if not details.is_empty():
			details += "\n" + extra
	return RichTooltip.create(normal, details, WIDTH)


## Where the item goes next in the smithy, e.g. "Glühend – weiter am Amboss",
## "Weiter: Schmelze", "Weiter: Werkbank (Schwert, Dolch)". Only known recipes name their
## result. "" = nowhere.
static func get_next_step(slot: InventorySlot) -> String:
	var item: ItemData = slot.item
	# Cast blanks (hot_<part>_blank) are forged at the anvil.
	for recipe in ContentDB.get_station_recipes(&"anvil"):
		if not recipe.ingredients.is_empty() and recipe.ingredients[0].matches(item):
			return Language.translate("Glühend – weiter am Amboss schmieden")
	if slot.hot:
		return Language.translate("Glühend – im Wassertrog abkühlen")
	var parts: Array[String] = []
	if item.smelt_result:
		parts.append(Language.translate("Schmelze"))
	if item.tan_result:
		parts.append(Language.translate("Gerberbank"))
	if Jewelry.is_band(item) or Jewelry.is_crystal(item):
		parts.append(Language.translate("Juweliertisch"))
	# Station -> names of the known results it makes from this item.
	var results: Dictionary = {}
	for recipe in ContentDB.get_all_recipes():
		if recipe.station == &"anvil" or not STATION_NAMES.has(recipe.station):
			continue
		if not recipe.ingredients.any(func(ingredient: Ingredient) -> bool: return ingredient.matches(item)):
			continue
		if not results.has(recipe.station):
			results[recipe.station] = []
		var name: String = recipe.get_display_name()
		if GameState.is_recipe_unlocked(recipe) and not results[recipe.station].has(name):
			results[recipe.station].append(name)
	for station: StringName in results:
		var names: Array = results[station]
		var text: String = Language.translate(STATION_NAMES[station])
		if not names.is_empty():
			text += " (%s%s)" % [", ".join(names.slice(0, MAX_NEXT_RESULTS)), " ..." if names.size() > MAX_NEXT_RESULTS else ""]
		parts.append(text)
	if parts.is_empty():
		return ""
	return Language.translate("Weiter: ") + " · ".join(parts)


## Only weapons, armor and items with combat values have a detail view.
static func has_details(slot: InventorySlot) -> bool:
	var item: ItemData = slot.item
	return item.is_weapon() or item.is_armor() or item.damage_max > 0 or item.armor > 0 \
			or not slot.get_resistances().is_empty() or slot.get_magic_damage_max() > 0


static func build_text(slot: InventorySlot, detailed: bool = false) -> String:
	var item: ItemData = slot.item
	var lines: Array[String] = []
	var rarity_color: Color = Rarity.get_color(slot.rarity)
	lines.append(_colored("[b]%s[/b]" % slot.get_display_name(), rarity_color))
	var rarity_text: String = Rarity.get_display_name(slot.rarity)
	# Quality 0-100 inside the rarity (ForgeQuality) for what can be forged or made.
	if slot.has_quality():
		rarity_text += Language.translate(" · Qualität %d") % slot.quality
	lines.append(_colored("[font_size=%d]%s[/font_size]" % [SMALL_FONT_SIZE, rarity_text], rarity_color))
	if item.weapon_type:
		lines.append(_colored(item.weapon_type.get_hands_name(), COLOR_MUTED))
		if not item.weapon_type.classes.is_empty():
			lines.append(_colored(Language.translate("Für: ") + item.weapon_type.get_classes_text(), COLOR_MUTED))
		if item.is_weapon() and not is_equal_approx(item.get_attack_speed(), 1.0):
			lines.append(_colored(Language.translate("Angriffstempo %d %%") % roundi(item.get_attack_speed() * 100.0), COLOR_STAT))
	var split: Dictionary = DamageKinds.normalized(slot.get_damage_split())
	if item.is_weapon() or item.damage_max > 0:
		var damage_text: String = _colored(Language.translate("Schaden %d-%d") % [slot.get_damage_min(), slot.get_damage_max()], COLOR_STAT)
		if split.size() > 1 or not split.has(DamageKinds.PHYSICAL):
			damage_text += " · " + DamageKinds.split_text(split)
		lines.append(damage_text)
	elif item.is_armor() or item.armor > 0:
		lines.append(_colored(Language.translate("Rüstungswert %d") % slot.get_armor(), COLOR_STAT))
	if slot.get_magic_resistance() > 0:
		lines.append(DamageKinds.colored(Language.translate("Magieresistenz +%d") % slot.get_magic_resistance(), DamageKinds.MAGIC))
	if slot.get_magic_damage_max() > 0:
		lines.append(DamageKinds.colored(Language.translate("Magieschaden %d-%d") % [slot.get_magic_damage_min(), slot.get_magic_damage_max()], DamageKinds.MAGIC))
	if slot.get_crit_chance() > 0.0:
		lines.append(_colored(Language.translate("Krit-Chance +%d %%") % roundi(slot.get_crit_chance() * 100.0), COLOR_STAT))
	if slot.get_crit_damage() > 0.0:
		lines.append(_colored(Language.translate("Krit-Schaden +%d %%") % roundi(slot.get_crit_damage() * 100.0), COLOR_STAT))
	for line in CombatRules.penetration_lines(slot.get_penetration()):
		lines.append(_colored(line, COLOR_STAT))
	var resistances: Dictionary = slot.get_resistances()
	for kind: String in resistances:
		lines.append(DamageKinds.colored("%s-Resistenz %+d" % [DamageKinds.get_display_name(kind), roundi(resistances[kind])], kind))
	if slot.get_mining_damage() > 0:
		lines.append(_colored(Language.translate("Abbau-Schaden +%d") % slot.get_mining_damage(), COLOR_STAT))
	if slot.get_chopping_damage() > 0:
		lines.append(_colored(Language.translate("Holz-Schaden +%d") % slot.get_chopping_damage(), COLOR_STAT))
	if slot.get_inventory_slots() > 0:
		lines.append(_colored(Language.translate("Inventar +%d Plätze (im Rucksack-Platz des Schmieds)") % slot.get_inventory_slots(), COLOR_STAT))
	if slot.get_water_capacity() > 0 and slot.item.type == ItemData.ItemType.WATERING_CAN:
		lines.append(_colored(Language.translate("Wasser: %d/%d (am Wasserhahn im Gewächshaus füllen)") % [slot.water, slot.get_water_capacity()], COLOR_STAT))
	elif slot.get_water_capacity() > 0:
		lines.append(_colored(Language.translate("Gießkanne: %d Wasser pro Füllung") % slot.get_water_capacity(), COLOR_STAT))
	if slot.item.forge_quality > 0:
		lines.append(_colored(Language.translate("Qualität beim Schmieden +%d %% (im Handschuh-Platz des Schmieds)") % slot.item.forge_quality, COLOR_STAT))
	if slot.item.minigame_calm > 0:
		lines.append(_colored(Language.translate("Minispiele %d %% langsamer (im Handschuh-Platz des Schmieds)") % slot.item.minigame_calm, COLOR_STAT))
	if slot.get_move_speed() > 0:
		lines.append(_colored(Language.translate("Lauftempo +%d %% (nur für den Schmied)") % slot.get_move_speed(), COLOR_STAT))
	if slot.get_element() != Element.Type.NONE:
		lines.append(_colored(Language.translate("Element: %s") % Element.get_display_name(slot.get_element()), Element.get_color(slot.get_element())))
	# Without sockets: they have their own "Sockel:" line, otherwise the bonus would show twice.
	for attribute in slot.get_attributes(false):
		lines.append(_colored("%s: %+d" % [attribute.get_display_name(), attribute.value], COLOR_ATTRIBUTE))
	if item.effect != "":
		lines.append(_colored(item.effect, COLOR_EFFECT))
	for socket in slot.sockets:
		lines.append(_colored(Language.translate("Sockel: %s") % socket.get_text(), COLOR_SOCKET))
	if slot.enchantment:
		lines.append(_colored(Language.translate("Verzaubert: %s") % slot.enchantment.get_text(), COLOR_ENCHANT))
	if slot.jewel_crystal:
		lines.append(_colored("%s: %s" % [slot.jewel_crystal.display_name,
				Jewelry.format(slot.jewel_effect, slot.get_jewel_value())], COLOR_JEWEL))
	var potion: PotionData = ContentDB.potion_of_item(item)
	if potion:
		lines.append(_colored(Language.translate("Zaubertisch » Verzaubern:\n%s") % potion.describe(slot.rarity), COLOR_ENCHANT))
	if slot.get_upgrade():
		lines.append(_colored(slot.get_upgrade().describe(slot.upgrade_rarity), COLOR_UPGRADE))
	if Jewelry.is_crystal(item):
		for kind: String in item.jewel_effects:
			var names: Array[String] = []
			for stat: String in item.jewel_effects[kind]:
				names.append(Language.translate(Jewelry.STAT_NAMES.get(stat, stat)))
			lines.append(_colored(Language.translate("Juweliertisch » %s: %s") % [Language.translate("Ring") if kind == "ring" else Language.translate("Amulett"), ", ".join(names)], COLOR_JEWEL))
	if slot.is_quiver():
		var places: Array[InventorySlot] = slot.get_quiver_slots()
		for index in slot.get_quiver_shot_order():
			var place: InventorySlot = places[index]
			var text: String = "leer" if place.is_empty() else "%d× %s (%s)" % [place.amount, place.get_display_name(),
					Rarity.get_display_name(place.rarity)]
			if not place.is_empty() and place.get_upgrade():
				text += ", " + place.get_upgrade().display_name.to_lower()
			lines.append(_colored("%s: %s" % [InventorySlot.QUIVER_PLACE_NAMES[index].capitalize(), text], COLOR_STAT))
	if slot.sharpened:
		lines.append(_colored(Language.translate("Poliert") if slot.item.is_armor() else Language.translate("Geschärft"), COLOR_STAT))
	if slot.quality_potion_used:
		lines.append(_colored(Language.translate("Mondglanz"), COLOR_STAT))
	# Weapon history: when it was made, its kills and bosses (InventorySlot.history).
	for line in slot.get_history_lines():
		lines.append(_colored("[i]%s[/i]" % line, COLOR_HISTORY))
	var next_step: String = get_next_step(slot)
	if not next_step.is_empty():
		lines.append(_colored(next_step, COLOR_NEXT))
	if not slot.components.is_empty():
		var part_names: PackedStringArray = []
		for part in slot.components:
			part_names.append(part.display_name)
		lines.append(_colored(Language.translate("Aus: %s") % " + ".join(part_names), COLOR_MUTED))
	if item.description != "":
		lines.append(_colored("[i]%s[/i]" % item.description, COLOR_MUTED))
	lines.append(_colored(Language.translate("[font_size=%d]Wert: %d Gold[/font_size]") % [SMALL_FONT_SIZE, item.value], COLOR_MUTED))
	if detailed:
		lines.append_array(_get_detail_lines(slot, split))
	elif has_details(slot):
		lines.append(_colored(Language.translate("Shift: Details"), COLOR_MUTED))
	return "\n".join(lines)


## Shift view: damage per kind, what the parts and the rarity bring, how defenses work.
static func _get_detail_lines(slot: InventorySlot, split: Dictionary) -> Array[String]:
	var item: ItemData = slot.item
	var lines: Array[String] = ["", _colored(Language.translate("Details"), COLOR_EFFECT)]
	if item.is_weapon() or item.damage_max > 0:
		lines.append(Language.translate("Schaden pro Art:"))
		for kind: String in split:
			lines.append("  " + DamageKinds.colored("%s %s-%s (%d %%)" % [DamageKinds.get_display_name(kind),
					_number(slot.get_damage_min() * split[kind]), _number(slot.get_damage_max() * split[kind]),
					roundi(split[kind] * 100.0)], kind))
		for part in slot.components:
			if part.damage_max > 0:
				lines.append(_colored("  %s: %d-%d" % [part.display_name, part.damage_min, part.damage_max], COLOR_MUTED))
		var rarity_bonus: int = Rarity.get_stat_bonus(slot.rarity)
		if rarity_bonus > 0:
			lines.append(_colored(Language.translate("  Seltenheit: +%d") % rarity_bonus, COLOR_MUTED))
		lines.append(_colored(Language.translate("Physischer Schaden wird durch Rüstung verringert, Element- und Magieschaden durch Resistenzen."), COLOR_MUTED))
	if item.is_armor() or item.armor > 0:
		lines.append(_colored(Language.translate("Rüstung wirkt nur gegen physischen Schaden (Stich, Stumpf, Schnitt)."), COLOR_MUTED))
	if not slot.get_resistances().is_empty():
		lines.append(_colored(Language.translate("Resistenz R: Schaden × 100 / (100 + R)."), COLOR_MUTED))
	return lines


## 3.5 -> "3,5", 4.0 -> "4".
static func _number(value: float) -> String:
	return DamageKinds.format_number(value)


static func _colored(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]
