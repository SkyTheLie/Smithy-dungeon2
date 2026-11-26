class_name BattleStage
extends Control
## The fight as a little side-view scene (top part of the battle window). Draws itself:
## the dungeon background (tiled, scrolls while the party walks), the heroes on the left
## (camera stays on them), the monsters on the right (they walk in at the start of a stage),
## health bars above everybody's heads (heroes also a blue mana bar below it), and rising numbers
## for damage and healing. Loot pops out of a defeated monster and lands on the ground; it moves
## with the ground while the party walks (a little faster if needed, so the heroes reach it during
## the walk) and is picked up when the first hero reaches it (or when the adventure ends).
## Heroes are drawn with their generated look and their equipment (CharacterBaker.get_battle_sheet,
## looking right); their weapon is drawn on its own so it can swing. Summons of the heroes
## (elementals, wolf) stand in front of them, with the picture of their monster turned to the right.
##
## Animations: every attack plays a pose (FighterMotion: swing, thrust, slam, shoot, cast, lunge;
## from skills.json "anim", else from the skill or weapon_types.json "attack_anim"; heroes with an
## own attack animation (gear.json "attacks" in the melee poses, builder figures in all poses; Bruno is
## drawn as his builder "battle_look") play its frames), the target
## reacts when the hit lands (knockback, white then red flash, number) and an effect is shown
## (BattleVfx: slash, stab, sparks, arrow, magic bolt; skills.json "vfx"; with an element its own
## bolt and hit, e.g. a fireball that bursts). Arrows and spells fly to the target first. Area
## skills play one effect over the whole group (a meteor, an earthquake ...; skills.json
## "area_vfx"). New buffs/debuffs show arrows up/down (or status_effects.json "apply_vfx"), lasting
## ones loop their "aura" at the feet (one buff and one debuff per fighter), shields a bubble,
## stunned fighters circling stars, hidden ones are see-through. Critical hits flash and shake the
## stage a little, dodges kick up dust, parries spark, the dead puff away, the revived get a beam
## of light, summons appear in one. Only looks: the fight does not wait.
## Monsters breathe (1 px up and down), flying ones (enemies.json "hover") float above the ground;
## everybody casts a soft shadow. Backgrounds of dungeons with "background_mirror" are tiled
## mirrored (every second copy flipped), so pictures that do not tile still scroll without a seam.
## Focus: a left click on a monster focuses it (Adventure.set_focus, again = away); heroes with
## enough IQ (HeroRole.focus_iq) attack it. The focused monster glows with a pulsing red outline.

## Poses that play a hero's own attack animation if his outfit has one (CharacterBaker.has_attack).
const MELEE_POSES: Array[String] = ["swing", "thrust", "slam", "lunge"]
## FighterMotion pose -> attack pose of a builder figure (CharacterBaker.has_pose).
const BODY_POSES: Dictionary = {"swing": "swing", "slam": "chop", "thrust": "thrust", "lunge": "thrust",
		"shoot": "shoot", "cast": "cast"}
## The bow while it is drawn: how far the string goes back (pixels), by when (pose time), its colour,
## and the arrow on it (longer than the bow reaches, with a metal tip).
const BOW_PULL: float = 9.0
const BOW_PULL_TIME: float = 0.34
const COLOR_BOW_STRING: Color = Color(0.86, 0.84, 0.76)
const COLOR_ARROW_TIP: Color = Color(0.82, 0.86, 0.9)
const ARROW_REACH: float = 4.0
## Weapon class of a weapon type: its animations are "<class>_stand", "_walk" and the attack from
## WEAPON_CLASS_ATTACK. Any metal fits, the weapon itself stays its own picture.
const WEAPON_CLASS: Dictionary = {"sword": "one", "dagger": "one", "axe": "one", "mace": "one", "hammer": "one",
		"pickaxe": "one", "two_handed_sword": "two", "two_handed_axe": "two", "polearm": "pole", "staff": "pole",
		"two_handed_staff": "pole", "bow": "bow", "longbow": "bow", "tome": "tome"}
## Attack animation of a class per FighterMotion pose; "*" = every pose.
const WEAPON_CLASS_ATTACK: Dictionary = {
	"one": {"swing": "swing", "slam": "chop", "thrust": "thrust", "lunge": "thrust", "shoot": "swing", "cast": "cast"},
	"two": {"*": "chop"},
	"pole": {"swing": "thrust", "slam": "thrust", "thrust": "thrust", "lunge": "thrust", "shoot": "thrust", "cast": "cast"},
	"bow": {"*": "shoot"},
	"tome": {"*": "cast"},
}
## Body pose between attacks: the hero stands ready, looping at this speed.
const GUARD_POSE: String = "guard"
const GUARD_FPS: float = 5.0
## Character sheet: 48x48 frames, column 0 = standing, 1-6 = walking.
const HERO_FRAME: Vector2 = Vector2(48, 48)
const WALK_FRAMES: int = 6
const WALK_FPS: float = 10.0
const MONSTER_SCALE: float = 2.0
## Distance from the bottom edge to the feet.
const GROUND_OFFSET: float = 12.0
## Monsters: seconds per breath, height a flying monster floats at (pixels above the ground) and
## how far it bobs up and down.
const BREATH_TIME: float = 1.6
const HOVER_HEIGHT: float = 6.0
const HOVER_BOB: float = 2.5
## Shadow under every fighter: colour, height of the ellipse.
const COLOR_SHADOW: Color = Color(0.05, 0.02, 0.05, 0.35)
const SHADOW_HEIGHT: float = 4.0
## Defeated monsters (without their own death animation) sink together and fade out in this time.
const DEATH_TIME: float = 0.5
## Laid over the background so the fighters stand out from detailed pictures: darker at the top
## (ceiling, sky) than at the ground.
const COLOR_BACKGROUND_DIM_TOP: Color = Color(0.03, 0.02, 0.05, 0.42)
const COLOR_BACKGROUND_DIM_GROUND: Color = Color(0.03, 0.02, 0.05, 0.12)
## Background pixels per second while walking.
const SCROLL_SPEED: float = 70.0
const FLOAT_TIME: float = 0.9
const BAR_SIZE: Vector2 = Vector2(28, 3)
## Bosses with phases: one health bar per phase, stacked; distance from one bar to the next.
const PHASE_BAR_STEP: float = 5.0
## Monsters sharing one body (the hydra's heads): one bar per monster, stacked with room for its label.
const BODY_BAR_STEP: float = 8.0
const MANA_BAR_HEIGHT: float = 2.0
## Height of the heroes' health bar above the ground (a bit above their heads).
const HERO_BAR_HEIGHT: float = 54.0
## Heroes: middle of the body and the hand that shoots (above the ground, forward).
const HERO_CENTER_HEIGHT: float = 24.0
const HERO_HAND: Vector2 = Vector2(8.0, 22.0)
## From the hand to where the arrow lies on the drawn bow.
const HERO_BOW_RELEASE: Vector2 = Vector2(8.0, -4.0)
## Pixels of the body around the hand drawn again over the weapon's grip.
const HERO_FIST: Vector2 = Vector2(4.0, 4.0)
## PixelLab battle figures (BattleFigure): their feet this far above the ground line, like the old
## figure's; the shield's middle this far from the fist that holds it.
const FIGURE_FEET: float = 6.0
## Distance between the heroes (the PixelLab figures with a shield are about 45 px wide).
const HERO_SPACING: float = 48.0
const FIGURE_SHIELD_OFFSET: Vector2 = Vector2(-6.0, 0.0)
## Degrees forward a hero holds the weapon between attacks (0 = upright like in the picture).
const WEAPON_REST_DEFAULT: float = 35.0
const WEAPON_REST: Dictionary = {"bow": 0.0, "longbow": 0.0, "tome": 0.0, "staff": 8.0, "two_handed_staff": 8.0}
## Arrows and spells: pixels per second, shortest and longest flight.
const PROJECTILE_SPEED: float = 320.0
const FLIGHT_MIN: float = 0.12
const FLIGHT_MAX: float = 0.4
## Critical hits: seconds the stage shakes (1 pixel).
const SHAKE_TIME: float = 0.15
const COLOR_BAR_BACK: Color = Color(0.13, 0.075, 0.12)
const COLOR_HERO_HEALTH: Color = Color(0.35, 0.8, 0.3)
const COLOR_MONSTER_HEALTH: Color = Color(0.85, 0.3, 0.25)
const COLOR_MANA: Color = Color(0.3, 0.5, 0.95)
const COLOR_SHIELD: Color = Color(0.5, 0.72, 1.0)
## Shield points on the health bar (extra health).
const COLOR_OVERHEAL: Color = Color(0.96, 0.96, 0.96)
const COLOR_HIT: Color = Color(1.0, 0.35, 0.3)
## Modulate of the short white flash when hit (more than 1 = brighter).
const COLOR_FLASH: Color = Color(4.0, 4.0, 4.0)
const COLOR_DAMAGE: Color = Color(1.0, 0.95, 0.85)
const COLOR_CRIT: Color = Color(1.0, 0.8, 0.25)
const COLOR_HEAL: Color = Color(0.45, 0.9, 0.5)
const COLOR_STUN: Color = Color(1.0, 0.9, 0.35)
## Colour of a slash/stab without element, of a buff/debuff arrow when the effect has no colour.
const COLOR_STRIKE: Color = Color(1.0, 1.0, 0.95)
const COLOR_BUFF: Color = Color(1.0, 0.85, 0.35)
const COLOR_DEBUFF: Color = Color(0.7, 0.45, 0.95)
const COLOR_SUMMON_ENEMY: Color = Color(1.0, 0.45, 0.35)
## Alpha of a hidden fighter (status effect "untargetable", e.g. Verschleiert).
const HIDDEN_ALPHA: float = 0.45
## The hits of one area skill come in the same frame: its area effect plays once within this time.
const AREA_GAP: float = 0.05
## Outline of the monster the player focused (pulses between the two alphas).
const COLOR_FOCUS: Color = Color(1.0, 0.2, 0.15)
const FOCUS_ALPHA: Vector2 = Vector2(0.55, 1.0)
const FOCUS_PULSE_SPEED: float = 6.0
const FOCUS_WIDTH: float = 2.0
const TEXT_NO_FOCUS: String = "Deine Helden sind noch nicht klug genug, um einem Ziel zu folgen (ab IQ %d)."
const FONT_SIZE: int = 11
## Loot: pixels per second² falling, upward speed when it pops out, sideways speed (random up
## to this), seconds of the pick-up animation.
const DROP_GRAVITY: float = 420.0
const DROP_JUMP: float = 110.0
const DROP_SIDEWAYS: float = 35.0
const PICKUP_TIME: float = 0.35

