extends Node2D
## The mine. At first only the small front part is free (mine_small). Once Gustav has braced the
## tunnels (story flag "mine_expanded", end of chapter 5) the bigger layout is used: other
## background and walls, the lights of the new passages and more rocks per day. Iron only grows
## here once the old mine below is open (part 2, mine_iron_rock.tres).
## Switched in _enter_tree, before CaveWalls and RockSpawner build themselves in _ready.

const EXPANDED_FLAG: String = "mine_expanded"

@export var expanded_background: Texture2D
@export var expanded_mask: Texture2D
## Rocks per day and chances (same order as the spawner's rock_types: coal, copper, iron).
@export var expanded_rock_count: int = 8
@export var expanded_weights: Array[float] = [35.0, 35.0, 30.0]


func _enter_tree() -> void:
	if not GameState.story.has_flag(EXPANDED_FLAG):
		return
	($Background as Sprite2D).texture = expanded_background
	($CaveWalls as CaveWalls).mask = expanded_mask
	var spawner := $RockSpawner as RockSpawner
	spawner.rock_count = expanded_rock_count
	spawner.weights = expanded_weights
	# Own resources of the day: the small mine's rock positions don't fit the new walls.
	spawner.area_id = "mine_medium"
	($ExpandedLights as Node2D).show()
