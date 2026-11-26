class_name Disguise
extends RefCounted
## The hooded cloak Nyra gives the player in the hideout (story flag FLAG, part 7). With it the wanted
## smith is just one more cloak in the Finsterstadt: on the maps in SCENES the player's walk sheet is
## the cloak figure (SHEET, the hood hides hair, horns and face, so it fits every look). It comes
## off once the city has risen (OFF_FLAG). Mining, chopping and raised arms keep the own look.

const FLAG: String = "finster_cloak"
const OFF_FLAG: String = "uprising_seen"
const SHEET: String = "res://assets/sprites/residents/player_cloak.png"
## Scene file names (without .tscn) where the cloak is worn.
const SCENES: Array[String] = ["finster_city", "finster_gate", "finster_guardhouse", "finster_hideout",
		"castle_wall", "castle_walk", "castle_cells"]


## true if the player wears the cloak in the scene `scene_path` right now.
static func is_worn(scene_path: String) -> bool:
	var story = GameState.story
	return story.has_flag(FLAG) and not story.has_flag(OFF_FLAG) \
			and SCENES.has(scene_path.get_file().get_basename())


## The cloak sheet (player layout, 7 x 4 frames of 48 px), null if it is missing.
static func get_sheet() -> Texture2D:
	return load(SHEET) as Texture2D if ResourceLoader.exists(SHEET) else null
