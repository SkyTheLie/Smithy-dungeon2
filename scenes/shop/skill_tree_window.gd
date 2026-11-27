class_name SkillTreeWindow
extends PanelContainer
## The skill tree window in Egon's shop (button "Skills"): at the top the player level, the EXP to
## the next level, the skill points and the gold; below the tree (SkillTree in a PanZoomView: pull
## in every direction with the mouse, wheel zooms). A click on a gold frame learns the next level
## (MetaState.buy_skill); `learned` lets the shop update gold and the hero. Esc / "Schließen".

signal learned(id: String)

const VIEW_SIZE := Vector2(560, 250)
const COLOR_TITLE := Color(1, 0.86, 0.55)

var _header: Label
var _view: PanZoomView
var _tree: SkillTree


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	var title := Label.new()
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.text = Language.translate("Skillbaum")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	top.add_child(title)
	_header = Label.new()
	_header.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_header.add_theme_font_size_override("font_size", 11)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_header)
	_view = PanZoomView.new()
	_view.custom_minimum_size = VIEW_SIZE
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.07, 0.05, 0.06, 0.9)
	_view.backdrop = back
	column.add_child(_view)
	_tree = SkillTree.new()
	_tree.learn_requested.connect(_on_learn)
	_view.add_child(_tree)
	var hint := Label.new()
	hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hint.text = Language.translate("Ziehen: verschieben · Mausrad: zoomen · Goldener Rahmen: lernen")
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(0.7, 0.65, 0.6)
	column.add_child(hint)
	var close_button := Button.new()
	close_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	close_button.text = Language.translate("Schließen")
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(hide)
	column.add_child(close_button)


func open() -> void:
	_refresh()
	show()
	# The whole tree in view once it has its size (after this frame).
	_view.fit_view.call_deferred()


func get_tree_view() -> SkillTree:
	return _tree


func _refresh() -> void:
	_tree.build()
	var to_next: int = Skills.exp_to_next(MetaState.level())
	var exp_text: String = Language.translate("max.") if to_next == 0 else "%d/%d" % [MetaState.exp_points(), to_next]
	_header.text = Language.translate("Stufe %d · EXP %s · Skillpunkte: %d · Gold: %d") % [MetaState.level(), exp_text, MetaState.skill_points(), MetaState.box()]


func _on_learn(id: String) -> void:
	if not MetaState.buy_skill(id):
		AudioManager.play_sound("denied")
		return
	AudioManager.play_sound("unlock")
	_refresh()
	learned.emit(id)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide()
