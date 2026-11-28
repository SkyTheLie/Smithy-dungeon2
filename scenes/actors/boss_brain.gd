class_name BossBrain
extends RefCounted
## What a boss does (Enemy with ai "boss"). Its "attacks" in data/enemies.json come in turn, with
## a pause between them (shorter below half life). Every boss has its own mix:
##   dash      wind-up, then a rush at the player
##   charge    rushes in a straight line until it hits a wall, then stands dazed (double damage)
##   summon    calls helpers ("summon")            rat_wave  a row of helpers along a wall
##   ring      shots all around ("ring")           spray     a fan at the player ("spray")
##   spiral    a turning stream of shots for a while
##   burrow    sinks into the floor, comes up under the player (red mark first), shock ring
##   leap      jumps onto the player's spot, shock ring on landing
##   teleport  vanishes and appears behind the player, then slashes (short dash)
##   phase     turns invisible and cannot be hurt, reappears near the player
##   mirror    a mirror shield: fireballs that hit it fly back at the player
##   web       sticky shots: a hit slows the player
##   axes      thrown axes that fly out and come back
##   boulder   a big slow rock that bursts into shots
##   skulls    shots that follow the player
##   march     a moving wall of shots with one gap
##   aimed_shot  draws its bow: a thin line follows the player (blinking faster just before),
##             then a fast arrow flies where the line points. Stands still and cannot dodge
##             while drawing (the moment to hit it). A player held by a snare gets one at once.
##   snares    throws 3 snares around the player (red marks first, gaps between them); stepping
##             in one holds the player (Player.hold), and the boss draws its bow at once
##   volley    3 arrows in a fan (5 when angry)
##   laser     a beam at the player (warning line first; 3 beams when angry)
##   laser_sweep  a beam that starts beside the player and sweeps across (behind the boss is safe)
##   cross     shots in a + pattern, a moment later in an x pattern
##   worm_dive digs under the floor towards the player (dust mound, rumble), a red mark where the
##             player stood, then it jumps out in a high arc onto that spot (shock on landing)
##   acid_spit comes up, sways, then spits "spit" blobs of acid in arcs at the player and around
##             (marks where they land); each leaves an acid puddle ("acid" in floors.json
##             hazard_types) for "acid_life" seconds; flying players are safe
##   sky_meteors flies up out of reach (cannot be hurt, its shadow shows where it is) and drops
##             "meteors" meteors: a red circle first, then the impact (hurts close by, embers lie
##             there a moment); from half life more of them, in the rage in a ring round the player
##   dive      screeches and aims (mark where the player stands), then dives down onto that spot
##             and lies dazed on the floor for a moment (double damage, the moment to hit it)
##   gust      a wing beat (shakes first, wind sound) that pushes the player far away
## Trait "underground": between attacks it stays under the floor (cannot be hurt, a dust mound
## shows where it is), so it can only be hit while it is out (jumping, spitting).
## Traits ("traits"): regen (heals when not hit for a while), lifesteal (heals when it hits you),
## evade (jumps aside when a shot of the player flies at it; not while drawing its bow).
## "keep_distance": metres it keeps away from the player between attacks (circling them, an
## archer); "stationary": true = does not walk at all.
## Phases (enemies.json "boss_phases", for every boss): from half life phase 2 (a new attack
## joins, shorter pauses), from a quarter phase 3 (rage: even shorter pauses, faster shots). Each
## change starts with a pause in which it roars, shakes and changes colour and cannot be hurt.

const PAUSE: float = 2.0
const MARK_TIME: float = 0.9
const STUN_TIME: float = 1.6
## Seconds between the attack cry and the attack.
const CUE_LEAD: float = 0.5
## evade: how far it sees shots coming, how long a jump aside lasts, the pause after it.
const EVADE_REACH: float = 3.5
const EVADE_TIME: float = 0.25
const EVADE_WAIT: float = 1.4
const ARROW_SPEED: float = 3.2
## Thrown snares lie this long; this far around the player.
const SNARE_LIFE: float = 8.0
const SNARE_RING: float = 1.5
const DRAW_TIME: float = 1.0
const DRAW_QUICK: float = 0.55
const RELEASE: float = 0.35

