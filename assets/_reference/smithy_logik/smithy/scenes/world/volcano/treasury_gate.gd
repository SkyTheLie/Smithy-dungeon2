class_name TreasuryGate
extends Station
## The gate of the treasure chamber in the great hall of the goblin castle (see GoblinKey). Dark at
## first; when the player touches it, three runes bloom on it (the smith's magic wakes them,
## GoblinKey.RUNES_SEEN_FLAG) and the player wonders about it (dialogue `runes_dialogue`). E then
## tries the key: the right one opens the gate (closed picture and its body go, the open picture
## comes), a wrong one breaks.

## Pictures of the closed and the open gate; `body`: blocks the opening while it is closed.
@export var closed_sprite: Sprite2D
@export var open_sprite: Sprite2D
@export var body: CollisionShape2D
## The three runes on the gate (sheet goblin_runes.png, one per disc) and their glow.
@export var runes: Array[Sprite2D] = []
@export var rune_lights: Array[PointLight2D] = []
## Dialogue (story.json) after the runes bloomed.
@export var runes_dialogue: String = "treasury_runes"

## Seconds between the runes and how long each takes to bloom.
const BLOOM_DELAY: float = 0.5
const BLOOM_TIME: float = 0.9

var _blooming: bool = false
var _rune_energy: Dictionary = {}

@onready var _dialogue: DialogueBox = $DialogueBox


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)
	for i in runes.size():
		runes[i].frame = i * GoblinKey.RUNES + GoblinKey.SOLUTION[i]
	for light in rune_lights:
		_rune_energy[light] = light.energy
	var seen: bool = GameState.story.has_flag(GoblinKey.RUNES_SEEN_FLAG)
	_show_runes(seen)
	_show_open(GameState.story.has_flag(GoblinKey.GATE_FLAG))


func wants_interact() -> bool:
	return super() and not _blooming and not _dialogue.visible \
			and not GameState.story.has_flag(GoblinKey.GATE_FLAG)


## Touching the gate is enough for the runes.
func _on_interaction_area_body_entered(body_entered: Node2D) -> void:
	super(body_entered)
	if body_entered is Player and not GameState.story.has_flag(GoblinKey.RUNES_SEEN_FLAG) and not _blooming:
		_bloom()


func _on_interacted() -> void:
	if _dialogue.visible:
		_dialogue.advance()
		return
	if not GameState.story.has_flag(GoblinKey.RUNES_SEEN_FLAG):
		_bloom()
		return
	if GoblinKey.try_gate():
		_show_open(true)


func _show_runes(shown: bool) -> void:
	for sprite in runes:
		sprite.visible = shown
		sprite.modulate.a = 1.0
		sprite.scale = Vector2.ONE
	for light in rune_lights:
		light.enabled = shown
		light.energy = _rune_energy[light]


func _show_open(open: bool) -> void:
	if closed_sprite:
		closed_sprite.visible = not open
	if open_sprite:
		open_sprite.visible = open
	if body:
		body.set_deferred("disabled", open)
	for sprite in runes:
		sprite.visible = sprite.visible and not open
	for light in rune_lights:
		light.enabled = light.enabled and not open


## One rune after the other glows up out of the dark, then the player wonders.
func _bloom() -> void:
	_blooming = true
	AudioManager.play_sound("rarity_up", 0.7)
	for i in runes.size():
		var sprite: Sprite2D = runes[i]
		sprite.visible = true
		sprite.modulate.a = 0.0
		sprite.scale = Vector2(2.0, 2.0)
		var tween := create_tween().set_parallel()
		tween.tween_property(sprite, "modulate:a", 1.0, BLOOM_TIME).set_delay(i * BLOOM_DELAY)
		tween.tween_property(sprite, "scale", Vector2.ONE, BLOOM_TIME).set_delay(i * BLOOM_DELAY) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if i < rune_lights.size():
			var light: PointLight2D = rune_lights[i]
			light.enabled = true
			light.energy = 0.0
			tween.tween_property(light, "energy", _rune_energy[light], BLOOM_TIME).set_delay(i * BLOOM_DELAY)
	await get_tree().create_timer(runes.size() * BLOOM_DELAY + BLOOM_TIME, false).timeout
	GameState.story.set_flag(GoblinKey.RUNES_SEEN_FLAG)
	_blooming = false
	_dialogue.play(GameState.story.get_dialogue(runes_dialogue))
