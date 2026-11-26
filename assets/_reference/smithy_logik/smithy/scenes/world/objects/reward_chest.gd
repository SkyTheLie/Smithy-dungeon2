extends Station
## Loot chest in the workshop of the smithy (contents: GameState.reward_chest, window: ChestMenu):
## dungeon loot and daily rewards. Shows a "!" while something is waiting inside.
## Appears once the story unlocks it (`required_flag`, e.g. after Bruno's first dungeon); until
## then the rewards wait in GameState.reward_chest. Small and big workshop have one each, the
## player can move it (HouseEditor) but not store it.

@onready var _marker: Label = $Marker


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	GameState.reward_chest.changed.connect(_update_marker)
	GameState.reward_chest_filled.connect(_update_marker)
	_update_marker()


func _update_marker() -> void:
	var has_items: bool = GameState.reward_chest_gold > 0
	for slot in GameState.reward_chest.slots:
		if not slot.is_empty():
			has_items = true
			break
	_marker.visible = has_items