var boss: Enemy

var _attacks: Array = []
var _index: int = 0
var _attack: String = ""
var _left: float = 0.0
var _wait: float = 1.2
var _dir: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _step: float = 0.0
var _turn: float = 0.0
var _done_once: bool = false
## The attack cry for the coming attack was played.
var _cued: bool = false
var _evade_left: float = 0.0
var _evade_wait: float = 0.0
var _evade_dir: Vector3 = Vector3.ZERO
## The next aimed_shot is a quick one (the player is held by a snare).
var _quick: bool = false
var _was_held: bool = false
## The player just got caught: the quick shot is still to come.
var _punish: bool = false
## 1, 2 or 3 (boss_phases); seconds left of the roar between two phases.
var phase: int = 1
var _transition_left: float = 0.0
## worm_dive: where the jump starts; dust mound timer.
var _from: Vector3 = Vector3.ZERO
var _dust_wait: float = 0.0
const DIVE_JUMP: float = 0.6
const DIVE_HEIGHT: float = 2.4
## sky_meteors: how high it flies, rise/sink time, seconds between meteors.
const SKY_HEIGHT: float = 4.5
const SKY_RISE: float = 0.5
const METEOR_GAP: float = 0.35
const METEOR_FALL: float = 1.0
const WIND := {"wave": "noise", "freq": 380, "slide": 0.8, "length": 0.6, "noise": 1.0, "vibrato": 0.2}


func _init(the_boss: Enemy) -> void:
	boss = the_boss
	_attacks = boss.data.get("attacks", ["dash"])


func angry() -> bool:
	return phase >= 2


## enemies.json "boss_phases".
static func phase_rules() -> Dictionary:
	return Content.get_file("enemies").get("boss_phases", {})


## The phase that belongs to the boss's life right now (1–3).
func _phase_for_life() -> int:
	var at: Array = BossBrain.phase_rules().get("at", [0.5, 0.25])
	var share: float = boss.hp / maxf(1.0, boss.max_hp)
	var result: int = 1
	for i in at.size():
		if share < float(at[i]):
			result = i + 2
	return result


## true while it roars between two phases (cannot be hurt then).
func in_transition() -> bool:
	return _transition_left > 0.0


func _pause_factor() -> float:
	var list: Array = BossBrain.phase_rules().get("pause", [1.0, 0.55, 0.55])
	return float(list[clampi(phase - 1, 0, list.size() - 1)])


## Factor on the speed of its shots in this phase.
func shot_factor() -> float:
	var list: Array = BossBrain.phase_rules().get("shot_speed", [1.0])
	return float(list[clampi(phase - 1, 0, list.size() - 1)])


## A new phase: stop the attack, roar, shake, new colour; phase 2/3 may bring a new attack.
func _enter_phase(new_phase: int) -> void:
	if not _attack.is_empty():
		_finish()
	phase = new_phase
	var rules: Dictionary = BossBrain.phase_rules()
	_transition_left = float(rules.get("transition", 1.4))
	var tints: Array = rules.get("tint", [])
	if phase - 1 < tints.size():
		var tint: Array = tints[phase - 1]
		boss.set_phase_tint(Color(float(tint[0]), float(tint[1]), float(tint[2])))
	var own: Array = boss.data.get("phase_attacks", [])
	var extra: String = ""
	if phase - 2 < own.size():
		extra = String(own[phase - 2])
	elif phase == 2:
		for candidate: Variant in rules.get("extra_attacks", []):
			if not _attacks.has(String(candidate)):
				extra = String(candidate)
				break
	if not extra.is_empty():
		_attacks = _attacks.duplicate()
		_attacks.insert(_index % maxi(1, _attacks.size()), extra)
	var music: Array = rules.get("music", [])
	if phase - 1 < music.size():
		AudioManager.set_music_intensity(float(music[phase - 1]))
	boss.hidden_phase = false
	boss.roar(_transition_left)


