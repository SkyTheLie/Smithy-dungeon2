class_name GoblinForgeView
extends Node2D
## How the old goblin forge looks, from the flags of GoblinKey. Cold at first: only the lava behind
## the windows gives light. Once the chain lever is pulled (GoblinKey.LAVA_FLAG) the stone gate in
## the wall rises, lava pours into the forge and runs out through the trench, the forge glows and
## the runes on the discs light up. While the player watches this happens slowly, after loading it
## is simply so.

## The stone gate in the wall behind the forge and how far it rises (pixels).
@export var stone_gate: Node2D
@export var gate_rise: float = 56.0
## Shown once the lava flows (lava in the slit and the trench, the glowing forge).
@export var lit_items: Array[CanvasItem] = []
## Shown while the forge is cold (the dark forge).
@export var cold_items: Array[CanvasItem] = []
## Lights that only shine once the lava flows (their energy in the scene is the full strength).
@export var lights: Array[PointLight2D] = []
## The rune of each disc (sheet with 4 runes per row, one row per disc).
@export var runes: Array[Sprite2D] = []
## The mold stand under the spout (frames: empty, mold, mold with a key) and its glow.
@export var mold: Sprite2D
@export var mold_light: PointLight2D

const RISE_TIME: float = 2.5
const FLOW_TIME: float = 2.0
const SHAKE: float = 1.5
## Runes while the forge is cold: dark and barely to see.
const COLOR_RUNE_COLD: Color = Color(0.25, 0.22, 0.28, 0.6)

var _lit: bool = false
## Whether it glows already (after the stone gate rose).
var _glowing: bool = false
var _full_energy: Dictionary = {}


func _ready() -> void:
	for light in lights:
		_full_energy[light] = light.energy
	_lit = GameState.story.has_flag(GoblinKey.LAVA_FLAG)
	_glowing = _lit
	if _lit and stone_gate:
		stone_gate.position.y -= gate_rise
	_set_lit(_lit)
	for sprite in runes:
		sprite.modulate = Color.WHITE if _glowing else COLOR_RUNE_COLD
	_update_runes()
	_update_mold()
	GameState.story.changed.connect(_on_story_changed)


func _on_story_changed() -> void:
	var lit: bool = GameState.story.has_flag(GoblinKey.LAVA_FLAG)
	if lit and not _lit:
		_lit = true
		_light_up()
	_update_runes()
	_update_mold()


func _set_lit(lit: bool) -> void:
	for item in lit_items:
		item.visible = lit
		item.modulate.a = 1.0
	for item in cold_items:
		item.visible = not lit
	for light in lights:
		light.energy = _full_energy[light] if lit else 0.0
		light.enabled = lit


## The stone gate grinds up, then the lava comes in and everything starts to glow.
func _light_up() -> void:
	AudioManager.play_sound("rock_break", 0.5)
	if stone_gate:
		var home: Vector2 = stone_gate.position
		var tween := create_tween()
		tween.tween_method(func(t: float) -> void:
			stone_gate.position = home + Vector2(randf_range(-SHAKE, SHAKE), -gate_rise * t).round(), 0.0, 1.0, RISE_TIME)
		await tween.finished
		stone_gate.position = home + Vector2(0, -gate_rise)
	_glowing = true
	AudioManager.play_sound("cast_pour", 0.6)
	for item in lit_items:
		item.visible = true
		item.modulate.a = 0.0
		create_tween().tween_property(item, "modulate:a", 1.0, FLOW_TIME)
	for item in cold_items:
		create_tween().tween_property(item, "modulate:a", 0.0, FLOW_TIME).finished.connect(item.hide)
	for light in lights:
		light.enabled = true
		create_tween().tween_property(light, "energy", _full_energy[light], FLOW_TIME)
	_update_runes()


func _update_runes() -> void:
	for disc in runes.size():
		var sprite: Sprite2D = runes[disc]
		sprite.frame = disc * GoblinKey.RUNES + GoblinKey.disc_rune(disc)
		var color: Color = Color.WHITE if _glowing else COLOR_RUNE_COLD
		if sprite.modulate != color:
			create_tween().tween_property(sprite, "modulate", color, FLOW_TIME)


func _update_mold() -> void:
	if mold == null:
		return
	var story: Story = GameState.story
	var frame: int = 0
	if story.has_flag(GoblinKey.IN_MOLD_FLAG):
		frame = 2
	elif story.has_flag(GoblinKey.MOLD_FLAG):
		frame = 1
	mold.frame = frame
	if mold_light:
		mold_light.enabled = frame == 2
