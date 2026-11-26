class_name Combatant
extends RefCounted
## One fighter in an adventure (a hero or a monster). Hits every attack interval, uses its
## skills when they are ready (and there is enough mana), regenerates health and mana, and
## carries status effects (buffs/debuffs, see StatusEffectData) that tick every second and
## run out. Formulas: CombatRules.
## A hit (roll_hit) is split into damage kinds (DamageKinds, e.g. 50 % fire + 50 % slash) and
## can be critical; the target reduces every share by its armor/resistances (receive_hit).
## It also counts what it did in the fight (damage per attack/skill, effect damage, healing,
## shielding) for the battle window.


## A status effect running on this fighter.
class ActiveEffect:
	var data: StatusEffectData
	var stacks: int = 1
	var duration: float = 0.0
	var time_left: float = 0.0
	## Seconds until the next per-second tick.
	var next_tick: float = 1.0
	## Who applied it (weak, so fighters don't keep each other alive), for the statistics.
	var source: WeakRef
	## Damage this shield can still absorb.
	var shield: float = 0.0
	## Heal power of the source when it was applied (heals per second are multiplied with it).
	var heal_factor: float = 1.0

	func get_source() -> Combatant:
		return source.get_ref() if source else null


var display_name: String
var icon: Texture2D
var level: int = 1
## Monster data (sprite animation, drops); null for heroes.
var enemy_data: EnemyData
## Attributes without buffs: ItemAttribute.Type -> value (heroes: base + equipment).
var attributes: Dictionary = {}
var max_health: int
var health: float
var max_mana: int = 0
var mana: float = 0.0
## Damage of a basic hit (heroes: base + weapon, strength is added when hitting; monsters:
## their damage). Physical skills deal a share of it (e.g. 150 %).
var damage_min: int
var damage_max: int
## true = strength adds flat damage to every physical hit (heroes; monsters have fixed damage).
var adds_strength_damage: bool = false
## Flat magic damage of spells (heroes: base + magic damage of the weapon; monsters: their
## magic damage, or their normal damage if they have none).
var magic_min: int = 0
var magic_max: int = 0
## Seconds between two basic hits.
var base_attack_interval: float = 1.0
## Without buffs/debuffs (see get_armor / get_magic_resistance).
var armor: int = 0
## Reduces all magic damage (elements and pure magic), same formula as armor.
var magic_resistance: int = 0
## Armor / magic penetration of this fighter's hits from equipment (CombatRules.penetration);
## buffs and the skill are added in get_penetration().
var penetration: Dictionary = {}
## Shorter cooldowns (0.2 = 20 %) and longer buffs this fighter casts (0.2 = +20 %).
var cooldown_reduction: float = 0.0
var buff_duration_bonus: float = 0.0
var health_regen: float = 0.0
var mana_regen: float = 0.0
## All healing this fighter receives (skills, effects, regeneration) times this, e.g. 0.5 in the
## arena (ArenaDuel), where healers would otherwise never lose.
var heal_received_factor: float = 1.0
## Used automatically when ready.
var skills: Array[SkillData] = []
## SkillData -> seconds until it is ready again (0 = ready).
var skill_cooldowns: Dictionary = {}
## SkillData -> level (heroes: learned level; monsters: 1).
var skill_levels: Dictionary = {}
## Kinds of the basic hit (weapon / monster): DamageKinds id -> share.
var weapon_split: Dictionary = {DamageKinds.PHYSICAL: 1.0}
## Bows: every physical hit adds the damage of the hero's next arrow in its kinds (wood tip = stab,
## copper = slash, iron = blunt; from the left hand or the first filled place of the quiver).
## Only skill hits use the arrow up (Hero.use_arrow), basic shots are picked up again. Without
## arrows the bow only hits for combat.json "no_arrow_damage_factor" (25 %).
var uses_arrows: bool = false
## Upgrade of the weapon (upgrade table, InventorySlot.get_upgrade_values): extra damage of its
## kind on every physical hit and a chance to put its effect on the target (e.g. poison).
var weapon_upgrade: Dictionary = {}
## Monsters: effects their basic hits can apply (EnemyData.on_hit, e.g. poison 30 %).
var hit_effects: Array[Dictionary] = []
## Heroes: effects the physical hits of the weapon can apply (enchantment with a curse, e.g. burn
## 5 %, InventorySlot.get_socket_on_hit).
var weapon_on_hit: Array[Dictionary] = []
## DamageKinds id -> resistance (equipment / monster data), buffs are added in get_resistances().
var resistances: Dictionary = {}
## Extra crit chance / crit damage from equipment (0.05 = +5 %).
var crit_chance_bonus: float = 0.0
var crit_damage_bonus: float = 0.0
var effects: Array[ActiveEffect] = []
## Durations of effects this fighter applies are multiplied with this (later: items/skills
## that make e.g. poison last longer).
var effect_duration_factor: float = 1.0
## Seconds until the next basic hit.
var attack_cooldown: float = 1.0
## Hero this fighter belongs to (null for monsters).
var hero: Hero
## Hero whose hit killed this fighter (Adventure._strike; null = a monster, an effect ...), for
## the weapon history (GameState._on_enemy_defeated).
var killed_by: Hero
## Boss or mini boss of its wave (the fixed monsters of a boss stage), for the command "boss".
var is_boss: bool = false
## Back row (archers, EnemyData.back_row): single-target attacks only reach it when no fighter
## of the front row is alive (see Adventure).
var back_row: bool = false
## How many times it has called helpers so far (EnemyData.summon).
var summons_done: int = 0
## Slimes (EnemyData.split): how many times its line already split (0 = the first one), whether
## this one has split already, and its picture size compared to the monster's own.
var split_generation: int = 0
var has_split: bool = false
var size_factor: float = 1.0
## Monsters that grow back (EnemyData.regrow, the hydra's heads): down and waiting to come back,
## seconds left until then, and how many times it already came back.
var regrowing: bool = false
var regrow_left: float = 0.0
var regrow_count: int = 0
## Damage kinds that heal it instead (EnemyData.absorb): DamageKinds id -> share.
var absorb: Dictionary = {}
## Health it got back through `absorb` since Adventure last looked (shown as a heal).
var absorbed_heal: int = 0
## Bosses with more health bars (EnemyData.phases): 0 = the first bar, 1 = the first extra phase ...
var phase: int = 0
## Factors of the dungeon on this monster (scale_power), also for its next boss phases.
var health_factor: float = 1.0
var damage_factor: float = 1.0
## Shout of a phase that just began (Adventure shows it once and clears it).
var phase_text: String = ""
## Commands of the hero for his skills: SkillData -> SkillCommand Dictionary.
var commands: Dictionary = {}
## Role of the hero in the fight (HeroRole, "" = random targets) and whether he follows the
## player's focus (IQ from combat.json "iq_focus"); both only if his IQ is high enough.
var role: String = ""
var can_focus: bool = false
## Values of the hero's passive skills that only matter in a fight (Hero.get_passive_value),
## e.g. "damage_slash", "parry", "offhand": name -> value (in % like in skills.json).
var passives: Dictionary = {}
## Damage of the weapon in the left hand (heroes). Classes in combat.json "offhand_attack_classes"
## (the rogue) hit with it on their own: every offhand_attack_interval_factor basic hits, with
## offhand_attack_damage x (weapon + attribute damage); "offhand" passives (Beidhändig) add to it.
var offhand_min: int = 0
var offhand_max: int = 0
var offhand_attacks: bool = false
## Loading a save: a boss saved in phase `saved_phase` gets the values of that phase again (its
## skills, damage, armor) without the shout, and the size of the health bar it had.
func restore_phase(saved_phase: int, saved_max_health: float) -> void:
	if enemy_data == null:
		return
	while phase < mini(saved_phase, enemy_data.phases.size()):
		_enter_next_phase()
	phase_text = ""
	if saved_max_health >= 1.0:
		max_health = roundi(saved_max_health)
		health = minf(health, max_health)


