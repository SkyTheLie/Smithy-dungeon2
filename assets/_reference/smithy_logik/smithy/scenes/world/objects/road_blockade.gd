class_name RoadBlockade
extends Node2D
## Blocks a road (fallen tree, rockfall, buried mine ...) until a story flag is set; from then
## on it is gone. The children carry the graphics and the collision.
## With `appears_when_open` it works the other way round: the node only exists once the flag is
## set (e.g. the cleared mine entrance that replaces the buried one).

## Story flag that clears the road. Empty = the road stays blocked.
@export var open_flag: String = ""
## true = this node is the "after" state: removed while the flag is NOT set.
@export var appears_when_open: bool = false


func _ready() -> void:
	var is_open: bool = not open_flag.is_empty() and GameState.story.has_flag(open_flag)
	if is_open != appears_when_open:
		queue_free()
