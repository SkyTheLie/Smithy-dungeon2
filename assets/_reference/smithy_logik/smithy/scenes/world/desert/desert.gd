extends Node2D
## One screen of the desert maze (DesertMaze, data/content/desert.json). Every field of the maze is
## this scene, the dunes always look the same; only the mark of the field differs (the warning
## sign at the start, the skeleton, the ruins, a chest). Walking out of the screen on a side walks
## that way in the maze (Exits/*): the next field, out of the desert, or lost.

## Exit area -> direction in the maze.
const EXITS: Dictionary = {"ExitNorth": "N", "ExitEast": "O", "ExitSouth": "S", "ExitWest": "W"}
## DesertMaze mark -> node under Marks that shows it.
const MARKS: Dictionary = {"sign": "Sign", "bones": "Bones", "ruins": "Ruins", "chest": "Chest"}

var _leaving: bool = false


func _enter_tree() -> void:
	# Coming in from the south road (or no valid field, e.g. an old save): start at the sign.
	var maze: DesertMaze = GameState.desert
	if GameState.next_spawn_point == DesertMaze.ENTRY_SPAWN or not DesertMaze.graph().has(maze.current) \
			or DesertMaze.scene_of(maze.current) != DesertMaze.DESERT_SCENE:
		maze.enter()


func _ready() -> void:
	var mark: String = GameState.desert.get_mark()
	for key: String in MARKS:
		if key != mark:
			get_node("Marks/" + MARKS[key]).queue_free()
	if mark == "chest":
		($Marks/Chest as DesertChest).setup(GameState.desert.get_chest())
	for exit_name: String in EXITS:
		(get_node("Exits/" + exit_name) as Area2D).body_entered.connect(_on_exit_entered.bind(EXITS[exit_name]))


func _on_exit_entered(body: Node2D, direction: String) -> void:
	if _leaving or not body is Player:
		return
	_leaving = true
	GameState.desert.walk(direction)
