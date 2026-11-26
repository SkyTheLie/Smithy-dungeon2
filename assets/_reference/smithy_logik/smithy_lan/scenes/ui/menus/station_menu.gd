class_name StationMenu
extends CanvasLayer
## Menu window of a station. Opened/closed via toggle(), closed with Escape, the interact key (E)
## or the X of its title bar (WindowTitleBar, also used to drag the window).
## While one with freezes_player is open the player stands still (Player, is_player_frozen).
## Every station menu is in QUICK_MOVE_GROUP: a right click on an inventory item asks the
## open menus (try_quick_move) to take it into a matching slot.

const QUICK_MOVE_GROUP: StringName = &"station_menus"

@export var title: String = "":
	get:
		return Language.translate(title)
## true = the player can't walk while this window is open.
@export var freezes_player: bool = true
## true = the interact key (E) closes the window (the dialogue box uses E for itself).
@export var closes_on_interact: bool = true
## true = opening this window opens the inventory too (shops); closing it closes the inventory
## again, unless the player had it open before or pinned it (HUD decides).
@export var opens_inventory: bool = false

@onready var _title_bar: WindowTitleBar = %TitleBar


func _ready() -> void:
	add_to_group(QUICK_MOVE_GROUP)
	_title_bar.title = title
	_title_bar.close_requested.connect(close)
	hide()
	# After hide(): the first hide must not ask the HUD to close the inventory.
	visibility_changed.connect(_on_station_visibility_changed)


func _on_station_visibility_changed() -> void:
	if not opens_inventory:
		return
	if visible:
		Events.inventory_open_requested.emit()
	else:
		Events.inventory_close_requested.emit()


func toggle() -> void:
	visible = not visible


func close() -> void:
	hide()


## Right click on an inventory item: put it into a matching slot of this menu.
## `amount`: at most this many pieces (Ctrl/Shift + right click), -1 = the whole stack.
## Returns true if something was moved. Menus without slots keep the default (false).
func try_quick_move(_inventory_index: int, _amount: int = -1) -> bool:
	return false


## How many pieces of `source` a drop/quick move moves: data["amount"] if set (Ctrl/Shift +
## right click), otherwise the whole stack.
static func get_move_amount(data: Dictionary, source: InventorySlot) -> int:
	var amount: int = int(data.get("amount", -1))
	return source.amount if amount < 0 else mini(amount, source.amount)


## true while a window that freezes the player is open, or while a text field has the focus
## (renaming a hero or a chest: WASD are letters then).
static func is_player_frozen(tree: SceneTree) -> bool:
	var focus: Control = tree.root.gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return true
	for node in tree.get_nodes_in_group(QUICK_MOVE_GROUP):
		var menu := node as StationMenu
		if menu and menu.visible and menu.freezes_player:
			return true
	return false


## true while any station window is open (they handle Escape/E themselves first).
static func is_any_open(tree: SceneTree) -> bool:
	for node in tree.get_nodes_in_group(QUICK_MOVE_GROUP):
		var menu := node as StationMenu
		if menu and menu.visible:
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (closes_on_interact and event.is_action_pressed("interact")):
		close()
		get_viewport().set_input_as_handled()