## Movement of this frame.
func update(delta: float, toward: Vector3, distance: float) -> Vector3:
	if _transition_left > 0.0:
		_transition_left -= delta
		if _transition_left <= 0.0:
			_wait = minf(_wait, 0.6)
		return Vector3.ZERO
	var due: int = _phase_for_life()
	if due > phase:
		_enter_phase(due)
		return Vector3.ZERO
	_traits(delta)
	_evade_wait = maxf(0.0, _evade_wait - delta)
	if _evade_left > 0.0:
		_evade_left -= delta
		return _evade_dir * boss.speed() * 6.0
	if _try_evade():
		return Vector3.ZERO
	# Caught in a snare: the boss draws its bow at once (quickly).
	var held: bool = boss.player.is_held()
	if held and not _was_held:
		_punish = true
	_was_held = held
	if not held:
		_punish = false
	elif _punish and _attacks.has("aimed_shot") and _attack in ["", "volley", "snares"]:
		_punish = false
		_attack = "aimed_shot"
		_quick = true
		_cued = false
		_start(toward)
	if _attack.is_empty():
		_underground(delta)
		_wait -= delta
		# The attack cry (data "cries" "attack") comes a moment before the attack.
		if not _cued and _wait <= CUE_LEAD:
			_cued = true
			boss.cry("attack")
		if _wait <= 0.0:
			_cued = false
			_attack = String(_attacks[_index % _attacks.size()])
			_index += 1
			_start(toward)
		return _walk_between(toward, distance)
	_left -= delta
	var move: Vector3 = _run(delta, toward, distance)
	if _left <= 0.0:
		_finish()
	return move


## Between attacks: walk at the player, a bit sideways so it is not a straight line; an archer
## ("keep_distance") circles the player at that distance; "stationary" stays where it is.
func _walk_between(toward: Vector3, distance: float) -> Vector3:
	if boss.pinned or bool(boss.data.get("stationary", false)):
		return Vector3.ZERO
	var keep: float = float(boss.data.get("keep_distance", 0.0))
	if keep > 0.0:
		var around: Vector3 = toward.cross(Vector3.UP) * (1.0 if sin(boss.age() * 0.5) > 0.0 else -1.0)
		var closer: Vector3 = toward * clampf((distance - keep) / 2.0, -1.0, 1.0)
		return (around * 0.8 + closer).normalized() * boss.speed()
	var side: Vector3 = toward.cross(Vector3.UP) * sin(boss.age() * 1.3) * 0.5
	return (toward + side).normalized() * boss.speed()


## Trait "evade": a shot of the player flies at it -> a quick jump aside (not while drawing the
## bow, and only every EVADE_WAIT seconds). true if it jumps now.
func _try_evade() -> bool:
	if not (boss.data.get("traits", []) as Array).has("evade") or _evade_wait > 0.0 or _attack == "aimed_shot":
		return false
	var shot: Node3D = boss.incoming_shot(EVADE_REACH)
	if shot == null:
		return false
	var flight: Vector3 = ((boss.global_position - shot.global_position) * Vector3(1, 0, 1)).normalized()
	_evade_dir = flight.cross(Vector3.UP).normalized()
	# The side with more room.
	var rect: Rect2 = boss.room_rect(1.0)
	var ahead: Vector3 = boss.global_position + _evade_dir * 1.5
	if not rect.has_point(Vector2(ahead.x, ahead.z)):
		_evade_dir = -_evade_dir
	_evade_left = EVADE_TIME
	_evade_wait = EVADE_WAIT * (0.7 if angry() else 1.0)
	boss.sound("dash")
	return true


