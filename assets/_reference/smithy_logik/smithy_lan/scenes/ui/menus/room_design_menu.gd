class_name RoomDesignMenu
extends StationMenu
## Room designer (B » "Wände & Böden" in the storage window): one row per kind (floor, wall,
## door) with "Standard" (the room's own picture) and every style of house.json "room_styles".
## A bought style is set at once; one not bought yet is bought with gold first (House.buy_style),
## then set. Styles whose "unlock_flag" is missing show a lock. RoomStyleLayer draws the result.

const SWATCH: Vector2 = Vector2(28, 28)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)
const COLOR_OK: Color = Color(0.6, 0.9, 0.6)
const HINT: String = "Klick auf einen Stil: kaufen (einmal) und hier anbringen. Gekaufte Stile gibt es für jeden Raum."

## Room key of the RoomStyleLayer of this room (e.g. "smithy_big", "shop").
var room: String = ""
## Kinds this room has (a room without doors in its wall has no door row).
var kinds: Array[String] = ["floor", "wall", "door"]

@onready var _content: VBoxContainer = %Content
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	super()
	remove_from_group(QUICK_MOVE_GROUP)
	GameState.house.changed.connect(_refresh)
	GameState.gold_changed.connect(func(_gold: int) -> void: _refresh())
	visibility_changed.connect(_refresh)


func open_for(room_key: String, room_kinds: Array[String]) -> void:
	room = room_key
	kinds = room_kinds
	show()
	_status_label.text = Language.translate(HINT)
	_status_label.remove_theme_color_override("font_color")


func _refresh() -> void:
	if not visible:
		return
	for child in _content.get_children():
		child.queue_free()
	var house: House = GameState.house
	for kind: String in kinds:
		var header := Label.new()
		header.text = Language.translate(House.STYLE_KIND_NAMES.get(kind, kind))
		_content.add_child(header)
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 2)
		row.add_theme_constant_override("v_separation", 2)
		_content.add_child(row)
		var current: String = house.get_room_style(room, kind)
		row.add_child(_swatch(kind, "", null, Language.translate("Standard\nWie der Raum gebaut wurde."), current.is_empty()))
		for id: String in House.get_styles(kind):
			var style: Dictionary = House.get_style(id)
			var path: String = str(style.get("texture", ""))
			var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
			var state: String
			if house.owns_style(id):
				state = Language.translate("gekauft")
			elif not House.is_style_unlocked(id):
				state = Language.translate("noch verschlossen")
			else:
				state = Language.translate("%d Gold") % int(style.get("price", 0))
			var bonus: float = float(style.get("bonus", 0.0))
			var text: String = "%s (%s)\n%s" % [style.get("name", id), state, style.get("description", "")]
			if bonus > 0.0:
				text += "\n" + Language.translate("Im eigenen Laden: Preise +%s %%") % str(snappedf(bonus * 100.0, 0.1)).replace(".", ",")
			var swatch: Button = _swatch(kind, id, texture, text, current == id)
			swatch.modulate = Color.WHITE if house.owns_style(id) or House.is_style_unlocked(id) else Color(0.45, 0.45, 0.45)
			row.add_child(swatch)


func _swatch(kind: String, id: String, texture: Texture2D, tooltip: String, selected: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = SWATCH
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.button_pressed = selected
	button.icon = texture
	button.expand_icon = true
	button.text = "" if texture else Language.translate("Std.")
	button.tooltip_text = tooltip
	button.pressed.connect(_on_chosen.bind(kind, id))
	return button


func _on_chosen(kind: String, id: String) -> void:
	var house: House = GameState.house
	if not id.is_empty() and not house.owns_style(id):
		var blocker: String = house.get_style_blocker(id)
		if not blocker.is_empty() or not house.buy_style(id):
			_show(blocker if not blocker.is_empty() else Language.translate("Das ging nicht."), COLOR_ERROR)
			_refresh()
			return
		AudioManager.play_sound("coins")
		_show(Language.translate("%s gekauft.") % House.get_style(id).get("name", id), COLOR_OK)
	house.set_room_style(room, kind, id)


func _show(text: String, color: Color) -> void:
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)