## Ids of the skills with once_per_dungeon that are used up (for the save).
func get_used_once_ids() -> Array:
	var ids: Array = []
	for skill: SkillData in used_once:
		ids.append(str(skill.id))
	return ids


func set_used_once_ids(ids: Array) -> void:
	used_once.clear()
	for skill in skills:
		if ids.has(str(skill.id)):
			used_once[skill] = true


## Seconds until the next hit of the left hand (offhand_attacks only).
var offhand_cooldown: float = 1.0
## Armor + this % from the auras of the group (Aura der Hingabe, set by Adventure).
var aura_armor_percent: float = 0.0
## Heroes: a ready skill that lacks mana keeps it for itself (cheaper skills with mana costs wait),
## so the expensive skills come up at all (tick_skills).
var reserves_mana: bool = false
## Skills with once_per_dungeon already used: SkillData -> true.
var used_once: Dictionary = {}
## Seconds until the "martyr" passive can heal again.
var martyr_cooldown: float = 0.0

## Summons: the hero who called it (weak), its data, seconds left (INF = until it dies), and whether
## allies may heal / buff it. Basic hits of magic summons are spells.
var summoner: WeakRef
var summon_data: SummonData
var summon_time_left: float = INF
var buffable: bool = true
var basic_magic: bool = false
## Summons this fighter called that are still in the fight (strong refs; the summon only holds a
## weak one back).
var pets: Array = []

## Statistics of this fight. Damage dealt by hits: "Angriff" / skill name -> total.
var damage_by_source: Dictionary = {}
## Main damage kind of each damage_by_source entry (DamageKinds id, for the colors in the battle window).
var damage_kind_by_source: Dictionary = {}
## Damage dealt through status effects this fighter applied: effect name -> total.
var effect_damage_dealt: Dictionary = {}
## Damage taken through status effects: effect name -> total.
var effect_damage_taken: Dictionary = {}
## Healing this fighter got (from anyone, without overheal) and damage shields on it absorbed.
var total_healed: int = 0
var total_shielded: int = 0
## Healing this fighter did (skill / effect name -> total, without overheal), and damage that
## shields it gave absorbed (effect name -> total). A summon's also counts for its hero.
var healing_by_source: Dictionary = {}
var shielding_by_source: Dictionary = {}

const BASIC_ATTACK_NAME: String = "Angriff"
## Only skills from this mana cost on keep the mana for themselves (reserves_mana).
const RESERVE_MIN_MANA: int = 15


static func from_hero(hero: Hero) -> Combatant:
	var fighter := Combatant.new()
	fighter.hero = hero
	fighter.display_name = hero.display_name
	fighter.icon = hero.get_portrait()
	fighter.level = hero.level
	for type in ItemAttribute.Type.values():
		fighter.attributes[type] = hero.get_attribute(type)
	fighter.max_health = hero.get_max_health()
	fighter.max_mana = hero.get_max_mana()
	fighter.damage_min = hero.get_weapon_damage_min()
	fighter.damage_max = hero.get_weapon_damage_max()
	fighter.adds_strength_damage = true
	fighter.magic_min = hero.get_magic_damage_min()
	fighter.magic_max = hero.get_magic_damage_max()
	fighter.base_attack_interval = hero.get_attack_interval()
	fighter.armor = hero.get_armor()
	fighter.magic_resistance = hero.get_magic_resistance()
	fighter.health_regen = hero.get_health_regen()
	fighter.mana_regen = hero.get_mana_regen()
	fighter.cooldown_reduction = hero.get_cooldown_reduction()
	fighter.buff_duration_bonus = hero.get_buff_duration_bonus()
	# Skills that need another weapon (e.g. shield bash without a shield) or that the player
	# switched off are not used; passive skills are values, not actions.
	fighter.skills.assign(hero.get_learned_skills().filter(func(skill: SkillData) -> bool:
			return not skill.is_passive() and hero.can_use_skill(skill) and hero.is_skill_enabled(skill)))
	for stat: String in COMBAT_PASSIVES:
		var value: float = hero.get_passive_value(stat)
		if value != 0.0:
			fighter.passives[stat] = value
	# Expensive skills first (the strongest, see tick_skills), otherwise in tree order.
	var tree_order: Array[SkillData] = fighter.skills.duplicate()
	fighter.skills.sort_custom(func(a: SkillData, b: SkillData) -> bool:
		var cost_a: int = a.get_mana_cost(hero.get_skill_rank(a))
		var cost_b: int = b.get_mana_cost(hero.get_skill_rank(b))
		if cost_a != cost_b:
			return cost_a > cost_b
		return tree_order.find(a) < tree_order.find(b))
	fighter.reserves_mana = true
	var left: InventorySlot = hero.get_equipped(Hero.EquipmentSlot.LEFT_HAND)
	if left and left.item.is_weapon() and not left.item.uses_arrows():
		fighter.offhand_min = left.get_damage_min()
		fighter.offhand_max = left.get_damage_max()
		var classes: Array = ContentDB.combat_list("offhand_attack_classes")
		fighter.offhand_attacks = hero.hero_class != null and String(hero.hero_class.id) in classes
		fighter.offhand_cooldown = fighter.get_offhand_interval()
	for skill in fighter.skills:
		fighter.skill_levels[skill] = hero.get_skill_rank(skill)
		var command: Dictionary = hero.get_skill_command(skill)
		# Only what the hero is clever enough for.
		if not SkillCommand.is_empty(command) and hero.get_iq() >= SkillCommand.required_iq(command):
			fighter.commands[skill] = command
	fighter.role = hero.get_role()
	fighter.can_focus = hero.get_iq() >= HeroRole.focus_iq()
	var weapon: InventorySlot = hero.get_weapon()
	if weapon:
		fighter.weapon_split = DamageKinds.normalized(weapon.get_damage_split())
		fighter.uses_arrows = weapon.item.uses_arrows()
		fighter.weapon_upgrade = weapon.get_upgrade_values()
		fighter.weapon_on_hit = weapon.get_socket_on_hit()
	fighter.resistances = hero.get_resistances()
	fighter.crit_chance_bonus = hero.get_crit_chance_bonus()
	fighter.crit_damage_bonus = hero.get_crit_damage_bonus()
	fighter.penetration = hero.get_penetration()
	fighter._start()
	return fighter


static func from_enemy(data: EnemyData) -> Combatant:
	var fighter := Combatant.new()
	fighter.enemy_data = data
	fighter.display_name = data.display_name
	fighter.icon = data.get_frame(0)
	fighter.level = data.level
	fighter.attributes = data.attributes.duplicate()
	fighter.max_health = randi_range(data.health_min, data.health_max)
	fighter.max_mana = data.mana
	fighter.damage_min = data.damage_min
	fighter.damage_max = data.damage_max
	fighter.base_attack_interval = data.attack_interval
	fighter.armor = data.armor
	fighter.magic_resistance = data.magic_resistance
	fighter.health_regen = data.health_regen
	fighter.mana_regen = data.mana_regen
	fighter.skills = data.skills.duplicate()
	var has_magic: bool = data.magic_damage_max > 0
	fighter.magic_min = data.magic_damage_min if has_magic else data.damage_min
	fighter.magic_max = data.magic_damage_max if has_magic else data.damage_max
	fighter.weapon_split = DamageKinds.normalized(data.damage_split)
	fighter.resistances = data.resistances.duplicate()
	fighter.crit_chance_bonus = data.crit_chance
	fighter.hit_effects = data.on_hit.duplicate()
	fighter.back_row = data.back_row
	fighter.absorb = data.absorb.duplicate()
	fighter._start()
	return fighter


