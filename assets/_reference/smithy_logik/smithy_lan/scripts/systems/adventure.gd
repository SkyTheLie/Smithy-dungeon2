class_name Adventure
extends RefCounted
## A party of 1-3 heroes clearing a dungeon on their own (idle fight). Ticked by GameState, so
## it keeps running in every scene and with the window closed; the BattleWindow only shows it.
## Each stage: the heroes walk on while the monsters walk in from the right (WALK_TIME, no
## fighting), then everybody fights automatically: skills when ready (damage and/or status
## effects, a ready skill comes before the basic hit), basic hits, buffs/debuffs (see Combatant).
## Heroes attack a random monster of the front row (back-row monsters like archers only once the
## front row is down), each attack anew; heroes with enough IQ follow the player's focus (an enemy
## clicked in the battle window, set_focus) and their role (HeroRole), monsters a random living hero;
## a taunting fighter (StatusEffectData.taunt) draws every single-target attack of the other side,
## area skills still hit everybody; a veiled fighter (untargetable) can only be hit by area skills.
## Heroes keep health and effects between stages.
## Heroes can call summons (elementals, the ranger's wolf, see SkillData.summon_id): they fight on
## the heroes' side in addition to the 3 heroes, until their time is up or they die, and can be
## attacked like heroes. The fight is lost when all heroes are down (summons don't count).
## Bosses with EnemyData.summon call helpers into the fight each time they lose a share of their
## health (e.g. 2 bandits at 75 %, 50 % and 25 %).
## A monster with EnemyData.shroud_effect_id hides while any other monster lives: nobody can hit it,
## not even with area attacks. Slimes (EnemyData.split) split into smaller ones below 25 % health.
## Hydra heads (EnemyData.regrow) grow back 30 s after they fell unless all heads of the hydra are
## down by then: only all at once kill it.
## All stages cleared = victory, all heroes down or the dungeon's time limit over = defeat.
## The monsters of a stage come from the dungeon's waves (DungeonData.roll_enemies).
## Defeated monsters drop loot by chance (kept on victory) and give every living hero EXP right
## away (CombatRules.kill_experience, kept even on defeat). Every fighter counts its damage for
## the statistics.

signal stage_started(stage: int)
## `skill` is null for a basic hit; `damage` is 0 for skills without damage (buffs).
## `hit` = the rolled hit (Combatant.roll_hit: "split", "crit"; "dodged" / "parried"), empty for
## skills without damage.
signal attacked(attacker: Combatant, target: Combatant, damage: int, skill: SkillData, hit: Dictionary)
## A status effect hurt or healed someone (poison tick, bleeding at the end, recovery ...).
signal effect_ticked(target: Combatant, effect: StatusEffectData, amount: int, heal: bool)
## A skill or passive healed someone right away (heal skills, martyr).
signal healed(target: Combatant, amount: int)
## Someone used a skill (once per use, also when it hits several targets), e.g. for its sound.
signal skill_used(user: Combatant, skill: SkillData)
## A boss called helpers into the fight (EnemyData.summon).
signal enemies_summoned(summoner: Combatant, helpers: Array[Combatant])
## A hero called a summon (elemental, wolf).
signal summon_called(summoner: Combatant, summon: Combatant)
## A defeated monster dropped something (the battle stage lets it fall out of `enemy`).
signal loot_dropped(enemy: Combatant, stack: InventorySlot)
signal finished(victory: bool)
## A monster died (once per monster), e.g. for the achievements.
signal enemy_defeated(enemy: Combatant)
## The player focused another enemy (null = focus taken away or the enemy fell).
signal focus_changed(target: Combatant)
## A boss lost a health bar and begins its next phase (EnemyData.phases), `text` = its shout.
signal phase_started(enemy: Combatant, text: String)

enum State { RUNNING, VICTORY, DEFEAT }

const MAX_HEROES: int = 3
## Seconds between the end of a stage and the walk to the next one.
const STAGE_PAUSE: float = 0.6
## Seconds the heroes walk / the monsters walk in before a stage starts.
const WALK_TIME: float = 1.6
## Heal-only skills wait until an ally has less than this share of his health.
const HEAL_BELOW: float = 0.9
## "Martyr" passive: allies below this share of their health are healed; its cooldown is in
## skills.json (MARTYR_COOLDOWN only if the skill is missing), shortened by cooldown reduction.
const MARTYR_BELOW: float = 0.25
const MARTYR_COOLDOWN: float = 20.0
## Seconds a shroud (EnemyData.shroud_effect_id) is put on for; _update_shrouds takes it away.
const SHROUD_DURATION: float = 3600.0

var heroes: Array[Hero] = []
var dungeon: DungeonData
var stage: int = 0
var state: State = State.RUNNING
var hero_fighters: Array[Combatant] = []
## Summons of the heroes still in the fight (they stay between stages).
var summons: Array[Combatant] = []
var enemies: Array[Combatant] = []
## Recipes unlocked by this adventure (filled by GameState on victory).
var unlocked_recipes: Array[RecipeData] = []
## Loot of defeated monsters, merged stacks (go into the reward chest on victory).
var loot: Array[InventorySlot] = []
## EXP each hero got from kills so far: Hero -> amount.
var kill_experience: Dictionary = {}
## Seconds of walking left in the current stage (0 = fighting).
var walk_left: float = 0.0
## Seconds since the start (for the time limit).
var elapsed: float = 0.0
## True if the defeat came from the time limit.
var timed_out: bool = false
## true if the player called the heroes back (give_up): like a defeat, no reward.
var gave_up: bool = false
## Rewards rolled on victory (filled by GameState): gold, EXP per hero, items (ItemData ->
## amount).
var reward_gold: int = 0
var reward_experience: int = 0
var reward_items: Dictionary = {}

## Enemy the player focused in the battle window: heroes with IQ from HeroRole.focus_iq attack it.
var focus: Combatant = null
## Luck of the party in % (ItemData.loot_luck, e.g. the goblin king's crown): the best piece any
## hero wears counts, several don't add up. Monsters drop more often and rarer.
var loot_luck: float = 0.0
## Which items may drop (ItemData -> bool, set by GameState: no ore of metals the story has not
## reached yet). Empty = everything.
var loot_filter: Callable = Callable()
## Hard mode: monsters this many times as strong (1 = normal), more and rarer loot
## (DungeonData.hard_mode, combat.json "hard_modes").
var power: int = 1
## DungeonData.hard_mode(power), read once at the start.
var hard_mode: Dictionary = {}
## Started by the story (action "start_adventure"), not from the board: does not count against
## the parallel dungeons (GameState.get_running_dungeon_count).
var story_started: bool = false
var _pause_left: float = 0.0
## Monsters whose loot was already rolled.
var _looted: Array[Combatant] = []
## The boss ingot was rolled in this run (only once, for the first boss of the boss stage).
var _boss_ingot_rolled: bool = false


