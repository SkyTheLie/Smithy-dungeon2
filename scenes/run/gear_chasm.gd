class_name GearChasm
extends DungeonRoom
## Die Räderkluft: a boss hall over a deep chasm (data/gear_chasm.json). There is no floor, only
## platforms; stepping off them means falling (half a heart, then back on the last fixed ground).
##
## Seen from above (north = -z = up):
##                 [ door ]
##                 (outer)
##                 (inner)
##   [door](outer)(inner)[ center ](inner)(outer)[door]
##                 (inner)
##                 (outer)
##                 [ door ]
##   - fixed: the big center platform with the boss dais in its middle (the boss stands there
##     later and never moves) and four door platforms at the walls, where the player comes in;
##   - inner ring: four platforms that travel on a rail around the center, counter-clockwise;
##   - outer ring: four platforms on a bigger rail around the inner ring, clockwise.
## The rails are rectangles: every platform is right next to the one inside it while both are in
## the middle of the same side. Both rings take `period` seconds for a whole lap, so every
## period/4 seconds a way from every door to the center lines up (door, outer, inner, center).
## A platform carries the player standing on it; a flying player (Player.flying) never falls. Walking from one platform to another works
## wherever they touch (the gap between neighbours is `gap`, the player may stand `reach` over an
## edge). Dungeon builds the hall the first time (enter_gear_chasm), calls tick() every physics
## frame while the player is in it, and on_leave() when they are taken out.
## End hall of a dungeon (dungeons.json "end_room": "gear_chasm"): the portal after the boss of
## the last floor leads here, the end boss stands on the dais and never moves (Enemy.pinned, kept
## there by tick). The dais blocks only the player (DAIS_LAYER), not shots. Helpers the boss calls
## stay on the platforms (they ride along and cannot step into the chasm). After the boss
## (on_cleared) the dais is free and the golden light stands on the center (Dungeon).

const TYPE: String = "gear_chasm"
const GATE_HEIGHT: float = 3.4
const PLATFORM_THICK: float = 0.6
## The rails hang this far under the platforms.
const RAIL_Y: float = -1.3
const RAIL_SIZE: float = 0.3
## Where the player comes back after a fall: this far inside the edge of the fixed platform.
const SAFE_MARGIN: float = 0.6
## Physics layer of the invisible block on the dais: only the player collides with it (while in
## the hall), so shots still reach the boss.
const DAIS_LAYER: int = 16

enum Ring { FIXED, OUTER, INNER }


## One platform: its node, half its size (x, z), its ring, where on the rail it starts
## (0..1 of a lap) and its place (local x, z) now and in the frame before.
class Platform:
	var node: Node3D
	var half: Vector2
	var ring: int
	var start: float = 0.0
	var at: Vector2 = Vector2.ZERO
	var before: Vector2 = Vector2.ZERO

	func holds(point: Vector2, reach: float) -> bool:
		var offset: Vector2 = (point - at).abs()
		return offset.x <= half.x + reach and offset.y <= half.y + reach


var dungeon: Dungeon
var player: Player
var settings: Dictionary = {}
## Half the size of the hall inside its walls (x, z).
var half: Vector2 = Vector2.ZERO
var platforms: Array[Platform] = []
## true while the player falls (no walking, platforms keep turning).
var falling: bool = false

## Half the size of the two rail rectangles (x, z).
var _inner_path: Vector2 = Vector2.ZERO
var _outer_path: Vector2 = Vector2.ZERO
var _period: float = 48.0
var _reach: float = 0.3
## Seconds on the clock of the rings (at 0 every way to the center is open).
var _time: float = 0.0
## The platform under the player in the last frame (null = none).
var _standing: Platform = null
## Last place on fixed ground (world): where the player comes back after a fall.
var _safe_spot: Vector3 = Vector3.ZERO
var _fall_tween: Tween = null
var _materials: Dictionary[String, StandardMaterial3D] = {}
var _dais_block: StaticBody3D = null
## Enemy instance id -> the platform it stood on in the last frame.
var _enemy_on: Dictionary[int, Platform] = {}


# --- Building ---------------------------------------------------------------------------