## Makes a monster stronger for a harder dungeon (DungeonData.enemy_health_factor / _damage_factor):
## health and all hit damage (weapon and spells) x the factors, also in its later boss phases.
## Call right after from_enemy.
func scale_power(health_scale: float, damage_scale: float) -> void:
	health_factor = health_scale
	damage_factor = damage_scale
	max_health = maxi(1, roundi(max_health * health_scale))
	health = max_health
	damage_min = roundi(damage_min * damage_scale)
	damage_max = maxi(damage_min, roundi(damage_max * damage_scale))
	magic_min = roundi(magic_min * damage_scale)
	magic_max = maxi(magic_min, roundi(magic_max * damage_scale))


## Health bars of this fighter (bosses with phases: more than 1).
func get_phase_count() -> int:
	return 1 + (enemy_data.phases.size() if enemy_data else 0)


## The last health bar ran out but another phase follows: full health and the values of that
## phase (EnemyData.phases); its debuffs are gone and its skills start half cooled down.
func _enter_next_phase() -> void:
	var data: Dictionary = enemy_data.phases[phase]
	phase += 1
	phase_text = data.get("text", "")
	if phase_text.is_empty():
		phase_text = Language.translate("Phase %d!") % (phase + 1)
	max_health = maxi(1, roundi(randi_range(data["hp_min"], data["hp_max"]) * health_factor))
	health = max_health
	if data.has("damage_min"):
		damage_min = roundi(data["damage_min"] * damage_factor)
		damage_max = roundi(data["damage_max"] * damage_factor)
	if data.has("magic_min"):
		magic_min = roundi(data["magic_min"] * damage_factor)
		magic_max = roundi(data["magic_max"] * damage_factor)
	base_attack_interval = data.get("attack_interval", base_attack_interval)
	armor = roundi(data.get("armor", armor))
	magic_resistance = roundi(data.get("magic_resistance", magic_resistance))
	health_regen = data.get("hp_regen", health_regen)
	mana_regen = data.get("mana_regen", mana_regen)
	var phase_skills: Array = data.get("skills", [])
	if not phase_skills.is_empty():
		skills.assign(phase_skills)
		for skill in skills:
			skill_cooldowns[skill] = skill.cooldown * 0.5
	effects = effects.filter(func(active: ActiveEffect) -> bool: return active.data.kind != StatusEffectData.Kind.DEBUFF)
	attack_cooldown = get_attack_interval()


## Size factor in the battle window: the monster's own, or that of its current phase.
func get_scale() -> float:
	if enemy_data == null:
		return 1.0
	if phase > 0:
		return float(enemy_data.phases[phase - 1].get("scale", enemy_data.scale)) * size_factor
	return enemy_data.scale * size_factor


## A creature a hero calls (SummonData): it gets `share` of the summoner's values (health, damage,
## magic damage, armor, magic resistance, attributes, resistances), times the summon's own factors
## and the summoner's "pet_*" passives, and stays `duration` seconds (0 = until it dies).
static func from_summon(owner: Combatant, data: SummonData, share: float, duration: float) -> Combatant:
	var fighter := Combatant.new()
	fighter.summon_data = data
	fighter.summoner = weakref(owner)
	fighter.display_name = data.display_name
	fighter.icon = data.get_texture()
	fighter.level = owner.level
	fighter.buffable = data.buffable
	fighter.basic_magic = data.magic
	var damage_share: float = share * (1.0 + owner.passives.get("pet_damage", 0.0) / 100.0)
	var health_share: float = share * (1.0 + owner.passives.get("pet_health", 0.0) / 100.0)
	for type: int in owner.attributes:
		fighter.attributes[type] = roundi(owner.attributes[type] * share)
	fighter.max_health = maxi(1, roundi(owner.max_health * health_share * data.health_factor))
	fighter.max_mana = 0
	var physical_min: float = owner.damage_min + (CombatRules.strength_damage(owner.get_attribute(ItemAttribute.Type.STRENGTH)) if owner.adds_strength_damage else 0)
	var physical_max: float = owner.damage_max + (CombatRules.strength_damage(owner.get_attribute(ItemAttribute.Type.STRENGTH)) if owner.adds_strength_damage else 0)
	fighter.damage_min = maxi(1, roundi(physical_min * damage_share))
	fighter.damage_max = maxi(fighter.damage_min, roundi(physical_max * damage_share))
	fighter.magic_min = maxi(1, roundi(owner.magic_min * owner.get_magic_damage_factor() * damage_share))
	fighter.magic_max = maxi(fighter.magic_min, roundi(owner.magic_max * owner.get_magic_damage_factor() * damage_share))
	fighter.base_attack_interval = owner.base_attack_interval / maxf(data.attack_speed, 0.1)
	fighter.armor = roundi(owner.armor * share)
	fighter.magic_resistance = roundi(owner.magic_resistance * share)
	fighter.health_regen = 0.0
	for kind: String in owner.resistances:
		fighter.resistances[kind] = owner.resistances[kind] * share
	fighter.crit_chance_bonus = owner.crit_chance_bonus
	fighter.weapon_split = data.damage_split
	fighter.hit_effects = data.on_hit.duplicate()
	fighter.skills = data.skills.duplicate()
	fighter.aura_armor_percent = owner.aura_armor_percent
	fighter.summon_time_left = duration if duration > 0.0 else INF
	fighter._start()
	return fighter


func _start() -> void:
	health = max_health
	mana = max_mana
	attack_cooldown = get_attack_interval()
	# Summons are ready at once (long cooldowns, and cooldowns pause while walking between waves,
	# so an elemental at half cooldown came too late or never); the others start half cooled down.
	for skill in skills:
		skill_cooldowns[skill] = 0.0 if not skill.summon_id.is_empty() else skill.cooldown * 0.5


## Passive values the fighter keeps from its hero (the others are already in the hero's values).
## "damage_<kind>" for every damage kind (skills like Klingenschärfe, races like the elves' air).
const COMBAT_PASSIVES: Array[String] = ["damage_physical", "damage_stab", "damage_blunt", "damage_slash",
		"damage_fire", "damage_water", "damage_earth", "damage_air", "damage_dark", "damage_light",
		"damage_lightning", "damage_ice", "damage_poison", "damage_magic", "damage_element",
		"arcane_blade", "low_health_damage", "low_health_lifesteal", "parry", "stealth_damage",
		"poisoned_target_damage", "skill_lifesteal", "offhand", "summon_duration", "bond_damage",
		"bond_mana_regen", "pet_damage", "pet_health", "pet_guard", "aura_armor", "martyr", "evasion",
		"tenacity", "heal_power", "debuff_duration", "debuff_chance", "lifesteal", "stun_chance", "shield_power", "poison_chance"]


func is_summon() -> bool:
	return summon_data != null


func get_summoner() -> Combatant:
	return summoner.get_ref() if summoner else null


## Living summons of this fighter (optionally only of one kind).
func get_living_pets(data: SummonData = null) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for pet: Combatant in pets:
		if pet.is_alive() and (data == null or pet.summon_data == data):
			result.append(pet)
	return result


