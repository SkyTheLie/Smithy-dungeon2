class_name Weapon
extends Node3D
## How the player shoots, by the current ShotStats (RunState.stats):
##   fire  left mouse button (hold = keep shooting): `shots` fireballs, `spread` degrees apart
##   bomb  the same, but thrown bombs (Pulverhandschuh)
##   beam  hold the button: a fire beam that hurts everything it touches (Feuerlanze)
##   charge (Glutsammler): hold to charge, release to shoot; with the beam a charged burst
##   melee (Krieger, swords and axes): a cut from left to right hits every enemy in the half
##         circle in front and knocks enemy shots out of the air; the blade is shown in the hand
## Also keeps the Glutmond fireballs circling the player and the helper sparks ("helpers") that
## follow the player and shoot at the nearest enemy. Flags here: back (one shot backwards),
## cross (chance: shots in all four directions), alternate (every second shot stronger).

signal charge_changed(amount: float)

const MUZZLE_DROP: float = 0.22
const AIM_DISTANCE: float = 60.0
const CHARGE_TIME: float = 1.1
const BEAM_TICK: float = 0.1
const BEAM_WIDTH: float = 0.18
const BEAM_BASE_LENGTH: float = 5.0
const BEAM_HOMING_ANGLE: float = 40.0
const BEAM_BLAST_TIME: float = 0.35
const ORBIT_RADIUS: float = 1.3
const ORBIT_SPEED: float = 3.0
const ORBIT_HIT_TIME: float = 0.3
## Melee: where the blade rests in the hand, how long the cut and the way back take.
const BLADE_REST_POSITION: Vector3 = Vector3(0.28, -0.22, -0.5)
const BLADE_REST_TILT: float = 0.6
const SWING_TIME: float = 0.14
const SWING_BACK_TIME: float = 0.2
## Picture in the hand if no melee item says otherwise.
const BLADE_DEFAULT: String = "res://assets/sprites/items/sword.png"
## Feuerhieb: the fire band starts this far in front of the player.
const SLASH_START: float = 0.5

var player: Player
var run: RunState
var dungeon: Dungeon

var _cooldown: float = 0.0
var _charge: float = 0.0
var _charging: bool = false
## Beam: seconds left of a charged burst (Drachenatem), tick timer, explosion timer.
var _burst_left: float = 0.0
var _burst_power: float = 0.0
var _tick: float = 0.0
var _blast: float = 0.0
var _beams: Array[MeshInstance3D] = []
var _beam_lights: Array[OmniLight3D] = []
var _orbitals: Array[Sprite3D] = []
var _orbit_angle: float = 0.0
## Enemy -> time until the Glutmond may hurt it again.
var _orbit_cooldowns: Dictionary = {}
var _helpers: Array[Sprite3D] = []
var _helper_wait: float = 0.0
## Counts the shots for "alternate".
var _shot_count: int = 0
## The weapon in the hand (melee only).
var _blade: Sprite3D
var _blade_path: String = ""
var _swing_tween: Tween


func setup(the_player: Player, run_state: RunState, the_dungeon: Dungeon) -> void:
	player = the_player
	run = run_state
	dungeon = the_dungeon
	_blade = Sprite3D.new()
	_blade.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_blade.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_blade.shaded = false
	_blade.no_depth_test = true
	_blade.position = BLADE_REST_POSITION
	_blade.rotation.z = BLADE_REST_TILT
	_blade.visible = false
	player.camera.add_child(_blade)
	_update_blade_picture()
	run.changed.connect(_update_blade_picture)


## The picture in the hand: the newest melee item ("hand", else its icon). Only loads when it
## changes (run.changed comes often).
func _update_blade_picture() -> void:
	var path: String = BLADE_DEFAULT
	for i in range(run.items.size() - 1, -1, -1):
		var data: Dictionary = Content.item(run.items[i])
		if String(data.get("mode", "")) == ShotStats.MODE_MELEE:
			path = String(data.get("hand", data.get("icon", BLADE_DEFAULT)))
			break
	if path == _blade_path:
		return
	_blade_path = path
	_blade.texture = load(path) as Texture2D if ResourceLoader.exists(path) else load(BLADE_DEFAULT) as Texture2D
	_blade.pixel_size = 0.4 / float(maxi(1, _blade.texture.get_height() if _blade.texture else 1))