## sky_meteors: up, meteors one after another (in the rage in a ring round the player), down.
func _sky_meteors(delta: float) -> Vector3:
	var meteors: int = int(boss.data.get("meteors", 4)) + (2 if angry() else 0)
	var total: float = SKY_RISE * 2.0 + meteors * METEOR_GAP + METEOR_FALL
	var spent: float = total - _left
	var height_now: float = SKY_HEIGHT
	if spent < SKY_RISE:
		height_now = SKY_HEIGHT * spent / SKY_RISE
	elif _left < SKY_RISE:
		height_now = SKY_HEIGHT * _left / SKY_RISE
	boss.set_jump(height_now)
	# Its shadow follows it on the floor.
	_dust_wait -= delta
	if _dust_wait <= 0.0:
		_dust_wait = 0.25
		boss.mark(boss.global_position, 0.9, 0.25)
	if spent >= SKY_RISE and int(_turn) < meteors and spent >= SKY_RISE + _turn * METEOR_GAP:
		var spot: Vector3 = boss.player.global_position
		if phase >= 3:
			spot += Vector3.FORWARD.rotated(Vector3.UP, TAU * _turn / meteors) * 2.0
		elif _turn > 0.0:
			spot += Vector3.FORWARD.rotated(Vector3.UP, boss.rng.randf() * TAU) * boss.rng.randf_range(0.5, 2.5)
		boss.drop_meteor(spot, METEOR_FALL)
		_turn += 1.0
	if _left < SKY_RISE * 0.5:
		boss.hidden_phase = false
	# Hovers after the player, high above.
	var toward: Vector3 = (boss.player.global_position - boss.global_position) * Vector3(1, 0, 1)
	return toward.normalized() * boss.speed() * 0.6 if toward.length() > 1.0 else Vector3.ZERO


## worm_dive: under the floor towards the player, the mark, a short rumble, then the jump.
func _worm_dive(delta: float, toward: Vector3) -> Vector3:
	if _left > DIVE_JUMP + MARK_TIME:
		_dust(delta)
		return toward * boss.speed() * 1.6
	if not _done_once:
		_done_once = true
		_target = boss.player.global_position
		_from = boss.global_position
		boss.mark(_target, 1.7, MARK_TIME)
		boss.cry("attack")
		boss.sound("boss_burrow", 0.8)
		return Vector3.ZERO
	if _left > DIVE_JUMP:
		_dust(delta)
		return Vector3.ZERO
	# In the air: visible and hittable, a high arc onto the marked spot.
	var t: float = clampf(1.0 - _left / DIVE_JUMP, 0.0, 1.0)
	if boss.hidden_phase:
		boss.hidden_phase = false
		Fx.puff(boss.dungeon.effects, _from + Vector3(0, 0.3, 0), "dust", 1.8)
		boss.sound("boss_burrow", 1.4)
	boss.move_to(_from.lerp(_target, t))
	boss.set_jump(sin(PI * t) * DIVE_HEIGHT)
	if t >= 0.97 and _step == 0.0:
		_step = 1.0
		boss.set_jump(0.0)
		boss.shake(0.5)
		Fx.puff(boss.dungeon.effects, _target + Vector3(0, 0.3, 0), "dust", 2.2)
		boss.hurt_player_near(1.6)
	return Vector3.ZERO


## Trait "underground": hidden under the floor between attacks, a dust mound shows where.
func _underground(delta: float) -> void:
	if not (boss.data.get("traits", []) as Array).has("underground"):
		return
	boss.hidden_phase = true
	_dust(delta)


func _dust(delta: float) -> void:
	_dust_wait -= delta
	if _dust_wait <= 0.0:
		_dust_wait = 0.18
		Fx.puff(boss.dungeon.effects, boss.global_position + Vector3(boss.rng.randf_range(-0.4, 0.4), 0.15, boss.rng.randf_range(-0.4, 0.4)), "dust", 0.7)


func _finish() -> void:
	boss.end_attack()
	boss.hidden_phase = false
	boss.set_jump(0.0)
	boss.reflecting = false
	boss.stun_left = 0.0 if _attack != "charge" else boss.stun_left
	_quick = false
	_attack = ""
	_wait = PAUSE * _pause_factor()