var _adventure: Adventure
var _scroll: float = 0.0
var _time: float = 0.0
## Combatant -> FighterMotion.
var _motions: Dictionary = {}
var _vfx := BattleVfx.new()
## Things that happen a bit later (when a swing or an arrow lands): {"time", "action"}.
var _pending: Array[Dictionary] = []
var _shake: float = 0.0
## Floating texts: {"text", "color", "fighter", "age"}.
var _floats: Array[Dictionary] = []
## Loot on the stage: {"icon", "x", "height" (above the ground), "vx", "vy", "landed",
## "pickup" (seconds since it was picked up, -1 = still lying)}.
var _drops: Array[Dictionary] = []
## Red silhouettes of monster pictures for the focus outline: key -> ImageTexture.
var _silhouettes: Dictionary = {}
## Combatant -> alive in the last frame (death puff, revive beam).
var _alive: Dictionary = {}
## "<attacker id>:<skill id>" -> _time its area effect started.
var _areas: Dictionary = {}
## Defeated monsters without a death animation: Combatant -> _time they fell.
var _died_at: Dictionary = {}
## Monsters playing one of their own animations (EnemyData.animations): Combatant -> [key, _time it started].
var _monster_animations: Dictionary = {}


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = Language.translate("Klick auf einen Gegner: Deine Helden greifen ihn gezielt an (ab IQ %d).") % HeroRole.focus_iq()


func show_adventure(adventure: Adventure) -> void:
	if _adventure:
		_adventure.attacked.disconnect(_on_attacked)
		_adventure.effect_ticked.disconnect(_on_effect_ticked)
		_adventure.loot_dropped.disconnect(_on_loot_dropped)
		_adventure.enemies_summoned.disconnect(_on_enemies_summoned)
		_adventure.healed.disconnect(_on_healed)
		_adventure.summon_called.disconnect(_on_summon_called)
		_adventure.skill_used.disconnect(_on_skill_used)
		_adventure.phase_started.disconnect(_on_phase_started)
	_adventure = adventure
	_adventure.attacked.connect(_on_attacked)
	_adventure.effect_ticked.connect(_on_effect_ticked)
	_adventure.loot_dropped.connect(_on_loot_dropped)
	_adventure.enemies_summoned.connect(_on_enemies_summoned)
	_adventure.healed.connect(_on_healed)
	_adventure.summon_called.connect(_on_summon_called)
	_adventure.skill_used.connect(_on_skill_used)
	_adventure.phase_started.connect(_on_phase_started)
	_motions.clear()
	_vfx.clear()
	_pending.clear()
	_floats.clear()
	_drops.clear()
	_alive.clear()
	_died_at.clear()
	_areas.clear()


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _adventure == null:
		return
	_time += delta
	if _adventure.is_walking():
		_scroll += SCROLL_SPEED * delta
	_shake = maxf(_shake - delta, 0.0)
	for motion: FighterMotion in _motions.values():
		motion.tick(delta)
	_vfx.tick(delta)
	_run_pending(delta)
	_spawn_effect_arrows()
	_spawn_life_changes()
	for entry in _floats:
		entry["age"] += delta
	_floats = _floats.filter(func(entry: Dictionary) -> bool: return entry["age"] < FLOAT_TIME)
	_update_drops(delta)
	queue_redraw()


func _get_motion(fighter: Combatant) -> FighterMotion:
	if not _motions.has(fighter):
		_motions[fighter] = FighterMotion.new()
	return _motions[fighter]


func _schedule(delay: float, action: Callable) -> void:
	if delay <= 0.0:
		action.call()
	else:
		_pending.append({"time": delay, "action": action})


func _run_pending(delta: float) -> void:
	var due: Array[Callable] = []
	for entry in _pending:
		entry["time"] -= delta
		if entry["time"] <= 0.0:
			due.append(entry["action"])
	_pending = _pending.filter(func(entry: Dictionary) -> bool: return entry["time"] > 0.0)
	for action in due:
		action.call()


## Arrows up (buff) or down (debuff) for every status effect a fighter got since the last frame,
## or the effect's own "apply_vfx" (e.g. the sparkle of a cleanse).
func _spawn_effect_arrows() -> void:
	for fighter in _get_all_fighters():
		var motion: FighterMotion = _get_motion(fighter)
		var now: Dictionary = {}
		for active in fighter.effects:
			now[active.data.id] = active.data
		for effect_id in now:
			if not motion.effect_ids.has(effect_id) and fighter.is_alive():
				var effect: StatusEffectData = now[effect_id]
				var buff: bool = effect.kind == StatusEffectData.Kind.BUFF
				var kind: String = effect.apply_vfx if not effect.apply_vfx.is_empty() else ("buff" if buff else "debuff")
				_vfx.spawn(kind, _get_center(fighter), _get_effect_color(effect))
		motion.effect_ids = now


func _get_effect_color(effect: StatusEffectData) -> Color:
	if effect.color != Color.WHITE:
		return effect.color
	return COLOR_BUFF if effect.kind == StatusEffectData.Kind.BUFF else COLOR_DEBUFF


## A fighter that died since the last frame puffs away, one that came back gets a beam of light.
func _spawn_life_changes() -> void:
	for fighter in _get_all_fighters():
		var alive: bool = fighter.is_alive()
		if _alive.has(fighter) and _alive[fighter] != alive:
			# A head of a body with more heads (the hydra): only a puff, the body stays.
			if _get_body_members(fighter).any(func(other: Combatant) -> bool: return other != fighter and other.is_alive()):
				if alive:
					_vfx.spawn("area_holy", _get_feet(fighter), Color.WHITE)
				else:
					_vfx.spawn("death", _get_center(fighter), Color.WHITE)
				_alive[fighter] = alive
				continue
			if alive:
				_monster_animations.erase(_get_body(fighter))
				_died_at.erase(_get_body(fighter))
				_vfx.spawn("area_holy", _get_feet(fighter), Color.WHITE)
			elif not _play_monster_animation(fighter, ["death"]):
				_vfx.spawn("death", _get_center(fighter), Color.WHITE)
				_died_at[_get_body(fighter)] = _time
		_alive[fighter] = alive


## Starts the first of `keys` the monster (or the monster a summon looks like) has its own animation
## for; false if it has none.
func _play_monster_animation(fighter: Combatant, keys: Array) -> bool:
	var look: EnemyData = _get_look(fighter)
	if look == null:
		return false
	for key in keys:
		if look.animations.has(key):
			_monster_animations[_get_body(fighter)] = [key, _time]
			return true
	return false


## The monster whose pictures a fighter uses: its own, or the look of a summon (wolf, elemental).
func _get_look(fighter: Combatant) -> EnemyData:
	if fighter.enemy_data:
		return fighter.enemy_data
	return fighter.summon_data.look if fighter.summon_data else null


## Monsters sharing one body (EnemyData.body, the hydra's heads): all of them in battle order; any
## other fighter alone.
func _get_body_members(fighter: Combatant) -> Array[Combatant]:
	var members: Array[Combatant] = []
	var body: String = fighter.enemy_data.body if fighter.enemy_data else ""
	if body.is_empty() or _adventure == null or not _adventure.enemies.has(fighter):
		members.append(fighter)
		return members
	for enemy in _adventure.enemies:
		if enemy.enemy_data and enemy.enemy_data.body == body:
			members.append(enemy)
	return members


