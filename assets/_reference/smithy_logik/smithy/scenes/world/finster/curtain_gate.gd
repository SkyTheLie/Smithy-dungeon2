class_name CurtainGate
extends Sprite2D
## The dyed cloth curtain at the mouth of the alley in the Finsterstadt (sheet with `hframes` frames,
## frame 0 = hanging still). Whenever the player walks through the opening, the cloth swings aside
## once and settles again. The player running through it in the chase (FinsterChase) swings it the same way.

const SWING_SECONDS: float = 0.9
## The opening between the posts, relative to the sprite's position (its foot).
const OPENING: Rect2 = Rect2(-18, -16, 36, 22)

## Further figures (e.g. Nyra leaving the yard) that swing the curtain too.
@export var others: Array[NodePath] = []

var _inside: bool = false
var _others: Array[Node2D] = []
var _others_inside: Array[bool] = []
var _tween: Tween
var _player: Node2D


func _ready() -> void:
	_find_player.call_deferred()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	for path in others:
		var figure := get_node_or_null(path) as Node2D
		if figure:
			_others.append(figure)
			_others_inside.append(false)


func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		var inside: bool = OPENING.has_point(_player.global_position - global_position)
		if inside and not _inside:
			swing()
		_inside = inside
	for i in _others.size():
		var figure := _others[i]
		if not is_instance_valid(figure) or not figure.visible:
			continue
		var inside_other: bool = OPENING.has_point(figure.global_position - global_position)
		if inside_other and not _others_inside[i]:
			swing()
		_others_inside[i] = inside_other


func swing() -> void:
	if _tween and _tween.is_running():
		return
	frame = 0
	_tween = create_tween()
	_tween.tween_property(self, "frame", hframes - 1, SWING_SECONDS)
