class_name Dungeon
extends Node3D
## One floor of the dungeon in 3D. build() makes a FloorLayout (data/floors.json) and builds every
## room side by side, with doors between neighbours. While the player walks around it:
##   - entering a room with enemies closes its doors and lets the enemies appear;
##   - when the last one falls the doors open and sometimes a reward drops;
##   - item room: one item on a pedestal; shop: an item and goods for coins;
##   - boss room: one boss of the theme, picked at random when the floor is built; after it a
##     trapdoor down (or the golden light after the last floor) and a boss item.
## Only the room the player is in and its neighbours are visible (drawn); the rest is hidden.
## Extra rooms (FloorLayout.add_extras): a secret room behind a wall that a bomb blows open
## (secret items), sometimes a sacrifice room (Opferstein: a heart for a reward) and the special
## room behind the boss: after the boss it may open as Glutpakt (items for heart containers) or
## Schrein (a free item), see RunState.roll_special_room.
## Rules about life, coins and items are in RunState; this node only calls them.
##
## Test room (P, only in debug builds): a closed room far away from the floor with every item on a
## pedestal and a red pedestal that drops all items again, to try out items and synergies.

signal floor_started(name: String)
signal room_entered(cell: Vector2i)
signal boss_appeared(boss: Enemy)
signal boss_defeated
signal trapdoor_entered(final: bool)
## A short text for the HUD (German key).
signal message(text: String)

const SPAWN_MIN_DISTANCE: float = 3.5
const MAX_ENEMIES: int = 12
const DOOR_TOUCH: float = 1.7
const KEEPER_HEIGHT: float = 1.6
## Far outside the floor grid (FloorLayout uses 0..8), so no room is next to it.
const TEST_CELL: Vector2i = Vector2i(-10, -10)
## 8 columns x 3 rows = one page of items; "Nächste Seite" shows the next ones.
const TEST_COLUMNS: int = 8
const TEST_ROWS: int = 3
const TEST_SPACING := Vector2(1.6, 2.0)
const TEST_FIRST_ROW: float = -4.0
## A bomb this close to a hidden wall blows it open.
const SECRET_BLAST_REACH: float = 1.2
const SACRIFICE_STEP: float = 0.7

var run: RunState
var player: Player
var layout: FloorLayout
var floor_data: Dictionary = {}
var floor_index: int = 0
var rooms: Dictionary[Vector2i, DungeonRoom] = {}
var doors: Array[Door] = []
var current_cell: Vector2i = FloorLayout.START
## The boss of this floor (random from the theme's "bosses").
var boss_id: String = ""
## Alive enemies of the room the player is in.
var enemies: Array[Enemy] = []
var boss: Enemy = null
## Shots, bombs, explosions and effects go here.
var effects: Node3D

var _rng := RandomNumberGenerator.new()
var _fighting: bool = false
## Locked door the player was told about (so the message comes once per approach).
var _warned_door: Door = null
## Test room: built on the first P; where the player came from.
var _test_room: DungeonRoom = null
var _test_pedestals: Array[Pedestal] = []
var _test_ids: Array[String] = []
var _test_page: int = 0
var _return_cell: Vector2i = FloorLayout.START
var _return_position: Vector3 = Vector3.ZERO
## Sacrifice room: the stone, how often it was used on this floor, and "step off first".
var _sacrifice_stone: Node3D = null
var _sacrifices: int = 0
var _on_stone: bool = false


func build(run_state: RunState, the_player: Player, index: int) -> void:
	run = run_state
	player = the_player
	floor_index = index
	floor_data = Content.floor_data(index)
	_rng.seed = hash(run.seed_value + index * 7919)
	layout = FloorLayout.generate(_rng, int(floor_data.get("rooms", 7)))
	# Extra rooms with their own random numbers: the normal rooms stay the same for a seed.
	var extra_rng := RandomNumberGenerator.new()
	extra_rng.seed = hash(run.seed_value * 31 + index * 104729)
	layout.add_extras(extra_rng, float((Content.floors_extra("sacrifice") as Dictionary).get("room_chance", 0.5)))
	effects = Node3D.new()
	effects.name = "Effects"
	add_child(effects)
	for cell: Vector2i in layout.rooms:
		_build_room(cell)
	_build_doors()
	# After the rooms, so the rooms come out the same for a seed whatever bosses there are.
	# A boss that did not come yet in this run (the floors of a theme share their bosses).
	var bosses: Array = floor_data.get("bosses", ["rat_king"])
	var fresh: Array = bosses.filter(func(id: Variant) -> bool: return not run.fought_bosses.has(String(id)))
	if fresh.is_empty():
		fresh = bosses
	boss_id = String(fresh[_rng.randi_range(0, fresh.size() - 1)])
	if not run.fought_bosses.has(boss_id):
		run.fought_bosses.append(boss_id)
	player.global_position = RoomBuilder.cell_center(FloorLayout.START) + Vector3(0, 0, 1.0)
	_enter_room(FloorLayout.START)
	run.blue_heart_lost.connect(_on_blue_heart_lost)
	run.revived.connect(func(_id: String) -> void: message.emit("Ein zweites Leben!"))
	run.item_added.connect(_on_item_added)
	AudioManager.play_music(String(floor_data.get("music", "")))
	floor_started.emit(String(floor_data.get("name", "")))


