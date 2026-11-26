class_name SkillData
extends Resource
## A skill heroes AND monsters can have (created by ContentDB from data/content/skills.json,
## format: docs/CONTENT.md). Heroes learn them in the three trees of their class
## (data/content/skill_trees.json, HeroClass.get_trees), monsters have them in enemies.json.
## In a fight an active skill is used automatically as soon as its cooldown is over and there is
## enough mana: optional damage, then its effects. Passive skills (is_passive) are never used, their
## values (get_passive_value) count all the time (Hero, Combatant).

enum DamageKind { PHYSICAL, MAGIC }
## ALLY = the ally with the lowest health in percent (yourself included). ALL_ENEMIES / ALL_ALLIES =
## every living fighter of that side (yourself included in the allies). New values only at the end.
enum Target { ENEMY, SELF, ALLY, ALL_ENEMIES, ALL_ALLIES }

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export_multiline var description: String = "":
	get:
		return Language.translate(description)
@export var icon: Texture2D
## Seconds between two uses.
@export var cooldown: float = 5.0
## Mana at level 1; every level above costs more (get_mana_cost).
@export var mana_cost: int = 0
## Share of mana_cost added per level above 1 (0.25: level 3 = 150 %, level 5 = 200 %).
## -1 = combat.json "skill_mana_per_level".
@export var mana_per_level: float = -1.0
## Damage at level 1 = this share of the weapon damage (1.5 = 150 %; spells: of the spell
## damage = base + magic damage of the weapon, x intelligence factor). 0 = no damage (a buff).
@export var damage_multiplier: float = 1.5
## Added to damage_multiplier per level above 1 (0.15: level 2 = 165 %, level 5 = 210 %).
@export var damage_per_level: float = 0.15
## Main attribute of the damage (the largest share of `scaling`); monsters scale with it alone.
@export var scaling_attribute: ItemAttribute.Type = ItemAttribute.Type.STRENGTH
## Attributes a hero's damage grows with: ItemAttribute.Type -> share (1.0 = 100 %), e.g. rapid
## shot {AGILITY: 1.0, STRENGTH: 0.4}. The weighted sum ("scaled attribute", Combatant
## .get_scaled_attribute) counts like strength for weapon skills (+0.5 damage per point) and like
## intelligence for spells (+2 % per point), see CombatRules. Empty = scaling_attribute 100 %.
@export var scaling: Dictionary = {}
## A spell (magic) whose base is the weapon damage instead of the magic damage of a staff: the
## ranger's nature magic with a bow, the paladin's judgment with a hammer (skills.json "base": "weapon").
## Counted like a weapon skill (weapon damage + attributes), but it is magic damage.
@export var spell_from_weapon: bool = false
## Old field, no longer used (damage always comes from weapon / spell damage).
@export var adds_weapon_damage: bool = true
## Physical damage is a share of the weapon damage and reduced by armor; magic damage (spells)
## grows with intelligence and is reduced by magic resistance (see CombatRules).
@export var damage_kind: DamageKind = DamageKind.PHYSICAL
@export var element: Element.Type = Element.Type.NONE
@export var damage_type: DamageType.Type = DamageType.Type.NONE
## How the damage is split: DamageKinds id -> share, e.g. {"fire": 0.5, "slash": 0.5}.
## Empty = derived (see get_damage_split).
@export var damage_split: Dictionary = {}
## Extra crit chance of this skill (0.1 = +10 %).
@export var crit_chance: float = 0.0
## Penetration of this skill's hits on top of the user's (CombatRules.penetration, e.g. armor
## break: {"armor_percent": 0.3} = ignores 30 % of the target's armor).
@export var penetration: Dictionary = {}
## Who the skill is aimed at (a heal on yourself = SELF).
@export var target: Target = Target.ENEMY
## Status effects: {"effect": StatusEffectData, "chance": 0..1, "chance_per_level": float,
## "target": Target, "stacks": int, "duration": seconds (0 = the effect's own duration),
## "levels": Array of StatusEffectData, one per skill level (empty = "effect" on every level;
## skills.json "set" / "per_level" make the effect stronger per level, see get_effect)}.
@export var effects: Array[Dictionary] = []

@export_group("Skill tree")
## Row in the tree (0 = bottom).
@export var tier: int = 0
## Skill points that must already be spent in the same tree to learn it (Hero.get_learn_blocker).
@export var required_points: int = 0
## Skill id that has to be learned first (empty = none), and an optional second one.
@export var required_skill_id: String = ""
@export var extra_required_skill_id: String = ""
## Highest level (every level costs a skill point).
@export var max_level: int = 5
## Weapon types (weapon_types.json ids) the hero must hold in one of his hands to use it in a
## fight, e.g. shield bash ["shield"], aimed shot ["bow", "longbow"]. Empty = no weapon needed.
## Learning works without; Combatant.from_hero leaves the skill out (Hero.can_use_skill). Passive
## skills with weapons only count while the hero holds one.
@export var required_weapon_types: Array[String] = []

