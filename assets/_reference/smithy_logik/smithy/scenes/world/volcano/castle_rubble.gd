class_name CastleRubble
extends Station
## The pile of boulders in front of the gate of the goblin castle. Only a pickaxe with at least
## `min_pickaxe_damage` (6 = bronze head) gets through: E, the screen goes black for a moment and
## the boulders are gone (`flag`). With a weaker pickaxe there is only a message.

## Story flag set once the boulders are gone; with it set they are gone when the scene loads.
@export var flag: String = "goblin_castle_gate_cleared"
## Mining damage the pickaxe itself needs (PlayerStats.get_pickaxe_damage, bronze head = 6).
@export var min_pickaxe_damage: int = 6
@export var too_weak_text: String = "Die Brocken sind steinhart. Deine Spitzhacke prallt ab. Dafür brauchst du mindestens eine Bronzespitzhacke."
@export var cleared_text: String = "Du schlägst die Felsbrocken in Stücke und räumst sie zur Seite. Das Tor ist frei."

## Experience like breaking this many ordinary rocks.
const EXPERIENCE_ROCKS: int = 15

## true while the screen is black (E does nothing meanwhile).
var _clearing: bool = false


func _ready() -> void:
	if GameState.story.has_flag(flag):
		queue_free()
		return
	super()
	interacted.connect(_on_interacted)


func wants_interact() -> bool:
	return super() and not _clearing


func _on_interacted() -> void:
	if GameState.player_stats.get_pickaxe_damage() < min_pickaxe_damage:
		AudioManager.play_sound("pickaxe_hit", 1.3)
		GameState.show_message(Language.translate(too_weak_text))
		return
	_clearing = true
	AudioManager.play_sound("pickaxe_hit")
	GameState.run_story_action("cutscene:fade")
	# while the screen is black
	await get_tree().create_timer(GameState.FADE_SECONDS, false).timeout
	AudioManager.play_sound("rock_break", 0.8)
	GameState.player_stats.add_experience(GameState.player_stats.experience_per_rock * EXPERIENCE_ROCKS)
	GameState.story.set_flag(flag)
	GameState.show_message(Language.translate(cleared_text))
	queue_free()
