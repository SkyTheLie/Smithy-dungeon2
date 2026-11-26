class_name SkillCommandWindow
extends PanelContainer
## Command of one learned skill of a hero (right click on the skill in the hero window):
##   [x] Im Dungeon benutzen   (on/off, needs no IQ)
##   Ziel: [target]   Nur wenn: [stat] [operator] [value]
## Options the hero's IQ is too low for are shown greyed out with the IQ they need
## (SkillCommand, tiers in combat.json). Below the first tier nothing can be set.

const FONT_SIZE: int = 11
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)

var _hero: Hero
var _skill: SkillData
## Option ids in the order of the OptionButtons.
var _target_ids: Array[String] = []
var _stat_ids: Array[String] = []
var _op_ids: Array[String] = []

@onready var _title_bar: WindowTitleBar = $VBox/TitleBar
@onready var _info_label: Label = %InfoLabel
@onready var _target_option: OptionButton = %TargetOption
@onready var _stat_option: OptionButton = %StatOption
@onready var _op_option: OptionButton = %OpOption
@onready var _value_box: SpinBox = %ValueBox
@onready var _apply_button: Button = %ApplyButton
@onready var _reset_button: Button = %ResetButton
@onready var _message_label: Label = %MessageLabel
@onready var _tiers_label: Label = %TiersLabel
## On/off switch of the skill (always usable, also without IQ).
var _enabled_toggle := CheckButton.new()


func _ready() -> void:
	_enabled_toggle.text = Language.translate("Im Dungeon benutzen")
	_enabled_toggle.focus_mode = Control.FOCUS_NONE
	_enabled_toggle.add_theme_font_size_override("font_size", FONT_SIZE)
	_info_label.add_sibling(_enabled_toggle)
	_enabled_toggle.toggled.connect(_on_enabled_toggled)
	_apply_button.pressed.connect(_on_apply_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_stat_option.item_selected.connect(func(_index: int) -> void: _update_condition_controls())
	for option: OptionButton in [_target_option, _stat_option, _op_option]:
		option.get_popup().add_theme_font_size_override("font_size", FONT_SIZE)
	_tiers_label.text = Language.translate("IQ %d: einfache Ziele · IQ %d: Bosse, Bedingungen mit < und > · IQ %d: alles") % [
			SkillCommand.iq_for(SkillCommand.TARGETS, "self"), SkillCommand.iq_for(SkillCommand.TARGETS, "boss"),
			SkillCommand.iq_for(SkillCommand.STATS, "own_mana")]


func show_command(hero: Hero, skill: SkillData) -> void:
	_hero = hero
	_skill = skill
	_title_bar.title = Language.translate("Befehl: %s") % skill.display_name
	_message_label.text = ""
	_enabled_toggle.set_pressed_no_signal(hero.is_skill_enabled(skill))
	var iq: int = hero.get_iq()
	var can_command: bool = iq >= SkillCommand.min_iq()
	_info_label.text = "%s · IQ %d" % [hero.display_name, iq]
	if not can_command:
		_info_label.text += Language.translate(" – zu wenig für Befehle (ab IQ %d)") % SkillCommand.min_iq()
	var command: Dictionary = hero.get_skill_command(skill)
	if command.is_empty():
		command = SkillCommand.create()
	_target_ids = SkillCommand.targets_for(skill)
	_fill(_target_option, _target_ids, SkillCommand.TARGETS, command.get("target", "default"), iq)
	_stat_ids.assign(SkillCommand.STATS.keys())
	_fill(_stat_option, _stat_ids, SkillCommand.STATS, command.get("stat", "none"), iq)
	_op_ids.assign(SkillCommand.OPS.keys())
	_fill(_op_option, _op_ids, SkillCommand.OPS, command.get("op", "<"), iq)
	_value_box.value = float(command.get("value", 50.0))
	for control: Control in [_target_option, _stat_option, _op_option, _value_box, _apply_button, _reset_button]:
		control.set("disabled", not can_command)
	_value_box.editable = can_command
	_update_condition_controls()
	show()


## Fills an OptionButton; options above the hero's IQ are disabled and show the IQ they need.
func _fill(option: OptionButton, ids: Array[String], table: Dictionary, selected: String, iq: int) -> void:
	option.clear()
	option.add_theme_font_size_override("font_size", FONT_SIZE)
	for i in ids.size():
		var needed: int = SkillCommand.iq_for(table, ids[i])
		var text: String = Language.translate(table[ids[i]]["name"])
		if needed > iq:
			text += " (IQ %d)" % needed
		option.add_item(text, i)
		option.set_item_disabled(i, needed > iq)
	option.select(maxi(0, ids.find(selected)))


func _update_condition_controls() -> void:
	var has_condition: bool = _stat_ids[_stat_option.selected] != "none"
	_op_option.visible = has_condition
	_value_box.visible = has_condition


func _get_command() -> Dictionary:
	return SkillCommand.create(_target_ids[_target_option.selected], _stat_ids[_stat_option.selected],
			_op_ids[_op_option.selected], _value_box.value)


func _on_apply_pressed() -> void:
	var command: Dictionary = _get_command()
	if _hero.set_skill_command(_skill, command):
		_message_label.text = Language.translate("Gespeichert: %s") % SkillCommand.describe(command)
		_message_label.remove_theme_color_override("font_color")
	else:
		_message_label.text = Language.translate("Dafür braucht %s IQ %d.") % [_hero.display_name, SkillCommand.required_iq(command)]
		_message_label.add_theme_color_override("font_color", COLOR_ERROR)


func _on_enabled_toggled(enabled: bool) -> void:
	_hero.set_skill_enabled(_skill, enabled)
	_message_label.text = Language.translate("%s ist %s.") % [_skill.display_name, "an" if enabled else Language.translate("aus: wird im Dungeon nicht benutzt")]
	_message_label.remove_theme_color_override("font_color")


func _on_reset_pressed() -> void:
	_hero.set_skill_command(_skill, {})
	show_command(_hero, _skill)
	_message_label.text = Language.translate("Zurückgesetzt: Standard")
