class_name ShopSlot
extends Panel
## One place in Egon's shop (table, inventory, hero): a frame in the colour of the rarity, the
## picture, the count or the price, a tooltip with name, rarity, values and price. Empty it shows
## a faint hint picture (hero slots). set_glow makes it shine (Egon points at it). Built in code.
## The shop decides what a click does (signal clicked).

signal clicked
## Right mouse button (inventory: put it on Egon's sell place).
signal right_clicked

const SIZE := Vector2(34, 34)
const ICON_SIZE := Vector2(26, 26)
const SLOT_COLOR := Color(0.18, 0.14, 0.12)
const EMPTY_BORDER := Color(0.32, 0.27, 0.24)
const GLOW_COLOR := Color(1.0, 0.85, 0.35)
const PRICE_COLOR := Color(1.0, 0.86, 0.35)
const HINT_ALPHA: float = 0.3

## What lies here: {} or {id, rarity?, count?, price?} (gear or loot).
var entry: Dictionary = {}
## Faint picture while empty (hero slots) and its name as tooltip.
var hint: Texture2D
var hint_name: String = ""
## How strong the empty picture shows (the money box shows its can fully).
var hint_alpha: float = HINT_ALPHA
var show_price: bool = false

var _icon: TextureRect
var _count: Label
var _glow: Panel
var _glow_tween: Tween


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The tooltip is translated already (describe).
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size = ICON_SIZE
	_icon.position = (SIZE - ICON_SIZE) / 2.0
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_count = Label.new()
	_count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_count.add_theme_font_size_override("font_size", 8)
	_count.add_theme_color_override("font_outline_color", Color.BLACK)
	_count.add_theme_constant_override("outline_size", 3)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.size = Vector2(SIZE.x - 3, 10)
	_count.position = Vector2(0, SIZE.y - 11)
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count)
	_glow = Panel.new()
	_glow.size = SIZE + Vector2(6, 6)
	_glow.position = Vector2(-3, -3)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.add_theme_stylebox_override("panel", box(Color(0, 0, 0, 0), GLOW_COLOR, 3))
	_glow.visible = false
	add_child(_glow)
	_refresh()


func show_entry(new_entry: Dictionary) -> void:
	entry = new_entry
	_refresh()


func is_empty() -> bool:
	return entry.is_empty()


func get_icon() -> Texture2D:
	return _icon.texture


## Egon points at it: the frame shines and pulses.
func set_glow(on: bool) -> void:
	if _glow_tween:
		_glow_tween.kill()
		_glow_tween = null
	_glow.visible = on
	if on:
		_glow.modulate.a = 1.0
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(_glow, "modulate:a", 0.25, 0.4)
		_glow_tween.tween_property(_glow, "modulate:a", 1.0, 0.4)


## A short jump (goods appear, something arrives).
func pop() -> void:
	pivot_offset = SIZE / 2.0
	scale = Vector2(0.4, 0.4)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		clicked.emit()
	elif click and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		right_clicked.emit()


func _refresh() -> void:
	if entry.is_empty():
		_icon.texture = hint
		_icon.modulate = Color(1, 1, 1, hint_alpha)
		_count.text = ""
		tooltip_text = hint_name
		add_theme_stylebox_override("panel", box(SLOT_COLOR, EMPTY_BORDER, 2))
		return
	_icon.texture = icon_of_piece(entry)
	_icon.modulate = Color.WHITE
	if show_price:
		_count.text = str(int(entry.get("price", 0)))
		_count.add_theme_color_override("font_color", PRICE_COLOR)
	else:
		_count.text = str(int(entry.get("count", 1))) if int(entry.get("count", 1)) > 1 else ""
		_count.remove_theme_color_override("font_color")
	tooltip_text = describe(entry, show_price)
	add_theme_stylebox_override("panel", box(SLOT_COLOR, Rarity.color(rarity_of(entry)), 2))


# --- Texts and pictures (also for the hero panel) ----------------------------------------

## The picture of a piece: a relic shows its item.
static func icon_of_piece(piece: Dictionary) -> Texture2D:
	if ShopGoods.is_relic(piece):
		var path: String = String(Content.item(String(piece.get("id", ""))).get("icon", ""))
		return load(path) as Texture2D if ResourceLoader.exists(path) else null
	return icon_of(String(piece.get("id", "")))


static func icon_of(id: String) -> Texture2D:
	var data: Dictionary = Content.gear_item(id) if ShopGoods.is_gear(id) else Content.material(id)
	var path: String = String(data.get("icon", ""))
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Gear has its own rarity; loot the one of its material (data/loot.json).
static func rarity_of(piece: Dictionary) -> int:
	var id: String = String(piece.get("id", ""))
	if ShopGoods.is_relic(piece):
		return ShopGoods.relic_rarity(id)
	if ShopGoods.is_gear(id):
		return int(piece.get("rarity", 1))
	return int(Content.material(id).get("rarity", 1))


## Tooltip: name, rarity, values, for whom, price, description.
static func describe(piece: Dictionary, with_price: bool) -> String:
	var id: String = String(piece.get("id", ""))
	if ShopGoods.is_relic(piece):
		return _describe_relic(piece, with_price)
	var gear: bool = ShopGoods.is_gear(id)
	var data: Dictionary = Content.gear_item(id) if gear else Content.material(id)
	var lines: Array[String] = [Language.translate(String(data.get("name", id))), Rarity.label(rarity_of(piece))]
	if gear:
		var values: Dictionary = ShopGoods.stats(id, int(piece.get("rarity", 1)))
		for key: String in values:
			lines.append("%s %s" % [stat_name(key), _signed(float(values[key]))])
		if data.has("class"):
			var character: Dictionary = Content.character(String(data["class"]))
			lines.append(Language.translate("Nur für: %s") % Language.translate(String(character.get("name", data["class"]))))
	if int(piece.get("count", 1)) > 1:
		lines.append("×%d" % int(piece["count"]))
	if with_price:
		lines.append(Language.translate("Preis: %d Gold") % int(piece.get("price", 0)))
	var desc: String = String(data.get("desc", ""))
	if not desc.is_empty():
		lines.append(Language.translate(desc))
	return "\n".join(lines)


## Relic: item name, "Relikt", how long it holds, price, the item's description.
static func _describe_relic(piece: Dictionary, with_price: bool) -> String:
	var data: Dictionary = Content.item(String(piece.get("id", "")))
	var lines: Array[String] = [Language.translate(String(data.get("name", ""))), Language.translate("Relikt") + " · " + Rarity.label(rarity_of(piece))]
	var left: int = int(piece.get("left", -1))
	lines.append(Language.translate("Hält für immer") if left < 0 else Language.translate("Hält noch %d Dungeons") % left)
	if with_price:
		lines.append(Language.translate("Preis: %d Gold") % int(piece.get("price", 0)))
	lines.append(Language.translate(String(data.get("desc", ""))))
	return "
".join(lines)


## The name of a value from player.json stats (written out for the translation script).
static func stat_name(key: String) -> String:
	match key:
		"damage": return Language.translate("Schaden")
		"hearts": return Language.translate("Herzen")
		"shield_hearts": return Language.translate("Schild-Herzen")
		"luck": return Language.translate("Glück")
		"fire_delay": return Language.translate("Pause zwischen Schüssen")
		"knockback": return Language.translate("Rückstoß")
		"move_speed": return Language.translate("Tempo")
	return key


## +0,25 / -0,01: up to two decimals, no trailing zeros.
static func _signed(value: float) -> String:
	var text: String = String.num(absf(value), 2)
	return ("-" if value < 0.0 else "+") + text


static func box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	return style