func get_enemies() -> Array[Enemy]:
	return enemies


func get_room(cell: Vector2i) -> DungeonRoom:
	return rooms.get(cell)


## Rooms on the map: the visited ones, the rooms next to them (through doors that are not
## hidden) and always the boss room. The rest of the floor stays unknown.
func known_cells() -> Array[Vector2i]:
	var known: Array[Vector2i] = []
	for cell: Vector2i in layout.rooms:
		if rooms[cell].visited:
			if not known.has(cell):
				known.append(cell)
		if not rooms[cell].visited:
			continue
		for door: Door in doors_of(cell):
			var other: Vector2i = door.cells[0] if door.cells[1] == cell else door.cells[1]
			if not door.hidden and not known.has(other):
				known.append(other)
	return known


func is_fighting() -> bool:
	return _fighting


## Doors that touch `cell`.
func doors_of(cell: Vector2i) -> Array[Door]:
	var list: Array[Door] = []
	for door: Door in doors:
		if door.cells.has(cell):
			list.append(door)
	return list


func nearest_enemy(from: Vector3, max_distance: float, skip: Array) -> Enemy:
	var best: Enemy = null
	var best_distance: float = max_distance
	for enemy: Enemy in enemies:
		if skip.has(enemy) or enemy.hidden_phase:
			continue
		var distance: float = from.distance_to(enemy.aim_point())
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


# --- Building ---------------------------------------------------------------------

func _build_room(cell: Vector2i) -> void:
	var room := DungeonRoom.new()
	room.cell = cell
	room.type = layout.get_type(cell)
	room.name = "Room_%d_%d" % [cell.x, cell.y]
	room.position = RoomBuilder.cell_center(cell)
	add_child(room)
	rooms[cell] = room
	var neighbours: Dictionary[Vector2i, String] = {}
	for dir: Vector2i in FloorLayout.DIRECTIONS:
		if layout.rooms.has(cell + dir):
			var other: String = layout.get_type(cell + dir)
			# Special rooms show their colour on both sides of the door; hidden doorways none.
			if other in FloorLayout.HIDDEN_TYPES or room.type in FloorLayout.HIDDEN_TYPES:
				neighbours[dir] = ""
			else:
				neighbours[dir] = other if other in ["boss", "item", "shop"] else room.type
	var style: Dictionary = (Content.floors_extra("room_styles") as Dictionary).get(room.type, {})
	var light: Array = floor_data.get("light", [1.0, 0.75, 0.5])
	RoomBuilder.build_shell(room,
			String(style.get("floor_texture", floor_data.get("floor_texture", ""))),
			String(style.get("wall_texture", floor_data.get("wall_texture", ""))),
			neighbours, Color(float(light[0]), float(light[1]), float(light[2])))
	match room.type:
		FloorLayout.START_ROOM:
			_add_controls_hint(room)
		FloorLayout.NORMAL:
			_add_rocks(room)
			_roll_enemies(room)
		FloorLayout.ITEM:
			_add_item_pedestal(room, Vector3.ZERO, "item", 0)
		FloorLayout.SHOP:
			_build_shop(room)
		FloorLayout.SECRET:
			_build_secret_room(room)
		FloorLayout.SACRIFICE:
			_build_sacrifice_room(room)


## The wall picture of the room at `cell` (room style or floor).
func _wall_texture_of(cell: Vector2i) -> String:
	var style: Dictionary = (Content.floors_extra("room_styles") as Dictionary).get(layout.get_type(cell), {})
	return String(style.get("wall_texture", floor_data.get("wall_texture", "")))


