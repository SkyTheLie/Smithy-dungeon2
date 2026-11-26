class_name CustomerSpawner
extends Node2D
## Places the waiting customers (GameState.customers.get_waiting()) in front of the smithy:
## one CustomerNpc per waiting customer, at the Marker2D children of this node (in order).
## Updates itself when customers arrive, leave or are talked to.

const CUSTOMER_SCENE: PackedScene = preload("res://scenes/actors/customer_npc.tscn")

## Visitor -> CustomerNpc standing in the world.
var _npcs: Dictionary = {}


func _ready() -> void:
	GameState.customers.changed.connect(_sync)
	_sync()


func _sync() -> void:
	var waiting: Array[Customers.Visitor] = GameState.customers.get_waiting()
	for visitor: Customers.Visitor in _npcs.keys():
		if not waiting.has(visitor):
			(_npcs[visitor] as Node).queue_free()
			_npcs.erase(visitor)
	var spots: Array[Node] = get_children().filter(func(child: Node) -> bool: return child is Marker2D)
	for visitor in waiting:
		if _npcs.has(visitor):
			continue
		var spot: Marker2D = _get_free_spot(spots)
		if spot == null:
			break
		var npc: CustomerNpc = CUSTOMER_SCENE.instantiate()
		npc.visitor = visitor
		npc.position = spot.position
		npc.set_meta("spot", spot)
		# Same parent as the player, so the y-sorting works.
		add_child(npc)
		_npcs[visitor] = npc


func _get_free_spot(spots: Array[Node]) -> Marker2D:
	for spot: Marker2D in spots:
		var used: bool = false
		for npc: Node in _npcs.values():
			used = used or npc.get_meta("spot") == spot
		if not used:
			return spot
	return null
