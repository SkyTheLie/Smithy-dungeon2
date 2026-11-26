class_name TailorMenu
extends StationMenu
## Window of the tailor in her house on the market (TailorStall), built like the character creator:
## on the left the player walking in place ("<" / ">" turn him), on the right two buttons:
##   - "Neue Kleidung kaufen": the clothes not owned yet (not sold yet: greyed out), a colour and
##     "Kaufen" with the price (the colour is included).
##   - "Umziehen": the clothes the player owns, a colour and "Anziehen" (free; a new colour costs
##     Tailor.get_color_price).
## A click on clothes or a colour only tries them on (the preview); nothing changes before the
## button. Colours: the swatches of appearance.json, "+" = an own colour from the colour wheel.
## The rules are in Tailor; this window only shows them and calls them. Built when it opens and
## after each change (Events.player_look_changed, gold), not while closed.

const MODE_SHOP: String = "shop"
const MODE_WARDROBE: String = "wardrobe"
const PREVIEW_ZOOM: float = 3.0
const WALK_FPS: float = 8.0
## Directions in turning order for the arrows under the preview (as in the character creator).
const TURN_ORDER: Array[String] = ["down", "left", "up", "right"]
const SLOT_SIZE: float = 26.0
const COLOR_SLOT_SIZE: float = 16.0
const SWATCH_INSET: float = 3.0
const FONT_SIZE: int = 11
## Slot value of the "own colour" slot behind the swatches.
const CUSTOM_SLOT: String = "#"
const COLOR_SELECTED: Color = Color(1.0, 0.82, 0.3)
const COLOR_HOVER: Color = Color(1.25, 1.2, 1.1)
const COLOR_LOCKED: Color = Color(0.45, 0.45, 0.45)
const COLOR_DONE: Color = Color(0.55, 0.85, 0.45)
const COLOR_PROBLEM: Color = Color(0.9, 0.55, 0.45)

var _mode: String = MODE_SHOP
## The look being tried on: the player's look with the chosen clothes and colour.
var _trial: Appearance
var _direction: int = 0
var _time: float = 0.0
var _preview_texture := AtlasTexture.new()
## Slots of the page: {"kind": "outfit"/"color", "value", "button", "frame", "icon"}.
var _slots: Array[Dictionary] = []
## Last own colour "#rrggbb" (the "+" slot keeps it after choosing a swatch).
var _custom_color: String = ""
var _wheel: ColorWheel
var _slot_style: StyleBox
var _frame_style := StyleBoxFlat.new()

@onready var _preview: TextureRect = %Preview
@onready var _shop_button: Button = %ShopButton
@onready var _wardrobe_button: Button = %WardrobeButton
@onready var _outfit_title: Label = %OutfitTitle
@onready var _outfits: HFlowContainer = %Outfits
@onready var _empty_label: Label = %EmptyLabel
@onready var _color_title: Label = %ColorTitle
@onready var _colors: HFlowContainer = %Colors
@onready var _wheel_holder: HBoxContainer = %WheelHolder
@onready var _price_label: Label = %PriceLabel
@onready var _action_button: Button = %ActionButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	super()
	_slot_style = _preview.get_theme_stylebox("panel", "ItemSlot")
	_frame_style.draw_center = false
	_frame_style.border_color = COLOR_SELECTED
	_frame_style.set_border_width_all(1)
	_preview.texture = _preview_texture
	_shop_button.pressed.connect(_set_mode.bind(MODE_SHOP))
	_wardrobe_button.pressed.connect(_set_mode.bind(MODE_WARDROBE))
	%TurnLeftButton.pressed.connect(_turn.bind(1))
	%TurnRightButton.pressed.connect(_turn.bind(-1))
	_action_button.pressed.connect(_on_action_pressed)
	_wheel = ColorWheel.new()
	_wheel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_wheel.color_changed.connect(_on_wheel_changed)
	_wheel_holder.add_child(_wheel)
	visibility_changed.connect(_on_visibility_changed)
	Events.player_look_changed.connect(_queue_refresh)
	GameState.gold_changed.connect(_queue_refresh)
	set_process(false)


