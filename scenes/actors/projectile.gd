class_name Projectile
extends Node3D
## A shot of the player: a fireball (or a bread loaf / a bomb, depending on the items). Moves by
## itself each physics frame: rays find walls and rocks, enemies are found by distance
## (Enemy.hits), so no physics body is needed. What it does comes from the ShotStats flags:
##   homing     turns towards the nearest enemy         pierce    flies through enemies
##   bounce     bounces off walls (2x)                   boomerang flies back to the player
##   split      bursts into 4 sparks on a hit            wave      snakes left and right
##   bread      bread loaf: hit enemies run away         explosive explodes where it ends
##   burn/slow  hit enemies burn / get slower (Enemy.afflict)
##   grow       more damage the farther it flew          shield    destroys enemy shots it touches
##   shrink     starts big and strong, gets smaller       spectral  flies through rocks
##   burst      bursts into 4 sparks at the end           overkill  flies on after a kill
##   poison/freeze/fear/daze/bleed: effects on the enemy (Enemy.afflict)
##   arrow / shuriken: only the picture (Bogenschütze, Wurfsterne)
## Chance flags (ShotStats.chances) are rolled once when the shot is made (`flags`).
##   mode bomb  thrown in an arc, explodes on the ground or an enemy (split: cluster bombs)
## After `reach` metres a fireball drops to the floor and goes out (like tears).

const BREAD: String = "res://assets/sprites/items/rye_bread.png"
const ARROW: String = "res://assets/sprites/items/iron_arrow_tip.png"
const GRAVITY: float = 14.0
const BOMB_GRAVITY: float = 13.0
const HOMING_RANGE: float = 9.0
const HOMING_TURN: float = 7.0
const WAVE_FREQ: float = 9.0
const WAVE_AMP: float = 0.45
const LIFETIME: float = 6.0
const BOUNCES: int = 2
## Every shot of the player is in this group (bosses that dodge look for it).
const GROUP: StringName = &"player_shots"

var dungeon: Dungeon
var player: Node3D
var stats: ShotStats
var velocity: Vector3 = Vector3.ZERO
var damage: float = 1.0
var radius: float = 0.18
var reach: float = 2.5
var is_bomb: bool = false
## Sparks from "split" and bomblets do not split again.
var small: bool = false

var _traveled: float = 0.0
var _age: float = 0.0
var _falling: bool = false
var _returning: bool = false
var _bounces_left: int = BOUNCES
var _hit: Array[Node] = []
var _side: Vector3 = Vector3.ZERO
var _wave_shift: float = 0.0
var _sprite: Sprite3D
var _done: bool = false
## The flags of this one shot (fixed ones plus rolled chances).
var flags: Dictionary[String, bool] = {}
## Extra damage factor from the weapon (alternate hand).
var bonus: float = 1.0


## `charge` 0..1 (Glutsammler): bigger and stronger.
func setup(the_dungeon: Dungeon, the_player: Node3D, the_stats: ShotStats, direction: Vector3, charge: float, as_small: bool) -> void:
	dungeon = the_dungeon
	player = the_player
	stats = the_stats
	flags = stats.roll_flags()
	small = as_small
	is_bomb = stats.mode == ShotStats.MODE_BOMB
	var speed: float = stats.shot_speed
	reach = stats.reach
	damage = stats.damage * (1.0 + 2.0 * charge)
	radius = 0.16 * stats.size * (1.0 + 1.2 * charge)
	if _has("jitter"):
		speed *= randf_range(0.8, 1.2)
		reach *= randf_range(0.8, 1.1)
	if small:
		damage *= 0.5
		radius *= 0.6
		reach *= 0.6
	if _has("shrink") and not is_bomb:
		var effects: Dictionary = Content.player().get("effects", {})
		damage *= float(effects.get("shrink_start", 2.0))
		radius *= float(effects.get("shrink_start", 2.0))
	if is_bomb:
		velocity = direction * speed * 0.7 + Vector3.UP * 3.0
	else:
		velocity = direction * speed
	_side = direction.cross(Vector3.UP).normalized()


func _has(flag: String) -> bool:
	return flags.has(flag)


## Enemies this shot must not hit (split sparks start inside the enemy that was hit).
func ignore(enemies: Array) -> void:
	for enemy: Variant in enemies:
		if enemy is Node:
			_hit.append(enemy)


