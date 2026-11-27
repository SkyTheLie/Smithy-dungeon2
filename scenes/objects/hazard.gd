class_name Hazard
extends Node3D
## A trap on the floor of a room (data/floors.json "hazard_types"): lava, a poison puddle, spikes or
## ice spikes. A square patch `size` metres wide, flat on the floor, in its colour (lava and poison
## glow and pulse a little). Spikes with a "cycle" [down, up] come out and go in again; they only
## hurt while they are up (a short warning shake before). Dungeon asks hurts_at() every physics
## frame and hits the player (Player.take_hit, so the usual invulnerable time after a hit counts).
## "hold" (seconds): a snare (Fangeisen). It snaps shut once when the player steps in, hurts and
## holds them for that long (Player.hold), then it lies open and harmless and fades away.
## "hidden": true = hard to see (faint patch, darker teeth); in tall grass it is almost invisible.
## `life` > 0 (set by a boss that throws it): after that many seconds it is gone (harmless).
## "decor" {sprite, frames, fps, height, count}: something that sits on a visible trap (pigeons
## pecking, world_props/city_7_walk); stepping into the trap scares them off (scare): they fly
## up and away and come back after "return" seconds. Never on hidden traps (they would show them).
## "owner": "player" = the player's own trap (from an item or relic: ShotStats.traps, the shot
## lays it where it ends, Dungeon.place_player_trap): it never hurts the player, only enemies
## (touch_enemy): "damage_mult" x the damage of the player's shot, at most every "every" seconds
## per enemy; with "hold" it snaps shut on the first enemy and stuns it that long. World traps
## (all others) never hurt enemies.
## Built in code, no scene. Timers run with _process, so they stop while the game is paused.

const SPIKE_ROWS: int = 3
const SPIKE_HEIGHT: float = 0.45
const WARN_TIME: float = 0.35
## Snare: number of teeth around the ring, how long it fades after use / at the end of its life.
const SNARE_TEETH: int = 8
const FADE_TIME: float = 0.6

var kind: String = "lava"
var data: Dictionary = {}
var size: float = 2.0
## Half hearts per hit.
var damage: int = 1

var _time: float = 0.0
var _floor_mat: StandardMaterial3D
var _spikes: Node3D
var _cycle: Array = []
## Seconds until a thrown snare is gone (0 = stays).
var life: float = 0.0
## Snare: snapped shut (harmless from then on); the teeth.
var _sprung: bool = false
var _spent: bool = false
var _teeth: Node3D
## The player's own trap: hurts enemies, never the player.
var from_player: bool = false
## Damage of the player's shot that laid it (touch_enemy multiplies it).
var shot_damage: float = 1.0
## Enemy instance id -> seconds until it can be hurt again.
var _enemy_wait: Dictionary[int, float] = {}
## "decor": the pigeons (one animated picture each) and the node that carries them.
var _decor: Node3D
var _decor_sprites: Array[Sprite3D] = []
var _decor_time: float = 0.0
## Seconds until scared pigeons come back (0 = they sit there).
var _decor_away: float = 0.0


## `type_data` = floors.json hazard_types[kind]; `side` = edge length in metres; `offset` = where
## in the cycle the spikes start (so not all of a room move together).
func setup(kind_name: String, type_data: Dictionary, side: float, offset: float) -> void:
	kind = kind_name
	data = type_data
	size = side
	damage = maxi(1, int(data.get("damage", 1)))
	_cycle = data.get("cycle", [])
	_time = offset
	from_player = String(data.get("owner", "")) == "player"


func _ready() -> void:
	var color_values: Array = data.get("color", [1.0, 0.4, 0.1])
	var color := Color(float(color_values[0]), float(color_values[1]), float(color_values[2]))
	if data.has("decor") and not is_hidden():
		_build_decor(data["decor"])
	if holds():
		_build_snare(color)
		return
	var patch := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	patch.mesh = plane
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_color = color.darkened(0.45) if has_cycle() else color
	if is_hidden():
		# Hard to see: a faint, see-through patch.
		_floor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_floor_mat.albedo_color.a = 0.25
	var glow: float = float(data.get("glow", 0.0))
	if glow > 0.0:
		_floor_mat.emission_enabled = true
		_floor_mat.emission = color
		_floor_mat.emission_energy_multiplier = glow
	patch.material_override = _floor_mat
	patch.position.y = 0.02
	add_child(patch)
	if has_cycle():
		_build_spikes(color)


func has_cycle() -> bool:
	return _cycle.size() == 2


## A snare: holds the player ("hold" seconds) instead of hurting again and again.
func holds() -> bool:
	return float(data.get("hold", 0.0)) > 0.0


func is_hidden() -> bool:
	return bool(data.get("hidden", false))


