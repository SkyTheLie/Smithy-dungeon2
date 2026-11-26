class_name WantedPoster
extends RefCounted
## The player's own wanted poster from the dark city (Finsterstadt), a keepsake for the smithy.
## Once Nyra is the rightful princess (story step "princess_reveal") nobody hunts the player there
## any more; the poster on the square stays until the player takes it down with E (story flag
## OWNED_FLAG, set by the dialogue "finster_poster_take"). From then on it lies in the storage
## outside the house: in front of the smithy B hangs it on the wall (ForgeSignPlacer,
## HouseExteriorMenu, WantedPosterWall), like the forge sign. It stays there until the player takes
## it down again (right click in that mode, back into the storage). Its place is kept per house level.
## Lives in GameState.house.wanted_poster, saved with the house.

## Hung up, taken down or moved.
signal changed

## Story flag: the player took the poster off the wall in the dark city.
const OWNED_FLAG: String = "wanted_poster_taken"

## The poster hangs on the smithy.
var attached: bool = false
## Where it hangs per house level: "<level>" -> [x, y] (top left corner in the coordinates of the
## smithy node). Missing = the first wall area's corner.
var spots: Dictionary = {}


## The player has the poster (took it down in the dark city).
func is_owned() -> bool:
	return attached or _game_state().story.has_flag(OWNED_FLAG)


## Hangs it up. false = not the player's, or it hangs already.
func attach() -> bool:
	if attached or not is_owned():
		return false
	attached = true
	changed.emit()
	return true


## Takes it down into the storage outside (it stays the player's).
func remove() -> void:
	if not attached:
		return
	attached = false
	changed.emit()


## Place at a house level, Vector2.INF = none.
func get_spot(level: int) -> Vector2:
	var saved: Array = spots.get(str(level), [])
	return Vector2(float(saved[0]), float(saved[1])) if saved.size() >= 2 else Vector2.INF


func set_spot(level: int, top_left: Vector2) -> void:
	spots[str(level)] = [roundi(top_left.x), roundi(top_left.y)]
	changed.emit()


# --- Saving -------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"attached": attached, "spots": spots.duplicate(true)}


func load_save_data(saved: Dictionary) -> void:
	attached = bool(saved.get("attached", false))
	spots.clear()
	var saved_spots: Dictionary = saved.get("spots", {})
	for level: String in saved_spots:
		var spot: Array = saved_spots[level]
		if spot.size() >= 2:
			spots[level] = [int(spot[0]), int(spot[1])]
	changed.emit()


## The autoload GameState without naming it (like ForgeSign._game_state: test scripts compile
## this class before the autoloads exist).
static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
