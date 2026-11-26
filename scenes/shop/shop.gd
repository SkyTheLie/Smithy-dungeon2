class_name MerchantShop
extends Control
## Egon's shop between the days (after the intro, "Weiter", and after every run). For now: Egon
## behind his table in the mine, the day, "Hauptmenü" at the bottom left and "Dungeons" at the
## bottom right. "Dungeons" opens the dungeon board (DungeonBoard); "Betreten" there asks for the
## character (CharacterSelect, locked ones from Progress) and starts the run.
## The shop itself (table with goods, lever, selling, money box) comes next (docs/ROADMAP.md).
## Built in code, except the character window (its own scene).

const CAVE: Texture2D = preload("res://assets/sprites/battle/mine_rats.png")
const MERCHANT: Texture2D = preload("res://assets/sprites/npcs/black_market_dealer.png")
const TABLE: Texture2D = preload("res://assets/sprites/finster/hideout_table.png")
const CHARACTER_SELECT: PackedScene = preload("res://scenes/ui/menus/character_select.tscn")
const CAVE_SHADE := Color(0.55, 0.5, 0.5)
const MERCHANT_SCALE: float = 4.0
const TABLE_SCALE: float = 2.0
const FADE_TIME: float = 0.5

var _board: DungeonBoard
var _characters: CharacterSelect
var _black: ColorRect


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	AudioManager.play_music("title")
	create_tween().tween_property(_black, "modulate:a", 0.0, FADE_TIME)


func _build() -> void:
	var cave := TextureRect.new()
	cave.texture = CAVE
	cave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cave.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cave.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cave.modulate = CAVE_SHADE
	cave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cave)
	# Egon stands behind the middle of his table (both anchored to the bottom centre).
	var merchant := _picture(MERCHANT, MERCHANT_SCALE, Vector2(0, -120))
	add_child(merchant)
	add_child(_picture(TABLE, TABLE_SCALE, Vector2(0, 0)))
	var title := _label(Language.translate("Egons Laden"), 22, Color(1, 0.86, 0.55))
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_top = 8
	add_child(title)
	var day := _label(Language.translate("Tag %d") % MetaState.day(), 16, Color.WHITE)
	day.position = Vector2(10, 10)
	add_child(day)
	var menu_button := _button(Language.translate("Hauptmenü"), Control.PRESET_BOTTOM_LEFT)
	menu_button.pressed.connect(Game.to_main_menu)
	var dungeons_button := _button(Language.translate("Dungeons"), Control.PRESET_BOTTOM_RIGHT)
	dungeons_button.name = "DungeonsButton"
	dungeons_button.pressed.connect(_open_board)
	var windows := CanvasLayer.new()
	add_child(windows)
	_board = DungeonBoard.new()
	_board.hide()
	_board.entered.connect(_on_dungeon_entered)
	windows.add_child(_board)
	_characters = CHARACTER_SELECT.instantiate()
	_characters.hide()
	windows.add_child(_characters)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_black)


func get_board() -> DungeonBoard:
	return _board


func get_character_select() -> CharacterSelect:
	return _characters


func _open_board() -> void:
	_characters.hide()
	_board.open()


## "Betreten": now the character (only one dungeon so far: every dungeon plays floors.json).
func _on_dungeon_entered(_id: String) -> void:
	_board.hide()
	_characters.open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _characters.visible:
		get_viewport().set_input_as_handled()
		_characters.close()


## A picture standing on the bottom centre of the screen, `offset` from there (its feet).
func _picture(texture: Texture2D, scale_by: float, offset: Vector2) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	picture.scale = Vector2.ONE * scale_by
	var top_left := Vector2(-texture.get_width() * scale_by / 2.0, -texture.get_height() * scale_by) + offset
	picture.offset_left = top_left.x
	picture.offset_top = top_left.y
	picture.offset_right = top_left.x + texture.get_width()
	picture.offset_bottom = top_left.y + texture.get_height()
	return picture


## A button in a bottom corner (added first, so it knows its size).
func _button(text: String, corner: Control.LayoutPreset) -> Button:
	var button := Button.new()
	button.text = text
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	add_child(button)
	button.set_anchors_and_offsets_preset(corner, Control.PRESET_MODE_MINSIZE, 10)
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN if corner == Control.PRESET_BOTTOM_RIGHT else Control.GROW_DIRECTION_END
	button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	return label
