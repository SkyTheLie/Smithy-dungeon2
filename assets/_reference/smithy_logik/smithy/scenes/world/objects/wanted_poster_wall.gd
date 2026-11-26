class_name WantedPosterWall
extends Node2D
## The player's wanted poster from the dark city on the smithy wall (GameState.house.wanted_poster,
## WantedPoster), a child of the smithy node next to the forge sign. Only there while it hangs.
## The node stands on the ground in front of the wall (so the player walks in front of it, y sort);
## the paper hangs at the place chosen for this house level (WantedPoster.get_spot, set with
## ForgeSignPlacer), without one at the corner of the first wall area. One nail at the top.
## While the player moves it, it shows as a preview (start_preview / move_preview / stop_preview),
## green where it may hang, red elsewhere; the same calls as ForgeSignWall, so the placer can carry both.

const NAIL_DARK := Color(0.12, 0.12, 0.14)
const NAIL_LIGHT := Color(0.5, 0.51, 0.56)
const COLOR_FREE := Color(0.6, 1.0, 0.6, 0.9)
const COLOR_BLOCKED := Color(1.0, 0.45, 0.45, 0.9)
const COLOR_HOVER := Color(1.0, 0.85, 0.5)
## Without a chosen place: this far inside the corner of the first wall area.
const CORNER_INSET := Vector2(4, 4)

var _previewing: bool = false

@onready var _picture: Sprite2D = $Picture


func _ready() -> void:
	GameState.house.wanted_poster.changed.connect(_update)
	GameState.house.changed.connect(_update)
	_update()


func _update() -> void:
	visible = GameState.house.wanted_poster.attached or _previewing
	if not _previewing:
		_layout()


## Size of the paper (smithy coordinates are the same size).
func get_board_size() -> Vector2:
	return _picture.texture.get_size()


## Where the paper hangs now, in the smithy's coordinates (top left corner).
func get_board_spot() -> Vector2:
	return position + _picture.position


func get_board_rect() -> Rect2:
	return Rect2(get_board_spot(), get_board_size())


## The pointer is over the hanging poster in the build mode.
func set_hovered(hovered: bool) -> void:
	if not _previewing:
		_picture.modulate = COLOR_HOVER if hovered else Color.WHITE


func start_preview() -> void:
	_previewing = true
	_update()


## The paper's top left corner at `top_left` (smithy coordinates); green = it may hang there.
func move_preview(top_left: Vector2, free: bool) -> void:
	_picture.position = top_left - position
	_picture.modulate = COLOR_FREE if free else COLOR_BLOCKED
	queue_redraw()


func stop_preview() -> void:
	_previewing = false
	_picture.modulate = Color.WHITE
	_update()


func _layout() -> void:
	var spot: Vector2 = GameState.house.wanted_poster.get_spot(GameState.house.level)
	if spot == Vector2.INF:
		var layout: Node = get_parent()
		var rects: Array = layout.get_wall_rects() if layout and layout.has_method("get_wall_rects") else []
		spot = ((rects[0] as Rect2).position + CORNER_INSET) if not rects.is_empty() else Vector2(-8, -40)
	_picture.position = spot - position
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	# One nail in the middle of the top edge.
	var x: float = roundf(_picture.position.x + get_board_size().x / 2.0) - 1.0
	var y: float = _picture.position.y + 1.0
	draw_rect(Rect2(x, y, 2.0, 2.0), NAIL_DARK)
	draw_rect(Rect2(x, y, 1.0, 1.0), NAIL_LIGHT)
