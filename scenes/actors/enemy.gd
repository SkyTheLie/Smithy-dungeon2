class_name Enemy
extends CharacterBody3D
## A monster: a flat Smithy battle sprite standing in the 3D room (billboard, always turned to the
## camera, looks left by default and is mirrored when it walks to the right of the screen).
## Values and behaviour come from data/enemies.json ("ai"):
##   lurk     stands still for "wake" seconds (or until hit / the player comes close), then
##            walks slowly towards the player (the rats)
##   chase    runs straight at the player          fly     flutters towards the player, over rocks
##   hop      jumps at the player in bursts         shooter keeps its distance and shoots orbs
##   guard    shield bearers (front_guard): keep their distance and circle, then wind up, ram
##            straight at where the player stood, and stand still afterwards without turning,
##            so the player can get behind them
##   boss     its own attacks (BossBrain)
## "leap": {"every", "range", "height"}: crouches, then jumps high at the player and lands on them.
## "burrow": {"every", "time"}: digs into the floor (cannot be hit), a red mark shows where it
##    will come up (under the player), then it bursts out there.
## "front_guard": true: a shield in front; hits from the front do nothing, only from the side and
##    behind. It turns slowly, so the player can run around it.
## "cries": animal sounds (SoundSynth voices, plus "volume" in dB): idle (now and then, "every"
##    [min, max] seconds), wake (a lurker wakes up), near (the player comes within "range", at
##    most every "cooldown" seconds), attack (just BEFORE an attack: leap crouch, shooter, shield
##    ram, boss attack), so the player hears what is coming. Further away = quieter.
## Touching the player hurts them by "damage" half hearts.
## Hits of the player can add effects (Enemy.afflict, numbers in data/player.json "effects"):
## burn (orange) and poison (green) hurt over time, slow (blue) slows it, freeze (white) stops it,
## fear makes it run away, daze makes it stagger around. With "thorns" touching the player hurts it.

signal died(enemy: Enemy)

const FRAMES: int = 6
const FRAME_SIZE: int = 48
const WALK_FPS: float = 8.0
const DEATH_FPS: float = 10.0
const SEPARATION: float = 0.8
const CONFUSED_TIME: float = 2.5
const FLY_HEIGHT: float = 0.7
const ATTACK_PAUSE: float = 2.4
## Seconds between two burn damage ticks.
const BURN_TICK: float = 0.5
## "guard": seconds of holding back, winding up, ramming, standing still after it.
const GUARD_HOLD: float = 2.2
const GUARD_WINDUP: float = 0.55
const GUARD_RAM: float = 0.75
const GUARD_RECOVER: float = 1.7
const GUARD_DISTANCE: float = 4.0
## Thin ring on the floor around the body (Fx.ring).
const RING_COLOR := Color(1.0, 0.55, 0.1, 0.85)
## Shooters: the attack cry starts this many seconds before the shot.
const ATTACK_CUE_LEAD: float = 0.45
## Idle cries of all enemies together at most this often (a room full of rats is not a choir).
const IDLE_GAP_MS: int = 700
## Cries get quieter by this many dB per metre beyond 2 m.
const CRY_FALLOFF_DB: float = 0.8

## When the last idle cry of any enemy was played.
static var _last_idle_ms: int = -IDLE_GAP_MS

var id: String = ""
var data: Dictionary = {}
var hp: float = 1.0
var max_hp: float = 1.0
var alive: bool = true
var radius: float = 0.4
var height: float = 1.2
var is_boss: bool = false

var dungeon: Dungeon
var player: Player

