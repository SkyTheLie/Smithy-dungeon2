class_name StoryStation
extends Station
## A station that only reacts between two story flags, and lets E through otherwise (e.g. the
## dragon in the treasure chamber: first the dragon talks (a StoryNpc on the same spot with
## silent_without_news), then E opens the hero choice for the fight, until the dragon is beaten).
## Unlike `required_flag` it can wake up while the player is in the scene.

## From this story flag on E opens the station (empty = always).
@export var open_flag: String = ""
## From this story flag on it is shut again (empty = never).
@export var close_flag: String = ""


func is_open() -> bool:
	var story: Story = GameState.story
	return story.has_flag(open_flag) and (close_flag.is_empty() or not story.has_flag(close_flag))


func wants_interact() -> bool:
	return is_open() and super()
