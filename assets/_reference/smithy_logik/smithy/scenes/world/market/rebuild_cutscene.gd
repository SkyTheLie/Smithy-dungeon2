class_name RebuildCutscene
extends StoryCutscene
## The delivery for the rebuilding on the market (dialogue "builder_rebuild_delivered"):
## - rebuild_carry: villagers come from all sides to Konrad, take planks and beams over their heads
##   and carry them to the burnt houses

@export var builder: NodePath
## Where the villagers come from and which house they carry to (map coordinates, pairs).
@export var starts: PackedVector2Array = []
@export var houses: PackedVector2Array = []
@export var helpers: PackedStringArray = ["farmer", "baker", "hunter", "gossip_a"]

const LOAD: Array[String] = ["res://assets/sprites/items/wooden_plank.png", "res://assets/sprites/items/wooden_beam.png"]


func _play_beat(id: String) -> bool:
	if id != "rebuild_carry":
		return false
	_carry()
	return true


func _map(point: Vector2) -> Vector2:
	var parent := get_parent() as Node2D
	return parent.to_global(point) if parent else point


func _carry() -> void:
	var konrad := node2d(builder)
	var pile: Vector2 = (konrad.global_position if konrad else global_position) + Vector2(0, 26)
	for i in mini(helpers.size(), mini(starts.size(), houses.size())):
		_helper(helpers[i], _map(starts[i]), pile + Vector2(-24 + 16 * i, 0), _map(houses[i]), LOAD[i % LOAD.size()], 0.35 * i)


func _helper(resident: String, start: Vector2, pile: Vector2, house: Vector2, load_path: String, delay: float) -> void:
	if delay > 0.0 and not await wait(delay):
		return
	var walker := extra(resident, start)
	walker.modulate.a = 0.0
	create_tween().tween_property(walker, "modulate:a", 1.0, 0.25)
	await walk_extra(walker, PackedVector2Array([Vector2(start.x, pile.y), pile]), 80.0, "up")
	if not is_instance_valid(walker):
		return
	# a plank or a beam over the head
	var piece := Sprite2D.new()
	piece.texture = load(load_path)
	piece.position = Vector2(0, -38)
	walker.add_child(piece)
	AudioManager.play_sound("wood_break", 0.4)
	await walk_extra(walker, PackedVector2Array([Vector2(house.x, pile.y), house]), 90.0, "up")
	if is_instance_valid(walker):
		var fade := create_tween()
		fade.tween_property(walker, "modulate:a", 0.0, 0.3)
		fade.tween_callback(walker.queue_free)
