class_name HireNpc
extends Station
## NPC that can be hired as a hero. Talk to him with E (opens the HireDialog).
## Once hired he joins GameState.heroes and is no longer standing in the world.

## Hero template (res://data/heroes/...) this NPC becomes when hired.
@export var hero: Hero
## What the NPC says in the dialog.
@export_multiline var greeting: String = "":
	get:
		return Language.translate(greeting)

@onready var _dialog: HireDialog = $HireDialog
@onready var _name_label: Label = $NameLabel


func _ready() -> void:
	# Story: e.g. Bruno is only for hire like this when the story is skipped (else he comes himself).
	if GameState.has_hero(hero.id) or not GameState.story.has_flag(required_flag) \
			or GameState.story.is_npc_gone(String(hero.id)):
		queue_free()
		return
	_name_label.text = hero.display_name
	# Figure in the world = the hero's generated look.
	var look: Appearance = hero.get_appearance()
	var sprite: Sprite2D = $Sprite2D
	sprite.texture = CharacterBaker.get_sheet(look)
	sprite.region_rect = CharacterBaker.get_frame_rect("down")
	sprite.scale = Vector2.ONE * look.get_scale()
	_dialog.setup(hero, greeting)
	_dialog.hired.connect(queue_free)