func _ready() -> void:
	# Enemies that dodge (BossBrain trait "evade") look for these.
	add_to_group(GROUP)
	var texture: Texture2D = Fx.ball_texture("spark" if small else "fire")
	var height: float = radius * 2.6
	if is_bomb:
		texture = Pickup.icon("bomb")
		height = radius * 3.2
	elif _has("bread"):
		texture = load(BREAD) as Texture2D
		height = radius * 3.2
	elif _has("arrow"):
		texture = load(ARROW) as Texture2D
		height = radius * 3.0
	elif _has("shuriken"):
		texture = Fx.star_texture()
		height = radius * 2.6
	_sprite = Fx.billboard(texture, height)
	add_child(_sprite)
	# Fire and sparks shine: a soft light spot around the ball.
	if not is_bomb and not _has("bread") and not _has("arrow") and not _has("shuriken"):
		add_child(Fx.halo(Color(1.0, 0.55, 0.2, 0.45), height * 1.9))
	if not small and get_tree().get_node_count_in_group(&"shot_light") < 10:
		var light := OmniLight3D.new()
		light.light_color = Color(1, 0.6, 0.25)
		light.light_energy = 0.9
		light.omni_range = 2.0 + radius * 4.0
		light.add_to_group(&"shot_light")
		add_child(light)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_age += delta
	if _age > LIFETIME:
		_end(false)
		return
	_steer(delta)
	var motion: Vector3 = velocity * delta
	if _has("wave") and not is_bomb:
		var shift: float = sin(_age * WAVE_FREQ) * WAVE_AMP
		motion += _side * (shift - _wave_shift)
		_wave_shift = shift
	if _move(motion):
		return
	_traveled += motion.length()
	if _has("shrink") and _sprite:
		var effects: Dictionary = Content.player().get("effects", {})
		_sprite.scale = Vector3.ONE * lerpf(1.0, float(effects.get("shrink_end", 0.5)) / float(effects.get("shrink_start", 2.0)), _progress())
	if global_position.y <= radius * 0.5:
		_end(true)
		return
	for enemy: Enemy in dungeon.get_enemies():
		if not _hit.has(enemy) and enemy.hits(global_position, radius):
			_on_enemy(enemy)
			if _done:
				return
	if _has("shield") and not is_bomb:
		_block_enemy_shots()


## Funkenfänger: enemy shots touching this fireball are destroyed.
func _block_enemy_shots() -> void:
	for shot: Node in get_tree().get_nodes_in_group(EnemyShot.GROUP):
		if (shot as Node3D).global_position.distance_to(global_position) < radius + EnemyShot.RADIUS:
			(shot as EnemyShot).pop()


## How far along the reach the shot is, 0..1.
func _progress() -> float:
	return clampf(_traveled / maxf(reach, 0.1), 0.0, 1.0)


## Damage of a hit: "grow" up to grow_max times at the end of the reach, "shrink" down to
## shrink_end of its big start.
func hit_damage() -> float:
	var effects: Dictionary = Content.player().get("effects", {})
	var amount: float = damage * bonus
	if _has("grow"):
		amount *= lerpf(1.0, float(effects.get("grow_max", 2.0)), _progress())
	if _has("shrink"):
		amount *= lerpf(1.0, float(effects.get("shrink_end", 0.5)) / float(effects.get("shrink_start", 2.0)), _progress())
	return amount


## Homing, boomerang, dropping and the bomb arc change the velocity.
func _steer(delta: float) -> void:
	if is_bomb:
		velocity.y -= BOMB_GRAVITY * delta
	if _has("homing"):
		var target: Enemy = dungeon.nearest_enemy(global_position, HOMING_RANGE, _hit)
		if target:
			var want: Vector3 = (target.aim_point() - global_position).normalized() * velocity.length()
			if is_bomb:
				want.y = velocity.y
			velocity = velocity.lerp(want, clampf(HOMING_TURN * delta, 0.0, 1.0))
	if is_bomb:
		return
	if _has("boomerang"):
		if not _returning and _traveled >= reach:
			_returning = true
			_hit.clear()
		if _returning and player:
			var home: Vector3 = player.global_position + Vector3(0, 1.1, 0)
			velocity = velocity.lerp((home - global_position).normalized() * stats.shot_speed * 1.2, clampf(6.0 * delta, 0.0, 1.0))
			if global_position.distance_to(home) < 0.6:
				_end(false)
		return
	if _traveled >= reach and not _falling:
		_falling = true
		velocity.y = minf(velocity.y, -0.5)
	if _falling:
		velocity.y -= GRAVITY * delta


