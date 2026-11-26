class_name HouseExteriorMenu
extends StationMenu
## The storage of the outside of the house while furnishing it (ForgeSignPlacer, key B in front of
## the smithy), like HouseStorageMenu inside: everything for the outside that is bought and not
## put up: the forge sign (ForgeSign) and the wanted poster from the dark city (WantedPoster),
## each while owned and not hanging. A click emits piece_chosen (the placer then lets the player hang it). Closing the
## window ends the mode.
## A right click in the inventory does nothing here (try_quick_move is the default false).

signal piece_chosen(id: String)

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const COLUMNS: int = 5
const MIN_SLOTS: int = 5
const COLOR_HINT: String = "#9e9a8f"
## Id of the forge sign in `_ids`.
const SIGN_ID: String = "forge_sign"
## Id of the wanted poster in `_ids`.
const POSTER_ID: String = "wanted_poster"
const POSTER_ICON: Texture2D = preload("res://assets/sprites/finster/poster_smith_small.png")
const HINT: String = "Klick: aufhängen. Anheben: Klick auf das Schild am Haus.\nRechtsklick auf das Schild: abnehmen.\n{key_build} oder Fenster schließen: fertig."
const HINT_PHONE: String = "Antippen: aufhängen oder anheben. Mit dem Finger verschieben, grüner Haken: aufhängen.\nKisten-Knopf: abnehmen.\nB oder Fenster schließen: fertig."

var _ids: Array[String] = []
var _slot_uis: Array[ItemSlotUI] = []

@onready var _grid: GridContainer = %Grid
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	# Stays in QUICK_MOVE_GROUP: then the HUD leaves Escape to this window (it closes, the mode
	# ends); right clicks in the inventory find nothing here (try_quick_move stays false).
	super()
	_grid.columns = COLUMNS
	GameState.house.forge_sign.changed.connect(_queue_refresh)
	GameState.house.wanted_poster.changed.connect(_queue_refresh)
	visibility_changed.connect(_queue_refresh)


func _refresh() -> void:
	_refresh_done()
	var forge_sign: ForgeSign = GameState.house.forge_sign
	_ids.clear()
	if forge_sign.is_owned() and not forge_sign.attached:
		_ids.append(SIGN_ID)
	var poster: WantedPoster = GameState.house.wanted_poster
	if poster.is_owned() and not poster.attached:
		_ids.append(POSTER_ID)
	while _slot_uis.size() < maxi(_ids.size(), MIN_SLOTS):
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(_slot_uis.size()))
		_grid.add_child(slot_ui)
		_slot_uis.append(slot_ui)
	for i in _slot_uis.size():
		if i >= _ids.size():
			_slot_uis[i].display(InventorySlot.new())
			continue
		var icon: Texture2D = POSTER_ICON
		var title: String = Language.translate("Dein Steckbrief")
		if _ids[i] == SIGN_ID:
			var item: ItemData = ContentDB.item(ForgeSign.item_id())
			icon = item.icon
			title = item.display_name
		_slot_uis[i].display_custom(icon, "[b]%s[/b] (%s)\n[color=%s]%s[/color]" % [title,
				Language.translate("im Lager"), COLOR_HINT, Language.translate("Klick: an die Hauswand hängen.")])
	var empty: String = Language.translate("Lager leer: Schmuck für das Haus gibt es bei der Möbelhändlerin.\n") if _ids.is_empty() else ""
	_status_label.text = empty + KeyBindings.fill(Language.translate(HINT_PHONE if MobileUi.active() else HINT))


## What the window offers now (ids, e.g. "forge_sign").
func get_ids() -> Array[String]:
	return _ids.duplicate()


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and index < _ids.size():
		piece_chosen.emit(_ids[index])
