class_name CombatRules
extends RefCounted
## All combat formulas in one place. The numbers come from data/content/combat.json, so they
## can be balanced without code. "Per 10" = for every full 10 points.
## Heroes get "health_per_level" extra health per level above 1.
##   STR: +0.5 weapon damage per point (rounded down), +1 health per 10
##   AGI: +1 % crit chance per point, +2.5 % evasion per 10
##   CON: +2 health per point, +1 health regeneration per 10
##   INT: +2 % magic damage and +1 max mana per point, +1 mana regeneration per 10
##   WIS: +0.3 % heal power and shield power per point, +2 health and +1 mana regeneration per 10
##   RES: +1 to every resistance per point, +3 % tenacity per 10
## Armor reduces physical damage, magic resistance all magic (elements and pure magic), both
## with the same formula; the resistance against the damage kind is added on top.
## Order for a hit: armor of the target x its buffs/debuffs in % (e.g. -30 %), then the
## attacker's penetration in %, then the flat penetration (only armor / magic resistance,
## not the resistance against the kind).


static func value(key: String, default: float) -> float:
	return ContentDB.combat_value(key, default)


## Full tens of an attribute (25 -> 2).
static func tens(attribute: float) -> int:
	return floori(attribute / 10.0)


## Attribute every hero starts with, before class and level.
static func start_attribute() -> int:
	return int(value("start_attribute", 5))


## +1 to every attribute per this many hero levels (level 4: +1, level 8: +2 ...).
static func level_attribute_bonus(level: int) -> int:
	return floori(level / maxf(value("levels_per_attribute_bonus", 4), 1.0))


## Base + per level above 1 + constitution (+ strength and wisdom per 10).
static func hero_max_health(strength: float, constitution: float, wisdom: float, level: int = 1) -> int:
	return int(value("hero_base_health", 20) + (level - 1) * value("health_per_level", 0)
			+ constitution * value("health_per_con", 2)
			+ tens(strength) * value("health_per_10_str", 1) + tens(wisdom) * value("health_per_10_wis", 2))


static func hero_max_mana(intelligence: float, level: int = 1) -> int:
	return int(value("hero_base_mana", 8) + intelligence * value("mana_per_int", 1) + (level - 1) * value("mana_per_level", 0.0))


static func hero_health_regen(constitution: float) -> float:
	return value("hero_health_regen", 0.1) + tens(constitution) * value("health_regen_per_10_con", 1)


## Mana per second: base + per 10 intelligence + per 10 wisdom (priests and paladins cast with wisdom).
static func hero_mana_regen(intelligence: float, wisdom: float = 0.0) -> float:
	return value("hero_mana_regen", 0.1) + tens(intelligence) * value("mana_regen_per_10_int", 1) \
			+ tens(wisdom) * value("mana_regen_per_10_wis", 0.0)


## Flat damage strength adds to every physical hit (and to skills, which scale with the hit).
static func strength_damage(strength: float) -> int:
	return floori(strength * value("damage_per_str", 1))


## Factor for spells from intelligence + bonuses, e.g. 10 INT = x1.2.
static func magic_damage_factor(intelligence: float, bonus: float = 0.0) -> float:
	return 1.0 + intelligence * value("magic_damage_per_int", 0.02) + bonus


## Factor for heals from wisdom and heal-power bonuses (passives, rings) in percent, all added up:
## 1 + 0.3 % per wisdom (combat.json) + bonus, e.g. 100 WIS and +20 % = x1.5. Added instead of multiplied so a
## late healer doesn't grow on three factors at once (max health, wisdom, passives).
static func heal_power(wisdom: float, bonus_percent: float = 0.0) -> float:
	return 1.0 + wisdom * value("heal_power_per_wis", 0.005) + bonus_percent / 100.0


static func shield_power(wisdom: float, bonus_percent: float = 0.0) -> float:
	return 1.0 + wisdom * value("shield_power_per_wis", 0.005) + bonus_percent / 100.0


## Shield points of a caster shield (status effect "caster_shield"): level + 5 x wisdom.
static func caster_shield(level: int, wisdom: float) -> float:
	return level * value("shield_per_caster_level", 1.0) + wisdom * value("shield_per_caster_wis", 5.0)


## Chance (0..max) to dodge a hit: agility + bonuses (buffs).
static func evasion(agility: float, bonus: float = 0.0) -> float:
	return clampf(tens(agility) * value("evasion_per_10_agi", 0.025) + bonus, 0.0, value("max_evasion", 0.9))


## How much shorter debuffs on this fighter last (0.3 = 30 %): resistance + bonuses.
static func tenacity(resistance: float, bonus: float = 0.0) -> float:
	return clampf(tens(resistance) * value("tenacity_per_10_res", 0.03) + bonus, 0.0, value("max_tenacity", 0.8))


## Shorter skill cooldowns (0.2 = 20 %), capped.
static func cooldown_reduction(bonus: float) -> float:
	return clampf(bonus, 0.0, value("max_cooldown_reduction", 0.5))


