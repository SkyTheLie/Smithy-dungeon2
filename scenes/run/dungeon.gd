class_name Dungeon
extends Node3D
## One floor of the dungeon in 3D. build() makes a FloorLayout (data/floors.json) and builds every
## room side by side, with doors between neighbours. While the player walks around it:
##   - entering a room with enemies closes its doors and lets the enemies appear;
##   - when the last one falls the doors open and sometimes a reward drops;
##   - item room: one item on a pedestal; shop: an item and goods for coins; the merchant there
##     is talked to with F (near_merchant, the bag window opens as his trade window: trading):
##     he buys loot (right click: sell_from_bag), the only gold of the dungeon, and offers a
##     relic (merchant_relic, buy_relic: it waits at home in the inventory);
##   - boss room: one boss of the theme, picked at random when the floor is built; after it a
##     trapdoor down and a boss item. Beating the very first boss (MetaState.rope_due) in the boss
##     room also lets a rope fall: the way out of the dungeon (Rope, climb_rope). After the boss of the last floor a portal rises
##     instead of the trapdoor (Portal); it leads to the Boss-Altar (BossAltar), where the end
##     boss of the dungeon waits (dungeons.json end_boss); after it the golden light (victory).
## Only the room the player is in and its neighbours are visible (drawn); the rest is hidden.
## Extra rooms (FloorLayout.add_extras): a secret room behind a wall that a bomb blows open
## (secret items), sometimes a sacrifice room (Opferstein: a heart for a reward) and the special
## room behind the boss: after the boss it may open as Glutpakt (items for heart containers) or
## Schrein (a free item), see RunState.roll_special_room.
## Tall grass (floors.json "grass", Meadow) in every room but the start room; traps a boss throws
## come in with add_hazard; a snare holds the player instead of hurting again and again.
## Start room: the controls on the floor and the way out (DungeonExit, a ladder in a corner):
## stepping on it sends exit_entered (the run scene asks whether to flee).
## Rules about life, coins and items are in RunState; this node only calls them.
##
## Guide of the very first run (guide = true, set by RunScene before build; DungeonGuide leads):
## the start room has no writing on the floor and its doors stay shut until the guide opens the
## one to the practice room (open_guide_door): a normal room next to the start with only the
## harmless practice rat (enemies.json "tutorial_rat", it always drops a rat fur), no rocks and
## no traps. end_guide opens the other doors again.
##
## Räderkluft (GearChasm, data/gear_chasm.json): a boss hall over a chasm with turning platforms,
## far away from the floor grid like the Boss-Altar. In a dungeon with "end_room": "gear_chasm"
## (dungeons.json) the portal after the last floor leads there instead of the Boss-Altar; the
## end boss stands still on the dais in the middle.
##
## Test room (P, only in debug builds): a closed room far away from the floor with every item on a
## pedestal and a red pedestal that drops all items again, to try out items and synergies.

signal floor_started(name: String)
signal room_entered(cell: Vector2i)
signal boss_appeared(boss: Enemy)
signal boss_defeated
## The leader (mini boss) of this floor comes / is beaten (HUD shows its life bar).
signal leader_appeared(leader: Enemy)
signal leader_defeated
signal trapdoor_entered(final: bool)
## The player took hold of the rope after the first boss (RunScene then ends the day).
signal rope_grabbed
## The player stepped onto the way out in the start room.
signal exit_entered
## A short text for the HUD (German key).
signal message(text: String)
## An enemy took `amount` damage (HUD: hit marker at the crosshair; red when `killed`).
signal enemy_damaged(enemy: Enemy, amount: float, killed: bool)
## The Boss-Altar scene started (true) / ended (false): the HUD hides meanwhile.
signal cutscene_changed(active: bool)

const SPAWN_MIN_DISTANCE: float = 3.5
const MAX_ENEMIES: int = 12
## Traps keep this far (metres) from the lines through the doors, so a way stays free.
const HAZARD_PATH: float = 1.4
## The player's own traps at the same time in one room (more: the oldest goes).
const PLAYER_TRAPS_MAX: int = 6
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
## The Boss-Altar (BossAltar) lies far away from the floor grid, like the test room.
const ALTAR_CELL: Vector2i = Vector2i(-12, 12)
## The Räderkluft (GearChasm), also far away from the floor grid.
const CHASM_CELL: Vector2i = Vector2i(14, -14)
## Walking this close to the portal in the boss room leads to the Boss-Altar.
const PORTAL_TOUCH: float = 1.2
## Seconds of climbing up the rope (then RunScene fades out) and how high the player gets.
const CLIMB_TIME: float = 2.6
const CLIMB_HEIGHT: float = 9.0

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
## The end boss in the Boss-Altar (dungeons.json end_boss): only on the last floor, else "".
var end_boss_id: String = ""
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
## Boss-Altar: built the first time the player walks into the portal of the boss room.
var altar: BossAltar = null
## Räderkluft: built the first time the player is taken there (enter_gear_chasm).
var chasm: GearChasm = null
## After the boss of the last floor (leads to the Boss-Altar); null before.
var _portal: Portal = null
## After the very first boss: the way out (null else).
var _rope: Rope = null
## The merchant in the shop room (null on floors without a shop).
var keeper: Node3D = null
## true while the bag window is open as the merchant's trade window (only then he buys).
var trading: bool = false
## The relic the merchant offers (ShopGoods.make_relic + "price"; {} = none or sold).
var merchant_relic: Dictionary = {}
## The rope's place in the boss room (next to the trapdoor, which stays in the middle).
const ROPE_SPOT := Vector3(-2.6, 0, 1.6)
## true once the boss of this floor died in its room (only then the rope may come).
var _boss_beaten: bool = false
## The guide of the first run is on (see above); its practice room (-1, -1 = none).
var guide: bool = false
var guide_cell := Vector2i(-1, -1)
const GUIDE_ENEMY: String = "tutorial_rat"


func build(run_state: RunState, the_player: Player, index: int) -> void:
	run = run_state
	player = the_player
	floor_index = index
	floor_data = Content.floor_data(index)
	_rng.seed = hash(run.seed_value + index * 7919)
	# floors.json "shop_room": false = no shop on this floor (and no room for it).
	var dead_ends: Array[String] = [FloorLayout.ITEM]
	if bool(floor_data.get("shop_room", true)):
		dead_ends.append(FloorLayout.SHOP)
	layout = FloorLayout.generate(_rng, int(floor_data.get("rooms", 7)), dead_ends)
	if not bool(floor_data.get("item_room", true)):
		layout.remove_item_room()
	# Extra rooms with their own random numbers: the normal rooms stay the same for a seed.
	# A floor may ask for a sure sacrifice room ("sacrifice_chance") and leave out the secret
	# room and the special room behind the boss ("secret_room", "special_room": false).
	var extra_rng := RandomNumberGenerator.new()
	extra_rng.seed = hash(run.seed_value * 31 + index * 104729)
	var sacrifice: float = float(floor_data.get("sacrifice_chance", (Content.floors_extra("sacrifice") as Dictionary).get("room_chance", 0.5)))
	layout.add_extras(extra_rng, sacrifice, bool(floor_data.get("secret_room", true)), bool(floor_data.get("special_room", true)))
	effects = Node3D.new()
	effects.name = "Effects"
	add_child(effects)
	# Quiet sounds of the place (floors.json theme "ambience").
	var sounds := RoomSounds.new()
	sounds.name = "RoomSounds"
	add_child(sounds)
	sounds.setup(self, floor_data.get("ambience", []), hash([run.seed_value, index, "ambience"]))
	if guide:
		for cell: Vector2i in layout.neighbours(FloorLayout.START):
			if layout.get_type(cell) == FloorLayout.NORMAL:
				guide_cell = cell
				break
	for cell: Vector2i in layout.rooms:
		_build_room(cell)
	_build_doors()
	_add_writings()
	_place_leader()
	if guide:
		for door: Door in doors_of(FloorLayout.START):
			door.set_closed(true)
	# After the rooms, so the rooms come out the same for a seed whatever bosses there are.
	# A boss that did not come yet in this run (the floors of a theme share their bosses).
	var bosses: Array = floor_data.get("bosses", ["rat_king"])
	if is_last_floor():
		end_boss_id = Content.end_boss()
		# The end boss waits in the Boss-Altar, not in the boss room (if the theme has others).
		var others: Array = bosses.filter(func(id: Variant) -> bool: return String(id) != end_boss_id)
		if not others.is_empty():
			bosses = others
	var fresh: Array = bosses.filter(func(id: Variant) -> bool: return not run.fought_bosses.has(String(id)))
	if fresh.is_empty():
		fresh = bosses
	boss_id = String(fresh[_rng.randi_range(0, fresh.size() - 1)])
	if not run.fought_bosses.has(boss_id):
		run.fought_bosses.append(boss_id)
	# enemies.json "arena" (light, traps) of the boss in its room; the end boss's goes into the
	# Boss-Altar when it is built.
	var boss_cell: Vector2i = layout.cell_of(FloorLayout.BOSS)
	if rooms.has(boss_cell):
		_build_arena(rooms[boss_cell], boss_id)
	player.global_position = RoomBuilder.cell_center(FloorLayout.START) + Vector3(0, 0, 1.0)
	_enter_room(FloorLayout.START)
	run.blue_heart_lost.connect(_on_blue_heart_lost)
	run.revived.connect(func(_id: String) -> void: message.emit("Ein zweites Leben!"))
	run.item_added.connect(_on_item_added)
	run.loot_overflow.connect(func(id: String, count: int) -> void: _drop_loot(rooms[current_cell], player.global_position, id, count, false))
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
	# Decoration along the walls (floors.json theme "props"), own random numbers per room.
	var door_dirs: Array[Vector2i] = []
	for dir: Vector2i in neighbours:
		door_dirs.append(dir)
	RoomProps.add_props(room, floor_data.get("props", []), Content.floors_extra("props"),
			door_dirs, hash([floor_index, cell, "props"]))
	# Dust, embers, snow or fireflies in the air (floors.json theme "air" -> "air_types").
	var air_types: Dictionary = Content.floors_extra("air_types")
	RoomAir.add_air(room, air_types.get(String(floor_data.get("air", "")), {}), hash([floor_index, cell, "air"]))
	# Tall grass (floors.json "grass"): hides low enemies and traps.
	var grass: Dictionary = floor_data.get("grass", {})
	if not grass.is_empty() and room.type != FloorLayout.START_ROOM:
		Meadow.add_grass(room, grass, hash([floor_index, cell]))
	match room.type:
		FloorLayout.START_ROOM:
			if not guide:
				_add_controls_hint(room)
			_add_exit(room)
		FloorLayout.NORMAL when cell == guide_cell:
			room.spawn_list.append(GUIDE_ENEMY)
		FloorLayout.NORMAL:
			_add_rocks(room)
			_roll_enemies(room)
			_add_hazards(room)
		FloorLayout.ITEM:
			_add_item_pedestal(room, Vector3.ZERO, "item", 0)
		FloorLayout.SHOP:
			_build_shop(room)
		FloorLayout.SECRET:
			_build_secret_room(room)
		FloorLayout.SACRIFICE:
			_build_sacrifice_room(room)


## Lines of earlier adventurers on the walls of some normal rooms (floors.json "writings",
## lines in story.json "walls" / "walls_<dungeon>"), own random numbers per floor.
func _add_writings() -> void:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in layout.rooms:
		if layout.get_type(cell) == FloorLayout.NORMAL and cell != guide_cell:
			cells.append(cell)
	var lines: Array[String] = RoomWriting.lines_for(Content.dungeon_id())
	var chosen: Dictionary[Vector2i, String] = RoomWriting.plan(cells, lines, Content.floors_extra("writings"), hash([run.seed_value, floor_index, "writings"]))
	for cell: Vector2i in chosen:
		var door_dirs: Array[Vector2i] = []
		for dir: Vector2i in FloorLayout.DIRECTIONS:
			if layout.rooms.has(cell + dir):
				door_dirs.append(dir)
		RoomWriting.add_writing(rooms[cell], chosen[cell], door_dirs, hash([floor_index, cell, "writing"]))


## The leader of this floor (floors.json "mini_boss", floor "mini_boss": false = none): one normal
## room about halfway to the boss gets a big golden enemy of the theme ("mini_bosses"), and only
## half of its normal enemies. Own random numbers, so the rooms stay the same for a seed.
func _place_leader() -> void:
	var table: Array = floor_data.get("mini_bosses", [])
	if table.is_empty() or not bool(floor_data.get("mini_boss", true)) or guide:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run.seed_value, floor_index, "leader"])
	var middle: float = float(layout.distance.get(layout.cell_of(FloorLayout.BOSS), 2)) / 2.0
	var best: Array[Vector2i] = []
	var best_gap: float = INF
	for cell: Vector2i in layout.rooms:
		if layout.get_type(cell) != FloorLayout.NORMAL or cell == guide_cell or layout.distance.get(cell, 0) < 2:
			continue
		var gap: float = absf(float(layout.distance.get(cell, 0)) - middle)
		if gap < best_gap - 0.01:
			best_gap = gap
			best = [cell]
		elif absf(gap - best_gap) < 0.01:
			best.append(cell)
	if best.is_empty():
		return
	var room: DungeonRoom = rooms[best[rng.randi() % best.size()]]
	room.leader = Content.pick_weighted(table, rng)
	room.spawn_list.resize(ceili(room.spawn_list.size() / 2.0))


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
			Language.translate("E: Bombe · Tab: Inventar · M: Karte · Esc: Pause")]
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


## Guide: the door from the start room to the practice room opens.
func open_guide_door() -> void:
	for door: Door in doors_of(FloorLayout.START):
		if door.cells.has(guide_cell) or guide_cell == Vector2i(-1, -1):
			door.set_closed(false)


## Guide over: every door of the start room opens (unless a fight there keeps them shut).
func end_guide() -> void:
	guide = false
	if _fighting and current_cell == FloorLayout.START:
		return
	for door: Door in doors_of(FloorLayout.START):
		if not (_fighting and door.cells.has(current_cell)):
			door.set_closed(false)


## true once the practice rat is beaten (its room is cleared).
func guide_room_cleared() -> bool:
	return rooms.has(guide_cell) and rooms[guide_cell].cleared


## The way out: a ladder in the back left corner of the start room (corners never have doors).
func _add_exit(room: DungeonRoom) -> void:
	var way_out := DungeonExit.new()
	way_out.name = "Exit"
	way_out.player = player
	way_out.entered.connect(exit_entered.emit)
	room.add_child(way_out)
	way_out.position = Vector3(-RoomBuilder.ROOM_W / 2.0 + 1.3, 0, -RoomBuilder.ROOM_D / 2.0 + 1.3)


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
	# Later dungeons and deeper floors are dearer (dungeons.json shop_mult, shop floor_step).
	var mult: float = float(floor_data.get("shop_mult", 1.0))
	var keeper_texture := load(String(shop.get("keeper", ""))) as Texture2D
	if keeper_texture:
		var sprite := Fx.billboard(keeper_texture, KEEPER_HEIGHT)
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.position = Vector3(0, KEEPER_HEIGHT / 2.0, -RoomBuilder.ROOM_D / 2.0 + 1.6)
		room.add_child(sprite)
		keeper = sprite
	# A relic (an item found before, data/relics.json), with its own random numbers.
	var relic_rng := RandomNumberGenerator.new()
	relic_rng.seed = hash([run.seed_value, floor_index, "relic"])
	var relic_id: String = ShopGoods.pick_relic(relic_rng)
	if not relic_id.is_empty() and relic_rng.randf() < float(shop.get("relic_chance", 0.0)):
		merchant_relic = ShopGoods.make_relic(relic_id)
		merchant_relic["price"] = maxi(1, roundi(float(merchant_relic.get("price", 0)) * float(shop.get("relic_price_mult", 1.0)) * mult))
	var goods: Array = shop.get("goods", [])
	var slots: int = goods.size() + 1
	var x: float = -(slots - 1) * 1.0
	_add_item_pedestal(room, Vector3(x, 0, 0), "shop", roundi(float(shop.get("item_price", 15)) * mult))
	for entry: Array in goods:
		x += 2.0
		var pedestal := Pedestal.new()
		pedestal.setup("", String(entry[0]), roundi(float(entry[1]) * mult), run, player)
		pedestal.message_requested.connect(message.emit)
		room.add_child(pedestal)
		pedestal.position = Vector3(x, 0, 0)
		room.loot.append(pedestal)


## A boss with "arena" (enemies.json) changes its room: "light" [r, g, b] = a coloured light over
## it, "hazards" [[kind, [min, max]]] = traps like in normal rooms (door paths and the middle stay
## free, so the boss always has room). With its own random numbers.
func _build_arena(room: DungeonRoom, id: String) -> void:
	var arena: Dictionary = Content.enemy(id).get("arena", {})
	if arena.is_empty() or room == null:
		return
	if arena.has("light"):
		var tint: Array = arena["light"]
		var glow := OmniLight3D.new()
		glow.light_color = Color(float(tint[0]), float(tint[1]), float(tint[2]))
		glow.light_energy = 1.6
		glow.omni_range = 12.0
		glow.position.y = 3.0
		room.add_child(glow)
	_place_hazards(room, arena.get("hazards", []), hash([run.seed_value, floor_index, "arena"]))


## Traps on the floor of a normal room: floor_data "hazards" [[kind, [min, max]], …], the kinds
## in floors.json "hazard_types". With their own random numbers (the rest of the room stays the
## same for a seed). Paths through the doors, the middle and the rocks stay free.
func _add_hazards(room: DungeonRoom) -> void:
	_place_hazards(room, floor_data.get("hazards", []), hash([run.seed_value, floor_index, room.cell]))


## `list` [[kind, [min, max]], …] of floors.json hazard_types into `room`, rolled with `seed`.
func _place_hazards(room: DungeonRoom, list: Array, seed: int) -> void:
	if list.is_empty():
		return
	var types: Dictionary = Content.floors_extra("hazard_types")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for entry: Array in list:
		var kind: String = String(entry[0])
		if not types.has(kind):
			continue
		var data: Dictionary = types[kind]
		var count_range: Array = entry[1]
		var sizes: Array = data.get("size", [1.5, 2.0])
		for i in rng.randi_range(int(count_range[0]), int(count_range[1])):
			var side: float = rng.randf_range(float(sizes[0]), float(sizes[1]))
			var spot: Vector3 = _hazard_spot(room, side, rng)
			if spot == Vector3.INF:
				continue
			var hazard := Hazard.new()
			hazard.setup(kind, data, side, rng.randf() * 3.0)
			room.add_child(hazard)
			hazard.position = spot
			room.hazards.append(hazard)


## A place (local) for a trap `side` metres wide: inside the walls, away from the door paths and
## the middle, not on a rock or another trap. Vector3.INF if none was found.
func _hazard_spot(room: DungeonRoom, side: float, rng: RandomNumberGenerator) -> Vector3:
	var half := Vector2(RoomBuilder.ROOM_W / 2.0 - RoomBuilder.WALL_T - side / 2.0 - 0.3, RoomBuilder.ROOM_D / 2.0 - RoomBuilder.WALL_T - side / 2.0 - 0.3)
	var keep: float = side / 2.0 + HAZARD_PATH
	if half.x <= keep or half.y <= keep:
		return Vector3.INF
	for attempt in 30:
		var spot := Vector3(rng.randf_range(-half.x, half.x), 0, rng.randf_range(-half.y, half.y))
		if absf(spot.x) < keep or absf(spot.z) < keep:
			continue
		var blocked: bool = false
		for rock: Rock in room.rocks:
			if absf(rock.position.x - spot.x) < side / 2.0 + 0.7 and absf(rock.position.z - spot.z) < side / 2.0 + 0.7:
				blocked = true
				break
		for other: Hazard in room.hazards:
			if absf(other.position.x - spot.x) < (side + other.size) / 2.0 + 0.4 and absf(other.position.z - spot.z) < (side + other.size) / 2.0 + 0.4:
				blocked = true
				break
		if not blocked:
			return spot
	return Vector3.INF


## Standing on a dangerous trap of this room: a hit (the player's invulnerable time limits it);
## a snare snaps shut and holds the player; pigeons on it fly off. The player's own traps hurt
## the enemies of the room instead (Hazard.touch_enemy), never the player.
func _check_hazards() -> void:
	if not rooms.has(current_cell):
		return
	var room: DungeonRoom = rooms[current_cell]
	for hazard: Hazard in room.hazards:
		if hazard.from_player:
			for enemy: Enemy in enemies.duplicate():
				hazard.touch_enemy(enemy)
	# Flying over the traps (fly, ghost): they do nothing to the player.
	if player.flying():
		return
	for hazard: Hazard in room.hazards:
		if hazard.hurts_at(player.global_position):
			hazard.scare()
			if hazard.holds():
				hazard.spring(player)
				message.emit("Festgehalten!")
			else:
				player.take_hit(hazard.damage)
			return


## A player shot ended at `at`: every trap of the shot (ShotStats.traps from items and relics:
## {kind, chance}) is rolled and laid there (place_player_trap).
func shot_ended(at: Vector3, stats: ShotStats) -> void:
	for trap: Dictionary in stats.traps:
		if _rng.randf() < float(trap.get("chance", 0.0)):
			place_player_trap(String(trap.get("kind", "")), at, stats.damage)


## One of the player's own traps (floors.json hazard_types with "owner": "player") at `at` in the
## room the player is in, hurting enemies with `shot_damage` x its damage_mult. Gone after its
## "life" seconds; at most PLAYER_TRAPS_MAX in a room (the oldest goes). null if not possible.
func place_player_trap(kind: String, at: Vector3, shot_damage: float) -> Hazard:
	var types: Dictionary = Content.floors_extra("hazard_types")
	if not types.has(kind) or String((types[kind] as Dictionary).get("owner", "")) != "player":
		return null
	var room: DungeonRoom = rooms.get(current_cell)
	if room == null:
		return null
	var own: Array[Hazard] = []
	for other: Hazard in room.hazards:
		if other.from_player and other.visible:
			own.append(other)
	if own.size() >= PLAYER_TRAPS_MAX:
		room.hazards.erase(own[0])
		own[0].queue_free()
	var hazard: Hazard = add_hazard(kind, at, float((types[kind] as Dictionary).get("life", 6.0)))
	if hazard:
		hazard.shot_damage = shot_damage
	return hazard


## A trap of floors.json hazard_types `kind` at `at` (world) in the room the player is in, e.g.
## the snares a boss throws. `life` > 0: gone after that many seconds. null for an unknown kind.
func add_hazard(kind: String, at: Vector3, life: float) -> Hazard:
	var types: Dictionary = Content.floors_extra("hazard_types")
	if not types.has(kind) or not rooms.has(current_cell):
		return null
	var data: Dictionary = types[kind]
	var sizes: Array = data.get("size", [1.0, 1.0])
	var hazard := Hazard.new()
	hazard.setup(kind, data, float(sizes[0]), 0.0)
	hazard.life = life
	var room: DungeonRoom = rooms[current_cell]
	room.add_child(hazard)
	var rect: Rect2 = room_rect(float(sizes[0]) / 2.0)
	hazard.global_position = Vector3(clampf(at.x, rect.position.x, rect.end.x), 0.0, clampf(at.z, rect.position.y, rect.end.y))
	room.hazards.append(hazard)
	return hazard


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
	_check_hazards()
	_check_stomp()
	_check_sacrifice()
	var pos: Vector3 = player.global_position
	if in_boss_altar():
		if altar.tick():
			leave_boss_altar()
		elif _fighting and enemies.is_empty():
			_clear_room(altar)
		return
	if in_gear_chasm():
		# It may move the player (platforms, falls): nothing more this frame.
		chasm.tick(delta)
		if _fighting and enemies.is_empty():
			_clear_room(chasm)
		return
	if _check_portal(pos):
		return
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
	if room.type == FloorLayout.SHOP and not room.visited:
		message.emit("Ein Händler! Geh hin und sprich ihn an.")
	room.visited = true
	room_entered.emit(cell)
	if room.cleared:
		return
	match room.type:
		FloorLayout.NORMAL:
			if room.spawn_list.is_empty() and room.leader.is_empty():
				room.cleared = true
				return
			_start_fight(room)
			for id: String in room.spawn_list:
				spawn_enemy(id, room.position + _spawn_spot(room))
			if not room.leader.is_empty():
				var leader := spawn_enemy(room.leader, room.position + _spawn_spot(room), true)
				leader_appeared.emit(leader)
				message.emit("Ein Anführer!")
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


func spawn_enemy(id: String, at: Vector3, leader: bool = false) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(id, self, player, _rng.randi())
	if leader:
		enemy.make_leader(Content.floors_extra("mini_boss"))
	enemy.name = "%s_%d" % [id, enemies.size()]
	enemy.died.connect(_on_enemy_died)
	rooms[current_cell].add_child(enemy)
	enemy.global_position = at
	enemies.append(enemy)
	Fx.puff(effects, at + Vector3(0, 0.5, 0), "enemy", 0.8)
	return enemy


## A boss calls helpers: at most data/enemies.json "summon_max" of them alive at once (and
## MAX_ENEMIES in all), inside the room.
func summon(id: String, at: Vector3) -> void:
	if enemies.size() >= MAX_ENEMIES or helper_count() >= summon_max():
		return
	var rect: Rect2 = room_rect(0.8)
	var spot := Vector3(clampf(at.x, rect.position.x, rect.end.x), 0, clampf(at.z, rect.position.y, rect.end.y))
	spawn_enemy(id, spot)


## How many helpers a boss may have alive at once (data/enemies.json "summon_max").
static func summon_max() -> int:
	return maxi(0, int(Content.get_file("enemies").get("summon_max", 5)))


## Enemies alive besides the boss (in a boss fight: its helpers).
func helper_count() -> int:
	return enemies.size() - (1 if boss != null and enemies.has(boss) else 0)


func _on_enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
	run.kills += 1
	var leader_rules: Dictionary = Content.floors_extra("mini_boss")
	run.add_kill_exp(enemy.is_boss or enemy.is_leader, float(floor_data.get("exp_mult", 1.0)) * (float(leader_rules.get("exp_share", 0.5)) if enemy.is_leader else 1.0))
	run.on_kill()
	if run.record_progress:
		run.announce(Progress.add_kills(1))
		run.announce(Progress.meet_enemy(enemy.id))
		if enemy.is_boss:
			run.announce(Progress.beat_boss(enemy.id))
	if enemy.is_boss:
		_drop_enemy_loot(enemy)
		_drop_coins(enemy)
	elif enemy.is_leader:
		# Its own reward, on top of the room's drop budget: all its loot, sure coins, maybe a heart.
		_drop_enemy_loot(enemy)
		_drop_coins(enemy)
		if _rng.randf() < float(leader_rules.get("heart_chance", 0.0)):
			_drop(rooms[current_cell], enemy.global_position + Vector3(0.5, 0, 0), "heart")
		leader_defeated.emit()
	else:
		_drop_from_normal(enemy)
	if enemy == boss:
		boss = null
		_boss_beaten = not in_end_hall()
		for other: Enemy in enemies.duplicate():
			other.take_damage(9999.0, Vector3.ZERO, false)
		AudioManager.play_sound("boss_die")
		# Egon's quest: the end boss (Boss-Altar) leaves the stone of the open quest of this dungeon.
		if in_end_hall():
			var stone: String = Quests.drop_for(Content.dungeon_id(), run.bag)
			if not stone.is_empty():
				_drop_loot(rooms[current_cell], enemy.global_position, stone, 1, false)
				message.emit("Ein seltener Stein! Egon wird staunen.")
		# Egon's errand: the very first boss always leaves the ruby.
		if not in_end_hall() and MetaState.rope_due(Content.dungeon_id(), floor_index):
			_drop_loot(rooms[current_cell], enemy.global_position, String(Content.meta("ruby_quest").get("item", "")), 1, false)
		boss_defeated.emit()
		return
	if _rng.randf() < key_drop_chance():
		_drop(rooms[current_cell], enemy.global_position, "key")


## A normal enemy: at most one thing, and only while the room has drops left (room_drops_left):
## first its loot, else coins, else a heart or bomb (enemies.json drop_chance).
func _drop_from_normal(enemy: Enemy) -> void:
	var room: DungeonRoom = rooms[current_cell]
	if room_drops_left(room) <= 0:
		return
	var dropped: bool = _drop_enemy_loot(enemy, true) or _drop_coins(enemy)
	if not dropped and _rng.randf() < float(enemy.data.get("drop_chance", 0.0)) + run.stats.luck * _luck_drop() * 0.5:
		_drop(room, enemy.global_position, _roll_drop())
		dropped = true
	if dropped:
		room.drops_left -= 1


## How many drops `room` still gives (data/loot.json room_budget drops; luck adds luck_extra
## per point, rounded down). Boss kills do not count.
func room_drops_left(room: DungeonRoom) -> int:
	if room.drops_left < 0:
		var rules: Dictionary = Content.get_file("loot").get("room_budget", {})
		room.drops_left = maxi(0, int(rules.get("drops", 1)) + int(floorf(run.stats.luck * float(rules.get("luck_extra", 0.0)))))
	return room.drops_left


## Enemy.take_damage: a number pops up over it (big and golden for a strong hit), the HUD hears it.
func on_enemy_damaged(enemy: Enemy, amount: float, killed: bool) -> void:
	var big: bool = amount >= run.stats.damage * 1.6
	Fx.damage_number(effects, enemy.aim_point() + Vector3(0, enemy.height * 0.4, 0), amount, big, killed)
	enemy_damaged.emit(enemy, amount, killed)


## Chance that a normal enemy drops a key (data/loot.json "key_chance", one value for all).
func key_drop_chance() -> float:
	return maxf(0.0, float(Content.get_file("loot").get("key_chance", 0.0)))


func _clear_room(room: DungeonRoom) -> void:
	_fighting = false
	room.cleared = true
	for door: Door in doors_of(room.cell):
		door.set_closed(false)
	if room == altar:
		altar.on_cleared()
		# Between the altar and the gate back: the golden light.
		_boss_rewards(room, Vector3(0, 0, 4.5), true)
		AudioManager.play_music(String(floor_data.get("music", "")))
		return
	if room == chasm:
		chasm.on_cleared()
		# On the center, in front of the dais: the golden light.
		_boss_rewards(room, Vector3(0, 0, 2.6), true)
		AudioManager.play_music(String(floor_data.get("music", "")))
		return
	if room.type == FloorLayout.BOSS:
		AudioManager.play_music(String(floor_data.get("music", "")))
		_boss_rewards(room, Vector3.ZERO, end_boss_id.is_empty())
		# Egon's errand: only after a real victory over the boss, the rope next to the trapdoor.
		if _boss_beaten and MetaState.rope_due(Content.dungeon_id(), floor_index):
			_drop_rope(room)
		return
	var drops: Dictionary = Content.floors_extra("room_drops")
	if room_drops_left(room) > 0 and _rng.randf() < float(drops.get("chance", 0.4)) + run.stats.luck * _luck_drop():
		_drop(room, room.position, _roll_drop())
		room.drops_left -= 1


