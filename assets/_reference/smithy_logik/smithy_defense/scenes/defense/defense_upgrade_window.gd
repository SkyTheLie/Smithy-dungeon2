class_name DefenseUpgradeWindow
extends PanelContainer
## The forge defense window between runs: the result of the last run on top, then tabs "Laden"
## (random crystal offers at fixed prices, shown as cards, "Auffrischen"; bought crystals lie near the smithy when
## the next run starts), "Verbesserungen" (lasting, coins), "Relikte" (slots + collection),
## "Meisterschaft" (lasting, mastery), "Sammlung" (units, each upgradable) and "Aufträge".
## The window has a fixed size: every tab scrolls; the two trees are pictures to pull around with
## the mouse and zoom with the wheel (PanZoomView). Button "Run starten" sends `start_requested`.
## Shop: a pack shows its crystals side by side (a mixed pack different ones), rarely a relic is for
## sale (coins); the row "Im Laden" takes crystals out of the shop (DefenseRun.crystal_filter).
## Effects (DefenseUiFx): embers drift behind the content; after a run the numbers count up with a
## click, a new best throws confetti; "Auffrischen" turns the cards over; expensive crystals
## glitter; a bought upgrade gets a stamp in its tree. Buying goes through DefenseRun
## (FEHLERKLASSEN 13). Built when it opens and after each click, never while closed (FEHLERKLASSEN 11).

signal start_requested

const ICON_SIZE := Vector2(24, 24)
const SLOT_SIZE := Vector2(30, 30)
const CARD_SIZE := Vector2(0, 44)
const CARD_ICON_SIZE := Vector2(32, 32)
const BUNDLE_COLOR := Color(0.6, 0.88, 1.0)
const DEAL_COLOR := Color(1, 0.86, 0.35)
## Width of the yellow frame around a discounted offer (px).
const OUTLINE_WIDTH: int = 2
const PRICE_COLOR := Color(0.55, 0.9, 1.0)
const RELIC_COLOR := Color(0.75, 0.6, 1.0)
const COIN_PRICE_COLOR := Color(1, 0.86, 0.35)
const JACKPOT_COLOR := Color(1.0, 0.55, 0.9)
## The crystals of a pack overlap by this much in the card picture.
const PACK_STEP: float = 12.0
const FILTER_SIZE := Vector2(22, 22)
## Crystals with units this strong (crystals[].power) glitter in the shop.
const GLITTER_POWER: int = 4
const COUNT_TIME: float = 1.0
const COUNT_TICK: float = 0.07
const FLIP_TIME: float = 0.18
const FLIP_STAGGER: float = 0.06
enum Tab { SHOP, UPGRADES, RELICS, MASTERY, COLLECTION, QUESTS }
## Collection pictures: first frame of the walk sheet.
const SHEET_PATH: String = "res://assets/sprites/enemies/%s_walk.png"

var _run: DefenseRun
var _info_text: String = ""
var _gains_text: String = ""
var _wins_text: String = ""
## After a run: coins, crystal coin room and mastery it brought (they count up), -1 = nothing.
var _gain_coins: int = -1
var _gain_crystal_max: int = 0
var _gain_mastery: int = 0
var _count_part: float = 1.0
var _tick_left: float = 0.0

@onready var _info: Label = %InfoLabel
@onready var _coins: Label = %CoinsLabel
@onready var _mastery: Label = %MasteryLabel
@onready var _tabs: TabContainer = %Tabs
@onready var _offer_list: GridContainer = %OfferList
@onready var _stock_label: Label = %StockLabel
@onready var _reroll: Button = %RerollButton
@onready var _filter_icons: HBoxContainer = %FilterIcons
@onready var _upgrade_tree: DefenseUpgradeTree = %UpgradeTree
@onready var _relic_slots: HBoxContainer = %RelicSlots
@onready var _relic_list: GridContainer = %RelicList
@onready var _mastery_tree: DefenseUpgradeTree = %MasteryTree
@onready var _collection_list: GridContainer = %CollectionList
@onready var _quest_list: VBoxContainer = %QuestList
@onready var _relic_choice: VBoxContainer = %RelicChoice
@onready var _relic_choice_row: HBoxContainer = %RelicChoiceRow
@onready var _start: Button = %NextWaveButton
@onready var _embers: DefenseUiFx = %Embers
@onready var _confetti: DefenseUiFx = %Confetti


