class_name EffectInfo
extends RefCounted
## What a status effect does, as text for the player (lexicon page "effect:<id>", HoverCard links):
## kind, duration, stacking, damage / healing over time with totals, how it scales, every value it
## changes, and which skills and monsters cause it. Everything is read from StatusEffectData, so new
## effects in status_effects.json explain themselves.

const LINK: String = "effect"
const COLOR_BUFF: Color = Color(0.55, 0.85, 0.45)
const COLOR_DEBUFF: Color = Color(1.0, 0.5, 0.4)
const COLOR_VALUE: Color = Color(0.92, 0.9, 0.82)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_SCALING: Color = Color(0.95, 0.8, 0.5)


## "[url=effect:poison][color=#..]Vergiftet[/color][/url]": a click opens the effect's page.
static func link(effect: StatusEffectData, text: String = "") -> String:
	return "[url=%s:%s][color=#%s]%s[/color][/url]" % [LINK, effect.id, effect.color.to_html(false),
			text if not text.is_empty() else effect.display_name]


## Every effect with a name, buffs first, then by name (lexicon tab "Effekte").
static func get_all() -> Array[StatusEffectData]:
	var result: Array[StatusEffectData] = ContentDB.all_status_effects().filter(func(effect: StatusEffectData) -> bool:
		return not effect.display_name.is_empty())
	result.sort_custom(func(a: StatusEffectData, b: StatusEffectData) -> bool:
		if a.kind != b.kind:
			return a.kind == StatusEffectData.Kind.BUFF
		return a.display_name.to_lower() < b.display_name.to_lower())
	return result


static func get_kind_text(effect: StatusEffectData) -> String:
	if effect.is_instant():
		return Language.translate("Sofort")
	return Language.translate("Stärkung") if effect.kind == StatusEffectData.Kind.BUFF else Language.translate("Schwächung")


static func get_kind_color(effect: StatusEffectData) -> Color:
	return COLOR_BUFF if effect.kind == StatusEffectData.Kind.BUFF else COLOR_DEBUFF


## All lines (BBCode) that explain what the effect does, one fact per line.
static func get_lines(effect: StatusEffectData) -> Array[String]:
	var lines: Array[String] = []
	var duration: float = effect.duration
	if effect.is_instant():
		lines.append(_hint(Language.translate("Wirkt sofort, bleibt nicht auf dem Ziel.")))
	else:
		var head: String = Language.translate("Dauer: %s s") % _num(duration)
		if effect.stacking == StatusEffectData.Stacking.STACK and effect.max_stacks > 1:
			head += Language.translate(" · stapelt bis %d×, jede Stapel-Stufe zählt voll, neue Anwendung startet die Dauer neu") % effect.max_stacks
		else:
			head += Language.translate(" · erneut angewendet: Dauer beginnt von vorn")
		lines.append(_hint(head))
	_damage_lines(effect, lines, duration)
	_heal_and_shield_lines(effect, lines, duration)
	_value_lines(effect, lines)
	_control_lines(effect, lines)
	return lines


# --- Damage and healing -----------------------------------------------------------------------