var _ai: String = "chase"
var _speed: float = 2.0
var _sprite: Sprite3D
## Thin orange ring on the floor: how big the body is (the hit radius).
var _ring: MeshInstance3D
var _walk: Texture2D
var _idle: Texture2D
var _death: Texture2D
var _anim_time: float = 0.0
var _wake_left: float = 0.0
var _awake: bool = true
var _push: Vector3 = Vector3.ZERO
var _flash: float = 0.0
var _confused: float = 0.0
var _timer: float = 0.0
var _hop_phase: bool = false
## Boss: index into "attacks", current attack and its time left.
var _attack_index: int = 0
var _attack: String = ""
var _attack_left: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
var _rng := RandomNumberGenerator.new()
## The boss's random numbers (BossBrain).
var rng: RandomNumberGenerator:
	get:
		return _rng
## Bosses: underground / invisible (cannot be hit), mirror shield up, dazed (double damage).
var hidden_phase: bool = false
var reflecting: bool = false
var stun_left: float = 0.0
var _brain: BossBrain = null
var _last_hit: float = 0.0
## "leap" enemies: time to the next jump, crouch / air time left, landing spot, height now.
var _leap_wait: float = 2.0
var _crouch_left: float = 0.0
var _air_left: float = 0.0
var _air_time: float = 0.6
var _leap_from: Vector3 = Vector3.ZERO
var _leap_to: Vector3 = Vector3.ZERO
var _jump_y: float = 0.0
## "burrow": time to the next dig, time underground left, where it comes up.
var _burrow_wait: float = 3.0
var _under_left: float = 0.0
var _rise_at: Vector3 = Vector3.ZERO
var _marked: bool = false
## Where it looks (front_guard turns slowly towards the player).
var _facing: Vector3 = Vector3.FORWARD
var _facing_set: bool = false
## "guard": 0 hold, 1 wind-up, 2 ram, 3 recover; time left; direction of the ram.
var _guard_step: int = 0
var _guard_left: float = GUARD_HOLD
var _ram_dir: Vector3 = Vector3.ZERO
var _burn_left: float = 0.0
var _burn_per_second: float = 0.0
var _burn_tick: float = 0.0
var _slow_left: float = 0.0
var _poison_left: float = 0.0
## Bleeding: stacks (each hit with "bleed" adds one, up to bleed_max), damage per stack.
var _bleed_left: float = 0.0
var _bleed_stacks: int = 0
var _bleed_per_stack: float = 0.0
var _poison_per_second: float = 0.0
var _freeze_left: float = 0.0
var _daze_left: float = 0.0
var _daze_dir: Vector3 = Vector3.ZERO
var _thorns_wait: float = 0.0
## "cries": time to the next idle cry, to the next near cry; shooter cry already played.
var _idle_wait: float = 0.0
var _near_wait: float = 0.0
var _cued: bool = false


func setup(enemy_id: String, the_dungeon: Dungeon, the_player: Player, rng_seed: int) -> void:
	id = enemy_id
	data = Content.enemy(enemy_id)
	dungeon = the_dungeon
	player = the_player
	_rng.seed = rng_seed
	# Deeper floors of a theme: more life (data/floors.json "hp_mult").
	max_hp = float(data.get("hp", 3)) * float(dungeon.floor_data.get("hp_mult", 1.0))
	hp = max_hp
	radius = float(data.get("radius", 0.4))
	height = float(data.get("height", 1.2))
	_ai = String(data.get("ai", "chase"))
	_speed = float(data.get("speed", 2.0))
	is_boss = _ai == "boss"
	if is_boss:
		_brain = BossBrain.new(self)
	if _ai == "lurk":
		var wake: Array = data.get("wake", [1.0, 3.0])
		_wake_left = _rng.randf_range(float(wake[0]), float(wake[1]))
		_awake = false
	_timer = _rng.randf_range(0.5, float(data.get("fire_interval", ATTACK_PAUSE)))
	# Not all at once when the room starts (own random numbers stay untouched).
	_idle_wait = randf_range(0.8, 4.0)


