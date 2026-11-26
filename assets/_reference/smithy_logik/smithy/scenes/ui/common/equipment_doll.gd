class_name EquipmentDoll
extends Control
## A silhouette with equipment slots around it (hero: 12 slots, player: 4 tools).
## add_slot() places an ItemSlotUI with its centre at a point of this control; while it is
## empty it shows a faint picture of what goes in (slot_hints/equip_<name>.png) and its name
## as tooltip.

## Open equipment windows (hero, character) are in this group: a right click on an inventory
## item asks them (try_quick_equip) to put it on, swapping out what was there.
const QUICK_EQUIP_GROUP: StringName = &"equipment_windows"
const DOLL: Texture2D = preload("res://assets/sprites/ui/doll.png")
const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const SLOT_SIZE: Vector2 = Vector2(28, 28)
## Where the silhouette is drawn (top-left).
const DOLL_OFFSET: Vector2 = Vector2(12, 4)
const HINT_DIR: String = "res://assets/sprites/ui/slot_hints/equip_%s.png"


func _draw() -> void:
	draw_texture(DOLL, DOLL_OFFSET, Color(1, 1, 1, 0.55))


## Adds a slot with its centre at `center`. `hint` = name of its empty-slot picture (e.g.
## "helmet", see HINT_DIR; "" = none). Returns the slot (connect gui_input / drag & drop).
func add_slot(center: Vector2, slot_name: String, hint: String = "") -> ItemSlotUI:
	var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
	add_child(slot_ui)
	slot_ui.position = (center - SLOT_SIZE / 2.0).round()
	slot_ui.set_meta("slot_name", slot_name)
	slot_ui.placeholder_tooltip = slot_name
	if not hint.is_empty() and ResourceLoader.exists(HINT_DIR % hint):
		slot_ui.placeholder = load(HINT_DIR % hint)
	return slot_ui


## Shows the stack in a slot; an empty slot shows its name as tooltip.
static func show_stack(slot_ui: ItemSlotUI, stack: InventorySlot) -> void:
	slot_ui.display(stack if stack else InventorySlot.new())
	if stack == null or stack.is_empty():
		slot_ui.tooltip_text = slot_ui.get_meta("slot_name", "")
