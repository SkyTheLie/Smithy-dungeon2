class_name Hero
extends Resource
## A hero. As .tres in res://data/heroes/ it is a hireable template; GameState.heroes holds
## the hired copies (GameState.hire_hero). Emits the built-in `changed` signal when equipment,
## skills or attributes change.
## Combat values come from CombatRules (data/content/combat.json). Attributes: every hero starts
## with combat.json "start_attribute" (5) in each, plus the class bonus (HeroClass.attribute_bonuses),
## +1 to all per "levels_per_attribute_bonus" (4) levels, plus spent points and equipment.
## The attribute values in templates / guild offers are no longer used.
## Level-ups give attribute points (reaching an even level 1, an odd level 2) and every
## LEVELS_PER_SKILL_POINT levels a skill point; skills have levels (SkillData.max_level).
## Skills are in the three trees of the class (HeroClass.get_trees); deeper skills need points
## already spent in the same tree (SkillData.required_points). Passive skills add their values
## to the getters below (get_passive_value).

enum EquipmentSlot { HELMET, SHOULDERS, CLOAK, ARMOR, LEFT_HAND, RIGHT_HAND, LEGS, BOOTS, NECKLACE, RING_1, RING_2, GLOVES }

const SLOT_NAMES: Array[String] = ["Helm", "Schulter", "Umhang", "Rüstung", "Linke Hand", "Rechte Hand",
		"Beine", "Stiefel", "Halskette", "Ring 1", "Ring 2", "Handschuhe"]
## Names used in save files (stay the same even if the enum order changes).
const SLOT_KEYS: Array[String] = ["helmet", "shoulders", "cloak", "armor", "left_hand", "right_hand",
		"legs", "boots", "necklace", "ring_1", "ring_2", "gloves"]
## Item types each slot accepts (same order as EquipmentSlot).
const SLOT_ITEM_TYPES: Array = [
	[ItemData.ItemType.HELMET],
	[ItemData.ItemType.SHOULDERS],
	[ItemData.ItemType.CLOAK],
	[ItemData.ItemType.ARMOR],
	[ItemData.ItemType.SHIELD, ItemData.ItemType.WEAPON, ItemData.ItemType.ARROWS, ItemData.ItemType.QUIVER],
	[ItemData.ItemType.WEAPON],
	[ItemData.ItemType.LEGS],
	[ItemData.ItemType.BOOTS],
	[ItemData.ItemType.NECKLACE, ItemData.ItemType.ACCESSORY],
	[ItemData.ItemType.RING],
	[ItemData.ItemType.RING],
	[ItemData.ItemType.GLOVES],
]
## Old saves had 5 slots: weapon, helmet, armor, boots, accessory.
const OLD_SLOTS: Array[EquipmentSlot] = [EquipmentSlot.RIGHT_HAND, EquipmentSlot.HELMET, EquipmentSlot.ARMOR,
		EquipmentSlot.BOOTS, EquipmentSlot.NECKLACE]

## Experience per level (exponential, max level 100), balanced in the .tres file.
const LEVEL_TABLE: LevelTable = preload("res://data/hero_level_table.tres")
## Every N levels the hero gets one skill point (level 2, 4, 6 ... = 50 points at level 100).
const LEVELS_PER_SKILL_POINT: int = 2
## Potions for heroes (ItemData.hero_potion), see use_potion.
const HERO_POTIONS: Array[String] = ["skill_point", "attribute_point", "reset_skills", "reset_attributes", "iq", "level_up"]

@export var id: StringName
@export var display_name: String = "":
	get:
		return custom_name if not custom_name.is_empty() else Language.translate(display_name)
## Name the player gave the hero in his window (set_custom_name). Empty = his own name.
## Storage (not shown in the inspector) so duplicates of a hired hero keep it.
@export_storage var custom_name: String = ""
@export var hero_class: HeroClass
@export var level: int = 1
## Stamina (Ausdauer) 0..get_max_stamina(): every dungeon costs some (DungeonData.stamina_cost),
## it comes back by the hour and over night (GameState, numbers in combat.json).
var stamina: float = 100.0
## Experience collected towards the next level.
@export var experience: int = 0
## Fixed portrait (optional). Empty = head of the generated look (see get_portrait).
@export var portrait: Texture2D
## Race of the generated look (id from appearance.json). Empty = random (but always the same
## for this hero, the look is generated from the id).
@export var race: String = ""
## Look of the hero. Empty in templates: generated from id and race (get_appearance).
@export var appearance: Appearance

## Skill points in one tree from which the hero wears that tree's role outfit (skill_trees.json
## "outfit", see get_role_tree).
const ROLE_OUTFIT_POINTS: int = 10
## Cache of the look dressed in the role outfit (see _dressed).
var _dressed_look: Appearance
var _dressed_key: String = ""
## One-time price for hiring (later calculated from stats and rarity).
@export var hire_cost: int = 50

@export_group("Attributes (unused, see get_base_attribute)")
@export var strength: int = 1
@export var agility: int = 1
@export var constitution: int = 1
@export var intelligence: int = 1
@export var wisdom: int = 1
@export var resistance: int = 1

## Equipped items: EquipmentSlot -> InventorySlot (amount 1). Empty for templates.
@export var equipment: Dictionary = {}
## Learned skills: SkillData.id -> level. Empty for templates.
@export var learned_skills: Dictionary = {}
## Attribute points spent: ItemAttribute.Type -> points. Empty for templates.
@export var attribute_points: Dictionary = {}
## Intelligence for commands (SkillCommand): from 80 simple commands, 100 more specific ones,
## 120 all. -1 = combat.json "hero_start_iq" (60). Later raised by items, potions and books.
@export var iq: int = -1
## Commands per learned skill: SkillData.id -> SkillCommand Dictionary.
@export var skill_commands: Dictionary = {}
## Role in the fight (HeroRole id, "" = none: random targets), chosen in the hero window.
@export var role: String = ""
## Skills the player switched off (skill id -> true): the hero does not use them in dungeons.
## Needs no IQ (unlike the commands).
@export var disabled_skills: Dictionary = {}
## Extra skill / attribute points on top of the level ones (from potions, use_potion).
@export var bonus_skill_points: int = 0
@export var bonus_attribute_points: int = 0
## Template this hero was hired from (res://data/heroes/...), set by GameState.hire_hero.
## Used to rebuild the hero when a save is loaded.
var template_path: String = ""