func passive(stat: String) -> float:
	return passives.get(stat, 0.0)


# --- Values -----------------------------------------------------------------------

## Attribute with all buffs/debuffs (e.g. rage: strength x1.1).
func get_attribute(type: ItemAttribute.Type) -> float:
	var result: float = attributes.get(type, 0)
	for active in effects:
		result *= active.data.attribute_multipliers.get(type, 1.0)
	return result


## Seconds between basic hits: base and buffs/debuffs that change the attack speed (slow).
func get_attack_interval() -> float:
	var speed: float = 1.0
	for active in effects:
		speed += active.data.attack_speed
	return base_attack_interval / maxf(speed, 0.1)


func is_alive() -> bool:
	return health > 0.0


## Stunned fighters neither hit nor use skills (their timers wait).
func is_stunned() -> bool:
	return _has_effect(func(data: StatusEffectData) -> bool: return data.stun) and not is_stun_immune()


func is_stun_immune() -> bool:
	return _has_effect(func(data: StatusEffectData) -> bool: return data.stun_immune)


## Silenced fighters use no skills (basic hits still work).
func is_silenced() -> bool:
	return _has_effect(func(data: StatusEffectData) -> bool: return data.silence)


## Veiled (StatusEffectData.untargetable): single-target attacks can't pick this fighter.
func is_untargetable() -> bool:
	return is_alive() and _has_effect(func(data: StatusEffectData) -> bool: return data.untargetable)


## Veiled and taking no damage (e.g. the ghost lord behind his ghosts, EnemyData.shroud_effect_id):
## not even area attacks reach it.
func is_unreachable() -> bool:
	return is_untargetable() and get_damage_taken_factor() <= 0.0


func _has_effect(test: Callable) -> bool:
	for active in effects:
		if test.call(active.data):
			return true
	return false


func has_effect_id(effect_id: String) -> bool:
	return _has_effect(func(data: StatusEffectData) -> bool: return String(data.id) == effect_id)


## The running effect with this id (null = none).
func get_active_effect(effect_id: String) -> ActiveEffect:
	for active in effects:
		if String(active.data.id) == effect_id:
			return active
	return null


func is_low_health() -> bool:
	return health < max_health * 0.5


## Factor on all hit damage from buffs/debuffs (StatusEffectData.damage_bonus, 1.4 = +40 %) and
## passives (under 50 % health, while a summon of this fighter lives).
func get_damage_factor() -> float:
	var factor: float = 1.0
	for active in effects:
		factor += active.data.damage_bonus
	if is_low_health():
		factor += passive("low_health_damage") / 100.0
	if not get_living_pets().is_empty():
		factor += passive("bond_damage") / 100.0
	return maxf(0.0, factor)


## Factor on the damage this fighter takes (vulnerable +15 % = 1.15, invulnerable = 0).
func get_damage_taken_factor() -> float:
	var factor: float = 1.0
	for active in effects:
		factor += active.data.damage_taken
	return maxf(0.0, factor)


## Taunting (StatusEffectData.taunt): the other side's single-target attacks must hit this fighter.
func is_taunting() -> bool:
	return is_alive() and effects.any(func(active: ActiveEffect) -> bool: return active.data.taunt)


## Chance (0..1) to dodge a hit completely: agility (per 10) + buffs (e.g. smoke bomb).
func get_evasion() -> float:
	var bonus: float = passive("evasion") / 100.0
	for active in effects:
		bonus += active.data.evasion
	return CombatRules.evasion(get_attribute(ItemAttribute.Type.AGILITY), bonus)


## How much shorter debuffs on this fighter last (0.3 = 30 %), from resistance (per 10) and passives.
func get_tenacity() -> float:
	return CombatRules.tenacity(get_attribute(ItemAttribute.Type.RESISTANCE), passive("tenacity") / 100.0)


## Factor on the spells of this fighter: intelligence, or the attributes of the skill (e.g. the
## shadow priest's spells grow with wisdom and some intelligence, get_scaled_attribute).
func get_magic_damage_factor(skill: SkillData = null) -> float:
	if skill and skill.is_magic():
		return CombatRules.magic_damage_factor(get_scaled_attribute(skill))
	return CombatRules.magic_damage_factor(get_attribute(ItemAttribute.Type.INTELLIGENCE))


## Attribute points the damage of `skill` grows with: heroes add up the shares of its attributes
## (SkillData.scaling, rapid shot = 100 % agility + 40 % strength); monsters and summons only use
## its main attribute, as before.
func get_scaled_attribute(skill: SkillData) -> float:
	if not adds_strength_damage:
		return get_attribute(skill.scaling_attribute)
	var total: float = 0.0
	var shares: Dictionary = skill.get_scaling()
	for type: int in shares:
		total += get_attribute(type) * float(shares[type])
	return total


## Flat damage the attributes add to a weapon hit: strength for basic hits, the skill's attributes
## for weapon skills (heroes only, monsters have fixed damage).
func get_attribute_damage(skill: SkillData = null) -> float:
	if not adds_strength_damage:
		return 0.0
	if skill:
		return CombatRules.strength_damage(get_scaled_attribute(skill))
	return CombatRules.strength_damage(get_attribute(ItemAttribute.Type.STRENGTH))


## Factor on heals and shields this fighter gives (wisdom, passives).
func get_heal_power() -> float:
	return CombatRules.heal_power(get_attribute(ItemAttribute.Type.WISDOM), passive("heal_power"))


func get_shield_power() -> float:
	return CombatRules.shield_power(get_attribute(ItemAttribute.Type.WISDOM), passive("shield_power"))


## Part of the hit damage that heals this fighter (0.3 = 30 %), from buffs and passives (always,
## e.g. a ruby ring; under 50 % health; skill hits).
func get_lifesteal(skill: SkillData = null) -> float:
	var total: float = passive("lifesteal") / 100.0
	for active in effects:
		total += active.data.lifesteal
	if is_low_health():
		total += passive("low_health_lifesteal") / 100.0
	if skill:
		total += passive("skill_lifesteal") / 100.0
	return total


## Resistances with the RES attribute and all buffs/debuffs: DamageKinds id -> value.
func get_resistances() -> Dictionary:
	var result: Dictionary = CombatRules.resistances_with_attribute(resistances, get_attribute(ItemAttribute.Type.RESISTANCE))
	for active in effects:
		for kind: String in active.data.resistances:
			result[kind] = result.get(kind, 0.0) + active.data.resistances[kind]
	return result


## Armor with buffs/debuffs in percent (e.g. armor break: -30 %).
func get_armor() -> float:
	var percent: float = aura_armor_percent / 100.0
	for active in effects:
		percent += active.data.armor_percent
	return CombatRules.changed_defense(armor, percent)


## Magic resistance with buffs/debuffs in percent.
func get_magic_resistance() -> float:
	var percent: float = 0.0
	for active in effects:
		percent += active.data.magic_resistance_percent
	return CombatRules.changed_defense(magic_resistance, percent)


## Penetration of a hit: equipment + buffs + the skill's own (e.g. armor break 30 %).
func get_penetration(skill: SkillData = null) -> Dictionary:
	var total: Dictionary = CombatRules.add_penetration(CombatRules.penetration(), penetration)
	for active in effects:
		total = CombatRules.add_penetration(total, active.data.penetration)
	if skill:
		total = CombatRules.add_penetration(total, skill.penetration)
	return total