func setup(the_dungeon: Dungeon, the_player: Player, at_cell: Vector2i) -> void:
	dungeon = the_dungeon
	player = the_player
	settings = Content.get_file("gear_chasm")
	cell = at_cell
	type = TYPE
	name = "GearChasm"
	_period = maxf(1.0, float(settings.get("period", 48.0)))
	_reach = float(settings.get("reach", 0.3))
	var center: Vector2 = _pair("center")
	var piece: Vector2 = _pair("platform")
	var door: Vector2 = _pair("door")
	var gap: float = float(settings.get("gap", 0.2))
	_inner_path = center + Vector2(gap, gap) + piece
	_outer_path = _inner_path + (piece + Vector2(gap, gap) / 2.0) * 2.0
	half = _outer_path + piece + Vector2(gap, gap) + Vector2(door.y, door.y) * 2.0


func _ready() -> void:
	position = RoomBuilder.cell_center(cell)
	_build_walls()
	_build_abyss()
	_build_rails(_inner_path, "inner")
	_build_rails(_outer_path, "outer")
	_build_fixed()
	for i in 4:
		_add_platform(Ring.INNER, i / 4.0)
		_add_platform(Ring.OUTER, i / 4.0)
	_move_platforms()


## [x, z] from the settings as a Vector2.
func _pair(key: String) -> Vector2:
	var list: Array = settings.get(key, [1.0, 1.0])
	return Vector2(float(list[0]), float(list[1]))


func _color(key: String) -> Color:
	var list: Array = (settings.get("colors", {}) as Dictionary).get(key, [1.0, 1.0, 1.0])
	return Color(float(list[0]), float(list[1]), float(list[2]))


## A texture repeated along the piece itself (not the world), so it moves with the platform.
func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(String((settings.get("textures", {}) as Dictionary).get(key, ""))) as Texture2D
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.uv1_triplanar = true
	material.uv1_scale = Vector3(1.0, 1.0, 1.0) / 1.5
	material.roughness = 1.0
	_materials[key] = material
	return material


## Four walls around the hall, reaching down into the chasm, and a gate behind each door.
func _build_walls() -> void:
	var height: float = float(settings.get("wall_height", 6.0))
	var depth: float = float(settings.get("abyss_depth", 18.0))
	var material := RoomBuilder.tiled_material(String(settings.get("wall_texture", "")), Vector3(2.0, 3.0, 2.0))
	var outer: Vector2 = half + Vector2(RoomBuilder.WALL_T, RoomBuilder.WALL_T)
	var mid_y: float = (height - depth) / 2.0
	for side: float in [-1.0, 1.0]:
		RoomBuilder.box(self, Vector3(outer.x * 2.0, height + depth, RoomBuilder.WALL_T), Vector3(0, mid_y, side * (outer.y - RoomBuilder.WALL_T / 2.0)), material, RoomBuilder.LAYER_WORLD)
		RoomBuilder.box(self, Vector3(RoomBuilder.WALL_T, height + depth, outer.y * 2.0), Vector3(side * (outer.x - RoomBuilder.WALL_T / 2.0), mid_y, 0), material, RoomBuilder.LAYER_WORLD)
	var gate_texture := load(String(settings.get("gate", ""))) as Texture2D
	var torch_color: Color = _color("fixed")
	# Direction into the wall -> turn of the gate picture so it faces into the hall.
	var sides: Dictionary[Vector2i, float] = {Vector2i(0, -1): 0.0, Vector2i(0, 1): PI, Vector2i(1, 0): -PI / 2.0, Vector2i(-1, 0): PI / 2.0}
	for dir: Vector2i in sides:
		var wall := Vector3(dir.x * (half.x - 0.02), 0.0, dir.y * (half.y - 0.02))
		var gate := Fx.billboard(gate_texture, GATE_HEIGHT)
		gate.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		gate.rotation.y = sides[dir]
		gate.position = wall + Vector3(0, GATE_HEIGHT / 2.0, 0)
		add_child(gate)
		var along := Vector3(absf(dir.y), 0, absf(dir.x))
		for side: float in [-1.0, 1.0]:
			var torch_at: Vector3 = Vector3(dir.x * (half.x - 0.12), 2.3, dir.y * (half.y - 0.12)) + along * side * 2.6
			RoomBuilder.torch(self, torch_at, torch_color)