func _start(toward: Vector3) -> void:
	boss.show_attack(_attack)
	_dir = toward
	_step = 0.0
	_done_once = false
	match _attack:
		"dash":
			_left = 1.2
		"charge":
			_left = 3.0
		"summon":
			_left = 0.6
			for i in (3 if angry() else 2):
				boss.summon_near(Vector3(boss.rng.randf_range(-1.5, 1.5), 0, boss.rng.randf_range(-1.5, 1.5)))
		"rat_wave":
			_left = 0.8
			var rect: Rect2 = boss.room_rect(1.0)
			var far_side: float = rect.position.y if boss.player.global_position.z > boss.global_position.z else rect.end.y
			for i in (7 if angry() else 5):
				var x: float = lerpf(rect.position.x, rect.end.x, (i + 0.5) / (7.0 if angry() else 5.0))
				boss.summon_at(Vector3(x, 0, far_side))
		"ring":
			_left = 0.5
			_ring(int(boss.data.get("ring", 8)) + (4 if angry() else 0), 0.0, 1.0)
		"spray":
			_left = 0.5
			boss.shoot_spray(int(boss.data.get("spray", 3)) + (2 if angry() else 0), 12.0, {})
		"spiral":
			_left = 2.2
		"burrow":
			_left = 2.4
			boss.hidden_phase = true
			boss.sound("boss_burrow")
		"leap":
			_left = 1.3
			_target = boss.player.global_position
			boss.mark(_target, 1.6, 1.0)
		"sky_meteors":
			var meteors: int = int(boss.data.get("meteors", 4)) + (2 if angry() else 0)
			_left = SKY_RISE * 2.0 + meteors * METEOR_GAP + METEOR_FALL
			_turn = 0.0
			boss.hidden_phase = true
			boss.cry("attack")
			boss.sound("boss_teleport", 0.7)
		"dive":
			_left = 0.8 + 0.45 + 1.4
			_target = boss.player.global_position
			boss.mark(_target, 1.3, 0.8)
			boss.cry("attack")
			boss.wobble(0.8)
		"gust":
			_left = 1.1
			boss.wobble(0.55)
			AudioManager.play_stream_at(SoundSynth.make(WIND, "cry"), boss.global_position, boss.dungeon.effects, 0.8, -2.0)
		"worm_dive":
			_left = 2.6
			boss.hidden_phase = true
			boss.sound("boss_burrow")
		"acid_spit":
			_left = 2.0
			if boss.hidden_phase:
				Fx.puff(boss.dungeon.effects, boss.global_position + Vector3(0, 0.4, 0), "dust", 1.6)
			boss.hidden_phase = false
			boss.wobble(0.6)
			boss.sound("boss_burrow", 1.3)
		"teleport":
			_left = 1.4
			boss.hidden_phase = true
			boss.sound("boss_teleport")
		"phase":
			_left = 1.8
			boss.hidden_phase = true
			boss.sound("boss_teleport")
		"mirror":
			_left = 2.8 if angry() else 2.2
			boss.reflecting = true
			boss.sound("boss_mirror")
		"web":
			_left = 0.6
			boss.shoot_spray(5, 14.0, {"slows": true, "speed": 0.8})
		"axes":
			_left = 1.6
			for angle: float in ([-25.0, 0.0, 25.0] if not angry() else [-40.0, -20.0, 0.0, 20.0, 40.0]):
				boss.shoot(_dir.rotated(Vector3.UP, deg_to_rad(angle)), {"returns": true, "speed": 1.3})
		"boulder":
			_left = 0.8
			boss.shoot(_dir, {"burst": 8 if angry() else 6, "speed": 0.6, "size": 2.2, "life": 1.4})
		"skulls":
			_left = 0.8
			for i in (5 if angry() else 3):
				boss.shoot(_dir.rotated(Vector3.UP, deg_to_rad(-40.0 + 40.0 * i)), {"homing": 1.6, "speed": 0.7, "life": 4.0})
		"march":
			_left = 0.6
			_march()
		"aimed_shot":
			var draw: float = DRAW_QUICK if _quick else DRAW_TIME * (0.75 if angry() else 1.0)
			_left = draw + RELEASE
			boss.wobble(draw)
			boss.sound("swing")
			# The aim line follows the player while the bow is drawn.
			boss.fire_beam(toward, {"aim": draw, "fire": 0.0, "track": true, "color": Color(1.0, 0.9, 0.4)})
		"snares":
			_left = 1.0
			var turn: float = boss.rng.randf() * TAU
			var middle: Vector3 = boss.player.global_position
			for i in 3:
				boss.throw_snare(middle + Vector3.FORWARD.rotated(Vector3.UP, turn + TAU * i / 3.0) * SNARE_RING, SNARE_LIFE)
		"volley":
			_left = 0.7
			boss.shoot_spray(5 if angry() else 3, 16.0, {"arrow": true, "speed": ARROW_SPEED * 0.75})
		"laser":
			_left = 1.6
			var aim: float = 0.7 if angry() else 0.9
			for angle: float in ([-30.0, 0.0, 30.0] if angry() else [0.0]):
				boss.fire_beam(toward.rotated(Vector3.UP, deg_to_rad(angle)), {"aim": aim, "fire": 0.6, "width": 0.6, "damage": 2})
		"laser_sweep":
			_left = 3.0
			var way: float = 1.0 if boss.rng.randf() < 0.5 else -1.0
			# Starts beside the player and sweeps across them; behind the boss stays safe.
			boss.fire_beam(toward.rotated(Vector3.UP, -way * 1.2), {"aim": 0.8, "fire": 2.0, "width": 0.5, "damage": 1, "sweep": way * (1.4 if angry() else 1.1)})
		"cross":
			_left = 1.1
			boss.shoot_pattern("cross", {"speed": 0.9})