## Chance for a critical hit (0..1), with equipment, buffs and the skill's own bonus.
func get_crit_chance(skill: SkillData = null) -> float:
	var bonus: float = crit_chance_bonus + (skill.crit_chance if skill else 0.0)
	for active in effects:
		bonus += active.data.crit_chance
	return CombatRules.crit_chance(get_attribute(ItemAttribute.Type.AGILITY), bonus)


## Damage factor of a critical hit (1.5 = 150 %), with the skill's own bonus.
func get_crit_damage(skill: SkillData = null) -> float:
	var bonus: float = crit_damage_bonus + (skill.crit_damage if skill else 0.0)
	for active in effects:
		bonus += active.data.crit_damage
	return CombatRules.crit_damage(bonus)


## Set by _shoot_arrow for the current hit: extra damage of the arrow and the factor on the
## bow's own damage (1 with an arrow, no_arrow_damage_factor without).
var _arrow_damage: float = 0.0
var _arrow_factor: float = 1.0


## A bow shoots the next arrow of the hero (the arrows are read for every shot: with a quiver
## e.g. first the good ones, then the simple ones): {"split", "upgrade"} of the arrow, or {}
## (no bow or no arrows left, then the bow only hits weakly). `consume`: the arrow is used up
## (skill hits only).
func _shoot_arrow(consume: bool = true) -> Dictionary:
	_arrow_damage = 0.0
	_arrow_factor = 1.0
	if not uses_arrows:
		return {}
	var arrows: InventorySlot = hero.get_arrows() if hero else null
	if arrows == null:
		_arrow_factor = CombatRules.value("no_arrow_damage_factor", 0.25)
		return {}
	_arrow_damage = randi_range(arrows.get_damage_min(), arrows.get_damage_max())
	var arrow_split: Dictionary = DamageKinds.normalized(arrows.get_damage_split())
	var upgrade: Dictionary = arrows.get_upgrade_values()
	if consume:
		hero.use_arrow()
	return {"split": arrow_split if not arrow_split.is_empty() else weapon_split, "upgrade": upgrade}


## Damage of one physical hit: rolled base + weapon damage, plus strength for heroes (the
## attributes of `skill` for a weapon skill, get_attribute_damage).
func roll_weapon_damage(skill: SkillData = null) -> float:
	return randi_range(damage_min, damage_max) + get_attribute_damage(skill)


## Spell damage before the skill factor: rolled magic damage x intelligence (or the skill's
## scaling attribute) factor.
func roll_magic_damage(skill: SkillData = null) -> float:
	return randi_range(magic_min, magic_max) * get_magic_damage_factor(skill)


## Average spell damage before the skill factor, with the factor of `attribute` (damage over time
## that grows with its caster, StatusEffectData.damage_from_magic).
func get_average_spell_damage(attribute: ItemAttribute.Type) -> float:
	return (magic_min + magic_max) / 2.0 * CombatRules.magic_damage_factor(get_attribute(attribute))


## Damage before the skill factor of skills with SkillData.base_from (e.g. shield bash: 50 % of the
## armor + 8 % of the max health).
func roll_base_from(skill: SkillData) -> float:
	return get_armor() * skill.base_from.get("armor", 0.0) + max_health * skill.base_from.get("max_health", 0.0)


## Raw damage before the target's defense: {"amount": float, "split": {kind: share}, "crit": bool,
## "on_hit": [{"effect": StatusEffectData, "chance": 0..1}] (upgrades, rolled by Adventure on a hit),
## "penetration": armor / magic penetration of this hit (get_penetration)}.
## Basic hit: weapon damage (with strength), split like the weapon.
## Physical skill: weapon damage x skill factor of its level (sword strike = 150 %).
## Spell (magic skill): (base + magic damage of the weapon) x skill factor x intelligence factor.
## A critical hit multiplies everything with get_crit_damage().
## `split_override`: own split of this hit (SkillData.hit_splits). Passives and buffs on top: the
## left-hand weapon (basic hits), arcane blade (basic hits + magic), extra damage of a buff (light),
## damage per kind (e.g. slash +10 %), physical / magic damage buffs, attacks from the veil.
## `offhand`: a basic hit of the weapon in the left hand (no arrow, no upgrade of the right-hand
## weapon).
func roll_hit(skill: SkillData = null, split_override: Dictionary = {}, offhand: bool = false) -> Dictionary:
	var amount: float
	var split: Dictionary
	var physical_split: Dictionary = weapon_split
	var magic_hit: bool = (skill != null and skill.is_magic()) or (skill == null and basic_magic)
	_arrow_damage = 0.0
	_arrow_factor = 1.0
	# Upgrades of the weapon and the shot arrow (physical hits only).
	var upgrades: Array[Dictionary] = []
	if not magic_hit and (skill == null or skill.base_from.is_empty()) and not offhand:
		if not weapon_upgrade.is_empty():
			upgrades.append(weapon_upgrade)
		var shot: Dictionary = _shoot_arrow(skill != null)
		if not shot.is_empty():
			physical_split = shot["split"]
			if not shot["upgrade"].is_empty():
				upgrades.append(shot["upgrade"])
	if offhand:
		amount = (randi_range(offhand_min, offhand_max) + get_attribute_damage()) \
				* ContentDB.combat_value("offhand_attack_damage", 0.5) * (1.0 + passive("offhand") / 100.0)
		split = physical_split
	elif skill == null:
		amount = roll_magic_damage() if basic_magic else roll_weapon_damage() * _arrow_factor + _arrow_damage
		split = physical_split
	else:
		var base: float
		if not skill.base_from.is_empty():
			base = roll_base_from(skill)
		elif skill.uses_spell_damage():
			base = roll_magic_damage(skill)
		else:
			base = roll_weapon_damage(skill) * _arrow_factor + _arrow_damage
		amount = base * skill.get_damage_multiplier(skill_levels.get(skill, 1))
		split = DamageKinds.normalized(skill.get_damage_split(physical_split))
	if not split_override.is_empty():
		split = split_override
	if skill == null and passive("arcane_blade") > 0.0:
		var arcane: float = roll_magic_damage() * passive("arcane_blade") / 100.0
		split = _add_to_split(amount, split, arcane, DamageKinds.MAGIC)
		amount += arcane
	for active in effects:
		if active.data.extra_damage > 0.0:
			var extra_amount: float = amount * active.data.extra_damage
			split = _add_to_split(amount, split, extra_amount, active.data.extra_damage_kind)
			amount += extra_amount
	amount *= get_kind_damage_factor(split)
	for active in effects:
		amount *= 1.0 + (active.data.magic_damage if magic_hit else active.data.physical_damage)
	if is_untargetable():
		amount *= 1.0 + passive("stealth_damage") / 100.0
	# Upgrades: flat extra damage of their kind (e.g. +1-2 poison), and a chance for their effect.
	var on_hit: Array[Dictionary] = []
	for upgrade in upgrades:
		var extra: float = randi_range(upgrade["damage_min"], upgrade["damage_max"])
		if extra > 0.0:
			split = _add_to_split(amount, split, extra, upgrade["kind"])
			amount += extra
		if upgrade["effect"] and upgrade["chance"] > 0.0:
			on_hit.append({"effect": upgrade["effect"], "chance": upgrade["chance"]})
	if skill == null:
		on_hit.append_array(hit_effects)
	if not magic_hit and (skill == null or skill.base_from.is_empty()) and not offhand:
		on_hit.append_array(weapon_on_hit)
	for active in effects:
		if not active.data.on_hit_effect_id.is_empty():
			on_hit.append({"effect": ContentDB.status_effect(active.data.on_hit_effect_id), "chance": active.data.on_hit_chance})
	# Stun chance (e.g. a topaz ring): every hit may stun the target.
	if passive("stun_chance") > 0.0:
		on_hit.append({"effect": ContentDB.status_effect("stun"), "chance": passive("stun_chance") / 100.0})
	# Poison chance (Giftklinge): every attack may poison the target.
	if passive("poison_chance") > 0.0:
		on_hit.append({"effect": ContentDB.status_effect("poison"), "chance": passive("poison_chance") / 100.0})
	amount *= get_damage_factor()
	var crit: bool = randf() < get_crit_chance(skill) or (skill != null and skill.crit_from_stealth and is_untargetable())
	if crit:
		amount *= get_crit_damage(skill)
	return {"amount": amount, "split": split, "crit": crit, "on_hit": on_hit, "penetration": get_penetration(skill)}


