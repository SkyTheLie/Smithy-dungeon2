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
## Traits ("traits"): regen (heals when not hit for a while), lifesteal (heals when it hits you),
## evade (jumps aside when a shot of the player flies at it; not while drawing its bow).
## "keep_distance": metres it keeps away from the player between attacks (circling them, an
## archer); "stationary": true = does not walk at all.

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


func _init(the_boss: Enemy) -> void:
	boss = the_boss
	_attacks = boss.data.get("attacks", ["dash"])


func angry() -> bool:
	return boss.hp < boss.max_hp * 0.5


## Movement of this frame.
func update(delta: float, toward: Vector3, distance: float) -> Vector3:
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


func _finish() -> void:
	boss.end_attack()
	boss.hidden_phase = false
	boss.reflecting = false
	boss.stun_left = 0.0 if _attack != "charge" else boss.stun_left
	_quick = false
	_attack = ""
	_wait = PAUSE * (0.55 if angry() else 1.0)


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
