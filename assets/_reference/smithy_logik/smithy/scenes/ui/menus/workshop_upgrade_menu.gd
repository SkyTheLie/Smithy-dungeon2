class_name WorkshopUpgradeMenu
extends StationMenu
## The master builder's workshop upgrades (House, house.json "workshop_upgrades"): one block per
## station (anvil, smelter, forge) with its level, the next level's name, effect, gold and
## material, and "Ausbauen". Levels are bought one after the other; a level with "unlock_flag"
## needs that story flag. Opened by the story action "open_menu:workshop" (BuilderNpc).

const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)
const COLOR_OK: Color = Color(0.6, 0.9, 0.6)
const COLOR_DONE: Color = Color(0.6, 0.58, 0.55)
const EFFECT_TEXTS: Dictionary = {
	"forge_quality": "Qualität beim Schmieden +%s %%",
	"smelt_speed": "Schmelzen %s %% schneller",
	"smelt_slots": "+%s Schmelzplatz",
	"heat_bonus": "%s %% mehr Güsse pro Brennstoff",
}

@onready var _content: VBoxContainer = %Content
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	super()
	remove_from_group(QUICK_MOVE_GROUP)
	# Buying fires both: one redraw at the end of the frame.
	GameState.house.changed.connect(_queue_refresh)
	GameState.gold_changed.connect(_queue_refresh)
	visibility_changed.connect(_refresh)


## Effect lines of a level ("Qualität beim Schmieden +2 %").
static func describe_effects(level: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in EFFECT_TEXTS:
		if level.has(key):
			parts.append(Language.translate(EFFECT_TEXTS[key]) % str(level[key]))
	return ", ".join(parts)


## Material of a level as names ("10 Eisenbarren, 20 Kohle").
static func describe_items(specs: String) -> String:
	var names: Array[String] = []
	for spec in specs.split(",", false):
		var stack: InventorySlot = ContentDB.make_stack(spec)
		if stack:
			names.append("%d %s" % [stack.amount, stack.get_display_name()])
	return ", ".join(names)


func _refresh() -> void:
	if not visible:
		return
	_refresh_done()
	for child in _content.get_children():
		child.queue_free()
	var house: House = GameState.house
	for station: String in House.get_upgrade_stations():
		var data: Dictionary = House.get_upgrade_data(station)
		var levels: Array = data.get("levels", [])
		var bought: int = house.get_workshop_level(station)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		var header := Label.new()
		header.text = Language.translate("%s: Stufe %d von %d") % [Language.translate(str(data.get("name", station))), bought, levels.size()]
		box.add_child(header)
		var next: Dictionary = house.get_next_upgrade(station)
		var info := Label.new()
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size = Vector2(320, 0)
		if next.is_empty():
			info.text = Language.translate("Ganz ausgebaut.")
			info.add_theme_color_override("font_color", COLOR_DONE)
			box.add_child(info)
			_content.add_child(box)
			continue
		info.text = "%s: %s\n%s\n%s" % [Language.translate(str(next.get("name", ""))), describe_effects(next),
				Language.translate(str(next.get("description", ""))),
				Language.translate("Kosten: %d Gold, %s") % [int(next.get("price", 0)), describe_items(str(next.get("items", "")))]]
		box.add_child(info)
		var button := Button.new()
		button.text = Language.translate("Ausbauen")
		button.focus_mode = Control.FOCUS_NONE
		var blocker: String = house.get_upgrade_blocker(station)
		button.disabled = not blocker.is_empty()
		button.tooltip_text = blocker
		button.pressed.connect(_on_buy.bind(station))
		box.add_child(button)
		_content.add_child(box)
	var total: Array[String] = []
	for key: String in EFFECT_TEXTS:
		var value: float = house.get_upgrade_value(key)
		if value > 0.0:
			total.append(Language.translate(EFFECT_TEXTS[key]) % str(int(value)))
	_status_label.text = Language.translate("Deine Werkstatt jetzt: %s") % (", ".join(total) if not total.is_empty() else Language.translate("wie gekauft"))
	_status_label.remove_theme_color_override("font_color")


func _on_buy(station: String) -> void:
	var name: String = str(GameState.house.get_next_upgrade(station).get("name", ""))
	if GameState.house.buy_upgrade(station):
		AudioManager.play_sound("coins")
		GameState.show_message(Language.translate("%s eingebaut.") % Language.translate(name))
	else:
		GameState.show_message(GameState.house.get_upgrade_blocker(station))