## What one hit of `skill` at `level` does before the target's defense, without rolling and without
## using anything up (for the skill tooltip; null = basic hit): {"base_min", "base_max" (before the
## skill factor), "multiplier", "kind_factor" (damage passives of its kinds), "damage_factor"
## (buffs/passives on all damage), "extra_min", "extra_max" (flat upgrade damage), "min", "max"
## (all of it), "split", "crit_chance", "crit_factor", "hits", "cooldown" (with the cooldown
## reduction of gear and passives, like in the dungeon)}. Empty for a skill whose damage comes
## from a summon (pet_attack).
func estimate_skill(skill: SkillData, skill_level: int) -> Dictionary:
	if skill and skill.pet_attack:
		return {}
	var base_min: float
	var base_max: float
	var physical_split: Dictionary = weapon_split
	var magic_hit: bool = (skill != null and skill.is_magic()) or (skill == null and basic_magic)
	var extra_min: float = 0.0
	var extra_max: float = 0.0
	var scaled_attribute: float = get_scaled_attribute(skill) if skill and skill.scales_with_attributes() else 0.0
	var attribute_bonus: float = 0.0
	var formula: String = "weapon"
	var arrow_factor: float = 1.0
	var arrow_min: float = 0.0
	var arrow_max: float = 0.0
	var no_arrows: bool = false
	if skill and not skill.base_from.is_empty():
		formula = "base_from"
		base_min = roll_base_from(skill)
		base_max = base_min
	elif magic_hit and (skill == null or skill.uses_spell_damage()):
		formula = "spell"
		attribute_bonus = get_magic_damage_factor(skill)
		base_min = magic_min * attribute_bonus
		base_max = magic_max * attribute_bonus
	else:
		var strength: float = get_attribute_damage(skill)
		attribute_bonus = strength
		if uses_arrows and not magic_hit:
			var arrows: InventorySlot = null
			if hero:
				arrows = hero.get_arrows()
			if arrows == null:
				arrow_factor = CombatRules.value("no_arrow_damage_factor", 0.25)
				no_arrows = true
			else:
				arrow_min = arrows.get_damage_min()
				arrow_max = arrows.get_damage_max()
				var arrow_split: Dictionary = DamageKinds.normalized(arrows.get_damage_split())
				if not arrow_split.is_empty():
					physical_split = arrow_split
		base_min = (damage_min + strength) * arrow_factor + arrow_min
		base_max = (damage_max + strength) * arrow_factor + arrow_max
		if not weapon_upgrade.is_empty() and not magic_hit:
			extra_min += float(weapon_upgrade.get("damage_min", 0))
			extra_max += float(weapon_upgrade.get("damage_max", 0))
	var multiplier: float = skill.get_damage_multiplier(skill_level) if skill else 1.0
	var split: Dictionary = DamageKinds.normalized(skill.get_damage_split(physical_split)) if skill else physical_split
	var kind_factor: float = get_kind_damage_factor(split)
	var buff_factor: float = 1.0
	for active in effects:
		buff_factor *= 1.0 + (active.data.magic_damage if magic_hit else active.data.physical_damage)
	var all_factor: float = get_damage_factor() * buff_factor
	var cooldown: float = skill.cooldown * (1.0 - cooldown_reduction) if skill else get_attack_interval()
	# Every attribute of the skill: its value, its share, and what one more point adds to the
	# average damage (before the target's defense), so the player sees what gear with it is worth.
	var attribute_parts: Array[Dictionary] = []
	if skill and skill.scales_with_attributes() and formula != "base_from":
		var after: float = multiplier * kind_factor * all_factor
		var shares: Dictionary = skill.get_scaling() if adds_strength_damage else {skill.scaling_attribute: 1.0}
		for type: int in shares:
			var share: float = float(shares[type])
			var value: float = get_attribute(type)
			var per_point: float
			var bonus: float
			if formula == "spell":
				bonus = value * share * CombatRules.value("magic_damage_per_int", 0.02)
				per_point = (magic_min + magic_max) / 2.0 * share * CombatRules.value("magic_damage_per_int", 0.02) * after
			else:
				bonus = value * share * CombatRules.value("damage_per_str", 0.5) if adds_strength_damage else 0.0
				per_point = share * CombatRules.value("damage_per_str", 0.5) * arrow_factor * after if adds_strength_damage else 0.0
			attribute_parts.append({"type": type, "value": value, "share": share, "bonus": bonus, "per_point": per_point})
	return {
		"base_min": base_min, "base_max": base_max, "multiplier": multiplier, "kind_factor": kind_factor,
		"damage_factor": all_factor, "extra_min": extra_min, "extra_max": extra_max,
		"min": (base_min * multiplier * kind_factor + extra_min) * all_factor,
		"max": (base_max * multiplier * kind_factor + extra_max) * all_factor,
		"split": split, "crit_chance": get_crit_chance(skill), "crit_factor": get_crit_damage(skill),
		"hits": skill.hits if skill else 1, "cooldown": cooldown,
		"scaled_attribute": scaled_attribute, "attribute_bonus": attribute_bonus,
		"formula": formula, "weapon_min": float(damage_min), "weapon_max": float(damage_max),
		"magic_min": float(magic_min), "magic_max": float(magic_max), "arrow_min": arrow_min, "arrow_max": arrow_max,
		"arrow_factor": arrow_factor, "no_arrows": no_arrows, "attribute_parts": attribute_parts,
	}


## Factor from the "damage_<kind>" passives for a hit of this split, e.g. 50 % slash with slash
## +20 % = x1.1. Elements also count for "damage_element" (e.g. fire: "damage_fire" + "damage_element").
func get_kind_damage_factor(split: Dictionary) -> float:
	var bonus: float = 0.0
	for kind: String in split:
		bonus += split[kind] * get_kind_bonus(kind)
	return 1.0 + bonus


## Passive bonus (0.2 = +20 %) for damage of this kind.
func get_kind_bonus(kind: String) -> float:
	var percent: float = passive("damage_" + kind)
	if kind in DamageKinds.ELEMENT_KINDS:
		percent += passive("damage_element")
	return percent / 100.0


## Split of `amount` + `extra` damage of `kind`: 10 slash + 2 poison = {"slash": 0.83, "poison": 0.17}.
static func _add_to_split(amount: float, split: Dictionary, extra: float, kind: String) -> Dictionary:
	var result: Dictionary = {}
	for key: String in split:
		result[key] = amount * split[key]
	result[kind] = result.get(kind, 0.0) + extra
	return DamageKinds.normalized(result)


