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
## Green / red over the place while something is dragged over it (set_drop_hint).
var _drop: Panel


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
	_drop = Panel.new()
	_drop.size = SIZE
	_drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop.visible = false
	add_child(_drop)
	mouse_exited.connect(set_drop_hint.bind(0))
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


## While dragging over it: 1 = green (it would go here), 2 = red (not here), 0 = nothing.
func set_drop_hint(state: int) -> void:
	_drop.visible = state != 0
	if state != 0:
		var color := Color(0.3, 0.9, 0.35, 0.45) if state == 1 else Color(1.0, 0.25, 0.2, 0.45)
		_drop.add_theme_stylebox_override("panel", box(color, Color(color, 0.9), 2))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _drop != null:
		_drop.visible = false


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
	if ShopGoods.is_potion(piece):
		var potion_path: String = String(Content.potion(String(piece.get("id", ""))).get("icon", ""))
		return load(potion_path) as Texture2D if ResourceLoader.exists(potion_path) else null
	if ShopGoods.is_backpack(piece):
		var backpack_path: String = String(BagLayout.backpack(String(piece.get("id", ""))).get("icon", ""))
		return load(backpack_path) as Texture2D if ResourceLoader.exists(backpack_path) else null
	if ShopGoods.is_container(piece):
		var container_path: String = String(ShopGoods.container_data(String(piece.get("id", ""))).get("icon", ""))
		return load(container_path) as Texture2D if ResourceLoader.exists(container_path) else null
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
	if ShopGoods.is_potion(piece):
		return int(Content.potion(id).get("rarity", 1))
	if ShopGoods.is_backpack(piece) or ShopGoods.is_container(piece):
		return 2
	if ShopGoods.is_gear(id):
		return int(piece.get("rarity", 1))
	return int(Content.material(id).get("rarity", 1))


## Tooltip: name (with its Bauart), rarity, values (pros with +, cons with -), for whom, price,
## description.
static func describe(piece: Dictionary, with_price: bool) -> String:
	var id: String = String(piece.get("id", ""))
	if ShopGoods.is_relic(piece):
		return _describe_relic(piece, with_price)
	if ShopGoods.is_potion(piece):
		return _describe_potion(piece, with_price)
	if ShopGoods.is_backpack(piece):
		return _describe_backpack(piece, with_price)
	if ShopGoods.is_container(piece):
		return _describe_container(piece, with_price)
	var gear: bool = ShopGoods.is_gear(id)
	var data: Dictionary = Content.gear_item(id) if gear else Content.material(id)
	var title: String = Language.translate(String(data.get("name", id)))
	var type_name: String = ShopGoods.type_name(piece) if gear else ""
	if not type_name.is_empty():
		title += " (%s)" % Language.translate(type_name)
	var lines: Array[String] = [title, Rarity.label(rarity_of(piece))]
	if gear:
		var values: Dictionary = ShopGoods.piece_stats(piece)
		for key: String in values:
			var line: String = stat_line(key, float(values[key]))
			if not line.is_empty():
				lines.append(line)
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
	lines.append(Language.translate("Hält für immer") if ShopGoods.relic_forever(piece) else Language.translate("Hält noch %d Dungeons") % left)
	if with_price:
		lines.append(Language.translate("Preis: %d Gold") % int(piece.get("price", 0)))
	lines.append(Language.translate(String(data.get("desc", ""))))
	return "\n".join(lines)


## Potion: name, "Trank", how much it heals, price, description.
static func _describe_potion(piece: Dictionary, with_price: bool) -> String:
	var data: Dictionary = Content.potion(String(piece.get("id", "")))
	var lines: Array[String] = [Language.translate(String(data.get("name", ""))), Language.translate("Trank") + " · " + Rarity.label(rarity_of(piece))]
	lines.append(Language.translate("Heilt %s Herzen") % String.num(int(data.get("heal", 0)) / 2.0, 1))
	lines.append(Language.translate("Im Dungeon: %s trinkt ihn") % Controls.key_name(Controls.get_key(Controls.POTION)))
	if with_price:
		lines.append(Language.translate("Preis: %d Gold") % int(piece.get("price", 0)))
	lines.append(Language.translate(String(data.get("desc", ""))))
	return "\n".join(lines)


## Backpack: name, "Rucksack" and its cells, price, description, how to attach it.
static func _describe_backpack(piece: Dictionary, with_price: bool) -> String:
	var data: Dictionary = BagLayout.backpack(String(piece.get("id", "")))
	var cells: Vector2i = BagLayout.backpack_size(String(piece.get("id", "")))
	var lines: Array[String] = [Language.translate(String(data.get("name", ""))), Language.translate("Rucksack: %d×%d Felder") % [cells.x, cells.y]]
	if with_price:
		lines.append(Language.translate("Preis: %d Gold") % int(piece.get("price", 0)))
	lines.append(Language.translate(String(data.get("desc", ""))))
	lines.append(Language.translate("Klick oder in den Reiter Inventar ziehen: an das Inventar anbauen"))
	return "\n".join(lines)


## Container: name, for what and how full, price, description, how to open it.
static func _describe_container(piece: Dictionary, with_price: bool) -> String:
	var id: String = String(piece.get("id", ""))
	var data: Dictionary = ShopGoods.container_data(id)
	var kind: String = String((Content.get_file("containers").get("kinds", {}) as Dictionary).get(String(data.get("kind", "")), ""))
	var lines: Array[String] = [Language.translate(String(data.get("name", id))), Language.translate("Behälter für %s") % Language.translate(kind)]
	lines.append(Language.translate("Belegt: %d/%d") % [(piece.get("items", []) as Array).size(), ShopGoods.container_slots(id)])
	if with_price:
		lines.append(Language.translate("Preis: %d Gold") % int(piece.get("price", 0)))
	lines.append(Language.translate(String(data.get("desc", ""))))
	lines.append(Language.translate("Klick: öffnen. Teile darauf ziehen: hineinlegen."))
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
		"reach": return Language.translate("Reichweite")
	return key


## One value of a piece: "Schaden +0.4", "Tempo -0.5"; fire_delay_mult as "Angriffstempo +18 %"
## (a shorter pause = faster); 0 and ×1 are left out ("").
static func stat_line(key: String, value: float) -> String:
	if key == "fire_delay_mult":
		var percent: int = roundi((1.0 / maxf(value, 0.01) - 1.0) * 100.0)
		return "" if percent == 0 else "%s %s%d %%" % [Language.translate("Angriffstempo"), "+" if percent > 0 else "-", absi(percent)]
	if key.ends_with("_mult"):
		return "" if is_equal_approx(value, 1.0) else "%s ×%s" % [stat_name(key.trim_suffix("_mult")), String.num(value, 2)]
	if is_zero_approx(value):
		return ""
	return "%s %s" % [stat_name(key), _signed(value)]


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