func _process(delta: float) -> void:
	_time += delta
	_update_preview_frame()


func _on_visibility_changed() -> void:
	set_process(visible)
	if visible:
		_status_label.text = ""
		_trial = null
		_refresh()


func _set_mode(mode: String) -> void:
	_mode = mode
	_trial = null
	_status_label.text = ""
	_refresh()


## The offers of the open page (Tailor.get_shop_offers / get_wardrobe).
func get_offers() -> Array[Dictionary]:
	return Tailor.get_shop_offers(GameState) if _mode == MODE_SHOP else Tailor.get_wardrobe(GameState)


## MODE_SHOP ("Neue Kleidung kaufen") or MODE_WARDROBE ("Umziehen").
func get_mode() -> String:
	return _mode


## The look being tried on (a copy; changing it changes nothing).
func get_trial() -> Appearance:
	return _trial.duplicate() as Appearance if _trial else null


## Slot of clothes ("outfit") or a colour ("color", CUSTOM_SLOT = own colour); null if not shown.
func get_slot_button(kind: String, value: String) -> Button:
	for slot in _slots:
		if slot["kind"] == kind and slot["value"] == value:
			return slot["button"]
	return null


## Frame of the sheet the preview shows (direction = row).
func get_preview_region() -> Rect2:
	return _preview_texture.region


func _refresh() -> void:
	_refresh_done()
	_shop_button.set_pressed_no_signal(_mode == MODE_SHOP)
	_wardrobe_button.set_pressed_no_signal(_mode == MODE_WARDROBE)
	var offers: Array[Dictionary] = get_offers()
	_pick_trial(offers)
	_build_slots(offers)
	_update_page()


## Keeps the clothes being tried on if they are still on the page; else the worn ones (Umziehen) or
## the first ones on sale (Neue Kleidung), in the colour the player wears.
func _pick_trial(offers: Array[Dictionary]) -> void:
	var ids: Array = offers.map(func(offer: Dictionary) -> String: return offer["id"])
	if _trial != null and ids.has(_trial.outfit):
		return
	_trial = GameState.player_appearance.duplicate() as Appearance
	if _mode == MODE_SHOP:
		var sold: Array = offers.filter(func(offer: Dictionary) -> bool: return offer["unlocked"])
		if not sold.is_empty():
			_trial.outfit = sold[0]["id"]
	_trial.normalize()


func _build_slots(offers: Array[Dictionary]) -> void:
	_clear(_outfits)
	_clear(_colors)
	_slots.clear()
	for offer in offers:
		_outfits.add_child(_create_outfit_slot(offer))
	_empty_label.visible = offers.is_empty()
	_empty_label.text = Language.translate("Du hast schon alles, was die Schneiderin näht.") if _mode == MODE_SHOP \
			else ""
	if _trial_colorable():
		for color_id: String in Appearance.get_options("clothes_color"):
			_colors.add_child(_create_color_slot(color_id))
		_colors.add_child(_create_color_slot(CUSTOM_SLOT))