# --- Attributes ---------------------------------------------------------------

## Start value + class bonus + level bonus + the points the player put in.
func get_base_attribute(type: ItemAttribute.Type) -> int:
	return get_natural_attribute(type) + attribute_points.get(type, 0)


## Without spent points: start value (5) + class bonus + 1 per 4 levels.
func get_natural_attribute(type: ItemAttribute.Type) -> int:
	var class_bonus: int = int(hero_class.attribute_bonuses.get(type, 0)) if hero_class else 0
	return CombatRules.start_attribute() + class_bonus + CombatRules.level_attribute_bonus(level)


## Attribute bonus from all equipped items.
func get_equipment_attribute(type: ItemAttribute.Type) -> int:
	var total: int = 0
	for stack: InventorySlot in equipment.values():
		for attribute in stack.get_attributes():
			if attribute.type == type:
				total += attribute.value
	return total


func get_attribute(type: ItemAttribute.Type) -> int:
	return get_base_attribute(type) + get_equipment_attribute(type)


## Attribute points earned up to the current level: reaching an even level gives 1,
## an odd level 2 (level 2: 1, level 3: 2, level 4: 1 ...).
## Plus the extra points from potions (bonus_attribute_points).
func get_attribute_points_total() -> int:
	var total: int = bonus_attribute_points
	for reached in range(2, level + 1):
		total += 1 if reached % 2 == 0 else 2
	return total


func get_free_attribute_points() -> int:
	var spent: int = 0
	for points: int in attribute_points.values():
		spent += points
	return get_attribute_points_total() - spent


## Puts one free point into an attribute (permanently). Returns false without free points.
func raise_attribute(type: ItemAttribute.Type) -> bool:
	if get_free_attribute_points() <= 0:
		return false
	attribute_points[type] = attribute_points.get(type, 0) + 1
	emit_changed()
	return true


# --- Derived values -------------------------------------------------------------

func _attribute(type: ItemAttribute.Type) -> float:
	return float(get_attribute(type))


## Health from level and constitution (+ strength and wisdom per 10), mana from intelligence.
func get_max_health() -> int:
	var health: int = CombatRules.hero_max_health(_attribute(ItemAttribute.Type.STRENGTH),
			_attribute(ItemAttribute.Type.CONSTITUTION), _attribute(ItemAttribute.Type.WISDOM), level)
	return roundi(health * (1.0 + get_passive_value("max_health") / 100.0)) + get_smith_health_bonus()


## Skill "Feldschmied" of the player: extra health while every piece the hero wears was made by
## the player (InventorySlot.crafted), at least one piece. 0 otherwise.
func get_smith_health_bonus() -> int:
	var worn: int = 0
	for slot in equipment:
		var stack: InventorySlot = equipment[slot]
		if stack == null or stack.is_empty():
			continue
		if not stack.crafted:
			return 0
		worn += 1
	if worn == 0:
		return 0
	var tree := Engine.get_main_loop() as SceneTree
	var game_state: Node = tree.root.get_node_or_null("GameState") if tree else null
	return game_state.player_stats.get_crafted_gear_health() if game_state else 0


## Mana from intelligence and level (combat.json "mana_per_level").
func get_max_mana() -> int:
	return CombatRules.hero_max_mana(_attribute(ItemAttribute.Type.INTELLIGENCE), level)


## Per second: constitution + passive skills (% of max health and flat).
func get_health_regen() -> float:
	return CombatRules.hero_health_regen(_attribute(ItemAttribute.Type.CONSTITUTION)) \
			+ get_max_health() * get_passive_value("health_regen") / 100.0 + get_passive_value("health_regen_flat")


func get_mana_regen() -> float:
	return CombatRules.hero_mana_regen(_attribute(ItemAttribute.Type.INTELLIGENCE), _attribute(ItemAttribute.Type.WISDOM)) \
			+ get_passive_value("mana_regen")


## Base damage of every hero (combat.json, 1-3); the weapon and strength are added on top.
func get_base_damage_min() -> int:
	return int(CombatRules.value("hero_base_damage_min", 1))


func get_base_damage_max() -> int:
	return int(CombatRules.value("hero_base_damage_max", 3))


## The weapon in the right hand (null = bare hands).
func get_weapon() -> InventorySlot:
	return get_equipped(EquipmentSlot.RIGHT_HAND)


## The arrows shot next (null = none): the stack in the left hand, or with a quiver the next
## filled place of the quiver (right place first, then left, then the 3rd).
func get_arrows() -> InventorySlot:
	var left: InventorySlot = get_equipped(EquipmentSlot.LEFT_HAND)
	if left == null:
		return null
	if left.item.type == ItemData.ItemType.ARROWS:
		return left
	if left.is_quiver():
		return left.get_next_quiver_arrows()
	return null


## The quiver in the left hand (null = none).
func get_quiver() -> InventorySlot:
	var left: InventorySlot = get_equipped(EquipmentSlot.LEFT_HAND)
	return left if left and left.is_quiver() else null


