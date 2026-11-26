class_name AudioSettings
extends VBoxContainer
## Volume settings for the settings windows (HUD and main menu use the same block): per kind
## (all, music, effects, surroundings, interface) a row "Musik 80 %" with an on/off switch and a
## slider below. Changes apply at once and are saved by AudioManager (user://settings.cfg). Builds its own children, so it can
## simply be added with AudioSettings.new().

const FONT_SIZE: int = 11
## Kinds = bus names in AudioManager; "test" = sound played when the slider is let go.
const KINDS: Array[Dictionary] = [
	{"kind": "Master", "name": "Gesamt", "test": "anvil_good"},
	{"kind": "Music", "name": "Musik", "test": ""},
	{"kind": "Sounds", "name": "Effekte", "test": "anvil_good"},
	{"kind": "Ambience", "name": "Umgebung", "test": "door"},
	{"kind": "Interface", "name": "Oberfläche", "test": "ui_click"},
]

## kind -> Label showing "Musik 80 %".
var _labels: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	for entry in KINDS:
		_add_row(entry["kind"], Language.translate(entry["name"]), entry["test"])


func _add_row(kind: String, display_name: String, test_sound: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var toggle := CheckButton.new()
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.add_theme_font_size_override("font_size", FONT_SIZE)
	toggle.tooltip_text = Language.translate("%s an / aus") % display_name
	toggle.button_pressed = not AudioManager.is_muted(kind)
	row.add_child(toggle)
	add_child(row)
	var slider := HSlider.new()
	slider.focus_mode = Control.FOCUS_NONE
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = roundi(AudioManager.get_volume(kind) * 100.0)
	slider.custom_minimum_size = Vector2(130, 0)
	add_child(slider)
	_labels[kind] = {"label": label, "name": display_name}
	_update_label(kind, slider.value, toggle.button_pressed)
	toggle.toggled.connect(func(on: bool) -> void:
		AudioManager.set_muted(kind, not on)
		_update_label(kind, slider.value, on))
	slider.value_changed.connect(func(value: float) -> void:
		AudioManager.set_volume(kind, value / 100.0)
		_update_label(kind, value, toggle.button_pressed))
	# A short test sound when the slider is let go, so the volume can be heard.
	if not test_sound.is_empty():
		slider.drag_ended.connect(func(_changed: bool) -> void: AudioManager.play_sound(test_sound))


func _update_label(kind: String, value: float, on: bool) -> void:
	var entry: Dictionary = _labels[kind]
	(entry["label"] as Label).text = "%s %s" % [entry["name"], "%d %%" % roundi(value) if on else Language.translate("aus")]
