class_name Tailor
extends RefCounted
## Rules of the tailor on the market (TailorStall, TailorMenu): the player changes clothes and their
## colour, and buys new clothes.
##   - Clothes without "price" (appearance.json outfits) are the ones of the character creator:
##     always owned. Clothes with a price are sold here once their "unlock_flag" is set (none = at
##     once) and stay owned (GameState.owned_outfits, saved).
##   - Only clothes for the player's figure (Appearance.get_options_for: the dresses for "female").
##   - Wearing owned clothes and changing the colour cost "color_price" (economy.json "tailor") /
##     nothing; every change tells the player figure (Events.player_look_changed).
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


## Clothes the tailor shows for the player's figure, in the order of appearance.json:
## [{"id", "owned": bool, "unlocked": bool, "price": int, "worn": bool}].
static func get_offers(state: Node) -> Array[Dictionary]:
	var look: Appearance = state.player_appearance
	var offers: Array[Dictionary] = []
	for outfit: String in look.get_options_for("outfit"):
		offers.append({"id": outfit, "owned": is_owned(state, outfit), "unlocked": is_unlocked(state, outfit),
				"price": get_price(outfit), "worn": look.outfit == outfit})
	return offers


## Buys clothes and puts them on. false if not sold, already owned or too little gold.
static func buy(state: Node, outfit: String) -> bool:
	if is_owned(state, outfit) or not is_unlocked(state, outfit) \
			or not state.player_appearance.get_options_for("outfit").has(outfit):
		return false
	if not state.spend_gold(get_price(outfit)):
		return false
	state.owned_outfits.append(outfit)
	state.achievements.count("outfit_bought")
	return wear(state, outfit)


## Puts on owned clothes. false if not owned or not for this figure.
static func wear(state: Node, outfit: String) -> bool:
	var look: Appearance = state.player_appearance
	if not is_owned(state, outfit) or not look.get_options_for("outfit").has(outfit):
		return false
	look.outfit = outfit
	look.normalize()
	_changed(state)
	return true


## Gold for a new clothes colour.
static func get_color_price() -> int:
	return int(get_settings().get("color_price", 0))


## Dyes the worn clothes (a colour id of appearance.json "clothes_colors" or an own "#rrggbb").
## false for clothes that keep their colour, the same colour or too little gold.
static func dye(state: Node, color: String) -> bool:
	var look: Appearance = state.player_appearance
	if not look.get_outfit_data().get("colorable", false) or look.clothes_color == color:
		return false
	if not Appearance.is_custom_color(color) and not Appearance.get_options("clothes_color").has(color):
		return false
	if not state.spend_gold(get_color_price()):
		return false
	look.clothes_color = color
	_changed(state)
	return true


static func _changed(state: Node) -> void:
	state.get_node("/root/Events").emit_signal("player_look_changed")