## One door per pair of neighbouring rooms; doors to rooms in "key_doors" are locked.
func _build_doors() -> void:
	var key_doors: Array = floor_data.get("key_doors", [])
	for cell: Vector2i in layout.rooms:
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
			var other: Vector2i = cell + dir
			if not layout.rooms.has(other):
				continue
			var door := Door.new()
			var locked: bool = key_doors.has(layout.get_type(cell)) or key_doors.has(layout.get_type(other))
			door.hidden = layout.get_type(cell) in FloorLayout.HIDDEN_TYPES or layout.get_type(other) in FloorLayout.HIDDEN_TYPES
			door.wall_textures = [_wall_texture_of(cell), _wall_texture_of(other)]
			door.setup(cell, other, locked and not door.hidden)
			door.name = "Door_%d_%d_%d_%d" % [cell.x, cell.y, other.x, other.y]
			add_child(door)
			doors.append(door)


func _add_controls_hint(room: DungeonRoom) -> void:
	var label := Label3D.new()
	label.text = "%s\n%s" % [Language.translate("WASD: laufen · Maus: zielen · Linksklick: schießen"),
			Language.translate("E: Bombe · Tab: Karte · Esc: Pause")]
	var theme: Theme = ThemeDB.get_project_theme()
	if theme and theme.default_font:
		label.font = theme.default_font
	label.font_size = 48
	label.outline_size = 10
	label.pixel_size = 0.01
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.modulate = Color(1, 0.86, 0.55)
	label.rotation.x = -PI / 2.0
	label.position = Vector3(0, 0.02, -1.5)
	room.add_child(label)


## Rocks in a pattern of this floor ("rock_patterns" [name, weight]): scatter (random), walls,
## pillars, ring, corners, columns, checker. The paths between the doors and the middle stay free.
func _add_rocks(room: DungeonRoom) -> void:
	var settings: Dictionary = Content.floors_extra("rocks")
	var pattern: String = Content.pick_weighted(floor_data.get("rock_patterns", [["scatter", 1]]), _rng)
	var spots: Array[Vector3] = []
	if pattern == "scatter":
		var count_range: Array = settings.get("count", [0, 4])
		for i in _rng.randi_range(int(count_range[0]), int(count_range[1])):
			var spot: Vector3 = _free_spot(room, 1.8, true)
			if spot != Vector3.INF:
				spots.append(spot)
				_place_rock(room, spot, settings)
		return
	for spot: Vector3 in RoomPatterns.spots(pattern, _rng):
		if absf(spot.x) < 1.5 or absf(spot.z) < 1.5:
			continue
		_place_rock(room, spot, settings)


func _place_rock(room: DungeonRoom, spot: Vector3, settings: Dictionary) -> void:
	var rock := Rock.new()
	rock.texture_path = String(floor_data.get("rock_texture", settings.get("texture", "")))
	rock.has_coin = _rng.randf() < float(settings.get("coin_chance", 0.2))
	room.add_child(rock)
	rock.position = spot
	room.rocks.append(rock)


func _roll_enemies(room: DungeonRoom) -> void:
	var fixed: Array = floor_data.get("first_room_enemies", [])
	if layout.distance.get(room.cell, 99) == 1 and not fixed.is_empty():
		for id: Variant in fixed:
			room.spawn_list.append(String(id))
		return
	var count_range: Array = floor_data.get("enemy_count", [3, 5])
	var count: int = _rng.randi_range(int(count_range[0]), int(count_range[1]))
	for i in count:
		room.spawn_list.append(Content.pick_weighted(floor_data.get("enemies", []), _rng))


func _add_item_pedestal(room: DungeonRoom, at: Vector3, pool_name: String, price: int) -> Pedestal:
	var item_id: String = run.pick_item(pool_name, _rng)
	if item_id.is_empty():
		_drop(room, room.position + at, "heart")
		return null
	var pedestal := Pedestal.new()
	pedestal.setup(item_id, "", price, run, player)
	pedestal.message_requested.connect(message.emit)
	room.add_child(pedestal)
	pedestal.position = at
	room.loot.append(pedestal)
	return pedestal