func _run(delta: float, toward: Vector3, distance: float) -> Vector3:
	match _attack:
		"worm_dive":
			return _worm_dive(delta, toward)
		"sky_meteors":
			return _sky_meteors(delta)
		"dive":
			if _left > 1.85:
				boss.flash(0.05)
				return Vector3.ZERO
			if _left > 1.4:
				var to_target: Vector3 = (_target - boss.global_position) * Vector3(1, 0, 1)
				if to_target.length() > 0.3:
					return to_target.normalized() * minf(to_target.length() / delta, boss.speed() * 8.0)
				return Vector3.ZERO
			if _step == 0.0:
				_step = 1.0
				boss.shake(0.4)
				boss.hurt_player_near(1.3)
				boss.stun_left = 1.4
				Fx.puff(boss.dungeon.effects, boss.global_position + Vector3(0, 0.3, 0), "dust", 1.8)
			return Vector3.ZERO
		"gust":
			if _left <= 0.55 and not _done_once:
				_done_once = true
				var away: Vector3 = (boss.player.global_position - boss.global_position) * Vector3(1, 0, 1)
				if away.length() < 7.0 and not boss.player.is_held():
					boss.player.knock(away.normalized() * float(boss.data.get("gust", 9.0)))
				for i in 4:
					Fx.puff(boss.dungeon.effects, boss.global_position.lerp(boss.player.global_position, (i + 1) / 5.0) + Vector3(0, 1.0, 0), "ghost_puff", 0.6)
			return Vector3.ZERO
		"acid_spit":
			if _left <= 1.4 and not _done_once:
				_done_once = true
				var count: int = int(boss.data.get("spit", 4)) + (2 if angry() else 0)
				for i in count:
					var spot: Vector3 = boss.player.global_position
					if i > 0:
						spot += Vector3.FORWARD.rotated(Vector3.UP, boss.rng.randf() * TAU) * boss.rng.randf_range(1.2, 2.6)
					boss.lob_acid(spot, 0.8 + 0.08 * i)
			return Vector3.ZERO
		"dash":
			if _left > 0.6:
				boss.flash(0.05)
				_dir = toward
				return Vector3.ZERO
			return _dir * boss.speed() * 4.5
		"charge":
			if _left > 2.3:
				boss.flash(0.05)
				_dir = toward
				return Vector3.ZERO
			if boss.stun_left > 0.0:
				return Vector3.ZERO
			if boss.hit_wall():
				# Ran into the wall: dazed, takes double damage.
				boss.stun_left = STUN_TIME
				_left = STUN_TIME
				boss.shake(0.4)
				_ring(10, 0.0, 0.8)
				return Vector3.ZERO
			return _dir * boss.speed() * 5.0
		"spiral":
			_step -= delta
			if _step <= 0.0:
				_step = 0.12 if angry() else 0.16
				_turn += 0.45
				_ring(3, _turn, 1.0)
			return Vector3.ZERO
		"burrow":
			# Underground, then a red mark under the player, then up it comes.
			if _left > MARK_TIME + 0.3:
				_target = boss.player.global_position
				return Vector3.ZERO
			if not _done_once:
				_done_once = true
				boss.mark(_target, 1.8, MARK_TIME)
				return Vector3.ZERO
			if _left <= 0.3 and boss.hidden_phase:
				boss.hidden_phase = false
				boss.move_to(_target)
				boss.shake(0.5)
				_ring(12, 0.0, 0.9)
				boss.hurt_player_near(1.6)
			return Vector3.ZERO
		"leap":
			if _left > 0.9:
				boss.flash(0.05)
				return Vector3.ZERO
			var to_target: Vector3 = (_target - boss.global_position) * Vector3(1, 0, 1)
			if to_target.length() < 0.4 or _left <= 0.1:
				if not _done_once:
					_done_once = true
					boss.shake(0.5)
					_ring(10, 0.0, 0.9)
					boss.hurt_player_near(1.7)
				return Vector3.ZERO
			return to_target.normalized() * minf(to_target.length() / 0.15, boss.speed() * 6.0)
		"teleport":
			if _left > 0.8:
				return Vector3.ZERO
			if not _done_once:
				_done_once = true
				# Behind the player (where they do not look).
				var behind: Vector3 = boss.player.global_position + boss.player.global_basis.z * 2.0
				boss.move_to(behind)
				boss.hidden_phase = false
				_dir = (boss.player.global_position - behind) * Vector3(1, 0, 1)
				_dir = _dir.normalized()
				boss.flash(0.2)
			if _left > 0.45:
				return Vector3.ZERO
			return _dir * boss.speed() * 5.0
		"phase":
			if _left <= 0.4 and boss.hidden_phase:
				var around: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, boss.rng.randf() * TAU) * 3.5
				boss.move_to(boss.player.global_position + around)
				boss.hidden_phase = false
				boss.shoot_spray(5, 15.0, {})
			return toward * boss.speed() * 0.5 if boss.hidden_phase else Vector3.ZERO
		"mirror":
			return toward * boss.speed() * 0.4
		"axes":
			return -toward * boss.speed() * 0.3
		"aimed_shot":
			if _left <= RELEASE and not _done_once:
				_done_once = true
				var aim: Vector3 = (boss.player.global_position - boss.global_position) * Vector3(1, 0, 1)
				boss.shoot(aim.normalized(), {"arrow": true, "speed": ARROW_SPEED, "damage": 2})
			return Vector3.ZERO
		"cross":
			if _left <= 0.6 and not _done_once:
				_done_once = true
				boss.shoot_pattern("diagonal", {"speed": 0.9})
			return Vector3.ZERO
	return Vector3.ZERO


## `count` shots all around, starting at `turn` radians.
func _ring(count: int, turn: float, speed: float) -> void:
	for i in count:
		boss.shoot(Vector3.FORWARD.rotated(Vector3.UP, turn + TAU * i / count), {"speed": speed})


## A wall of shots across the room towards the player, with one gap to slip through.
func _march() -> void:
	var forward: Vector3 = _dir
	var side: Vector3 = forward.cross(Vector3.UP).normalized()
	var gap: int = boss.rng.randi_range(-3, 3)
	for i in range(-6, 7):
		if absi(i - gap) <= 0:
			continue
		boss.shoot_from(boss.global_position + side * i * 0.9 - forward * 0.5, forward, {"speed": 0.6, "life": 5.0})


func _traits(delta: float) -> void:
	var traits: Array = boss.data.get("traits", [])
	if traits.has("regen") and boss.time_since_hit() > 3.0 and boss.hp < boss.max_hp:
		boss.hp = minf(boss.max_hp, boss.hp + boss.max_hp * 0.015 * delta)