func _ready() -> void:
	hide()
	_tabs.set_tab_title(Tab.SHOP, Language.translate("Laden"))
	_tabs.set_tab_title(Tab.UPGRADES, Language.translate("Verbesserungen"))
	_tabs.set_tab_title(Tab.RELICS, Language.translate("Relikte"))
	_tabs.set_tab_title(Tab.MASTERY, Language.translate("Meisterschaft"))
	_tabs.set_tab_title(Tab.COLLECTION, Language.translate("Sammlung"))
	_tabs.set_tab_title(Tab.QUESTS, Language.translate("Aufträge"))
	%SlotTitle.text = Language.translate("Eingesetzt")
	%FilterLabel.text = Language.translate("Im Laden:")
	%RelicChoiceTitle.text = Language.translate("Elite besiegt! Wähle ein Relikt:")
	_reroll.pressed.connect(_on_reroll_pressed)
	_upgrade_tree.buy_requested.connect(_on_upgrade_pressed)
	_mastery_tree.buy_requested.connect(_on_upgrade_pressed)
	_start.pressed.connect(_on_start_pressed)
	_embers.embers = true


## Opens the window. `gained` = mastery of the run that just ended, -1 = no run yet (start).
func open_lobby(run: DefenseRun, gained: int) -> void:
	_run = run
	if gained < 0:
		_info_text = Language.translate("Kaufe Kristalle und Verbesserungen, dann starte den Run.")
		_gain_coins = -1
		_wins_text = ""
	else:
		_info_text = Language.translate("Die Schmiede ist in Welle %s gefallen.") % DamageKinds.format_number(run.wave)
		_gain_coins = run.run_coins + run.income()
		_gain_crystal_max = run.crystal_coin_max()
		_gain_mastery = gained
		_wins_text = "   ·   ".join(_run_wins(run))
	_count_part = 1.0
	_gains_text = _gains_line(1.0)
	_start.text = Language.translate("Run starten")
	_tabs.current_tab = Tab.SHOP
	_rebuild()
	show()
	_start.grab_focus()
	if _gain_coins >= 0:
		_count_up()
		if run.run_best:
			_celebrate.call_deferred()


## "+87 Münzen · Kristallmünzen wieder voll (210) · +1 Meisterschaft", the numbers at `part` (0..1).
func _gains_line(part: float) -> String:
	if _gain_coins < 0:
		return ""
	return "   ·   ".join(["+" + DamageKinds.format_number(int(round(_gain_coins * part))) + " " + Language.translate("Münzen"),
			Language.translate("Kristallmünzen wieder voll (%s)") % DamageKinds.format_number(int(round(_gain_crystal_max * part))),
			"+" + DamageKinds.format_number(int(round(_gain_mastery * part))) + " " + Language.translate("Meisterschaft")])