func _build_shop(room: DungeonRoom) -> void:
	var shop: Dictionary = Content.floors_extra("shop")
	var keeper_texture := load(String(shop.get("keeper", ""))) as Texture2D
	if keeper_texture:
		var keeper := Fx.billboard(keeper_texture, KEEPER_HEIGHT)
		keeper.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		keeper.position = Vector3(0, KEEPER_HEIGHT / 2.0, -RoomBuilder.ROOM_D / 2.0 + 1.6)
		room.add_child(keeper)
	var goods: Array = shop.get("goods", [])
	var slots: int = goods.size() + 1
	var x: float = -(slots - 1) * 1.0
	_add_item_pedestal(room, Vector3(x, 0, 0), "shop", int(shop.get("item_price", 15)))
	for entry: Array in goods:
		x += 2.0
		var pedestal := Pedestal.new()
		pedestal.setup("", String(entry[0]), int(entry[1]), run, player)
		pedestal.message_requested.connect(message.emit)
		room.add_child(pedestal)
		pedestal.position = Vector3(x, 0, 0)
		room.loot.append(pedestal)


## A random free place in the room (local), away from doors, the middle (if `keep_middle_free`),
## rocks and other things. Vector3.INF if none was found.
func _free_spot(room: DungeonRoom, margin: float, keep_middle_free: bool) -> Vector3:
	var half := Vector2(RoomBuilder.ROOM_W / 2.0 - RoomBuilder.WALL_T - margin, RoomBuilder.ROOM_D / 2.0 - RoomBuilder.WALL_T - margin)
	for attempt in 30:
		var spot := Vector3(roundf(_rng.randf_range(-half.x, half.x)), 0, roundf(_rng.randf_range(-half.y, half.y)))
		# Paths through the doors stay free.
		if absf(spot.x) < 1.6 or absf(spot.z) < 1.6:
			continue
		if keep_middle_free and spot.length() < 2.5:
			continue
		var blocked: bool = false
		for rock: Rock in room.rocks:
			if rock.position.distance_to(spot) < 1.4:
				blocked = true
				break
		if not blocked:
			return spot
	return Vector3.INF


# --- Playing ------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if player == null or layout == null:
		return
	run.tick(delta)
	_check_stomp()
	_check_sacrifice()
	var pos: Vector3 = player.global_position
	var cell: Vector2i = RoomBuilder.cell_at(pos)
	if cell != current_cell and layout.rooms.has(cell) and RoomBuilder.inner_rect(cell, 0.4).has_point(Vector2(pos.x, pos.z)):
		_enter_room(cell)
	if _fighting and enemies.is_empty():
		_clear_room(rooms[current_cell])
	_check_locked_doors(pos)


func _enter_room(cell: Vector2i) -> void:
	current_cell = cell
	_show_near(cell)
	run.refresh_mantle()
	var room: DungeonRoom = rooms[cell]
	room.visited = true
	room_entered.emit(cell)
	if room.cleared:
		return
	match room.type:
		FloorLayout.NORMAL:
			if room.spawn_list.is_empty():
				room.cleared = true
				return
			_start_fight(room)
			for id: String in room.spawn_list:
				spawn_enemy(id, room.position + _spawn_spot(room))
		FloorLayout.BOSS:
			_start_fight(room)
			var toward_player: Vector3 = (player.global_position - room.position) * Vector3(1, 0, 1)
			boss = spawn_enemy(boss_id, room.position - toward_player.normalized() * 3.5)
			boss_appeared.emit(boss)
			AudioManager.play_music("boss")
		_:
			room.cleared = true


## Draws only `cell` and the rooms next to it (and their doors); far rooms are hidden.
func _show_near(cell: Vector2i) -> void:
	for other: Vector2i in rooms:
		var near: bool = other == cell or (layout.rooms.has(cell) and FloorLayout.DIRECTIONS.any(func(dir: Vector2i) -> bool: return cell + dir == other))
		rooms[other].visible = near
	for door: Door in doors:
		door.visible = door.cells.has(cell) or (rooms[door.cells[0]].visible and rooms[door.cells[1]].visible)


func _start_fight(room: DungeonRoom) -> void:
	_fighting = true
	for door: Door in doors_of(room.cell):
		door.set_closed(true)


## Somewhere free in the room and not too close to the player.
func _spawn_spot(room: DungeonRoom) -> Vector3:
	for attempt in 20:
		var spot: Vector3 = _free_spot(room, 1.2, false)
		if spot == Vector3.INF:
			continue
		if (room.position + spot).distance_to(player.global_position) >= SPAWN_MIN_DISTANCE:
			return spot
	return Vector3(0, 0, -2.0)


func spawn_enemy(id: String, at: Vector3) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(id, self, player, _rng.randi())
	enemy.name = "%s_%d" % [id, enemies.size()]
	enemy.died.connect(_on_enemy_died)
	rooms[current_cell].add_child(enemy)
	enemy.global_position = at
	enemies.append(enemy)
	Fx.puff(effects, at + Vector3(0, 0.5, 0), "enemy", 0.8)
	return enemy