## Titles, frames, colour wheel, price and the button for the look being tried on. `from_wheel`:
## the wheel itself changed the colour (it keeps its own markers then).
func _update_page(from_wheel: bool = false) -> void:
	var has_outfit: bool = not get_offers().is_empty()
	_outfit_title.text = Language.translate("Kleidung: %s") % _trial.get_option_name("outfit") if has_outfit \
			else Language.translate("Kleidung")
	var colorable: bool = _trial_colorable() and has_outfit
	_color_title.visible = has_outfit
	_color_title.text = Language.translate("Farbe: %s") % _trial.get_option_name("clothes_color") if colorable \
			else Language.translate("Diese Kleidung behält ihre Farbe.")
	_colors.visible = colorable
	_wheel_holder.visible = colorable
	if colorable and not from_wheel:
		_wheel.set_color(_main_color(_trial.clothes_color))
	for slot in _slots:
		var value: String = slot["value"]
		var chosen: bool = value == _trial.outfit if slot["kind"] == "outfit" \
				else value == _trial.clothes_color or (value == CUSTOM_SLOT and Appearance.is_custom_color(_trial.clothes_color))
		(slot["frame"] as Control).visible = chosen
		if value == CUSTOM_SLOT:
			var color: String = _trial.clothes_color if Appearance.is_custom_color(_trial.clothes_color) else _custom_color
			(slot["icon"] as ColorRect).visible = not color.is_empty()
			if not color.is_empty():
				(slot["icon"] as ColorRect).color = _main_color(color)
	_update_action(has_outfit)
	_preview_texture.atlas = CharacterBaker.get_sheet(_trial)
	_preview.custom_minimum_size = Vector2.ONE * CharacterBaker.FRAME * PREVIEW_ZOOM
	_update_preview_frame()


func _update_action(has_outfit: bool) -> void:
	_action_button.visible = has_outfit
	_price_label.text = ""
	_price_label.remove_theme_color_override("font_color")
	if not has_outfit:
		return
	var outfit: String = _trial.outfit
	if _mode == MODE_SHOP:
		var price: int = Tailor.get_price(outfit)
		_action_button.text = Language.translate("Kaufen")
		if not Tailor.is_unlocked(GameState, outfit):
			_action_button.disabled = true
			_price_label.text = Language.translate("Noch nicht da")
			_price_label.add_theme_color_override("font_color", COLOR_LOCKED)
		else:
			_action_button.disabled = GameState.gold < price
			_price_label.text = Language.translate("%s Gold") % DamageKinds.format_number(price)
			if GameState.gold < price:
				_price_label.add_theme_color_override("font_color", COLOR_PROBLEM)
		return
	var look: Appearance = GameState.player_appearance
	var unchanged: bool = outfit == look.outfit and (_trial.clothes_color == look.clothes_color or not _trial_colorable())
	if unchanged:
		_action_button.text = Language.translate("Angezogen")
		_action_button.disabled = true
		_price_label.text = Language.translate("Trägst du gerade")
		_price_label.add_theme_color_override("font_color", COLOR_DONE)
		return
	var cost: int = Tailor.get_change_price(GameState, outfit, _trial.clothes_color)
	_action_button.text = Language.translate("Anziehen")
	_action_button.disabled = GameState.gold < cost
	_price_label.text = Language.translate("Neue Farbe: %s Gold") % DamageKinds.format_number(cost) if cost > 0 \
			else Language.translate("Kostenlos")
	if GameState.gold < cost:
		_price_label.add_theme_color_override("font_color", COLOR_PROBLEM)


func _create_outfit_slot(offer: Dictionary) -> Button:
	var look: Appearance = _trial.duplicate() as Appearance
	look.outfit = offer["id"]
	look.normalize()
	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.texture = CharacterBaker.get_portrait(look)
	var button: Button = _create_slot_button(SLOT_SIZE, _on_outfit_pressed.bind(offer["id"]))
	button.tooltip_text = look.get_option_name("outfit")
	if _mode == MODE_SHOP:
		button.tooltip_text += "\n" + (Language.translate("%s Gold") % DamageKinds.format_number(int(offer["price"])) \
				if offer["unlocked"] else Language.translate("Noch nicht da"))
		if not offer["unlocked"]:
			portrait.modulate = COLOR_LOCKED
	button.add_child(portrait)
	_add_frame(button, "outfit", offer["id"], portrait)
	return button