## How much of `amount` gets through, share by share: physical kinds against armor + their
## resistance, elements/magic against magic resistance + their resistance, true damage unchanged.
## Armor and magic resistance include buffs/debuffs; `pen` = the attacker's penetration.
func get_damage_after_defense(amount: float, split: Dictionary, pen: Dictionary = {}) -> float:
	var total: float = 0.0
	var current: Dictionary = get_resistances()
	var current_armor: float = get_armor()
	var current_magic: float = get_magic_resistance()
	for kind: String in split:
		total += amount * split[kind] * CombatRules.mitigation(kind, current_armor, current_magic, current, pen)
	return total


## Takes a hit from roll_hit(); shields absorb first. Returns the damage that hit the health.
## Buffs/debuffs change it (vulnerable +15 %, invulnerable = nothing).
## Kinds it absorbs (absorb, e.g. fire for the lava golem) heal it instead, without defense.
func receive_hit(hit: Dictionary) -> int:
	var factor: float = get_damage_taken_factor()
	if factor <= 0.0:
		return 0
	var amount: float = hit["amount"]
	var split: Dictionary = hit["split"]
	if not absorb.is_empty():
		var absorbed: float = 0.0
		var rest: Dictionary = {}
		for kind: String in split:
			var share: float = split[kind] * absorb.get(kind, 0.0)
			absorbed += amount * share
			if split[kind] - share > 0.0:
				rest[kind] = split[kind] - share
		if absorbed > 0.0:
			absorbed_heal += heal(absorbed)
		var rest_share: float = 0.0
		for kind: String in rest:
			rest_share += rest[kind]
		if rest_share <= 0.001:
			return 0
		amount *= rest_share
		split = DamageKinds.normalized(rest)
	return _lose(maxi(1, roundi(get_damage_after_defense(amount, split, hit.get("penetration", {})) * factor)))


## Damage of a status effect: of its element against that resistance, without element it
## ignores defense (bleeding); shields still absorb it.
func take_effect_damage(amount: float, effect: StatusEffectData) -> int:
	if effect.element != Element.Type.NONE:
		amount = get_damage_after_defense(amount, {DamageKinds.from_element(effect.element): 1.0})
	var factor: float = get_damage_taken_factor()
	if factor <= 0.0:
		return 0
	return lose_health(amount * factor)


## Damage that ignores defense; shields still absorb it.
func lose_health(amount: float) -> int:
	return _lose(maxi(1, roundi(amount)))


func _lose(amount: int) -> int:
	var rest: float = amount
	for active in effects:
		if rest <= 0.0:
			break
		if active.shield > 0.0:
			var absorbed: float = minf(active.shield, rest)
			active.shield -= absorbed
			rest -= absorbed
			total_shielded += roundi(absorbed)
			var caster: Combatant = active.get_source()
			_credit(caster if caster else self, "shielding_by_source", active.data.display_name, roundi(absorbed))
	# Used-up shields disappear.
	effects = effects.filter(func(active: ActiveEffect) -> bool: return not active.data.is_shield() or active.shield > 0.0)
	var taken: int = roundi(rest)
	# Undying: the health stays at 1 at least.
	if health > 1.0 and _has_effect(func(data: StatusEffectData) -> bool: return data.undying):
		taken = mini(taken, floori(health - 1.0))
	health = maxf(health - taken, 0.0)
	# A boss with another health bar goes on with its next phase.
	if health <= 0.0 and enemy_data and phase < enemy_data.phases.size():
		_enter_next_phase()
	return taken


## Remaining shield points (for the battle window).
func get_shield() -> int:
	var total: float = 0.0
	for active in effects:
		total += active.shield
	return roundi(total)


## `source` and `source_name` (skill or effect): who healed, for the statistics (healing_by_source).
## Without a source nobody gets the credit (e.g. the lava golem absorbing fire).
func heal(amount: float, source: Combatant = null, source_name: String = "") -> int:
	var before: float = health
	health = minf(health + amount * heal_received_factor, max_health)
	var healed: int = roundi(health - before)
	total_healed += healed
	if source:
		source._credit(source, "healing_by_source", source_name, healed)
	return healed


## Adds `amount` to `fighter`'s statistic `stat` under `key`, and for a summon also to its hero
## (under the summon's name, as record_hit does).
func _credit(fighter: Combatant, stat: String, key: String, amount: int) -> void:
	if amount <= 0:
		return
	var by_source: Dictionary = fighter.get(stat)
	by_source[key] = by_source.get(key, 0) + amount
	var owner: Combatant = fighter.get_summoner()
	if owner:
		var owner_stat: Dictionary = owner.get(stat)
		owner_stat[fighter.display_name] = owner_stat.get(fighter.display_name, 0) + amount


# --- Status effects -----------------------------------------------------------------

## Applies a buff/debuff. "stack": +stacks (up to max) and the duration starts again;
## "refresh": only the duration starts again. `duration` 0 = the effect's own duration.
## Debuffs are shorter by the tenacity of this fighter, buffs longer by the buff duration of
## the source; shields and heals grow with the shield / heal power of the source.
## `source` = who applied it (for the damage statistics).
func apply_effect(effect: StatusEffectData, stacks: int = 1, duration: float = 0.0, source: Combatant = null) -> void:
	if effect.is_instant():
		_apply_instant(effect)
		return
	if not is_alive():
		return
	if effect.stun and is_stun_immune():
		return
	var length: float = duration if duration > 0.0 else effect.duration
	if effect.kind == StatusEffectData.Kind.DEBUFF:
		length *= 1.0 - get_tenacity()
		if source:
			length *= 1.0 + source.passive("debuff_duration") / 100.0
	elif source:
		length *= 1.0 + source.buff_duration_bonus
	var shield: float = max_health * effect.shield_percent / 100.0 * (source.get_shield_power() if source else 1.0)
	if effect.caster_shield:
		var caster: Combatant = source if source else self
		shield = effect.get_caster_shield(caster)
	var heal_factor: float = source.get_heal_power() if source else 1.0
	for active in effects:
		# Same effect (also a stronger version of it from a higher skill level): the newest counts.
		if active.data.id == effect.id:
			active.data = effect
			if effect.stacking == StatusEffectData.Stacking.STACK:
				active.stacks = mini(active.stacks + stacks, effect.max_stacks)
			active.duration = maxf(active.duration, length)
			active.time_left = active.duration
			active.shield = maxf(active.shield, shield)
			active.heal_factor = heal_factor
			if source:
				active.source = weakref(source)
			return
	var active := ActiveEffect.new()
	active.data = effect
	active.shield = shield
	active.heal_factor = heal_factor
	if source:
		active.source = weakref(source)
	active.stacks = mini(stacks, effect.max_stacks) if effect.stacking == StatusEffectData.Stacking.STACK else 1
	active.duration = length
	active.time_left = length
	effects.append(active)


## Cleanse: debuffs are gone (all, or cleanse_count of them, the newest first). Revive: a fallen
## fighter stands up again with some health.
func _apply_instant(effect: StatusEffectData) -> void:
	if effect.cleanse:
		var left: int = effect.cleanse_count if effect.cleanse_count > 0 else effects.size()
		for i in range(effects.size() - 1, -1, -1):
			if left > 0 and effects[i].data.kind == StatusEffectData.Kind.DEBUFF:
				effects.remove_at(i)
				left -= 1
	if effect.revive_percent > 0.0 and not is_alive():
		effects.clear()
		health = maxf(1.0, max_health * effect.revive_percent / 100.0)
		attack_cooldown = get_attack_interval()


func is_health_regen_blocked() -> bool:
	for active in effects:
		if active.data.block_health_regen:
			return true
	return false