## A boss calls helpers (only up to MAX_ENEMIES, inside the room).
func summon(id: String, at: Vector3) -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var rect: Rect2 = RoomBuilder.inner_rect(current_cell, 0.8)
	var spot := Vector3(clampf(at.x, rect.position.x, rect.end.x), 0, clampf(at.z, rect.position.y, rect.end.y))
	spawn_enemy(id, spot)


func _on_enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
	run.kills += 1
	run.on_kill()
	if run.record_progress:
		run.announce(Progress.add_kills(1))
		if enemy.is_boss:
			run.announce(Progress.beat_boss(enemy.id))
	if enemy == boss:
		boss = null
		for other: Enemy in enemies.duplicate():
			other.take_damage(9999.0, Vector3.ZERO, false)
		AudioManager.play_sound("boss_die")
		boss_defeated.emit()
		return
	if _rng.randf() < float(enemy.data.get("drop_chance", 0.0)) + run.stats.luck * _luck_drop() * 0.5:
		_drop(rooms[current_cell], enemy.global_position, _roll_drop())


func _clear_room(room: DungeonRoom) -> void:
	_fighting = false
	room.cleared = true
	for door: Door in doors_of(room.cell):
		door.set_closed(false)
	if room.type == FloorLayout.BOSS:
		_boss_rewards(room)
		AudioManager.play_music(String(floor_data.get("music", "")))
		return
	var drops: Dictionary = Content.floors_extra("room_drops")
	if _rng.randf() < float(drops.get("chance", 0.4)) + run.stats.luck * _luck_drop():
		_drop(room, room.position, _roll_drop())


## Extra drop chance per point of luck (data/player.json effects).
func _luck_drop() -> float:
	return float((Content.player().get("effects", {}) as Dictionary).get("luck_drop", 0.08))


func _roll_drop() -> String:
	var drops: Dictionary = Content.floors_extra("room_drops")
	return Content.pick_weighted(drops.get("table", [["coin", 1]]), _rng)


func _boss_rewards(room: DungeonRoom) -> void:
	var trapdoor := Trapdoor.new()
	trapdoor.final = floor_index >= Content.floors().size() - 1
	trapdoor.player = player
	trapdoor.entered.connect(func() -> void: trapdoor_entered.emit(trapdoor.final))
	room.add_child(trapdoor)
	trapdoor.position = Vector3(0, 0, 0)
	var first: Pedestal = _add_item_pedestal(room, Vector3(0, 0, -2.8), "boss", 0)
	# "choice": a second boss item; taking one makes the other vanish.
	if run.stats.has("choice") and first:
		first.position.x = -1.2
		var second: Pedestal = _add_item_pedestal(room, Vector3(1.2, 0, -2.8), "boss", 0)
		if second:
			first.taken.connect(func(_p: Pedestal) -> void: second.show_item(""))
			second.taken.connect(func(_p: Pedestal) -> void: first.show_item(""))
	_drop(room, room.position + Vector3(2.0, 0, 0), "heart")
	_open_special_room()
	message.emit("Der Weg nach unten ist frei!" if not trapdoor.final else "Du hast den Dungeon bezwungen!")


func _drop(room: DungeonRoom, at: Vector3, kind: String) -> void:
	var pickup := Pickup.new()
	pickup.setup(kind, run, player)
	room.add_child(pickup)
	pickup.global_position = Vector3(at.x, 0, at.z)
	room.loot.append(pickup)


## Touching a locked door with a key opens it; without a key a message says so.
func _check_locked_doors(pos: Vector3) -> void:
	for door: Door in doors_of(current_cell):
		if not door.locked:
			continue
		var offset: Vector3 = door.global_position - pos
		offset.y = 0.0
		if offset.length() > DOOR_TOUCH:
			if _warned_door == door:
				_warned_door = null
			continue
		if run.use_key():
			door.unlock()
		elif _warned_door != door:
			_warned_door = door
			AudioManager.play_sound("denied")
			message.emit("Du brauchst einen Schlüssel")


# --- Extra rooms ---------------------------------------------------------------------