@export_group("Passive")
## true = never used in a fight; its values count all the time.
@export var passive_skill: bool = false
## Passive values: name -> [value at level 1, added per level], e.g. {"armor": [8, 8]} = armor
## +8 % (+8 % per level). Names: docs/CONTENT.md ("passive").
@export var passive: Dictionary = {}
## Passive values that also grow with an attribute: name -> {attribute type: added per point},
## e.g. {"damage_poison": {INTELLIGENCE: 0.5}} = +0.5 % poison damage per intelligence point.
## Only counts while the skill is learned (skills.json "passive_scaling").
@export var passive_scaling: Dictionary = {}
## Weapon types the hero may hold although his class can't: "right_hand" / "left_hand" -> ids.
@export var unlock_weapons: Dictionary = {}

@export_group("Special")
## Heals every target by this % of its max health (+ per level), times the heal power.
@export var heal_percent: float = 0.0
@export var heal_per_level: float = 0.0
## Costs the user this % of his own max health.
@export var self_damage_percent: float = 0.0
## Number of hits (each rolls crit and effects on its own); with random_targets every hit picks a
## random opponent. hit_splits: own damage split per hit (cycled).
@export var hits: int = 1
@export var random_targets: bool = false
@export var hit_splits: Array[Dictionary] = []
## Targets in a row (first + jumps, chain lightning / piercing shot) and the damage lost per jump.
@export var chain_targets: int = 1
@export var chain_falloff: float = 0.0
## Targets below this share of their health take damage x execute_factor.
@export var execute_below: float = 0.0
@export var execute_factor: float = 1.0
## Against opponents whose hits are (partly) of this kind (e.g. "dark"): damage x bonus_vs_factor.
@export var bonus_vs_kind: String = ""
@export var bonus_vs_factor: float = 1.0
## Extra crit damage of this skill (0.5 = +50 %); always critical from stealth.
@export var crit_damage: float = 0.0
@export var crit_from_stealth: bool = false
## The cooldown is over at once when the hit kills; usable once per dungeon.
@export var reset_on_kill: bool = false
@export var once_per_dungeon: bool = false
## Damage from own values instead of the weapon: "armor" / "max_health" -> factor.
@export var base_from: Dictionary = {}
## Summon (summons.json id), share of the summoner's values at level 1 (0.1 = 10 %) and per level,
## seconds it stays (0 = until it dies), and stronger summons once a skill is learned:
## [{"skill": id, "summon": id, "share": 1.0}] (the last learned one counts).
@export var summon_id: String = ""
@export var summon_share: float = 0.0
@export var summon_share_per_level: float = 0.0
@export var summon_duration: float = 0.0
@export var summon_upgrades: Array[Dictionary] = []
## The user's summon does the hit (its own damage); effects put on the summon; blows up the
## user's summon (damage in its kinds).
@export var pet_attack: bool = false
@export var pet_effects: Array[Dictionary] = []
@export var sacrifice_summon: bool = false
## Status effect id: damage per stack of it on the target, the effect is used up (toxic burst).
@export var detonate_effect_id: String = ""
## For all allies: cooldowns shorter by these seconds, mana + % of the max (and per level).
@export var allies_cooldown: float = 0.0
@export var allies_mana_percent: float = 0.0
@export var allies_mana_per_level: float = 0.0
## All allies heal by this share of the damage dealt (0.1 = 10 %).
@export var heal_allies_from_damage: float = 0.0
## Monsters: calls these monsters (enemies.json ids) into the fight, `summon_enemy_count` per use,
## as long as fewer than `summon_enemy_max` of them live (e.g. the dragon's fire elementals).
@export var summon_enemy_ids: Array[String] = []
@export var summon_enemy_count: int = 1
@export var summon_enemy_max: int = 2
## Monsters: an ALLY skill picks a random living fighter of its side (itself included) instead of
## the most hurt one (skills.json "random_ally").
@export var random_ally: bool = false
## Only usable while the user carries this status effect (skills.json "requires_effect", e.g.
## "shrouded": the ghost lord heals only while hidden behind his ghosts).
@export var requires_effect_id: String = ""
## The skill also hits its user (e.g. the lava golem's eruption, which heals him through his
## absorption, EnemyData.absorb).
@export var hits_self: bool = false

@export_group("Battle window")
## How the user moves (FighterMotion.POSES); "" = from the skill (magic/support: "cast") or the weapon.
@export var anim: String = ""
## Effect on the target (BattleVfx.KINDS); "" = from the pose (e.g. "slash" for "swing", "bolt" for "cast").
@export var vfx: String = ""
## Area skills (all enemies, heals on all allies): one effect over the whole group, e.g. "area_meteor";
## "" = from the main damage kind (BattleVfx.AREA_KINDS), "none" = one effect per target.
@export var area_vfx: String = ""


