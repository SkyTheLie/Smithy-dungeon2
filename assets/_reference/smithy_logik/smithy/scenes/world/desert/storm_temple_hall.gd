extends Node2D
## The hall of the storm temple: four pillars of different heights (StormTemple). Each one the
## player strikes in the right order glows; once all four sounded from the highest to the lowest,
## the stone slab in the north grinds aside (right of the doorway) and frees the way to the
## sanctum. If the puzzle was solved earlier, the slab already stands beside the doorway.

const LIT: Color = Color(1.35, 1.3, 0.85)
## Where the slab stands once it is pushed aside (right of the doorway, x of the node).
const SLAB_ASIDE_X: float = 58.0
## Seconds the slab takes to slide aside.
const SLIDE_TIME: float = 2.4
## Sand-coloured dust at the slab's foot while it grinds over the floor.
const DUST: Color = Color(0.95, 0.8, 0.55)

## The slab as last placed; it moving while the player is here plays _play_slab_slide.
var _shown_open: bool = false

@onready var _pillars: Array[Node2D] = [$Pillars/Pillar1, $Pillars/Pillar2, $Pillars/Pillar3, $Pillars/Pillar4]
@onready var _slab: Node2D = $Slab/Stone


func _ready() -> void:
	GameState.story.changed.connect(_update)
	_shown_open = GameState.story.has_flag(StormTemple.PILLARS_FLAG)
	if _shown_open:
		_slab.position.x = SLAB_ASIDE_X


func _process(_delta: float) -> void:
	for i in _pillars.size():
		_pillars[i].modulate = LIT if StormTemple.is_lit(i + 1) else Color.WHITE


func _update() -> void:
	if not _shown_open and GameState.story.has_flag(StormTemple.PILLARS_FLAG):
		_shown_open = true
		_play_slab_slide()


## The last tone rumbles through the hall: the slab shudders, then grinds slowly to the right of
## the doorway with dust at its foot and a shaking camera.
func _play_slab_slide() -> void:
	var fx := WorldVfx.new()
	add_child(fx)
	var sprite := _slab.get_node("Sprite2D") as Sprite2D
	AudioManager.play_sound("rock_break", 0.6)
	await NpcActing._quake(_slab, 0.5, 2.0)
	var slide := create_tween()
	slide.tween_property(_slab, "position:x", SLAB_ASIDE_X, SLIDE_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	NpcActing._quake(_slab, SLIDE_TIME, 1.0)
	AudioManager.play_sound("stone_grind", 0.85)
	var time: float = 0.0
	var next_dust: float = 0.0
	while slide.is_running():
		var delta: float = get_process_delta_time()
		time += delta
		# The stone judders a little while it moves.
		sprite.position = Vector2(randf_range(-0.6, 0.6), randf_range(-0.4, 0.4)).round()
		if time >= next_dust:
			next_dust = time + 0.18
			var foot: Vector2 = _slab.global_position + Vector2(randf_range(-30, 30), randf_range(-3, 2))
			fx.spawn("earth_hit", foot, DUST)
		await get_tree().process_frame
	sprite.position = Vector2.ZERO
	AudioManager.play_sound("rock_break", 0.5)
	for i in 3:
		fx.spawn("earth_hit", _slab.global_position + Vector2(-26 + i * 6, -2), DUST)
	NpcActing._quake(_slab, 0.25, 2.0)
	await get_tree().create_timer(2.0, false).timeout
	fx.queue_free()
