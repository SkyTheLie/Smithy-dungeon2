extends Node
## Lays out the guild hall for the guild level (GuildLevel, 0-3): the hall grows with every level,
## from a small room with one table to the big hall with four. Per level: the room picture (baked by
## assets/_reference/guild_hall/bake_guild_hall.gd), the walls, the red runner and where each piece
## of furniture stands or whether it is there at all. The front door stays at the bottom middle.
## Must be the first child of the scene: it has to be done before GuildPatrons seats the heroes
## (they only sit at visible tables).

## Room picture per level (all as wide as the room, bottom edge = `floor_bottom`).
@export var backgrounds: Array[Texture2D] = []
## Lower edge of every room picture (the front door is there).
@export var floor_bottom: float = 172.0
## Height of the outline above the floor plus the back wall (bake: SIDE + WALL_H).
@export var wall_height: float = 72.0
## Length of the red runner from the door per level (0 = no runner).
@export var runner_lengths: Array[int] = []
## Node path (from the scene root) » positions per level; null = not there on that level.
@export var positions: Dictionary = {}

@onready var _root: Node2D = get_parent() as Node2D


func _ready() -> void:
	apply(GuildLevel.get_level(GameState.story))


## Puts the hall into the shape of guild level `level`.
func apply(level: int) -> void:
	level = clampi(level, 0, backgrounds.size() - 1)
	var texture: Texture2D = backgrounds[level]
	var size: Vector2 = texture.get_size()
	var background := _root.get_node("Background") as Sprite2D
	background.texture = texture
	background.position = Vector2(-size.x / 2.0, floor_bottom - size.y)
	var floor_top: float = floor_bottom - size.y + wall_height
	(_root.get_node("Walls/Top") as Node2D).position.y = floor_top - 24.0
	(_root.get_node("Walls/Left") as Node2D).position.x = -size.x / 2.0
	(_root.get_node("Walls/Right") as Node2D).position.x = size.x / 2.0
	_lay_runner(runner_lengths[level] if level < runner_lengths.size() else 0)
	for path: Variant in positions:
		var node := _root.get_node_or_null(NodePath(str(path))) as Node2D
		var places: Array = positions[path]
		if node == null or level >= places.size():
			continue
		var place: Variant = places[level]
		_set_present(node, place != null)
		if place != null:
			node.position = place


## The runner starts at the door and is `length` long (cut from its top end).
func _lay_runner(length: int) -> void:
	var runner := _root.get_node("Runner") as Sprite2D
	_set_present(runner, length > 0)
	if length <= 0:
		return
	var full: Vector2 = runner.texture.get_size()
	length = mini(length, int(full.y))
	runner.region_enabled = true
	runner.region_rect = Rect2(0, full.y - length, full.x, length)
	runner.position = Vector2(0, floor_bottom - 8.0 - length / 2.0)


## Shown and solid, or hidden and without collision (and without E).
func _set_present(node: Node, present: bool) -> void:
	(node as CanvasItem).visible = present
	node.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED
