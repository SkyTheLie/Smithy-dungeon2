extends CanvasItem
## Hides this node once the story flag `flag` is set (e.g. a sign to a place that no longer exists).

@export var flag: String = ""


func _ready() -> void:
	visible = not GameState.story.has_flag(flag)
