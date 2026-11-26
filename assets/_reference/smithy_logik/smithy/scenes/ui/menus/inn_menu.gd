class_name InnMenu
extends StationMenu
## The innkeeper of the inn in Leonheim: rent a room for the night (economy.json "inn.room_price")
## and sleep right away (GameState.sleep); the autosave of that night wakes up in the inn.

## Where the player wakes up after a night in the inn (spawn point in the inn scene).
@export_file("*.tscn") var inn_scene: String = "res://scenes/world/capital/capital_inn.tscn"
@export var room_spawn: StringName = &"FromRoom"

const TEXT: String = "Ein Zimmer für die Nacht? %d Gold, mit Frühstück. Es ist gerade %s."
const TEXT_NO_GOLD: String = "Ohne %d Gold gibt's kein Zimmer, mein Freund."

@onready var _text_label: Label = %TextLabel


func _ready() -> void:
	super()
	%RentButton.pressed.connect(_on_rent_pressed)
	%StayButton.pressed.connect(close)
	visibility_changed.connect(_update_text)


static func room_price() -> int:
	return int(ContentDB.economy("inn").get("room_price", 25))


func _update_text() -> void:
	%RentButton.text = Language.translate("Zimmer mieten (%d Gold)") % room_price()
	_text_label.text = Language.translate(TEXT) % [room_price(), GameState.day_cycle.get_phase_name()]


func _on_rent_pressed() -> void:
	if not GameState.spend_gold(room_price()):
		_text_label.text = Language.translate(TEXT_NO_GOLD) % room_price()
		return
	close()
	GameState.sleep(inn_scene, room_spawn)