func _ready() -> void:
	collision_layer = RoomBuilder.LAYER_ENEMIES
	collision_mask = RoomBuilder.LAYER_WORLD if _ai == "fly" else RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius * 0.8
	cylinder.height = 1.0
	shape.shape = cylinder
	shape.position.y = 0.5
	add_child(shape)
	var base: String = String(data.get("sprite", ""))
	_walk = load(base + "_walk.png") as Texture2D
	_idle = load(base + ".png") as Texture2D if ResourceLoader.exists(base + ".png") else _walk
	_death = load(base + "_death.png") as Texture2D if ResourceLoader.exists(base + "_death.png") else null
	_sprite = Fx.billboard(_walk if _awake else _idle, height)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.pixel_size = height / FRAME_SIZE
	_set_sheet(_walk if _awake else _idle)
	_sprite.position.y = height / 2.0 + (FLY_HEIGHT if _ai == "fly" else 0.0)
	add_child(_sprite)
	_ring = Fx.ring(self, radius, RING_COLOR)


## true if a ball at `point` with `ball_radius` touches this enemy.
func hits(point: Vector3, ball_radius: float) -> bool:
	if not alive or hidden_phase:
		return false
	var offset := Vector2(point.x - global_position.x, point.z - global_position.z)
	var bottom: float = global_position.y + _jump_y + (FLY_HEIGHT * 0.6 if _ai == "fly" else 0.0)
	return offset.length() < radius + ball_radius and point.y > bottom - ball_radius and point.y < bottom + height + ball_radius


## Middle of the body (homing shots aim here).
func aim_point() -> Vector3:
	return global_position + Vector3(0, height * 0.5 + (FLY_HEIGHT if _ai == "fly" else 0.0), 0)


## `push` = knockback (bosses barely move). `confuse` (bread): runs away for a while.
func take_damage(amount: float, push: Vector3, confuse: bool) -> void:
	if not alive or amount <= 0.0 or hidden_phase:
		return
	# Shield in front: a hit coming against its face bounces off.
	if bool(data.get("front_guard", false)) and push.length() > 0.01 and Vector3(push.x, 0, push.z).normalized().dot(_facing) < -0.35:
		_flash = 0.0
		AudioManager.play_sound("blocked", randf_range(0.9, 1.1))
		Fx.puff(dungeon.effects, global_position + Vector3(0, height * 0.6, 0) + _facing * radius, "spark", 0.4)
		return
	if stun_left > 0.0:
		amount *= 2.0
	_last_hit = _anim_time
	hp -= amount
	_flash = 0.12
	_awake = true
	_push += Vector3(push.x, 0, push.z) * (0.15 if is_boss else 1.0)
	if confuse and not is_boss:
		_confused = CONFUSED_TIME
	_voice("hit", randf_range(0.9, 1.15))
	if hp <= 0.0:
		_die()


## A player hit with these `flags` (ShotStats.roll_flags) for `amount`: adds the effects.
func afflict(flags: Dictionary, amount: float) -> void:
	if not alive:
		return
	var effects: Dictionary = Content.player().get("effects", {})
	if flags.has("burn"):
		_burn_left = float(effects.get("burn_time", 3.0))
		_burn_per_second = maxf(_burn_per_second, amount * float(effects.get("burn_share", 0.4)))
	if flags.has("poison"):
		_poison_left = float(effects.get("poison_time", 5.0))
		_poison_per_second = maxf(_poison_per_second, amount * float(effects.get("poison_share", 0.25)))
	if flags.has("slow"):
		_slow_left = float(effects.get("slow_time", 2.0))
	if flags.has("bleed"):
		_bleed_left = float(effects.get("bleed_time", 4.0))
		_bleed_stacks = mini(_bleed_stacks + 1, int(effects.get("bleed_max", 5)))
		_bleed_per_stack = maxf(_bleed_per_stack, amount * float(effects.get("bleed_share", 0.15)))
	# Bosses are only stopped / scared for a short moment.
	var boss_factor: float = 0.3 if is_boss else 1.0
	if flags.has("freeze"):
		_freeze_left = float(effects.get("freeze_time", 1.0)) * boss_factor
	if flags.has("fear"):
		_confused = maxf(_confused, float(effects.get("fear_time", 2.5)) * boss_factor)
	if flags.has("daze"):
		_daze_left = float(effects.get("daze_time", 2.5)) * boss_factor
		_daze_dir = Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)