## Moves by `motion`, stopping at walls and rocks (bounce if it can). true if the shot ended.
func _move(motion: Vector3) -> bool:
	var from: Vector3 = global_position
	var to: Vector3 = from + motion + motion.normalized() * radius
	var mask: int = RoomBuilder.LAYER_WORLD if _has("spectral") and not is_bomb else RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = from + motion
		return false
	# A crate or barrel breaks, the shot ends there like at a rock.
	if hit.get("collider") is BreakableProp:
		dungeon.break_prop(hit["collider"] as BreakableProp)
		global_position = Vector3(hit["position"])
		_end(true)
		return true
	var normal: Vector3 = hit["normal"]
	# The floor is world too: landing there ends the shot.
	if normal.y > 0.7:
		global_position = hit["position"]
		_end(true)
		return true
	if _has("bounce") and _bounces_left > 0 and not is_bomb:
		_bounces_left -= 1
		velocity = velocity.bounce(normal)
		_side = velocity.normalized().cross(Vector3.UP).normalized()
		global_position = Vector3(hit["position"]) + normal * radius
		return false
	global_position = Vector3(hit["position"]) + normal * radius * 0.5
	_end(true)
	return true


func _on_enemy(enemy: Enemy) -> void:
	if is_bomb:
		_end(true)
		return
	# Mirror shield: the fireball flies back at the player as an enemy shot.
	if enemy.reflecting:
		var back: Vector3 = (player.global_position - global_position) * Vector3(1, 0, 1)
		enemy.shoot_from(global_position, back.normalized(), {"speed": 1.4})
		_end(false)
		return
	var push: Vector3 = velocity.normalized() * stats.knockback
	var amount: float = hit_damage()
	var hp_before: float = enemy.hp
	enemy.take_damage(amount, push, _has("bread"))
	enemy.afflict(flags, amount)
	_hit.append(enemy)
	# Overkill: a shot that kills flies on with the damage that was left.
	if _has("overkill") and not enemy.alive and amount > hp_before:
		damage *= (amount - hp_before) / amount
		return
	if _has("split") and not small:
		_split()
	if _has("explosive"):
		dungeon.explode(global_position, 1.0 + radius * 2.0, damage * 0.8, false)
	if not _has("pierce"):
		_end(false)


## Four sparks flying apart (left, right, back-left, back-right).
func _split() -> void:
	var forward: Vector3 = Vector3(velocity.x, 0, velocity.z).normalized()
	for angle: float in [70.0, -70.0, 140.0, -140.0]:
		dungeon.spawn_projectile(global_position, forward.rotated(Vector3.UP, deg_to_rad(angle)), stats, 0.0, true, _hit)


## The shot ends: bombs and explosive shots explode, fireballs go out with a puff.
func _end(on_ground: bool) -> void:
	if _done:
		return
	_done = true
	if is_bomb:
		var blast: float = (1.4 if small else 2.0) * stats.size * stats.bomb_size
		dungeon.explode(global_position, blast, damage * 2.5, false)
		if _has("split") and not small:
			for angle: float in [0.0, 120.0, 240.0]:
				var dir := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(angle + randf() * 40.0))
				dungeon.spawn_projectile(global_position + Vector3(0, 0.3, 0), dir * 0.5, stats, 0.0, true, [])
	elif _has("explosive") and on_ground:
		dungeon.explode(global_position, 1.0 + radius * 2.0, damage * 0.8, false)
	elif _has("burst") and on_ground and not small:
		var forward: Vector3 = Vector3(velocity.x, 0, velocity.z).normalized()
		for angle: float in [45.0, 135.0, 225.0, 315.0]:
			dungeon.spawn_projectile(global_position + Vector3(0, 0.4, 0), forward.rotated(Vector3.UP, deg_to_rad(angle)), stats, 0.0, true, [])
	else:
		Fx.puff(dungeon.effects, global_position, "fire", radius * 2.0)
	# Traps from items and relics (ShotStats.traps) lie where the shot ended (not the small sparks).
	if not small and not stats.traps.is_empty():
		dungeon.shot_ended(Vector3(global_position.x, 0.0, global_position.z), stats)
	queue_free()