## Regeneration, effect ticks (once per second) and expiry. Returns what happened, for the
## battle window: [{"effect": StatusEffectData, "amount": int, "heal": bool, "source": Combatant}].
func tick(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not is_alive():
		return events
	if not is_health_regen_blocked():
		health = minf(health + health_regen * heal_received_factor * delta, max_health)
	var extra_mana: float = passive("bond_mana_regen") if not get_living_pets().is_empty() else 0.0
	for active in effects:
		extra_mana += active.data.mana_regen
	mana = minf(mana + (mana_regen + extra_mana) * delta, max_mana)
	for active in effects.duplicate():
		active.time_left -= delta
		active.next_tick -= delta
		while active.next_tick <= 0.0 and is_alive():
			active.next_tick += 1.0
			if active.data.damage_per_second > 0.0 or active.data.damage_from_magic > 0.0 or active.data.damage_percent_per_second > 0.0:
				# Poison / burn grow with the "damage_<kind>" passives of whoever applied them, the
				# shadow priest's pain also with his spell damage (damage_from_magic).
				var source: Combatant = active.get_source()
				var per_second: float = active.data.damage_per_second + max_health * active.data.damage_percent_per_second / 100.0
				if source and active.data.damage_from_magic > 0.0:
					per_second += source.get_average_spell_damage(active.data.damage_attribute) * active.data.damage_from_magic
				per_second *= active.stacks
				var kind: String = DamageKinds.from_element(active.data.element) if active.data.element != Element.Type.NONE else ""
				if source and not kind.is_empty():
					per_second *= 1.0 + source.get_kind_bonus(kind)
				if absorb.get(kind, 0.0) > 0.0:
					# e.g. burning heals the lava golem
					events.append({"effect": active.data, "amount": heal(per_second * absorb[kind]), "heal": true, "source": source})
				else:
					events.append({"effect": active.data, "amount": take_effect_damage(per_second, active.data), "heal": false, "source": source})
			if active.data.heal_percent_per_second > 0.0:
				events.append({"effect": active.data, "amount": heal(max_health * active.data.heal_percent_per_second / 100.0 * active.heal_factor,
						active.get_source(), active.data.display_name), "heal": true, "source": active.get_source()})
		if active.time_left <= 0.0:
			effects.erase(active)
			if active.data.damage_percent_on_expire > 0.0 and is_alive():
				events.append({"effect": active.data, "amount": lose_health(max_health * active.data.damage_percent_on_expire / 100.0), "heal": false, "source": active.get_source()})
			if active.data.heal_percent_on_expire > 0.0 and is_alive():
				events.append({"effect": active.data, "amount": heal(max_health * active.data.heal_percent_on_expire / 100.0,
						active.get_source(), active.data.display_name), "heal": true, "source": active.get_source()})
	return events


## Adds hit damage to the statistics ("Angriff" or the skill name). A summon's damage also counts
## for its hero under the summon's name.
func record_hit(skill: SkillData, damage: int) -> void:
	var key: String = skill.display_name if skill else Language.translate(BASIC_ATTACK_NAME)
	damage_by_source[key] = damage_by_source.get(key, 0) + damage
	if not damage_kind_by_source.has(key):
		damage_kind_by_source[key] = _color_kind(skill.get_damage_split(weapon_split)) if skill else DamageKinds.PHYSICAL
	var owner: Combatant = get_summoner()
	if owner:
		owner.damage_by_source[display_name] = owner.damage_by_source.get(display_name, 0) + damage
		# The summon's line has the color of its own hits (fire elemental = fire).
		if not owner.damage_kind_by_source.has(display_name):
			owner.damage_kind_by_source[display_name] = _color_kind(weapon_split)


## Kind a damage line is colored by: the biggest element / magic share if there is one (fire
## arrow = fire, even with half stab damage), otherwise physical.
static func _color_kind(split: Dictionary) -> String:
	var magic_part: Dictionary = {}
	for kind: String in split:
		if not DamageKinds.is_physical(kind):
			magic_part[kind] = split[kind]
	return DamageKinds.get_main_kind(magic_part) if not magic_part.is_empty() else DamageKinds.PHYSICAL


## e.g. "Gift x3 · Rage" for the battle window.
func get_effects_text() -> String:
	var parts: Array[String] = []
	for active in effects:
		parts.append(active.data.display_name + (" x%d" % active.stacks if active.stacks > 1 else ""))
	return " · ".join(parts)


# --- Actions ------------------------------------------------------------------------

## Counts down the basic hit. Returns true when it is time to hit (and restarts it).
## Stunned fighters wait.
func tick_attack(delta: float) -> bool:
	if is_stunned():
		return false
	attack_cooldown -= delta
	if attack_cooldown > 0.0:
		return false
	attack_cooldown += get_attack_interval()
	return true


## Seconds between two hits of the left hand: combat.json "offhand_attack_interval_factor" times
## the basic hit (2 = half as fast).
func get_offhand_interval() -> float:
	return get_attack_interval() * ContentDB.combat_value("offhand_attack_interval_factor", 2.0)


## Counts down the hit of the left hand (only offhand_attacks with a weapon there). Returns true
## when it is time to hit (and restarts it). Stunned fighters wait.
func tick_offhand(delta: float) -> bool:
	if not offhand_attacks or offhand_max <= 0 or is_stunned():
		return false
	offhand_cooldown -= delta
	if offhand_cooldown > 0.0:
		return false
	offhand_cooldown += get_offhand_interval()
	return true


## Counts down all skill cooldowns. Returns the first skill that is ready, affordable and
## useful right now (`can_use`, e.g. a revive only with a fallen ally) - pays its mana and
## restarts its cooldown - or null. Stunned and silenced fighters use no skills; a skill that is
## once per dungeon only once. With reserves_mana (heroes, skills sorted by mana cost) a ready skill
## without enough mana makes the cheaper ones with mana costs wait until it can be paid.
func tick_skills(delta: float, can_use: Callable = Callable()) -> SkillData:
	var ready: SkillData = null
	var blocked: bool = is_stunned() or is_silenced()
	var reserved: bool = false
	for skill in skills:
		skill_cooldowns[skill] = maxf(skill_cooldowns[skill] - delta, 0.0)
		if ready != null or blocked or skill_cooldowns[skill] > 0.0 or used_once.has(skill):
			continue
		var cost: int = get_mana_cost(skill)
		# Heals don't wait for a reserved skill.
		if reserved and cost > 0 and skill.heal_percent <= 0.0:
			continue
		var can_reserve: bool = reserves_mana and cost >= RESERVE_MIN_MANA and cost <= max_mana
		if mana < cost and not can_reserve:
			continue
		if can_use.is_valid() and not can_use.call(skill):
			continue
		if mana >= cost:
			ready = skill
		else:
			reserved = true
	if ready:
		skill_cooldowns[ready] = ready.cooldown * (1.0 - cooldown_reduction)
		mana -= get_mana_cost(ready)
		if ready.once_per_dungeon:
			used_once[ready] = true
	return ready


## Mana this fighter pays for the skill (more on higher skill levels, SkillData.get_mana_cost).
func get_mana_cost(skill: SkillData) -> int:
	return skill.get_mana_cost(skill_levels.get(skill, 1))


## All cooldowns shorter by `seconds` (e.g. the priest's inspiration).
func shorten_cooldowns(seconds: float) -> void:
	for skill in skills:
		skill_cooldowns[skill] = maxf(skill_cooldowns[skill] - seconds, 0.0)
