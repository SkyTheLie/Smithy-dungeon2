class_name Teleporter
extends Station
## A teleport crystal. Every one stands on its own spot from the start (`spot_id`, e.g. "home" in
## front of the smithy, "leonheim" in the shopping street), but it sleeps: E only says that
## nothing happens. Once the player has the portal crystal of Aurelius (story flag
## `portal_crystal_owned`, chapter 14) and the spot is open (`open_flag`), E wakes it up (flag
## "teleporter_<spot_id>_built") and from then on opens the TeleportMenu. The menu lists every
## destination whose teleporter is awake (GameState.is_teleporter_built).

## Story flag that gives the player the portal crystal (needed to wake teleporters).
const CRYSTAL_FLAG: String = "portal_crystal_owned"
## A sleeping crystal is a bit darker.
const SLEEP_COLOR: Color = Color(0.6, 0.62, 0.7)
const TEXT_ASLEEP: String = "Ein alter Teleport-Kristall. Er ist kalt und rührt sich nicht."
const TEXT_NOT_YET: String = "Der Portalkristall summt, aber dieser Teleporter wacht noch nicht auf."

## Id of this spot, the same as its TravelDestination id (data/destinations/<id>.tres).
@export var spot_id: String = "home"
## Story flag from which this spot can be woken up (empty = as soon as the player has the
## crystal; e.g. the mine and the forest come later in the story).
@export var open_flag: String = ""

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if GameState.is_teleporter_built(spot_id):
		return
	# Asleep: E is handled here, the menu stays shut until it is woken up.
	blocked = true
	_sprite.modulate = SLEEP_COLOR
	_sprite.speed_scale = 0.3


## A sleeping crystal takes E too (it says why nothing happens or wakes up).
func wants_interact() -> bool:
	return _player_in_range and visible


func _unhandled_input(event: InputEvent) -> void:
	if blocked and _player_in_range and event.is_action_pressed("interact") and is_nearest_interactable(self):
		get_viewport().set_input_as_handled()
		if not GameState.story.has_flag(CRYSTAL_FLAG):
			GameState.show_message(Language.translate(TEXT_ASLEEP))
		elif not GameState.story.has_flag(open_flag):
			GameState.show_message(Language.translate(TEXT_NOT_YET))
		else:
			_wake_up()
		return
	super(event)


## The portal crystal flashes, the teleporter wakes up and its menu opens.
func _wake_up() -> void:
	GameState.build_teleporter(spot_id)
	blocked = false
	_sprite.speed_scale = 1.0
	_sprite.modulate = Color(2.0, 2.0, 2.4)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.8)
	GameState.show_message(Language.translate("Der Portalkristall leuchtet auf: Der Teleporter ist erwacht!"))
	interacted.emit()