## Names of the passive values for tooltips ("%" = shown with a percent sign).
const PASSIVE_NAMES: Dictionary = {
	"max_health": "Max. Leben +%s %%", "armor": "Rüstung +%s %%", "tenacity": "Zähigkeit +%s %%",
	"evasion": "Ausweichen +%s %%", "crit_chance": "Krit-Chance +%s %%", "crit_damage": "Krit-Schaden +%s %%",
	"cooldown": "Abklingzeiten −%s %%", "buff_duration": "Buff-Dauer +%s %%", "debuff_duration": "Debuff-Dauer +%s %%",
	"debuff_chance": "Debuff-Chance +%s %%", "heal_power": "Heilkraft +%s %%", "mana_regen": "Mana +%s/s",
	"health_regen": "Leben +%s %% pro Sekunde", "health_regen_flat": "Leben +%s/s", "element_resist": "Element-Resistenzen +%s",
	"magic_pen": "Magiedurchdringung +%s %%", "damage_slash": "Schnittschaden +%s %%", "damage_blunt": "Stumpfschaden +%s %%",
	"damage_element": "Element-Schaden +%s %%", "damage_poison": "Giftschaden +%s %%", "arcane_blade": "Angriffe +%s %% Magieschaden",
	"damage_stab": "Stichschaden +%s %%", "damage_fire": "Feuerschaden +%s %%", "damage_water": "Wasserschaden +%s %%",
	"damage_earth": "Erdschaden +%s %%", "damage_air": "Luftschaden +%s %%", "damage_dark": "Dunkelschaden +%s %%",
	"damage_light": "Lichtschaden +%s %%", "damage_lightning": "Blitzschaden +%s %%", "damage_ice": "Eisschaden +%s %%",
	"damage_magic": "Magieschaden +%s %%",
	"low_health_damage": "Unter 50 %% Leben: Schaden +%s %%", "low_health_lifesteal": "Unter 50 %% Leben: Lebensraub %s %%",
	"parry": "Parade %s %%", "stealth_damage": "Aus dem Verschleiern: Schaden +%s %%",
	"poisoned_target_damage": "Gegen Vergiftete: Schaden +%s %%", "skill_lifesteal": "Skill-Lebensraub %s %%",
	"lifesteal": "Lebensraub %s %%", "kill_heal": "Besiegt er einen Gegner: +%s %% Leben",
	"second_wind": "Zweiter Atem: einmal pro Stufe unter 35 %% Leben +%s %% Leben", "stage_heal": "Nach jeder Stufe +%s %% Leben",
	"offhand": "Linke Hand: +%s %% Schaden", "poison_chance": "Jeder Angriff: %s %% Gift", "summon_duration": "Beschwörungen +%s s", "bond_damage": "Mit Beschwörung: Schaden +%s %%",
	"bond_mana_regen": "Mit Beschwörung: Mana +%s/s", "pet_damage": "Wolf: Schaden +%s %%", "pet_health": "Wolf: Leben +%s %%",
	"pet_guard": "Wolf schützt: %s %%", "aura_armor": "Gruppe: Rüstung +%s %%", "martyr": "Märtyrer-Heilung %s %%",
}


func is_passive() -> bool:
	return passive_skill


## Like get_passive_text, with the attribute share (passive_scaling) of these attributes.
func _get_passive_text_with(level: int, attributes: Dictionary) -> String:
	var parts: Array[String] = []
	for stat: String in passive:
		var template: String = Language.translate(PASSIVE_NAMES.get(stat, stat + " %s"))
		parts.append(template % DamageKinds.format_number(get_passive_value(stat, maxi(level, 1), attributes)))
	return " · ".join(parts)


## e.g. "Rüstung +16 % · Zähigkeit +8 %" at this level ("" without values).
func get_passive_text(level: int) -> String:
	var parts: Array[String] = []
	for stat: String in passive:
		var template: String = Language.translate(PASSIVE_NAMES.get(stat, stat + " %s"))
		parts.append(template % DamageKinds.format_number(get_passive_value(stat, maxi(level, 1))))
	return " · ".join(parts)


## A passive value at this level (0 if the skill doesn't have it), e.g. "armor" level 3 = 24.
## `attributes` (type -> points, e.g. the hero's): adds the share from `passive_scaling`.
func get_passive_value(stat: String, level: int, attributes: Dictionary = {}) -> float:
	if level <= 0 or not passive.has(stat):
		return 0.0
	var values: Array = passive[stat]
	var total: float = float(values[0]) + float(values[1]) * (level - 1)
	var per_point: Dictionary = passive_scaling.get(stat, {})
	for type: int in per_point:
		total += float(attributes.get(type, 0)) * float(per_point[type])
	return total


## e.g. "Giftschaden +0,5 % pro Punkt Intelligenz" ("" without passive_scaling).
func get_passive_scaling_text() -> String:
	var parts: Array[String] = []
	for stat: String in passive_scaling:
		var per_point: Dictionary = passive_scaling[stat]
		for type: int in per_point:
			var template: String = Language.translate(PASSIVE_NAMES.get(stat, stat + " %s"))
			parts.append(Language.translate("%s pro Punkt %s") % [template % DamageKinds.format_number(float(per_point[type])),
					Language.translate(ItemAttribute.NAMES[type])])
	return " · ".join(parts)


