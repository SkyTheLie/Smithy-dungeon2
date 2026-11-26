class_name UnlockNotices
extends RefCounted
## Popups (UnlockPopup: picture, name, short text, one after the other) when something new is
## unlocked, so the player knows about it: a station now standing in the smithy, a station or a
## piece of furniture the furniture trader offers from now on (economy.json "stations", house.json
## "furniture" with "unlock_flag" / "house_level"), new recipes and molds (announce_recipes). Each
## station and furniture popup comes once (Story.shown_hints); mark_known() takes what is there
## already without a popup (start of a game, loading a save).

## Recipes shown one by one; more are counted in one last popup.
const MAX_RECIPE_POPUPS: int = 8
## Names of the stations that are always there (the others come from economy.json "stations").
const STATION_NAMES: Dictionary = {"anvil": "Amboss", "forge": "Esse", "workbench": "Werkbank",
		"smelter": "Schmelze"}


## Everything unlocked so far counts as known (no popup).
static func mark_known() -> void:
	check(false)


## Popups for what became available since the last check (`announce` false = only mark it known).
static func check(announce: bool) -> void:
	var story: Story = GameState.story
	var stations: Dictionary = ContentDB.economy("stations")
	for station_id: String in stations:
		var info: Dictionary = stations[station_id]
		var station_name: String = info.get("name", station_id)
		if story.has_flag(info.get("flag", "")):
			_notice("unlock_station_%s" % station_id, info.get("icon", ""), station_name,
					Language.translate("%s wurde freigeschaltet und ist jetzt in deiner Schmiede verfügbar.") % station_name, announce)
		elif _is_offered(info):
			_offer("unlock_station_shop_%s" % station_id, info.get("icon", ""), station_name, info, announce)
	var furniture: Dictionary = ContentDB.house("furniture")
	for furniture_id: String in furniture:
		var piece: Dictionary = furniture[furniture_id]
		if piece.has("unlock_flag") and _is_offered(piece):
			_offer("unlock_furniture_%s" % furniture_id, piece.get("texture", ""), piece.get("name", furniture_id), piece, announce)


## A popup per new mold and recipe; the recipes that come with a mold are not listed again.
static func announce_recipes(recipes: Array[RecipeData]) -> void:
	var with_mold: Array[RecipeData] = []
	var molds: Array[RecipeData] = []
	for recipe in recipes:
		if recipe.get_mold_part() and not molds.has(recipe):
			molds.append(recipe)
			with_mold.append_array(ContentDB.get_mold_unlocks(recipe))
	var shown: Array[RecipeData] = molds.duplicate()
	for recipe in recipes:
		if not with_mold.has(recipe) and not molds.has(recipe):
			shown.append(recipe)
	# A group (e.g. the nine iron staffs, one per crystal) is one popup, like rings and amulets.
	shown = RecipeData.collapse_groups(shown)
	for recipe in shown.slice(0, MAX_RECIPE_POPUPS):
		var part: ItemData = recipe.get_mold_part()
		if part:
			UnlockPopup.add(recipe.get_icon(), part.display_name, Language.translate("Neue Gussform"))
		elif recipe.group != "":
			UnlockPopup.add(recipe.get_icon(), recipe.group, Language.translate("Neues Rezept (beliebiger %s)") % recipe.group_slot_name)
		else:
			UnlockPopup.add(recipe.get_icon(), recipe.get_display_name(), Language.translate("Neues Rezept"))
	if shown.size() > MAX_RECIPE_POPUPS:
		UnlockPopup.add(null, Language.translate("Neue Rezepte"), Language.translate("Und %d weitere") % (shown.size() - MAX_RECIPE_POPUPS))


static func station_name(station: StringName) -> String:
	if STATION_NAMES.has(String(station)):
		return Language.translate(STATION_NAMES[String(station)])
	return ContentDB.economy("stations").get(String(station), {}).get("name", String(station).capitalize())


## The furniture trader offers it: its unlock_flag is set and the house is big enough.
static func _is_offered(info: Dictionary) -> bool:
	var unlock_flag: String = info.get("unlock_flag", "")
	if not unlock_flag.is_empty() and not GameState.story.has_flag(unlock_flag):
		return false
	return GameState.house.level >= int(info.get("house_level", 0))


static func _offer(id: String, icon_path: String, title: String, info: Dictionary, announce: bool) -> void:
	_notice(id, icon_path, title, Language.translate("Neu bei der Möbelhändlerin am Markt: %d Gold") % int(info.get("price", 0)), announce)


static func _notice(id: String, icon_path: String, title: String, text: String, announce: bool) -> void:
	var story: Story = GameState.story
	if story.shown_hints.has(id):
		return
	story.shown_hints.append(id)
	if announce:
		UnlockPopup.add(load(icon_path) if ResourceLoader.exists(icon_path) else null, title, text)
