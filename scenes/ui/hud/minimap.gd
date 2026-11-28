class_name Minimap
extends Control
## The map at the top right. Small: the room the player is in, seen from above: walls, doors
## (grey open, brown closed, gold locked), rocks, things to take (yellow), enemies as red dots and
## the player as a green dot with a line for the view direction.
## M (toggle): zooms out to the whole floor in the middle of the screen: every room (visited ones
## lighter), the item room (chest), the shop (coin), the boss room (boss picture), and inside the
## current room again the red and green dots. The big map always fits: a big floor is zoomed out
## until every known room is on it.
## always_big = only the big map, without darkening the screen (next to the bag window, Tab).

const SMALL_SCALE: float = 7.0
const SMALL_MARGIN: float = 6.0
const BIG_CELL := Vector2(34, 25)
const BIG_GAP: float = 6.0
const ZOOM_TIME: float = 0.18
## Free space around the big map (pixels) when it is fitted.
const FIT_MARGIN: float = 20.0
## Loot pictures: on the small map (pixels), in the current room of the big map (metres), and in
## the row along the bottom of other rooms on the big map (pixels before fitting).
const SMALL_ICON: float = 9.0
const BIG_ICON_METRES: float = 2.2
const ROW_ICON: float = 8.0

const COLOR_PANEL := Color(0.05, 0.04, 0.06, 0.78)
const COLOR_FLOOR := Color(0.24, 0.2, 0.2)
const COLOR_WALL := Color(0.62, 0.55, 0.5)
const COLOR_DOOR_OPEN := Color(0.5, 0.5, 0.5)
const COLOR_DOOR_CLOSED := Color(0.55, 0.32, 0.18)
const COLOR_DOOR_LOCKED := Color(0.95, 0.78, 0.25)
const COLOR_ROCK := Color(0.45, 0.45, 0.48)
const COLOR_LOOT := Color(1.0, 0.88, 0.3)
const COLOR_ENEMY := Color(0.95, 0.18, 0.15)
const COLOR_PLAYER := Color(0.3, 1.0, 0.35)
const COLOR_ROOM_SEEN := Color(0.55, 0.5, 0.48)
const COLOR_ROOM_NEW := Color(0.2, 0.18, 0.2)
const COLOR_ROOM_NOW := Color(0.95, 0.92, 0.85)

const ICON_ITEM: Texture2D = preload("res://assets/sprites/props/chest.png")
const ICON_SHOP: Texture2D = preload("res://assets/sprites/ui/slot/coin.png")

var dungeon: Dungeon
var player: Player
## 0 = small map, 1 = whole floor.
var zoom: float = 0.0
var expanded: bool = false
## Only the whole floor, fitted into this control (the map beside the bag window).
var always_big: bool = false

var _boss_icon: Texture2D
var _tween: Tween


func setup(the_dungeon: Dungeon, the_player: Player) -> void:
	dungeon = the_dungeon
	player = the_player
	var boss_sprite: String = String(Content.enemy(String(dungeon.floor_data.get("boss", ""))).get("sprite", ""))
	if ResourceLoader.exists(boss_sprite + ".png"):
		_boss_icon = load(boss_sprite + ".png") as Texture2D


func toggle() -> void:
	expanded = not expanded
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "zoom", 1.0 if expanded else 0.0, ZOOM_TIME)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if dungeon == null or player == null or dungeon.layout == null:
		return
	if always_big:
		_draw_big(1.0)
		return
	if zoom < 1.0:
		_draw_small(1.0 - zoom)
	if zoom > 0.0:
		_draw_big(zoom)


# --- Small map: the current room ---------------------------------------------------------

func _draw_small(alpha: float) -> void:
	# A bigger room (the boss hall) is drawn smaller, so it fits the same box.
	var real_size: Vector2 = dungeon.room_size(dungeon.current_cell)
	var scale_by: float = SMALL_SCALE * minf(RoomBuilder.ROOM_W / real_size.x, RoomBuilder.ROOM_D / real_size.y)
	var room_size: Vector2 = real_size * scale_by
	var origin := Vector2(size.x - room_size.x - SMALL_MARGIN - 4.0, SMALL_MARGIN + 4.0)
	draw_rect(Rect2(origin - Vector2(4, 4), room_size + Vector2(8, 8)), _fade(COLOR_PANEL, alpha))
	var center: Vector3 = RoomBuilder.cell_center(dungeon.current_cell)
	_draw_room_inside(origin, room_size, center, scale_by, alpha, true)


