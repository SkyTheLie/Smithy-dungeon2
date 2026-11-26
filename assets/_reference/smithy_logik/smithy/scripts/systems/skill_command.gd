class_name SkillCommand
extends RefCounted
## Commands heroes follow for a learned skill ("Befehle", set in the SkillCommandWindow).
## A command is a Dictionary {"target": id, "stat": id, "op": id, "value": number}:
##   [target]              whom the skill hits, e.g. the enemy with the most health
##   [stat] [op] [value]   only use the skill when this is true, e.g. health of the target < 50 %
## What a hero may choose depends on his IQ (Hero.iq, start 60). Every option needs a tier
## (combat.json): "simple" iq_simple (80), "specific" iq_specific (100), "all" iq_all (120).
## Below iq_simple a hero can't follow commands at all. No command = the normal behaviour
## (a random enemy or the hero's role, see HeroRole; the most hurt ally). "Ohne diese Schwächung /
## Stärkung" holds the skill back while every possible target has its effect already.

## Tier of an option -> combat.json key of the IQ it needs.
const TIER_KEYS: Dictionary = {"none": "", "simple": "iq_simple", "specific": "iq_specific", "all": "iq_all"}
const TIER_DEFAULTS: Dictionary = {"none": 0, "simple": 80, "specific": 100, "all": 120}

## Targets: name, tier, side ("enemy" = for skills against enemies, "ally" = for ally skills).
const TARGETS: Dictionary = {
	"default": {"name": "Standard", "tier": "none", "side": "any"},
	"enemy_most_health": {"name": "Gegner mit den meisten Leben", "tier": "simple", "side": "enemy"},
	"enemy_least_health": {"name": "Gegner mit den wenigsten Leben", "tier": "simple", "side": "enemy"},
	"ally_least_health": {"name": "Verbündeter mit den wenigsten Leben", "tier": "simple", "side": "ally"},
	"ally_most_health": {"name": "Verbündeter mit den meisten Leben", "tier": "simple", "side": "ally"},
	"self": {"name": "Sich selbst", "tier": "simple", "side": "ally"},
	"boss": {"name": "Nur gegen Bosse", "tier": "specific", "side": "enemy"},
	"not_boss": {"name": "Erst die anderen, dann den Boss", "tier": "specific", "side": "enemy"},
	"enemy_without_effect": {"name": "Gegner ohne diese Schwächung", "tier": "specific", "side": "enemy"},
	"ally_without_effect": {"name": "Verbündeter ohne diese Stärkung", "tier": "specific", "side": "ally"},
	"enemy_least_health_percent": {"name": "Gegner mit den wenigsten Leben (in %)", "tier": "all", "side": "enemy"},
	"ally_least_health_percent": {"name": "Verbündeter mit den wenigsten Leben (in %)", "tier": "all", "side": "ally"},
}
## Conditions: what is compared.
const STATS: Dictionary = {
	"none": {"name": "immer", "tier": "none"},
	"target_health": {"name": "Leben des Ziels in %", "tier": "specific"},
	"own_health": {"name": "eigenes Leben in %", "tier": "specific"},
	"own_mana": {"name": "eigenes Mana in %", "tier": "all"},
	"enemy_count": {"name": "Anzahl Gegner", "tier": "all"},
}
const OPS: Dictionary = {
	"<": {"name": "<", "tier": "specific"},
	">": {"name": ">", "tier": "specific"},
	"<=": {"name": "≤", "tier": "all"},
	">=": {"name": "≥", "tier": "all"},
	"=": {"name": "=", "tier": "all"},
}


static func create(target: String = "default", stat: String = "none", op: String = "<", value: float = 50.0) -> Dictionary:
	return {"target": target, "stat": stat, "op": op, "value": value}


static func is_empty(command: Dictionary) -> bool:
	return command.is_empty() or (command.get("target", "default") == "default" and command.get("stat", "none") == "none")


## IQ an option needs (table = TARGETS, STATS or OPS).
static func iq_for(table: Dictionary, id: String) -> int:
	var tier: String = table.get(id, {}).get("tier", "all")
	if TIER_KEYS[tier].is_empty():
		return 0
	return int(CombatRules.value(TIER_KEYS[tier], TIER_DEFAULTS[tier]))


## The lowest IQ for any command (below it the hero can't follow commands).
static func min_iq() -> int:
	return int(CombatRules.value("iq_simple", 80))


## IQ the whole command needs.
static func required_iq(command: Dictionary) -> int:
	var needed: int = iq_for(TARGETS, command.get("target", "default"))
	if command.get("stat", "none") != "none":
		needed = maxi(needed, maxi(iq_for(STATS, command["stat"]), iq_for(OPS, command.get("op", "<"))))
	return needed