## The fighter that draws the shared picture (the first of its body), or the fighter itself.
func _get_body(fighter: Combatant) -> Combatant:
	return _get_body_members(fighter)[0]


## The first living monster of the body (for breathing, tint), else the body itself.
func _get_body_face(fighter: Combatant) -> Combatant:
	for member in _get_body_members(fighter):
		if member.is_alive():
			return member
	return fighter


func _is_body_alive(fighter: Combatant) -> bool:
	return _get_body_members(fighter).any(func(member: Combatant) -> bool: return member.is_alive())


## The motion of the body: the member that moves the most right now (attacks, hits).
func _get_body_motion(fighter: Combatant) -> FighterMotion:
	var best: FighterMotion = _get_motion(fighter)
	var best_amount: float = _get_motion_amount(best)
	for member in _get_body_members(fighter):
		var motion: FighterMotion = _get_motion(member)
		var amount: float = _get_motion_amount(motion)
		if amount > best_amount:
			best = motion
			best_amount = amount
	return best


func _get_motion_amount(motion: FighterMotion) -> float:
	return motion.get_offset().length() + absf(motion.get_squash().x - 1.0) * 10.0


func _get_all_fighters() -> Array[Combatant]:
	var all: Array[Combatant] = []
	all.append_array(_adventure.hero_fighters)
	all.append_array(_adventure.summons)
	all.append_array(_adventure.enemies)
	return all


## A boss calls helpers: its shout above it (EnemyData.summon_shout, e.g. "Zu mir, Jungs!").
func _on_enemies_summoned(summoner: Combatant, helpers: Array[Combatant]) -> void:
	var shout: String = summoner.enemy_data.summon_shout if summoner.enemy_data else "Zu mir, Jungs!"
	_floats.append({"text": shout, "color": COLOR_CRIT, "fighter": summoner, "age": 0.0})
	for helper in helpers:
		_vfx.spawn("summon", _get_feet(helper), COLOR_SUMMON_ENEMY)


## A boss begins its next phase (another health bar): its shout above it, the stage shakes.
func _on_phase_started(enemy: Combatant, text: String) -> void:
	_floats.append({"text": text, "color": COLOR_CRIT, "fighter": enemy, "age": 0.0})
	_shake = SHAKE_TIME * 3.0


## A hero called a summon: its name above it.
func _on_summon_called(_summoner: Combatant, summon: Combatant) -> void:
	_floats.append({"text": summon.display_name, "color": COLOR_HEAL, "fighter": summon, "age": 0.0})
	_vfx.spawn("summon", _get_feet(summon), summon.summon_data.tint if summon.summon_data else COLOR_HEAL)


func _on_healed(target: Combatant, amount: int) -> void:
	if amount > 0:
		_floats.append({"text": "+%d" % amount, "color": COLOR_HEAL, "fighter": target, "age": 0.0})
		_vfx.spawn("heal", _get_center(target), COLOR_HEAL)


## Skills without a hit (heals, buffs, summons) still play their pose; attacks start theirs again
## in _on_attacked (the same pose does not restart).
func _on_skill_used(user: Combatant, skill: SkillData) -> void:
	var pose: String = _get_pose(user, skill)
	_get_motion(user).start(pose)
	_play_monster_animation(user, [String(skill.id), pose])
	if pose == "cast":
		_schedule(FighterMotion.get_impact_delay(pose), func() -> void:
			_vfx.spawn("glow", _get_hand(user), _get_skill_color(skill), _get_facing(user)))
	if skill.target == SkillData.Target.ALL_ALLIES and skill.heal_percent > 0.0:
		var side: Array[Combatant] = _get_side(user)
		_schedule(FighterMotion.get_impact_delay(pose), func() -> void:
			_vfx.spawn(_get_area_kind(skill, "area_heal"), _get_area_point(side), Color.WHITE))


## The attacker starts its pose; when it lands (after the swing, or when the arrow/spell arrives)
## the target reacts, the effect and the number appear. An area skill plays its area effect once
## over the group instead of one effect per target.
func _on_attacked(attacker: Combatant, target: Combatant, damage: int, skill: SkillData, hit: Dictionary) -> void:
	var pose: String = _get_pose(attacker, skill)
	_get_motion(attacker).start(pose)
	_play_monster_animation(attacker, [String(skill.id) if skill else "", pose])
	var release: float = FighterMotion.get_impact_delay(pose)
	var main_kind: String = DamageKinds.get_main_kind(hit.get("split", {}))
	var kind: String = BattleVfx.element_kind(_get_vfx(attacker, pose, skill), main_kind)
	var color: Color = _get_hit_color(skill, hit)
	var facing: float = _get_facing(attacker)
	var area: String = _get_area_vfx(skill, pose, main_kind)
	if not area.is_empty():
		_play_area(attacker, target, skill, area, release)
		if area == "area_meteor":
			release += BattleVfx.METEOR_FALL
		_schedule(release, _show_hit.bind(target, damage, skill, hit, "none", color, facing))
	elif BattleVfx.is_flying(kind):
		var from: Vector2 = _get_hand(attacker) + (HERO_BOW_RELEASE * Vector2(_get_facing(attacker), 1.0) if attacker.hero and pose == "shoot" else Vector2.ZERO)
		var to: Vector2 = _get_center(target)
		var flight: float = clampf(from.distance_to(to) / PROJECTILE_SPEED, FLIGHT_MIN, FLIGHT_MAX)
		_schedule(release, func() -> void: _vfx.spawn(kind, to, color, facing, from, flight))
		var impact: String = BattleVfx.element_kind("impact", main_kind)
		if kind == "arrow" and impact == "impact":
			impact = "hit_arrow"
		_schedule(release + flight, _show_hit.bind(target, damage, skill, hit, impact, color, facing))
	else:
		_schedule(release, _show_hit.bind(target, damage, skill, hit, kind, color, facing))


## The area effect of a skill over the target's group, once for all its hits (a meteor falls
## first, from the caster's side of the sky).
func _play_area(attacker: Combatant, target: Combatant, skill: SkillData, area: String, release: float) -> void:
	var key: String = "%d:%s" % [attacker.get_instance_id(), skill.id]
	if _time - _areas.get(key, -INF) < AREA_GAP:
		return
	_areas[key] = _time
	var at: Vector2 = _get_area_point(_get_side(target)) + BattleVfx.AREA_OFFSET.get(area, Vector2.ZERO)
	if area == "area_meteor":
		var from: Vector2 = at + BattleVfx.METEOR_FROM * Vector2(_get_facing(attacker), 1.0)
		_schedule(release, func() -> void: _vfx.spawn("fire_bolt", at, Color.WHITE, 1.0, from, BattleVfx.METEOR_FALL, true))
		release += BattleVfx.METEOR_FALL
	_schedule(release, func() -> void:
		_vfx.spawn(area, at, Color.WHITE)
		_shake = SHAKE_TIME)


## Area effect of a skill that hits every enemy: skills.json "area_vfx" ("none" = none), else
## from its main damage kind (BattleVfx.AREA_KINDS) or an earthquake for a slam. "" = none.
func _get_area_vfx(skill: SkillData, pose: String, main_kind: String) -> String:
	if skill == null or skill.target != SkillData.Target.ALL_ENEMIES:
		return ""
	var fallback: String = BattleVfx.AREA_KINDS.get(main_kind, "area_quake" if pose == "slam" else "")
	return _get_area_kind(skill, fallback)


func _get_area_kind(skill: SkillData, fallback: String) -> String:
	var area: String = skill.area_vfx if not skill.area_vfx.is_empty() else fallback
	return "" if area == "none" else area


## The living fighters on the side of `fighter` (heroes and their summons, or the monsters).
func _get_side(fighter: Combatant) -> Array[Combatant]:
	var all: Array[Combatant] = []
	if _adventure.enemies.has(fighter):
		all.assign(_adventure.enemies)
	else:
		all.assign(_adventure.hero_fighters + _adventure.summons)
	var side: Array[Combatant] = []
	side.assign(all.filter(func(other: Combatant) -> bool: return other.is_alive()))
	return side


## On the ground in the middle of a group.
func _get_area_point(side: Array[Combatant]) -> Vector2:
	if side.is_empty():
		return Vector2(size.x / 2.0, _get_ground())
	var x: float = 0.0
	for fighter in side:
		x += _fighter_x(fighter)
	return Vector2(roundf(x / side.size()), _get_ground())