## Extra drop chance per point of luck (data/player.json effects).
func _luck_drop() -> float:
	return float((Content.player().get("effects", {}) as Dictionary).get("luck_drop", 0.08))


func _roll_drop() -> String:
	var drops: Dictionary = Content.floors_extra("room_drops")
	return Content.pick_weighted(drops.get("table", [["heart", 1]]), _rng)


## true on the last floor of the dungeon.
func is_last_floor() -> bool:
	return floor_index >= Content.floors().size() - 1


## After a boss, at `base` (local to `room`): the way on, the boss item behind it, a heart beside
## it. `way_down`: a trapdoor (the golden light on the last floor); else (the boss of the last
## floor of a dungeon with an end boss) the portal to the Boss-Altar.
func _boss_rewards(room: DungeonRoom, base: Vector3, way_down: bool) -> void:
	if way_down:
		var trapdoor := Trapdoor.new()
		trapdoor.final = is_last_floor()
		trapdoor.player = player
		trapdoor.entered.connect(func() -> void: trapdoor_entered.emit(trapdoor.final))
		room.add_child(trapdoor)
		trapdoor.position = base
	else:
		_portal = Portal.new()
		_portal.name = "Portal"
		room.add_child(_portal)
		_portal.position = base
		player.shake(0.5)
	var first: Pedestal = _add_item_pedestal(room, base + Vector3(0, 0, -2.8), "boss", 0)
	# "choice": a second boss item; taking one makes the other vanish.
	if run.stats.has("choice") and first:
		first.position.x = -1.2
		var second: Pedestal = _add_item_pedestal(room, base + Vector3(1.2, 0, -2.8), "boss", 0)
		if second:
			first.taken.connect(func(_p: Pedestal) -> void: second.show_item(""))
			second.taken.connect(func(_p: Pedestal) -> void: first.show_item(""))
	_drop(room, room.position + base + Vector3(2.0, 0, 0), "heart")
	if room == altar or room == chasm:
		message.emit("Du hast den Dungeon bezwungen!")
		return
	_open_special_room()
	if not way_down:
		message.emit("Ein Portal öffnet sich!")
	elif is_last_floor():
		message.emit("Du hast den Dungeon bezwungen!")
	else:
		message.emit("Der Weg nach unten ist frei!")


func _drop(room: DungeonRoom, at: Vector3, kind: String) -> void:
	# Bombs and keys are loot for the bag (loot.json bomb / key).
	if kind == "bomb" or kind == "key":
		_drop_loot(room, at, Bag.BOMB if kind == "bomb" else Bag.KEY, 1, false)
		return
	var pickup := Pickup.new()
	pickup.setup(kind, run, player)
	room.add_child(pickup)
	pickup.global_position = Vector3(at.x, 0, at.z)
	room.loot.append(pickup)


## Loot for the bag (data/loot.json "enemies"): every entry is rolled on its own; luck helps.
## `one`: stop after the first piece (normal enemies). true if something dropped.
func _drop_enemy_loot(enemy: Enemy, one: bool = false) -> bool:
	var luck_bonus: float = float(Content.get_file("loot").get("luck_bonus", 0.03)) * run.stats.luck
	var dropped: bool = false
	for entry: Dictionary in Content.enemy_loot(enemy.id):
		if _rng.randf() >= float(entry.get("chance", 0.0)) + luck_bonus:
			continue
		var range_of: Array = entry.get("amount", [1, 1])
		var count: int = _rng.randi_range(int(range_of[0]), int(range_of[-1]))
		if one:
			count = 1
		var spot: Vector3 = enemy.global_position + Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5))
		if _drop_loot(rooms[current_cell], spot, String(entry.get("id", "")), count, false) != null:
			dropped = true
			if one:
				return true
	return dropped


## Coins (data/loot.json "coins"): normal enemies by chance (luck helps), bosses always; deeper
## floors give a few more. They lie as one pile of gold (Bag.GOLD, stacks to 999 in the bag).
## true if coins dropped.
func _drop_coins(enemy: Enemy) -> bool:
	var rules: Dictionary = Content.get_file("loot").get("coins", {})
	if rules.is_empty():
		return false
	var luck_bonus: float = float(Content.get_file("loot").get("luck_bonus", 0.03)) * run.stats.luck
	if not enemy.is_boss and not enemy.is_leader and _rng.randf() >= float(rules.get("chance", 0.0)) + luck_bonus:
		return false
	var range_of: Array = rules.get("boss_amount" if enemy.is_boss else "amount", [1, 1])
	var count: int = _rng.randi_range(int(range_of[0]), int(range_of[-1])) + int(rules.get("per_floor", 0)) * floor_index
	var spot: Vector3 = enemy.global_position + Vector3(_rng.randf_range(-0.4, 0.4), 0, _rng.randf_range(-0.4, 0.4))
	return _drop_loot(rooms[current_cell], spot, Bag.GOLD, count, false) != null


func _drop_loot(room: DungeonRoom, at: Vector3, id: String, count: int, dropped: bool) -> Pickup:
	if Content.material(id).is_empty() or count <= 0:
		return null
	var pickup := Pickup.new()
	pickup.setup_loot(id, count, run, player, dropped)
	pickup.bag_full.connect(func() -> void: message.emit("Inventar voll!"))
	room.add_child(pickup)
	var rect: Rect2 = rect_of(room.cell, 0.6)
	pickup.global_position = Vector3(clampf(at.x, rect.position.x, rect.end.x), 0, clampf(at.z, rect.position.y, rect.end.y))
	room.loot.append(pickup)
	return pickup


## Bag window: place `index` is thrown on the floor in front of the player (to make room).
func drop_from_bag(index: int) -> Pickup:
	# Gear, relics and potions have no pickup: they stay in the bag.
	if Bag.is_piece(run.bag.get_place(index)):
		return null
	var place: Dictionary = run.bag.take(index)
	if place.is_empty():
		return null
	var forward: Vector3 = -player.global_transform.basis.z
	forward.y = 0.0
	var at: Vector3 = player.global_position + forward.normalized() * 0.9
	return _drop_loot(rooms[current_cell], at, String(place["id"]), int(place["count"]), true)


## true while the player stands in the shop room.
func in_shop() -> bool:
	return rooms.has(current_cell) and (rooms[current_cell] as DungeonRoom).type == FloorLayout.SHOP