## The effect of an entry at this skill level (stronger per level if skills.json says so).
func get_effect(entry: Dictionary, level: int) -> StatusEffectData:
	var levels: Array = entry.get("levels", [])
	if levels.is_empty():
		return entry["effect"]
	return levels[clampi(level, 1, levels.size()) - 1]


func get_effect_chance(entry: Dictionary, level: int) -> float:
	return minf(1.0, entry["chance"] + entry.get("chance_per_level", 0.0) * maxi(level - 1, 0))


func get_heal_percent(level: int) -> float:
	return heal_percent + heal_per_level * maxi(level - 1, 0)


func get_summon_share(level: int) -> float:
	return summon_share + summon_share_per_level * maxi(level - 1, 0)


func get_extra_required_skill() -> SkillData:
	return ContentDB.skill(extra_required_skill_id) if not extra_required_skill_id.is_empty() else null


## e.g. "Bögen oder Langbögen" ("" = no weapon needed).
func get_required_weapons_text() -> String:
	var names: Array[String] = []
	for type_id in required_weapon_types:
		var type: WeaponType = ContentDB.weapon_type(type_id)
		names.append(type.display_name if type else type_id)
	return Language.translate(" oder ").join(names)


func get_required_skill() -> SkillData:
	return ContentDB.skill(required_skill_id) if not required_skill_id.is_empty() else null


## Damage factor at this level (level 1 = damage_multiplier).
func get_damage_multiplier(level: int) -> float:
	return damage_multiplier + maxi(level - 1, 0) * damage_per_level


## The kinds its damage is made of. Without its own split: magic skills = their element (or
## pure magic), physical skills = their damage type, otherwise the weapon's split.
func get_damage_split(weapon_split: Dictionary = {}) -> Dictionary:
	if not damage_split.is_empty():
		return damage_split
	if damage_kind == DamageKind.MAGIC:
		return {DamageKinds.from_element(element) if element != Element.Type.NONE else DamageKinds.MAGIC: 1.0}
	if damage_type != DamageType.Type.NONE:
		return {DamageKinds.from_damage_type(damage_type): 1.0}
	return weapon_split if not weapon_split.is_empty() else {DamageKinds.PHYSICAL: 1.0}


## Mana of one use at this level: mana_cost + mana_per_level share per level above 1.
func get_mana_cost(level: int = 1) -> int:
	if mana_cost <= 0:
		return 0
	var per_level: float = mana_per_level if mana_per_level >= 0.0 else CombatRules.value("skill_mana_per_level", 0.0)
	return roundi(mana_cost * (1.0 + per_level * (maxi(level, 1) - 1)))


func is_magic() -> bool:
	return damage_kind == DamageKind.MAGIC


## Shares of the attributes the damage grows with (see `scaling`).
func get_scaling() -> Dictionary:
	if scaling.is_empty():
		return {scaling_attribute: 1.0}
	return scaling


## Spells with the staff formula (magic damage x attribute factor); everything else counts the
## weapon damage + attribute bonus.
func uses_spell_damage() -> bool:
	return is_magic() and not spell_from_weapon


## e.g. "100 % Beweglichkeit + 40 % Stärke".
func get_scaling_text() -> String:
	var parts: Array[String] = []
	var shares: Dictionary = get_scaling()
	var types: Array = shares.keys()
	types.sort_custom(func(a: int, b: int) -> bool: return shares[a] > shares[b])
	for type: int in types:
		parts.append("%d %% %s" % [roundi(shares[type] * 100.0), Language.translate(ItemAttribute.NAMES[type])])
	return " + ".join(parts)


## True if the hero's attributes count for the damage (not for damage from armor / health or from a summon).
func scales_with_attributes() -> bool:
	return damage_multiplier > 0.0 and base_from.is_empty() and not pet_attack


## e.g. "150 % Waffenschaden" / "150 % Zauberschaden" at this level, or "" without damage.
func get_damage_text(level: int) -> String:
	if damage_multiplier <= 0.0:
		return ""
	return "%d %% %s" % [roundi(get_damage_multiplier(maxi(level, 1)) * 100.0), Language.translate("Zauberschaden") if is_magic() else Language.translate("Waffenschaden")]


## Short summary for windows, e.g. "Abklingzeit 5 s · 5 Mana · 150 % Stärke + Waffenschaden · Blutung".
func get_summary(level: int = 1) -> String:
	var parts: Array[String] = [Language.translate("Abklingzeit %s s") % DamageKinds.format_number(cooldown)]
	if mana_cost > 0:
		parts.append(Language.translate("%d Mana") % get_mana_cost(level))
	if damage_multiplier > 0.0:
		parts.append(get_damage_text(level))
	for entry in effects:
		var effect: StatusEffectData = entry["effect"]
		var chance: float = entry.get("chance", 1.0)
		parts.append(effect.display_name + ("" if chance >= 1.0 else " (%d %%)" % roundi(chance * 100.0)))
	return " · ".join(parts)