func stats() -> ShotStats:
	return run.stats


func _physics_process(delta: float) -> void:
	if run == null or dungeon == null:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	var holding: bool = player.controls_enabled and Input.is_action_pressed(Controls.SHOOT)
	var s: ShotStats = stats()
	if s.mode == ShotStats.MODE_BEAM:
		_update_beam(delta, holding, s)
	else:
		_hide_beams(0)
		if s.has("charge"):
			_update_charge(delta, holding, s)
		elif holding and _cooldown <= 0.0:
			_fire(s, 0.0)
	_update_orbitals(delta, s)
	_update_helpers(delta, s)
	if _blade:
		_blade.visible = s.mode == ShotStats.MODE_MELEE


# --- fireballs / bombs ----------------------------------------------------------

func _update_charge(delta: float, holding: bool, s: ShotStats) -> void:
	if holding:
		_charging = true
		# A faster fire rate also charges faster.
		_charge = minf(1.0, _charge + delta / (CHARGE_TIME * clampf(s.fire_delay / 0.42, 0.4, 2.0)))
		charge_changed.emit(_charge)
	elif _charging:
		_charging = false
		if _charge > 0.15:
			_fire(s, _charge)
		_charge = 0.0
		charge_changed.emit(0.0)


## Shoots `shots` fireballs (or bombs) at the crosshair, fanned out by `spread`.
func _fire(s: ShotStats, charge: float) -> void:
	_cooldown = s.fire_delay
	if s.mode == ShotStats.MODE_MELEE:
		_swing(s, charge)
		return
	var camera: Camera3D = player.camera
	var origin: Vector3 = camera.global_position + player.aim_direction() * 0.45 - Vector3(0, MUZZLE_DROP, 0)
	var aim: Vector3 = (_aim_point() - origin).normalized()
	_shot_count += 1
	var bonus: float = 1.0
	if s.has("alternate") and _shot_count % 2 == 0:
		bonus = float((Content.player().get("effects", {}) as Dictionary).get("alternate_mult", 1.6))
	var turns: Array[float] = [0.0]
	if s.has("back"):
		turns.append(180.0)
	if s.roll("cross"):
		turns = [0.0, 90.0, 180.0, 270.0]
	for turn: float in turns:
		for i in s.shots:
			var angle: float = (i - (s.shots - 1) / 2.0) * s.spread + turn
			if s.has("jitter"):
				angle += randf_range(-s.spread * 0.4, s.spread * 0.4)
			var direction: Vector3 = aim.rotated(Vector3.UP, deg_to_rad(angle))
			dungeon.spawn_projectile(origin, direction, s, charge, false, [], bonus)
	AudioManager.play_sound("shoot", randf_range(0.9, 1.1) * (0.8 if charge > 0.5 else 1.0))


## Where the crosshair points: the first wall, rock or enemy in front of the camera.
func _aim_point() -> Vector3:
	var camera: Camera3D = player.camera
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + player.aim_direction() * AIM_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to, RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS | RoomBuilder.LAYER_ENEMIES)
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or from.distance_to(hit["position"]) < 1.0:
		return to
	return hit["position"]


# --- beam -------------------------------------------------------------------------