func is_burning() -> bool:
	return _burn_left > 0.0


func is_slowed() -> bool:
	return _slow_left > 0.0


func _update_effects(delta: float) -> void:
	_slow_left = maxf(0.0, _slow_left - delta)
	_freeze_left = maxf(0.0, _freeze_left - delta)
	_thorns_wait = maxf(0.0, _thorns_wait - delta)
	stun_left = maxf(0.0, stun_left - delta)
	if _daze_left > 0.0:
		_daze_left -= delta
		if _rng.randf() < delta * 1.5:
			_daze_dir = _daze_dir.rotated(Vector3.UP, _rng.randf_range(-2.0, 2.0))
	_burn_left = maxf(0.0, _burn_left - delta)
	_poison_left = maxf(0.0, _poison_left - delta)
	if _burn_left <= 0.0:
		_burn_per_second = 0.0
	if _poison_left <= 0.0:
		_poison_per_second = 0.0
	_bleed_left = maxf(0.0, _bleed_left - delta)
	if _bleed_left <= 0.0:
		_bleed_stacks = 0
		_bleed_per_stack = 0.0
	var bleed: float = _bleed_stacks * _bleed_per_stack
	if _burn_per_second + _poison_per_second + bleed <= 0.0:
		return
	_burn_tick -= delta
	if _burn_tick <= 0.0:
		_burn_tick = BURN_TICK
		hp -= (_burn_per_second + _poison_per_second + bleed) * BURN_TICK
		_flash = 0.06
		if hp <= 0.0:
			_die()


## front_guard enemies turn slowly (others look at the player at once).
func _turn_facing(delta: float, toward: Vector3) -> void:
	# Ramming or standing after it: the shield keeps pointing where it rammed.
	if _ai == "guard" and _guard_step >= 2:
		_facing = _ram_dir
		return
	if not bool(data.get("front_guard", false)) or not _facing_set:
		# Others look at the player at once; a guard does so when it appears.
		_facing = toward
		_facing_set = true
		return
	var angle: float = _facing.signed_angle_to(toward, Vector3.UP)
	_facing = _facing.rotated(Vector3.UP, clampf(angle, -1.6 * delta, 1.6 * delta)).normalized()


## Shield bearer: circle at a distance, wind up, ram straight, then stand still (back open).
func _guard(delta: float, toward: Vector3, distance: float) -> Vector3:
	_guard_left -= delta
	match _guard_step:
		0:
			if _guard_left <= 0.0:
				_guard_step = 1
				_guard_left = GUARD_WINDUP
				cry("attack")
			# Keep the distance and walk around the player, shield first.
			var side: Vector3 = toward.cross(Vector3.UP) * (1.0 if sin(_anim_time * 0.6 + float(get_instance_id() % 7)) > 0.0 else -1.0)
			var keep: Vector3 = toward * clampf(distance - GUARD_DISTANCE, -1.0, 1.0)
			return (side * 0.6 + keep).normalized() * _speed * 0.6
		1:
			_flash = 0.05
			_ram_dir = toward
			if _guard_left <= 0.0:
				_guard_step = 2
				_guard_left = GUARD_RAM
				AudioManager.play_sound("dash", 0.6)
			return Vector3.ZERO
		2:
			if _guard_left <= 0.0 or is_on_wall():
				_guard_step = 3
				_guard_left = GUARD_RECOVER
				return Vector3.ZERO
			return _ram_dir * _speed * 3.5
		_:
			if _guard_left <= 0.0:
				_guard_step = 0
				_guard_left = GUARD_HOLD * _rng.randf_range(0.8, 1.3)
			return Vector3.ZERO