## true when the player is close enough to the merchant to talk to him (F, floors.json shop
## talk_distance).
func near_merchant() -> bool:
	if keeper == null or player == null or run.is_dead() or not in_shop():
		return false
	var offset: Vector3 = (player.global_position - keeper.global_position) * Vector3(1, 0, 1)
	return offset.length() <= float(Content.floors_extra("shop").get("talk_distance", 3.5))


## Trade window, right click: the merchant buys place `index` (RunState.sell_from_bag).
## Returns the gold (0 = nothing sold: not talking to him, or nothing to sell).
func sell_from_bag(index: int) -> int:
	if not trading or not in_shop():
		return 0
	var gold: int = run.sell_from_bag(index)
	if gold > 0:
		AudioManager.play_sound("coin")
	return gold


## Trade window: buys the merchant's relic with the gold of the bag. It goes home at once (into
## the inventory at Egon's, MetaState.give_piece), so it stays even if the player dies.
func buy_relic() -> bool:
	if not trading or merchant_relic.is_empty() or run.is_dead():
		return false
	if not run.spend(int(merchant_relic.get("price", 0))):
		message.emit("Dafür reicht dein Gold nicht")
		return false
	MetaState.give_piece(merchant_relic)
	merchant_relic = {}
	AudioManager.play_sound("coin")
	message.emit("Gekauft! Das Relikt wartet zu Hause im Inventar.")
	return true


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
		"blue_heart":
			run.add_blue_hearts(1)
		"item":
			_add_item_pedestal(room, Vector3(0, 0, -2.5), "item", 0)
		_:
			# A loot id (loot.json) falls out as loot, else a pickup (heart, bomb, key).
			if not Content.material(String(entry[0])).is_empty():
				_drop_loot(room, at, String(entry[0]), 1, false)
			else:
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
		var rect: Rect2 = room_rect(0.6)
		at = Vector3(clampf(at.x, rect.position.x, rect.end.x), 0, clampf(at.z, rect.position.y, rect.end.y))
		_drop(room, at, String(list[i]))


## blue_burst: a lost blue heart hurts every enemy in the room.
func _on_blue_heart_lost() -> void:
	var amount: float = float((Content.player().get("effects", {}) as Dictionary).get("blue_burst_damage", 12.0))
	Fx.explosion(effects, player.global_position, 3.0)
	for enemy: Enemy in enemies.duplicate():
		enemy.take_damage(amount, Vector3.ZERO, false)


# --- Boss-Altar, portal, rope ---------------------------------------------------------

## Walkable area (world x/z) of the room at `cell`, `margin` metres from the walls; the Boss-Altar
## is bigger than the other rooms.
func rect_of(cell: Vector2i, margin: float) -> Rect2:
	if altar and cell == ALTAR_CELL:
		return altar.inner_rect(margin)
	if chasm and cell == CHASM_CELL:
		return chasm.inner_rect(margin)
	return RoomBuilder.inner_rect(cell, margin)


## Walkable area of the room the player is in (enemies, traps and the player stay inside).
func room_rect(margin: float) -> Rect2:
	return rect_of(current_cell, margin)


## Size (x, z in metres, walls included) of the room at `cell` (the map draws it).
func room_size(cell: Vector2i) -> Vector2:
	if altar and cell == ALTAR_CELL:
		return (altar.half + Vector2(RoomBuilder.WALL_T, RoomBuilder.WALL_T)) * 2.0
	if chasm and cell == CHASM_CELL:
		return (chasm.half + Vector2(RoomBuilder.WALL_T, RoomBuilder.WALL_T)) * 2.0
	return Vector2(RoomBuilder.ROOM_W, RoomBuilder.ROOM_D)


func in_boss_altar() -> bool:
	return altar != null and current_cell == ALTAR_CELL


## The portal in the boss room (after the boss of the last floor); null before.
func get_portal() -> Portal:
	return _portal


## Walking into the open portal leads to the Boss-Altar. true if it did (the player is
## somewhere else now: nothing more this frame).
func _check_portal(pos: Vector3) -> bool:
	if _portal == null or not _portal.is_open() or current_cell != layout.cell_of(FloorLayout.BOSS):
		return false
	var offset: Vector3 = pos - _portal.global_position
	offset.y = 0.0
	if offset.length() >= PORTAL_TOUCH:
		return false
	if String(Content.dungeon().get("end_room", "")) == GearChasm.TYPE:
		enter_gear_chasm()
	else:
		enter_boss_altar()
	return true


## Into the Boss-Altar (built the first time), in front of its gate, looking at the altar.
func enter_boss_altar() -> void:
	if end_boss_id.is_empty():
		end_boss_id = Content.end_boss()
	if end_boss_id.is_empty():
		end_boss_id = boss_id
	if altar == null:
		altar = BossAltar.new()
		altar.setup(self, player, ALTAR_CELL)
		add_child(altar)
		rooms[ALTAR_CELL] = altar
		altar.cutscene_changed.connect(cutscene_changed.emit)
		_build_arena(altar, end_boss_id)
	current_cell = ALTAR_CELL
	altar.visited = true
	_show_near(ALTAR_CELL)
	_move_player(altar.arrival_point())
	player.rotation.y = 0.0
	player.camera.rotation.x = 0.0
	run.refresh_mantle()
	room_entered.emit(ALTAR_CELL)
	altar.on_enter()


## Back from the Boss-Altar into the boss room, in front of the portal (only after the end boss).
func leave_boss_altar() -> void:
	var cell: Vector2i = layout.cell_of(FloorLayout.BOSS)
	altar.on_leave()
	current_cell = cell
	_show_near(cell)
	var room: DungeonRoom = rooms[cell]
	var at: Vector3 = room.global_position + Vector3(0, 0, 1.0) * (PORTAL_TOUCH + 1.2)
	if _portal:
		at = _portal.global_position + Vector3(0, 0, PORTAL_TOUCH + 1.2)
	_move_player(Vector3(at.x, 0.0, at.z))
	room_entered.emit(cell)
	AudioManager.play_music(String(floor_data.get("music", "")))


## The end boss lands in the Boss-Altar (BossAltar at the end of its scene): the fight starts.
func start_boss_fight(at: Vector3) -> Enemy:
	_fighting = true
	boss = spawn_enemy(end_boss_id, at)
	boss_appeared.emit(boss)
	return boss