static func _damage_lines(effect: StatusEffectData, lines: Array[String], duration: float) -> void:
	var element: String = Element.get_display_name(effect.element) if effect.element != Element.Type.NONE else ""
	var kind_text: String = (" " + Language.translate("(%s)") % element) if not element.is_empty() else ""
	if effect.damage_per_second > 0.0:
		var ticks: int = maxi(floori(duration), 1)
		var total: float = effect.damage_per_second * ticks
		lines.append(_value(Language.translate("Schaden: %s pro Sekunde%s, über %d s = %s") % [_num(effect.damage_per_second), kind_text, ticks, _num(total)]))
		if effect.max_stacks > 1 and effect.stacking == StatusEffectData.Stacking.STACK:
			lines.append(_hint(Language.translate("Mit %d Stapeln: %s pro Sekunde, %s insgesamt") % [effect.max_stacks,
					_num(effect.damage_per_second * effect.max_stacks), _num(total * effect.max_stacks)]))
	if effect.damage_percent_per_second > 0.0:
		lines.append(_value(Language.translate("Schaden: %s %% des max. Lebens pro Sekunde und Stapel%s") % [_num_fine(effect.damage_percent_per_second), kind_text]))
		if effect.max_stacks > 1 and effect.stacking == StatusEffectData.Stacking.STACK:
			lines.append(_hint(Language.translate("Mit %d Stapeln: %s %% des max. Lebens pro Sekunde") % [effect.max_stacks,
					_num_fine(effect.damage_percent_per_second * effect.max_stacks)]))
	if effect.damage_from_magic > 0.0:
		lines.append(_value(Language.translate("Schaden pro Sekunde: %s %% des Zauberschadens des Wirkers%s") % [_num(effect.damage_from_magic * 100.0), kind_text]))
		lines.append(_scaling(Language.translate("Skaliert mit: %s des Wirkers (Zauberschaden der Waffe × Attribut)") % _attribute(effect.damage_attribute)))
	if not element.is_empty() and (effect.damage_per_second > 0.0 or effect.damage_from_magic > 0.0 or effect.damage_percent_per_second > 0.0):
		lines.append(_scaling(Language.translate("Wird stärker mit Boni auf %s-Schaden des Wirkers; die %s-Resistenz des Ziels senkt ihn") % [element, element]))
	if effect.damage_percent_on_expire > 0.0:
		lines.append(_value(Language.translate("Am Ende: %s %% des max. Lebens als Schaden") % _num(effect.damage_percent_on_expire)))
	if effect.extra_damage > 0.0:
		lines.append(_value(Language.translate("Jeder Treffer des Trägers: +%s %% als %s-Schaden") % [_num(effect.extra_damage * 100.0),
				DamageKinds.get_display_name(effect.extra_damage_kind)]))
	if effect.thorns > 0.0:
		lines.append(_value(Language.translate("Dornen: Angreifer bekommen %s %% ihres Treffers als Magieschaden zurück") % _num(effect.thorns * 100.0)))
	if not effect.on_hit_effect_id.is_empty() and ContentDB.has_status_effect(effect.on_hit_effect_id):
		lines.append(_value(Language.translate("Jeder Treffer des Trägers: %s %% Chance auf %s") % [_num(effect.on_hit_chance * 100.0),
				link(ContentDB.status_effect(effect.on_hit_effect_id))]))
	if effect.spread_on_death:
		lines.append(_value(Language.translate("Stirbt der Träger, springt der Effekt (und Gift) auf einen anderen Kämpfer seiner Seite")))


static func _heal_and_shield_lines(effect: StatusEffectData, lines: Array[String], duration: float) -> void:
	if effect.heal_percent_per_second > 0.0:
		var ticks: int = maxi(floori(duration), 1)
		lines.append(_value(Language.translate("Heilt %s %% des max. Lebens pro Sekunde, über %d s = %s %%") % [_num(effect.heal_percent_per_second), ticks,
				_num(effect.heal_percent_per_second * ticks)]))
		lines.append(_scaling(Language.translate("Skaliert mit der Heilkraft des Wirkers (Weisheit, Passive)")))
	if effect.heal_percent_on_expire > 0.0:
		lines.append(_value(Language.translate("Am Ende: Heilung um %s %% des max. Lebens") % _num(effect.heal_percent_on_expire)))
	if effect.shield_percent > 0.0:
		lines.append(_value(Language.translate("Schild: fängt Schaden bis %s %% des max. Lebens ab") % _num(effect.shield_percent)))
		lines.append(_scaling(Language.translate("Skaliert mit der Schildkraft des Wirkers (Weisheit, Passive)")))
	if effect.caster_shield:
		var per_level: float = CombatRules.value("shield_per_caster_level", 1.0)
		var per_point: float = CombatRules.value("shield_per_caster_wis", 5.0)
		var factor: String = "" if is_equal_approx(effect.shield_factor, 1.0) else " × %s %%" % _num(effect.shield_factor * 100.0)
		lines.append(_value(Language.translate("Schild: (Level × %s + %s × %s)%s des Wirkers") % [_num(per_level), _num(per_point), _shield_attributes(effect), factor]))
		lines.append(_scaling(Language.translate("Skaliert mit: Level und %s des Wirkers") % _shield_attributes(effect)))
	if effect.is_shield():
		lines.append(_hint(Language.translate("Ein Schild fängt Schaden ab, bevor das Leben sinkt; aufgebraucht oder abgelaufen ist er weg.")))
	if effect.lifesteal > 0.0:
		lines.append(_value(Language.translate("Lebensraub: %s %% des Trefferschadens heilt den Träger") % _num(effect.lifesteal * 100.0)))
	if effect.mana_regen != 0.0:
		lines.append(_value(Language.translate("Mana-Regeneration %s/s") % _signed(effect.mana_regen)))
	if effect.block_health_regen:
		lines.append(_value(Language.translate("Keine Lebens-Regeneration, solange er wirkt")))
	if effect.revive_percent > 0.0:
		lines.append(_value(Language.translate("Holt einen gefallenen Verbündeten mit %s %% des Lebens zurück") % _num(effect.revive_percent)))
	if effect.cleanse:
		lines.append(_value(Language.translate("Entfernt %s") % (Language.translate("alle Schwächungen") if effect.cleanse_count <= 0
				else Language.translate("%d Schwächung(en)") % effect.cleanse_count)))