## The dig of "burrow" enemies; true while it is underground (it does not walk then).
func _burrowing(delta: float, distance: float) -> bool:
	var burrow: Dictionary = data.get("burrow", {})
	if burrow.is_empty():
		return false
	if _under_left > 0.0:
		_under_left -= delta
		if not _marked and _under_left < 0.8:
			_marked = true
			_rise_at = player.global_position
			mark(_rise_at, radius + 0.6, 0.8)
		if _under_left <= 0.0:
			move_to(_rise_at)
			hidden_phase = false
			collision_layer = RoomBuilder.LAYER_ENEMIES
			Fx.puff(dungeon.effects, global_position + Vector3(0, 0.3, 0), "spark", 1.0)
			AudioManager.play_sound("boss_burrow", 1.3)
			hurt_player_near(0.9)
		return true
	_burrow_wait -= delta
	if _burrow_wait <= 0.0 and _awake and distance > 2.5:
		_burrow_wait = float(burrow.get("every", 4.0)) * _rng.randf_range(0.8, 1.3)
		_under_left = float(burrow.get("time", 1.6))
		_marked = false
		hidden_phase = true
		collision_layer = 0
		Fx.puff(dungeon.effects, global_position + Vector3(0, 0.3, 0), "spark", 1.0)
		AudioManager.play_sound("boss_burrow", 1.3)
		return true
	return false


## The jump of "leap" enemies; true while crouching or in the air (it moves itself then).
func _leaping(delta: float, distance: float) -> bool:
	var leap: Dictionary = data.get("leap", {})
	if leap.is_empty():
		return false
	if _air_left > 0.0:
		_air_left -= delta
		var t: float = 1.0 - _air_left / _air_time
		var next: Vector3 = _leap_from.lerp(_leap_to, clampf(t, 0.0, 1.0))
		velocity = (next - global_position) / maxf(delta, 0.001) * Vector3(1, 0, 1)
		_jump_y = sin(PI * clampf(t, 0.0, 1.0)) * float(leap.get("height", 1.4))
		move_and_slide()
		if _air_left <= 0.0:
			_jump_y = 0.0
			Fx.puff(dungeon.effects, global_position + Vector3(0, 0.2, 0), "spark", 0.6)
		return true
	if _crouch_left > 0.0:
		_crouch_left -= delta
		_sprite.scale = Vector3(1.15, 0.75, 1.0)
		if _crouch_left <= 0.0:
			_sprite.scale = Vector3.ONE
			_leap_from = global_position
			var target: Vector3 = player.global_position
			var rect: Rect2 = room_rect(radius + 0.2)
			_leap_to = Vector3(clampf(target.x, rect.position.x, rect.end.x), 0.0, clampf(target.z, rect.position.y, rect.end.y))
			_air_time = clampf(_leap_from.distance_to(_leap_to) / 7.0, 0.35, 0.8)
			_air_left = _air_time
			AudioManager.play_sound("dash", 0.7)
		return true
	_leap_wait -= delta
	if _leap_wait <= 0.0 and _awake and distance < float(leap.get("range", 5.0)) and distance > 1.2:
		_leap_wait = float(leap.get("every", 3.0)) * _rng.randf_range(0.8, 1.2)
		_crouch_left = float(leap.get("windup", 0.35))
		cry("attack")
		return true
	return false


## The enemy's own sound (data "voice", made by SoundSynth); without one the usual sounds.
func _voice(kind: String, pitch: float) -> void:
	var voice: Dictionary = data.get("voice", {})
	if voice.is_empty():
		AudioManager.play_sound("enemy_hit" if kind == "hit" else "enemy_die", pitch)
		return
	AudioManager.play_stream(SoundSynth.make(voice, kind), pitch, -4.0 if kind == "hit" else 0.0)