## The glowing ground far down in the chasm.
func _build_abyss() -> void:
	var depth: float = float(settings.get("abyss_depth", 18.0))
	var color: Color = _color("abyss")
	RoomBuilder.box(self, Vector3(half.x * 2.0, 0.5, half.y * 2.0), Vector3(0, -depth, 0), RoomBuilder.color_material(color, 0.8), 0)
	for x: float in [-half.x * 0.5, half.x * 0.5]:
		for z: float in [-half.y * 0.5, half.y * 0.5]:
			var light := OmniLight3D.new()
			light.light_color = color
			light.light_energy = 2.0
			light.omni_range = depth * 0.8
			light.position = Vector3(x, -depth + 2.0, z)
			add_child(light)


## The dark rail (a rectangle) the platforms of one ring ride on.
func _build_rails(path: Vector2, ring_key: String) -> void:
	var material := RoomBuilder.tiled_material(String(settings.get("rail_texture", "")), Vector3(1.5, 1.5, 1.5))
	var glow := RoomBuilder.color_material(_color(ring_key), 0.5)
	for side: float in [-1.0, 1.0]:
		RoomBuilder.box(self, Vector3(path.x * 2.0 + RAIL_SIZE, RAIL_SIZE, RAIL_SIZE), Vector3(0, RAIL_Y, side * path.y), material, 0)
		RoomBuilder.box(self, Vector3(RAIL_SIZE, RAIL_SIZE, path.y * 2.0 + RAIL_SIZE), Vector3(side * path.x, RAIL_Y, 0), material, 0)
		# A thin glowing line on top of the rail, in the colour of its ring.
		RoomBuilder.box(self, Vector3(path.x * 2.0, 0.04, 0.08), Vector3(0, RAIL_Y + RAIL_SIZE / 2.0, side * path.y), glow, 0)
		RoomBuilder.box(self, Vector3(0.08, 0.04, path.y * 2.0), Vector3(side * path.x, RAIL_Y + RAIL_SIZE / 2.0, 0), glow, 0)


## The center with the boss dais and the four door platforms.
func _build_fixed() -> void:
	var center := _make_platform(Ring.FIXED, _pair("center"), "fixed")
	center.at = Vector2.ZERO
	# The boss dais: a red block in the middle that nobody walks through.
	var dais: Vector2 = _pair("dais")
	var height: float = float(settings.get("dais_height", 0.6))
	RoomBuilder.box(center.node, Vector3(dais.x * 2.0, height, dais.y * 2.0), Vector3(0, height / 2.0, 0), _material("dais"), 0)
	_dais_block = StaticBody3D.new()
	_dais_block.collision_layer = DAIS_LAYER
	_dais_block.collision_mask = 0
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(dais.x * 2.0, 3.0, dais.y * 2.0)
	shape.shape = block
	shape.position.y = 1.5
	_dais_block.add_child(shape)
	center.node.add_child(_dais_block)
	RoomBuilder.box(center.node, Vector3(dais.x * 2.0 + 0.1, 0.1, dais.y * 2.0 + 0.1), Vector3(0, height - 0.05, 0), RoomBuilder.color_material(_color("dais"), 1.5), 0)
	var light := OmniLight3D.new()
	light.light_color = _color("dais")
	light.light_energy = 1.6
	light.omni_range = 9.0
	light.position = Vector3(0, 3.5, 0)
	center.node.add_child(light)
	var door: Vector2 = _pair("door")
	for dir: Vector2i in FloorLayout.DIRECTIONS:
		var size: Vector2 = door if dir.x == 0 else Vector2(door.y, door.x)
		var piece := _make_platform(Ring.FIXED, size, "fixed")
		piece.at = Vector2(dir.x * (half.x - size.x), dir.y * (half.y - size.y))