# --- Changed values ---------------------------------------------------------------------------

static func _value_lines(effect: StatusEffectData, lines: Array[String]) -> void:
	for type: ItemAttribute.Type in effect.attribute_multipliers:
		var percent: float = (float(effect.attribute_multipliers[type]) - 1.0) * 100.0
		lines.append(_value("%s %s %%" % [_attribute(type), _signed(percent)]))
	for kind: String in effect.resistances:
		lines.append(_value(Language.translate("Resistenz %s %s") % [DamageKinds.get_display_name(kind), _signed(float(effect.resistances[kind]))]))
	var percents: Array = [
		[effect.damage_bonus, "Schaden jedes Treffers"],
		[effect.physical_damage, "Physischer Schaden"],
		[effect.magic_damage, "Magieschaden"],
		[effect.attack_speed, "Angriffstempo"],
		[effect.armor_percent, "Rüstung"],
		[effect.magic_resistance_percent, "Magieresistenz"],
		[effect.crit_chance, "Krit-Chance"],
		[effect.crit_damage, "Krit-Schaden"],
		[effect.evasion, "Ausweichen"],
	]
	for entry: Array in percents:
		if float(entry[0]) != 0.0:
			lines.append(_value("%s %s %%" % [Language.translate(entry[1]), _signed(float(entry[0]) * 100.0)]))
	if effect.damage_taken != 0.0:
		lines.append(_value(Language.translate("Kein Schaden mehr") if effect.damage_taken <= -1.0
				else Language.translate("Erlittener Schaden %s %%") % _signed(effect.damage_taken * 100.0)))
	if effect.guard_share > 0.0:
		lines.append(_value(Language.translate("Übernimmt %s %% des Schadens seiner Verbündeten") % _num(effect.guard_share * 100.0)))
	for line in CombatRules.penetration_lines(effect.penetration):
		lines.append(_value(line))


static func _control_lines(effect: StatusEffectData, lines: Array[String]) -> void:
	var flags: Array = [
		[effect.stun, "Betäubt: keine Angriffe, keine Skills"],
		[effect.silence, "Verstummt: keine Skills (Angriffe gehen)"],
		[effect.taunt, "Spottet: Gegner können nur ihn mit Einzelangriffen treffen (Flächenangriffe treffen alle)"],
		[effect.untargetable, "Nicht als Einzelziel wählbar (Flächenangriffe treffen ihn)"],
		[effect.undying, "Fällt nicht unter 1 Leben"],
		[effect.stun_immune, "Kann nicht betäubt werden"],
		[effect.cleave, "Grundangriffe treffen alle Gegner"],
	]
	for entry: Array in flags:
		if entry[0]:
			lines.append(_value(Language.translate(entry[1])))
	if effect.kind == StatusEffectData.Kind.DEBUFF and not effect.is_instant():
		lines.append(_hint(Language.translate("Widerstand des Ziels verkürzt die Dauer.")))


# --- Who causes it ----------------------------------------------------------------------------

