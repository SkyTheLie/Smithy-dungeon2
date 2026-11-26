class_name SneakZone
extends Node2D
## One area of the sneaking way into the Finsterburg (moat, wall passages, gate yard). Every
## SneakGuard of the scene watches the player; when one sees him, a "!" appears above the guard,
## a short text says what happened and the player runs back to the start of the area (`start_spawn`).
## The first time in the first area the story shows how sneaking works (hint "sneaking").

const TEXT_CAUGHT: Array[String] = [
	"Entdeckt! Du rennst zurück in die Schatten.",
	"Eine Wache hat dich gesehen. Du rettest dich zurück an den Anfang.",
	"Knochen klappern, ein Ruf hallt über die Mauer. Zurück in den Schatten, schnell.",
]
## Seconds between being seen and running back.
const CAUGHT_DELAY: float = 0.8

@export var start_spawn: StringName = &"Start"
## Story flag -> spawn point: from this flag on the player starts again there instead (e.g. in the
## gatehouse after the lever, next to the lever instead of at the door he came in by).
@export var flag_spawns: Dictionary = {}

var _caught: bool = false


func _ready() -> void:
	for guard in find_children("*", Language.translate("SneakGuard"), true, false):
		(guard as SneakGuard).spotted.connect(_on_spotted)


func _on_spotted(guard: SneakGuard) -> void:
	if _caught:
		return
	_caught = true
	var mark := Label.new()
	mark.text = "!"
	mark.position = Vector2(-4, -64)
	mark.add_theme_font_size_override("font_size", 22)
	mark.add_theme_color_override("font_color", Color(1.0, 0.3, 0.25))
	mark.add_theme_color_override("font_outline_color", Color.BLACK)
	mark.add_theme_constant_override("outline_size", 4)
	guard.add_child(mark)
	GameState.story.set_flag("sneak_caught_once")
	GameState.show_message(TEXT_CAUGHT.pick_random())
	await get_tree().create_timer(CAUGHT_DELAY, false).timeout
	GameState.travel_to(scene_file_path, restart_spawn(), true)


## Where the player starts again: `start_spawn`, or the spawn of the last set flag in `flag_spawns`.
func restart_spawn() -> StringName:
	var spawn: StringName = start_spawn
	for flag: String in flag_spawns:
		if GameState.story.has_flag(flag):
			spawn = StringName(flag_spawns[flag])
	return spawn
