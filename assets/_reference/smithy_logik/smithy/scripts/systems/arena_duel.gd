class_name ArenaDuel
extends Adventure
## One hero against one other hero (Kahn's hero tournament, HeroTournament). Runs like an
## adventure with a single stage, ticked by GameState and shown in the battle window, but the
## other side is a hero (Combatant.from_hero, drawn like a hero looking left) instead of monsters.
## No loot, no stamina; a victory gives the player's hero EXP (win_experience, arena.json
## "win_experience_factor", a bit slower than a dungeon). The arena "dungeon" (arena.json "dungeon") gives name, background
## and time limit; when the time is up, the fighter with the larger share of health left wins.
## Both fighters get arena.json "health_factor" times their health, so a duel lasts a while
## (heroes are made for fights against many monsters, one against one would be over in seconds),
## and every heal only "heal_factor" (with that much health a healer would never lose).
## Healing also wears off: every "heal_decay_interval" seconds it loses "heal_decay_step" of its
## strength (0.05 every 10 s), so two healers do not just heal until the time runs out.
## Duels are not saved: after loading, the tournament round is simply fought again.

var opponent: Hero


func _init(hero: Hero, rival: Hero, arena: DungeonData) -> void:
	opponent = rival
	var party: Array[Hero] = [hero]
	super(party, arena)
	for fighter in hero_fighters:
		_prepare(fighter)


## "Brakka gegen Torgai" for the window title.
func get_party_names() -> String:
	return Language.translate("%s gegen %s") % [heroes[0].display_name, opponent.display_name if opponent else "?"]


func tick(delta: float) -> void:
	if state == State.RUNNING and dungeon.time_limit > 0.0 and elapsed + delta >= dungeon.time_limit:
		elapsed = dungeon.time_limit
		timed_out = true
		_finish(_health_share(hero_fighters[0]) >= _health_share(enemies[0] if not enemies.is_empty() else null))
		return
	super(delta)
	var factor: float = get_heal_factor()
	for fighter in hero_fighters + enemies:
		fighter.heal_received_factor = factor


func _start_stage(number: int) -> void:
	stage = number
	enemies.clear()
	if opponent:
		var rival: Combatant = Combatant.from_hero(opponent)
		_prepare(rival)
		enemies.append(rival)
	for fighter in get_allies():
		fighter.attack_cooldown = fighter.get_attack_interval()
		fighter.offhand_cooldown = fighter.get_offhand_interval()
	walk_left = WALK_TIME
	stage_started.emit(stage)


## The arena rules for one fighter: more health, less healing.
func _prepare(fighter: Combatant) -> void:
	fighter.scale_power(float(ContentDB.arena().get("health_factor", 1.0)), 1.0)
	fighter.heal_received_factor = get_heal_factor()


## How strong every heal is right now: arena.json "heal_factor", minus "heal_decay_step" of it for
## every full "heal_decay_interval" seconds of the duel (never below 0).
func get_heal_factor() -> float:
	var arena: Dictionary = ContentDB.arena()
	var base: float = float(arena.get("heal_factor", 1.0))
	var interval: float = float(arena.get("heal_decay_interval", 0.0))
	if interval <= 0.0:
		return base
	var steps: int = floori(elapsed / interval)
	return base * maxf(1.0 - steps * float(arena.get("heal_decay_step", 0.0)), 0.0)


static func _health_share(fighter: Combatant) -> float:
	if fighter == null or fighter.max_health <= 0:
		return 0.0
	return fighter.health / fighter.max_health


## A victory: the player's hero gets the EXP of `win_experience_factor` monsters of the
## opponent's level (and levels up). Shown in the battle window like kill EXP.
func _finish(victory: bool) -> void:
	if victory and state == State.RUNNING and not heroes.is_empty() and opponent:
		var amount: int = win_experience(heroes[0].level, opponent.level)
		if amount > 0:
			heroes[0].add_experience(amount)
			kill_experience[heroes[0]] = kill_experience.get(heroes[0], 0) + amount
	super(victory)


## EXP of a won duel: opponent level × arena.json "win_experience_per_level" ×
## "win_experience_factor", with the level gap rule of monster kills (CombatRules.kill_experience).
static func win_experience(hero_level: int, opponent_level: int) -> int:
	var arena: Dictionary = ContentDB.arena()
	var base: int = roundi(maxi(1, opponent_level) * float(arena.get("win_experience_per_level", 0))
			* float(arena.get("win_experience_factor", 0.0)))
	if base <= 0:
		return 0
	return CombatRules.kill_experience(base, hero_level, opponent_level)


## Duels are never saved (GameState skips them).
func to_save_data() -> Dictionary:
	return {}