## Damage numbers: physical in white, otherwise in the colour of the main damage kind (fire
## orange-red ...); critical hits get a "!" and the crit colour. A melee hit with an element also
## shows the element's hit (a fire slash bursts into flames).
func _show_hit(target: Combatant, damage: int, skill: SkillData, hit: Dictionary, kind: String, color: Color, facing: float) -> void:
	if _adventure == null:
		return
	var center: Vector2 = _get_center(target)
	_vfx.spawn(kind, center, color, facing)
	var main_kind: String = DamageKinds.get_main_kind(hit.get("split", {}))
	var element_hit: String = BattleVfx.element_kind("impact", main_kind)
	if kind != "none" and kind != element_hit and element_hit != "impact" and damage > 0:
		_vfx.spawn(element_hit, center, color, facing)
	if hit.get("dodged", false):
		_floats.append({"text": Language.translate("Ausgewichen"), "color": COLOR_DAMAGE, "fighter": target, "age": 0.0})
		_vfx.spawn("dodge", _get_feet(target), Color.WHITE, facing)
	elif hit.get("parried", false):
		_floats.append({"text": Language.translate("Pariert"), "color": COLOR_DAMAGE, "fighter": target, "age": 0.0})
		_vfx.spawn("block", center, Color.WHITE, -facing)
	elif damage > 0:
		_get_motion(target).hit()
		if not _monster_animations.has(_get_body(target)):
			_play_monster_animation(target, ["hit"])
		var text_color: Color = COLOR_DAMAGE
		if not DamageKinds.is_physical(main_kind):
			text_color = DamageKinds.get_color(main_kind)
		var crit: bool = hit.get("crit", false)
		if crit:
			_shake = SHAKE_TIME
			_vfx.spawn("crit", center, COLOR_CRIT, facing)
		_floats.append({"text": str(damage) + ("!" if crit else ""), "color": COLOR_CRIT if crit else text_color, "fighter": target, "age": 0.0})
	elif skill:
		_floats.append({"text": skill.display_name, "color": COLOR_HEAL, "fighter": target, "age": 0.0})


## Pose of an attack or skill: skills.json "anim", else spells, support skills and skills without
## damage (curses) "cast", else the weapon's "attack_anim" (heroes), "cast" for magic monsters and
## summons, "shoot" for monsters in the back row, "lunge" otherwise.
func _get_pose(fighter: Combatant, skill: SkillData) -> String:
	if skill and not skill.anim.is_empty():
		return skill.anim
	if skill and (skill.is_magic() or skill.damage_multiplier <= 0.0
			or skill.target in [SkillData.Target.SELF, SkillData.Target.ALLY, SkillData.Target.ALL_ALLIES]):
		return "cast"
	if fighter.hero:
		var type_id: String = fighter.hero.get_battle_gear().get("weapon", {}).get("type", "")
		var type: WeaponType = ContentDB.weapon_type(type_id) if not type_id.is_empty() else null
		return type.attack_anim if type else "lunge"
	if fighter.basic_magic:
		return "cast"
	return "shoot" if fighter.back_row else "lunge"


## Effect on the target: skills.json "vfx", else from the pose.
func _get_vfx(fighter: Combatant, pose: String, skill: SkillData) -> String:
	if skill and not skill.vfx.is_empty():
		return skill.vfx
	if skill == null and fighter.enemy_data and not fighter.enemy_data.attack_vfx.is_empty():
		return fighter.enemy_data.attack_vfx
	if skill == null and fighter.hero:
		var type_id: String = fighter.hero.get_battle_gear().get("weapon", {}).get("type", "")
		var type: WeaponType = ContentDB.weapon_type(type_id) if not type_id.is_empty() else null
		if type and not type.hit_vfx.is_empty():
			return type.hit_vfx
	match pose:
		"swing", "slam":
			return "slash"
		"thrust":
			return "pierce"
		"shoot":
			return "arrow"
		"cast":
			return "bolt"
	return "slash" if fighter.hero else "impact"


## Colour of the effect: the main damage kind if it is not physical (fire orange ...), else white.
func _get_hit_color(skill: SkillData, hit: Dictionary) -> Color:
	var main_kind: String = DamageKinds.get_main_kind(hit.get("split", {}))
	if not DamageKinds.is_physical(main_kind):
		return DamageKinds.get_color(main_kind)
	return _get_skill_color(skill) if skill and skill.is_magic() else COLOR_STRIKE


func _get_skill_color(skill: SkillData) -> Color:
	if skill == null:
		return COLOR_STRIKE
	var main_kind: String = DamageKinds.get_main_kind(skill.get_damage_split())
	if not DamageKinds.is_physical(main_kind):
		return DamageKinds.get_color(main_kind)
	if skill.heal_percent > 0.0:
		return COLOR_HEAL
	return DamageKinds.get_color("magic") if skill.is_magic() else COLOR_BUFF


func _on_loot_dropped(enemy: Combatant, stack: InventorySlot) -> void:
	var index: int = maxi(0, _adventure.enemies.find(enemy))
	var size_y: float = _get_sprite_size(enemy).y
	_drops.append({"icon": stack.get_icon(), "x": _monster_x(index), "height": size_y * 0.5,
			"vx": randf_range(-DROP_SIDEWAYS, DROP_SIDEWAYS), "vy": DROP_JUMP, "landed": false, "pickup": -1.0})


## Flying loot falls and bounces once; lying loot moves with the ground while the party walks;
## the first hero picks it up when he reaches it, and at the end everything is picked up.
func _update_drops(delta: float) -> void:
	var collect_all: bool = _adventure.state != Adventure.State.RUNNING
	for drop in _drops:
		if drop["pickup"] >= 0.0:
			drop["pickup"] += delta
			continue
		if not drop["landed"]:
			drop["x"] += drop["vx"] * delta
			drop["vy"] -= DROP_GRAVITY * delta
			drop["height"] = maxf(drop["height"] + drop["vy"] * delta, 0.0)
			if drop["height"] <= 0.0 and drop["vy"] < 0.0:
				if absf(drop["vy"]) > DROP_JUMP * 0.5:
					drop["vy"] = -drop["vy"] * 0.3
				else:
					drop["landed"] = true
		if _adventure.is_walking():
			# At least as fast as the ground, fast enough that the heroes reach it during this walk.
			var needed: float = (drop["x"] - _hero_x(0)) / maxf(_adventure.walk_left, 0.05)
			drop["x"] -= maxf(SCROLL_SPEED, needed) * delta
		if drop["landed"] and (collect_all or drop["x"] <= _hero_x(0) + 6.0):
			drop["pickup"] = 0.0
	_drops = _drops.filter(func(drop: Dictionary) -> bool: return drop["pickup"] < PICKUP_TIME)


func _on_effect_ticked(target: Combatant, effect: StatusEffectData, amount: int, heal: bool) -> void:
	if amount <= 0:
		return
	_floats.append({"text": ("+%d" if heal else "%d") % amount, "color": COLOR_HEAL if heal else effect.color, "fighter": target, "age": 0.0})


# --- Positions ----------------------------------------------------------------------

## Heroes stand on the left, the first one in front (furthest right).
func _hero_x(index: int) -> float:
	return 136.0 - index * HERO_SPACING


## Summons stand in front of the first hero, next to each other.
func _summon_x(index: int) -> float:
	return _hero_x(0) + 30.0 + index * 22.0


## Monsters stand on the right; while the party walks they come in from the right edge. The back
## row (archers) stands furthest right, behind the front row; with many monsters (a boss called
## helpers) they stand closer together.
func _monster_x(index: int) -> float:
	var enemies: Array[Combatant] = _adventure.enemies
	var order: Array[Combatant] = []
	order.assign(enemies.filter(func(fighter: Combatant) -> bool: return fighter.back_row))
	order.append_array(enemies.filter(func(fighter: Combatant) -> bool: return not fighter.back_row))
	# Monsters sharing one body (the hydra's heads) stand on one spot.
	var units: Array[Combatant] = []
	for fighter in order:
		var body: Combatant = _get_body(fighter)
		if not units.has(body):
			units.append(body)
	var slot: int = units.find(_get_body(enemies[index])) if index < enemies.size() else index
	var spacing: float = minf(46.0, size.x * 0.6 / maxf(1.0, units.size()))
	var x: float = size.x - 52.0 - slot * spacing
	if _adventure.is_walking():
		x += (1.0 - _adventure.get_walk_progress()) * (size.x * 0.6)
	return x


func _fighter_x(fighter: Combatant) -> float:
	var index: int = _adventure.hero_fighters.find(fighter)
	if index >= 0:
		return _hero_x(index)
	if fighter.is_summon() and not _adventure.enemies.has(fighter):
		return _summon_x(maxi(0, _adventure.summons.find(fighter)))
	return _monster_x(maxi(0, _adventure.enemies.find(fighter)))


func _get_ground() -> float:
	return size.y - GROUND_OFFSET


## 1 = looks right (heroes, summons), -1 = looks left (monsters).
func _get_facing(fighter: Combatant) -> float:
	return -1.0 if _adventure.enemies.has(fighter) else 1.0


## Size of a monster's or summon's picture on the stage.
func _get_sprite_size(fighter: Combatant) -> Vector2:
	if fighter.icon == null:
		return Vector2(32, 32)
	var scale_factor: float = fighter.get_scale() if fighter.enemy_data else (fighter.summon_data.scale if fighter.summon_data else 1.0)
	return (fighter.icon.get_size() * MONSTER_SCALE * scale_factor).round()