func _create_color_slot(value: String) -> Button:
	var button: Button = _create_slot_button(COLOR_SLOT_SIZE, _on_color_pressed.bind(value))
	var swatch := ColorRect.new()
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	swatch.offset_left = SWATCH_INSET
	swatch.offset_top = SWATCH_INSET
	swatch.offset_right = -SWATCH_INSET
	swatch.offset_bottom = -SWATCH_INSET
	if value == CUSTOM_SLOT:
		button.text = "+"
		button.tooltip_text = Language.translate("Eigene Farbe")
	else:
		swatch.color = _main_color(value)
		var look: Appearance = _trial.duplicate() as Appearance
		look.clothes_color = value
		button.tooltip_text = look.get_option_name("clothes_color")
	button.add_child(swatch)
	_add_frame(button, "color", value, swatch)
	return button


func _create_slot_button(side: float, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(side, side)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	if _slot_style:
		for state in ["normal", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, _slot_style)
		var hover: StyleBox = _slot_style.duplicate()
		if hover is StyleBoxTexture:
			(hover as StyleBoxTexture).modulate_color = COLOR_HOVER
		button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(on_pressed)
	return button


func _add_frame(button: Button, kind: String, value: String, icon: Control) -> void:
	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _frame_style)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(frame)
	_slots.append({"kind": kind, "value": value, "button": button, "frame": frame, "icon": icon})


func _trial_colorable() -> bool:
	return Tailor.is_colorable(_trial.outfit)


## Colour a swatch shows: the main shade.
func _main_color(value: String) -> Color:
	var colors: Array[Color] = Appearance.get_colors("clothes_color", value)
	return colors[1] if colors.size() > 1 else colors[0]


# --- Trying on -----------------------------------------------------------------------------

func _on_outfit_pressed(outfit: String) -> void:
	var was_colorable: bool = _trial_colorable()
	_trial.outfit = outfit
	if not Tailor.is_colorable(outfit):
		_trial.clothes_color = GameState.player_appearance.clothes_color
	_trial.normalize()
	_status_label.text = ""
	if was_colorable != _trial_colorable():
		_build_slots(get_offers())
	_update_page()


func _on_color_pressed(value: String) -> void:
	if value == CUSTOM_SLOT:
		if _custom_color.is_empty():
			return
		value = _custom_color
	_forget_custom_trial()
	_trial.clothes_color = value
	_update_page()


## An own colour from the wheel; the sheet of the previous own colour is dropped (dragging tries
## many colours).
func _on_wheel_changed(color: Color) -> void:
	if not _trial_colorable():
		return
	_forget_custom_trial()
	_custom_color = "#" + color.to_html(false)
	_trial.clothes_color = _custom_color
	_update_page(true)


func _forget_custom_trial() -> void:
	if Appearance.is_custom_color(_trial.clothes_color) and _trial.clothes_color != GameState.player_appearance.clothes_color:
		CharacterBaker.forget(_trial)


func _turn(step: int) -> void:
	_direction = posmod(_direction + step, TURN_ORDER.size())
	_update_preview_frame()


## Walks in place: frames 1-6 of the chosen direction.
func _update_preview_frame() -> void:
	var frame: int = 1 + int(_time * WALK_FPS) % (CharacterBaker.COLUMNS - 1)
	_preview_texture.region = CharacterBaker.get_frame_rect(TURN_ORDER[_direction], frame)


# --- Buying and changing -------------------------------------------------------------------

func _on_action_pressed() -> void:
	var outfit: String = _trial.outfit
	var color: String = _trial.clothes_color if _trial_colorable() else ""
	var done: bool
	if _mode == MODE_SHOP:
		done = Tailor.buy(GameState, outfit, color)
	else:
		done = Tailor.change(GameState, outfit, color)
	if not done:
		_status_label.add_theme_color_override("font_color", COLOR_PROBLEM)
		_status_label.text = Language.translate("Dafür reicht dein Gold nicht.")
		return
	_status_label.add_theme_color_override("font_color", COLOR_DONE)
	_status_label.text = Language.translate("Gekauft und angezogen!") if _mode == MODE_SHOP \
			else Language.translate("Umgezogen!")
	if _mode == MODE_SHOP:
		# The bought clothes are in the wardrobe now: show them there, worn.
		_mode = MODE_WARDROBE
		_trial = null
	_refresh()


static func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