## Tooltip (BBCode) in the skill tree: name, level, description, damage with its kinds in their
## colours, values now and on the next level. `detailed` (Shift held) adds how the damage is
## split and calculated, crit, every effect with chance, duration and target.
## `fighter` (the hero as he goes into the dungeon, Combatant.from_hero): the damage he really
## does with this skill (weapon, attributes, rings, passives) and the cooldown with his cooldown
## reduction; Shift shows how it is made up.
func get_tooltip(level: int, detailed: bool = false, fighter: Combatant = null) -> String:
	var title: String = Language.translate("[b]%s[/b]  (Stufe %d/%d)") % [display_name, level, max_level]
	if is_passive():
		title += "  [color=#9e998f]passiv[/color]"
	var lines: Array[String] = [title, description, ""]
	var shown_level: int = maxi(level, 1)
	if damage_multiplier > 0.0:
		var hit_text: String = get_damage_text(shown_level)
		if hits > 1:
			hit_text = "%d × %s" % [hits, hit_text]
		lines.append(Language.translate("Schaden: %s · %s") % [hit_text, DamageKinds.split_text(get_damage_split())])
		if scales_with_attributes():
			lines.append(Language.translate("Skaliert mit: %s") % get_scaling_text())
	var estimate: Dictionary = fighter.estimate_skill(self, shown_level) if fighter and damage_multiplier > 0.0 else {}
	if not estimate.is_empty():
		lines.append(_get_estimate_line(estimate))
		if estimate.get("no_arrows", false):
			lines.append(Language.translate("[color=#e0574b]Keine Pfeile: Bogen-Skills machen nur %d %% Schaden![/color]") % roundi(float(estimate["arrow_factor"]) * 100.0))
	if not passive.is_empty():
		lines.append("[color=#6fd38a]%s[/color]" % get_passive_text(shown_level))
		if level > 0 and level < max_level:
			lines.append(Language.translate("Nächste Stufe: ") + get_passive_text(level + 1))
		if not passive_scaling.is_empty():
			lines.append(Language.translate("Skaliert mit: %s") % get_passive_scaling_text())
			if fighter:
				lines.append(Language.translate("[color=#f2cc80]Beim Helden: %s[/color]") % _get_passive_text_with(shown_level, fighter.attributes))
	if heal_percent > 0.0:
		lines.append(Language.translate("[color=#6fd38a]Heilung: %s %% des max. Lebens[/color]") % DamageKinds.format_number(get_heal_percent(shown_level)))
		if fighter:
			lines.append(Language.translate("[color=#f2cc80]Beim Helden: %s %% des max. Lebens des Ziels[/color]") % _number(get_heal_percent(shown_level) * fighter.get_heal_power(), 0.1))
	if not summon_id.is_empty():
		var duration_text: String = Language.translate("bis zum Tod") if summon_duration <= 0.0 else Language.translate("%s s") % DamageKinds.format_number(summon_duration)
		lines.append(Language.translate("Beschwörung: %d %% der Werte, %s") % [roundi(get_summon_share(shown_level) * 100.0), duration_text])
	lines.append_array(CombatRules.penetration_lines(penetration))
	if is_passive() and cooldown > 0.0:
		# A passive that triggers itself (Märtyrer): its cooldown like an active skill's.
		lines.append(_get_cooldown_text(fighter))
	elif not is_passive():
		var parts: Array[String] = [_get_cooldown_text(fighter)]
		if mana_cost > 0:
			parts.append(Language.translate("%d Mana") % get_mana_cost(shown_level))
		if once_per_dungeon:
			parts.append(Language.translate("einmal pro Dungeon"))
		lines.append(" · ".join(parts))
	for entry in effects:
		var effect: StatusEffectData = get_effect(entry, shown_level)
		var chance: float = get_effect_chance(entry, shown_level)
		var text: String = effect.display_name + ("" if chance >= 1.0 else " (%d %%)" % roundi(chance * 100.0))
		# A link to the effect's lexicon page (like EffectInfo.link; that one is not used here so
		# the resource classes don't depend on the UI side).
		lines.append("[url=effect:%s][color=#%s]%s[/color][/url]" % [effect.id, effect.color.to_html(false), text])
		if effect.caster_shield and fighter:
			lines.append(Language.translate("[color=#f2cc80]Beim Helden: Schild %d[/color]") % roundi(effect.get_caster_shield(fighter)))
	if not required_weapon_types.is_empty():
		lines.append(Language.translate("[color=#f2cc80]Nur mit: %s[/color]") % get_required_weapons_text())
	if level > 0 and level < max_level and damage_multiplier > 0.0:
		lines.append(Language.translate("Nächste Stufe: ") + get_damage_text(level + 1))
	if level > 0 and level < max_level and get_mana_cost(level + 1) > get_mana_cost(level):
		lines.append(Language.translate("Nächste Stufe: %d Mana") % get_mana_cost(level + 1))
	if level == 0:
		var needs: Array[String] = []
		if required_points > 0:
			needs.append(Language.translate("ab %d Punkten im Baum") % required_points)
		for required in [get_required_skill(), get_extra_required_skill()]:
			if required:
				needs.append(Language.translate("benötigt ") + required.display_name)
		if not needs.is_empty():
			var text: String = ", ".join(needs)
			lines.append(text.left(1).to_upper() + text.substr(1))
	if detailed:
		lines.append_array(_get_detail_lines(shown_level))
		if not estimate.is_empty():
			lines.append_array(_get_estimate_details(estimate))
		if heal_percent > 0.0 and fighter:
			lines.append_array(_get_heal_details(shown_level, fighter))
	else:
		lines.append("[color=#9e998f][font_size=11]Shift: Details[/font_size][/color]")
	return "\n".join(lines)


