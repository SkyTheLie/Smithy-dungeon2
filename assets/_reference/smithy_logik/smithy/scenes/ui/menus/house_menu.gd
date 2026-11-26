class_name HouseMenu
extends StationMenu
## Window of the master builder (BuilderNpc): on top the price of the next level and what it brings
## (house.json description, sale tables), below the level of the player's house now. Builds the
## next one for gold over night (House.buy_next_level), but only as far as the reputation allows
## (Reputation.get_max_house_level, e.g. rank E = level 2), one level after the other. The player
## can't pick a level (for tests: admin panel, tab "Haus"). After a
## change the current scene is reloaded, the player appears at the spawn point RELOAD_SPAWN (next
## to the builder, Konrad stands on the market).

const RELOAD_SPAWN: StringName = &"FromBuilder"
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)
const COLOR_PRICE: Color = Color(1.0, 0.84, 0.35)
const RENT_FLAG: String = "smithy_rented"

@onready var _price_row: HBoxContainer = %PriceRow
@onready var _price_label: Label = %PriceLabel
@onready var _gain_label: Label = %GainLabel
@onready var _text_label: Label = %TextLabel
@onready var _buy_button: Button = %BuyButton
@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	super()
	_buy_button.pressed.connect(_on_buy_pressed)
	visibility_changed.connect(_refresh)
	GameState.gold_changed.connect(_queue_refresh)


## Top: the price of the next level and what it brings; below: the house now, reputation, tip.
func _refresh() -> void:
	if not visible:
		return
	_refresh_done()
	var house: House = GameState.house
	var lines: Array[String] = [Language.translate("Dein Haus jetzt: Stufe %d – %s") % [house.level, house.get_level_name()]]
	var price: int = house.get_next_price()
	if house.is_upgrading():
		_price_row.hide()
		_gain_label.text = Language.translate("Wir bauen schon! Morgen früh ist alles fertig.")
		_buy_button.hide()
	elif house.is_builder_busy():
		# One job at a time: the hall of fame or the greenhouse stands first (House.get_builder_job).
		_price_row.hide()
		_gain_label.text = Language.translate(House.BUSY_TEXT)
		_buy_button.hide()
	elif price < 0:
		_price_row.hide()
		_gain_label.text = Language.translate("Mehr kann ich nicht bauen. Ein prächtiges Haus!")
		_buy_button.hide()
	else:
		_price_row.show()
		_price_label.text = Language.translate("%d Gold") % price
		_price_label.add_theme_color_override("font_color", COLOR_PRICE if GameState.gold >= price else COLOR_ERROR)
		_gain_label.text = _get_gain_text(house.level + 1)
		_buy_button.show()
		_buy_button.text = Language.translate("Ausbauen")
		_buy_button.disabled = GameState.gold < price or not _reputation_allows()
		if GameState.gold < price:
			lines.append(Language.translate("Dir fehlen noch %d Gold.") % (price - GameState.gold))
		if not _reputation_allows():
			lines.append(Language.translate("Dafür brauchst du mehr Ruf: Rang %s.") % _needed_rank())
	lines.append(KeyBindings.fill(Language.translate("Tipp: Mit {key_build} kannst du in deinem Haus Möbel und Geräte verschieben.")))
	_text_label.text = "\n".join(lines)
	_message_label.text = ""


## What level `next_level` brings: its name, the description from house.json and how many sale
## tables there are afterwards (when that changes).
func _get_gain_text(next_level: int) -> String:
	var next: Dictionary = House.get_level_data(next_level)
	var now: Dictionary = House.get_level_data(next_level - 1)
	var lines: Array[String] = [Language.translate("Stufe %d: %s") % [next_level, next.get("name", "")],
			Language.translate("Du bekommst: %s") % next.get("description", "")]
	var tables: int = int(next.get("smithy_displays", 0)) + int(next.get("shop_displays", 0))
	var tables_now: int = int(now.get("smithy_displays", 0)) + int(now.get("shop_displays", 0))
	if tables != tables_now:
		lines.append(Language.translate("Verkaufstische: %d (jetzt %d)") % [tables, tables_now])
	return "\n".join(lines)


func _on_buy_pressed() -> void:
	if not GameState.story.has_flag(RENT_FLAG):
		_show_error(Language.translate("Erst brauchst du die Schmiede überhaupt – frag die Vermieterin."))
		return
	if GameState.house.is_builder_busy():
		_show_error(Language.translate(House.BUSY_TEXT))
		return
	if not _reputation_allows():
		_show_error(Language.translate("So ein Haus baue ich erst einem Schmied mit Ruf %s.") % _needed_rank())
		return
	if not GameState.house.buy_next_level():
		_show_error(Language.translate("Dafür reicht dein Gold nicht."))
		return
	GameState.pending_message = Language.translate("Der Baumeister fängt an. Morgen früh steht dein neues Haus.")
	_reload()


func _reload() -> void:
	close()
	GameState.travel_to(get_tree().current_scene.scene_file_path, RELOAD_SPAWN)


func _show_error(text: String) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", COLOR_ERROR)


## The next level is within what the reputation allows.
func _reputation_allows() -> bool:
	return GameState.house.level + 1 <= GameState.reputation.get_max_house_level()


## Rank needed for the next level, e.g. "D".
func _needed_rank() -> String:
	return String(Reputation.get_rank_for_house_level(GameState.house.level + 1).get("id", "?"))
