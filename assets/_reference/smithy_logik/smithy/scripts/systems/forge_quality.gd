class_name ForgeQuality
extends RefCounted
## Rarity and quality of made items (numbers: economy.json "crafting_quality").
## Every stack has a rarity (R1-R8) and a quality 0-100 inside that rarity, like experience:
## points above 100 raise the rarity by one tier (R1 Q80 + 40 = R2 Q20), points below 0 drop it
## (R3 Q0 - 20 = R2 Q80). R1 Q0 is the floor, R8 Q100 the top.
## Where the points come from:
##   - a freshly cast glowing blank starts at cast_quality (50), its rarity from the ingot
##   - other new pieces inherit rarity and quality from what they are made of (inherit)
##   - anvil: green strike +, yellow strike a little +, miss - (anvil_points)
##   - workbench: green on green +, green on yellow a little +, no colour meets: the parts lose
##     points (joining_points)
##   - grindstone: + by the time the ball stayed green in its minigame (grindstone_points)
## Gains (not losses) grow with the skill "Meisterhand" (PlayerStats.Stat.QUALITY_GAIN) and gloves
## like the master gloves (PlayerStats.get_quality_gain).
## How hard the minigames are depends on the material and the reputation (get_difficulty).

const MAX_QUALITY: int = 100
const POINTS_PER_TIER: int = 100


## The GameState autoload, looked up at runtime: Crafting and ContentDB use this class, and they
## are compiled before the autoloads exist (e.g. in headless test scripts).
static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")


static func settings() -> Dictionary:
	return ContentDB.economy("crafting_quality")


## Quality every freshly cast glowing blank starts with (economy.json "crafting_quality.cast_quality").
static func cast_quality() -> int:
	return int(settings().get("cast_quality", 50))


## Rarity and quality as one number: R1 Q0 = 0, R2 Q50 = 150, R8 Q100 = 800.
static func get_total(slot: InventorySlot) -> int:
	return slot.rarity * POINTS_PER_TIER + slot.quality


## Sets rarity and quality from a total. If the rarity changes, weapons and armor get new
## random attributes for it (Rarity.roll_attributes).
static func set_total(slot: InventorySlot, total: int) -> void:
	var top: int = Rarity.Tier.MYTHIC * POINTS_PER_TIER + MAX_QUALITY
	total = clampi(total, 0, top)
	var tier: int = mini(floori(total / float(POINTS_PER_TIER)), Rarity.Tier.MYTHIC)
	var old_tier: Rarity.Tier = slot.rarity
	slot.rarity = tier as Rarity.Tier
	slot.quality = total - tier * POINTS_PER_TIER
	if slot.rarity != old_tier and slot.item and (slot.item.is_weapon() or slot.item.is_armor()):
		slot.bonus_attributes = Rarity.roll_attributes(slot.rarity)


## Adds points (negative = loses points). Returns the points really added.
static func add(slot: InventorySlot, points: int) -> int:
	var before: int = get_total(slot)
	set_total(slot, before + points)
	return get_total(slot) - before


## A gain with the skill "Meisterhand" (losses stay as they are).
static func with_skill(points: float) -> int:
	if points <= 0.0:
		return roundi(points)
	return roundi(points * (1.0 + _game_state().player_stats.get_quality_gain()))


## Points of one anvil strike (`zone`: TimingBar.Zone) when the piece needs `strikes` strikes.
## The numbers in economy.json are for the whole piece (all strikes green = "green").
static func anvil_points(zone: int, strikes: int) -> int:
	var anvil: Dictionary = settings().get("anvil", {})
	var key: String = ["miss", "yellow", "green"][clampi(zone, 0, 2)]
	var defaults: Dictionary = {"green": 80.0, "yellow": 24.0, "miss": -48.0}
	return with_skill(float(anvil.get(key, defaults[key])) / maxi(1, strikes))


## Points a joining grade gives the assembled item (Joining.Grade: FAIL, OKAY, GOOD, PERFECT).
## For FAIL: what every part loses (nothing is built).
static func joining_points(grade: int) -> int:
	var joining: Dictionary = settings().get("joining", {})
	var key: String = ["fail", "okay", "good", "perfect"][clampi(grade, 0, 3)]
	var defaults: Dictionary = {"fail": -15.0, "okay": 0.0, "good": 20.0, "perfect": 50.0}
	return with_skill(float(joining.get(key, defaults[key])))


## Points of the grindstone when the ball stayed in the green zone for `share` (0-1) of the
## minigame (economy.json "grindstone" = all the time).
static func grindstone_points(share: float = 1.0) -> int:
	return with_skill(float(settings().get("grindstone", 50)) * clampf(share, 0.0, 1.0))


