extends Node2D
## In front of Sahrim, the glass dome of the lizardfolk. This screen is the field "town" of the
## desert maze (DesertMaze, desert.json "town"): the south and the east exit lead back into the
## dunes, the gate (a Door) leads into the city (desert_town.tscn). The first visit sets
## "desert_town_found" (side tasks, Ishra's welcome, Zahir's map) and shows a short text.

## Exit area -> direction in the maze.
const EXITS: Dictionary = {"ExitSouth": "S", "ExitEast": "O"}
const FOUND_FLAG: String = "desert_town_found"

var _leaving: bool = false


func _enter_tree() -> void:
	GameState.desert.arrive_at(str(DesertMaze.data().get("town", "town")))


func _ready() -> void:
	for exit_name: String in EXITS:
		(get_node("Exits/" + exit_name) as Area2D).body_entered.connect(_on_exit_entered.bind(EXITS[exit_name]))
	if not GameState.story.has_flag(FOUND_FLAG):
		GameState.story.set_flag(FOUND_FLAG)
		GameState.show_message(str(DesertMaze.data().get("arrive_text", "")))


func _on_exit_entered(body: Node2D, direction: String) -> void:
	if _leaving or not body is Player:
		return
	_leaving = true
	GameState.desert.walk(direction)
