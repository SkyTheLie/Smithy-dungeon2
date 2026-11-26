class_name StoryHider
extends Node
## Hides other nodes of the scene for a part of the story, e.g. the merchants behind their stalls
## and the market guards while the market burns at night. Hidden from `from_flag` until
## `until_flag` (empty = for good); their collision shapes are switched off meanwhile.

@export var from_flag: String = ""
@export var until_flag: String = ""
@export var nodes: Array[NodePath] = []

## Whether the nodes are hidden by this hider right now. Nodes are only touched when this changes,
## so the hider never shows something its own script hid (e.g. a merchant after closing time).
var _hidden: bool = false


func _ready() -> void:
	GameState.story.changed.connect(_update)
	_update.call_deferred()


func _update() -> void:
	var story: Story = GameState.story
	var hidden: bool = not from_flag.is_empty() and story.has_flag(from_flag) \
			and (until_flag.is_empty() or not story.has_flag(until_flag))
	if hidden == _hidden:
		return
	_hidden = hidden
	for path in nodes:
		var node := get_node_or_null(path) as CanvasItem
		if node == null:
			continue
		node.visible = not hidden
		for shape in node.find_children("*", Language.translate("CollisionShape2D"), true, false):
			(shape as CollisionShape2D).set_deferred("disabled", hidden)
		if node is CollisionObject2D:
			for child in node.get_children():
				if child is CollisionShape2D:
					child.set_deferred("disabled", hidden)