## "Beim Helden: 120–150 Schaden (Krit 15 %: ×1,5)", per hit for skills with several hits.
func _get_estimate_line(estimate: Dictionary) -> String:
	var text: String = Language.translate("[color=#f2cc80]Beim Helden: %s Schaden[/color]") % _range_text(estimate["min"], estimate["max"])
	if int(estimate["hits"]) > 1:
		text += Language.translate(" pro Treffer, %d Treffer") % int(estimate["hits"])
	if float(estimate["crit_chance"]) > 0.0:
		text += Language.translate(" · Krit %d %%: ×%s") % [roundi(float(estimate["crit_chance"]) * 100.0),
				DamageKinds.format_number(snappedf(float(estimate["crit_factor"]), 0.01))]
	return text


## "Abklingzeit 4,3 s (ohne Reduktion 5 s)" with the hero's cooldown reduction, else the base value.
func _get_cooldown_text(fighter: Combatant) -> String:
	if fighter == null or fighter.cooldown_reduction <= 0.0:
		return Language.translate("Abklingzeit %s s") % DamageKinds.format_number(cooldown)
	var reduced: float = snappedf(cooldown * (1.0 - fighter.cooldown_reduction), 0.1)
	return Language.translate("Abklingzeit %s s (ohne Reduktion %s s, −%d %%)") % [DamageKinds.format_number(reduced),
			DamageKinds.format_number(cooldown), roundi(fighter.cooldown_reduction * 100.0)]


## With Shift: how the hero's damage is made up and how much of each kind it is.
func _get_estimate_details(estimate: Dictionary) -> Array[String]:
	var lines: Array[String] = ["", Language.translate("[color=#f2cc80]Rechnung beim Helden[/color]")]
	var formula: String = estimate.get("formula", "weapon")
	var parts: Array = estimate.get("attribute_parts", [])
	if formula == "base_from":
		lines.append(Language.translate("Grundwert: %s (aus Rüstung / Leben)") % _range_text(estimate["base_min"], estimate["base_max"]))
	elif formula == "spell":
		lines.append(Language.translate("Zauberschaden der Waffe: %s") % _range_text(estimate["magic_min"], estimate["magic_max"]))
		lines.append(Language.translate("× %s aus Attributen (1 + %s %% je Punkt):") % [_number(float(estimate["attribute_bonus"]), 0.01),
				_number(CombatRules.value("magic_damage_per_int", 0.02) * 100.0, 0.1)])
		for part: Dictionary in parts:
			lines.append(Language.translate("    %s %s × %d %% = %s Punkte (+%s %%)") % [Language.translate(ItemAttribute.NAMES[part["type"]]),
					_number(part["value"], 1.0), roundi(float(part["share"]) * 100.0), _number(float(part["value"]) * float(part["share"]), 0.1),
					_number(float(part["bonus"]) * 100.0, 1.0)])
		lines.append(Language.translate("= Grundwert %s") % _range_text(estimate["base_min"], estimate["base_max"]))
	else:
		lines.append(Language.translate("Waffenschaden: %s") % _range_text(estimate["weapon_min"], estimate["weapon_max"]))
		for part: Dictionary in parts:
			lines.append(Language.translate("+ %s %s × %d %% × %s = +%s") % [Language.translate(ItemAttribute.NAMES[part["type"]]),
					_number(part["value"], 1.0), roundi(float(part["share"]) * 100.0),
					_number(CombatRules.value("damage_per_str", 0.5), 0.1), _number(part["bonus"], 0.1)])
		if not parts.is_empty():
			lines.append(Language.translate("    zusammen +%s aus Attributen (abgerundet)") % _number(float(estimate["attribute_bonus"]), 1.0))
		if estimate.get("no_arrows", false):
			lines.append(Language.translate("[color=#e0574b]× %d %%: keine Pfeile im Köcher![/color]") % roundi(float(estimate["arrow_factor"]) * 100.0))
		if float(estimate.get("arrow_max", 0.0)) > 0.0:
			lines.append(Language.translate("+ Pfeil: %s") % _range_text(estimate["arrow_min"], estimate["arrow_max"]))
		lines.append(Language.translate("= Grundwert %s") % _range_text(estimate["base_min"], estimate["base_max"]))
	lines.append(Language.translate("× %d %% Skill (Stufe)") % roundi(float(estimate["multiplier"]) * 100.0))
	if not is_equal_approx(float(estimate["kind_factor"]), 1.0):
		lines.append(Language.translate("× %s Schadensboni der Schadensart (Passive, Ringe)") % _number(float(estimate["kind_factor"]), 0.01))
	if float(estimate["extra_max"]) > 0.0:
		lines.append(Language.translate("+ %s Aufwertung der Waffe") % _range_text(estimate["extra_min"], estimate["extra_max"]))
	if not is_equal_approx(float(estimate["damage_factor"]), 1.0):
		lines.append(Language.translate("× %s Schaden allgemein (Passive)") % _number(float(estimate["damage_factor"]), 0.01))
	lines.append(Language.translate("= %s Gesamtschaden vor Rüstung und Resistenzen des Gegners") % _range_text(estimate["min"], estimate["max"]))
	var split: Dictionary = estimate["split"]
	var kinds: Array[String] = []
	for kind: String in split:
		kinds.append(DamageKinds.colored("%s %s" % [DamageKinds.get_display_name(kind),
				_range_text(float(estimate["min"]) * split[kind], float(estimate["max"]) * split[kind])], kind))
	if kinds.size() > 1:
		lines.append(Language.translate("Davon: ") + ", ".join(kinds))
	if float(estimate["crit_chance"]) > 0.0:
		lines.append(Language.translate("Krit (%d %%): %s") % [roundi(float(estimate["crit_chance"]) * 100.0),
				_range_text(float(estimate["min"]) * float(estimate["crit_factor"]), float(estimate["max"]) * float(estimate["crit_factor"]))])
	if not parts.is_empty():
		var gains: Array[String] = []
		for part: Dictionary in parts:
			gains.append(Language.translate("+1 %s » +%s") % [Language.translate(ItemAttribute.NAMES[part["type"]]), _number(part["per_point"], 0.01)])
		lines.append(Language.translate("[color=#6fd38a]Pro Attributpunkt (Schnitt): %s Schaden[/color]") % " · ".join(gains))
	return lines