## The animal sound `kind` from "cries" (idle, wake, near, attack); nothing if it has none.
## Further away from the player = quieter.
func cry(kind: String) -> void:
	var cries: Dictionary = data.get("cries", {})
	if not alive or not cries.has(kind):
		return
	var sound: Dictionary = cries[kind]
	var distance: float = global_position.distance_to(player.global_position) if player else 0.0
	var volume: float = float(sound.get("volume", 0.0)) - clampf(distance - 2.0, 0.0, 14.0) * CRY_FALLOFF_DB
	AudioManager.play_stream(SoundSynth.make(sound, "cry"), randf_range(0.94, 1.06), volume)


## Idle cries now and then, the near cry when the player comes close.
func _update_cries(delta: float, distance: float) -> void:
	var cries: Dictionary = data.get("cries", {})
	if cries.is_empty() or hidden_phase:
		return
	_near_wait = maxf(0.0, _near_wait - delta)
	if cries.has("near") and _awake and _near_wait <= 0.0:
		var near: Dictionary = cries["near"]
		if distance < float(near.get("range", 2.0)):
			_near_wait = float(near.get("cooldown", 3.0))
			cry("near")
	if cries.has("idle"):
		_idle_wait -= delta
		if _idle_wait <= 0.0:
			var every: Array = (cries["idle"] as Dictionary).get("every", [3.0, 7.0])
			_idle_wait = randf_range(float(every[0]), float(every[1]))
			var now: int = Time.get_ticks_msec()
			if now - _last_idle_ms >= IDLE_GAP_MS:
				_last_idle_ms = now
				cry("idle")


func _die() -> void:
	alive = false
	collision_layer = 0
	collision_mask = 0
	died.emit(self)
	_voice("die", randf_range(0.9, 1.05))
	if _death == null:
		queue_free()
		return
	_ring.visible = false
	_set_sheet(_death)
	_sprite.modulate = Color.WHITE
	_anim_time = 0.0


func _set_sheet(texture: Texture2D) -> void:
	_sprite.texture = texture
	_sprite.hframes = maxi(1, texture.get_width() / FRAME_SIZE)
	_sprite.frame = 0


func _physics_process(delta: float) -> void:
	_anim_time += delta
	if not alive:
		var frame: int = int(_anim_time * DEATH_FPS)
		if frame >= _sprite.hframes:
			queue_free()
		else:
			_sprite.frame = frame
			_sprite.modulate.a = 1.0 - float(frame) / _sprite.hframes * 0.5
		return
	if player == null:
		return
	_flash = maxf(0.0, _flash - delta)
	_confused = maxf(0.0, _confused - delta)
	_update_effects(delta)
	if not alive:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var distance: float = to_player.length()
	var toward: Vector3 = to_player / maxf(distance, 0.001)
	var move := Vector3.ZERO
	_update_cries(delta, distance)
	if not _awake:
		_wake_left -= delta
		if _wake_left <= 0.0 or distance < 1.8:
			_awake = true
			_set_sheet(_walk)
			cry("wake")
	elif _freeze_left > 0.0:
		move = Vector3.ZERO
	elif _leaping(delta, distance) or _burrowing(delta, distance):
		move = Vector3.ZERO
	elif _confused > 0.0:
		move = -toward * _speed
	elif _daze_left > 0.0:
		move = _daze_dir * _speed * 0.7
	else:
		move = _think(delta, toward, distance)
	if _slow_left > 0.0:
		move *= float((Content.player().get("effects", {}) as Dictionary).get("slow_factor", 0.5))
	move += _separation()
	velocity = move + _push
	_push = _push.move_toward(Vector3.ZERO, 12.0 * delta)
	move_and_slide()
	global_position.y = 0.0
	_turn_facing(delta, toward)
	_animate(move)
	if distance < radius + player.hit_radius() + 0.1 and _freeze_left <= 0.0 and not hidden_phase:
		var life_before: int = player.run.health + player.run.blue if player.run else 0
		player.take_hit(int(data.get("damage", 1)))
		# lifesteal: the boss heals when it hurts the player.
		if player.run and (data.get("traits", []) as Array).has("lifesteal") and player.run.health + player.run.blue < life_before:
			hp = minf(max_hp, hp + max_hp * 0.08)
		# Dornen: touching the player hurts the enemy too.
		if player.run and player.run.stats.has("thorns") and _thorns_wait <= 0.0:
			_thorns_wait = 0.5
			take_damage(float((Content.player().get("effects", {}) as Dictionary).get("thorns_damage", 3.0)), -toward * 3.0, false)