## The numbers of the run count up from 0, a click now and then.
func _count_up() -> void:
	_count_part = 0.0
	_tick_left = 0.0
	create_tween().tween_method(_set_count_part, 0.0, 1.0, COUNT_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _set_count_part(part: float) -> void:
	var step: float = part - _count_part
	_count_part = part
	_gains_text = _gains_line(part)
	%GainsLabel.text = _gains_text
	%GainsLabel.tooltip_text = _gains_line(1.0)
	_tick_left -= step * COUNT_TIME
	if _tick_left <= 0.0 and part < 1.0:
		_tick_left = COUNT_TICK
		AudioManager.play_sound("ui_click", 0.9 + part * 0.6)


## New best: confetti bursts from the title.
func _celebrate() -> void:
	var at: Vector2 = _info.get_global_rect().get_center() - _confetti.get_global_rect().position
	_confetti.confetti(at, 60)
	AudioManager.play_sound("achievement")


## What the run brought, big things first (shown in gold under the result).
func _run_wins(run: DefenseRun) -> PackedStringArray:
	var wins: PackedStringArray = []
	for index: int in run.run_parts:
		wins.append(Language.translate("%s besiegt!") % run.part_dungeon_name(index))
	for id: String in run.run_relics:
		wins.append(Language.translate("Relikt: %s") % Language.translate(String(run.relic(id).get("name", id))))
	for id: String in run.run_new_units:
		wins.append(Language.translate("Neue Einheit: %s") % Language.translate(String(run.all_units()[id].get("name", id))))
	if run.run_assaults > 0:
		wins.append(Language.translate("Anstürme abgewehrt: %s") % DamageKinds.format_number(run.run_assaults))
	for id: String in run.run_quests:
		var quest: Dictionary = run.quests().filter(func(q: Dictionary) -> bool: return String(q.get("id", "")) == id).front()
		wins.append(Language.translate("Auftrag erfüllt: %s") % quest_title(run, quest))
	if run.run_best:
		wins.append(Language.translate("Neue Bestleistung: Welle %s") % DamageKinds.format_number(run.best_wave))
	if run.run_boss_percent > 0:
		var boss: String = Language.translate("%s noch bei %s %%") % [Language.translate(run.run_boss_name), DamageKinds.format_number(run.run_boss_percent)]
		if run.run_boss_record:
			boss += " " + Language.translate("(so weit wie nie!)")
		wins.append(boss)
	if wins.is_empty():
		wins.append(Language.translate("Nächstes Mal klappt es!"))
	return wins


## Always the window between runs now (kept for the tests).
func is_lobby() -> bool:
	return true


func _rebuild() -> void:
	_info.text = _info_text
	_info.tooltip_text = _info_text
	%GainsLabel.text = _gains_text
	%GainsLabel.tooltip_text = _gains_line(1.0)
	%GainsLabel.visible = not _gains_text.is_empty()
	%WinsLabel.text = _wins_text
	%WinsLabel.tooltip_text = _wins_text.replace("   ·   ", "\n")
	%WinsLabel.visible = not _wins_text.is_empty()
	_coins.text = DamageKinds.format_number(_run.coins)
	%CrystalCoinsLabel.text = Language.translate("Kristallmünzen %s/%s") % [DamageKinds.format_number(_run.crystal_coins),
			DamageKinds.format_number(_run.crystal_coin_max())]
	%CrystalCoinsLabel.tooltip_text = Language.translate("Nur für Kristalle. Nach jedem Run wieder voll. Mehr Platz: Aufträge und Meisterschaft „Kristallbeutel“.")
	_mastery.text = Language.translate("Meisterschaft") + " " + DamageKinds.format_number(_run.mastery)
	_coins.tooltip_text = Language.translate("Münzen")
	for list: Node in [_offer_list, _relic_slots, _relic_list, _relic_choice_row,
			_collection_list, _quest_list, _filter_icons]:
		for child in list.get_children():
			child.queue_free()
	for index in _run.offers.size():
		_offer_list.add_child(_offer_button(index))
	if not _run.relic_offer.is_empty():
		_offer_list.add_child(_relic_offer_button())
	%FilterLabel.tooltip_text = Language.translate("Klicke einen Kristall an, damit er nicht mehr im Laden (und in der Taverne) kommt. Mindestens %s verschiedene bleiben.") \
			% DamageKinds.format_number(_run.min_shop_crystals())
	for entry: Dictionary in _run.crystals():
		if _run.is_crystal_unlocked(String(entry.get("id", ""))):
			_filter_icons.add_child(_filter_button(String(entry.get("id", ""))))
	_stock_label.text = Language.translate("Liegen beim nächsten Run bei der Schmiede: %s Kristalle") \
			% DamageKinds.format_number(_run.crystal_stock.size())
	var cost: int = _run.reroll_cost()
	_reroll.text = Language.translate("Auffrischen") + "  " + (Language.translate("gratis") if cost == 0 else DamageKinds.format_number(cost))
	_reroll.disabled = _run.coins < cost
	_upgrade_tree.build(_run, _run.upgrades())
	_mastery_tree.build(_run, _run.mastery_upgrades())
	for index in _run.relic_slots.size():
		_relic_slots.add_child(_slot_button(index))
	# Equipped relics only show in their slot above, the list has the ones left to equip.
	for entry: Dictionary in _run.relics():
		if _run.has_relic(String(entry.id)) and not _run.is_relic_equipped(String(entry.id)):
			_relic_list.add_child(_relic_button(entry))
	if _relic_list.get_child_count() == 0:
		var none := Label.new()
		none.text = Language.translate("Alle Relikte sind eingesetzt.") if not _run.owned_relics.is_empty() \
				else Language.translate("Noch keine Relikte. Jeder Boss lässt eines fallen.")
		_relic_list.add_child(none)
	var units: Dictionary = _run.all_units()
	for id: String in units:
		_collection_list.add_child(_collection_button(id))
	_tabs.set_tab_title(Tab.COLLECTION, Language.translate("Sammlung") + " %s/%s" % [
			DamageKinds.format_number(_run.discovered.size()), DamageKinds.format_number(units.size())])
	_fill_quests()
	_relic_choice.visible = not _run.relic_choice.is_empty()
	for id: String in _run.relic_choice:
		_relic_choice_row.add_child(_choice_button(_run.relic(id)))
	_start.disabled = _relic_choice.visible


# --- Rows --------------------------------------------------------------------------

## A card: the crystal's icon big on the left, name above, price below, "Paket!"/"Angebot!" as a
## coloured badge; dimmed when it cannot be bought.
func _offer_button(index: int) -> Button:
	var id: String = _run.offers[index]
	if id.is_empty():
		var sold := _card([], Language.translate("verkauft"), "", "", Color.WHITE)
		sold.disabled = true
		sold.modulate = Color(1, 1, 1, 0.45)
		return sold
	var ids: Array[String] = _run.offer_crystals(index)
	var icons: Array[Texture2D] = []
	var single_sum: int = 0
	var power: int = 1
	for crystal_id: String in ids:
		var crystal_item: ItemData = ContentDB.item(crystal_id)
		icons.append(crystal_item.icon if crystal_item else null)
		single_sum += _run.crystal_price(crystal_id)
		power = maxi(power, int(_run.crystal(crystal_id).get("power", 1)))
	var item: ItemData = ContentDB.item(id)
	var amount: int = ids.size()
	var badge: String = ""
	var badge_color := Color.WHITE
	if amount > 1:
		badge = Language.translate("Paket!")
		badge_color = BUNDLE_COLOR
	if _run.offer_discounts[index]:
		badge = Language.translate("Angebot!")
		badge_color = DEAL_COLOR
	if _run.offer_jackpots[index]:
		badge = Language.translate("Jackpot!")
		badge_color = JACKPOT_COLOR
	var title: String = item.display_name if item else id
	if _run.is_offer_mixed(index):
		title = Language.translate("Gemischtes Paket")
	elif amount > 1:
		title = "%s× " % DamageKinds.format_number(amount) + title
	var price: String = _crystal_price_text(_run.offer_price(index))
	if amount > 1 or _run.offer_discounts[index] or _run.offer_jackpots[index]:
		price += "  " + Language.translate("(statt %s)") % DamageKinds.format_number(single_sum)
	var button := _card(icons, title, price, badge, badge_color)
	if _run.offer_discounts[index]:
		_outline(button, DEAL_COLOR)
	button.disabled = not _run.can_buy_offer(index)
	if button.disabled:
		button.modulate = Color(1, 1, 1, 0.55)
	if power >= GLITTER_POWER or _run.offer_jackpots[index]:
		var glitter := DefenseUiFx.new()
		glitter.twinkle = true
		glitter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(glitter)
	var lines: PackedStringArray = []
	if amount > 1:
		lines.append(Language.translate("Paket: %s Kristalle für %s statt %s Kristallmünzen.") % [DamageKinds.format_number(amount),
				DamageKinds.format_number(_run.offer_price(index)), DamageKinds.format_number(single_sum)])
	var shown: Array[String] = []
	for crystal_id: String in ids:
		if shown.has(crystal_id):
			continue
		shown.append(crystal_id)
		var crystal: Dictionary = _run.crystal(crystal_id)
		var crystal_item: ItemData = ContentDB.item(crystal_id)
		if amount > 1:
			lines.append(crystal_item.display_name if crystal_item else crystal_id)
		lines.append(Language.translate("Liegt beim nächsten Run bei der Schmiede. %s Hammerschläge zerbrechen ihn, dann erscheinen %s bis %s Einheiten:") % [
				DamageKinds.format_number(_run.crystal_hits(crystal_id)), DamageKinds.format_number(int(crystal.get("min", 1))),
				DamageKinds.format_number(int(crystal.get("max", 1)))] + "\n" + _unit_list_text(crystal_id))
	button.tooltip_text = "\n".join(lines)
	button.pressed.connect(_on_offer_pressed.bind(index))
	return button


## The rare relic for coins: its picture, name, tier and price; bought it goes into a free slot.
func _relic_offer_button() -> Button:
	var id: String = _run.relic_offer
	var entry: Dictionary = _run.relic(id)
	var price: int = _run.relic_price(id)
	var button := _card([_relic_icon(entry)], Language.translate(String(entry.get("name", id))) + "  · " + Language.translate("Stufe %s") % DamageKinds.format_number(_run.relic_tier(id)),
			Language.translate("%s Münzen") % DamageKinds.format_number(price), Language.translate("Relikt!"), RELIC_COLOR, COIN_PRICE_COLOR)
	button.disabled = not _run.can_buy_relic_offer()
	if button.disabled:
		button.modulate = Color(1, 1, 1, 0.55)
	var glitter := DefenseUiFx.new()
	glitter.twinkle = true
	glitter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(glitter)
	button.tooltip_text = _relic_tooltip(entry) + "\n" + Language.translate("Selten im Laden. Kostet Münzen, bleibt für immer.")
	button.pressed.connect(_on_relic_offer_pressed)
	return button


## One crystal of the filter row: lit = it comes in the shop, dark = filtered out. A click switches.
func _filter_button(id: String) -> Button:
	var item: ItemData = ContentDB.item(id)
	var button := Button.new()
	button.icon = item.icon if item else null
	button.expand_icon = true
	button.custom_minimum_size = FILTER_SIZE
	var crystal_name: String = item.display_name if item else id
	if _run.is_crystal_filtered(id):
		button.modulate = Color(0.45, 0.45, 0.45, 0.8)
		button.tooltip_text = crystal_name + "\n" + Language.translate("Nicht im Laden. Klicken: wieder in den Laden.")
	elif _run.can_filter_crystal(id):
		button.tooltip_text = crystal_name + "\n" + Language.translate("Im Laden. Klicken: nicht mehr im Laden.")
	else:
		button.tooltip_text = crystal_name + "\n" + Language.translate("Im Laden. Mindestens %s verschiedene Kristalle bleiben im Laden.") \
				% DamageKinds.format_number(_run.min_shop_crystals())
	button.pressed.connect(_on_filter_pressed.bind(id))
	return button


## Button with an icon on the left and two lines of text (title, price) plus a badge on the right.
## The labels let the mouse through, so the whole card is one button.
func _card(icons: Array[Texture2D], title: String, price: String, badge: String, badge_color: Color,
		price_color: Color = PRICE_COLOR) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	# Every crystal of a pack side by side, overlapping a little (one icon: the normal card).
	var picture := Control.new()
	picture.custom_minimum_size = CARD_ICON_SIZE + Vector2(PACK_STEP * maxi(icons.size() - 1, 0), 0)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	for i in icons.size():
		var icon_rect := TextureRect.new()
		icon_rect.texture = icons[i]
		icon_rect.size = CARD_ICON_SIZE
		icon_rect.position = Vector2(PACK_STEP * i, (i % 2) * 3.0 - 1.5 if icons.size() > 1 else 0.0)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.add_child(icon_rect)
	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.add_theme_constant_override("separation", 0)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lines)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(top)
	top.add_child(_card_label(title, Color(1, 0.95, 0.85), true))
	if not badge.is_empty():
		top.add_child(_card_label(badge, badge_color, false))
	if not price.is_empty():
		lines.add_child(_card_label(price, price_color, true))
	return button