## true while the trap hurts: always for lava and poison, spikes only while they are up, a snare
## until it snapped shut (or its life ran out).
func is_dangerous() -> bool:
	if _spent or _sprung:
		return false
	if not has_cycle():
		return true
	return fmod(_time, _period()) >= float(_cycle[0])


## true if the player standing at `at` (world position, height ignored) gets hurt: a dangerous
## world trap under them (the player's own traps never hurt the player).
func hurts_at(at: Vector3) -> bool:
	return not from_player and is_dangerous() and covers(at, 0.0)


## true if a body at `at` with `reach` radius touches the square (height ignored).
func covers(at: Vector3, reach: float) -> bool:
	var local: Vector3 = at - global_position
	var half: float = size / 2.0 + reach
	return absf(local.x) <= half and absf(local.z) <= half


## The player's own trap meets `enemy` (Dungeon asks for every enemy of the room each physics
## frame): damage_mult x shot_damage, at most every "every" seconds per enemy; a snare snaps shut
## once and stuns it for "hold" seconds. Returns true if it hurt the enemy. Flying enemies and
## enemies under the ground are not caught.
func touch_enemy(enemy: Enemy) -> bool:
	if not from_player or not is_dangerous() or enemy == null or not enemy.alive or enemy.hidden_phase:
		return false
	if String(enemy.data.get("ai", "")) == "fly" or not covers(enemy.global_position, enemy.radius * 0.5):
		return false
	var key: int = enemy.get_instance_id()
	if _enemy_wait.get(key, 0.0) > 0.0:
		return false
	enemy.take_damage(shot_damage * float(data.get("damage_mult", 1.0)), Vector3.ZERO, false)
	if holds():
		_sprung = true
		enemy.stun_left = maxf(enemy.stun_left, float(data.get("hold", 1.0)))
		AudioManager.play_sound("blocked", 0.6)
		if _teeth:
			create_tween().tween_property(_teeth, "scale", Vector3(0.35, 1.3, 0.35), 0.08)
		var fade := create_tween()
		fade.tween_interval(float(data.get("hold", 1.0)) + 0.4)
		fade.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), FADE_TIME)
		fade.tween_callback(_vanish)
	else:
		_enemy_wait[key] = float(data.get("every", 0.5))
	return true


## Stepped in: the pigeons fly up and away and come back after decor "return" seconds.
func scare() -> void:
	if _decor == null or _decor_away > 0.0:
		return
	_decor_away = float((data.get("decor", {}) as Dictionary).get("return", 5.0))
	for sprite: Sprite3D in _decor_sprites:
		var away := Vector3(sprite.position.x, 0, sprite.position.z).normalized()
		if away.length() < 0.1:
			away = Vector3.RIGHT
		var fly := create_tween().set_parallel(true)
		fly.tween_property(sprite, "position", sprite.position + away * 3.0 + Vector3(0, 3.5, 0), 0.9).set_ease(Tween.EASE_OUT)
		fly.tween_property(sprite, "modulate:a", 0.0, 0.9)


func is_scared() -> bool:
	return _decor_away > 0.0


func _period() -> float:
	return maxf(0.1, float(_cycle[0]) + float(_cycle[1]))


## A snare snaps shut on `player`: one hit and held for "hold" seconds. Then it fades away.
func spring(player: Player) -> void:
	if not holds() or _sprung or _spent:
		return
	_sprung = true
	player.take_hit(damage)
	player.hold(float(data.get("hold", 1.0)))
	AudioManager.play_sound("blocked", 0.6)
	if _teeth:
		var snap := create_tween()
		snap.tween_property(_teeth, "scale", Vector3(0.35, 1.3, 0.35), 0.08)
	var fade := create_tween()
	fade.tween_interval(float(data.get("hold", 1.0)) + 0.4)
	fade.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), FADE_TIME)
	fade.tween_callback(_vanish)


func _process(delta: float) -> void:
	_time += delta
	for key: int in _enemy_wait.keys():
		_enemy_wait[key] -= delta
		if _enemy_wait[key] <= 0.0:
			_enemy_wait.erase(key)
	if _decor:
		_animate_decor(delta)
	if life > 0.0 and not _spent and _time >= life:
		_spent = true
		var fade := create_tween()
		fade.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), FADE_TIME)
		fade.tween_callback(_vanish)
	if holds() or _floor_mat == null:
		return
	if has_cycle():
		_move_spikes()
	elif _floor_mat.emission_enabled:
		_floor_mat.emission_energy_multiplier = float(data.get("glow", 0.0)) * (0.8 + 0.2 * sin(_time * 2.5))


## Used up: harmless and hidden.
func _vanish() -> void:
	_spent = true
	visible = false