## Velocity this frame, by "ai".
func _think(delta: float, toward: Vector3, distance: float) -> Vector3:
	match _ai:
		"lurk", "chase":
			return toward * _speed
		"fly":
			var wobble := Vector3(sin(_anim_time * 3.1), 0, cos(_anim_time * 2.3)) * 1.5
			return toward * _speed + wobble
		"hop":
			_timer -= delta
			if _timer <= 0.0:
				_hop_phase = not _hop_phase
				_timer = 0.45 if _hop_phase else 0.7
			return toward * _speed if _hop_phase else Vector3.ZERO
		"guard":
			return _guard(delta, toward, distance)
		"shooter":
			_timer -= delta
			if not _cued and _timer <= ATTACK_CUE_LEAD:
				_cued = true
				cry("attack")
			if _timer <= 0.0:
				_cued = false
				_timer = float(data.get("fire_interval", 2.5))
				_shoot_spray(int(data.get("spray", 1)), 14.0)
			var keep: float = float(data.get("keep_distance", 4.0))
			if distance < keep - 1.0:
				return -toward * _speed
			if distance > keep + 1.0:
				return toward * _speed
			return toward.cross(Vector3.UP) * _speed * 0.6 * (1.0 if sin(_anim_time * 0.7) > 0.0 else -1.0)
		"boss":
			return _brain.update(delta, toward, distance)
	return Vector3.ZERO


## Boss: walks at the player; every few seconds the next attack from "attacks". Below half life
## the pauses get shorter.
func _shoot_spray(count: int, step_degrees: float) -> void:
	shoot_spray(count, step_degrees, {})


func _shoot(direction: Vector3) -> void:
	shoot(direction, {})


# --- Used by BossBrain (and _shoot) -----------------------------------------------------

## A shot towards `direction`. `options`: speed (factor), slows, returns, burst, size, life, homing.
func shoot(direction: Vector3, options: Dictionary) -> void:
	shoot_from(global_position + Vector3(0, 0.8, 0) + direction * (radius + 0.2), direction, options)


func shoot_from(at: Vector3, direction: Vector3, options: Dictionary) -> void:
	var shot := EnemyShot.new()
	shot.velocity = direction * float(data.get("shot_speed", 4.0)) * float(options.get("speed", 1.0))
	shot.player = player
	shot.slows = bool(options.get("slows", false))
	shot.burst = int(options.get("burst", 0))
	shot.size = float(options.get("size", 1.0))
	shot.homing = float(options.get("homing", 0.0))
	shot.lifetime = float(options.get("life", EnemyShot.LIFETIME))
	if bool(options.get("returns", false)):
		shot.returns_to = self
	dungeon.effects.add_child(shot)
	shot.global_position = Vector3(at.x, 0.8, at.z)
	AudioManager.play_sound("enemy_shoot", randf_range(1.2, 1.5))


## A fan of `count` shots at the player.
func shoot_spray(count: int, step_degrees: float, options: Dictionary) -> void:
	var to_player: Vector3 = (player.global_position - global_position) * Vector3(1, 0, 1)
	var forward: Vector3 = to_player.normalized()
	for i in count:
		var angle: float = (i - (count - 1) / 2.0) * step_degrees
		shoot(forward.rotated(Vector3.UP, deg_to_rad(angle)), options)


