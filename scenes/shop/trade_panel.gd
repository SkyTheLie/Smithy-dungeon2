class_name TradePanel
extends PanelContainer
## The Tausch tab in Egon's shop (data/trades.json, Trades, MetaState.trade): one row per offer,
## left what it costs (picture and "have/need", green when enough is at home), right what you get
## (a ShopSlot with its tooltip) and the button "Tauschen". Closed offers are grey and say why.
## Built in code; the shop calls refresh and hears `trade_requested`.

signal trade_requested(id: String)

const ROOM := Vector2(222, 252)
const COST_ICON := Vector2(18, 18)
const ENOUGH := Color(0.45, 0.9, 0.45)
const MISSING := Color(1.0, 0.4, 0.35)

var _rows: VBoxContainer
var _buttons: Dictionary[String, Button] = {}


func _init() -> void:
	name = "TradePanel"
	add_theme_stylebox_override("panel", ShopSlot.box(Color(0.1, 0.08, 0.07, 0.92), Color(0.4, 0.32, 0.25), 1))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	add_child(column)
	var title := _label(Language.translate("Tausch: Beute gegen Besonderes"), 10, Color(1, 0.86, 0.55))
	column.add_child(title)
	var hint := _label(Language.translate("Gezählt wird alles zu Hause: Lager, Inventar und Behälter."), 8, Color(0.75, 0.7, 0.65))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(ROOM.x, 0)
	column.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = ROOM
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 3)
	_rows.custom_minimum_size = Vector2(ROOM.x - 10, 0)
	scroll.add_child(_rows)


func get_button(id: String) -> Button:
	return _buttons.get(id, null)


## Builds every row new (counts, open or closed).
func refresh() -> void:
	for child: Node in _rows.get_children():
		child.queue_free()
	_buttons.clear()
	for offer: Dictionary in Trades.all():
		var piece: Dictionary = Trades.piece_of(offer)
		if piece.is_empty():
			continue
		_rows.add_child(_row(offer, piece))


func _row(offer: Dictionary, piece: Dictionary) -> Control:
	var id: String = String(offer.get("id", ""))
	var open: bool = Trades.is_open(offer)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", ShopSlot.box(Color(0.16, 0.12, 0.1, 0.95), Color(0.32, 0.27, 0.24), 1))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 3)
	frame.add_child(line)
	var costs := VBoxContainer.new()
	costs.add_theme_constant_override("separation", 1)
	costs.custom_minimum_size = Vector2(78, 0)
	line.add_child(costs)
	for cost: Array in Trades.costs(offer):
		var loot: String = String(cost[0])
		var need: int = int(cost[1])
		var have: int = MetaState.home_count(loot)
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.texture = ShopSlot.icon_of(loot)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = COST_ICON
		icon.tooltip_text = ShopSlot.describe({"id": loot, "count": 1}, false)
		icon.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		pair.add_child(icon)
		pair.add_child(_label("%d/%d" % [mini(have, 999), need], 9, ENOUGH if have >= need else MISSING))
		costs.add_child(pair)
	line.add_child(_label("→", 12, Color(1, 0.86, 0.55)))
	var slot := ShopSlot.new()
	slot.show_entry(piece)
	slot.tooltip_text = ShopSlot.describe(piece, false)
	line.add_child(slot)
	if open:
		var button := Button.new()
		button.name = "Trade_" + id
		button.text = Language.translate("Tauschen")
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 9)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.disabled = not MetaState.can_trade(id)
		button.pressed.connect(func() -> void: trade_requested.emit(id))
		line.add_child(button)
		_buttons[id] = button
	else:
		frame.modulate = Color(0.6, 0.6, 0.6)
		var reason := _label(Trades.lock_reason(offer), 8, Color(0.85, 0.8, 0.75))
		reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reason.custom_minimum_size = Vector2(60, 0)
		reason.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(reason)
	return frame


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label