## Targets that make sense for this skill (enemy skills: enemy targets, ally skills: ally ones;
## skills on yourself or a whole side have no target to pick).
static func targets_for(skill: SkillData) -> Array[String]:
	var side: String = "enemy" if skill.target == SkillData.Target.ENEMY else "ally"
	var no_pick: bool = skill.target in [SkillData.Target.SELF, SkillData.Target.ALL_ENEMIES, SkillData.Target.ALL_ALLIES]
	var result: Array[String] = []
	for id: String in TARGETS:
		var target_side: String = TARGETS[id]["side"]
		if no_pick and target_side != "any":
			continue
		if target_side == "any" or target_side == side:
			result.append(id)
	return result


## "Gegner mit den meisten Leben · nur wenn Leben des Ziels in % < 50"
static func describe(command: Dictionary) -> String:
	if is_empty(command):
		return Language.translate("Standard")
	var parts: Array[String] = [TARGETS.get(command.get("target", "default"), TARGETS["default"])["name"]]
	if command.get("stat", "none") != "none":
		parts.append(Language.translate("nur wenn %s %s %s") % [STATS[command["stat"]]["name"], OPS.get(command.get("op", "<"), OPS["<"])["name"],
				DamageKinds.format_number(float(command.get("value", 0.0)))])
	return " · ".join(parts)


# --- In the fight -------------------------------------------------------------------

## The fighter the command chooses, or null if it wants the normal target ("default") or
## finds nobody (e.g. "boss" without a boss: then the skill waits).
static func pick_target(command: Dictionary, user: Combatant, opponents: Array[Combatant], allies: Array[Combatant],
		skill: SkillData = null) -> Combatant:
	match command.get("target", "default"):
		"enemy_most_health":
			return _extreme(opponents, func(f: Combatant) -> float: return f.health, true)
		"enemy_least_health":
			return _extreme(opponents, func(f: Combatant) -> float: return f.health, false)
		"enemy_least_health_percent":
			return _extreme(opponents, func(f: Combatant) -> float: return f.health / f.max_health, false)
		"ally_least_health":
			return _extreme(allies, func(f: Combatant) -> float: return f.health, false)
		"ally_most_health":
			return _extreme(allies, func(f: Combatant) -> float: return f.health, true)
		"ally_least_health_percent":
			return _extreme(allies, func(f: Combatant) -> float: return f.health / f.max_health, false)
		"self":
			return user
		"boss":
			for fighter in opponents:
				if fighter.is_alive() and fighter.is_boss:
					return fighter
		"not_boss":
			var open: Array[Combatant] = HeroRole.get_open_targets(opponents)
			var others: Array = open.filter(func(f: Combatant) -> bool: return not f.is_boss)
			return others.pick_random() if not others.is_empty() else (open[0] if not open.is_empty() else null)
		"enemy_without_effect":
			var debuffs: Array[StatusEffectData] = HeroRole.get_debuffs(skill)
			var fresh: Array = HeroRole.get_open_targets(opponents).filter(func(f: Combatant) -> bool:
				return not debuffs.any(func(effect: StatusEffectData) -> bool: return f.has_effect_id(String(effect.id))))
			return fresh.pick_random() if not fresh.is_empty() else null
		"ally_without_effect":
			var buffs: Array[StatusEffectData] = HeroRole.get_buffs(skill)
			var fresh: Array = allies.filter(func(f: Combatant) -> bool:
				return f.is_alive() and (f == user or f.buffable) \
						and not buffs.any(func(effect: StatusEffectData) -> bool: return f.has_effect_id(String(effect.id))))
			return fresh.pick_random() if not fresh.is_empty() else null
	return null


## Whether a target selection is needed but nobody fits (e.g. no boss in this wave).
static func lacks_target(command: Dictionary, picked: Combatant) -> bool:
	return command.get("target", "default") != "default" and picked == null


static func condition_met(command: Dictionary, user: Combatant, target: Combatant, opponents: Array[Combatant]) -> bool:
	var stat: String = command.get("stat", "none")
	if stat == "none":
		return true
	var current: float = 0.0
	match stat:
		"target_health":
			if target == null:
				return false
			current = target.health / target.max_health * 100.0
		"own_health":
			current = user.health / user.max_health * 100.0
		"own_mana":
			current = user.mana / user.max_mana * 100.0 if user.max_mana > 0.0 else 0.0
		"enemy_count":
			current = opponents.filter(func(f: Combatant) -> bool: return f.is_alive()).size()
	var wanted: float = float(command.get("value", 0.0))
	match command.get("op", "<"):
		"<":
			return current < wanted
		">":
			return current > wanted
		"<=":
			return current <= wanted
		">=":
			return current >= wanted
		"=":
			return is_equal_approx(current, wanted)
	return true


static func _extreme(fighters: Array[Combatant], measure: Callable, highest: bool) -> Combatant:
	var best: Combatant = null
	for fighter in fighters:
		if not fighter.is_alive():
			continue
		if best == null or (measure.call(fighter) > measure.call(best)) == highest and measure.call(fighter) != measure.call(best):
			best = fighter
	return best