## With Shift: how the hero's heal is made up (skill % x wisdom x heal passives), an example in health
## points, and what one more point of wisdom adds.
func _get_heal_details(level: int, fighter: Combatant) -> Array[String]:
	var percent: float = get_heal_percent(level)
	var wisdom: float = fighter.get_attribute(ItemAttribute.Type.WISDOM)
	var per_wisdom: float = CombatRules.value("heal_power_per_wis", 0.01)
	var bonus: float = fighter.passive("heal_power")
	var total: float = percent * fighter.get_heal_power()
	var lines: Array[String] = ["", Language.translate("[color=#f2cc80]Heilung beim Helden[/color]")]
	lines.append(Language.translate("Skill: %s %% des max. Lebens") % _number(percent, 0.1))
	lines.append(Language.translate("× %s Heilkraft:") % _number(fighter.get_heal_power(), 0.01))
	lines.append(Language.translate("    Weisheit %s × %s %% = +%s %%") % [_number(wisdom, 1.0), _number(per_wisdom * 100.0, 0.1), _number(wisdom * per_wisdom * 100.0, 1.0)])
	if bonus != 0.0:
		lines.append(Language.translate("    Heilkraft aus Passiven und Ringen: +%s %%") % _number(bonus, 1.0))
	lines.append(Language.translate("= %s %% des max. Lebens des Ziels") % _number(total, 0.1))
	lines.append(Language.translate("Zum Beispiel bei %s (%d Leben): %d Leben") % [fighter.display_name, roundi(fighter.max_health),
			roundi(fighter.max_health * total / 100.0)])
	lines.append(Language.translate("Nie über das max. Leben hinaus; im Heldenturnier wirkt Heilung nur zu %d %%.") % roundi(float(ContentDB.arena().get("heal_factor", 1.0)) * 100.0))
	lines.append(Language.translate("[color=#6fd38a]Pro Punkt Weisheit: +%s %% des max. Lebens[/color]") % _number(percent * per_wisdom, 0.01))
	return lines


## A number for tooltips, rounded to `step` (1,25 / 48 / 3,3).
static func _number(value: float, step: float) -> String:
	var decimals: int = 0 if step >= 1.0 else (1 if step >= 0.1 else 2)
	var text: String = String.num(snappedf(value, step), decimals)
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	return text.replace(".", ",")


## "120–150", or one number if both are the same.
static func _range_text(low: float, high: float) -> String:
	if roundi(low) == roundi(high):
		return str(roundi(low))
	return "%d–%d" % [roundi(low), roundi(high)]


