class_name FinsterScaffold
extends Sprite2D
## The dyers' scaffold at the end of the alley in the Finsterstadt (part 7). After the player was pulled
## behind the curtain two guards stand next to it. Story action "cutscene:scaffold_fall" plays the sheet once:
## it tips over, at the impact the flag SAVED_FLAG is set and the guards are gone under the heap.

const PULLED_FLAG: String = "chase_pulled"
const SAVED_FLAG: String = "nyra_saved"
const FRAME_TIME: float = 0.09
## Frame of the sheet in which the scaffold hits the ground.
const IMPACT_FRAME: int = 6

@export var guard_a: Appearance
@export var guard_b: Appearance
## PixelLab sheets of the two guards (assets/sprites/residents/), win over the looks.
@export var resident_a: String = ""
@export var resident_b: String = ""
## Where the guards stand, relative to this sprite.
@export var guard_spots: PackedVector2Array = []

var _guards: Array[Sprite2D] = []


func _ready() -> void:
	y_sort_enabled = true
	Events.cutscene_requested.connect(_on_cutscene)
	GameState.story.changed.connect(_update_guards)
	if GameState.story.has_flag(SAVED_FLAG):
		frame = hframes - 1
		return
	for i in guard_spots.size():
		var look: Appearance = guard_a if i % 2 == 0 else guard_b
		var sheet: Texture2D = CharacterBaker.get_resident_sheet(resident_a if i % 2 == 0 else resident_b)
		var guard := Sprite2D.new()
		guard.texture = sheet if sheet else CharacterBaker.get_sheet(look)
		guard.region_enabled = true
		guard.region_rect = CharacterBaker.get_frame_rect("up")
		guard.offset = Vector2(0, -13)
		guard.position = guard_spots[i]
		add_child(guard)
		_guards.append(guard)
	_update_guards()


func _update_guards() -> void:
	var here: bool = GameState.story.has_flag(PULLED_FLAG) and not GameState.story.has_flag(SAVED_FLAG)
	for guard in _guards:
		if is_instance_valid(guard):
			guard.visible = here


func _on_cutscene(cutscene_id: String) -> void:
	if cutscene_id != "scaffold_fall":
		return
	var tween := create_tween()
	tween.tween_property(self, "frame", IMPACT_FRAME, FRAME_TIME * IMPACT_FRAME)
	tween.tween_callback(GameState.story.set_flag.bind(SAVED_FLAG))
	tween.tween_property(self, "frame", hframes - 1, FRAME_TIME * (hframes - 1 - IMPACT_FRAME))
