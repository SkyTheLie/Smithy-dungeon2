extends Node2D
## The valley of the pyramids, the field "pyramids" of the desert maze (desert.json). The way
## there only opens with a legendary desert compass (route "required_compass"); the compass
## points there once the player carries one. The south edge leads back into the maze.
## NpcSpot marks where the valley's figure will stand (not built yet).

const FIELD: String = "pyramids"

var _leaving: bool = false


func _enter_tree() -> void:
	GameState.desert.arrive_at(FIELD)


func _ready() -> void:
	($Exits/ExitSouth as Area2D).body_entered.connect(_on_exit_entered)
	GameState.story.set_flag("pyramid_valley_found")


func _on_exit_entered(body: Node2D) -> void:
	if _leaving or not body is Player:
		return
	_leaving = true
	GameState.desert.walk("S")