func _get_detail_lines(level: int) -> Array[String]:
	var lines: Array[String] = ["", "[color=#f2cc80]Details[/color]"]
	if damage_multiplier > 0.0:
		var split: Dictionary = get_damage_split()
		if damage_split.is_empty() and damage_kind == DamageKind.PHYSICAL and damage_type == DamageType.Type.NONE:
			lines.append(Language.translate("Schadensart: wie die Waffe (z. B. Schwert = Schnitt)"))
		else:
			lines.append(Language.translate("Aufteilung: ") + DamageKinds.split_text(DamageKinds.normalized(split)))
		if not base_from.is_empty():
			var sources: Array[String] = []
			for key: String in base_from:
				sources.append("%d %% %s" % [roundi(base_from[key] * 100.0), Language.translate("Rüstung") if key == "armor" else Language.translate("max. Leben")])
			lines.append(Language.translate("Grundlage: (%s) × %d %% (+%d %% pro Stufe)") % [" + ".join(sources),
					roundi(get_damage_multiplier(level) * 100.0), roundi(damage_per_level * 100.0)])
		elif pet_attack:
			lines.append(Language.translate("Grundlage: Angriff der Beschwörung × %d %% (+%d %% pro Stufe)") % [
					roundi(get_damage_multiplier(level) * 100.0), roundi(damage_per_level * 100.0)])
		elif uses_spell_damage():
			lines.append(Language.translate("Grundlage: (Grundschaden + Magieschaden der Waffe) × %d %% (+%d %% pro Stufe) × (1 + %s %% je Attributpunkt)") % [
					roundi(get_damage_multiplier(level) * 100.0), roundi(damage_per_level * 100.0),
					DamageKinds.format_number(CombatRules.value("magic_damage_per_int", 0.02) * 100.0)])
			lines.append(Language.translate("Attributpunkte: %s") % get_scaling_text())
		else:
			lines.append(Language.translate("Grundlage: (Waffenschaden + %s je Attributpunkt) × %d %% (+%d %% pro Stufe)") % [
					DamageKinds.format_number(CombatRules.value("damage_per_str", 0.5)),
					roundi(get_damage_multiplier(level) * 100.0), roundi(damage_per_level * 100.0)])
			lines.append(Language.translate("Attributpunkte: %s") % get_scaling_text())
			if spell_from_weapon:
				lines.append(Language.translate("Zauber mit dem Schaden der Waffe (kein Stab nötig)"))
		for kind: String in split:
			if kind == DamageKinds.TRUE_DAMAGE:
				lines.append(DamageKinds.colored(Language.translate("Wahrer Schaden ignoriert Rüstung und Resistenzen"), kind))
			elif DamageKinds.is_physical(kind):
				lines.append(Language.translate("%s: verringert durch Rüstung und %s-Resistenz") % [DamageKinds.colored(DamageKinds.get_display_name(kind), kind), DamageKinds.get_display_name(kind)])
			else:
				lines.append(Language.translate("%s: verringert durch Magieresistenz und %s-Resistenz") % [DamageKinds.colored(DamageKinds.get_display_name(kind), kind), DamageKinds.get_display_name(kind)])
		if crit_chance > 0.0:
			lines.append(Language.translate("Krit-Chance +%d %%") % roundi(crit_chance * 100.0))
		if crit_damage > 0.0:
			lines.append(Language.translate("Krit-Schaden +%d %%") % roundi(crit_damage * 100.0))
		if chain_targets > 1:
			lines.append(Language.translate("Trifft bis zu %d Ziele nacheinander, −%d %% pro Ziel") % [chain_targets, roundi(chain_falloff * 100.0)] \
					if chain_targets < 99 else Language.translate("Durchschlägt alle Gegner, −%d %% pro Ziel") % roundi(chain_falloff * 100.0))
		if execute_below > 0.0:
			lines.append(Language.translate("Unter %d %% Leben: Schaden × %s") % [roundi(execute_below * 100.0), DamageKinds.format_number(execute_factor)])
		if not bonus_vs_kind.is_empty():
			lines.append(Language.translate("Gegen %s-Gegner: Schaden × %s") % [DamageKinds.get_display_name(bonus_vs_kind), DamageKinds.format_number(bonus_vs_factor)])
		if not penetration.is_empty():
			lines.append(Language.translate("Durchdringung: erst %, dann Punkte; kommt zur Durchdringung des Helden dazu"))
	var target_names: Array[String] = [Language.translate("Gegner"), Language.translate("sich selbst"), Language.translate("verletztester Verbündeter"), Language.translate("alle Gegner"), Language.translate("alle Verbündeten")]
	lines.append(Language.translate("Ziel: ") + target_names[target])
	for entry in effects:
		var effect: StatusEffectData = get_effect(entry, level)
		var duration: float = entry["duration"] if entry["duration"] > 0.0 else effect.duration
		lines.append(Language.translate("%s: %d %% Chance, %s s, auf %s%s") % [effect.display_name, roundi(get_effect_chance(entry, level) * 100.0),
				DamageKinds.format_number(duration), target_names[entry["target"]],
				Language.translate(" (%d Stapel)") % entry["stacks"] if entry["stacks"] > 1 else ""])
	return lines