## Middle of the body (where effects hit).
func _get_center(fighter: Combatant) -> Vector2:
	var height: float = HERO_CENTER_HEIGHT if fighter.hero else _get_sprite_size(fighter).y / 2.0
	return Vector2(_fighter_x(fighter), _get_ground() - height).round()


## On the ground under the fighter (status auras, dust, summons appear).
func _get_feet(fighter: Combatant) -> Vector2:
	return Vector2(_fighter_x(fighter), _get_ground()).round()


## Where arrows and spells leave the fighter.
func _get_hand(fighter: Combatant) -> Vector2:
	var facing: float = _get_facing(fighter)
	if fighter.hero:
		return Vector2(_fighter_x(fighter) + HERO_HAND.x * facing, _get_ground() - HERO_HAND.y)
	var sprite_size: Vector2 = _get_sprite_size(fighter)
	return _get_center(fighter) + Vector2(sprite_size.x * 0.3 * facing, 0.0)


# --- Drawing ------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BAR_BACK)
	if _adventure == null:
		return
	var shake := Vector2(randi_range(-1, 1), randi_range(-1, 1)) if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(shake)
	_draw_background(shake)
	var ground: float = _get_ground()
	for fighter in _get_all_fighters():
		_draw_shadow(fighter)
		_draw_auras(fighter, true)
	for i in _adventure.hero_fighters.size():
		_draw_hero(_adventure.hero_fighters[i], _hero_x(i), ground, shake)
	for i in _adventure.summons.size():
		_draw_summon(_adventure.summons[i], _summon_x(i), ground, shake)
	for i in _adventure.enemies.size():
		var enemy: Combatant = _adventure.enemies[i]
		# Arena duels (ArenaDuel): the opponent is a hero, drawn like one but looking left.
		if enemy.hero:
			_draw_hero(enemy, _monster_x(i), ground, shake, -1.0)
		elif enemy.is_summon():
			_draw_summon(enemy, _monster_x(i), ground, shake, -1.0)
		elif _get_body(enemy) == enemy:
			# The other heads of a shared body are drawn with it (one picture, their bars above it).
			_draw_monster(enemy, _monster_x(i), ground, shake)
			if _get_body_members(enemy).size() == 1:
				_draw_regrow_timer(enemy, _monster_x(i), ground)
	for fighter in _get_all_fighters():
		_draw_auras(fighter, false)
		_draw_states(fighter)
	_vfx.offset = shake
	_vfx.draw(self)
	for drop in _drops:
		_draw_drop(drop, ground)
	draw_set_transform(Vector2.ZERO)
	for entry in _floats:
		_draw_float(entry, ground)


func _draw_background(shake: Vector2) -> void:
	var texture: Texture2D = _adventure.dungeon.battle_background
	if texture == null:
		return
	var width: float = texture.get_width()
	var offset: float = fmod(_scroll, width)
	var top: float = size.y - texture.get_height()
	var mirror: bool = _adventure.dungeon.background_mirror
	var copy: int = int(floor(_scroll / width))
	var x: float = -offset - 1.0
	while x < size.x + 1.0:
		var at := Vector2(roundf(x), top)
		if mirror and copy % 2 == 1:
			# Flipped around the middle of this copy (as _draw_summon).
			draw_set_transform(shake + Vector2(2.0 * at.x + width, 0.0), 0.0, Vector2(-1.0, 1.0))
			draw_texture(texture, at)
			draw_set_transform(shake)
		else:
			draw_texture(texture, at)
		x += width
		copy += 1
	var colors := PackedColorArray([COLOR_BACKGROUND_DIM_TOP, COLOR_BACKGROUND_DIM_TOP,
			COLOR_BACKGROUND_DIM_GROUND, COLOR_BACKGROUND_DIM_GROUND])
	draw_polygon(PackedVector2Array([Vector2(-2, -2), Vector2(size.x + 2, -2), Vector2(size.x + 2, size.y + 2),
			Vector2(-2, size.y + 2)]), colors)


## Body without weapon, then the weapon turned around the hand. `facing` -1 = mirrored, looking
## left (a hero on the monsters' side in an arena duel).
func _draw_hero(fighter: Combatant, x: float, ground: float, shake: Vector2, facing: float = 1.0) -> void:
	if _draw_battle_figure(fighter, x, ground, shake, facing):
		_draw_health_bar(fighter, Vector2(x, ground - HERO_BAR_HEIGHT), COLOR_HERO_HEALTH if facing > 0.0 else COLOR_MONSTER_HEALTH)
		_draw_mana_bar(fighter, Vector2(x, ground - HERO_BAR_HEIGHT))
		return
	var frame: int = 0
	if _adventure.is_walking() and fighter.is_alive():
		frame = 1 + int(_time * WALK_FPS) % WALK_FRAMES
	var motion: FighterMotion = _get_motion(fighter)
	var at: Vector2 = Vector2(roundf(x - HERO_FRAME.x / 2.0), roundf(ground - HERO_FRAME.y + 4.0)) + motion.get_offset()
	var look: Appearance = fighter.hero.get_battle_look() if fighter.hero else Appearance.new()
	var gear: Dictionary = fighter.hero.get_battle_gear() if fighter.hero else {}
	var tint: Color = _apply_state_tint(fighter, Color.WHITE)
	var sheet: Texture2D = CharacterBaker.get_battle_sheet(look, gear, false)
	var hand_in_frame: Vector2
	var weapon_pose: String = _get_weapon_pose(look.outfit, gear, motion)
	var weapon_angle: float = NAN
	if not weapon_pose.is_empty():
		var count: int = CharacterBaker.get_pose_frame_count(look.outfit, weapon_pose)
		if not motion.pose.is_empty():
			frame = mini(int(motion.get_progress() * count), count - 1)
		elif frame > 0:
			frame = (frame - 1) % count
		elif fighter.is_alive():
			frame = int(_time * GUARD_FPS) % count
		sheet = CharacterBaker.get_pose_sheet(look, gear, weapon_pose)
		hand_in_frame = CharacterBaker.get_pose_hand(look.outfit, weapon_pose, frame)
		weapon_angle = CharacterBaker.get_pose_angle(look.outfit, weapon_pose, frame)
	elif MELEE_POSES.has(motion.pose) and CharacterBaker.has_attack(look.outfit):
		# Own attack animation (gear.json "attacks"): its frames over the pose, the weapon in the moving hand.
		var count: int = CharacterBaker.get_attack_frame_count(look.outfit)
		frame = mini(int(motion.get_progress() * count), count - 1)
		sheet = CharacterBaker.get_attack_sheet(look, gear)
		hand_in_frame = CharacterBaker.get_attack_hand(look.outfit, frame)
	elif CharacterBaker.has_pose(look.outfit, BODY_POSES.get(motion.pose, "")):
		var pose: String = BODY_POSES[motion.pose]
		var count: int = CharacterBaker.get_pose_frame_count(look.outfit, pose)
		frame = mini(int(motion.get_progress() * count), count - 1)
		sheet = CharacterBaker.get_pose_sheet(look, gear, pose)
		hand_in_frame = CharacterBaker.get_pose_hand(look.outfit, pose, frame)
	elif frame == 0 and fighter.is_alive() and CharacterBaker.has_pose(look.outfit, GUARD_POSE):
		frame = int(_time * GUARD_FPS) % CharacterBaker.get_pose_frame_count(look.outfit, GUARD_POSE)
		sheet = CharacterBaker.get_pose_sheet(look, gear, GUARD_POSE)
		hand_in_frame = CharacterBaker.get_pose_hand(look.outfit, GUARD_POSE, frame)
	else:
		hand_in_frame = CharacterBaker.get_weapon_hand(look.outfit, frame)
	var region := Rect2(frame * HERO_FRAME.x, 0, HERO_FRAME.x, HERO_FRAME.y)
	# Mirrored around the fighter's x: everything is drawn as if he looked right.
	var base := Transform2D(0.0, shake)
	if facing < 0.0:
		base = Transform2D(Vector2(-1, 0), Vector2(0, 1), Vector2(roundf(x) * 2.0, 0.0) + shake)
	draw_set_transform_matrix(base)
	draw_texture_rect_region(sheet, Rect2(at, HERO_FRAME), region, tint)
	var weapon: Dictionary = CharacterBaker.get_weapon_overlay(gear.get("weapon", {}))
	if not weapon.is_empty():
		var hand: Vector2 = at + hand_in_frame + Vector2(0.5, 0.5)
		var rest: float = WEAPON_REST.get(gear["weapon"].get("type", ""), WEAPON_REST_DEFAULT)
		var angle: float = motion.get_weapon_angle(rest) if is_nan(weapon_angle) else weapon_angle
		var drawn: bool = weapon_pose.ends_with("_shoot") and motion.get_progress() < FighterMotion.IMPACT["shoot"]
		draw_set_transform_matrix(base * Transform2D(0.0 if drawn else deg_to_rad(angle), hand))
		if drawn:
			_draw_drawn_bow(weapon["texture"], weapon["anchor"], motion.get_progress(), tint)
		else:
			draw_texture(weapon["texture"], -weapon["anchor"] - Vector2(0.5, 0.5), tint)
		# The fist over the grip, so the hand closes around the weapon.
		draw_set_transform_matrix(base)
		var fist := Rect2(hand_in_frame - HERO_FIST / 2.0, HERO_FIST)
		draw_texture_rect_region(sheet, Rect2(at + fist.position, fist.size), Rect2(region.position + fist.position, fist.size), tint)
	draw_set_transform(shake)
	_draw_health_bar(fighter, Vector2(x, ground - HERO_BAR_HEIGHT), COLOR_HERO_HEALTH if facing > 0.0 else COLOR_MONSTER_HEALTH)
	_draw_mana_bar(fighter, Vector2(x, ground - HERO_BAR_HEIGHT))