## Skills of the heroes that put it on: [{"skill": SkillData, "class": String, "tree": String, "chance": float}].
static func get_hero_skills(effect: StatusEffectData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for class_id: String in ContentDB.skill_tree_class_ids():
		var hero_class: HeroClass = HeroClass.load_class(class_id)
		for tree: Dictionary in ContentDB.skill_trees(class_id):
			for skill: SkillData in tree.get("skills", []):
				var chance: float = get_chance(skill, effect)
				if chance > 0.0:
					result.append({"skill": skill, "class": hero_class.display_name if hero_class else class_id,
							"tree": str(tree.get("name", "")), "chance": chance})
	return result


## Monsters that cause it with a skill or with their hits: [{"enemy": EnemyData, "via": String (skill name or ""), "chance": float}].
static func get_enemies(effect: StatusEffectData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy: EnemyData in Lexicon.get_enemies():
		for entry: Dictionary in enemy.on_hit:
			var hit_effect: StatusEffectData = entry.get("effect")
			if hit_effect and hit_effect.id == effect.id:
				result.append({"enemy": enemy, "via": "", "chance": float(entry.get("chance", 0.0))})
		for skill: SkillData in get_enemy_skills(enemy):
			var chance: float = get_chance(skill, effect)
			if chance > 0.0:
				result.append({"enemy": enemy, "via": skill.display_name, "chance": chance})
	return result


## Chance (level 1) that `skill` puts `effect` on someone, 0 = it doesn't.
static func get_chance(skill: SkillData, effect: StatusEffectData) -> float:
	for entry: Dictionary in skill.effects + skill.pet_effects:
		var own: StatusEffectData = skill.get_effect(entry, 1)
		if own and own.id == effect.id:
			return skill.get_effect_chance(entry, 1)
	return 0.0


## A monster's skills, also those of its later phases.
static func get_enemy_skills(enemy: EnemyData) -> Array[SkillData]:
	var skills: Array[SkillData] = enemy.skills.duplicate()
	for phase: Dictionary in enemy.phases:
		for skill: SkillData in phase.get("skills", []):
			if not skills.has(skill):
				skills.append(skill)
	return skills


## Every status effect a monster can cause (its hits and its skills, on itself or others), once each.
static func get_effects_of_enemy(enemy: EnemyData) -> Array[StatusEffectData]:
	var result: Array[StatusEffectData] = []
	for entry: Dictionary in enemy.on_hit:
		_add_unique(result, entry.get("effect"))
	for skill: SkillData in get_enemy_skills(enemy):
		for effect: StatusEffectData in get_effects_of_skill(skill):
			_add_unique(result, effect)
	if not enemy.shroud_effect_id.is_empty() and ContentDB.has_status_effect(enemy.shroud_effect_id):
		_add_unique(result, ContentDB.status_effect(enemy.shroud_effect_id))
	return result


static func get_effects_of_skill(skill: SkillData) -> Array[StatusEffectData]:
	var result: Array[StatusEffectData] = []
	for entry: Dictionary in skill.effects + skill.pet_effects:
		_add_unique(result, skill.get_effect(entry, 1))
	return result


static func _add_unique(list: Array[StatusEffectData], effect: StatusEffectData) -> void:
	if effect == null:
		return
	for other in list:
		if other.id == effect.id:
			return
	list.append(effect)


# --- Text helpers -----------------------------------------------------------------------------

static func _shield_attributes(effect: StatusEffectData) -> String:
	# Several attributes (status_effects.json "shield_attributes"), where the game has them.
	var mix: Dictionary = effect.get("shield_attributes") if "shield_attributes" in effect else {}
	if mix.is_empty():
		return _attribute(effect.shield_attribute)
	var parts: Array[String] = []
	for type: ItemAttribute.Type in mix:
		var weight: float = float(mix[type])
		parts.append(_attribute(type) if is_equal_approx(weight, 1.0) else "%s × %s" % [_num(weight), _attribute(type)])
	return "(%s)" % " + ".join(parts) if parts.size() > 1 else parts[0]


static func _attribute(type: ItemAttribute.Type) -> String:
	return Language.translate(ItemAttribute.NAMES[type])


static func _value(text: String) -> String:
	return "[color=#%s]%s[/color]" % [COLOR_VALUE.to_html(false), text]


static func _hint(text: String) -> String:
	return "[color=#%s]%s[/color]" % [COLOR_HINT.to_html(false), text]


static func _scaling(text: String) -> String:
	return "[color=#%s]%s[/color]" % [COLOR_SCALING.to_html(false), text]


static func _num(value: float) -> String:
	return DamageKinds.format_number(snappedf(value, 0.1))


## Like _num, but keeps two decimals (0.75 %).
static func _num_fine(value: float) -> String:
	var rounded: float = snappedf(value, 0.01)
	if is_equal_approx(rounded, roundf(rounded)):
		return str(roundi(rounded))
	return str(rounded).replace(".", ",")


static func _signed(value: float) -> String:
	return ("+" if value > 0.0 else "−" if value < 0.0 else "") + _num(absf(value))
