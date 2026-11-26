class_name Tailor
extends RefCounted
## Rules of the tailor in her house on the market (TailorStall, TailorMenu): the player buys new
## clothes and changes into clothes he owns, each in a colour of his choice.
##   - Clothes without "price" (appearance.json outfits) are the ones of the character creator:
##     always owned. Clothes with a price are sold here once their "unlock_flag" is set (none = at
##     once) and stay owned (GameState.owned_outfits, saved).
##   - Every figure may wear every piece (dresses too); Appearance.get_options_for decides.
##   - Buying: the price of the clothes, the chosen colour is included. Changing into owned clothes
##     is free, a new colour costs "color_price" (economy.json "tailor").
##   - Every change tells the player figure (Events.player_look_changed).
## Logic without a scene; it changes the game through `state` (GameState).


static func get_settings() -> Dictionary:
	return ContentDB.economy("tailor")


static func get_price(outfit: String) -> int:
	return int(ContentDB.appearance_section("outfits").get(outfit, {}).get("price", 0))


## Clothes of the character creator (no price).
static func is_starter_outfit(outfit: String) -> bool:
	return get_price(outfit) <= 0


static func is_owned(state: Node, outfit: String) -> bool:
	return is_starter_outfit(outfit) or state.owned_outfits.has(outfit)


## Sold now: its "unlock_flag" is set (or it has none).
static func is_unlocked(state: Node, outfit: String) -> bool:
	var flag: String = str(ContentDB.appearance_section("outfits").get(outfit, {}).get("unlock_flag", ""))
	return flag.is_empty() or state.story.has_flag(flag)


static func is_colorable(outfit: String) -> bool:
	return ContentDB.appearance_section("outfits").get(outfit, {}).get("colorable", false)


## Clothes for the player's figure, in the order of appearance.json:
## [{"id", "owned": bool, "unlocked": bool, "price": int, "worn": bool}].
static func get_offers(state: Node) -> Array[Dictionary]:
	var look: Appearance = state.player_appearance
	var offers: Array[Dictionary] = []
	for outfit: String in look.get_options_for("outfit"):
		offers.append({"id": outfit, "owned": is_owned(state, outfit), "unlocked": is_unlocked(state, outfit),
				"price": get_price(outfit), "worn": look.outfit == outfit})
	return offers


## "Neue Kleidung": the clothes not owned yet (sold ones first, then the ones not sold yet).
static func get_shop_offers(state: Node) -> Array[Dictionary]:
	var offers: Array[Dictionary] = get_offers(state).filter(func(offer: Dictionary) -> bool: return not offer["owned"])
	offers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["unlocked"] and not b["unlocked"])
	return offers


## "Umziehen": the clothes the player owns.
static func get_wardrobe(state: Node) -> Array[Dictionary]:
	return get_offers(state).filter(func(offer: Dictionary) -> bool: return offer["owned"])


## Buys clothes and puts them on in `color` ("" = keep the current colour; ignored for clothes
## that keep their colour). false if not sold, already owned, a wrong colour or too little gold.
static func buy(state: Node, outfit: String, color: String = "") -> bool:
	if is_owned(state, outfit) or not is_unlocked(state, outfit) \
			or not state.player_appearance.get_options_for("outfit").has(outfit):
		return false
	if not color.is_empty() and is_colorable(outfit) and not is_valid_color(color):
		return false
	if not state.spend_gold(get_price(outfit)):
		return false
	state.owned_outfits.append(outfit)
	state.achievements.count("outfit_bought")
	return _put_on(state, outfit, color)


## Gold for changing into `outfit` in `color` ("" = current colour): free, unless the colour is new.
static func get_change_price(state: Node, outfit: String, color: String = "") -> int:
	var look: Appearance = state.player_appearance
	if color.is_empty() or not is_colorable(outfit) or color == look.clothes_color:
		return 0
	return get_color_price()


## Changes into owned clothes in `color` ("" = current colour) and pays get_change_price. false if
## not owned, not for this figure, a wrong colour, nothing would change or too little gold.
static func change(state: Node, outfit: String, color: String = "") -> bool:
	var look: Appearance = state.player_appearance
	if not is_owned(state, outfit) or not look.get_options_for("outfit").has(outfit):
		return false
	if not color.is_empty() and is_colorable(outfit) and not is_valid_color(color):
		return false
	var new_color: bool = not color.is_empty() and is_colorable(outfit) and color != look.clothes_color
	if outfit == look.outfit and not new_color:
		return false
	if not state.spend_gold(get_change_price(state, outfit, color)):
		return false
	return _put_on(state, outfit, color)


## Puts on owned clothes, colour unchanged. false if not owned or not for this figure.
static func wear(state: Node, outfit: String) -> bool:
	var look: Appearance = state.player_appearance
	if not is_owned(state, outfit) or not look.get_options_for("outfit").has(outfit):
		return false
	return _put_on(state, outfit, "")


## Gold for a new clothes colour.
static func get_color_price() -> int:
	return int(get_settings().get("color_price", 0))


## Dyes the worn clothes (a colour id of appearance.json "clothes_colors" or an own "#rrggbb").
## false for clothes that keep their colour, the same colour or too little gold.
static func dye(state: Node, color: String) -> bool:
	var look: Appearance = state.player_appearance
	if not is_colorable(look.outfit) or look.clothes_color == color or not is_valid_color(color):
		return false
	return change(state, look.outfit, color)


## A colour id of appearance.json "clothes_colors" or an own colour "#rrggbb".
static func is_valid_color(color: String) -> bool:
	if Appearance.is_custom_color(color):
		return color.length() == 7 and color.substr(1).is_valid_hex_number()
	return Appearance.get_options("clothes_color").has(color)


static func _put_on(state: Node, outfit: String, color: String) -> bool:
	var look: Appearance = state.player_appearance
	look.outfit = outfit
	if not color.is_empty() and is_colorable(outfit):
		look.clothes_color = color
	look.normalize()
	state.get_node("/root/Events").emit_signal("player_look_changed")
	return true
