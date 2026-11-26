class_name ForgeSign
extends RefCounted
## The name sign of the player's smithy (house.json "forge_sign"). It is bought once at the furniture
## trader (item "item", only for its name, icon and price: the sign never goes into the inventory,
## it goes into the storage outside the house, `owned`; the purchase also sets the story flag
## "bought_<item>", after that the trader doesn't offer it any more). In front of the smithy B
## opens that storage and places it (ForgeSignPlacer, HouseExteriorMenu): the board can hang
## anywhere on the house wall, its place is kept per house level (`spots`). The first time it
## hangs, the name window opens (ForgeSignMenu). Taken off,
## the sign stays the player's (no item back); B in front of the house hangs it up again.
## Without a place for the current house level (e.g. after an upgrade) it sticks out from a corner.
## The board shows the name in one of the themes: wood from the start, every other metal from the
## first victory in that league, smiths or heroes (theme "league", leagues.json, place 1;
## TournamentRanking.won_leagues, so wins from before this sign count too).
## Lives in GameState.house.forge_sign, saved with the house.

## Attached, taken off, moved, renamed or another theme.
signal changed

const DEFAULT_THEME: String = "wood"

## The sign hangs on the smithy.
var attached: bool = false
## Bought: the sign is the player's (in the storage outside while it doesn't hang).
var owned: bool = false
## Name on the board ("" = default_name).
var sign_name: String = ""
## Theme id (house.json forge_sign.themes).
var theme: String = DEFAULT_THEME
## Where the board hangs per house level: "<level>" -> [x, y] (top left corner of the board in
## the coordinates of the smithy node). Missing = the corner of that level.
var spots: Dictionary = {}


# --- Data -------------------------------------------------------------------------

static func data() -> Dictionary:
	return ContentDB.house("forge_sign")


static func item_id() -> String:
	return str(data().get("item", "forge_sign"))


static func max_length() -> int:
	return int(data().get("max_length", 16))


## Share of the board that must lie on the house wall to hang (house.json "min_on_wall").
static func min_on_wall() -> float:
	return clampf(float(data().get("min_on_wall", 1.0)), 0.0, 1.0)


static func themes() -> Array:
	return data().get("themes", [])


## Entry of a theme ({} = unknown).
static func get_theme_data(id: String) -> Dictionary:
	for entry: Dictionary in themes():
		if str(entry.get("id", "")) == id:
			return entry
	return {}


## The theme a smith league gives at its first victory ("" = none).
static func theme_for_league(league_id: String) -> String:
	if league_id.is_empty():
		return ""
	for entry: Dictionary in themes():
		if str(entry.get("league", "")) == league_id:
			return str(entry.get("id", ""))
	return ""


## Story flag the purchase sets (GameState.record_purchase).
static func bought_flag() -> String:
	return "bought_" + item_id()


# --- State ------------------------------------------------------------------------

## The player has the sign: bought or hanging (or the flag of a save from before `owned`). Then
## the trader doesn't sell another one.
func is_owned() -> bool:
	return owned or attached or _game_state().story.has_flag(bought_flag())


## Bought at the trader: straight into the storage outside the house (B in front of the smithy).
func store() -> void:
	if owned:
		return
	owned = true
	changed.emit()


## Saves from before: a sign item in the bag moves into the storage outside (no story event).
## Untyped `inventory`: Inventory may name autoloads (see _game_state).
func take_from_inventory(inventory: Resource) -> void:
	var item: Resource = ContentDB.item(item_id())
	var count: int = inventory.count_item(item)
	if count <= 0:
		return
	inventory.remove_item(item, count)
	store()


## Wood always; the others once their league was won (place 1, smiths or heroes).
func is_theme_unlocked(id: String) -> bool:
	var entry: Dictionary = get_theme_data(id)
	if entry.is_empty():
		return false
	var league: String = str(entry.get("league", ""))
	if league.is_empty():
		return true
	var won: Dictionary = _game_state().ranking.won_leagues
	return won.get("smith", []).has(league) or won.get("hero", []).has(league)


## Why a theme can't be chosen yet ("" = it can).
func get_theme_blocker(id: String) -> String:
	if is_theme_unlocked(id):
		return ""
	var index: int = TournamentRanking.league_index(str(get_theme_data(id).get("league", "")))
	return Language.translate("Gewinne die %s (Platz 1, Schmiede oder Wettkampf).") % TournamentRanking.league_name(index)


## The name shown on the board.
func get_display_name() -> String:
	return sign_name if not sign_name.is_empty() else str(data().get("default_name", "Schmiede"))


## Hangs the sign up. false = the player has no sign, or it hangs already.
func attach() -> bool:
	if attached or not is_owned():
		return false
	owned = true
	attached = true
	changed.emit()
	return true


## Takes the sign down. It stays the player's (name, theme and places too).
func remove() -> void:
	if not attached:
		return
	attached = false
	changed.emit()


func set_sign_name(new_name: String) -> void:
	var cleaned: String = new_name.strip_edges().left(max_length()).strip_edges()
	if cleaned == sign_name:
		return
	sign_name = cleaned
	changed.emit()


## Chooses a theme. false = unknown or not won yet.
func set_theme(id: String) -> bool:
	if not is_theme_unlocked(id):
		return false
	if id != theme:
		theme = id
		changed.emit()
	return true


## Place of the board at a house level, Vector2.INF = none (the corner).
func get_spot(level: int) -> Vector2:
	var saved: Array = spots.get(str(level), [])
	return Vector2(float(saved[0]), float(saved[1])) if saved.size() >= 2 else Vector2.INF


func set_spot(level: int, top_left: Vector2) -> void:
	spots[str(level)] = [roundi(top_left.x), roundi(top_left.y)]
	changed.emit()


# --- Saving -------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"attached": attached, "owned": owned, "name": sign_name, "theme": theme, "spots": spots.duplicate(true)}


func load_save_data(saved: Dictionary) -> void:
	attached = bool(saved.get("attached", false))
	# Saves from before `owned`: a hanging sign was bought.
	owned = bool(saved.get("owned", attached))
	sign_name = str(saved.get("name", "")).left(max_length())
	theme = str(saved.get("theme", DEFAULT_THEME))
	if get_theme_data(theme).is_empty():
		theme = DEFAULT_THEME
	spots.clear()
	var saved_spots: Dictionary = saved.get("spots", {})
	for level: String in saved_spots:
		var spot: Array = saved_spots[level]
		if spot.size() >= 2:
			spots[level] = [int(spot[0]), int(spot[1])]
	changed.emit()


## The autoload GameState without naming it: ContentDB and TournamentRanking use this class, and
## test scripts (-s) compile them before the autoloads exist (like TournamentRanking._game_state).
static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