## One arrow was shot: the stack gets smaller; an empty stack is taken off the hand, an empty
## place in the quiver stays free.
func use_arrow() -> void:
	var arrows: InventorySlot = get_arrows()
	if arrows == null:
		return
	arrows.amount -= 1
	if arrows.amount <= 0:
		if get_quiver():
			arrows.clear()
			emit_changed()
		else:
			unequip(EquipmentSlot.LEFT_HAND)
	else:
		emit_changed()


## Seconds between two basic hits: combat.json "hero_attack_interval" divided by the attack
## speed of the weapon type (dagger 1.4 = faster, two-handed sword 0.7 = slower) and its attack
## speed bonus (feather potion, +10 % = 1.1 times as fast).
func get_attack_interval() -> float:
	var weapon: InventorySlot = get_weapon()
	var speed: float = 1.0
	if weapon:
		speed = weapon.item.get_attack_speed() * (1.0 + weapon.get_socket_total(SocketBonus.Effect.ATTACK_SPEED) / 100.0)
	return CombatRules.value("hero_attack_interval", 1.0) / speed


## True if the right hand holds a two-handed weapon (then the left hand must stay empty).
func holds_two_handed() -> bool:
	var weapon: InventorySlot = get_weapon()
	return weapon != null and weapon.item.is_two_handed()


## Damage of a basic hit without strength: base + weapon (Combatant adds strength when hitting).
func get_weapon_damage_min() -> int:
	var weapon: InventorySlot = get_weapon()
	return get_base_damage_min() + (weapon.get_damage_min() if weapon else 0)


func get_weapon_damage_max() -> int:
	var weapon: InventorySlot = get_weapon()
	return get_base_damage_max() + (weapon.get_damage_max() if weapon else 0)


## Damage of a basic hit: base + weapon + strength, with a bow also the arrows (without arrows
## the bow only hits for "no_arrow_damage_factor", like in Combatant.roll_hit).
func get_damage_min() -> int:
	return _with_arrows(get_weapon_damage_min() + CombatRules.strength_damage(_attribute(ItemAttribute.Type.STRENGTH)), true)


func get_damage_max() -> int:
	return _with_arrows(get_weapon_damage_max() + CombatRules.strength_damage(_attribute(ItemAttribute.Type.STRENGTH)), false)


func _with_arrows(damage: int, use_min: bool) -> int:
	var weapon: InventorySlot = get_weapon()
	if weapon == null or not weapon.item.uses_arrows():
		return damage
	var arrows: InventorySlot = get_arrows()
	if arrows == null:
		return int(damage * CombatRules.value("no_arrow_damage_factor", 0.25))
	return damage + (arrows.get_damage_min() if use_min else arrows.get_damage_max())


## Flat magic damage of spells: base damage + magic damage of the weapon (staff 5-7).
func get_magic_damage_min() -> int:
	var weapon: InventorySlot = get_weapon()
	return get_base_damage_min() + (weapon.get_magic_damage_min() if weapon else 0)


func get_magic_damage_max() -> int:
	var weapon: InventorySlot = get_weapon()
	return get_base_damage_max() + (weapon.get_magic_damage_max() if weapon else 0)


## Factor on spells from intelligence (1.1 = +10 %).
func get_magic_damage_factor() -> float:
	return CombatRules.magic_damage_factor(_attribute(ItemAttribute.Type.INTELLIGENCE))


func get_heal_power() -> float:
	return CombatRules.heal_power(_attribute(ItemAttribute.Type.WISDOM), get_passive_value("heal_power"))


func get_shield_power() -> float:
	return CombatRules.shield_power(_attribute(ItemAttribute.Type.WISDOM), get_passive_value("shield_power"))


func get_evasion() -> float:
	return CombatRules.evasion(_attribute(ItemAttribute.Type.AGILITY), get_passive_value("evasion") / 100.0)


func get_tenacity() -> float:
	return CombatRules.tenacity(_attribute(ItemAttribute.Type.RESISTANCE), get_passive_value("tenacity") / 100.0)


## Cooldown reduction and longer buffs: from passive skills (later also items).
func get_cooldown_reduction() -> float:
	return CombatRules.cooldown_reduction(get_passive_value("cooldown") / 100.0)


func get_buff_duration_bonus() -> float:
	return get_passive_value("buff_duration") / 100.0


## Resistances of everything equipped: DamageKinds id -> value (without the RES attribute).
func get_resistances() -> Dictionary:
	var totals: Dictionary = {}
	for slot in equipment:
		var stack_resistances: Dictionary = (equipment[slot] as InventorySlot).get_resistances()
		for kind: String in stack_resistances:
			totals[kind] = totals.get(kind, 0.0) + stack_resistances[kind]
	var element_bonus: float = get_passive_value("element_resist")
	if element_bonus != 0.0:
		for kind: String in DamageKinds.ELEMENT_KINDS:
			totals[kind] = totals.get(kind, 0.0) + element_bonus
	var race_resistances: Dictionary = get_race_data().get("hero_resistances", {})
	for kind: String in race_resistances:
		totals[kind] = totals.get(kind, 0.0) + float(race_resistances[kind])
	return totals


## Resistances including the RES attribute (+1 per point to every kind).
func get_total_resistances() -> Dictionary:
	return CombatRules.resistances_with_attribute(get_resistances(), _attribute(ItemAttribute.Type.RESISTANCE))


## Extra crit chance / crit damage of the equipment (0.05 = +5 %).
func get_crit_chance_bonus() -> float:
	var total: float = get_passive_value("crit_chance") / 100.0
	for slot in equipment:
		total += (equipment[slot] as InventorySlot).get_crit_chance()
	return total


func get_crit_damage_bonus() -> float:
	var total: float = get_passive_value("crit_damage") / 100.0
	for slot in equipment:
		total += (equipment[slot] as InventorySlot).get_crit_damage()
	return total


