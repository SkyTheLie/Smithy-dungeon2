class_name GoblinKeySwitch
extends Station
## One of the things in the old goblin forge the player uses with E (see GoblinKey):
## - CHAIN_LEVER: pulls the chain, the stone gate in the wall rises and lets the lava in (once).
## - DISC_LEVER: turns rune disc `disc` one rune further.
## - FORGE: melts copper and iron ore into bronze and pours a key into the mold.
## - MOLD: puts the key mold under the spout, or takes the cast key out.
## - TROUGH: cools the hot key.
## The forge's look follows the flags (GoblinForgeView). `lever` (optional): sprite with two
## frames (up / pulled) that moves when used.

enum Action { CHAIN_LEVER, DISC_LEVER, FORGE, MOLD, TROUGH }

@export var action: Action = Action.FORGE
## Disc 0-2 (with DISC_LEVER).
@export_range(0, 2) var disc: int = 0
@export var lever: Sprite2D

const TEXT_LAVA_ON: String = "Der Hebel ist unten. Die Lava fließt."
## Seconds a disc lever stays tilted.
const LEVER_BACK_TIME: float = 0.3


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)
	if action == Action.CHAIN_LEVER and lever and GameState.story.has_flag(GoblinKey.LAVA_FLAG):
		lever.frame = 1


func _on_interacted() -> void:
	match action:
		Action.CHAIN_LEVER:
			_pull_chain()
		Action.DISC_LEVER:
			if GoblinKey.turn_disc(disc):
				AudioManager.play_sound("ui_click", 0.6)
				_tilt_lever()
		Action.FORGE:
			GoblinKey.pour_key()
		Action.MOLD:
			GoblinKey.use_mold()
		Action.TROUGH:
			GoblinKey.cool_key()


func _pull_chain() -> void:
	if GameState.story.has_flag(GoblinKey.LAVA_FLAG):
		GameState.show_message(Language.translate(TEXT_LAVA_ON))
		return
	if lever:
		lever.frame = 1
	AudioManager.play_sound("ui_click", 0.5)
	GameState.story.set_flag(GoblinKey.LAVA_FLAG)


func _tilt_lever() -> void:
	if lever == null:
		return
	lever.frame = lever.frame - lever.frame % 2 + 1
	await get_tree().create_timer(LEVER_BACK_TIME, false).timeout
	if is_instance_valid(lever):
		lever.frame = lever.frame - lever.frame % 2
