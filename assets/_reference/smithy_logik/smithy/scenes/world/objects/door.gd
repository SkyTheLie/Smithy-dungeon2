class_name Door
extends Area2D

## Scene that is loaded when the player walks into the door.
@export_file("*.tscn") var target_scene: String
## Name of the spawn point in the target scene where the player appears.
@export var target_spawn_point: StringName
## Story flag (GameState.story) that opens the door. Empty = always open.
@export var required_flag: String = ""
## Message while the door is locked.
@export var locked_text: String = "Die Tür ist verschlossen.":
	get:
		return Language.translate(locked_text)
## Story flag from which the way is closed for a while (e.g. during the raid only the way to the
## market is open). Empty = never closed this way.
@export var blocked_flag: String = ""
## Story flag that opens the way again. Empty = closed for good once `blocked_flag` is set.
@export var unblocked_flag: String = ""
## Message while the way is closed by `blocked_flag`.
@export var blocked_text: String = "Da kannst du jetzt nicht hin.":
	get:
		return Language.translate(blocked_text)
## Fade to black while travelling (e.g. a carriage to another town).
@export var fade: bool = false
## true = walking in is not enough, the player has to press the interact key (E) there
## (carriages: no accidental rides). `interact_text` is shown when he steps in.
@export var needs_interact: bool = false
@export var interact_text: String = "{key_interact}: einsteigen"
## A carriage: the id of its stop (world_map.json "carriage.stops"). Instead of going to
## `target_scene`, E opens the CarriageMenu: the player picks where to ride, the ride takes days.
@export var carriage_stop: String = ""
## Door of a shop: only open during its opening hours (`hours_of`); walking into it while closed
## shows "Geschlossen" with the opening hours.
@export var shop_hours: bool = false
## Whose opening hours the shop door keeps: "market" = economy.json "market_hours" (like the
## merchants inside), "nina_shop" = Nina's shop (economy.json "shop" open_from_hour/open_until_hour).
@export_enum("market", "nina_shop") var hours_of: String = "market"

const CARRIAGE_MENU: PackedScene = preload("res://scenes/ui/menus/carriage_menu.tscn")
## Ways out of the scene on foot (doors, map edges; not carriages): story figures leave through
## the nearest one (StoryNpc._walk_off).
const EXIT_GROUP: StringName = &"scene_exits"

## Story step in which the player knocks before he goes in (Oma Hilde: "Na, wer klopft denn da?").
@export var knock_step: String = ""
## Door of a walk-in house (scenes/world/homes/): no way out of the map for story figures
## (not in EXIT_GROUP) and shut while a cutscene moves the player (Player.is_locked), so an
## auto-walk past the house never ends up inside.
@export var house_door: bool = false

const KNOCK_LOCK: StringName = &"door_knock"

var _player_in_range: bool = false
var _knocking: bool = false
var _carriage_menu: CarriageMenu


func _ready() -> void:
	body_exited.connect(_on_body_exited)
	if needs_interact:
		add_to_group(Station.INTERACT_GROUP)
	elif not target_scene.is_empty() and not house_door:
		add_to_group(EXIT_GROUP)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if house_door and (body as Player).is_locked():
		return
	if needs_interact:
		_player_in_range = true
		GameState.show_message(KeyBindings.fill(Language.translate(interact_text)))
		return
	_enter()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		if _carriage_menu:
			_carriage_menu.hide()


func _unhandled_input(event: InputEvent) -> void:
	if needs_interact and _player_in_range and event.is_action_pressed("interact") 			and Station.is_nearest_interactable(self):
		get_viewport().set_input_as_handled()
		if _carriage_menu and _carriage_menu.visible:
			_carriage_menu.hide()
			return
		_enter()


func _enter() -> void:
	if not GameState.story.has_flag(required_flag):
		GameState.show_message(locked_text)
		return
	if is_blocked():
		GameState.show_message(blocked_text)
		return
	if not carriage_stop.is_empty():
		_open_carriage_menu()
		return
	var here: String = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	if GameState.is_blocked_at_night(target_scene, here):
		GameState.show_message(GameState.NIGHT_BLOCKED_MESSAGE)
		return
	if _knocking:
		return
	if not knock_step.is_empty() and GameState.story.step == knock_step:
		var knocker := get_tree().get_first_node_in_group(Player.GROUP) as Player
		if knocker:
			_knocking = true
			knocker.lock(KNOCK_LOCK)
			await NpcActing.play(knocker, "knock")
			if not is_instance_valid(knocker) or not is_inside_tree():
				return
			knocker.unlock(KNOCK_LOCK)
			_knocking = false
	if not is_shop_open():
		GameState.show_message(Language.translate("Geschlossen. Geöffnet von %d bis %d Uhr.") % [_get_hours()[0], _get_hours()[1]])
		return
	# Only real doors creak: into or out of a building, not between two outdoor maps.
	if AudioManager.is_indoor(here) or AudioManager.is_indoor(target_scene):
		AudioManager.play_sound("door")
	GameState.travel_to(target_scene, target_spawn_point, fade)


## For Station.is_nearest_interactable: a door you enter with E (a carriage) takes E in its area.
func wants_interact() -> bool:
	return needs_interact and _player_in_range


func interact_priority() -> int:
	return 0


func _open_carriage_menu() -> void:
	if _carriage_menu == null:
		_carriage_menu = CARRIAGE_MENU.instantiate()
		add_child(_carriage_menu)
	_carriage_menu.stop_id = carriage_stop
	_carriage_menu.show()


## false while a shop door (`shop_hours`) is outside its opening hours.
func is_shop_open() -> bool:
	if not shop_hours:
		return true
	var hour: float = GameState.day_cycle.minutes / 60.0
	var hours: Array[int] = _get_hours()
	return hour >= hours[0] and hour < hours[1]


## [from, until] as whole hours: economy.json "market_hours" or, for Nina's shop, "shop".
func _get_hours() -> Array[int]:
	if hours_of == "nina_shop":
		var shop: Dictionary = ContentDB.economy("shop")
		return [int(shop.get("open_from_hour", 6)), int(shop.get("open_until_hour", 20))]
	var hours: Dictionary = ContentDB.economy("market_hours")
	return [int(hours.get("from", 6)), int(hours.get("until", 19))]


## true while the story closes this way (`blocked_flag` set, `unblocked_flag` not yet).
func is_blocked() -> bool:
	var story: Story = GameState.story
	return not blocked_flag.is_empty() and story.has_flag(blocked_flag) \
			and (unblocked_flag.is_empty() or not story.has_flag(unblocked_flag))
