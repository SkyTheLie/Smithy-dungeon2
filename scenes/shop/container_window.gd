class_name ContainerWindow
extends PanelContainer
## An open container of the stash (data/containers.json, MetaState.container_*): its name, how
## full it is and one ShopSlot per place (four in a row). Drag a piece of the stash onto a place =
## put it in; drag a place into the stash = take one piece out (the stash calls
## MetaState.container_take). X closes it. Built in code, the shop places it and calls show_box /
## refresh after every change. Rules live in MetaState / ShopGoods; this only shows them.

## Something was put in or taken out (the shop shows everything new).
signal changed

const COLUMNS: int = 4

## The container shown (its uid in the stash), 0 = none.
var uid: int = 0

var _title: Label
var _grid: GridContainer
var _slots: Array[ShopSlot] = []


func _init() -> void:
	name = "ContainerWindow"
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", ShopSlot.box(Color(0.1, 0.08, 0.07, 0.96), Color(1.0, 0.78, 0.3), 2))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	_title = Label.new()
	_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title.add_theme_font_size_override("font_size", 10)
	_title.add_theme_color_override("font_color", Color(1, 0.86, 0.55))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	var close := Button.new()
	close.name = "Close"
	close.text = "X"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 9)
	close.pressed.connect(close_box)
	head.add_child(close)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	column.add_child(_grid)
	hide()


## Opens container `new_uid` (a uid of MetaState.stash).
func show_box(new_uid: int) -> void:
	uid = new_uid
	show()
	refresh()


func close_box() -> void:
	uid = 0
	hide()


func get_slots() -> Array[ShopSlot]:
	return _slots


## Builds the places new; closes when the container is gone (sold, …).
func refresh() -> void:
	var index: int = MetaState.container_index(uid)
	if uid <= 0 or index < 0:
		close_box()
		return
	var box: Dictionary = MetaState.stash()[index]
	var id: String = String(box.get("id", ""))
	var items: Array[Dictionary] = MetaState.container_items(uid)
	var places: int = ShopGoods.container_slots(id)
	_title.text = "%s  %d/%d" % [Language.translate(String(ShopGoods.container_data(id).get("name", id))), items.size(), places]
	for child: Node in _grid.get_children():
		child.queue_free()
	_slots.clear()
	for i in places:
		var place := ShopSlot.new()
		place.name = "Place%d" % i
		var piece: Dictionary = items[i] if i < items.size() else {}
		place.show_entry(piece)
		var slot_index: int = i
		place.set_drag_forwarding(_drag_out.bind(place, slot_index), _can_drop_in.bind(place), _drop_in)
		_grid.add_child(place)
		_slots.append(place)
	reset_size()


## Drag data of place `slot` ({from: "container", uid, slot, piece …}); null when empty.
func _drag_out(_at: Vector2, place: ShopSlot, slot: int) -> Variant:
	if place.is_empty():
		return null
	var piece: Dictionary = place.entry.duplicate()
	piece["count"] = 1
	var data: Dictionary = ItemBoard.make_drag(place, "container", slot, piece, false, Vector2i.ZERO, ShopSlot.SIZE.x)
	data["uid"] = uid
	return data


## A piece of the stash over a place: green if it goes in (MetaState.container_fits), else red.
func _can_drop_in(_at: Vector2, data: Variant, place: ShopSlot) -> bool:
	if not data is Dictionary or String((data as Dictionary).get("from", "")) != "stash":
		return false
	place.set_drop_hint(1 if MetaState.container_fits(uid, int((data as Dictionary).get("index", -1))) else 2)
	return true


func _drop_in(_at: Vector2, data: Variant) -> void:
	var done: bool = MetaState.container_put(uid, int((data as Dictionary).get("index", -1)))
	AudioManager.play_sound("pickup" if done else "denied", 1.2)
	changed.emit()