## Resistances with the RES attribute added to every damage kind (physical kinds, elements, magic).
static func resistances_with_attribute(resistances: Dictionary, resistance: float) -> Dictionary:
	var result: Dictionary = resistances.duplicate()
	var bonus: float = resistance * value("resistance_per_res", 1)
	if bonus == 0.0:
		return result
	for kind: String in DamageKinds.PHYSICAL_KINDS + DamageKinds.ELEMENT_KINDS + [DamageKinds.MAGIC]:
		result[kind] = result.get(kind, 0.0) + bonus
	return result


## Factor of `points` defense that gets through: base / (base + points) (base = 100).
## Below -50 counts as -50 (at most double damage).
static func defense_factor(points: float) -> float:
	var base: float = value("resistance_base", 100.0)
	return base / (base + maxf(points, -base * 0.5))


## Damage reduced by armor (or magic resistance) alone, 0..1 (armor 5 = 4.8 %).
static func reduction(points: float) -> float:
	return 1.0 - defense_factor(points)


## Factor of one damage share that gets through.
## Physical kinds (stab/blunt/slash): armor + resistance against that kind.
## Elements and magic: magic resistance + resistance against that kind.
## True damage ignores everything. `resistances` already include the RES attribute.
## `pen` (see penetration()) of the attacker lowers armor / magic resistance first.
static func mitigation(kind: String, armor: float, magic_resistance: float, resistances: Dictionary,
		pen: Dictionary = {}) -> float:
	if kind == DamageKinds.TRUE_DAMAGE:
		return 1.0
	var points: float = float(resistances.get(kind, 0.0))
	if DamageKinds.is_physical(kind):
		points += penetrated(armor, pen.get("armor_percent", 0.0), pen.get("armor_flat", 0.0))
	else:
		points += penetrated(magic_resistance, pen.get("magic_percent", 0.0), pen.get("magic_flat", 0.0))
	return defense_factor(points)


## Penetration of an attacker (the sum of weapon, equipment, skill and buffs):
## percent = share of the armor / magic resistance that is ignored (0.3 = 30 %),
## flat = points that are ignored after that (10 = 10 armor less).
static func penetration(armor_percent: float = 0.0, armor_flat: float = 0.0, magic_percent: float = 0.0,
		magic_flat: float = 0.0) -> Dictionary:
	return {"armor_percent": armor_percent, "armor_flat": armor_flat, "magic_percent": magic_percent, "magic_flat": magic_flat}


## Two penetrations added up (e.g. hero + skill).
static func add_penetration(a: Dictionary, b: Dictionary) -> Dictionary:
	var result: Dictionary = a.duplicate()
	for key: String in b:
		result[key] = result.get(key, 0.0) + b[key]
	return result


## Armor (or magic resistance) left after penetration: first the percent (capped at
## combat.json "max_penetration_percent"), then the flat value. Never below 0, and negative
## armor (weakness) stays as it is.
static func penetrated(points: float, percent: float, flat: float) -> float:
	if points <= 0.0:
		return points
	var rest: float = points * (1.0 - clampf(percent, 0.0, value("max_penetration_percent", 1.0)))
	return maxf(rest - maxf(flat, 0.0), 0.0)


## Texts for tooltips, e.g. ["Rüstungsdurchdringung 30 %", "Rüstungsdurchdringung +10"]
## (only the values that are set).
static func penetration_lines(pen: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if pen.get("armor_percent", 0.0) > 0.0:
		lines.append(Language.translate("Rüstungsdurchdringung %s %%") % DamageKinds.format_number(pen["armor_percent"] * 100.0))
	if pen.get("armor_flat", 0.0) > 0.0:
		lines.append(Language.translate("Rüstungsdurchdringung +%s") % DamageKinds.format_number(pen["armor_flat"]))
	if pen.get("magic_percent", 0.0) > 0.0:
		lines.append(Language.translate("Magiedurchdringung %s %%") % DamageKinds.format_number(pen["magic_percent"] * 100.0))
	if pen.get("magic_flat", 0.0) > 0.0:
		lines.append(Language.translate("Magiedurchdringung +%s") % DamageKinds.format_number(pen["magic_flat"]))
	return lines


## Armor (or magic resistance) of the target with its buffs/debuffs in percent
## (0.3 = +30 %, -0.3 = -30 %; several add up, at most -100 %).
static func changed_defense(points: float, percent: float) -> float:
	return points * maxf(1.0 + percent, 0.0)


## Chance for a critical hit (0..1): base + per agility point + bonuses (equipment, buffs, skill).
static func crit_chance(agility: float, bonus: float) -> float:
	return clampf(value("crit_chance", 0.05) + agility * value("crit_chance_per_agi", 0.01) + bonus, 0.0, 1.0)


## Damage factor of a critical hit: base (1.5 = 150 %) + bonuses.
static func crit_damage(bonus: float) -> float:
	return value("crit_damage", 1.5) + bonus


## EXP a hero gets for killing a monster: its "exp" x 1.5 if the monster is at least 5 levels
## above the hero, x 0.5 if at least 5 levels below (values in combat.json).
static func kill_experience(base: int, hero_level: int, enemy_level: int) -> int:
	var gap: int = int(value("kill_exp_level_gap", 5))
	var factor: float = 1.0
	if enemy_level - hero_level >= gap:
		factor = value("kill_exp_higher_factor", 1.5)
	elif hero_level - enemy_level >= gap:
		factor = value("kill_exp_lower_factor", 0.5)
	return roundi(base * factor)