func _init(party: Array[Hero], adventure_dungeon: DungeonData, hard_power: int = 1) -> void:
	heroes = party.slice(0, MAX_HEROES)
	dungeon = adventure_dungeon
	power = maxi(1, hard_power)
	hard_mode = DungeonData.hard_mode(power)
	for hero in heroes:
		hero_fighters.append(Combatant.from_hero(hero))
	# Auras (e.g. "Aura der Hingabe") count for the whole group.
	var aura: float = 0.0
	for fighter in hero_fighters:
		aura += fighter.passive("aura_armor")
	for fighter in hero_fighters:
		fighter.aura_armor_percent = aura
	for hero in heroes:
		for stack: InventorySlot in hero.equipment.values():
			if stack and not stack.is_empty():
				loot_luck = maxf(loot_luck, stack.item.loot_luck)
	_start_stage(1)


## "Bruno, Lena" for lists and messages.
func get_party_names() -> String:
	return ", ".join(PackedStringArray(heroes.map(func(hero: Hero) -> String: return hero.display_name)))


## The heroes' side: heroes and their summons.
func get_allies() -> Array[Combatant]:
	var allies: Array[Combatant] = hero_fighters.duplicate()
	allies.append_array(summons)
	return allies


func is_walking() -> bool:
	return walk_left > 0.0


## 0 = the walk just started, 1 = monsters arrived.
func get_walk_progress() -> float:
	return 1.0 - walk_left / WALK_TIME


## Seconds left of the time limit (INF without a limit).
func get_time_left() -> float:
	if dungeon.time_limit <= 0.0:
		return INF
	return maxf(dungeon.time_limit - elapsed, 0.0)


func tick(delta: float) -> void:
	if state != State.RUNNING:
		return
	elapsed += delta
	if get_time_left() <= 0.0:
		timed_out = true
		_finish(false)
		return
	for fighter in get_allies():
		_tick_effects(fighter, delta)
	_tick_summons(delta)
	if _pause_left > 0.0:
		_pause_left -= delta
		if _pause_left <= 0.0:
			_start_stage(stage + 1)
		return
	for enemy in enemies:
		_tick_effects(enemy, delta)
	if walk_left > 0.0:
		walk_left = maxf(walk_left - delta, 0.0)
		return
	if focus and not focus.is_alive():
		set_focus(null)
	_update_shrouds()
	for fighter in get_allies():
		if fighter.is_alive():
			_act(fighter, HeroRole.pick_enemy(fighter, enemies, focus), get_allies(), enemies, delta, true)
	for enemy in enemies.duplicate():
		if enemy.is_alive():
			_act(enemy, _enemy_target(), enemies, get_allies(), delta)
	_tick_martyrs(delta)
	_call_helpers()
	_split_enemies()
	_regrow(delta)
	_update_shrouds()
	_report_bosses()
	_roll_loot()
	if _first_alive(hero_fighters) == null:
		_finish(false)
	elif _first_alive(enemies.filter(func(enemy: Combatant) -> bool: return not enemy.is_summon())) == null:
		if stage >= dungeon.stage_count:
			_finish(true)
		else:
			_pause_left = STAGE_PAUSE


func _tick_effects(fighter: Combatant, delta: float) -> void:
	for event in fighter.tick(delta):
		var effect: StatusEffectData = event["effect"]
		var amount: int = event["amount"]
		if not event["heal"]:
			fighter.effect_damage_taken[effect.display_name] = fighter.effect_damage_taken.get(effect.display_name, 0) + amount
			var source: Combatant = event["source"]
			if source:
				source.effect_damage_dealt[effect.display_name] = source.effect_damage_dealt.get(effect.display_name, 0) + amount
		effect_ticked.emit(fighter, effect, amount, event["heal"])


## Summons run out of time; dead ones leave the fight.
func _tick_summons(delta: float) -> void:
	for pet in summons:
		if pet.is_alive() and pet.summon_time_left < INF:
			pet.summon_time_left -= delta
			if pet.summon_time_left <= 0.0:
				pet.health = 0.0
	summons = summons.filter(func(pet: Combatant) -> bool: return pet.is_alive())
	for fighter in hero_fighters:
		fighter.pets = fighter.pets.filter(func(pet: Combatant) -> bool: return pet.is_alive())
	# Summons of an arena opponent stay in `enemies` (dead ones too, like monsters).
	for enemy in enemies:
		if enemy.is_summon() and enemy.is_alive() and enemy.summon_time_left < INF:
			enemy.summon_time_left -= delta
			if enemy.summon_time_left <= 0.0:
				enemy.health = 0.0
		if enemy.hero:
			enemy.pets = enemy.pets.filter(func(pet: Combatant) -> bool: return pet.is_alive())


## The first ready skill, else the basic hit when its timer is up (a skill comes first: that
## moment the basic hit waits). `allies` = own side, `opponents` = the other side. A hero's command
## (SkillCommand) can pick another target and hold a skill back until its condition is true (the
## skill then stays ready, nothing is used up); without a command the hero's role (HeroRole) picks
## the target of the skill (`heroes_side`: the fighter is a hero or a summon).
func _act(fighter: Combatant, opponent: Combatant, allies: Array[Combatant], opponents: Array[Combatant], delta: float,
		heroes_side: bool = false) -> void:
	if opponent == null:
		return
	var can_use: Callable = func(skill: SkillData) -> bool:
		return _is_useful(fighter, skill, allies, opponents) and _command_allows(fighter, skill, opponent, allies, opponents)
	# The left hand (rogue with two weapons) hits on its own timer, whatever the right hand does.
	if fighter.tick_offhand(delta) and opponent.is_alive() and not opponent.is_unreachable():
		var offhand_hit: Dictionary = fighter.roll_hit(null, {}, true)
		offhand_hit["offhand"] = true
		var offhand_damage: int = _strike(fighter, opponent, offhand_hit, null, true)
		fighter.record_hit(null, offhand_damage)
		attacked.emit(fighter, opponent, offhand_damage, null, offhand_hit)
	var skill: SkillData = fighter.tick_skills(delta, can_use)
	if skill:
		var ally: Combatant = _first_fallen(allies) if _revives(skill) \
				else (_random_ally(allies) if skill.random_ally else _most_hurt(allies))
		var command: Dictionary = fighter.commands.get(skill, {})
		var picked: Combatant = SkillCommand.pick_target(command, fighter, opponents, allies, skill)
		if picked and skill.target == SkillData.Target.ENEMY and can_single_target(picked, opponents):
			opponent = picked
		elif picked and skill.target == SkillData.Target.ALLY:
			ally = picked
		elif heroes_side and SkillCommand.is_empty(command):
			if skill.target == SkillData.Target.ENEMY:
				opponent = HeroRole.pick_enemy(fighter, opponents, focus, skill)
			elif skill.target == SkillData.Target.ALLY and not _revives(skill):
				var supported: Combatant = HeroRole.pick_ally(fighter, allies, skill)
				if supported:
					ally = supported
		if opponent and opponent.is_alive():
			_use_skill(fighter, skill, opponent, ally, allies, opponents)
		return
	if fighter.tick_attack(delta):
		# "Cleave" (e.g. the wild hunt): the basic hit reaches every opponent.
		var cleave: bool = fighter.effects.any(func(active: Combatant.ActiveEffect) -> bool: return active.data.cleave)
		var targets: Array[Combatant] = [opponent]
		if cleave:
			targets.assign(opponents.filter(func(other: Combatant) -> bool: return other.is_alive() and not other.is_unreachable()))
		for target in targets:
			var hit: Dictionary = fighter.roll_hit()
			var damage: int = _strike(fighter, target, hit, null, not cleave)
			fighter.record_hit(null, damage)
			attacked.emit(fighter, target, damage, null, hit)


