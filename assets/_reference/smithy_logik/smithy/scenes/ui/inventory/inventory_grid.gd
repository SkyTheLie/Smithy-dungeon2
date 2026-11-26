class_name InventoryGrid
extends GridContainer
## Shows a range of slots of GameState.inventory. Used for both hotbar and bag.

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")

## Index of the first inventory slot this grid shows.
@export var first_slot: int = 0
## How many slots it shows; -1 = all from first_slot on (the bag grows with the backpack).
@export var slot_count: int = 8

var _slot_uis: Array[ItemSlotUI] = []


func _ready() -> void:
	GameState.inventory.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_ensure_slots()
	for i in _slot_uis.size():
		_slot_uis[i].display(GameState.inventory.slots[first_slot + i])


## Adds or removes slot UIs until there is one per shown inventory slot.
func _ensure_slots() -> void:
	var count: int = slot_count if slot_count >= 0 else maxi(0, GameState.inventory.slots.size() - first_slot)
	count = mini(count, GameState.inventory.slots.size() - first_slot)
	while _slot_uis.size() < count:
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		slot_ui.inventory_index = first_slot + _slot_uis.size()
		add_child(slot_ui)
		_slot_uis.append(slot_ui)
	while _slot_uis.size() > count:
		var slot_ui: ItemSlotUI = _slot_uis.pop_back()
		remove_child(slot_ui)
		slot_ui.queue_free()