## The hero as his class's PixelLab battle figure (BattleFigure) in his lead metal, the shield and
## the weapon on top in their own metals. false = he has none for this weapon (old figure).
func _draw_battle_figure(fighter: Combatant, x: float, ground: float, shake: Vector2, facing: float) -> bool:
	if fighter.hero == null:
		return false
	var gear: Dictionary = fighter.hero.get_battle_gear()
	var weapon_class: String = WEAPON_CLASS.get(gear.get("weapon", {}).get("type", ""), "")
	if gear.has("weapon") and weapon_class.is_empty():
		return false
	var class_id: String = BattleFigure.get_class_for(fighter.hero, weapon_class)
	if class_id.is_empty():
		return false
	var figure: Dictionary = BattleFigure.get_figure(class_id)
	var motion: FighterMotion = _get_motion(fighter)
	var walking: bool = _adventure.is_walking() and fighter.is_alive()
	var pose: String = "walk" if walking else "stand"
	if not motion.pose.is_empty():
		var attacks: Dictionary = WEAPON_CLASS_ATTACK.get(figure.get("weapon_class", "one"), {})
		pose = attacks.get("*", attacks.get(motion.pose, "swing"))
	var count: int = maxi(BattleFigure.get_frame_count(class_id, pose), 1)
	var frame: int = 0
	if not motion.pose.is_empty():
		frame = mini(int(motion.get_progress() * count), count - 1)
	elif walking:
		frame = int(_time * WALK_FPS) % count
	elif fighter.is_alive():
		frame = int(_time * GUARD_FPS) % count
	var sheet: Texture2D = BattleFigure.get_sheet(class_id, BattleFigure.get_tier(class_id, fighter.hero), pose)
	if sheet == null:
		return false
	var cell: float = float(figure.get("frame", 64))
	# Feet where the old figure has them (FIGURE_FEET above the ground line).
	var at: Vector2 = Vector2(roundf(x - cell / 2.0), roundf(ground - FIGURE_FEET - float(figure.get("feet", 61)))) + motion.get_offset()
	var tint: Color = _apply_state_tint(fighter, Color.WHITE)
	var hands: Dictionary = BattleFigure.get_hands(class_id, pose, frame)
	var region := Rect2(frame * cell, 0, cell, cell)
	var base := Transform2D(0.0, shake)
	if facing < 0.0:
		base = Transform2D(Vector2(-1, 0), Vector2(0, 1), Vector2(roundf(x) * 2.0, 0.0) + shake)
	draw_set_transform_matrix(base)
	draw_texture_rect_region(sheet, Rect2(at, Vector2(cell, cell)), region, tint)
	if gear.has("shield"):
		var shield: Dictionary = BattleFigure.get_held("shield", gear["shield"].get("head", ""))
		if not shield.is_empty():
			draw_texture(shield["texture"], at + hands["shield"] + FIGURE_SHIELD_OFFSET - shield["anchor"], tint)
	if gear.has("weapon"):
		var weapon: Dictionary = BattleFigure.get_held(gear["weapon"].get("type", ""), gear["weapon"].get("head", ""))
		if not weapon.is_empty():
			var hand: Vector2 = at + hands["weapon"] + Vector2(0.5, 0.5)
			draw_set_transform_matrix(base * Transform2D(deg_to_rad(hands["angle"]), hand))
			draw_texture(weapon["texture"], -weapon["anchor"] - Vector2(0.5, 0.5), tint)
			# The fist over the grip, so the hand closes around the weapon.
			draw_set_transform_matrix(base)
			var fist := Rect2(hands["weapon"] - HERO_FIST / 2.0, HERO_FIST)
			draw_texture_rect_region(sheet, Rect2(at + fist.position, fist.size), Rect2(region.position + fist.position, fist.size), tint)
	draw_set_transform(shake)
	return true


## The bow with its string pulled back and the arrow on it. The string is the left column of the
## picture: that column is left out and the string drawn from the tips to the arrow's end instead.
func _draw_drawn_bow(texture: Texture2D, anchor: Vector2, progress: float, tint: Color) -> void:
	var bow_size: Vector2 = texture.get_size()
	var corner: Vector2 = -anchor - Vector2(0.5, 0.5)
	draw_texture_rect_region(texture, Rect2(corner + Vector2(1, 0), bow_size - Vector2(1, 0)),
			Rect2(Vector2(1, 0), bow_size - Vector2(1, 0)), tint)
	var pull: float = roundf(BOW_PULL * minf(progress / BOW_PULL_TIME, 1.0))
	var nock: Vector2 = corner + Vector2(0.5 - pull, roundf(bow_size.y / 2.0))
	draw_line(corner + Vector2(0.5, 0.5), nock, Color(COLOR_BOW_STRING, tint.a), 1.0)
	draw_line(corner + Vector2(0.5, bow_size.y - 0.5), nock, Color(COLOR_BOW_STRING, tint.a), 1.0)
	var tip: Vector2 = corner + Vector2(bow_size.x + ARROW_REACH, nock.y - corner.y)
	draw_line(nock, tip, Color(BattleVfx.COLOR_SHAFT, tint.a), 1.0)
	draw_rect(Rect2(tip - Vector2(0, 1), Vector2(2, 2)), Color(COLOR_ARROW_TIP, tint.a))


## The body animation made for the held weapon's class right now, "" = none (no weapon, own figure).
func _get_weapon_pose(outfit: String, gear: Dictionary, motion: FighterMotion) -> String:
	var weapon_class: String = WEAPON_CLASS.get(gear.get("weapon", {}).get("type", ""), "")
	if weapon_class.is_empty() or not CharacterBaker.has_pose(outfit, weapon_class + "_stand"):
		return ""
	if not motion.pose.is_empty():
		var attacks: Dictionary = WEAPON_CLASS_ATTACK[weapon_class]
		return weapon_class + "_" + attacks.get("*", attacks.get(motion.pose, "swing"))
	return weapon_class + ("_walk" if _adventure.is_walking() else "_stand")