func _update_beam(delta: float, holding: bool, s: ShotStats) -> void:
	var firing: bool = false
	var power: float = 1.0
	if s.has("charge"):
		# Drachenatem: charge, release = burst as long as it was charged.
		if _burst_left > 0.0:
			_burst_left -= delta
			firing = true
			power = 1.0 + _burst_power
		elif holding:
			_charging = true
			_charge = minf(1.0, _charge + delta / CHARGE_TIME)
			charge_changed.emit(_charge)
		elif _charging:
			_charging = false
			if _charge > 0.2:
				_burst_left = 0.3 + 1.1 * _charge
				_burst_power = _charge
			_charge = 0.0
			charge_changed.emit(0.0)
	else:
		firing = holding
	if not firing:
		_hide_beams(0)
		return
	_tick -= delta
	_blast -= delta
	var hurt_now: bool = _tick <= 0.0
	if hurt_now:
		_tick = BEAM_TICK
	var camera: Camera3D = player.camera
	var origin: Vector3 = camera.global_position + player.aim_direction() * 0.4 - Vector3(0, MUZZLE_DROP, 0)
	var length: float = BEAM_BASE_LENGTH + s.reach * 1.5
	var width: float = BEAM_WIDTH * s.size * (1.0 + power * 0.6 if s.has("charge") else 1.0)
	var aim: Vector3 = (_aim_point() - origin).normalized()
	for i in s.shots:
		var angle: float = (i - (s.shots - 1) / 2.0) * s.spread
		var direction: Vector3 = aim.rotated(Vector3.UP, deg_to_rad(angle))
		if s.has("homing"):
			direction = _bend_to_enemy(origin, direction, length)
		var end: Vector3 = _beam_end(origin, direction, length)
		_show_beam(i, origin, end, width)
		if hurt_now:
			_beam_damage(origin, end, width, s.damage * 0.45 * power, s)
		if s.has("explosive") and _blast <= 0.0:
			dungeon.explode(end - direction * 0.3, 1.3, s.damage * 1.2, false)
	if s.has("explosive") and _blast <= 0.0:
		_blast = BEAM_BLAST_TIME
	_hide_beams(s.shots)


## Suchender Strahl: turns the beam to the nearest enemy within BEAM_HOMING_ANGLE degrees.
func _bend_to_enemy(origin: Vector3, direction: Vector3, length: float) -> Vector3:
	var best: Vector3 = direction
	var best_angle: float = deg_to_rad(BEAM_HOMING_ANGLE)
	for enemy: Enemy in dungeon.get_enemies():
		var to_enemy: Vector3 = enemy.aim_point() - origin
		if to_enemy.length() > length:
			continue
		var angle: float = direction.angle_to(to_enemy)
		if angle < best_angle:
			best_angle = angle
			best = to_enemy.normalized()
	return best


func _beam_end(origin: Vector3, direction: Vector3, length: float) -> Vector3:
	var to: Vector3 = origin + direction * length
	var query := PhysicsRayQueryParameters3D.create(origin, to, RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS)
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	return to if hit.is_empty() else Vector3(hit["position"])


func _beam_damage(origin: Vector3, end: Vector3, width: float, amount: float, s: ShotStats) -> void:
	var direction: Vector3 = (end - origin).normalized()
	for enemy: Enemy in dungeon.get_enemies():
		var center: Vector3 = enemy.aim_point()
		var closest: Vector3 = Geometry3D.get_closest_point_to_segment(center, origin, end)
		var offset := Vector2(closest.x - center.x, closest.z - center.z)
		if enemy.reflecting:
			continue
		if offset.length() < enemy.radius + width and absf(closest.y - center.y) < enemy.height * 0.5 + width + 0.3:
			enemy.take_damage(amount, direction * s.knockback * 0.3, s.has("bread"))
			# Per second, not per tick: the beam hurts 10 times a second. Fixed flags only.
			enemy.afflict(s.flags, s.damage)


