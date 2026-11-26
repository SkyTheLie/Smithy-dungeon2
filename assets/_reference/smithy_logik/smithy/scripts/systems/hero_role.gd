class_name HeroRole
extends RefCounted
## Roles of heroes in a fight ("Rolle", chosen in the hero window), unlocked by IQ (Hero.iq).
## Without a role a hero hits a random enemy that may be hit (each attack picks anew). A role
## decides whom the basic hits and the skills without a command (SkillCommand) go to:
##   boss_hunter   only bosses; without a boss in the wave random
##   cleaner       the other monsters first, the boss only when he is alone
##   finisher      the enemy with the least health in %
##   debuffer      debuff skills on an enemy that doesn't have that debuff yet
##   supporter     buff skills on an ally that doesn't have that buff yet (else the one whose buff
##                 runs out first), heals on the most hurt
## From combat.json "iq_focus" (80) a hero follows the player's focus (the enemy clicked in the
## battle window, Adventure.focus) - it beats boss_hunter, cleaner and finisher.
## IQ per role: combat.json "iq_role_<id>" (e.g. "iq_role_cleaner"), defaults in ROLES.

const ROLES: Dictionary = {
	"": {"name": "Keine (zufällig)", "iq": 0,
			"text": "Greift einen zufälligen Gegner an, jeder Angriff neu."},
	"boss_hunter": {"name": "Bossjäger", "iq": 85,
			"text": "Greift nur Bosse an. Ohne Boss einen zufälligen Gegner."},
	"cleaner": {"name": "Aufräumer", "iq": 85,
			"text": "Greift erst die anderen Gegner an, den Boss erst, wenn er allein ist."},
	"finisher": {"name": "Vollstrecker", "iq": 100,
			"text": "Greift den Gegner mit den wenigsten Leben (in %) an."},
	"debuffer": {"name": "Schwächer", "iq": 100,
			"text": "Schwächungen nur auf Gegner, die sie noch nicht haben."},
	"supporter": {"name": "Unterstützer", "iq": 110,
			"text": "Stärkungen nur auf Verbündete, die sie noch nicht haben."},
}


static func get_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(ROLES.keys())
	return ids


static func get_display_name(role: String) -> String:
	return Language.translate(ROLES.get(role, ROLES[""])["name"])


static func get_text(role: String) -> String:
	return Language.translate(ROLES.get(role, ROLES[""])["text"])


## IQ a hero needs for this role.
static func required_iq(role: String) -> int:
	if role.is_empty() or not ROLES.has(role):
		return 0
	return int(CombatRules.value("iq_role_" + role, ROLES[role]["iq"]))


## IQ from which a hero attacks the enemy the player focused in the battle window.
static func focus_iq() -> int:
	return int(CombatRules.value("iq_focus", 80))


# --- In the fight -------------------------------------------------------------------

## The enemies a single-target attack may hit now: a taunting one alone, else the living front
## row (the back row once the front row is down); veiled ones never.
static func get_open_targets(opponents: Array[Combatant]) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for fighter in opponents:
		if fighter.is_alive() and fighter.is_taunting():
			result.append(fighter)
			return result
	for back: bool in [false, true]:
		for fighter in opponents:
			if fighter.is_alive() and fighter.back_row == back and not fighter.is_untargetable():
				result.append(fighter)
		if not result.is_empty():
			return result
	return result


## The enemy `fighter` hits with a basic hit or a skill (`skill`, null = basic hit): the player's
## focus if the fighter follows it, else by role, else a random open one. null = nobody open.
static func pick_enemy(fighter: Combatant, opponents: Array[Combatant], focus: Combatant,
		skill: SkillData = null) -> Combatant:
	var open: Array[Combatant] = get_open_targets(opponents)
	if open.is_empty():
		return null
	if open.size() == 1:
		return open[0]
	if fighter.role == "debuffer" and skill != null and not get_debuffs(skill).is_empty():
		var fresh: Array[Combatant] = []
		fresh.assign(open.filter(func(enemy: Combatant) -> bool: return not _has_any(enemy, get_debuffs(skill))))
		if not fresh.is_empty():
			return fresh.pick_random()
	if fighter.can_focus and focus != null and open.has(focus):
		return focus
	match fighter.role:
		"boss_hunter":
			var bosses: Array = open.filter(func(enemy: Combatant) -> bool: return enemy.is_boss)
			if not bosses.is_empty():
				return bosses.pick_random()
		"cleaner":
			var others: Array = open.filter(func(enemy: Combatant) -> bool: return not enemy.is_boss)
			if not others.is_empty():
				return others.pick_random()
		"finisher":
			var lowest: Combatant = open[0]
			for enemy in open:
				if enemy.health / enemy.max_health < lowest.health / lowest.max_health:
					lowest = enemy
			return lowest
	return open.pick_random()


## The ally a supporter gives the buffs of `skill` to: one without them (others before himself),
## else the one whose buff runs out first. null = no buff skill or not a supporter.
static func pick_ally(fighter: Combatant, allies: Array[Combatant], skill: SkillData) -> Combatant:
	if fighter.role != "supporter" or skill.heal_percent > 0.0:
		return null
	var buffs: Array[StatusEffectData] = get_buffs(skill)
	if buffs.is_empty():
		return null
	var living: Array[Combatant] = []
	living.assign(allies.filter(func(ally: Combatant) -> bool:
		return ally.is_alive() and (ally == fighter or ally.buffable)))
	if living.is_empty():
		return null
	var fresh: Array = living.filter(func(ally: Combatant) -> bool: return not _has_any(ally, buffs))
	if not fresh.is_empty():
		var others: Array = fresh.filter(func(ally: Combatant) -> bool: return ally != fighter)
		return (others if not others.is_empty() else fresh).pick_random()
	var soonest: Combatant = living[0]
	for ally in living:
		if _time_left(ally, buffs) < _time_left(soonest, buffs):
			soonest = ally
	return soonest


## Debuffs a skill puts on its enemy target.
static func get_debuffs(skill: SkillData) -> Array[StatusEffectData]:
	return _effects_of(skill, SkillData.Target.ENEMY, StatusEffectData.Kind.DEBUFF)


## Buffs a skill gives its ally target.
static func get_buffs(skill: SkillData) -> Array[StatusEffectData]:
	return _effects_of(skill, SkillData.Target.ALLY, StatusEffectData.Kind.BUFF)


static func _effects_of(skill: SkillData, target: SkillData.Target, kind: StatusEffectData.Kind) -> Array[StatusEffectData]:
	var result: Array[StatusEffectData] = []
	if skill == null:
		return result
	for entry in skill.effects:
		var effect: StatusEffectData = entry["effect"]
		if entry["target"] == target and effect and effect.kind == kind:
			result.append(effect)
	return result


static func _has_any(fighter: Combatant, effects: Array[StatusEffectData]) -> bool:
	for effect in effects:
		if fighter.has_effect_id(String(effect.id)):
			return true
	return false


## Seconds the first of these effects on `fighter` has left (0 = none of them).
static func _time_left(fighter: Combatant, effects: Array[StatusEffectData]) -> float:
	var left: float = INF
	for effect in effects:
		var active: Combatant.ActiveEffect = fighter.get_active_effect(String(effect.id))
		left = minf(left, active.time_left if active else 0.0)
	return left