## A coloured frame around a card (discounted offers: yellow), drawn over it, lets the mouse through.
func _outline(card: Button, color: Color) -> void:
	var frame := Panel.new()
	frame.name = "Outline"
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color
	style.set_border_width_all(OUTLINE_WIDTH)
	style.set_corner_radius_all(2)
	frame.add_theme_stylebox_override("panel", style)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame)


func _card_label(text: String, color: Color, expand: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


## "1 Kristallmünze" / "3 Kristallmünzen".
func _crystal_price_text(price: int) -> String:
	return Language.translate("1 Kristallmünze") if price == 1 else Language.translate("%s Kristallmünzen") % DamageKinds.format_number(price)


## The units a crystal can call with their chance (unknown ones as "???"), then the rarity chances.
func _unit_list_text(crystal_id: String) -> String:
	var lines: PackedStringArray = []
	for pair: Array in _run.crystal_unit_chances(crystal_id):
		var unit_id: String = String(pair[0])
		var unit_name: String = "???"
		if _run.discovered.has(unit_id):
			var stats: Dictionary = _run.unit_stats(unit_id)
			unit_name = Language.translate(String(stats.get("name", unit_id))) + ": " + Language.translate("Leben %s, Schaden %s") % [
					DamageKinds.format_number(int(stats.hp)), DamageKinds.format_number(int(stats.damage))]
		lines.append("%s %%  %s" % [String.num(float(pair[1]), 0), unit_name])
	var chances: PackedStringArray = []
	var odds: Array = _run.rarity_chances()
	for i in odds.size():
		chances.append("R%d %s %%" % [i + 1, String.num(float(odds[i]), 0)])
	lines.append(Language.translate("Seltenheit:") + " " + ", ".join(chances))
	return "\n".join(lines)


func _collection_button(unit_id: String) -> Button:
	var entry: Dictionary = _run.all_units()[unit_id]
	if not _run.discovered.has(unit_id):
		var unknown := _row_button(null, "???")
		unknown.disabled = true
		unknown.tooltip_text = Language.translate("Noch nicht entdeckt: aus einem Kristall rufen.")
		return unknown
	var stats: Dictionary = _run.unit_stats(unit_id)
	var button := _row_button(_unit_picture(String(entry.get("sprite", ""))), Language.translate(String(entry.get("name", unit_id)))
			+ "  %s/%s" % [DamageKinds.format_number(_run.unit_level(unit_id)), DamageKinds.format_number(_run.unit_max_level())])
	button.add_theme_color_override("font_color", stats.get("rarity_color", Color.WHITE))
	var cost: int = _run.unit_upgrade_cost(unit_id)
	if cost < 0:
		button.disabled = true
	else:
		button.text += "  " + DamageKinds.format_number(cost)
		button.disabled = _run.mastery < cost
		button.pressed.connect(_on_unit_upgrade_pressed.bind(unit_id))
	var best: int = _run.unit_best(unit_id)
	var summon_quest: String = "u_summon_" + unit_id
	var grow_quest: String = "u_grow_" + unit_id
	button.tooltip_text = "\n".join([
			Language.translate("Beste Seltenheit: %s") % _run.rarity_name("r%d" % maxi(best, 1)),
			Language.translate("Gerufen: %s") % DamageKinds.format_number(_run.quest_count(summon_quest))
					+ ("  (" + Language.translate("Auftrag erfüllt") + ")" if _run.is_quest_done(summon_quest) else ""),
			Language.translate("Wird durch Siege seltener: R2 nach %s, R3 nach %s, R4 nach %s, R5 nach %s Siegen.") % _rarity_kill_texts()
					+ ("  (" + Language.translate("Seltenheits-Auftrag erfüllt") + ")" if _run.is_quest_done(grow_quest) else ""),
			Language.translate("Werte bei R1:"),
			Language.translate("Leben %s, Schaden %s") % [DamageKinds.format_number(int(stats.hp)), DamageKinds.format_number(int(stats.damage))],
			Language.translate("Angriff alle %s s, Reichweite %s") % [String.num(float(stats.attack_interval), 2), DamageKinds.format_number(int(stats.get("range", 0)))],
			Language.translate("Lauftempo %s") % DamageKinds.format_number(int(stats.get("speed", 0))),
			_skill_text(stats),
			Language.translate("Klicken: Leben und Schaden ×1,25 (Meisterschaft)")])
	return button


## The kills for R2 … R5 as four numbers (rarity_growth.kills, "-" where none).
func _rarity_kill_texts() -> Array:
	var kills: Array[int] = _run.rarity_kills()
	var result: Array = []
	for i in 4:
		result.append(DamageKinds.format_number(kills[i]) if i < kills.size() else "-")
	return result


## "Fähigkeit: Feuerball (alle 6 s)" or "" for units without a skill.
func _skill_text(stats: Dictionary) -> String:
	var skill: Dictionary = stats.get("skill", {})
	if skill.is_empty():
		return Language.translate("Keine Fähigkeit")
	return Language.translate("Fähigkeit: %s (alle %s s)") % [Language.translate(String(skill.get("name", ""))),
			String.num(float(skill.get("interval", 0.0)), 0)]


func _unit_picture(sprite: String) -> Texture2D:
	var path: String = SHEET_PATH % sprite
	if not ResourceLoader.exists(path):
		return null
	var picture := AtlasTexture.new()
	picture.atlas = load(path)
	picture.region = Rect2(0, 0, picture.atlas.get_height(), picture.atlas.get_height())
	return picture


## A summary line, then the open quests sorted by progress (closest to done first), each with a
## bar and its reward; the done ones last, greyed out.
func _fill_quests() -> void:
	var open: Array[Dictionary] = []
	var done: Array[Dictionary] = []
	for quest: Dictionary in _run.quests():
		if _run.is_quest_done(String(quest.get("id", ""))):
			done.append(quest)
		else:
			open.append(quest)
	open.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _quest_part(a) > _quest_part(b))
	var head := Label.new()
	head.text = Language.translate("Erfüllt: %s/%s  ·  Kristallmünzen-Vorrat %s") % [DamageKinds.format_number(done.size()),
			DamageKinds.format_number(done.size() + open.size()), DamageKinds.format_number(_run.crystal_coin_max())]
	head.modulate = Color(0.55, 0.9, 1.0)
	_quest_list.add_child(head)
	for quest: Dictionary in open:
		_quest_list.add_child(_quest_row(quest, false))
	for quest: Dictionary in done:
		_quest_list.add_child(_quest_row(quest, true))