## Armor / magic penetration of everything equipped (CombatRules.penetration).
func get_penetration() -> Dictionary:
	var total: Dictionary = CombatRules.penetration(get_passive_value("armor_pen") / 100.0, 0.0, get_passive_value("magic_pen") / 100.0)
	for slot in equipment:
		total = CombatRules.add_penetration(total, (equipment[slot] as InventorySlot).get_penetration())
	return total


## Crit chance (0..1) and crit damage factor without buffs (formulas: CombatRules).
func get_crit_chance() -> float:
	return CombatRules.crit_chance(_attribute(ItemAttribute.Type.AGILITY), get_crit_chance_bonus())


func get_crit_damage() -> float:
	return CombatRules.crit_damage(get_crit_damage_bonus())


## Base armor (combat.json, 5) + everything equipped except weapons. Reduces physical damage.
func get_armor() -> int:
	var total: int = int(CombatRules.value("hero_base_armor", 5))
	for slot in equipment:
		var stack: InventorySlot = equipment[slot]
		# The leather of a quiver does not protect.
		if not stack.item.is_weapon() and not stack.is_quiver():
			total += stack.get_armor()
	return roundi(total * (1.0 + get_passive_value("armor") / 100.0))


## Base magic resistance (combat.json, 0) + equipment. Reduces all magic damage.
func get_magic_resistance() -> int:
	var total: int = int(CombatRules.value("hero_base_magic_resistance", 0))
	for slot in equipment:
		total += (equipment[slot] as InventorySlot).get_magic_resistance()
	return total


func get_max_level() -> int:
	return LEVEL_TABLE.get_max_level()


## Experience needed for the next level (0 at the max level).
func get_experience_to_next_level() -> int:
	return LEVEL_TABLE.get_experience_to_next(level)


