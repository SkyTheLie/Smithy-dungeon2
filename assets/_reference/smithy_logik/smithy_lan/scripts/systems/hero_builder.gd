class_name HeroBuilder
extends RefCounted
## Builds a ready hero from a plan (data/content/arena.json "builds"): class, level, attribute
## points spread by the plan's weights, skill points in the plan's order, and a full set of one
## metal at one rarity (helmet to cloak, weapon, shield or second weapon). Used for the opponents
## of Kahn's hero tournament (HeroTournament); the same rules as the balancing simulator
## (assets/_reference/balancing/sim_party.gd).

const ATTRIBUTE_KEYS: Dictionary = {"str": ItemAttribute.Type.STRENGTH, "agi": ItemAttribute.Type.AGILITY,
		"con": ItemAttribute.Type.CONSTITUTION, "int": ItemAttribute.Type.INTELLIGENCE,
		"wis": ItemAttribute.Type.WISDOM, "res": ItemAttribute.Type.RESISTANCE}
const WEAPON_PARTS: Dictionary = {"sword": ["blade", "handle"], "hammer": ["hammer_head", "shaft"],
		"dagger": ["dagger_blade", "handle"], "two_handed_sword": ["greatsword_blade", "handle"]}


## A new hero. `build_id` = key of arena.json "builds"; `look` = Appearance (null = random from
## `seed_text` and `race`); `weights` = attribute weights instead of the plan's (e.g. a champion).
static func make(build_id: String, display_name: String, level: int, metal: String, rarity: int,
		race: String, seed_text: String, look: Appearance = null, weights: Dictionary = {}) -> Hero:
	var builds: Dictionary = ContentDB.arena().get("builds", {})
	var build: Dictionary = builds.get(build_id, builds.get("warrior", {}))
	var hero := Hero.new()
	hero.id = StringName("arena_" + seed_text)
	hero.display_name = display_name
	hero.hero_class = HeroClass.load_class(str(build.get("class", build_id)))
	hero.race = race
	hero.appearance = look if look else Appearance.from_seed(seed_text, race)
	hero.level = level
	_spend_attributes(hero, weights if not weights.is_empty() else build.get("attributes", {"str": 1}))
	_spend_skills(hero, build.get("skills", []))
	_equip(hero, build, metal, rarity)
	return hero


## Spreads the free points by the weights (str 2 : con 1 = two of three points into strength).
static func _spend_attributes(hero: Hero, weights: Dictionary) -> void:
	var total_weight: int = 0
	for key: String in weights:
		total_weight += int(weights[key])
	if total_weight <= 0:
		return
	for i in hero.get_free_attribute_points():
		var slot: int = i % total_weight
		for key: String in weights:
			slot -= int(weights[key])
			if slot < 0:
				hero.raise_attribute(ATTRIBUTE_KEYS[key])
				break


## Learns the skills in the plan's order, again and again, until no point is left (skills that
## can't be learned yet are skipped).
static func _spend_skills(hero: Hero, order: Array) -> void:
	var learned_any: bool = true
	while hero.get_free_skill_points() > 0 and learned_any:
		learned_any = false
		for skill_id: String in order:
			if hero.get_free_skill_points() <= 0:
				break
			var skill: SkillData = ContentDB.skill(skill_id)
			if skill and hero.learn_skill(skill):
				learned_any = true


static func _piece(item_id: String, parts: Array, rarity: int, amount: int = 1) -> InventorySlot:
	var components: Array[ItemData] = []
	for part: String in parts:
		components.append(ContentDB.item(part))
	return Crafting.create_result(ContentDB.item(item_id), amount, 0, rarity as Rarity.Tier, components)


static func _equip(hero: Hero, build: Dictionary, metal: String, rarity: int) -> void:
	var S := Hero.EquipmentSlot
	var leather: String = "leather" if metal == "copper" else "wolf_leather"
	for entry: Array in [[S.HELMET, "helmet", "helmet_plate"], [S.ARMOR, "chest_armor", "chest_plate"],
			[S.SHOULDERS, "shoulder_armor", "shoulder_plate"], [S.LEGS, "leg_armor", "leg_plate"],
			[S.BOOTS, "boots", "boot_plate"], [S.GLOVES, "gloves", "glove_plate"]]:
		hero.equipment[entry[0]] = _piece(entry[1], [metal + "_" + entry[2], leather], rarity)
	hero.equipment[S.CLOAK] = _piece("leather_cloak", [leather, leather, leather], rarity)
	match str(build.get("weapon", "sword")):
		"staff":
			var staff: String = "wooden_staff" if metal == "copper" else metal + "_staff_" + str(build.get("staff", "fire"))
			if not ContentDB.has_item(staff):
				staff = metal + "_staff_fire"
			hero.equipment[S.RIGHT_HAND] = Crafting.create_result(ContentDB.item(staff), 1, 0, rarity as Rarity.Tier)
		"bow":
			hero.equipment[S.RIGHT_HAND] = _piece("bow", [metal + "_bow_frame"], rarity)
			hero.equipment[S.LEFT_HAND] = _piece("arrows", [metal + "_arrow_tip", metal + "_arrow_shaft"], rarity, 999)
		var weapon:
			hero.equipment[S.RIGHT_HAND] = _piece(weapon, _weapon_parts(weapon, metal), rarity)
	if build.get("shield", false):
		hero.equipment[S.LEFT_HAND] = _piece("shield", [metal + "_shield_plate", metal + "_handle"], rarity)
	elif build.has("offhand"):
		var offhand: String = str(build["offhand"])
		hero.equipment[S.LEFT_HAND] = _piece(offhand, _weapon_parts(offhand, metal), rarity)


static func _weapon_parts(weapon: String, metal: String) -> Array:
	var parts: Array = []
	for part: String in WEAPON_PARTS.get(weapon, ["blade", "handle"]):
		parts.append(metal + "_" + part)
	return parts