func _draw_monster(fighter: Combatant, x: float, ground: float, shake: Vector2 = Vector2.ZERO) -> void:
	var texture: Texture2D = fighter.icon
	var data: EnemyData = fighter.enemy_data
	# Shared body (the hydra's heads): drawn while any of them lives, by the first of them.
	var members: Array[Combatant] = _get_body_members(fighter)
	var face: Combatant = _get_body_face(fighter)
	var alive: bool = face.is_alive()
	if data and data.frame_count > 1 and alive:
		texture = data.get_frame(int(_time * data.frames_per_second))
	if data and _adventure.is_walking() and alive:
		var walk_frame: Texture2D = data.get_walk_frame(_time)
		if walk_frame:
			texture = walk_frame
	var playing: Array = _monster_animations.get(fighter, [])
	if not playing.is_empty():
		var frame: Texture2D = data.get_animation_frame(playing[0], _time - playing[1])
		if frame:
			texture = frame
		else:
			_monster_animations.erase(fighter)
	if texture == null:
		return
	var motion: FighterMotion = _get_body_motion(fighter)
	var squash: Vector2 = motion.get_squash()
	var fade: float = 1.0
	if _died_at.has(fighter):
		# Sinks together (flatter, a bit wider) and fades out.
		var dead_for: float = clampf((_time - _died_at[fighter]) / DEATH_TIME, 0.0, 1.0)
		if dead_for >= 1.0:
			return
		squash = Vector2(1.0 + 0.25 * dead_for, 1.0 - 0.6 * dead_for)
		fade = (1.0 - dead_for) / 0.3
	var sprite_size: Vector2 = _get_sprite_size(fighter)
	# Animations with bigger pictures (EnemyData "frame_size" of an animation, e.g. fire breath) are
	# drawn at the same pixel scale; they are padded evenly, so the middle and the feet stay put.
	if fighter.icon and texture.get_size() != fighter.icon.get_size():
		sprite_size *= texture.get_size() / fighter.icon.get_size()
	sprite_size = (sprite_size * squash).round()
	# Monsters look left: forward is to the left.
	var offset: Vector2 = motion.get_offset() * Vector2(-1.0, 1.0) + _get_idle_offset(face)
	var at: Vector2 = Vector2(roundf(x - sprite_size.x / 2.0), roundf(ground - sprite_size.y)) + offset
	# Pictures that look right (enemies.json "faces_right") are mirrored around the middle of their rect.
	var mirrored: bool = data != null and data.faces_right
	if mirrored:
		draw_set_transform(shake + Vector2(2.0 * at.x + sprite_size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	if members.has(_adventure.focus) and _adventure.focus.is_alive():
		_draw_focus_outline(texture, Rect2(at, sprite_size))
	var tint: Color = _apply_state_tint(face, data.tint if data else Color.WHITE)
	tint.a = minf(tint.a * fade, 1.0)
	draw_texture_rect(texture, Rect2(at, sprite_size), false, tint)
	if mirrored:
		draw_set_transform(shake)
	if members.size() > 1:
		if alive:
			_draw_body_bars(members, _get_bar_center(face, x, ground))
	elif fighter.is_alive():
		_draw_boss_bars(fighter, _get_bar_center(fighter, x, ground))


## Where the (lowest) health bar of a monster standing at `x` sits. Big bosses fill the stage: the bar
## stays inside it.
func _get_bar_center(fighter: Combatant, x: float, ground: float) -> Vector2:
	var center := Vector2(x, maxf(ground - _get_sprite_size(fighter).y - 5.0 + _get_idle_offset(fighter).y, 4.0))
	var members: Array[Combatant] = _get_body_members(fighter)
	if members.size() > 1:
		center.y = maxf(center.y, 4.0 + (members.size() - 1) * BODY_BAR_STEP)
	return center


## Middle of the bar of the `index`th monster of a shared body: the first on top.
func _get_body_bar_center(members: Array[Combatant], index: int, lowest_center: Vector2) -> Vector2:
	return lowest_center - Vector2(0.0, (members.size() - 1 - index) * BODY_BAR_STEP)


## Monsters sharing one body (the hydra's heads): one health bar each, stacked above the picture, its
## label (EnemyData.body_label) on the left. A fallen one has an empty bar and the seconds until it
## grows back on the right; the focused one gets a red frame.
func _draw_body_bars(members: Array[Combatant], lowest_center: Vector2) -> void:
	var font: Font = get_theme_default_font()
	var outline := Color(0.13, 0.075, 0.12)
	var baseline_offset: float = roundf(font.get_ascent(FONT_SIZE) / 2.0) - 1.0
	for i in members.size():
		var member: Combatant = members[i]
		var center: Vector2 = _get_body_bar_center(members, i, lowest_center)
		var rect := Rect2((center - BAR_SIZE / 2.0).round(), BAR_SIZE)
		if member == _adventure.focus and member.is_alive():
			draw_rect(rect.grow(2), COLOR_FOCUS)
		if member.is_alive():
			_draw_health_bar(member, center, COLOR_MONSTER_HEALTH)
		else:
			draw_rect(rect.grow(1), COLOR_BAR_BACK)
			if member.regrowing:
				var seconds: String = "%d s" % ceili(member.regrow_left)
				var at := Vector2(rect.end.x + 3.0, center.y + baseline_offset).round()
				draw_string_outline(font, at, seconds, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, outline)
				draw_string(font, at, seconds, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_CRIT)
		var label: String = Language.translate(member.enemy_data.body_label) if member.enemy_data else ""
		if not label.is_empty():
			var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
			var label_at := Vector2(rect.position.x - width - 3.0, center.y + baseline_offset).round()
			var color: Color = Color.WHITE if member.is_alive() else Color(1.0, 1.0, 1.0, 0.5)
			draw_string_outline(font, label_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, outline)
			draw_string(font, label_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


## A hydra head that grows back (Combatant.regrowing): the seconds left where it fell.
func _draw_regrow_timer(fighter: Combatant, x: float, ground: float) -> void:
	if not fighter.regrowing or fighter.is_alive():
		return
	var font: Font = get_theme_default_font()
	var text: String = "%d s" % ceili(fighter.regrow_left)
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var at := Vector2(roundf(x - width / 2.0), roundf(maxf(ground - _get_sprite_size(fighter).y * 0.5, 12.0)))
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, Color(0.13, 0.075, 0.12))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_CRIT)


## Breathing (1 px every other half breath) or, for flying monsters, floating and bobbing; each
## monster has its own rhythm. Dead monsters lie still.
func _get_idle_offset(fighter: Combatant) -> Vector2:
	var data: EnemyData = fighter.enemy_data
	if data == null or not fighter.is_alive():
		return Vector2.ZERO
	var phase: float = float(fighter.get_instance_id() % 97) / 97.0 * TAU
	var wave: float = sin(_time * TAU / BREATH_TIME + phase)
	if data.hover:
		return Vector2(0.0, roundf(-HOVER_HEIGHT - HOVER_BOB * wave))
	return Vector2(0.0, -1.0 if wave > 0.0 else 0.0)


## A soft dark ellipse on the ground under a fighter (smaller under flying monsters).
func _draw_shadow(fighter: Combatant) -> void:
	if _get_body(fighter) != fighter or not _is_body_alive(fighter):
		return
	var width: float = 22.0
	if not fighter.hero:
		width = clampf(_get_sprite_size(fighter).x * 0.6, 12.0, 90.0)
		if fighter.enemy_data and fighter.enemy_data.hover:
			width *= 0.6
	var feet: Vector2 = _get_feet(fighter) + Vector2(_get_motion(fighter).get_offset().x * _get_facing(fighter), 0.0)
	var points := PackedVector2Array()
	for i in 16:
		var angle: float = i * TAU / 16.0
		points.append(feet + Vector2(cos(angle) * width / 2.0, sin(angle) * SHADOW_HEIGHT / 2.0 - 1.0))
	draw_colored_polygon(points, COLOR_SHADOW)


## Health bars of a monster; a boss with phases (EnemyData.phases) has one bar per phase, stacked
## above its head: the top bar runs out first, then the next one below. Bars it has lost stay empty,
## the bars still to come are full. The lowest bar sits where a normal monster has its bar.
func _draw_boss_bars(fighter: Combatant, lowest_center: Vector2) -> void:
	var count: int = fighter.get_phase_count()
	if count <= 1:
		_draw_health_bar(fighter, lowest_center, COLOR_MONSTER_HEALTH)
		return
	for i in count:
		var center: Vector2 = lowest_center - Vector2(0.0, (count - 1 - i) * PHASE_BAR_STEP)
		if i == fighter.phase:
			_draw_health_bar(fighter, center, COLOR_MONSTER_HEALTH)
			continue
		var rect := Rect2((center - BAR_SIZE / 2.0).round(), BAR_SIZE)
		draw_rect(rect.grow(1), COLOR_BAR_BACK)
		if i > fighter.phase:
			draw_rect(rect, COLOR_MONSTER_HEALTH)


## A summon: the first frame of its monster, mirrored (monsters look left), in its colour and size.
## `facing` -1 = a summon of the opponent in an arena duel (looks left like the monsters).
func _draw_summon(fighter: Combatant, x: float, ground: float, shake: Vector2, facing: float = 1.0) -> void:
	var data: SummonData = fighter.summon_data
	var texture: Texture2D = fighter.icon
	if texture == null or data == null:
		return
	# The animations of its monster: walking with the party, its attacks and hits.
	var look: EnemyData = data.look
	if look and fighter.is_alive():
		if look.frame_count > 1:
			texture = look.get_frame(int(_time * look.frames_per_second))
		if _adventure.is_walking():
			var walk_frame: Texture2D = look.get_walk_frame(_time)
			if walk_frame:
				texture = walk_frame
	var playing: Array = _monster_animations.get(fighter, [])
	if look and not playing.is_empty():
		var frame: Texture2D = look.get_animation_frame(playing[0], _time - playing[1])
		if frame:
			texture = frame
		else:
			_monster_animations.erase(fighter)
	var sprite_size: Vector2 = _get_sprite_size(fighter)
	var at: Vector2 = Vector2(roundf(x - sprite_size.x / 2.0), roundf(ground - sprite_size.y)) + _get_motion(fighter).get_offset()
	# Mirrored around the middle of its rect (a negative width would draw it one width further right);
	# a monster whose pictures already look right (EnemyData.faces_right) is drawn as it is.
	var looks_right: bool = look != null and look.faces_right
	if looks_right != (facing > 0.0):
		draw_set_transform(shake + Vector2(2.0 * at.x + sprite_size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect(texture, Rect2(at, sprite_size), false, _apply_state_tint(fighter, data.tint))
	draw_set_transform(shake)
	if fighter.is_alive():
		_draw_health_bar(fighter, Vector2(x, ground - sprite_size.y - 5.0), COLOR_HERO_HEALTH)


## Lasting states: a pulsing bubble around a shielded fighter, stars circling a stunned one.
func _draw_states(fighter: Combatant) -> void:
	if not fighter.is_alive():
		return
	var center: Vector2 = _get_center(fighter)
	var radius: float = 16.0 if fighter.hero else maxf(_get_sprite_size(fighter).y / 2.0 + 2.0, 8.0)
	if fighter.get_shield() > 0:
		var alpha: float = 0.35 + 0.15 * sin(_time * 5.0)
		if not BattleVfx.draw_loop(self, "shield", center, _time, Color(COLOR_SHIELD, alpha + 0.3)):
			draw_arc(center, radius, 0.0, TAU, 24, Color(COLOR_SHIELD, alpha), 1.0)
	if fighter.is_stunned():
		var top: Vector2 = center - Vector2(0.0, radius + 2.0)
		if BattleVfx.draw_loop(self, "stun", top, _time, COLOR_STUN):
			return
		for i in 3:
			var angle: float = _time * 6.0 + i * TAU / 3.0
			var star: Vector2 = (top + Vector2(cos(angle) * 6.0, sin(angle) * 2.0)).round()
			draw_rect(Rect2(star, Vector2(1, 1)), COLOR_STUN)


## The looping auras of the fighter's status effects at its feet (status_effects.json "aura"): the
## newest buff and the newest debuff that have one, behind the body or over it (from the sheet).
func _draw_auras(fighter: Combatant, behind: bool) -> void:
	if not fighter.is_alive():
		return
	var shown: Dictionary = {}
	for active in fighter.effects:
		if not active.data.aura.is_empty():
			shown[active.data.kind] = active.data
	for effect: StatusEffectData in shown.values():
		var kind: String = "aura_" + effect.aura
		if (BattleVfx.get_depth(kind) == "behind") == behind:
			BattleVfx.draw_loop(self, kind, _get_feet(fighter), _time, _get_effect_color(effect))


func _apply_state_tint(fighter: Combatant, tint: Color) -> Color:
	if not fighter.is_alive():
		return Color(tint, 0.3)
	if fighter.effects.any(func(active) -> bool: return active.data.untargetable):
		tint = Color(tint, tint.a * HIDDEN_ALPHA)
	match _get_motion(fighter).get_hit_state():
		1:
			return tint * COLOR_FLASH
		2:
			return tint * COLOR_HIT
	return tint


## Health bar centred at `center`. A shield is extra health: a white part right after the health;
## if health + shield is more than the max health, the bar shows health + shield as its whole length.
func _draw_health_bar(fighter: Combatant, center: Vector2, color: Color) -> void:
	var rect := Rect2((center - BAR_SIZE / 2.0).round(), BAR_SIZE)
	draw_rect(rect.grow(1), COLOR_BAR_BACK)
	var shield: int = fighter.get_shield()
	var total: float = maxf(fighter.max_health, fighter.health + shield)
	var health_width: float = roundf(rect.size.x * fighter.health / total)
	draw_rect(Rect2(rect.position, Vector2(health_width, rect.size.y)), color)
	if shield > 0:
		var shield_width: float = maxf(1.0, roundf(rect.size.x * shield / total))
		draw_rect(Rect2(rect.position + Vector2(health_width, 0), Vector2(minf(shield_width, rect.size.x - health_width), rect.size.y)), COLOR_OVERHEAL)


## Blue mana bar right below the health bar centred at `health_center` (nothing without max mana).
func _draw_mana_bar(fighter: Combatant, health_center: Vector2) -> void:
	if fighter.max_mana <= 0:
		return
	var top_left: Vector2 = (health_center - BAR_SIZE / 2.0).round() + Vector2(0, BAR_SIZE.y + 1.0)
	var rect := Rect2(top_left, Vector2(BAR_SIZE.x, MANA_BAR_HEIGHT))
	draw_rect(rect.grow(1), COLOR_BAR_BACK)
	var mana_width: float = roundf(rect.size.x * clampf(fighter.mana / fighter.max_mana, 0.0, 1.0))
	draw_rect(Rect2(rect.position, Vector2(mana_width, rect.size.y)), COLOR_MANA)


## Loot icon; while being picked up it rises and fades out.
func _draw_drop(drop: Dictionary, ground: float) -> void:
	var icon: Texture2D = drop["icon"]
	if icon == null:
		return
	var height: float = drop["height"]
	var color := Color.WHITE
	if drop["pickup"] >= 0.0:
		var progress: float = drop["pickup"] / PICKUP_TIME
		height += progress * 12.0
		color.a = 1.0 - progress
	var at := Vector2(roundf(drop["x"] - icon.get_width() / 2.0), roundf(ground - icon.get_height() - height))
	draw_texture(icon, at, color)


func _draw_float(entry: Dictionary, ground: float) -> void:
	var fighter: Combatant = entry["fighter"]
	var x: float = _fighter_x(fighter)
	var progress: float = entry["age"] / FLOAT_TIME
	var font: Font = get_theme_default_font()
	var text: String = entry["text"]
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	# Numbers over heroes start above their (higher) health and mana bars.
	var start: float = HERO_BAR_HEIGHT + 8.0 if _adventure.hero_fighters.has(fighter) else 46.0
	# Bosses with phases: above their stack of health bars.
	if fighter.enemy_data and fighter.get_phase_count() > 1:
		start = maxf(start, _get_sprite_size(fighter).y + 12.0 + (fighter.get_phase_count() - 1) * PHASE_BAR_STEP)
	var members: Array[Combatant] = _get_body_members(fighter)
	if members.size() > 1:
		start = maxf(start, _get_sprite_size(fighter).y + 12.0 + (members.size() - 1) * BODY_BAR_STEP)
	var at := Vector2(roundf(x - width / 2.0), roundf(ground - start - progress * 14.0))
	var color: Color = entry["color"]
	color.a = 1.0 - progress * progress
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, Color(0.13, 0.075, 0.12, color.a))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


# --- Focus ----------------------------------------------------------------------------

## A left click on a living monster focuses it (or takes the focus away again).
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if _adventure == null or click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var enemy: Combatant = _monster_at(click.position)
	if enemy == null:
		return
	accept_event()
	if not _adventure.can_focus():
		GameState.show_message(Language.translate(TEXT_NO_FOCUS) % HeroRole.focus_iq())
		return
	_adventure.set_focus(enemy)


## The living monster whose picture is at `point` (the front one if they overlap), or null.
func _monster_at(point: Vector2) -> Combatant:
	var ground: float = _get_ground()
	var found: Combatant = null
	# A shared body (the hydra): a click on a head's bar (or its label) picks that head.
	for i in _adventure.enemies.size():
		var leader: Combatant = _adventure.enemies[i]
		var members: Array[Combatant] = _get_body_members(leader)
		if members.size() < 2 or members[0] != leader:
			continue
		var lowest: Vector2 = _get_bar_center(_get_body_face(leader), _monster_x(i), ground)
		for j in members.size():
			var center: Vector2 = _get_body_bar_center(members, j, lowest)
			var row := Rect2(center - Vector2(BAR_SIZE.x / 2.0 + 30.0, BODY_BAR_STEP / 2.0), Vector2(BAR_SIZE.x + 34.0, BODY_BAR_STEP))
			if members[j].is_alive() and row.has_point(point):
				return members[j]
	for i in _adventure.enemies.size():
		var enemy: Combatant = _adventure.enemies[i]
		if not enemy.is_alive():
			continue
		var sprite_size: Vector2 = _get_sprite_size(enemy)
		var rect := Rect2(Vector2(_monster_x(i) - sprite_size.x / 2.0, ground - sprite_size.y), sprite_size).grow(2.0)
		if rect.has_point(point) and (found == null or not enemy.back_row):
			found = enemy
	return found


## The red outline: the monster's silhouette drawn around it, pulsing.
func _draw_focus_outline(texture: Texture2D, rect: Rect2) -> void:
	var silhouette: Texture2D = _get_silhouette(texture)
	if silhouette == null:
		return
	var pulse: float = (sin(_time * FOCUS_PULSE_SPEED) + 1.0) / 2.0
	var tint := Color(1.0, 1.0, 1.0, lerpf(FOCUS_ALPHA.x, FOCUS_ALPHA.y, pulse))
	for offset: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_texture_rect(silhouette, Rect2(rect.position + offset * FOCUS_WIDTH, rect.size), false, tint)


## A copy of the picture with every visible pixel in COLOR_FOCUS (cached per picture / frame).
func _get_silhouette(texture: Texture2D) -> Texture2D:
	var key: String = str(texture.get_instance_id())
	var atlas := texture as AtlasTexture
	if atlas and atlas.atlas:
		key = "%d:%s" % [atlas.atlas.get_instance_id(), atlas.region]
	if not _silhouettes.has(key):
		var image: Image = texture.get_image()
		if image == null:
			return null
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				image.set_pixel(x, y, COLOR_FOCUS if image.get_pixel(x, y).a >= 0.5 else Color.TRANSPARENT)
		_silhouettes[key] = ImageTexture.create_from_image(image)
	return _silhouettes[key]