## Walls, doors, rocks, loot, enemies and the player of the current room, drawn into
## Rect2(origin, room_size) with `scale` pixels per metre.
func _draw_room_inside(origin: Vector2, room_size: Vector2, center: Vector3, scale_by: float, alpha: float, detailed: bool) -> void:
	var wall: float = RoomBuilder.WALL_T * scale_by
	draw_rect(Rect2(origin, room_size), _fade(COLOR_WALL, alpha))
	draw_rect(Rect2(origin + Vector2(wall, wall), room_size - Vector2(wall, wall) * 2.0), _fade(COLOR_FLOOR, alpha))
	var to_map := func(world: Vector3) -> Vector2:
		return origin + room_size / 2.0 + Vector2(world.x - center.x, world.z - center.z) * scale_by
	for door: Door in dungeon.doors:
		if not door.cells.has(dungeon.current_cell) or door.hidden:
			continue
		var color: Color = COLOR_DOOR_LOCKED if door.locked else (COLOR_DOOR_CLOSED if door.closed else COLOR_DOOR_OPEN)
		var at: Vector2 = to_map.call(door.global_position)
		var along_x: bool = door.cells[0].x == door.cells[1].x
		var half := Vector2(RoomBuilder.DOOR_W / 2.0 * scale_by, wall) if along_x else Vector2(wall, RoomBuilder.DOOR_W / 2.0 * scale_by)
		draw_rect(Rect2(at - half, half * 2.0), _fade(color, alpha))
	var room: DungeonRoom = dungeon.get_room(dungeon.current_cell)
	if room and detailed:
		for rock: Rock in room.rocks:
			draw_circle(to_map.call(rock.global_position), maxf(1.5, Rock.RADIUS * scale_by), _fade(COLOR_ROCK, alpha))
	if room:
		# What still lies here: its own picture (small map bigger, big map smaller).
		var icon_px: float = SMALL_ICON if detailed else maxf(4.0, scale_by * BIG_ICON_METRES)
		for thing: Node3D in room.loot:
			var icon: Texture2D = _loot_icon(thing)
			if icon:
				var at: Vector2 = to_map.call(thing.global_position)
				draw_texture_rect(icon, Rect2(at - Vector2(icon_px, icon_px) / 2.0, Vector2(icon_px, icon_px)), false, _fade(Color.WHITE, alpha))
			elif is_instance_valid(thing) and thing is Pickup:
				draw_circle(to_map.call(thing.global_position), 2.0, _fade(COLOR_LOOT, alpha))
	for enemy: Enemy in dungeon.get_enemies():
		if enemy.is_unseen():
			continue
		draw_circle(to_map.call(enemy.global_position), maxf(2.0, enemy.radius * scale_by * 0.8), _fade(COLOR_ENEMY, alpha))
	var me: Vector2 = to_map.call(player.global_position)
	var look: Vector3 = player.aim_direction()
	var look_2d := Vector2(look.x, look.z).normalized()
	draw_line(me, me + look_2d * 7.0, _fade(COLOR_PLAYER, alpha), 1.0)
	draw_circle(me, 2.5, _fade(COLOR_PLAYER, alpha))


# --- Big map: the whole floor ----------------------------------------------------------------