func speed() -> float:
	return _speed * (1.25 if is_boss and hp < max_hp * 0.5 else 1.0)


func age() -> float:
	return _anim_time


func flash(time: float) -> void:
	_flash = maxf(_flash, time)


func time_since_hit() -> float:
	return _anim_time - _last_hit


func summon_near(offset: Vector3) -> void:
	dungeon.summon(String(data.get("summon", "rat")), global_position + offset)


func summon_at(at: Vector3) -> void:
	dungeon.summon(String(data.get("summon", "rat")), at)


func room_rect(margin: float) -> Rect2:
	return RoomBuilder.inner_rect(dungeon.current_cell, margin)


## Jumps to `at` (kept inside the room).
func move_to(at: Vector3) -> void:
	var rect: Rect2 = room_rect(radius + 0.3)
	global_position = Vector3(clampf(at.x, rect.position.x, rect.end.x), 0.0, clampf(at.z, rect.position.y, rect.end.y))


## true right after running into a wall or rock.
func hit_wall() -> bool:
	return is_on_wall()


## A red mark on the floor (where something will land).
func mark(at: Vector3, size: float, time: float) -> void:
	Fx.marker(dungeon.effects, at, size, time)


func shake(time: float) -> void:
	player.shake(time)
	AudioManager.play_sound("explosion", 0.7)


## The player takes a hit if closer than `distance`.
func hurt_player_near(distance: float) -> void:
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	if offset.length() < distance + radius:
		player.take_hit(int(data.get("damage", 2)))


func sound(id: String) -> void:
	AudioManager.play_sound(id)


## Keeps enemies of a room from standing inside each other.
func _separation() -> Vector3:
	var push := Vector3.ZERO
	for other: Enemy in dungeon.get_enemies():
		if other == self:
			continue
		var offset: Vector3 = global_position - other.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		var wanted: float = (radius + other.radius) * SEPARATION
		if distance < wanted and distance > 0.001:
			push += offset / distance * (wanted - distance) * 4.0
	return push


func _animate(move: Vector3) -> void:
	if _awake:
		_sprite.frame = int(_anim_time * WALK_FPS) % _sprite.hframes
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera and move.length() > 0.1:
		# Sprites look left; walking to the right of the screen mirrors them.
		_sprite.flip_h = move.dot(camera.global_basis.x) > 0.0
	# Underground / invisible: no ring either.
	_ring.visible = not hidden_phase
	if hidden_phase:
		_sprite.modulate = Color(0.6, 0.6, 0.8, 0.12 if is_boss else 0.0)
	elif reflecting:
		_sprite.modulate = Color(0.75 + sin(_anim_time * 20.0) * 0.2, 0.75, 1.0)
	elif stun_left > 0.0:
		_sprite.modulate = Color(1.0, 1.0, 0.45)
	elif _flash > 0.0:
		_sprite.modulate = Color(1, 0.35, 0.35)
	elif _confused > 0.0:
		_sprite.modulate = Color(1, 0.95, 0.5)
	elif _freeze_left > 0.0:
		_sprite.modulate = Color(0.85, 0.95, 1.0)
	elif _burn_left > 0.0:
		_sprite.modulate = Color(1, 0.65 + sin(_anim_time * 18.0) * 0.1, 0.35)
	elif _poison_left > 0.0:
		_sprite.modulate = Color(0.55, 1.0, 0.5)
	elif _bleed_stacks > 0:
		_sprite.modulate = Color(0.85, 0.3, 0.35)
	elif _slow_left > 0.0:
		_sprite.modulate = Color(0.6, 0.8, 1.0)
	else:
		_sprite.modulate = Color.WHITE
	if _ai == "fly":
		_sprite.position.y = height / 2.0 + FLY_HEIGHT + sin(_anim_time * 6.0) * 0.12
	else:
		_sprite.position.y = height / 2.0 + _jump_y