## Settings of the grindstone minigame (economy.json "grindstone_game"), with the skill
## "Meisterhand": the green zone grows and moves slower by its bonus (+15 % per rank).
## Returns {"seconds", "zone", "zone_speed", "lift", "gravity"}.
static func grindstone_game() -> Dictionary:
	var game: Dictionary = {"seconds": 6.0, "zone": 0.28, "zone_speed": 0.45, "lift": 2.6, "gravity": 2.0}
	game.merge(settings().get("grindstone_game", {}), true)
	var bonus: float = _game_state().player_stats.get_quality_gain()
	game["zone"] = minf(0.9, float(game["zone"]) * (1.0 + bonus))
	game["zone_speed"] = float(game["zone_speed"]) / (1.0 + bonus)
	return game


## Rarity and quality of a new piece made from `groups` (per recipe ingredient the stacks that
## went into it): the rarity follows the 50/50 rule of Crafting.roll_mixed_rarity, the quality is
## the average quality of the pieces. Pieces of wood, rope, feathers ... don't count as long as
## a forged piece or leather is there (a wooden shaft does not pull an iron axe down), and leather
## doesn't count as long as a forged piece is there (the plate decides, the leather is the lining).
## Returns {"rarity": Rarity.Tier, "quality": int}.
static func inherit(groups: Array) -> Dictionary:
	var counted: Array = get_counted_groups(groups)
	if counted.is_empty():
		return {"rarity": Rarity.Tier.COMMON, "quality": 0}
	var quality_sum: int = 0
	var pieces: int = 0
	for group: Array in counted:
		for stack: InventorySlot in group:
			quality_sum += stack.quality
			pieces += 1
	return {"rarity": Crafting.roll_mixed_rarity(get_rarity_groups(counted)), "quality": roundi(quality_sum / float(pieces))}


## The groups whose pieces count for the rarity (see inherit); all non-empty groups if none does.
static func get_counted_groups(groups: Array) -> Array:
	var counted: Array = []
	for group: Array in groups:
		var main: Array = group.filter(func(stack: InventorySlot) -> bool: return _counts(stack))
		if not main.is_empty():
			counted.append(main)
	if counted.is_empty():
		counted = groups.filter(func(group: Array) -> bool: return not group.is_empty())
	# Armor: with a forged plate the leather is only the lining, like the wooden shaft of an axe.
	var forged: bool = counted.any(func(group: Array) -> bool:
		return group.any(func(stack: InventorySlot) -> bool: return not _is_leather(stack)))
	if forged:
		var without_leather: Array = []
		for group: Array in counted:
			var rest: Array = group.filter(func(stack: InventorySlot) -> bool: return not _is_leather(stack))
			if not rest.is_empty():
				without_leather.append(rest)
		counted = without_leather
	return counted


static func _is_leather(stack: InventorySlot) -> bool:
	return stack != null and not stack.is_empty() and stack.item.part_type == ItemData.PartType.LEATHER


## Per group the rarities of its stacks, e.g. [[1], [0, 0]] (for Crafting.roll_mixed_rarity).
static func get_rarity_groups(groups: Array) -> Array:
	var rarity_groups: Array = []
	for group: Array in groups:
		var tiers: Array = []
		for stack: InventorySlot in group:
			tiers.append(int(stack.rarity))
		rarity_groups.append(tiers)
	return rarity_groups


## Metal, leather and alloy pieces count for the rarity of what is made from them.
static func _counts(stack: InventorySlot) -> bool:
	if stack == null or stack.is_empty():
		return false
	var item: ItemData = stack.item
	return item.material_id != "" and item.material_id != "wood" \
			or item.type == ItemData.ItemType.INGOT or item.part_type == ItemData.PartType.LEATHER


## "Gewöhnlich · Qualität 50"
static func describe(rarity: Rarity.Tier, quality: int) -> String:
	return Language.translate("%s · Qualität %d") % [Rarity.get_display_name(rarity), quality]


## Rarity of ore or ingots found as dungeon loot (economy.json "crafting_quality.loot_rarity":
## chance per tier, higher dungeons raise them by "per_dungeon_level" per level). Other items and
## no luck: their base rarity (-1).
static func roll_loot_rarity(item: ItemData, dungeon_level: int, rarity_factor: float = 1.0) -> int:
	if item.type != ItemData.ItemType.ORE and item.type != ItemData.ItemType.INGOT:
		return -1
	var loot: Dictionary = settings().get("loot_rarity", {})
	var factor: float = (1.0 + float(loot.get("per_dungeon_level", 0.0)) * dungeon_level) * rarity_factor
	var tiers: Array = loot.get("chances", {}).keys()
	tiers.sort()
	tiers.reverse()
	# Rarest first: R5, then R4 ...
	for tier_name: String in tiers:
		if randf() < float(loot["chances"][tier_name]) * factor:
			return int(tier_name.trim_prefix("R")) - 1
	return -1