## Secret room: a secret item (or, if none is left, a normal one) and some pickups.
func _build_secret_room(room: DungeonRoom) -> void:
	room.cleared = true
	if run.pick_item("secret", _rng).is_empty():
		_add_item_pedestal(room, Vector3.ZERO, "item", 0)
	else:
		# pick_item marked one as seen; give it back and let the pedestal pick it.
		run.seen_items.pop_back()
		_add_item_pedestal(room, Vector3.ZERO, "secret", 0)
	for i in 3:
		_drop(room, room.position + Vector3(-2.0 + i * 2.0, 0, 2.0), _roll_drop())


## Sacrifice room: the Opferstein in the middle.
func _build_sacrifice_room(room: DungeonRoom) -> void:
	room.cleared = true
	var stone := Node3D.new()
	stone.name = "Opferstein"
	RoomBuilder.box(stone, Vector3(1.2, 0.15, 1.2), Vector3(0, 0.075, 0), RoomBuilder.color_material(Color(0.45, 0.08, 0.06), 0.8), 0)
	for i in 4:
		var spike := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.12
		cone.height = 0.5
		spike.mesh = cone
		spike.material_override = RoomBuilder.color_material(Color(0.75, 0.72, 0.7))
		spike.position = Vector3(-0.3 + (i % 2) * 0.6, 0.4, -0.3 + floori(i / 2.0) * 0.6)
		stone.add_child(spike)
	var label := Label3D.new()
	label.text = Language.translate("Opferstein: ein Herz für eine Gabe")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.pixel_size = 0.01
	label.font_size = 32
	label.outline_size = 8
	label.modulate = Color(1, 0.5, 0.4)
	label.position.y = 1.6
	stone.add_child(label)
	room.add_child(stone)
	_sacrifice_stone = stone


## Standing on the Opferstein: a whole heart for the reward of this step (floors.json "sacrifice").
## Step off before it works again. Never kills.
func _check_sacrifice() -> void:
	if _sacrifice_stone == null or current_cell != RoomBuilder.cell_at(_sacrifice_stone.global_position):
		return
	var offset: Vector3 = player.global_position - _sacrifice_stone.global_position
	offset.y = 0.0
	if offset.length() > SACRIFICE_STEP:
		_on_stone = false
		return
	if _on_stone:
		return
	_on_stone = true
	if run.health + run.blue <= 2:
		message.emit("Du hast nicht genug Leben")
		return
	run.take_damage(2)
	player.invulnerable = Player.INVULNERABLE_TIME
	AudioManager.play_sound("player_hurt")
	var rewards: Array = (Content.floors_extra("sacrifice") as Dictionary).get("rewards", [])
	if rewards.is_empty():
		return
	var entry: Array = rewards[mini(_sacrifices, rewards.size() - 1)]
	_sacrifices += 1
	if _rng.randf() >= float(entry[1]):
		message.emit("Nichts geschieht")
		return
	var room: DungeonRoom = rooms[current_cell]
	var at: Vector3 = _sacrifice_stone.global_position + Vector3(0, 0, 1.6)
	match String(entry[0]):
		"coins":
			for i in 3:
				_drop(room, at + Vector3(i - 1.0, 0, 0), "coin")
		"blue_heart":
			run.add_blue_hearts(1)
		"item":
			_add_item_pedestal(room, Vector3(0, 0, -2.5), "item", 0)
		_:
			_drop(room, at, String(entry[0]))
	message.emit("Der Stein nimmt dein Opfer an")


## After the boss: maybe the room behind it opens as Glutpakt or Schrein.
func _open_special_room() -> void:
	var cell: Vector2i = layout.cell_of(FloorLayout.SPECIAL)
	if cell == Vector2i(-1, -1):
		return
	var kind: String = run.roll_special_room(_rng)
	if kind.is_empty():
		return
	var room: DungeonRoom = rooms[cell]
	room.cleared = true
	var settings: Dictionary = Content.floors_extra("special")
	var glow := OmniLight3D.new()
	glow.omni_range = 9.0
	glow.light_energy = 1.4
	glow.position.y = 2.4
	room.add_child(glow)
	if kind == "pact":
		glow.light_color = Color(1.0, 0.25, 0.15)
		var count: int = int(settings.get("pact_items", 2))
		var costs: Array = settings.get("pact_hearts", [1, 2])
		for i in count:
			var pedestal: Pedestal = _add_item_pedestal(room, Vector3((i - (count - 1) / 2.0) * 2.4, 0, 0), "pact", 0)
			if pedestal:
				pedestal.set_heart_price(int(costs[_rng.randi_range(0, costs.size() - 1)]))
		message.emit("Ein Glutpakt hat sich geöffnet")
	else:
		glow.light_color = Color(0.7, 0.85, 1.0)
		_add_item_pedestal(room, Vector3.ZERO, "shrine", 0)
		run.add_blue_hearts(1)
		message.emit("Ein Schrein hat sich geöffnet")
	for door: Door in doors_of(cell):
		door.reveal()