## The very first boss: a rope falls from the sky in the middle of `room`, nothing else.
func _drop_rope(room: DungeonRoom) -> void:
	_rope = Rope.new()
	_rope.name = "Rope"
	_rope.player = player
	_rope.grabbed.connect(rope_grabbed.emit)
	room.add_child(_rope)
	_rope.position = ROPE_SPOT
	message.emit("Ein Seil fällt vom Himmel!")


## The rope after the first boss; null on other floors.
func get_rope() -> Rope:
	return _rope


## The player climbs the rope out of the dungeon (RunScene calls it after rope_grabbed): steps
## to it, looks up, climbs. Returns when they are up (or the scene is gone).
func climb_rope() -> void:
	if _rope == null:
		return
	player.controls_enabled = false
	player.invulnerable = 999.0
	player.velocity = Vector3.ZERO
	# The player's own movement (gravity) stops while they hang on the rope.
	player.set_physics_process(false)
	var to_rope: Vector3 = (_rope.global_position - player.global_position) * Vector3(1, 0, 1)
	if to_rope.length() < 0.05:
		to_rope = Vector3.FORWARD
	var hold: Vector3 = _rope.global_position - to_rope.normalized() * 0.35
	var tween := create_tween()
	tween.tween_property(player, "global_position", Vector3(hold.x, player.global_position.y, hold.z), 0.3)
	tween.parallel().tween_property(player, "rotation:y", atan2(-to_rope.x, -to_rope.z), 0.3)
	tween.tween_property(player.camera, "rotation:x", 0.9, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(player, "global_position:y", player.global_position.y + CLIMB_HEIGHT, CLIMB_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var steps: int = 6
	for i in steps:
		get_tree().create_timer(0.8 + i * CLIMB_TIME / steps, false).timeout.connect(func() -> void:
			if is_inside_tree():
				AudioManager.play_sound("rope_climb", randf_range(0.9, 1.1)))
	await tween.finished


## Admin menu: ends a fight at once (enemies gone without their death tricks, doors open).
func end_fight_now() -> void:
	for enemy: Enemy in enemies.duplicate():
		enemy.take_damage(Enemy.FORCED_DAMAGE, Vector3.ZERO, false)
	if _fighting and rooms.has(current_cell):
		_clear_room(rooms[current_cell])


## Admin menu: to the middle of the room at `cell` of this floor (ends a fight first).
func teleport_to_cell(cell: Vector2i) -> void:
	if not layout.rooms.has(cell):
		return
	end_fight_now()
	if in_boss_altar():
		altar.on_leave()
	if in_gear_chasm():
		chasm.on_leave()
	_move_player(RoomBuilder.cell_center(cell) + Vector3(0, 0, 1.5))
	_enter_room(cell)


## Admin menu: straight into the Boss-Altar (ends a fight first).
func teleport_to_boss_altar() -> void:
	end_fight_now()
	enter_boss_altar()


# --- Räderkluft ------------------------------------------------------------------------------

func in_gear_chasm() -> bool:
	return chasm != null and current_cell == CHASM_CELL


## In the hall of the end boss (Boss-Altar or Räderkluft).
func in_end_hall() -> bool:
	return in_boss_altar() or in_gear_chasm()


## Into the Räderkluft (built the first time), on its south door platform, looking at the
## center; the end boss of the dungeon appears on the dais (not again once beaten). From the
## portal of the last floor, or the admin menu (ends a fight first).
func enter_gear_chasm() -> void:
	end_fight_now()
	if in_boss_altar():
		altar.on_leave()
	if chasm == null:
		chasm = GearChasm.new()
		chasm.setup(self, player, CHASM_CELL)
		add_child(chasm)
		rooms[CHASM_CELL] = chasm
	current_cell = CHASM_CELL
	chasm.visited = true
	_show_near(CHASM_CELL)
	_move_player(chasm.arrival_point())
	player.rotation.y = 0.0
	player.camera.rotation.x = 0.0
	run.refresh_mantle()
	room_entered.emit(CHASM_CELL)
	chasm.on_enter()
	message.emit(String(chasm.settings.get("name", "")))
	if chasm.cleared or boss != null:
		return
	if end_boss_id.is_empty():
		end_boss_id = Content.end_boss()
	if end_boss_id.is_empty():
		end_boss_id = boss_id
	_fighting = true
	boss = spawn_enemy(end_boss_id, chasm.boss_spot())
	boss.pinned = true
	boss_appeared.emit(boss)


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
	if in_gear_chasm():
		chasm.on_leave()
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
	label.text = Language.translate("Testraum · P: Admin-Menü")
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
		for prop: BreakableProp in room.breakables.duplicate():
			if Vector2(prop.global_position.x - at.x, prop.global_position.z - at.z).length() < radius + 0.3:
				break_prop(prop)
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
	rock.queue_free()


## A crate, barrel … breaks (shot, sword swing or bomb): pieces fly apart, and with the chance in
## floors.json props "break" coins fall out. Coins count against the room's drop budget
## (loot.json room_budget), so crates never give more than the room allows.
func break_prop(prop: BreakableProp) -> void:
	if not is_instance_valid(prop) or prop.is_queued_for_deletion():
		return
	var at: Vector3 = prop.global_position
	var room: DungeonRoom = rooms.get(RoomBuilder.cell_at(at))
	if room:
		room.breakables.erase(prop)
	Fx.shards(effects, at, prop.sprite.texture, prop.sprite.pixel_size * float(prop.sprite.texture.get_height()))
	AudioManager.play_sound_at(prop.sound, at, effects, randf_range(0.9, 1.1))
	prop.queue_free()
	if room == null or run.is_dead() or room_drops_left(room) <= 0:
		return
	var rules: Dictionary = (Content.floors_extra("props") as Dictionary).get("break", {})
	var luck_bonus: float = float(Content.get_file("loot").get("luck_bonus", 0.03)) * run.stats.luck
	if _rng.randf() >= float(rules.get("coin_chance", 0.0)) + luck_bonus:
		return
	var range_of: Array = rules.get("coins", [1, 1])
	var spot: Vector3 = at.move_toward(room.global_position, 0.6)
	if _drop_loot(room, spot, Bag.GOLD, _rng.randi_range(int(range_of[0]), int(range_of[-1])), false) != null:
		room.drops_left -= 1