func _show_beam(index: int, from: Vector3, to: Vector3, width: float) -> void:
	while _beams.size() <= index:
		var mesh_instance := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 1.0
		cylinder.bottom_radius = 1.0
		cylinder.height = 1.0
		cylinder.radial_segments = 6
		cylinder.rings = 1
		mesh_instance.mesh = cylinder
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(1.0, 0.55, 0.15)
		mesh_instance.material_override = material
		mesh_instance.top_level = true
		add_child(mesh_instance)
		_beams.append(mesh_instance)
		var light := OmniLight3D.new()
		light.light_color = Color(1, 0.55, 0.2)
		light.light_energy = 1.5
		light.omni_range = 3.0
		light.top_level = true
		add_child(light)
		_beam_lights.append(light)
	var beam: MeshInstance3D = _beams[index]
	var length: float = from.distance_to(to)
	var y_axis: Vector3 = (to - from) / maxf(length, 0.001)
	var up: Vector3 = Vector3.FORWARD if absf(y_axis.dot(Vector3.UP)) > 0.98 else Vector3.UP
	var x_axis: Vector3 = y_axis.cross(up).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	# Flickers a little.
	var w: float = width * randf_range(0.85, 1.15)
	beam.global_transform = Transform3D(Basis(x_axis * w, y_axis * length, z_axis * w), (from + to) / 2.0)
	beam.visible = true
	_beam_lights[index].global_position = to - y_axis * 0.3
	_beam_lights[index].visible = true


## Hides every beam from `first` on.
func _hide_beams(first: int) -> void:
	for i in range(first, _beams.size()):
		_beams[i].visible = false
		_beam_lights[i].visible = false


# --- Glutmond -------------------------------------------------------------------------

func _update_orbitals(delta: float, s: ShotStats) -> void:
	while _orbitals.size() < s.orbitals:
		var sprite := Fx.billboard(Fx.ball_texture("fire"), 0.5)
		sprite.top_level = true
		var light := OmniLight3D.new()
		light.light_color = Color(1, 0.6, 0.25)
		light.omni_range = 2.0
		sprite.add_child(light)
		add_child(sprite)
		_orbitals.append(sprite)
	# Fewer after the test room took the items away.
	while _orbitals.size() > s.orbitals:
		_orbitals.pop_back().queue_free()
	_orbit_angle += ORBIT_SPEED * delta
	for enemy: Variant in _orbit_cooldowns.keys():
		_orbit_cooldowns[enemy] = float(_orbit_cooldowns[enemy]) - delta
	for i in _orbitals.size():
		var angle: float = _orbit_angle + TAU * i / maxf(1.0, _orbitals.size())
		var at: Vector3 = player.global_position + Vector3(cos(angle), 0, sin(angle)) * ORBIT_RADIUS + Vector3(0, 1.0, 0)
		_orbitals[i].global_position = at
		for enemy: Enemy in dungeon.get_enemies():
			if enemy.hits(at, 0.3) and float(_orbit_cooldowns.get(enemy, 0.0)) <= 0.0:
				_orbit_cooldowns[enemy] = ORBIT_HIT_TIME
				enemy.take_damage(1.5 + s.damage * 0.5, Vector3.ZERO, false)
		for shot: Node in get_tree().get_nodes_in_group(EnemyShot.GROUP):
			if (shot as Node3D).global_position.distance_to(at) < 0.45:
				(shot as EnemyShot).pop()
	# Enemies that died are dropped from the list.
	for enemy: Variant in _orbit_cooldowns.keys():
		if not is_instance_valid(enemy):
			_orbit_cooldowns.erase(enemy)


# --- helpers (Begleiter-Funken) -------------------------------------------------------

func _update_helpers(delta: float, s: ShotStats) -> void:
	while _helpers.size() < s.helpers:
		var sprite := Fx.billboard(Fx.ball_texture("spark"), 0.35)
		sprite.top_level = true
		add_child(sprite)
		_helpers.append(sprite)
	while _helpers.size() > s.helpers:
		_helpers.pop_back().queue_free()
	if _helpers.is_empty():
		return
	var effects: Dictionary = Content.player().get("effects", {})
	var back: Vector3 = player.global_basis.z
	for i in _helpers.size():
		var side: float = (i - (_helpers.size() - 1) / 2.0) * 0.6
		var want: Vector3 = player.global_position + back * 0.8 + player.global_basis.x * side + Vector3(0, 1.5 + sin(_orbit_angle * 2.0 + i) * 0.1, 0)
		_helpers[i].global_position = _helpers[i].global_position.lerp(want, clampf(8.0 * delta, 0.0, 1.0))
	_helper_wait -= delta
	if _helper_wait > 0.0:
		return
	_helper_wait = float(effects.get("helper_delay", 1.1))
	for helper: Sprite3D in _helpers:
		var target: Enemy = dungeon.nearest_enemy(helper.global_position, 9.0, [])
		if target == null:
			return
		var direction: Vector3 = (target.aim_point() - helper.global_position).normalized()
		dungeon.spawn_projectile(helper.global_position, direction, s, 0.0, true, [], float(effects.get("helper_damage", 0.5)) * 2.0)


