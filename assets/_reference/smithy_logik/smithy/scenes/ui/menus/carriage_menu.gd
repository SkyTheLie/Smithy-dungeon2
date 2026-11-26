class_name CarriageMenu
extends StationMenu
## Window of a carriage (Door with `carriage_stop`): one button per stop the story has opened,
## with the days the ride takes (Carriage.days_between). A click rides there; the days pass.

const FONT_SIZE: int = 11

## The stop this carriage stands at (world_map.json "carriage.stops").
var stop_id: String = ""

@onready var _info: Label = %Info
@onready var _list: VBoxContainer = %StopList


func _ready() -> void:
	super()
	visibility_changed.connect(func() -> void:
		if visible:
			_build_list())


func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	var targets: Array[String] = Carriage.destinations_from(stop_id)
	_info.text = Language.translate("Wohin soll die Kutsche fahren?") if not targets.is_empty() \
			else Language.translate("Von hier fährt noch keine Kutsche woandershin.")
	for target in targets:
		var days: int = Carriage.days_between(stop_id, target)
		var button := Button.new()
		var stop_name: String = Language.translate(str(Carriage.get_stop(target).get("name", target)))
		button.text = (Language.translate("%s (%d Tage)") % [stop_name, days]) if days != 1 \
				else Language.translate("%s (1 Tag)") % stop_name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.pressed.connect(_ride.bind(target))
		_list.add_child(button)


func _ride(target: String) -> void:
	hide()
	Carriage.ride(stop_id, target)