func _add_platform(ring: int, start: float) -> void:
	var piece := _make_platform(ring, _pair("platform"), "inner" if ring == Ring.INNER else "outer")
	piece.start = start
	# A post down to the rail and a small light in the colour of the ring.
	RoomBuilder.box(piece.node, Vector3(0.35, -RAIL_Y - PLATFORM_THICK, 0.35), Vector3(0, (RAIL_Y - PLATFORM_THICK) / 2.0, 0), RoomBuilder.tiled_material(String(settings.get("rail_texture", "")), Vector3(1.5, 1.5, 1.5)), 0)
	var light := OmniLight3D.new()
	light.light_color = _color("inner" if ring == Ring.INNER else "outer")
	light.light_energy = 0.6
	light.omni_range = 3.5
	light.position = Vector3(0, 1.2, 0)
	piece.node.add_child(light)


## A platform: its top is the floor (height 0), with a glowing edge in its colour under the top.
func _make_platform(ring: int, size: Vector2, key: String) -> Platform:
	var piece := Platform.new()
	piece.ring = ring
	piece.half = size
	piece.node = Node3D.new()
	add_child(piece.node)
	RoomBuilder.box(piece.node, Vector3(size.x * 2.0, PLATFORM_THICK, size.y * 2.0), Vector3(0, -PLATFORM_THICK / 2.0, 0), _material(key), 0)
	RoomBuilder.box(piece.node, Vector3(size.x * 2.0 + 0.08, 0.1, size.y * 2.0 + 0.08), Vector3(0, -PLATFORM_THICK + 0.1, 0), RoomBuilder.color_material(_color(key), 1.2), 0)
	platforms.append(piece)
	return piece


# --- Rails ------------------------------------------------------------------------------

## A point on the rail rectangle with half size `path`: `lap` 0 = middle of the north side, then
## clockwise seen from above (east, south, west), 1 = round again.
static func path_point(path: Vector2, lap: float) -> Vector2:
	var walked: float = fposmod(lap, 1.0) * 4.0 * (path.x + path.y)
	if walked < path.x:
		return Vector2(walked, -path.y)
	walked -= path.x
	if walked < path.y * 2.0:
		return Vector2(path.x, -path.y + walked)
	walked -= path.y * 2.0
	if walked < path.x * 2.0:
		return Vector2(path.x - walked, path.y)
	walked -= path.x * 2.0
	if walked < path.y * 2.0:
		return Vector2(-path.x, path.y - walked)
	walked -= path.y * 2.0
	return Vector2(-path.x + walked, -path.y)


## Puts every moving platform where the clock says (the fixed ones stay).
func _move_platforms() -> void:
	var turned: float = _time / _period
	for piece: Platform in platforms:
		piece.before = piece.at
		if piece.ring == Ring.OUTER:
			piece.at = path_point(_outer_path, piece.start + turned)
		elif piece.ring == Ring.INNER:
			piece.at = path_point(_inner_path, piece.start - turned)
		piece.node.position = Vector3(piece.at.x, 0.0, piece.at.y)


## The platform that holds a point (local x, z): the one the player stood on first, so they stay
## on it where two touch. null = nothing there (the chasm).
func platform_at(point: Vector2) -> Platform:
	if _standing and _standing.holds(point, _reach):
		return _standing
	for piece: Platform in platforms:
		if piece.holds(point, _reach):
			return piece
	return null


func platforms_of(ring: int) -> Array[Platform]:
	var list: Array[Platform] = []
	for piece: Platform in platforms:
		if piece.ring == ring:
			list.append(piece)
	return list


# --- Playing ----------------------------------------------------------------------------

## Walkable area (world x, z), `margin` metres from the walls (bombs, blink stay inside).
func inner_rect(margin: float) -> Rect2:
	var center := Vector2(global_position.x, global_position.z)
	var inside: Vector2 = half - Vector2(margin, margin)
	return Rect2(center - inside, inside * 2.0)


## On the south door platform, looking north at the center.
func arrival_point() -> Vector3:
	var door: Vector2 = _pair("door")
	return global_position + Vector3(0, 0, half.y - door.y)


## Where the end boss stands: the middle of the dais.
func boss_spot() -> Vector3:
	return global_position


## The player came in: the clock starts so that the first way opens after `wait_at_start`.
func on_enter() -> void:
	_time = -float(settings.get("wait_at_start", 4.0))
	_move_platforms()
	_standing = null
	_safe_spot = arrival_point()
	if _dais_block:
		player.collision_mask |= DAIS_LAYER
	AudioManager.play_music(String(settings.get("music", "")))