## Adds experience and levels up as often as it reaches the next level (up to the max level).
func add_experience(amount: int) -> void:
	experience += amount
	var old_level: int = level
	while level < get_max_level() and experience >= get_experience_to_next_level():
		experience -= get_experience_to_next_level()
		level += 1
	if level > old_level:
		var game_state: Node = (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
		game_state.show_message(Language.translate("%s erreicht Level %d!") % [display_name, level])
		game_state.get_node("/root/AudioManager").play_sound("level_up")
	if level >= get_max_level():
		experience = 0
	emit_changed()


# --- Skills ---------------------------------------------------------------------

func get_skill_points_total() -> int:
	return floori(level / float(LEVELS_PER_SKILL_POINT)) + bonus_skill_points


## Points in skills of the class (skills that are no longer in its trees don't count).
func get_skill_points_spent() -> int:
	var spent: int = 0
	for skill in get_learned_skills():
		spent += get_skill_rank(skill)
	return spent


## Points spent in one tree of the class (index in HeroClass.get_trees).
func get_points_in_tree(tree_index: int) -> int:
	var trees: Array = hero_class.get_trees()
	if tree_index < 0 or tree_index >= trees.size():
		return 0
	var spent: int = 0
	for skill: SkillData in trees[tree_index]["skills"]:
		spent += get_skill_rank(skill)
	return spent


func get_free_skill_points() -> int:
	return get_skill_points_total() - get_skill_points_spent()


## Level of a skill (0 = not learned).
func get_skill_rank(skill: SkillData) -> int:
	return learned_skills.get(skill.id, 0)


## Why the skill cannot be learned / raised right now ("" = it can).
func get_learn_blocker(skill: SkillData) -> String:
	var tree_index: int = hero_class.get_tree_index(skill)
	if tree_index < 0:
		return Language.translate("Gehört nicht zu dieser Klasse")
	if get_skill_rank(skill) >= skill.max_level:
		return Language.translate("Höchste Stufe erreicht")
	if get_points_in_tree(tree_index) < skill.required_points:
		return Language.translate("Ab %d Punkten in %s (bisher %d)") % [skill.required_points, hero_class.get_trees()[tree_index]["name"],
				get_points_in_tree(tree_index)]
	for required: SkillData in [skill.get_required_skill(), skill.get_extra_required_skill()]:
		if required and get_skill_rank(required) == 0:
			return Language.translate("Benötigt %s") % required.display_name
	if get_free_skill_points() <= 0:
		return Language.translate("Kein Skillpunkt frei")
	return ""


## IQ for the skill commands and the player's focus (see iq).
func get_iq() -> int:
	return iq if iq >= 0 else int(CombatRules.value("hero_start_iq", 60))


## Most extra skill points a hero can get from potions (combat.json "hero_max_bonus_skill_points").
static func get_max_bonus_skill_points() -> int:
	return int(CombatRules.value("hero_max_bonus_skill_points", 3))


## Most extra attribute points a hero can get from potions (combat.json "hero_max_bonus_attribute_points").
static func get_max_bonus_attribute_points() -> int:
	return int(CombatRules.value("hero_max_bonus_attribute_points", 6))


## Highest IQ potions can raise a hero to (combat.json "hero_max_iq").
static func get_max_iq() -> int:
	return int(CombatRules.value("hero_max_iq", 150))


## The role the hero fights with: his chosen one if his IQ is enough for it, else none ("").
func get_role() -> String:
	return role if HeroRole.ROLES.has(role) and get_iq() >= HeroRole.required_iq(role) else ""


## Chooses a role; false if the IQ is too low for it.
func set_role(new_role: String) -> bool:
	if not HeroRole.ROLES.has(new_role) or get_iq() < HeroRole.required_iq(new_role):
		return false
	role = new_role
	changed.emit()
	return true


## Whether the hero uses this learned skill in dungeons (switched on, the default).
func is_skill_enabled(skill: SkillData) -> bool:
	return not disabled_skills.has(skill.id)


func set_skill_enabled(skill: SkillData, enabled: bool) -> void:
	if enabled:
		disabled_skills.erase(skill.id)
	else:
		disabled_skills[skill.id] = true
	changed.emit()


func get_skill_command(skill: SkillData) -> Dictionary:
	return skill_commands.get(skill.id, {})


## Sets the command of a skill; an empty / "Standard" command removes it. false if the hero's IQ is
## too low for it.
func set_skill_command(skill: SkillData, command: Dictionary) -> bool:
	if SkillCommand.is_empty(command):
		skill_commands.erase(skill.id)
		changed.emit()
		return true
	if get_iq() < SkillCommand.required_iq(command):
		return false
	skill_commands[skill.id] = command.duplicate()
	changed.emit()
	return true


## Why a potion (Hero.HERO_POTIONS) does nothing for this hero right now ("" = it works).
func get_potion_blocker(kind: String) -> String:
	match kind:
		"reset_skills":
			return Language.translate("%s hat noch keine Skills gelernt.") % display_name if learned_skills.is_empty() else ""
		"reset_attributes":
			return Language.translate("%s hat noch keine Attributpunkte verteilt.") % display_name if attribute_points.is_empty() else ""
		"skill_point":
			return Language.translate("%s hat schon %d Tränke des Wissens getrunken, mehr verträgt kein Held.") % [display_name, get_max_bonus_skill_points()] 					if bonus_skill_points >= get_max_bonus_skill_points() else ""
		"attribute_point":
			return Language.translate("%s hat schon %d Tränke der Stärkung getrunken, mehr verträgt kein Held.") % [display_name, get_max_bonus_attribute_points()] 					if bonus_attribute_points >= get_max_bonus_attribute_points() else ""
		"iq":
			return Language.translate("%s ist schon so klug wie möglich.") % display_name if get_iq() >= get_max_iq() else ""
		"level_up":
			return Language.translate("%s hat schon das höchste Level.") % display_name if level >= get_max_level() else ""
	return Language.translate("Unbekannter Trank.")


## Drinks a potion: +1 skill point, +1 attribute point, all skills / spent attribute points back
## (the points are free again; skill commands and switched-off skills are forgotten too), or
## +`amount` IQ ("iq", at most get_max_iq), or exactly one level more ("level_up", admin potion:
## the experience is filled up to the next level, what was left over is gone). false if it does nothing (get_potion_blocker).
func use_potion(kind: String, amount: int = 1) -> bool:
	if get_potion_blocker(kind) != "":
		return false
	match kind:
		"skill_point":
			bonus_skill_points += 1
		"attribute_point":
			bonus_attribute_points += 1
		"reset_skills":
			learned_skills.clear()
			skill_commands.clear()
			disabled_skills.clear()
		"reset_attributes":
			attribute_points.clear()
		"iq":
			iq = mini(get_iq() + amount, get_max_iq())
		"level_up":
			add_experience(maxi(get_experience_to_next_level() - experience, 0))
			experience = 0
	emit_changed()
	return true


func learn_skill(skill: SkillData) -> bool:
	if get_learn_blocker(skill) != "":
		return false
	learned_skills[skill.id] = get_skill_rank(skill) + 1
	emit_changed()
	return true


## Skills of the class trees the hero has learned (active ones are used automatically in fights).
func get_learned_skills() -> Array[SkillData]:
	var skills: Array[SkillData] = []
	if hero_class == null:
		return skills
	for skill in hero_class.get_skills():
		if get_skill_rank(skill) > 0:
			skills.append(skill)
	return skills


## Sum of a value of all learned passive skills at their level, e.g. "armor" = 24 (%), plus the
## bonus of the hero's race (appearance.json "hero_bonus", same names, e.g. dogs "max_health": 10).
## Passives that need a weapon only count while the hero holds one. Rings and amulets from the
## jewel table add their effect (Jewelry, e.g. a ruby ring: "lifesteal" 3).
## Some grow with an attribute (SkillData.passive_scaling, e.g. Ätzende Gifte with intelligence).
func get_passive_value(stat: String) -> float:
	var total: float = float(get_race_data().get("hero_bonus", {}).get(stat, 0.0))
	for skill in get_learned_skills():
		if skill.is_passive() and skill.passive.has(stat) and can_use_skill(skill):
			var attributes: Dictionary = {}
			for type: int in skill.passive_scaling.get(stat, {}):
				attributes[type] = get_attribute(type)
			total += skill.get_passive_value(stat, get_skill_rank(skill), attributes)
	for slot in equipment:
		total += (equipment[slot] as InventorySlot).get_jewel_stat(stat)
	return total


## Weapon types learned passive skills allow for this hand ("right_hand" / "left_hand"),
## SkillData.unlock_weapons.
func get_unlocked_weapon_types(hand: String) -> Array:
	var types: Array = []
	for skill in get_learned_skills():
		types.append_array(skill.unlock_weapons.get(hand, []))
	return types


# --- Equipment --------------------------------------------------------------------

func get_equipped(slot: EquipmentSlot) -> InventorySlot:
	return equipment.get(slot)


## Two-handed weapons only go into the right hand, and nothing goes into the left hand while
## the right one holds a two-handed weapon. Weapons only for the classes of their weapon type
## (weapon_types.json "classes", e.g. bows only rangers).
func can_equip(slot: EquipmentSlot, item: ItemData) -> bool:
	if item == null or not (SLOT_ITEM_TYPES[slot] as Array).has(item.type):
		return false
	if not can_use_weapon_type(item, slot):
		return false
	# Arrows and quivers go into the left hand, also next to a two-handed bow.
	if item.type in [ItemData.ItemType.ARROWS, ItemData.ItemType.QUIVER]:
		return true
	if slot == EquipmentSlot.LEFT_HAND and (item.is_two_handed() or holds_two_handed()):
		return false
	return true


## Skills with "requires_weapon" only work while one hand holds such a weapon type (e.g. shield
## bash needs a shield, so a warrior with a two-handed sword can't use it).
func can_use_skill(skill: SkillData) -> bool:
	if skill.required_weapon_types.is_empty():
		return true
	for slot in [EquipmentSlot.RIGHT_HAND, EquipmentSlot.LEFT_HAND]:
		var stack: InventorySlot = get_equipped(slot)
		if stack and stack.item.weapon_type and skill.required_weapon_types.has(String(stack.item.weapon_type.id)):
			return true
	return false


## false if the item's weapon type is not for this hero's class. A skill of the class can lock a
## weapon type for one hand until it is learned (SkillData.unlock_weapons, e.g. the rogue's
## "Schwertkunst": swords in the right hand, "Zwei Schwerter": also in the left); slot -1 = either hand.
func can_use_weapon_type(item: ItemData, slot: int = -1) -> bool:
	if item.weapon_type == null or hero_class == null:
		return true
	if not item.weapon_type.allows_class(String(hero_class.id)):
		return false
	var type_id: String = String(item.weapon_type.id)
	if slot != EquipmentSlot.LEFT_HAND and _hand_allows(type_id, "right_hand"):
		return true
	return slot != EquipmentSlot.RIGHT_HAND and _hand_allows(type_id, "left_hand")


## Whether this hand may hold the weapon type: yes, unless a skill of the class unlocks it for
## this hand and the hero hasn't learned such a skill.
func _hand_allows(type_id: String, hand: String) -> bool:
	var locked: bool = hero_class.get_skills().any(func(skill: SkillData) -> bool:
			return (skill.unlock_weapons.get(hand, []) as Array).has(type_id))
	return not locked or get_unlocked_weapon_types(hand).has(type_id)


## Puts `stack` (amount 1) into the slot. Returns the item that was there before (or null).
func equip(slot: EquipmentSlot, stack: InventorySlot) -> InventorySlot:
	var previous: InventorySlot = get_equipped(slot)
	equipment[slot] = stack
	emit_changed()
	return previous


## Takes the item out of the slot and returns it (or null).
func unequip(slot: EquipmentSlot) -> InventorySlot:
	var previous: InventorySlot = get_equipped(slot)
	equipment.erase(slot)
	emit_changed()
	return previous


# --- Look -------------------------------------------------------------------------

## The hero's look; generated from the id the first time (same id = same face).
## Look of the hero as shown (world, portrait, fights): his own look, dressed in the outfit of his
## role once he has ROLE_OUTFIT_POINTS points in one tree (get_role_tree). Fixed looks (Bruno) keep
## their figure; their battle look gets the outfit (get_battle_look).
func get_appearance() -> Appearance:
	var own: Appearance = get_own_appearance()
	if own.is_fixed():
		return own
	return _dressed(own)


## The hero's own look (race, hair, clothes he was hired with), saved with him.
func get_own_appearance() -> Appearance:
	if appearance == null:
		appearance = Appearance.from_seed(String(id), race)
	return appearance


## Look in the battle window: the outfit's battle figure (Bruno as a kit figure), in the role outfit.
func get_battle_look() -> Appearance:
	var own: Appearance = get_own_appearance()
	return _dressed(own.get_battle_look()) if own.is_fixed() else get_appearance()


## The tree of the hero's role: the one with the most points, once it has at least
## ROLE_OUTFIT_POINTS (ties: the first tree). {} = no role yet. Resetting the skills (potion)
## takes the points back, so the outfit goes too.
func get_role_tree() -> Dictionary:
	var best: Dictionary = {}
	var best_points: int = ROLE_OUTFIT_POINTS - 1
	if hero_class == null:
		return best
	var trees: Array = hero_class.get_trees()
	for index in trees.size():
		var points: int = get_points_in_tree(index)
		if points > best_points:
			best_points = points
			best = trees[index]
	return best


## skill_trees.json "outfit" of the role tree: {"outfit": cut id (appearance.json outfits),
## "clothes_color": colour id}, {} = none.
func get_role_outfit() -> Dictionary:
	return get_role_tree().get("outfit", {})


func _dressed(look: Appearance) -> Appearance:
	var outfit: Dictionary = get_role_outfit()
	if outfit.is_empty():
		return look
	var key: String = "%d|%s" % [look.get_instance_id(), JSON.stringify(outfit)]
	if key != _dressed_key:
		_dressed_look = Appearance.from_save_data(look.to_save_data())
		_dressed_look.outfit = str(outfit.get("outfit", look.outfit))
		_dressed_look.clothes_color = str(outfit.get("clothes_color", look.clothes_color))
		_dressed_key = key
	return _dressed_look


## Race id (appearance.json "races"): the one set for the hero, else the one of his look.
func get_race() -> String:
	return race if not race.is_empty() else get_own_appearance().race


## The race's entry in appearance.json: name, bonuses for heroes ("hero_bonus", "hero_resistances")
## and for the player ("player_bonus").
func get_race_data() -> Dictionary:
	return ContentDB.appearance_section("races").get(get_race(), {})


## e.g. "Elf: Luftschaden +8 % · Ausweichen +2 % · Resistenz gegen Luft +5" (hero windows).
func get_race_line() -> String:
	var race_name: String = get_race_data().get("name", get_race())
	var bonus: String = Appearance.get_race_hero_text(get_race())
	return race_name if bonus.is_empty() else "%s: %s" % [race_name, bonus]


func get_portrait() -> Texture2D:
	return portrait if portrait else CharacterBaker.get_portrait(get_appearance())


## What the hero wears, for CharacterBaker.get_battle_sheet: {"helmet" / "shoulders" / "cloak" /
## "armor" / "gloves" / "legs" / "boots": {"head": material id}, "weapon" / "shield": {"type": weapon type
## id, "head": material of the blade/head, "grip": material of the handle}}. Rings, necklaces and
## a weapon in the left hand are not shown.
func get_battle_gear() -> Dictionary:
	var gear: Dictionary = {}
	for slot: EquipmentSlot in [EquipmentSlot.HELMET, EquipmentSlot.SHOULDERS, EquipmentSlot.CLOAK,
			EquipmentSlot.ARMOR, EquipmentSlot.GLOVES, EquipmentSlot.LEGS, EquipmentSlot.BOOTS]:
		var stack: InventorySlot = get_equipped(slot)
		if stack:
			gear[SLOT_KEYS[slot]] = {"head": get_gear_material(stack, true)}
	var weapon: InventorySlot = get_equipped(EquipmentSlot.RIGHT_HAND)
	if weapon:
		gear["weapon"] = _get_held_gear(weapon)
	var left: InventorySlot = get_equipped(EquipmentSlot.LEFT_HAND)
	if left and left.item.type == ItemData.ItemType.SHIELD:
		gear["shield"] = _get_held_gear(left)
	return gear


func _get_held_gear(stack: InventorySlot) -> Dictionary:
	var type_id: String = stack.item.weapon_type.id if stack.item.weapon_type else "sword"
	if stack.item.type == ItemData.ItemType.SHIELD:
		type_id = "shield"
	return {"type": type_id, "head": get_gear_material(stack, true), "grip": get_gear_material(stack, false)}


## The slots that count for sets ("Goldset 5/8") and for the metal of the battle figure; the left
## hand only with a shield in it.
const SET_SLOTS: Array[EquipmentSlot] = [EquipmentSlot.HELMET, EquipmentSlot.SHOULDERS, EquipmentSlot.CLOAK,
		EquipmentSlot.ARMOR, EquipmentSlot.GLOVES, EquipmentSlot.LEGS, EquipmentSlot.BOOTS, EquipmentSlot.LEFT_HAND]
## Metal of each material tier (materials.json "tier"): leather counts as the metal of its tier
## (wolf leather = iron, hippogriff leather = silver), wood (0) as none.
const TIER_METALS: Array[String] = ["", "copper", "iron", "bronze", "silver", "gold", "platinum", "palladium"]


## Metal a set piece counts as: the material of its metal parts (the handle and leather do not
## count), leather-only pieces (cloak) by the tier of their leather. "" = no metal (wood, nothing).
static func get_set_metal(stack: InventorySlot) -> String:
	if stack == null or stack.item == null:
		return ""
	var tier: int = int(ContentDB.material_info(get_gear_material(stack, true)).get("tier", 0))
	return TIER_METALS[tier] if tier > 0 and tier < TIER_METALS.size() else ""


## {metal id: worn set pieces of it}, only metals with at least one piece.
func get_set_counts() -> Dictionary:
	var counts: Dictionary = {}
	for slot: EquipmentSlot in SET_SLOTS:
		var stack: InventorySlot = get_equipped(slot)
		if slot == EquipmentSlot.LEFT_HAND and (stack == null or stack.item.type != ItemData.ItemType.SHIELD):
			continue
		var metal: String = get_set_metal(stack)
		if not metal.is_empty():
			counts[metal] = int(counts.get(metal, 0)) + 1
	return counts


## The metal most set pieces are made of (a tie: the better metal), "" = none (no metal worn).
## The battle figure shows it (BattleFigure).
func get_lead_metal() -> String:
	var counts: Dictionary = get_set_counts()
	var best: String = ""
	for metal: String in counts:
		if best.is_empty() or counts[metal] > counts[best] \
				or (counts[metal] == counts[best] and TIER_METALS.find(metal) > TIER_METALS.find(best)):
			best = metal
	return best


## Tooltip lines of the worn sets, best metal first: "Goldset 5/8", "Silberset 3/8".
func get_set_lines() -> PackedStringArray:
	var counts: Dictionary = get_set_counts()
	var lines := PackedStringArray()
	for index in range(TIER_METALS.size() - 1, 0, -1):
		var metal: String = TIER_METALS[index]
		if counts.has(metal):
			lines.append(Language.translate("%s-Set %d/%d") % [ContentDB.material_name(metal), counts[metal], SET_SLOTS.size()])
	return lines


## Material id of the head/metal parts (`head`) or of the handle/leather parts of an item.
static func get_gear_material(stack: InventorySlot, head: bool) -> String:
	var grip_parts: Array = [ItemData.PartType.HANDLE, ItemData.PartType.SHAFT, ItemData.PartType.LEATHER]
	var fallback: String = ""
	for part in stack.components:
		if part.material_id.is_empty():
			continue
		if grip_parts.has(part.part_type) != head:
			return part.material_id
		fallback = part.material_id
	if not fallback.is_empty():
		return fallback
	return stack.item.material_id if not stack.item.material_id.is_empty() else ("iron" if head else "wood")


# --- Saving -----------------------------------------------------------------------

## Only what changes after hiring; everything else comes from the template.
## Longest name the player can give a hero (fits the hero list and the window header).
const NAME_MAX_LENGTH: int = 16


## Renames the hero (spaces at the ends are cut off); empty or the own name = his own name again.
func set_custom_name(new_name: String) -> void:
	var cleaned: String = new_name.strip_edges().left(NAME_MAX_LENGTH)
	custom_name = "" if cleaned == get_original_name() else cleaned
	emit_changed()


## The hero's own name (template or generated), whatever the player called him.
func get_original_name() -> String:
	var saved: String = custom_name
	custom_name = ""
	var original: String = display_name
	custom_name = saved
	return original


static func get_max_stamina() -> float:
	return ContentDB.combat_value("hero_max_stamina", 100.0)


## Adds stamina (negative = uses it), kept within 0..max.
func change_stamina(amount: float) -> void:
	stamina = clampf(stamina + amount, 0.0, get_max_stamina())


func to_save_data() -> Dictionary:
	var saved_equipment: Dictionary = {}
	for slot in equipment:
		saved_equipment[SLOT_KEYS[slot]] = (equipment[slot] as InventorySlot).to_save_data()
	var skills: Dictionary = {}
	for skill_id in learned_skills:
		skills[str(skill_id)] = learned_skills[skill_id]
	# German names as keys: they never change with the language.
	var points: Dictionary = {}
	for type in attribute_points:
		points[ItemAttribute.NAMES[type]] = attribute_points[type]
	var data: Dictionary = {
		"template": template_path,
		"level": level,
		"experience": experience,
		"stamina": stamina,
		"equipment": saved_equipment,
		"skills": skills,
		"attribute_points": points,
		"appearance": get_own_appearance().to_save_data(),
		"iq": iq,
		"skill_commands": _commands_to_save_data(),
		"role": role,
		"disabled_skills": disabled_skills.keys().map(func(skill_id: StringName) -> String: return str(skill_id)),
		"bonus_skill_points": bonus_skill_points,
		"bonus_attribute_points": bonus_attribute_points,
		"custom_name": custom_name,
	}
	if template_path.is_empty():
		# Generated hero (HeroOffers): there is no template file, so save what defines him.
		var attributes: Dictionary = {}
		for attribute in HeroOffers.ATTRIBUTES:
			attributes[attribute] = get(attribute)
		data["generated"] = {
			"id": String(id),
			"name": get_original_name(),
			"class": hero_class.resource_path if hero_class else "",
			"race": race,
			"hire_cost": hire_cost,
			"attributes": attributes,
		}
	return data


## Rebuilds a hired hero from its template (or, for a generated hero, from its saved "generated"
## data) and the saved data. Null if neither is there.
static func from_save_data(data: Dictionary) -> Hero:
	var hero: Hero
	var template := SaveSystem.load_resource(data.get("template", "")) as Hero
	if template:
		hero = template.duplicate()
		hero.template_path = template.resource_path
	elif data.has("generated"):
		var generated: Dictionary = data["generated"]
		hero = Hero.new()
		hero.id = StringName(generated.get("id", "hero"))
		hero.display_name = generated.get("name", "")
		hero.hero_class = SaveSystem.load_resource(generated.get("class", "")) as HeroClass
		hero.race = generated.get("race", "")
		hero.hire_cost = int(generated.get("hire_cost", 0))
		var attributes: Dictionary = generated.get("attributes", {})
		for attribute: String in attributes:
			hero.set(attribute, int(attributes[attribute]))
	else:
		return null
	hero.level = clampi(int(data.get("level", 1)), 1, hero.get_max_level())
	hero.experience = int(data.get("experience", 0))
	hero.stamina = clampf(float(data.get("stamina", get_max_stamina())), 0.0, get_max_stamina())
	hero.equipment = {}
	var saved_equipment: Dictionary = data.get("equipment", {})
	for key: String in saved_equipment:
		var stack := InventorySlot.from_save_data(saved_equipment[key])
		if stack.is_empty():
			continue
		# Slot names; old saves used numbers of the old 5-slot layout.
		var slot: int = SLOT_KEYS.find(key)
		if slot < 0 and key.is_valid_int() and int(key) < OLD_SLOTS.size():
			slot = OLD_SLOTS[int(key)]
		if slot >= 0:
			hero.equipment[slot] = stack
	# A template with a fixed figure (Bruno) keeps it; older saves have his generated look.
	if data.has("appearance") and not (template and template.appearance and template.appearance.is_fixed()):
		hero.appearance = Appearance.from_save_data(data["appearance"])
	hero.iq = int(data.get("iq", -1))
	hero.role = str(data.get("role", ""))
	hero.skill_commands = {}
	var commands: Dictionary = data.get("skill_commands", {})
	for skill_id: String in commands:
		hero.skill_commands[StringName(ContentDB.normalize_id(skill_id))] = (commands[skill_id] as Dictionary).duplicate()
	hero.disabled_skills = {}
	for skill_id: String in data.get("disabled_skills", []):
		hero.disabled_skills[StringName(ContentDB.normalize_id(skill_id))] = true
	hero.bonus_skill_points = int(data.get("bonus_skill_points", 0))
	hero.bonus_attribute_points = int(data.get("bonus_attribute_points", 0))
	hero.custom_name = str(data.get("custom_name", ""))
	hero.learned_skills = {}
	var skills: Dictionary = data.get("skills", {})
	for skill_id: String in skills:
		# Old saves may use renamed skill ids (e.g. warrior_sword_strike -> sword_strike). Skills that
		# are no longer in the class trees are dropped, their points are free again.
		var normalized: String = ContentDB.normalize_id(skill_id)
		var skill: SkillData = ContentDB.find_skill(normalized)
		if skill and hero.hero_class and hero.hero_class.has_skill(skill):
			hero.learned_skills[StringName(normalized)] = mini(int(skills[skill_id]), skill.max_level)
	hero.attribute_points = {}
	var points: Dictionary = data.get("attribute_points", {})
	for attribute_name: String in points:
		var type: int = ItemAttribute.NAMES.find(attribute_name)
		# Older saves used the translated name ("Strength") when playing in another language.
		if type < 0:
			type = ItemAttribute.NAMES.map(func(german: String) -> String: return Language.translate(german)).find(attribute_name)
		if type >= 0:
			hero.attribute_points[type] = int(points[attribute_name])
	return hero


func _commands_to_save_data() -> Dictionary:
	var saved: Dictionary = {}
	for skill_id in skill_commands:
		saved[str(skill_id)] = skill_commands[skill_id]
	return saved

