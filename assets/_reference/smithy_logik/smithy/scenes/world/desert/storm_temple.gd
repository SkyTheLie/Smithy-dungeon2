extends Node2D
## The forecourt of the storm temple, the field "temple" of the desert maze (desert.json, reached
## over the storm paths with Ssarok's map). The south edge leads back onto the storm paths. The
## gate shows the seals the player put into its three sockets (StormTemple) and opens once they
## sit right; the old forge on the west side works like the smithy's stations.

const FIELD: String = "temple"
const TEXTURE_CLOSED: Texture2D = preload("res://assets/sprites/desert/storm_temple.png")
const TEXTURE_OPEN: Texture2D = preload("res://assets/sprites/desert/storm_temple_open.png")
## Top of the gate in the temple picture, from the sprite's position.
const GATE_TOP: Vector2 = Vector2(0, -100)

var _leaving: bool = false
## The gate as last drawn; it opening while the player is here plays _play_gate_open.
var _shown_open: bool = false
var _opening: bool = false

@onready var _front: Sprite2D = $Temple/Sprite2D
@onready var _sockets: Array[Sprite2D] = [$Tablet/Sprite2D/Socket0, $Tablet/Sprite2D/Socket1, $Tablet/Sprite2D/Socket2]


func _enter_tree() -> void:
	GameState.desert.arrive_at(FIELD)


func _ready() -> void:
	($Exits/ExitSouth as Area2D).body_entered.connect(_on_exit_entered)
	GameState.story.changed.connect(_update)
	_shown_open = GameState.story.has_flag(StormTemple.GATE_FLAG)
	_update()


func _update() -> void:
	var open: bool = GameState.story.has_flag(StormTemple.GATE_FLAG)
	# The seals stay in the tablet once the gate is open.
	for socket in _sockets.size():
		var seal: String = StormTemple.socket_content(socket)
		_sockets[socket].visible = not seal.is_empty()
		if not seal.is_empty():
			_sockets[socket].texture = ContentDB.item(seal).icon
	if open and not _shown_open:
		_shown_open = true
		_play_gate_open()
	elif not _opening:
		_front.texture = TEXTURE_OPEN if open else TEXTURE_CLOSED


## The gate opens while the player watches (the message of StormTemple): the three seals in the
## tablet light up one after the other, a bolt strikes the gate from the sky (flash, shake), and
## the gate slides open with a rumble.
func _play_gate_open() -> void:
	_opening = true
	var fx := WorldVfx.new()
	add_child(fx)
	for seal in _sockets:
		AudioManager.play_sound("anvil_perfect", 0.9)
		fx.spawn("light_hit", seal.global_position, Color(0.6, 0.85, 1.0))
		var glow := create_tween()
		glow.tween_property(seal, "modulate", Color(2.0, 2.2, 2.6), 0.12)
		glow.tween_property(seal, "modulate", Color(1.3, 1.5, 1.9), 0.3)
		await get_tree().create_timer(0.3, false).timeout
	await get_tree().create_timer(0.25, false).timeout
	var door: Vector2 = _front.global_position + GATE_TOP
	for strike in 3:
		fx.spawn("lightning_bolt", door, Color.WHITE, -1.0, door + Vector2(randf_range(-30, 30), -220))
		fx.spawn("lightning_hit", door, Color.WHITE)
		# One thunderclap for the quick triple strike (three would pile up).
		if strike == 0:
			AudioManager.play_sound("lightning_strike", 1.0)
		await get_tree().create_timer(0.09, false).timeout
	AudioManager.play_sound("rock_break", 0.5)
	NpcActing._flash(_front, Color(0.85, 0.92, 1.0, 0.6), 0.4)
	await NpcActing._quake(_front, 0.3, 3.0)
	# The gate slides aside: the open picture fades in under a slow rumble.
	var open_front := Sprite2D.new()
	open_front.texture = TEXTURE_OPEN
	open_front.offset = _front.offset
	open_front.modulate.a = 0.0
	_front.add_child(open_front)
	AudioManager.play_sound("stone_grind", 0.8)
	var slide := create_tween()
	slide.tween_property(open_front, "modulate:a", 1.0, 0.9)
	NpcActing._quake(_front, 0.9, 1.0)
	await slide.finished
	_front.texture = TEXTURE_OPEN
	open_front.queue_free()
	for seal in _sockets:
		var calm := create_tween()
		calm.tween_property(seal, "modulate", Color.WHITE, 0.6)
	_opening = false
	await get_tree().create_timer(2.0, false).timeout
	fx.queue_free()


func _on_exit_entered(body: Node2D) -> void:
	if _leaving or not body is Player:
		return
	_leaving = true
	GameState.desert.walk("S")