## "decor": `count` animated pictures (sprite sheet with `frames` pictures side by side) standing
## on the patch, each starting at another frame.
func _build_decor(decor: Dictionary) -> void:
	var texture := load(String(decor.get("sprite", ""))) as Texture2D
	if texture == null:
		return
	_decor = Node3D.new()
	add_child(_decor)
	var frames: int = maxi(1, int(decor.get("frames", 1)))
	var height: float = float(decor.get("height", 0.6))
	var count: int = maxi(1, int(decor.get("count", 1)))
	for i in count:
		var sprite: Sprite3D = Fx.billboard(texture, height)
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.hframes = frames
		# A sheet frame is as wide as tall: pixel_size from one frame, not the whole sheet.
		sprite.pixel_size = height / float(texture.get_height())
		sprite.frame = (i * 2) % frames
		var angle: float = TAU * i / count + 0.6
		var spread: float = 0.0 if count == 1 else size * 0.22
		sprite.position = Vector3(cos(angle) * spread, height / 2.0, sin(angle) * spread)
		_decor.add_child(sprite)
		_decor_sprites.append(sprite)


func _animate_decor(delta: float) -> void:
	var decor: Dictionary = data.get("decor", {})
	if _decor_away > 0.0:
		_decor_away -= delta
		if _decor_away <= 0.0:
			_land_decor()
		return
	_decor_time += delta
	var frames: int = maxi(1, int(decor.get("frames", 1)))
	var step: int = int(_decor_time * float(decor.get("fps", 6.0)))
	for i in _decor_sprites.size():
		_decor_sprites[i].frame = (step + i * 2) % frames


## Back from flying away: the pigeons land on their places again.
func _land_decor() -> void:
	_decor_away = 0.0
	var height: float = float((data.get("decor", {}) as Dictionary).get("height", 0.6))
	var count: int = _decor_sprites.size()
	for i in count:
		var sprite: Sprite3D = _decor_sprites[i]
		var angle: float = TAU * i / count + 0.6
		var spread: float = 0.0 if count == 1 else size * 0.22
		var land := create_tween().set_parallel(true)
		land.tween_property(sprite, "position", Vector3(cos(angle) * spread, height / 2.0, sin(angle) * spread), 0.8).set_ease(Tween.EASE_IN_OUT)
		land.tween_property(sprite, "modulate:a", 1.0, 0.5)


## A snare: a flat dark ring on the floor with a circle of teeth standing up (they snap together).
func _build_snare(color: Color) -> void:
	var plate := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = size * 0.45
	disc.bottom_radius = size * 0.45
	disc.height = 0.03
	disc.radial_segments = 12
	plate.mesh = disc
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = color.darkened(0.55 if is_hidden() else 0.3)
	plate_mat.metallic = 0.5
	plate.material_override = plate_mat
	plate.position.y = 0.02
	add_child(plate)
	_teeth = Node3D.new()
	add_child(_teeth)
	var tooth := CylinderMesh.new()
	tooth.top_radius = 0.0
	tooth.bottom_radius = 0.05
	tooth.height = 0.22
	tooth.radial_segments = 4
	var tooth_mat := StandardMaterial3D.new()
	tooth_mat.albedo_color = color.darkened(0.35) if is_hidden() else color.lightened(0.2)
	tooth_mat.metallic = 0.7
	tooth.material = tooth_mat
	for i in SNARE_TEETH:
		var spike := MeshInstance3D.new()
		spike.mesh = tooth
		var angle: float = TAU * i / SNARE_TEETH
		spike.position = Vector3(cos(angle), 0, sin(angle)) * size * 0.38 + Vector3(0, 0.11, 0)
		_teeth.add_child(spike)


## A grid of thin cones on the patch.
func _build_spikes(color: Color) -> void:
	_spikes = Node3D.new()
	add_child(_spikes)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.09
	mesh.height = SPIKE_HEIGHT
	mesh.radial_segments = 6
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.6
	var glow: float = float(data.get("glow", 0.0))
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	mesh.material = material
	var step: float = size / SPIKE_ROWS
	for x in SPIKE_ROWS:
		for z in SPIKE_ROWS:
			var spike := MeshInstance3D.new()
			spike.mesh = mesh
			spike.position = Vector3(-size / 2.0 + step * (x + 0.5), SPIKE_HEIGHT / 2.0, -size / 2.0 + step * (z + 0.5))
			_spikes.add_child(spike)
	_move_spikes()


## Down: hidden in the floor; a short shake just before they come out; up: out.
func _move_spikes() -> void:
	var at: float = fmod(_time, _period())
	var down: float = float(_cycle[0])
	if at >= down:
		_spikes.position.y = 0.0
	elif at >= down - WARN_TIME:
		_spikes.position.y = -SPIKE_HEIGHT * 0.75 + sin(_time * 60.0) * 0.03
	else:
		_spikes.position.y = -SPIKE_HEIGHT