## A quest's title (translated): the JSON name, or for a unit's own quest made from its unit
## ("Rufe 10 × Feuersalamander", "Bringe Feuersalamander durch Siege auf R3"); unknown units "???".
static func quest_title(run: DefenseRun, quest: Dictionary) -> String:
	var unit_id: String = String(quest.get("unit", ""))
	if unit_id.is_empty():
		return Language.translate(String(quest.get("name", quest.get("id", ""))))
	var unit_name: String = Language.translate(String((run.all_units().get(unit_id, {}) as Dictionary).get("name", unit_id))) \
			if run.discovered.has(unit_id) else "???"
	if String(quest.get("kind", "")) == "grow":
		return Language.translate("Bringe %s durch Siege auf %s") % [unit_name, run.rarity_name(String(quest.get("rarity", "r2")))]
	return Language.translate("Rufe %s × %s") % [DamageKinds.format_number(int(quest.get("count", 1))), unit_name]


## How far a quest is (0..1).
func _quest_part(quest: Dictionary) -> float:
	return clampf(float(_run.quest_count(String(quest.get("id", "")))) / float(maxi(int(quest.get("count", 1)), 1)), 0.0, 1.0)


## Name | bar with "x/y" | reward ("+1 KM"); done: greyed with "erfüllt".
func _quest_row(quest: Dictionary, done: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var id: String = String(quest.get("id", ""))
	var count: int = int(quest.get("count", 1))
	var title := Label.new()
	title.text = quest_title(_run, quest)
	title.tooltip_text = title.text
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	title.custom_minimum_size = Vector2(230, 0)
	title.clip_text = true
	row.add_child(title)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(110, 10)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = count
	bar.value = count if done else mini(_run.quest_count(id), count)
	row.add_child(bar)
	var numbers := Label.new()
	numbers.custom_minimum_size = Vector2(70, 0)
	numbers.text = Language.translate("erfüllt") if done else "%s/%s" % [DamageKinds.format_number(int(bar.value)), DamageKinds.format_number(count)]
	row.add_child(numbers)
	# Reward: crystal coins in the supply and/or income after every run.
	var reward := Label.new()
	var short: PackedStringArray = []
	var long: PackedStringArray = []
	if int(quest.get("crystal_coins", 0)) > 0:
		short.append(Language.translate("+%s KM") % DamageKinds.format_number(int(quest.get("crystal_coins", 0))))
		long.append(Language.translate("+%s Kristallmünzen im Vorrat") % DamageKinds.format_number(int(quest.get("crystal_coins", 0))))
	if int(quest.get("income", 0)) > 0:
		short.append(Language.translate("+%s Eink.") % DamageKinds.format_number(int(quest.get("income", 0))))
		long.append(Language.translate("+%s Münzen Einkommen nach jedem Run") % DamageKinds.format_number(int(quest.get("income", 0))))
	reward.text = " ".join(short)
	reward.tooltip_text = "\n".join(long)
	reward.mouse_filter = Control.MOUSE_FILTER_PASS
	reward.modulate = Color(0.55, 0.9, 1.0) if int(quest.get("income", 0)) <= 0 else COIN_PRICE_COLOR
	row.add_child(reward)
	if done:
		row.modulate = Color(0.55, 0.55, 0.55)
	elif _quest_part(quest) >= 0.75:
		title.modulate = Color(1, 0.86, 0.55)
	return row


func _relic_icon(entry: Dictionary) -> Texture2D:
	var path: String = String(entry.get("icon", ""))
	return load(path) if ResourceLoader.exists(path) else null


func _relic_tooltip(entry: Dictionary) -> String:
	return Language.translate(String(entry.get("name", ""))) + "\n" + Language.translate(String(entry.get("description", "")))


func _relic_button(entry: Dictionary) -> Button:
	var id: String = String(entry.get("id", ""))
	var button := _row_button(_relic_icon(entry), Language.translate(String(entry.get("name", id))))
	button.tooltip_text = _relic_tooltip(entry)
	button.text += "  (" + Language.translate("einsetzen") + ")"
	button.disabled = not _run.relic_slots.has("")
	button.pressed.connect(_on_relic_equip_pressed.bind(id))
	return button


func _choice_button(entry: Dictionary) -> Button:
	var button := Button.new()
	button.icon = _relic_icon(entry)
	button.expand_icon = true
	button.custom_minimum_size = Vector2(150, 40)
	button.add_theme_constant_override("icon_max_width", int(ICON_SIZE.x))
	button.text = Language.translate(String(entry.get("name", "")))
	button.tooltip_text = _relic_tooltip(entry)
	button.pressed.connect(_on_relic_chosen.bind(String(entry.get("id", ""))))
	return button


func _slot_button(index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = SLOT_SIZE
	button.expand_icon = true
	var entry: Dictionary = _run.relic(_run.relic_slots[index])
	if entry.is_empty():
		button.disabled = true
		button.tooltip_text = Language.translate("Freier Platz: klicke unten ein Relikt an.")
	else:
		button.icon = _relic_icon(entry)
		button.tooltip_text = _relic_tooltip(entry) + "\n" + Language.translate("Klicken: herausnehmen")
		button.pressed.connect(_on_slot_pressed.bind(index))
	return button


func _row_button(icon: Texture2D, text: String) -> Button:
	var button := Button.new()
	button.icon = icon
	button.expand_icon = true
	button.custom_minimum_size = Vector2(0, ICON_SIZE.y + 4)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_constant_override("icon_max_width", int(ICON_SIZE.x))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.text = text
	return button


# --- Clicks ------------------------------------------------------------------------

func _on_offer_pressed(index: int) -> void:
	if _run.buy_offer(index):
		AudioManager.play_sound("coins")
		_rebuild()


func _on_relic_offer_pressed() -> void:
	if _run.buy_relic_offer():
		AudioManager.play_sound("achievement")
		_rebuild()


func _on_filter_pressed(id: String) -> void:
	if _run.set_crystal_filtered(id, not _run.is_crystal_filtered(id)):
		AudioManager.play_sound("ui_click")
		_rebuild()


func _on_reroll_pressed() -> void:
	if _run.reroll():
		AudioManager.play_sound("coins")
		_rebuild()
		_flip_cards()
		if _run.last_jackpot:
			_jackpot()


## Jackpot: confetti over the shop and a fanfare.
func _jackpot() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_confetti.confetti(_offer_list.get_global_rect().get_center() - _confetti.get_global_rect().position, 80)
	AudioManager.play_sound("achievement")


## The new offers turn over one after the other (once they have their size).
func _flip_cards() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var index: int = 0
	for card: Node in _offer_list.get_children():
		if card.is_queued_for_deletion() or not card is Control:
			continue
		var control: Control = card
		control.pivot_offset = control.size / 2.0
		control.scale = Vector2(0.0, 1.0)
		var turn := create_tween()
		turn.tween_interval(index * FLIP_STAGGER)
		turn.tween_property(control, "scale", Vector2.ONE, FLIP_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		index += 1


func _on_upgrade_pressed(id: String) -> void:
	if _run.buy_upgrade(id):
		AudioManager.play_sound("level_up")
		_rebuild()
		_upgrade_tree.stamp(id)
		_mastery_tree.stamp(id)


func _on_unit_upgrade_pressed(unit_id: String) -> void:
	if _run.buy_unit_upgrade(unit_id):
		AudioManager.play_sound("level_up")
		_rebuild()


func _on_relic_chosen(id: String) -> void:
	if _run.choose_relic(id):
		AudioManager.play_sound("level_up")
		_rebuild()


func _on_relic_equip_pressed(id: String) -> void:
	if _run.equip_relic(id):
		_rebuild()


func _on_slot_pressed(index: int) -> void:
	_run.unequip_slot(index)
	_rebuild()


func _on_start_pressed() -> void:
	hide()
	start_requested.emit()
