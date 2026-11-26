class_name ForgeSignWall
extends Station
## The forge sign outside on the smithy (GameState.house.forge_sign, ForgeSign), a child of the
## smithy node. Only there while the sign hangs.
## Where it hangs: at the place the player chose for this house level (ForgeSign.get_spot, set with
## ForgeSignPlacer), flat on the wall from two nails on short chains; without such a place it
## sticks out from a corner like an inn sign (iron plate, an arm as long as the board).
## The board is a ForgeSignBoard with the name in the chosen theme. The node stands on the ground
## at the corner; the arm sits `hang_height` px above it and points to `side`. The smithy sets
## both per house level (smithy_house_layout.gd "sign_positions", "sign_sides").
## E below the board opens the name window. While the player moves the sign, it shows as a
## preview (start_preview / move_preview / stop_preview), green where it may hang, red elsewhere.

const SIGN_MENU: PackedScene = preload("res://scenes/ui/menus/forge_sign_menu.tscn")
## Wall plate (width, height) and how far the board stays from the wall.
const PLATE := Vector2(3, 8)
const WALL_GAP: float = 3.0
## Arm beyond the board, chains (length, inset from the board's edges).
const ARM_OVERHANG: float = 2.0
const CHAIN_LENGTH: float = 3.0
const CHAIN_INSET: float = 3.0
const IRON_DARK := Color(0.12, 0.12, 0.14)
const IRON := Color(0.3, 0.31, 0.35)
const IRON_LIGHT := Color(0.5, 0.51, 0.56)
const COLOR_FREE := Color(0.6, 1.0, 0.6, 0.9)
const COLOR_BLOCKED := Color(1.0, 0.45, 0.45, 0.9)
const COLOR_HOVER := Color(1.0, 0.85, 0.5)
## E reaches the sign from the ground below the board (height of that area).
const REACH_HEIGHT: float = 30.0

## Height of the arm above the node (the ground at the corner).
@export var hang_height: float = 40.0:
	set(value):
		hang_height = value
		if is_node_ready():
			_layout()
## Where the arm points: -1 = left, 1 = right.
@export_enum("left:-1", "right:1") var side: int = -1:
	set(value):
		side = -1 if value < 0 else 1
		if is_node_ready():
			_layout()

var _menu: ForgeSignMenu
## The board hangs flat on the wall at a chosen place (else: from the corner arm).
var _mounted: bool = false
## Moving the sign: the board follows the pointer.
var _previewing: bool = false

@onready var _board: ForgeSignBoard = $Board
@onready var _reach: CollisionShape2D = $InteractionArea/CollisionShape2D


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	interacted.connect(open_menu.bind(false))
	player_left.connect(_close_menu)
	GameState.house.forge_sign.changed.connect(_update)
	_update()


func _update() -> void:
	var forge_sign: ForgeSign = GameState.house.forge_sign
	visible = forge_sign.attached or _previewing
	if not forge_sign.attached:
		_close_menu()
	_board.show_sign(forge_sign.get_display_name(), forge_sign.theme)
	if not _previewing:
		_layout()


## Size of the board with the current name (smithy coordinates are the same size).
func get_board_size() -> Vector2:
	return _board.size


## Where the board hangs now, in the smithy's coordinates (top left corner).
func get_board_spot() -> Vector2:
	return position + _board.position


## Where the board is, in the smithy's coordinates (a click there in the build mode lifts it).
func get_board_rect() -> Rect2:
	return Rect2(get_board_spot(), _board.size)


## The pointer is over the hanging sign in the build mode (lighter, like things in the house).
func set_hovered(hovered: bool) -> void:
	if not _previewing:
		_board.modulate = COLOR_HOVER if hovered else Color.WHITE


## Moving the sign starts: it shows even if it doesn't hang yet.
func start_preview() -> void:
	_previewing = true
	_update()


## The board's top left corner at `top_left` (smithy coordinates); green = it may hang there.
func move_preview(top_left: Vector2, free: bool) -> void:
	_mounted = true
	_board.position = top_left - position
	_board.modulate = COLOR_FREE if free else COLOR_BLOCKED
	queue_redraw()


func stop_preview() -> void:
	_previewing = false
	_board.modulate = Color.WHITE
	_update()


## Board at the chosen place of this house level, else under the corner arm; E reaches it from below.
func _layout() -> void:
	var spot: Vector2 = GameState.house.forge_sign.get_spot(GameState.house.level)
	_mounted = spot != Vector2.INF
	var width: float = _board.size.x
	if _mounted:
		_board.position = spot - position
	else:
		var near: float = WALL_GAP if side > 0 else -WALL_GAP - width
		_board.position = Vector2(roundf(near), -hang_height + 2.0 + CHAIN_LENGTH)
	var reach := RectangleShape2D.new()
	reach.size = Vector2(width + 8.0, REACH_HEIGHT)
	_reach.shape = reach
	_reach.position = Vector2(_board.position.x + width / 2.0, 4.0)
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var board_left: float = _board.position.x
	var board_right: float = board_left + _board.size.x
	var chain_xs: Array[float] = [board_left + CHAIN_INSET, board_right - CHAIN_INSET - 1.0]
	var y: float
	if _mounted:
		# Two nails in the wall above the board.
		y = _board.position.y - CHAIN_LENGTH - 2.0
		for x: float in chain_xs:
			draw_rect(Rect2(roundf(x) - 1.0, y, 3.0, 2.0), IRON_DARK)
			draw_rect(Rect2(roundf(x), y, 1.0, 1.0), IRON_LIGHT)
	else:
		y = -hang_height
		# Arm from the wall to just beyond the board: light top, dark bottom.
		var arm_to: float = (board_right + ARM_OVERHANG) if side > 0 else (board_left - ARM_OVERHANG)
		draw_rect(Rect2(minf(0.0, arm_to), y, absf(arm_to), 1.0), IRON_LIGHT)
		draw_rect(Rect2(minf(0.0, arm_to), y + 1.0, absf(arm_to), 1.0), IRON_DARK)
		# Little curl under the arm near the wall.
		draw_rect(Rect2(side * 2.0 - (1.0 if side < 0 else 0.0), y + 2.0, 1.0, 2.0), IRON)
		draw_rect(Rect2(side * 3.0 - (1.0 if side < 0 else 0.0), y + 3.0, 2.0 * side, 1.0).abs(), IRON)
		# Wall plate.
		var plate := Rect2(-PLATE.x if side > 0 else 0.0, y - 3.0, PLATE.x, PLATE.y)
		draw_rect(plate, IRON)
		draw_rect(plate, IRON_DARK, false, 1.0)
	# Chains: dots down to the board.
	for x: float in chain_xs:
		for i in int(CHAIN_LENGTH) + 1:
			draw_rect(Rect2(roundf(x), y + 2.0 + i, 1.0, 1.0), IRON if i % 2 == 0 else IRON_DARK)


## Opens the name window (E at the sign, or right after hanging it up: `focus_name` puts the
## cursor into the name field).
func open_menu(focus_name: bool = false) -> void:
	if _menu == null:
		_menu = SIGN_MENU.instantiate()
		add_child(_menu)
	_menu.open(focus_name)


func _close_menu() -> void:
	if _menu and _menu.visible:
		_menu.close()