## The player clicks an enemy in the battle window: heroes that follow the focus attack it. The
## same enemy again (or null) takes the focus away.
func set_focus(target: Combatant) -> void:
	var new_focus: Combatant = null if target == focus or (target and not target.is_alive()) else target
	if new_focus == focus:
		return
	focus = new_focus
	focus_changed.emit(focus)


## Whether any hero of the party is clever enough to follow the player's focus.
func can_focus() -> bool:
	return hero_fighters.any(func(fighter: Combatant) -> bool: return fighter.can_focus)


## Whether the command of this skill lets the fighter use it now (no command = yes).
func _command_allows(fighter: Combatant, skill: SkillData, opponent: Combatant, allies: Array[Combatant], opponents: Array[Combatant]) -> bool:
	var command: Dictionary = fighter.commands.get(skill, {})
	if command.is_empty():
		return true
	var picked: Combatant = SkillCommand.pick_target(command, fighter, opponents, allies, skill)
	if SkillCommand.lacks_target(command, picked):
		return false
	var target: Combatant = picked
	if target == null:
		match skill.target:
			SkillData.Target.ENEMY, SkillData.Target.ALL_ENEMIES:
				target = opponent
			SkillData.Target.ALLY, SkillData.Target.ALL_ALLIES:
				target = _most_hurt(allies)
			_:
				target = fighter
	return SkillCommand.condition_met(command, fighter, target, opponents)


## A hit that can be dodged (hit["dodged"]) or parried (hit["parried"], single-target attacks only,
## "parry" passive) and heals a lifestealing attacker. Against the target it gets stronger by
## the skill's execute / bonus_vs and the attacker's "poisoned_target_damage" passive. A guardian
## on the target's side (StatusEffectData.guard_share) takes a share of it; thorns hurt the
## attacker. Upgraded weapons/arrows and buffs (hit["on_hit"]) may put their effect on the target.
func _strike(attacker: Combatant, target: Combatant, hit: Dictionary, skill: SkillData = null, single: bool = true) -> int:
	if target.is_unreachable():
		return 0
	if randf() < target.get_evasion():
		hit["dodged"] = true
		return 0
	if single and randf() < target.passive("parry") / 100.0:
		hit["parried"] = true
		return 0
	var amount: float = hit["amount"] * _target_factor(attacker, target, skill)
	var guardian: Combatant = _guardian_for(target)
	if guardian:
		var share: float = 0.0
		for active in guardian.effects:
			share = maxf(share, active.data.guard_share)
		var guard_hit: Dictionary = hit.duplicate()
		guard_hit["amount"] = amount * share
		guardian.receive_hit(guard_hit)
		amount *= 1.0 - share
	var target_hit: Dictionary = hit.duplicate()
	target_hit["amount"] = amount
	var was_alive: bool = target.is_alive()
	var damage: int = target.receive_hit(target_hit)
	if was_alive and not target.is_alive() and attacker.hero:
		target.killed_by = attacker.hero
	if attacker.get_lifesteal(skill) > 0.0:
		attacker.heal(damage * attacker.get_lifesteal(skill), attacker, Language.translate("Lebensraub"))
	for active in target.effects:
		if active.data.thorns > 0.0 and damage > 0 and attacker.is_alive():
			attacker.receive_hit({"amount": damage * active.data.thorns, "split": {DamageKinds.MAGIC: 1.0}})
	for entry: Dictionary in hit.get("on_hit", []):
		var effect: StatusEffectData = entry["effect"]
		if effect and randf() < entry["chance"] * _effect_chance_factor(attacker, effect):
			target.apply_effect(effect, 1, effect.duration * attacker.effect_duration_factor, attacker)
	return damage


## Damage factor of a hit against this target: low health (execute), its kind of damage (e.g.
## light against dark monsters), poisoned targets (virulence).
func _target_factor(attacker: Combatant, target: Combatant, skill: SkillData) -> float:
	var factor: float = 1.0
	if skill:
		if skill.execute_below > 0.0 and target.health < target.max_health * skill.execute_below:
			factor *= skill.execute_factor
		if not skill.bonus_vs_kind.is_empty() and target.weapon_split.get(skill.bonus_vs_kind, 0.0) > 0.0:
			factor *= skill.bonus_vs_factor
	if attacker.passive("poisoned_target_damage") > 0.0 and target.has_effect_id("poison"):
		factor *= 1.0 + attacker.passive("poisoned_target_damage") / 100.0
	return factor


## Debuffs land more often with the "debuff_chance" passive of whoever applies them.
func _effect_chance_factor(user: Combatant, effect: StatusEffectData) -> float:
	if effect.kind == StatusEffectData.Kind.DEBUFF:
		return 1.0 + user.passive("debuff_chance") / 100.0
	return 1.0


## Another living fighter of the target's side that guards it (Schutzwall), or null.
func _guardian_for(target: Combatant) -> Combatant:
	var side: Array[Combatant] = enemies if enemies.has(target) else get_allies()
	for fighter in side:
		if fighter != target and fighter.is_alive() and fighter.effects.any(func(active: Combatant.ActiveEffect) -> bool:
				return active.data.guard_share > 0.0):
			return fighter
	return null


## Uses a skill: costs (self damage), damage on its targets, heals, summons, help for the allies,
## then its effects. `allies` / `opponents` = the user's side / the other side.
func _use_skill(user: Combatant, skill: SkillData, opponent: Combatant, ally: Combatant,
		allies: Array[Combatant], opponents: Array[Combatant]) -> void:
	skill_used.emit(user, skill)
	var level: int = user.skill_levels.get(skill, 1)
	if skill.self_damage_percent > 0.0:
		user.lose_health(user.max_health * skill.self_damage_percent / 100.0)
	# Effects on oneself come first, so e.g. the lifesteal of a strike already counts for it.
	_apply_skill_effects(user, skill, opponent, ally, allies, opponents, true)
	var results: Array[Dictionary] = []
	var deals_damage: bool = skill.damage_multiplier > 0.0 and skill.target in [SkillData.Target.ENEMY, SkillData.Target.ALL_ENEMIES]
	# Multi hits roll the enemy effects on every hit (_deal_skill_damage).
	var effects_per_hit: bool = deals_damage and (skill.hits > 1 or skill.random_targets)
	if deals_damage:
		results = _deal_skill_damage(user, skill, opponent, allies, opponents, level)
	else:
		for target in _targets_of(skill.target, user, opponent, ally, allies, opponents):
			results.append({"target": target, "damage": 0, "hit": {}})
	if skill.heal_percent > 0.0:
		for target in _targets_of(skill.target, user, opponent, ally, allies, opponents):
			if target.is_alive() and (target == user or target.buffable):
				healed.emit(target, target.heal(target.max_health * skill.get_heal_percent(level) / 100.0 * user.get_heal_power(),
						user, skill.display_name))
	if not skill.summon_id.is_empty():
		_call_summon(user, skill, level)
	if not skill.summon_enemy_ids.is_empty() and user.enemy_data:
		_call_enemy_helpers(user, skill)
	if skill.hits_self and deals_damage and user.is_alive():
		# e.g. the lava golem's eruption also hits himself - and heals him (absorb).
		var own_hit: Dictionary = user.roll_hit(skill)
		var own_damage: int = user.receive_hit(own_hit)
		if own_damage > 0:
			results.append({"target": user, "damage": own_damage, "hit": own_hit})
	if skill.allies_cooldown > 0.0 or skill.allies_mana_percent > 0.0:
		var mana_percent: float = skill.allies_mana_percent + skill.allies_mana_per_level * (level - 1)
		for fighter in allies:
			if fighter.is_alive():
				fighter.shorten_cooldowns(skill.allies_cooldown)
				fighter.mana = minf(fighter.mana + fighter.max_mana * mana_percent / 100.0, fighter.max_mana)
	_apply_skill_effects(user, skill, opponent, ally, allies, opponents, false, effects_per_hit)
	for pet in user.get_living_pets():
		for entry in skill.pet_effects:
			var effect: StatusEffectData = skill.get_effect(entry, level)
			pet.apply_effect(effect, entry["stacks"], entry["duration"] if entry["duration"] > 0.0 else effect.duration, user)
	for result in results:
		attacked.emit(user, result["target"], result["damage"], skill, result["hit"])


