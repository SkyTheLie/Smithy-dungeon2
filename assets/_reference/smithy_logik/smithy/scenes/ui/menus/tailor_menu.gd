class_name TailorMenu
extends StationMenu
## Window of the tailor on the market (TailorStall): on the left the player as he looks now, on the
## right the clothes for his figure (owned: "Anziehen", sold: "Kaufen" with the price, not sold yet:
## greyed out) and the colours of the worn clothes (a click dyes them for Tailor.get_color_price).
## The rules are in Tailor; this window only shows them and calls them. Built when it opens and after
## each change (Events.player_look_changed, gold), not while closed.

const PREVIEW_ZOOM: float = 3.0
const ICON_SIZE: Vector2 = Vector2(24, 24)
const SWATCH_SIZE: Vector2 = Vector2(14, 14)
const COLOR_HINT: Color = Color(0.75, 0.7, 0.62)
const COLOR_WORN: Color = Color(0.55, 0.85, 0.45)

@onready var _preview: TextureRect = %Preview
@onready var _outfit_list: VBoxContainer = %OutfitList
@onready var _color_title: Label = %ColorTitle
@onready var _colors: HFlowContainer = %Colors
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	super()
	visibility_changed.connect(func() -> void:
		if visible:
			_status_label.text = ""
			_refresh())
	Events.player_look_changed.connect(_queue_refresh)
	GameState.gold_changed.connect(_queue_refresh)


func _refresh() -> void:
	_refresh_done()
	var look: Appearance = GameState.player_appearance
	var frame := AtlasTexture.new()
	frame.atlas = CharacterBaker.get_sheet(look)
	frame.region = CharacterBaker.get_frame_rect("down", 0)
	_preview.texture = frame
	_preview.custom_minimum_size = Vector2(CharacterBaker.FRAME, CharacterBaker.FRAME) * PREVIEW_ZOOM
	_clear(_outfit_list)
	for offer: Dictionary in Tailor.get_offers(GameState):
		_outfit_list.add_child(_make_outfit_row(offer))
	_clear(_colors)
	var colorable: bool = look.get_outfit_data().get("colorable", false)
	_color_title.text = Language.translate("Farbe (%d Gold)") % Tailor.get_color_price() if colorable \
			else Language.translate("Diese Kleidung behält ihre Farbe.")
	if colorable:
		for color_id: String in Appearance.get_options("clothes_color"):
			_colors.add_child(_make_swatch(color_id, look.clothes_color == color_id))


func _make_outfit_row(offer: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var look: Appearance = GameState.player_appearance.duplicate() as Appearance
	look.outfit = offer["id"]
	look.normalize()
	var icon := TextureRect.new()
	icon.texture = CharacterBaker.get_portrait(look)
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	var name_label := Label.new()
	name_label.text = look.get_option_name("outfit")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if offer["worn"]:
		name_label.add_theme_color_override("font_color", COLOR_WORN)
	row.add_child(name_label)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	if offer["worn"]:
		button.text = Language.translate("Angezogen")
		button.disabled = true
	elif offer["owned"]:
		button.text = Language.translate("Anziehen")
		button.pressed.connect(_on_wear_pressed.bind(offer["id"]))
	elif offer["unlocked"]:
		button.text = Language.translate("Kaufen (%d Gold)") % offer["price"]
		button.disabled = GameState.gold < int(offer["price"])
		button.pressed.connect(_on_buy_pressed.bind(offer["id"]))
	else:
		button.text = Language.translate("Noch nicht da")
		button.disabled = true
	row.add_child(button)
	return row


func _make_swatch(color_id: String, worn: bool) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = SWATCH_SIZE
	button.tooltip_text = ContentDB.appearance_section("clothes_colors").get(color_id, {}).get("name", color_id)
	button.disabled = worn or GameState.gold < Tailor.get_color_price()
	var swatch := ColorRect.new()
	var shades: Array[Color] = Appearance.get_colors("clothes_color", color_id)
	swatch.color = shades[1] if shades.size() > 1 else Color.MAGENTA
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
	swatch.offset_left = 2.0
	swatch.offset_top = 2.0
	swatch.offset_right = -2.0
	swatch.offset_bottom = -2.0
	button.add_child(swatch)
	if worn:
		button.tooltip_text += " " + Language.translate("(getragen)")
	button.pressed.connect(_on_color_pressed.bind(color_id))
	return button


func _on_wear_pressed(outfit: String) -> void:
	Tailor.wear(GameState, outfit)


func _on_buy_pressed(outfit: String) -> void:
	if not Tailor.buy(GameState, outfit):
		_status_label.text = Language.translate("Dafür reicht dein Gold nicht.")


func _on_color_pressed(color_id: String) -> void:
	if not Tailor.dye(GameState, color_id):
		_status_label.text = Language.translate("Dafür reicht dein Gold nicht.")


static func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