# --- Lucky strike ------------------------------------------------------------------------

## Settings of the lucky strike (economy.json "lucky_strike"): "chance" (0-1), "rarity_steps"
## (tiers the rarity jumps), "socket_share" (share of the strikes that bring a socket instead) and
## "flag" (story flag of the first one, opens the skill "Glückshand").
static func lucky_settings() -> Dictionary:
	return ContentDB.economy("lucky_strike")


## Chance (0-1) of a lucky strike: economy.json "lucky_strike.chance" plus the skill "Glückshand"
## (+1 % per rank).
static func get_lucky_chance() -> float:
	var base: float = float(lucky_settings().get("chance", 0.0))
	return clampf(base + _game_state().player_stats.get_lucky_strike_bonus(), 0.0, 1.0)


## A finished piece of equipment from the workbench: with get_lucky_chance it is a lucky strike
## (apply_lucky_strike). Returns "rarity", "socket" or "" (no luck).
static func try_lucky_strike(slot: InventorySlot) -> String:
	if slot == null or slot.is_empty() or not slot.item.is_equipment():
		return ""
	if randf() >= get_lucky_chance():
		return ""
	return apply_lucky_strike(slot, randf() < float(lucky_settings().get("socket_share", 0.5)))


## The lucky strike itself: the rarity jumps "rarity_steps" tiers (quality stays, at most Mythic)
## or, with `want_socket`, the piece gets one more random socket. If the wanted one can't be done
## (Mythic already, no socket fits or all sockets full), the other one. The first lucky strike sets
## the flag that opens the skill "Glückshand"; each counts for the achievement "Glückspilz" and
## tells ItemReveal (Events.lucky_strike_struck: lightning and banner). Returns "rarity",
## "socket" or "" (neither was possible).
static func apply_lucky_strike(slot: InventorySlot, want_socket: bool) -> String:
	var settings: Dictionary = lucky_settings()
	var kind: String = ""
	var can_rise: bool = slot.rarity < Rarity.Tier.MYTHIC
	if want_socket or not can_rise:
		if slot.add_socket(Socket.roll_for(slot.item)):
			kind = "socket"
	if kind.is_empty() and can_rise:
		add(slot, int(settings.get("rarity_steps", 2)) * POINTS_PER_TIER)
		kind = "rarity"
	if kind.is_empty():
		return ""
	var state: Node = _game_state()
	state.story.set_flag(str(settings.get("flag", "lucky_strike_found")))
	state.achievements.count("lucky_strike")
	# Events is looked up at runtime like GameState (this class compiles before the autoloads).
	state.get_node("/root/Events").emit_signal("lucky_strike_struck", kind)
	return kind


# --- Difficulty --------------------------------------------------------------------------

## How hard the anvil and workbench minigames are for a material tier (ItemData.material_tier)
## at the current reputation: gap = material tier - rank index - skill "Materialkunde".
## Returns economy.json "crafting_quality.difficulty" entry: {"name", "speed" (the marker /
## parts move this much faster), "green", "yellow" (zone widths are multiplied by these)}.
static func get_difficulty(material_tier: int) -> Dictionary:
	var gap: int = material_tier - _game_state().reputation.get_rank_index() \
			- roundi(_game_state().player_stats.get_skill_bonus(PlayerStats.Stat.MATERIAL_MASTERY))
	return _with_gloves(get_difficulty_for_gap(gap))


## Gloves with "minigame_calm" in the smith's gloves slot (the sandsmith gloves from the desert)
## make the marker and the parts move that many percent slower.
static func _with_gloves(stage: Dictionary) -> Dictionary:
	var calm: int = _game_state().player_stats.get_minigame_calm()
	if calm <= 0:
		return stage
	var calmer: Dictionary = stage.duplicate()
	calmer["speed"] = float(stage.get("speed", 1.0)) * (1.0 - calm / 100.0)
	return calmer


static func get_difficulty_for_gap(gap: int) -> Dictionary:
	var stages: Array = settings().get("difficulty", [])
	for stage: Dictionary in stages:
		if gap <= int(stage.get("max_gap", 0)):
			return stage
	return stages.back() if not stages.is_empty() else {"name": Language.translate("Normal"), "speed": 1.0, "green": 1.0, "yellow": 1.0}


## Highest material tier among these stacks (the hardest material decides at the workbench;
## wolf leather counts like iron).
static func get_hardest_tier(stacks: Array) -> int:
	var tier: int = 0
	for stack: InventorySlot in stacks:
		if stack and not stack.is_empty():
			tier = maxi(tier, stack.item.material_tier)
	return tier
