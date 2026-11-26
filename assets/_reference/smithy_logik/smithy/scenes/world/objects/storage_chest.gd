extends Station
## Storage chest next to the bed (contents: GameState.storage_chest, window: StorageMenu).
## While the story figure `story_npc_id` (the old chest with the axe recipes) has something for
## the current step, E belongs to it and the chest can't be opened.

@export var story_npc_id: String = "old_chest"


func wants_interact() -> bool:
	return not (not story_npc_id.is_empty() and GameState.story.npc_has_news(story_npc_id)) and super()