func _draw_big(alpha: float) -> void:
	var cells: Array[Vector2i] = dungeon.known_cells()
	var low := Vector2i(999, 999)
	var high := Vector2i(-999, -999)
	for cell: Vector2i in cells:
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	# Zoomed out as far as needed so the whole known floor fits (never zoomed in).
	var full_grid := Vector2(high - low + Vector2i.ONE) * (BIG_CELL + Vector2(BIG_GAP, BIG_GAP)) - Vector2(BIG_GAP, BIG_GAP)
	var room_for := size - Vector2(FIT_MARGIN, FIT_MARGIN) * 2.0
	var fit: float = clampf(minf(room_for.x / full_grid.x, room_for.y / full_grid.y), 0.2, 1.0)
	var cell_size: Vector2 = (BIG_CELL * fit).floor()
	var gap: float = maxf(2.0, floorf(BIG_GAP * fit))
	var step := cell_size + Vector2(gap, gap)
	var grid_size := Vector2(high - low + Vector2i.ONE) * step - Vector2(gap, gap)
	var origin: Vector2 = ((size - grid_size) / 2.0).floor()
	if not always_big:
		draw_rect(Rect2(Vector2.ZERO, size), _fade(Color(0, 0, 0, 0.55), alpha))
	draw_rect(Rect2(origin - Vector2(14, 14) * fit, grid_size + Vector2(28, 28) * fit), _fade(COLOR_PANEL, alpha))
	# Connections between neighbouring rooms.
	for door: Door in dungeon.doors:
		if door.hidden or not cells.has(door.cells[0]) or not cells.has(door.cells[1]):
			continue
		# Only ways out of rooms that were visited.
		if not dungeon.get_room(door.cells[0]).visited and not dungeon.get_room(door.cells[1]).visited:
			continue
		var a: Vector2 = origin + Vector2(door.cells[0] - low) * step + cell_size / 2.0
		var b: Vector2 = origin + Vector2(door.cells[1] - low) * step + cell_size / 2.0
		var color: Color = COLOR_DOOR_LOCKED if door.locked else COLOR_ROOM_SEEN
		draw_line(a, b, _fade(color, alpha), maxf(1.0, 3.0 * fit))
	for cell: Vector2i in cells:
		var rect := Rect2(origin + Vector2(cell - low) * step, cell_size)
		var room: DungeonRoom = dungeon.get_room(cell)
		var color: Color = COLOR_ROOM_SEEN if room.visited else COLOR_ROOM_NEW
		# The boss room gets a red frame once it is on the map.
		if room.type == FloorLayout.BOSS:
			draw_rect(rect.grow(2.0), _fade(Color(0.75, 0.12, 0.1), alpha))
		if cell == dungeon.current_cell:
			draw_rect(rect.grow(2.0), _fade(COLOR_ROOM_NOW, alpha))
		draw_rect(rect, _fade(color, alpha))
		var icon: Texture2D = null
		match room.type:
			FloorLayout.ITEM:
				icon = ICON_ITEM
			FloorLayout.SHOP:
				icon = ICON_SHOP
			FloorLayout.BOSS:
				icon = _boss_icon
		if cell == dungeon.current_cell:
			var scale_by: float = cell_size.x / RoomBuilder.ROOM_W
			_draw_room_inside(rect.position, cell_size, RoomBuilder.cell_center(cell), scale_by, alpha, false)
		else:
			if icon:
				var icon_size := (Vector2(16, 16) * fit).round()
				draw_texture_rect(icon, Rect2(rect.get_center() - icon_size / 2.0, icon_size), false, _fade(Color.WHITE, alpha))
			if room.visited:
				_draw_loot_row(room, rect, fit, alpha)


## Pictures of what still lies in a visited room, in a row along the bottom of its box. More than
## fit: the last place shows a "+".
func _draw_loot_row(room: DungeonRoom, rect: Rect2, fit: float, alpha: float) -> void:
	var icon_px: float = maxf(5.0, roundf(ROW_ICON * fit))
	var fits: int = maxi(1, floori((rect.size.x - 2.0) / icon_px))
	var total: int = 0
	for thing: Node3D in room.loot:
		if _loot_icon(thing):
			total += 1
	if total == 0:
		return
	var shown: int = mini(total, fits)
	var start := Vector2(rect.get_center().x - shown * icon_px / 2.0, rect.end.y - icon_px - 1.0).round()
	var index: int = 0
	for thing: Node3D in room.loot:
		var icon: Texture2D = _loot_icon(thing)
		if icon == null:
			continue
		var place := Rect2(start + Vector2(index * icon_px, 0), Vector2(icon_px, icon_px))
		if index == shown - 1 and total > shown:
			var mid: Vector2 = place.get_center()
			var arm: float = icon_px * 0.3
			draw_line(mid - Vector2(arm, 0), mid + Vector2(arm, 0), _fade(COLOR_LOOT, alpha), 1.0)
			draw_line(mid - Vector2(0, arm), mid + Vector2(0, arm), _fade(COLOR_LOOT, alpha), 1.0)
			return
		draw_texture_rect(icon, place, false, _fade(Color.WHITE, alpha))
		index += 1


## The picture of a pickup or a full pedestal; null if it is gone or empty. Untyped: picked-up
## things stay in room.loot as freed objects, and those may not be passed as a Node3D.
func _loot_icon(thing: Variant) -> Texture2D:
	if not is_instance_valid(thing):
		return null
	if thing is Pickup:
		return (thing as Pickup).map_icon()
	if thing is Pedestal:
		return (thing as Pedestal).map_icon()
	if thing is Chest:
		return (thing as Chest).map_icon()
	return null


func _fade(color: Color, alpha: float) -> Color:
	return Color(color, color.a * alpha)