# --- melee ------------------------------------------------------------------------------

## One swing, a cut from left to right: every enemy within reach in the half circle in front
## (melee_arc, 180 degrees) takes the hit; enemy shots there are knocked away. Charge = longer
## and stronger. No sparks or explosions, only the blade moves.
func _swing(s: ShotStats, charge: float) -> void:
	var effects: Dictionary = Content.player().get("effects", {})
	var reach: float = float(effects.get("melee_reach", 1.5)) + s.reach * float(effects.get("melee_reach_per_range", 0.2)) + charge
	var arc: float = deg_to_rad(float(effects.get("melee_arc", 180.0)))
	var forward: Vector3 = player.aim_direction() * Vector3(1, 0, 1)
	forward = forward.normalized()
	var amount: float = s.damage * (1.0 + 2.0 * charge)
	var hit: Array[Node] = []
	for enemy: Enemy in dungeon.get_enemies().duplicate():
		if enemy.hidden_phase:
			continue
		var offset: Vector3 = (enemy.global_position - player.global_position) * Vector3(1, 0, 1)
		if offset.length() - enemy.radius > reach or forward.angle_to(offset.normalized()) > arc / 2.0:
			continue
		enemy.take_damage(amount, offset.normalized() * s.knockback * 2.0, s.has("bread"))
		enemy.afflict(s.roll_flags(), amount)
		hit.append(enemy)
	# Feuerhieb (sword + fire staff): a band of fire flies on, as far as reach + fire range.
	if s.has("fire_slash"):
		var slash := FireSlash.new()
		var slash_damage: float = amount * float(effects.get("fire_slash_damage", 0.6))
		slash.setup(dungeon, s, forward, maxf(1.0, reach + s.reach - SLASH_START), slash_damage, hit)
		dungeon.effects.add_child(slash)
		slash.global_position = player.global_position * Vector3(1, 0, 1) + forward * (SLASH_START - FireSlash.RADIUS)
	for shot: Node in get_tree().get_nodes_in_group(EnemyShot.GROUP):
		var offset: Vector3 = ((shot as Node3D).global_position - player.global_position) * Vector3(1, 0, 1)
		if offset.length() < reach + 0.3 and forward.angle_to(offset.normalized()) < arc / 2.0:
			(shot as EnemyShot).pop()
	# The blade cuts from left to right (fast), then goes back to rest in the right hand.
	if _swing_tween:
		_swing_tween.kill()
	_swing_tween = create_tween()
	_swing_tween.tween_method(_set_swing_pose, 0.0, 1.0, SWING_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_swing_tween.tween_property(_blade, "position", BLADE_REST_POSITION, SWING_BACK_TIME)
	_swing_tween.parallel().tween_property(_blade, "rotation:z", BLADE_REST_TILT, SWING_BACK_TIME)
	AudioManager.play_sound("swing", randf_range(0.9, 1.1))
	if not hit.is_empty():
		AudioManager.play_sound("melee_hit", randf_range(0.9, 1.1))


## Blade pose during the cut, `t` from 0 (left, tilted left) to 1 (right, tilted right). The
## blade moves on a flat arc: a little higher and further forward in the middle.
func _set_swing_pose(t: float) -> void:
	var bulge: float = sin(t * PI)
	_blade.position = Vector3(lerpf(-0.36, 0.38, t), -0.24 + bulge * 0.08, -0.5 - bulge * 0.1)
	_blade.rotation.z = lerpf(1.4, -1.1, t)
