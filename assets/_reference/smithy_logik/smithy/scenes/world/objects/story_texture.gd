class_name StoryTexture
extends Sprite2D
## A sprite that changes its picture once a story flag is set, e.g. a market house that is
## scorched by a fireball during the raid. From `until_flag` on (empty = never) it shows its
## first picture again (e.g. the house is repaired after the rebuilding, chapter 11).

@export var flag: String = ""
@export var texture_after: Texture2D
@export var until_flag: String = ""

var _texture_before: Texture2D


func _ready() -> void:
	_texture_before = texture
	GameState.story.changed.connect(_update)
	_update()


func _update() -> void:
	var story: Story = GameState.story
	var changed: bool = not flag.is_empty() and story.has_flag(flag) and texture_after \
			and (until_flag.is_empty() or not story.has_flag(until_flag))
	texture = texture_after if changed else _texture_before
