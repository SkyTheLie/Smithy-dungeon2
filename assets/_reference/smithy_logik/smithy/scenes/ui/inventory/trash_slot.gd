class_name TrashSlot
extends ItemSlotUI
## "Wegschmeißen" under the bag: an inventory item dragged here is thrown away. The last thrown
## stack stays in the trash (GameState.trash, not saved) and a click takes it back, until the next
## one is thrown away (then the old one is gone for good).

const TRASH_ICON: Texture2D = preload("res://assets/sprites/ui/slot_hints/trash.png")
## The trash can is easier to see than the faint hints of other empty slots.
const COLOR_TRASH_ICON: Color = Color(1.0, 1.0, 1.0, 0.75)


func _ready() -> void:
	placeholder = TRASH_ICON
	placeholder_tooltip = Language.translate("Wegschmeißen: Gegenstand aus dem Inventar hierher ziehen.")
	extra_tooltip = Language.translate("[color=#9e9a8f]Weggeworfen. Klick: zurück ins Inventar.\nWirfst du etwas Neues weg, ist das hier für immer weg.[/color]")
	GameState.trash_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	display(GameState.trash)
	if GameState.trash.is_empty():
		_icon.modulate = COLOR_TRASH_ICON


func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		GameState.take_back_trash()
		accept_event()


func _get_drag_data(_at_position: Vector2) -> Variant:
	return null


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("inventory_index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	GameState.throw_away(data["inventory_index"])