## Steine zertreten: walking into rocks breaks them.
func _check_stomp() -> void:
	if not run.stats.has("stomp"):
		return
	var room: DungeonRoom = rooms.get(current_cell)
	if room == null:
		return
	for rock: Rock in room.rocks.duplicate():
		var offset: Vector3 = rock.global_position - player.global_position
		offset.y = 0.0
		if offset.length() < Rock.RADIUS + Player.RADIUS + 0.15:
			_break_rock(room, rock)


## Items with "spawn" put pickups on the floor around the player.
func _on_item_added(id: String) -> void:
	var list: Array = Content.item(id).get("spawn", [])
	var room: DungeonRoom = rooms.get(current_cell)
	if room == null:
		return
	for i in list.size():
		var at: Vector3 = player.global_position + Vector3.FORWARD.rotated(Vector3.UP, TAU * i / list.size()) * 1.4
		var rect: Rect2 = RoomBuilder.inner_rect(current_cell, 0.6)
		at = Vector3(clampf(at.x, rect.position.x, rect.end.x), 0, clampf(at.z, rect.position.y, rect.end.y))
		_drop(room, at, String(list[i]))


## blue_burst: a lost blue heart hurts every enemy in the room.
func _on_blue_heart_lost() -> void:
	var amount: float = float((Content.player().get("effects", {}) as Dictionary).get("blue_burst_damage", 12.0))
	Fx.explosion(effects, player.global_position, 3.0)
	for enemy: Enemy in enemies.duplicate():
		enemy.take_damage(amount, Vector3.ZERO, false)


# --- Test room ----------------------------------------------------------------------------

func in_test_room() -> bool:
	return current_cell == TEST_CELL


## P: into the test room, or back to where the player was. Not during a fight.
func toggle_test_room() -> void:
	if in_test_room():
		current_cell = _return_cell
		_show_near(current_cell)
		_move_player(_return_position)
		room_entered.emit(current_cell)
		return
	if _fighting:
		message.emit("Nicht während eines Kampfes")
		return
	if _test_room == null:
		_build_test_room()
	# Free items: from now on this run does not count for the Lexikon and unlocks.
	run.record_progress = false
	_return_cell = current_cell
	_return_position = player.global_position
	current_cell = TEST_CELL
	_show_near(current_cell)
	_move_player(_test_room.position + Vector3(0, 0, RoomBuilder.ROOM_D / 2.0 - 2.3))
	player.rotation.y = 0.0
	room_entered.emit(current_cell)


