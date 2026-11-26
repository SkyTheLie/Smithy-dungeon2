class_name PokerTable
extends Station
## The poker table in the gambling den: E opens its PokerMenu (connected in the scene). The three
## chairs around it (`seat_nodes`: left, top, right = DenPoker seats 1, 2, 3) show the bots who
## sit there today with their sit picture (economy.json gambling_den.poker.bots "sprite"); an
## empty seat or a broke bot shows nobody.

## Seat bodies (StaticBody2D with a Sprite2D and a CollisionShape2D), seats 1..3 of DenPoker.
@export var seat_nodes: Array[NodePath] = []


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	GameState.gambling_den.prepare_poker_table()
	GameState.gambling_den.poker_table_changed.connect(_refresh_seats)
	_refresh_seats()


func _refresh_seats() -> void:
	var den: GamblingDen = GameState.gambling_den
	for i in seat_nodes.size():
		var body: Node2D = get_node_or_null(seat_nodes[i])
		if body == null:
			continue
		var id: String = den.poker_seats[i] if i < den.poker_seats.size() else ""
		var sprite_path: String = str(GamblingDen.get_poker_bot(id).get("sprite", ""))
		var here: bool = not id.is_empty() and den.get_bot_stack(id) > 0 and ResourceLoader.exists(sprite_path)
		body.visible = here
		var shape: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
		if shape:
			shape.set_deferred("disabled", not here)
		if here:
			(body.get_node("Sprite2D") as Sprite2D).texture = load(sprite_path)


## Whose seat a chair is (tests): the bot id at seat `index` (0 = left) or "".
func get_seat_bot(index: int) -> String:
	var den: GamblingDen = GameState.gambling_den
	return den.poker_seats[index] if index < den.poker_seats.size() else ""