## The end boss is beaten: the dais is free (the rewards stand on the center).
func on_cleared() -> void:
	if _dais_block:
		_dais_block.queue_free()
		_dais_block = null
	player.collision_mask &= ~DAIS_LAYER


## The player is taken out (admin menu, test room): stop a fall that is still going on.
func on_leave() -> void:
	player.collision_mask &= ~DAIS_LAYER
	if not falling:
		return
	falling = false
	if _fall_tween:
		_fall_tween.kill()
	player.global_position.y = 0.0
	player.set_physics_process(true)
	player.controls_enabled = true


## Every physics frame while the player is in the hall (Dungeon): turns the rings, carries the
## player along with the platform under them, and lets them fall where there is none.
func tick(delta: float) -> void:
	var feet := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z)
	var under: Platform = null if falling else platform_at(feet)
	_time += delta
	_move_platforms()
	_keep_enemies()
	if falling:
		return
	if under == null:
		# Flying (fly, ghost items): over the chasm without falling.
		if player.flying():
			_standing = null
			return
		_fall()
		return
	_standing = under
	if under.ring == Ring.FIXED:
		var low: Vector2 = under.at - under.half + Vector2(SAFE_MARGIN, SAFE_MARGIN)
		var high: Vector2 = under.at + under.half - Vector2(SAFE_MARGIN, SAFE_MARGIN)
		_safe_spot = global_position + Vector3(clampf(feet.x, low.x, high.x), 0.0, clampf(feet.y, low.y, high.y))
	else:
		var moved: Vector2 = under.at - under.before
		player.global_position += Vector3(moved.x, 0.0, moved.y)


## The boss stays on the dais; every other enemy rides along with its platform and may only step
## onto another one where they touch (never into the chasm). One that stands over the chasm
## without having stood on a platform falls (dies).
func _keep_enemies() -> void:
	var alive: Dictionary[int, Platform] = {}
	for enemy: Enemy in dungeon.enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if enemy.pinned:
			enemy.global_position = boss_spot()
			continue
		var key: int = enemy.get_instance_id()
		var last: Platform = _enemy_on.get(key)
		if last and last.ring != Ring.FIXED:
			var moved: Vector2 = last.at - last.before
			enemy.global_position += Vector3(moved.x, 0.0, moved.y)
		var feet := Vector2(enemy.global_position.x - global_position.x, enemy.global_position.z - global_position.z)
		var under: Platform = null
		if last and last.holds(feet, 0.0):
			under = last
		else:
			for piece: Platform in platforms:
				if piece.holds(feet, _reach):
					under = piece
					break
		if under == null and last:
			# Would step into the chasm: stays on the edge of its platform.
			under = last
			var low: Vector2 = last.at - last.half
			var high: Vector2 = last.at + last.half
			enemy.global_position = global_position + Vector3(clampf(feet.x, low.x, high.x), 0.0, clampf(feet.y, low.y, high.y))
		if under == null:
			enemy.take_damage(Enemy.FORCED_DAMAGE, Vector3.ZERO, false)
			continue
		alive[key] = under
	_enemy_on = alive


## Off the platforms: down into the chasm, half a heart (fall_damage), back on fixed ground.
func _fall() -> void:
	falling = true
	_standing = null
	player.controls_enabled = false
	player.velocity = Vector3.ZERO
	# The player's own movement keeps them at height 0; it stops while they fall.
	player.set_physics_process(false)
	AudioManager.play_sound("rope_fall", 0.7)
	_fall_tween = create_tween()
	_fall_tween.tween_property(player, "global_position:y", -float(settings.get("fall_depth", 9.0)), float(settings.get("fall_time", 0.7))).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _fall_tween.finished
	if not falling or not is_inside_tree():
		return
	falling = false
	var run: RunState = dungeon.run
	if run.take_damage(int(settings.get("fall_damage", 1))):
		AudioManager.play_sound("player_hurt")
		player.hurt.emit()
	player.global_position = _safe_spot
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	if run.is_dead():
		return
	player.invulnerable = maxf(player.invulnerable, Player.INVULNERABLE_TIME)
	player.controls_enabled = true
	Fx.puff(dungeon.effects, _safe_spot + Vector3(0, 1.0, 0), "spark", 1.2)