## Damage of a skill: its targets (one, every opponent, a chain, random ones), its hits, special
## damage (the summon attacks, a sacrificed summon explodes, poison is set off). Returns
## [{"target", "damage", "hit"}] for the battle window.
func _deal_skill_damage(user: Combatant, skill: SkillData, opponent: Combatant, allies: Array[Combatant],
		opponents: Array[Combatant], level: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var pet: Combatant = null
	if skill.pet_attack or skill.sacrifice_summon:
		var pets: Array[Combatant] = user.get_living_pets()
		if pets.is_empty():
			return results
		pet = pets[0]
	var attacker: Combatant = pet if skill.pet_attack else user
	var row: Array[Combatant] = []
	if skill.target == SkillData.Target.ALL_ENEMIES:
		row.assign(opponents.filter(func(fighter: Combatant) -> bool: return fighter.is_alive() and not fighter.is_unreachable()))
		if row.is_empty():
			return results
	else:
		row.append(opponent)
		if skill.chain_targets > 1:
			for fighter in opponents:
				if row.size() >= skill.chain_targets:
					break
				if fighter != opponent and fighter.is_alive() and not fighter.is_untargetable():
					row.append(fighter)
	var single: bool = skill.target == SkillData.Target.ENEMY and skill.chain_targets <= 1
	var total_damage: int = 0
	for hit_index in skill.hits:
		var targets: Array[Combatant] = row
		if skill.random_targets:
			var alive: Array = opponents.filter(func(fighter: Combatant) -> bool: return fighter.is_alive() and not fighter.is_unreachable())
			if alive.is_empty():
				break
			targets = [alive.pick_random()]
		elif skill.hits > 1 and not row[0].is_alive():
			# The target fell: the remaining hits go to the next one.
			var next: Combatant = get_single_target(opponents)
			if next == null:
				break
			row = [next]
			targets = row
		var split: Dictionary = skill.hit_splits[hit_index % skill.hit_splits.size()] if not skill.hit_splits.is_empty() else {}
		if skill.sacrifice_summon:
			split = pet.weapon_split
		for i in targets.size():
			var target: Combatant = targets[i]
			if not target.is_alive():
				continue
			var hit: Dictionary
			if skill.pet_attack:
				hit = pet.roll_hit()
				hit["amount"] *= skill.get_damage_multiplier(level)
			else:
				hit = user.roll_hit(skill, split)
			if not skill.detonate_effect_id.is_empty():
				var active: Combatant.ActiveEffect = target.get_active_effect(skill.detonate_effect_id)
				if active == null:
					continue
				hit["amount"] *= active.stacks
				target.effects.erase(active)
			if i > 0:
				hit["amount"] *= pow(1.0 - skill.chain_falloff, i)
			var damage: int = _strike(attacker, target, hit, skill, single)
			attacker.record_hit(skill if attacker == user else null, damage)
			total_damage += damage
			results.append({"target": target, "damage": damage, "hit": hit})
			if skill.hits > 1 or skill.random_targets:
				_apply_enemy_effects(user, skill, target, level)
			if skill.reset_on_kill and not target.is_alive():
				user.skill_cooldowns[skill] = 0.0
	if skill.sacrifice_summon:
		pet.health = 0.0
	if skill.heal_allies_from_damage > 0.0 and total_damage > 0:
		for fighter in allies:
			if fighter.is_alive() and (fighter == user or fighter.buffable):
				healed.emit(fighter, fighter.heal(total_damage * skill.heal_allies_from_damage, user, skill.display_name))
	return results


## The effects of a skill aimed at its enemy target, rolled for one hit (multi hits).
func _apply_enemy_effects(user: Combatant, skill: SkillData, target: Combatant, level: int) -> void:
	for entry in skill.effects:
		if entry["target"] != SkillData.Target.ENEMY:
			continue
		var effect: StatusEffectData = skill.get_effect(entry, level)
		if randf() < skill.get_effect_chance(entry, level) * _effect_chance_factor(user, effect):
			var duration: float = entry["duration"] if entry["duration"] > 0.0 else effect.duration
			target.apply_effect(effect, entry["stacks"], duration * user.effect_duration_factor, user)


## `skip_enemy`: entries aimed at the enemy were already rolled per hit.
func _apply_skill_effects(user: Combatant, skill: SkillData, opponent: Combatant, ally: Combatant,
		allies: Array[Combatant], opponents: Array[Combatant], on_self: bool, skip_enemy: bool = false) -> void:
	var level: int = user.skill_levels.get(skill, 1)
	for entry in skill.effects:
		if (entry["target"] == SkillData.Target.SELF) != on_self:
			continue
		if skip_enemy and entry["target"] == SkillData.Target.ENEMY:
			continue
		var effect: StatusEffectData = skill.get_effect(entry, level)
		if randf() >= skill.get_effect_chance(entry, level) * _effect_chance_factor(user, effect):
			continue
		var duration: float = entry["duration"] if entry["duration"] > 0.0 else effect.duration
		var own_side: bool = entry["target"] in [SkillData.Target.SELF, SkillData.Target.ALLY, SkillData.Target.ALL_ALLIES]
		for receiver in _targets_of(entry["target"], user, opponent, ally, allies, opponents):
			# Elementals can't be healed or buffed by their allies.
			if own_side and receiver != user and not receiver.buffable:
				continue
			receiver.apply_effect(effect, entry["stacks"], duration * user.effect_duration_factor, user)


## A hero calls the summon of a skill: the strongest one his learned skills allow (summon_upgrades,
## e.g. wolf pup -> wolf -> giant wolf) with its share of his values.
func _call_summon(user: Combatant, skill: SkillData, level: int) -> void:
	var summon_id: String = skill.summon_id
	var share: float = skill.get_summon_share(level)
	if user.hero:
		for upgrade: Dictionary in skill.summon_upgrades:
			var upgrade_skill: SkillData = ContentDB.find_skill(upgrade["skill"])
			if upgrade_skill and user.hero.get_skill_rank(upgrade_skill) > 0:
				summon_id = upgrade["summon"]
				share = upgrade["share"]
	var data: SummonData = ContentDB.summon_data(summon_id)
	if data == null:
		return
	var duration: float = skill.summon_duration
	if duration > 0.0:
		duration += user.passive("summon_duration")
	var pet: Combatant = Combatant.from_summon(user, data, share, duration)
	user.pets.append(pet)
	# The opponent in an arena duel (ArenaDuel) summons onto his own side.
	if enemies.has(user):
		enemies.append(pet)
	else:
		summons.append(pet)
	summon_called.emit(user, pet)


## A monster calls more monsters into the fight (SkillData.summon_enemy_ids, e.g. the dragon's fire
## elementals).
func _call_enemy_helpers(user: Combatant, skill: SkillData) -> void:
	var helpers: Array[Combatant] = []
	for i in skill.summon_enemy_count:
		var helper: Combatant = _spawn_enemy(ContentDB.enemy(skill.summon_enemy_ids.pick_random()))
		enemies.append(helper)
		helpers.append(helper)
	enemies_summoned.emit(user, helpers)


## Living monsters of `fighters` that a skill with summon_enemy_ids calls.
func _count_enemy_helpers(skill: SkillData, fighters: Array[Combatant]) -> int:
	return fighters.filter(func(fighter: Combatant) -> bool:
		return fighter.is_alive() and fighter.enemy_data and skill.summon_enemy_ids.has(String(fighter.enemy_data.id))).size()


## Everyone a skill or effect with this target reaches: one fighter, or all living ones of a side.
func _targets_of(target: SkillData.Target, user: Combatant, opponent: Combatant, ally: Combatant,
		allies: Array[Combatant], opponents: Array[Combatant]) -> Array[Combatant]:
	var result: Array[Combatant] = []
	match target:
		SkillData.Target.ALL_ENEMIES:
			result.assign(opponents.filter(func(fighter: Combatant) -> bool: return fighter.is_alive() and not fighter.is_unreachable()))
		SkillData.Target.ALL_ALLIES:
			result.assign(allies.filter(func(fighter: Combatant) -> bool: return fighter.is_alive()))
		_:
			result.append(_pick_target(target, user, opponent, ally))
	return result


## Whether using the skill makes sense now: a revive only with a fallen ally, a summon only when it
## isn't already there (once per kind), the summon's attack / sacrifice only with a living summon,
## setting off poison only when someone is poisoned, a heal only when someone is hurt.
func _is_useful(user: Combatant, skill: SkillData, allies: Array[Combatant], opponents: Array[Combatant]) -> bool:
	if not skill.requires_effect_id.is_empty() and not user.has_effect_id(skill.requires_effect_id):
		return false
	if _revives(skill):
		return _first_fallen(allies) != null
	if (skill.pet_attack or skill.sacrifice_summon) and user.get_living_pets().is_empty():
		return false
	if not skill.summon_enemy_ids.is_empty() and _count_enemy_helpers(skill, allies) >= skill.summon_enemy_max:
		return false
	if not skill.summon_id.is_empty():
		var kinds: Array = [skill.summon_id] + skill.summon_upgrades.map(func(upgrade: Dictionary) -> String: return upgrade["summon"])
		for pet in user.get_living_pets():
			if kinds.has(String(pet.summon_data.id)):
				return false
	if not skill.detonate_effect_id.is_empty():
		return opponents.any(func(fighter: Combatant) -> bool: return fighter.is_alive() and fighter.has_effect_id(skill.detonate_effect_id))
	if skill.heal_percent > 0.0 and skill.damage_multiplier <= 0.0 and skill.effects.is_empty():
		var hurt: Combatant = user if skill.target == SkillData.Target.SELF else _most_hurt(allies)
		return hurt != null and hurt.health < hurt.max_health * HEAL_BELOW
	return true


func _revives(skill: SkillData) -> bool:
	for entry in skill.effects:
		if (entry["effect"] as StatusEffectData).revive_percent > 0.0:
			return true
	return false


## The first fallen hero (summons can't be revived).
func _first_fallen(fighters: Array[Combatant]) -> Combatant:
	for fighter in fighters:
		if not fighter.is_alive() and not fighter.is_summon():
			return fighter
	return null


## "Martyr" passive: a hero heals an ally that drops below 25 % health, then waits its cooldown.
func _tick_martyrs(delta: float) -> void:
	for fighter in hero_fighters:
		if not fighter.is_alive() or fighter.passive("martyr") <= 0.0:
			continue
		fighter.martyr_cooldown -= delta
		if fighter.martyr_cooldown > 0.0:
			continue
		var hurt: Combatant = _most_hurt(get_allies())
		if hurt and hurt.health < hurt.max_health * MARTYR_BELOW:
			healed.emit(hurt, hurt.heal(hurt.max_health * fighter.passive("martyr") / 100.0 * fighter.get_heal_power(),
					fighter, Language.translate("Märtyrer")))
			var martyr: SkillData = ContentDB.skill("martyr")
			fighter.martyr_cooldown = (martyr.cooldown if martyr else MARTYR_COOLDOWN) * (1.0 - fighter.cooldown_reduction)


func _start_stage(number: int) -> void:
	stage = number
	enemies.clear()
	_looted.clear()
	# The fixed monsters of a boss / mini boss stage are its bosses (command "boss").
	var bosses: Array = dungeon.get_wave(number).get("fixed", []).duplicate() \
			if dungeon.get_stage_type(number) != DungeonData.StageType.NORMAL else []
	for kind in dungeon.roll_enemies(number):
		var enemy: Combatant = _spawn_enemy(kind)
		if bosses.has(kind):
			enemy.is_boss = true
			bosses.erase(kind)
		enemies.append(enemy)
	_update_shrouds()
	for fighter in get_allies():
		fighter.attack_cooldown = fighter.get_attack_interval()
		fighter.offhand_cooldown = fighter.get_offhand_interval()
	walk_left = WALK_TIME
	stage_started.emit(stage)


## A monster of this dungeon, as strong as the dungeon makes it (DungeonData.enemy_health_factor /
## enemy_damage_factor), times the hard mode's power (health and damage).
func _spawn_enemy(data: EnemyData) -> Combatant:
	var enemy: Combatant = Combatant.from_enemy(data)
	enemy.scale_power(dungeon.enemy_health_factor * power, dungeon.enemy_damage_factor * power)
	return enemy


## Monsters that just died: EXP for the living heroes and their drops; a plague jumps on.
func _roll_loot() -> void:
	for enemy in enemies:
		if enemy.is_alive() or _looted.has(enemy) or enemy.enemy_data == null or enemy.regrowing:
			continue
		_looted.append(enemy)
		enemy_defeated.emit(enemy)
		_spread_plague(enemy)
		_give_kill_experience(enemy)
		var settings: Dictionary = ContentDB.dungeon_loot()
		# Luck (the crown): drops more often (half the luck) and better rarities more often (all of it).
		# The dungeon's drop_factor thins out the ordinary monsters' drops, bosses keep theirs.
		# A hard mode: drops more often (drop_factor) and rarer (rarity_factor).
		var dungeon_factor: float = 1.0 if enemy.is_boss else dungeon.drop_factor
		var drops: Array[InventorySlot] = enemy.enemy_data.roll_drops(
				settings["chance_factor"] * dungeon_factor * float(hard_mode["drop_factor"]) * (1.0 + loot_luck / 200.0),
				settings["rarity"], get_rarity_factor())
		var ingot: InventorySlot = _roll_boss_ingot(enemy, settings)
		if ingot:
			drops.append(ingot)
		for stack in drops:
			if loot_filter.is_valid() and not loot_filter.call(stack.item):
				continue
			stack.rarity = DungeonData.shift_rarity(stack.item, stack.rarity, int(hard_mode["rarity_shift"])) as Rarity.Tier
			_add_loot(stack)
			loot_dropped.emit(enemy, stack)


## The boss of the boss stage may drop the dungeon's ingot (DungeonData.boss_ingot, chance:
## combat.json "dungeon_loot" boss_ingot_chance), often R2 or R3 (boss_ingot_rarity); one roll per
## run, mini-bosses and a second boss don't roll again. null = none.
## In a hard mode the ingot always drops, plus "extra_ingots" more, and rarer (rarity_factor).
func _roll_boss_ingot(enemy: Combatant, settings: Dictionary) -> InventorySlot:
	if not enemy.is_boss or dungeon.boss_ingot == null or _boss_ingot_rolled 			or dungeon.get_stage_type(stage) != DungeonData.StageType.BOSS:
		return null
	_boss_ingot_rolled = true
	if power <= 1 and randf() >= settings["boss_ingot_chance"]:
		return null
	return _make_ingot(settings)


## The dungeon's ingot: 1, in a hard mode 1 + "extra_ingots"; rarer by boss_ingot_rarity.
func _make_ingot(settings: Dictionary) -> InventorySlot:
	var stack := InventorySlot.new()
	stack.item = dungeon.boss_ingot
	stack.amount = 1 + (int(hard_mode["extra_ingots"]) if power > 1 else 0)
	stack.rarity = stack.item.base_rarity
	for chance: Array in settings["boss_ingot_rarity"]:
		if randf() < chance[1] * get_rarity_factor():
			stack.rarity = chance[0]
			break
	stack.rarity = DungeonData.shift_rarity(stack.item, stack.rarity, int(hard_mode["rarity_shift"])) as Rarity.Tier
	return stack


## How much more often rare loot comes: luck (the crown) times the hard mode's rarity_factor.
func get_rarity_factor() -> float:
	return (1.0 + loot_luck / 100.0) * float(hard_mode.get("rarity_factor", 1.0))


## "Rattenkeller", "Rattenkeller ×3" in a hard mode.
func get_dungeon_title() -> String:
	return dungeon.display_name if power <= 1 else "%s ×%d" % [dungeon.display_name, power]


## A dead monster with a spreading effect (Seuche) passes it and its poison to another monster.
func _spread_plague(dead: Combatant) -> void:
	for active in dead.effects:
		if not active.data.spread_on_death:
			continue
		var others: Array = enemies.filter(func(fighter: Combatant) -> bool: return fighter.is_alive())
		if others.is_empty():
			return
		var next: Combatant = others.pick_random()
		var poison: Combatant.ActiveEffect = dead.get_active_effect("poison")
		if poison:
			next.apply_effect(poison.data, poison.stacks, poison.time_left, poison.get_source())
		next.apply_effect(active.data, 1, active.time_left, active.get_source())
		return


func _give_kill_experience(enemy: Combatant) -> void:
	if enemy.enemy_data.experience <= 0:
		return
	# A monster made tougher by its dungeon (enemy_health_factor) is worth that much more; a weaker
	# one (copper dungeons) still gives its normal experience.
	var base: int = maxi(1, roundi(enemy.enemy_data.experience * maxf(1.0, enemy.health_factor)))
	for fighter in hero_fighters:
		if fighter.is_alive() and fighter.hero:
			var amount: int = CombatRules.kill_experience(base, fighter.hero.level, enemy.level)
			fighter.hero.add_experience(amount)
			kill_experience[fighter.hero] = kill_experience.get(fighter.hero, 0) + amount


func _add_loot(stack: InventorySlot) -> void:
	for existing in loot:
		if existing.can_stack_with(stack):
			existing.add_from(stack, stack.amount)
			return
	loot.append(stack.copy_with_amount(stack.amount))


func _pick_target(target: SkillData.Target, user: Combatant, opponent: Combatant, ally: Combatant) -> Combatant:
	match target:
		SkillData.Target.SELF:
			return user
		SkillData.Target.ALLY:
			return ally if ally else user
	return opponent


## A random living fighter of `fighters` that allies may heal (SkillData.random_ally).
func _random_ally(fighters: Array[Combatant]) -> Combatant:
	var open: Array = fighters.filter(func(fighter: Combatant) -> bool: return fighter.is_alive() and fighter.buffable)
	return open.pick_random() if not open.is_empty() else null


## Living fighter with the lowest health in percent that allies may heal (not elementals).
func _most_hurt(fighters: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	for fighter in fighters:
		if fighter.is_alive() and fighter.buffable and (best == null or fighter.health / fighter.max_health < best.health / best.max_health):
			best = fighter
	return best


## The hero / summon a monster's single-target attack hits: a taunting one, otherwise a random one
## that isn't veiled. A ranger's wolf may jump in front of him ("pet_guard" passive).
func _enemy_target() -> Combatant:
	var allies: Array[Combatant] = get_allies()
	var target: Combatant = _taunter(allies)
	if target == null:
		var open: Array = allies.filter(func(fighter: Combatant) -> bool: return fighter.is_alive() and not fighter.is_untargetable())
		target = open.pick_random() if not open.is_empty() else null
	if target and target.passive("pet_guard") > 0.0 and randf() < target.passive("pet_guard") / 100.0:
		var guards: Array[Combatant] = target.get_living_pets().filter(func(pet: Combatant) -> bool: return pet.buffable)
		if not guards.is_empty():
			return guards[0]
	return target


## The fighter of `opponents` a single-target attack hits: a taunting one first, then the first
## living one of the front row, the back row only when the front row is down. Veiled fighters
## (untargetable) are skipped.
static func get_single_target(opponents: Array[Combatant]) -> Combatant:
	var taunter: Combatant = _taunter(opponents)
	if taunter:
		return taunter
	for fighter in opponents:
		if fighter.is_alive() and not fighter.back_row and not fighter.is_untargetable():
			return fighter
	for fighter in opponents:
		if fighter.is_alive() and not fighter.is_untargetable():
			return fighter
	return null


## Whether a single-target attack may hit `target` (no taunter in the way, the front row down
## for a back-row target, not veiled), e.g. for a hero's command "lowest health".
static func can_single_target(target: Combatant, opponents: Array[Combatant]) -> bool:
	if target.is_untargetable():
		return false
	var taunter: Combatant = _taunter(opponents)
	if taunter:
		return target == taunter
	if target.back_row:
		return not opponents.any(func(fighter: Combatant) -> bool: return fighter.is_alive() and not fighter.back_row)
	return true


static func _taunter(fighters: Array[Combatant]) -> Combatant:
	for fighter in fighters:
		if fighter.is_taunting():
			return fighter
	return null


## Health monsters got back by absorbing a hit (EnemyData.absorb) shows as a heal; a boss that
## began a new phase shouts.
func _report_bosses() -> void:
	for enemy in enemies:
		if enemy.absorbed_heal > 0:
			healed.emit(enemy, enemy.absorbed_heal)
			enemy.absorbed_heal = 0
		if not enemy.phase_text.is_empty():
			phase_started.emit(enemy, enemy.phase_text)
			enemy.phase_text = ""


## Bosses that lost another share of their health call their helpers (EnemyData.summon).
func _call_helpers() -> void:
	for enemy in enemies.duplicate():
		var summon: Dictionary = enemy.enemy_data.summon if enemy.enemy_data else {}
		if summon.is_empty() or not enemy.is_alive():
			continue
		var every: float = float(summon.get("every", 0.25))
		if every <= 0.0:
			push_error("Enemy %s: summon \"every\" must be above 0." % enemy.enemy_data.id)
			continue
		var pool: Array = summon.get("pool", [])
		var possible: int = int(ceilf(1.0 / every)) - 1
		var lost_shares: int = floori((1.0 - enemy.health / enemy.max_health) / every + 0.0001)
		while enemy.summons_done < mini(lost_shares, possible) and not pool.is_empty():
			enemy.summons_done += 1
			var helpers: Array[Combatant] = []
			for i in int(summon.get("count", 2)):
				var helper: Combatant = _spawn_enemy(pool.pick_random())
				enemies.append(helper)
				helpers.append(helper)
			enemies_summoned.emit(enemy, helpers)


## Monsters with EnemyData.shroud_effect_id carry that effect while another monster of theirs lives
## and lose it when they stand alone; then their skills that call helpers start cooling down anew.
func _update_shrouds() -> void:
	for enemy in enemies:
		if enemy.enemy_data == null or enemy.enemy_data.shroud_effect_id.is_empty() or not enemy.is_alive():
			continue
		var effect_id: String = enemy.enemy_data.shroud_effect_id
		var guarded: bool = enemies.any(func(other: Combatant) -> bool: return other != enemy and other.is_alive())
		var active: Combatant.ActiveEffect = enemy.get_active_effect(effect_id)
		if guarded and active == null:
			enemy.apply_effect(ContentDB.status_effect(effect_id), 1, SHROUD_DURATION, enemy)
		elif not guarded and active:
			enemy.effects.erase(active)
			# The heroes get a window: calling new helpers starts its cooldown anew.
			for skill in enemy.skills:
				if not skill.summon_enemy_ids.is_empty():
					enemy.skill_cooldowns[skill] = maxf(enemy.skill_cooldowns.get(skill, 0.0), skill.cooldown)


## Slimes (EnemyData.split) below their share of health (or killed by one big hit) split: the slime
## counts as defeated, `count` smaller ones with `share` of its health and damage take its place.
## The parts split again until "times" is reached; the last ones simply die.
func _split_enemies() -> void:
	for enemy in enemies.duplicate():
		var split: Dictionary = enemy.enemy_data.split if enemy.enemy_data else {}
		if split.is_empty() or enemy.has_split or _looted.has(enemy) or enemy.split_generation >= int(split["times"]):
			continue
		if enemy.health >= enemy.max_health * float(split["below"]):
			continue
		enemy.has_split = true
		enemy.health = 0.0
		var parts: Array[Combatant] = []
		var index: int = enemies.find(enemy)
		for i in int(split["count"]):
			var part: Combatant = Combatant.from_enemy(enemy.enemy_data)
			part.health_factor = enemy.health_factor
			part.damage_factor = enemy.damage_factor
			_make_split_part(part, enemy, split)
			index += 1
			enemies.insert(index, part)
			parts.append(part)
		enemies_summoned.emit(enemy, parts)


## Monsters that grow back (EnemyData.regrow, the hydra's heads): one that fell while another of its
## group still lives waits `seconds`, then comes back with the next share of its health (50 %, then
## 25 % ...). Once the whole group is down, nobody comes back any more: then they are looted.
func _regrow(delta: float) -> void:
	for enemy in enemies:
		var regrow: Dictionary = enemy.enemy_data.regrow if enemy.enemy_data else {}
		if regrow.is_empty() or enemy.is_alive() or _looted.has(enemy):
			continue
		if not _regrow_group_alive(enemy):
			enemy.regrowing = false
			continue
		if not enemy.regrowing:
			enemy.regrowing = true
			enemy.regrow_left = float(regrow["seconds"])
			continue
		enemy.regrow_left -= delta
		if enemy.regrow_left > 0.0:
			continue
		var shares: Array = regrow["health"]
		enemy.regrowing = false
		enemy.effects.clear()
		enemy.health = maxf(1.0, enemy.max_health * float(shares[mini(enemy.regrow_count, shares.size() - 1)]))
		enemy.regrow_count += 1
		enemy.attack_cooldown = enemy.base_attack_interval
		if not str(regrow["text"]).is_empty():
			phase_started.emit(enemy, Language.translate(str(regrow["text"])))


## true if another monster of `enemy`'s regrow group is alive.
func _regrow_group_alive(enemy: Combatant) -> bool:
	var group: String = enemy.enemy_data.regrow["group"]
	return enemies.any(func(other: Combatant) -> bool:
		return other != enemy and other.is_alive() and other.enemy_data != null \
				and str(other.enemy_data.regrow.get("group", "")) == group)


## `part` gets `share` of the parent's health and damage, a smaller picture and the next generation.
static func _make_split_part(part: Combatant, parent: Combatant, split: Dictionary) -> void:
	var share: float = split["share"]
	part.max_health = maxi(1, roundi(parent.max_health * share))
	part.health = part.max_health
	part.damage_min = maxi(1, roundi(parent.damage_min * share))
	part.damage_max = maxi(part.damage_min, roundi(parent.damage_max * share))
	part.magic_min = roundi(parent.magic_min * share)
	part.magic_max = maxi(part.magic_min, roundi(parent.magic_max * share))
	part.split_generation = parent.split_generation + 1
	part.size_factor = parent.size_factor * float(split["size"])
	part.is_boss = parent.is_boss


static func _first_alive(fighters: Array[Combatant]) -> Combatant:
	for fighter in fighters:
		if fighter.is_alive():
			return fighter
	return null


## TEMPORARY dev shortcut, must go before release (only in debug builds anyway): the button "Sofort"
## (dungeon board, battle window) once the dungeon was won. See can_finish_instantly.
const INSTANT_STEP_SECONDS: float = 0.1
## Fast-forward stops after this many fight seconds (endless fight, e.g. regrowing heads).
const INSTANT_MAX_SECONDS: float = 7200.0

## True while finish_instantly runs (the battle window skips its skill sounds then).
var fast_forwarding: bool = false


## TEMPORARY, DEV-ONLY: "Sofort" may be shown: test tools on (DevTools, like the admin panel), a
## running dungeon (no arena duel) won once before.
func can_finish_instantly(wins: Dictionary) -> bool:
	return DevTools.enabled() and state == State.RUNNING and not (self is ArenaDuel) and dungeon.was_won(wins)


## TEMPORARY: runs the rest of the fight right now in small steps, like sleeping through the night:
## the result is the real one (it can also be lost), loot, EXP and rewards as usual.
func finish_instantly() -> void:
	fast_forwarding = true
	var left: float = INSTANT_MAX_SECONDS
	while state == State.RUNNING and left > 0.0:
		tick(INSTANT_STEP_SECONDS)
		left -= INSTANT_STEP_SECONDS
	fast_forwarding = false


## The player calls the heroes back (button "Aufgeben" in the battle window): the adventure ends
## like a defeat, without a reward; EXP from fights already won stays.
func give_up() -> void:
	if state != State.RUNNING:
		return
	gave_up = true
	_finish(false)


func _finish(victory: bool) -> void:
	# A won hard mode always brings the dungeon's ingot, also in a dungeon without a boss stage.
	if victory and power > 1 and not _boss_ingot_rolled and dungeon.boss_ingot:
		_boss_ingot_rolled = true
		var ingot: InventorySlot = _make_ingot(ContentDB.dungeon_loot())
		if not loot_filter.is_valid() or loot_filter.call(ingot.item):
			_add_loot(ingot)
	state = State.VICTORY if victory else State.DEFEAT
	finished.emit(victory)


# --- Saving -----------------------------------------------------------------------

## Where the adventure stands: stage, time, the heroes' health and mana and the loot so far.
## The living monsters of the current stage are saved with their health, so a monster killed
## before saving does not come back; a boss keeps its phase (health bar) and the helper waves it
## called already. Skills used "once per dungeon" stay used. Summons and running effects are not saved.
func to_save_data() -> Dictionary:
	var fighters: Array = []
	for fighter in hero_fighters:
		fighters.append({"health": fighter.health, "mana": fighter.mana, "used_once": fighter.get_used_once_ids()})
	var saved_loot: Array = []
	for stack in loot:
		saved_loot.append(stack.to_save_data())
	var saved_enemies: Array = []
	for enemy in enemies:
		# A hydra head waiting to grow back is saved too (with its seconds left).
		if (enemy.is_alive() or enemy.regrowing) and enemy.enemy_data != null:
			saved_enemies.append({"id": str(enemy.enemy_data.id), "health": enemy.health, "boss": enemy.is_boss,
					"generation": enemy.split_generation, "regrow_left": enemy.regrow_left if enemy.regrowing else -1.0,
					"regrow_count": enemy.regrow_count, "phase": enemy.phase, "max_health": enemy.max_health,
					"summons_done": enemy.summons_done, "used_once": enemy.get_used_once_ids()})
	return {
		"heroes": heroes.map(func(hero: Hero) -> String: return str(hero.id)),
		"dungeon": str(dungeon.id),
		"power": power,
		"story_started": story_started,
		"stage": stage,
		"elapsed": elapsed,
		"fighters": fighters,
		"enemies": saved_enemies,
		"loot": saved_loot,
		"boss_ingot_rolled": _boss_ingot_rolled,
	}


## Opposite of to_save_data(), on an adventure just started with the same party (same order).
## Older saves without progress start at stage 1.
func load_progress(data: Dictionary) -> void:
	elapsed = float(data.get("elapsed", 0.0))
	# Older saves: a hidden dungeon could only come from the story.
	story_started = bool(data.get("story_started", dungeon.hidden))
	var fighters: Array = data.get("fighters", [])
	for i in mini(fighters.size(), hero_fighters.size()):
		var fighter: Combatant = hero_fighters[i]
		var saved: Dictionary = fighters[i]
		fighter.health = clampf(float(saved.get("health", fighter.max_health)), 0.0, fighter.max_health)
		fighter.mana = clampf(float(saved.get("mana", fighter.mana)), 0.0, fighter.max_mana)
		fighter.set_used_once_ids(saved.get("used_once", []))
	_boss_ingot_rolled = bool(data.get("boss_ingot_rolled", false))
	loot.clear()
	for saved_stack: Dictionary in data.get("loot", []):
		var stack: InventorySlot = InventorySlot.from_save_data(saved_stack)
		if stack.item:
			loot.append(stack)
	var saved_stage: int = clampi(int(data.get("stage", 1)), 1, dungeon.stage_count)
	if saved_stage > 1:
		_start_stage(saved_stage)
	# Older saves have no monsters: the stage keeps the fresh ones.
	if data.has("enemies"):
		_restore_enemies(data["enemies"])


func _restore_enemies(saved_enemies: Array) -> void:
	enemies.clear()
	for saved: Dictionary in saved_enemies:
		var enemy_id: String = saved.get("id", "")
		if not ContentDB.has_enemy(enemy_id):
			continue
		var enemy: Combatant = _spawn_enemy(ContentDB.enemy(enemy_id))
		# A slime part: shrink it once per split before it was saved.
		var split: Dictionary = enemy.enemy_data.split
		for i in mini(int(saved.get("generation", 0)), int(split.get("times", 0))):
			_make_split_part(enemy, enemy, split)
		# A boss in a later phase: its values of that phase and the health bar it had (older saves: phase 0).
		enemy.restore_phase(int(saved.get("phase", 0)), float(saved.get("max_health", 0.0)))
		enemy.summons_done = int(saved.get("summons_done", 0))
		enemy.set_used_once_ids(saved.get("used_once", []))
		enemy.health = clampf(float(saved.get("health", enemy.max_health)), 1.0, enemy.max_health)
		enemy.is_boss = bool(saved.get("boss", false))
		enemy.regrow_count = int(saved.get("regrow_count", 0))
		if float(saved.get("regrow_left", -1.0)) >= 0.0:
			enemy.health = 0.0
			enemy.regrowing = true
			enemy.regrow_left = float(saved["regrow_left"])
		enemies.append(enemy)
	_update_shrouds()
	stage_started.emit(stage)
