class_name GuildPatrons
extends Node2D
## Seats the heroes that can be hired in the guild (the GuildMenu's list, minus those already
## hired) at the tables: a different number per table (`group_sizes`, e.g. 2, alone, 3, 4).
## Every table is a child Node2D with four Marker2D seats: SeatL1, SeatL2 (left of the table,
## the hero looks right) and SeatR1, SeatR2 (right of the table, looks left). Hidden tables (the
## small guild, GuildHallLayout) stay empty. The heroes are drawn
## with CharacterBaker from their appearance, like the portraits in the hire menu, and sit on
## the chair (the lower legs are cut off, the backrest is drawn in front of them). Hired heroes
## leave their seat.

## The GuildMenu with the heroes on offer.
@export var guild_menu: GuildMenu
## How many heroes sit at each table (shuffled every day, repeats when there are more tables).
@export var group_sizes: Array[int] = [2, 1, 3, 4]

## Height of the cushion above the chair's foot point (guild_chair.png).
const SEAT_HEIGHT: float = 12.0
## The chair's backrest alone, same size as guild_chair.png: in front of the hero.
const BACKREST: Texture2D = preload("res://assets/sprites/furniture/guild_chair_back.png")
## Rows of the 48x48 character frame that stay visible (head down to just below the hip,
## so the hero sits on the cushion instead of standing in front of the chair).
const VISIBLE_ROWS: float = 34.0
## Hip height inside the character frame.
const HIP_IN_FRAME: float = 31.0
## The hero leans a little towards the table.
const LEAN: float = 3.0
const SEAT_ORDER: Array[String] = ["SeatL1", "SeatR1", "SeatL2", "SeatR2"]
## Radius around a seated hero in which E shows his card (GuildHeroCard).
const TALK_RADIUS: float = 18.0

var _seated: Array[Node] = []
## Seated heroes the player stands next to (latest last).
var _in_range: Array[Hero] = []
var _card: GuildHeroCard


func _ready() -> void:
	_card = GuildHeroCard.new()
	add_child(_card)
	GameState.heroes_changed.connect(_rebuild, CONNECT_DEFERRED)
	_rebuild()


## E next to a seated hero: his card (level, class, values); E again closes it (the card).
func _unhandled_input(event: InputEvent) -> void:
	if _in_range.is_empty() or _card.visible or not event.is_action_pressed("interact"):
		return
	_card.show_hero(_in_range.back())
	get_viewport().set_input_as_handled()


func _on_talk_area_entered(body: Node2D, hero: Hero) -> void:
	if body is Player and not _in_range.has(hero):
		_in_range.append(hero)


func _on_talk_area_exited(body: Node2D, hero: Hero) -> void:
	if body is Player:
		_in_range.erase(hero)
		if _card.hero == hero:
			_card.close()


func _rebuild() -> void:
	for node in _seated:
		node.queue_free()
	_seated.clear()
	_in_range.clear()
	if _card:
		_card.close()
	if guild_menu == null:
		return
	var waiting: Array[Hero] = []
	for hero in guild_menu.get_offered_heroes():
		if not GameState.has_hero(hero.id):
			waiting.append(hero)
	var tables: Array[Node] = get_children().filter(func(n: Node) -> bool: return n.has_node("SeatL1") and n.visible)
	var sizes: Array[int] = _sizes_of_today()
	var next: int = 0
	for t in tables.size():
		var count: int = mini(sizes[t % sizes.size()], SEAT_ORDER.size())
		for s in count:
			if next >= waiting.size():
				return
			_seat(waiting[next], tables[t].get_node(SEAT_ORDER[s]) as Marker2D)
			next += 1


func _seat(hero: Hero, seat: Marker2D) -> void:
	var looks_right: bool = seat.name.begins_with("SeatL")
	var sprite := Sprite2D.new()
	sprite.texture = CharacterBaker.get_sheet(hero.get_appearance())
	sprite.region_enabled = true
	var rect: Rect2 = CharacterBaker.get_frame_rect("right" if looks_right else "left")
	rect.size.y = VISIBLE_ROWS
	sprite.region_rect = rect
	sprite.centered = false
	sprite.offset = Vector2(-rect.size.x / 2.0 + (LEAN if looks_right else -LEAN), -HIP_IN_FRAME)
	sprite.position = seat.position + Vector2(0.0, -SEAT_HEIGHT)
	sprite.z_index = 1  # in front of the chair it sits on
	seat.get_parent().add_child(sprite)
	_seated.append(sprite)
	var backrest := Sprite2D.new()
	backrest.texture = BACKREST
	backrest.flip_h = not looks_right
	backrest.offset = Vector2(0.0, -BACKREST.get_height() / 2.0)
	backrest.position = seat.position
	backrest.z_index = 2  # the hero sits between the seat and the backrest
	seat.get_parent().add_child(backrest)
	_seated.append(backrest)
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = TALK_RADIUS
	shape.shape = circle
	area.add_child(shape)
	area.position = seat.position
	area.body_entered.connect(_on_talk_area_entered.bind(hero))
	area.body_exited.connect(_on_talk_area_exited.bind(hero))
	seat.get_parent().add_child(area)
	_seated.append(area)


## `group_sizes` in a different order every day (same order all day long).
func _sizes_of_today() -> Array[int]:
	var sizes: Array[int] = group_sizes.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("guild_tables_%d" % GameState.day_cycle.day)
	for i in range(sizes.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = sizes[i]
		sizes[i] = sizes[j]
		sizes[j] = swap
	return sizes