func _move_player(at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO


func _build_test_room() -> void:
	var room := DungeonRoom.new()
	room.cell = TEST_CELL
	room.type = "test"
	room.name = "TestRoom"
	room.position = RoomBuilder.cell_center(TEST_CELL)
	room.visited = true
	room.cleared = true
	add_child(room)
	rooms[TEST_CELL] = room
	_test_room = room
	var light: Array = floor_data.get("light", [1.0, 0.75, 0.5])
	var no_doors: Dictionary[Vector2i, String] = {}
	RoomBuilder.build_shell(room, String(floor_data.get("floor_texture", "")), String(floor_data.get("wall_texture", "")),
			no_doors, Color(float(light[0]), float(light[1]), float(light[2])))
	_test_ids.assign(Content.items().keys())
	_test_ids.sort()
	for i in TEST_COLUMNS * TEST_ROWS:
		var column: int = i % TEST_COLUMNS
		var row: int = floori(float(i) / TEST_COLUMNS)
		var at := Vector3((column - (TEST_COLUMNS - 1) / 2.0) * TEST_SPACING.x, 0, TEST_FIRST_ROW + row * TEST_SPACING.y)
		_add_test_pedestal(room, "", "", at)
	_show_test_page(0)
	var reset: Pedestal = _add_test_pedestal(room, "", Pedestal.RESET, Vector3(-6.0, 0, 4.0))
	reset.taken.connect(_on_test_reset)
	var next_page: Pedestal = _add_test_pedestal(room, "", Pedestal.PAGE, Vector3(6.0, 0, 4.0))
	next_page.taken.connect(_on_test_next_page)
	var label := Label3D.new()
	label.text = Language.translate("Testraum · P: zurück")
	var theme: Theme = ThemeDB.get_project_theme()
	if theme and theme.default_font:
		label.font = theme.default_font
	label.font_size = 48
	label.outline_size = 10
	label.pixel_size = 0.01
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.modulate = Color(1, 0.86, 0.55)
	label.rotation.x = -PI / 2.0
	label.position = Vector3(1.5, 0.02, 4.1)
	room.add_child(label)


func _add_test_pedestal(room: DungeonRoom, item_id: String, goods: String, at: Vector3) -> Pedestal:
	var pedestal := Pedestal.new()
	pedestal.setup(item_id, goods, 0, run, player)
	room.add_child(pedestal)
	pedestal.position = at
	room.loot.append(pedestal)
	_test_pedestals.append(pedestal)
	return pedestal


## The item pedestals (the first TEST_COLUMNS * TEST_ROWS) show page `page` of all items.
func _show_test_page(page: int) -> void:
	var per_page: int = TEST_COLUMNS * TEST_ROWS
	_test_page = page if page * per_page < _test_ids.size() else 0
	for i in per_page:
		var index: int = _test_page * per_page + i
		_test_pedestals[i].show_item(_test_ids[index] if index < _test_ids.size() else "")


## Blue pedestal: the next page (after the last one the first again).
func _on_test_next_page(pedestal: Pedestal) -> void:
	_show_test_page(_test_page + 1)
	pedestal.refill()
	var pages: int = ceili(float(_test_ids.size()) / (TEST_COLUMNS * TEST_ROWS))
	message.emit(Language.translate("Seite %d von %d") % [_test_page + 1, pages])


## Red pedestal: drop every item, all pedestals full again.
func _on_test_reset(_pedestal: Pedestal) -> void:
	run.clear_items()
	for pedestal: Pedestal in _test_pedestals:
		if pedestal.visible:
			pedestal.refill()
	message.emit("Alle Items abgelegt")


# --- Shots and explosions ---------------------------------------------------------------

## A player shot (Weapon, split sparks, cluster bombs). `skip`: enemies it must not hit at once.
func spawn_projectile(at: Vector3, direction: Vector3, stats: ShotStats, charge: float, small: bool, skip: Array, bonus: float = 1.0) -> void:
	var projectile := Projectile.new()
	projectile.setup(self, player, stats, direction, charge, small)
	projectile.bonus = bonus
	projectile.ignore(skip)
	effects.add_child(projectile)
	projectile.global_position = at


## Hurts enemies (and the player if `hurts_player`, not with the Schmiedeschürze) within
## `radius`, breaks rocks.
func explode(at: Vector3, radius: float, damage: float, hurts_player: bool) -> void:
	Fx.explosion(effects, at, radius)
	AudioManager.play_sound("explosion", randf_range(0.85, 1.05))
	for enemy: Enemy in enemies.duplicate():
		var offset: Vector3 = enemy.global_position - at
		offset.y = 0.0
		if offset.length() - enemy.radius < radius:
			enemy.take_damage(damage, offset.normalized() * 4.0, false)
	# Hidden walls of secret rooms nearby are blown open.
	for door: Door in doors:
		if door.hidden and layout.get_type(door.cells[0]) != FloorLayout.SPECIAL and layout.get_type(door.cells[1]) != FloorLayout.SPECIAL:
			if Vector2(door.global_position.x - at.x, door.global_position.z - at.z).length() < radius + SECRET_BLAST_REACH:
				door.reveal()
				message.emit("Ein geheimer Raum!")
	var room: DungeonRoom = rooms.get(RoomBuilder.cell_at(at))
	if room:
		for rock: Rock in room.rocks.duplicate():
			if Vector2(rock.global_position.x - at.x, rock.global_position.z - at.z).length() < radius + 0.3:
				_break_rock(room, rock)
	if hurts_player and run.stats.has("blast_heal"):
		var near: Vector3 = player.global_position - at
		near.y = 0.0
		if near.length() < radius:
			run.heal(1)
	elif hurts_player and not run.stats.has("blast_proof"):
		var to_player: Vector3 = player.global_position - at
		to_player.y = 0.0
		if to_player.length() < radius * 0.8:
			player.take_hit(2)


func _break_rock(room: DungeonRoom, rock: Rock) -> void:
	room.remove_rock(rock)
	Fx.puff(effects, rock.global_position + Vector3(0, 0.5, 0), "spark", 1.0)
	if rock.has_coin:
		_drop(room, rock.global_position, "coin")
	rock.queue_free()
