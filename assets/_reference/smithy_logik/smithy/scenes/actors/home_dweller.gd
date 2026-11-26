class_name HomeDweller
extends Villager
## Somebody inside his own house, there exactly while he is at home:
##   - a fixed villager (`npc_id`, npcs.json): while Residents.where says HOME, the same rule that
##     hides him outside (Resident);
##   - a villager of the map outside (`resident` sheet + `night_key`): while that villager is in
##     bed (he goes in through his home_spot, this house's door); without night_key between
##     `home_hours` (from, until; over midnight when from > until).
## Inside he walks between the spots of the room (stove, table, bed ...) like any villager and
## never "goes home" (he is home).
## Use: villager.tscn with this script, `npc_id` or `resident` + `home_hours`, `spots`, `roads`.

## How often (seconds) the clock is checked.
const CHECK_INTERVAL: float = 0.5
const NAME_OFFSET: Vector2 = Vector2(-40, -50)

## Id in npcs.json (empty: a plain villager with `resident` and `home_hours`).
@export var npc_id: String = ""
## Without npc_id: the outside villager's Villager.get_night_key() - inside exactly while he is in
## bed out there (he walks to his home_spot at his bedtime).
@export var night_key: String = ""
## Without npc_id and night_key: hours at home, [x, y) with x > y meaning over midnight.
@export var home_hours: Vector2 = Vector2(19.5, 7.5)

var _check_left: float = 0.0
var _present: bool = true


func _ready() -> void:
	goes_home_at_night = false
	if not npc_id.is_empty():
		appearance = Residents.get_look(npc_id)
		if resident.is_empty():
			resident = Residents.get_resident(npc_id)
	super()
	if not npc_id.is_empty():
		if not Residents.get_info(npc_id).exists:
			push_error("HomeDweller: '%s' is not in npcs.json." % npc_id)
		var label := Label.new()
		label.text = Residents.get_display_name(npc_id)
		label.add_theme_font_size_override("font_size", 11)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(80, 0)
		label.position = NAME_OFFSET
		add_child(label)
	_set_present(is_home())


## True while he is in his house (not out in the village, not at work).
func is_home() -> bool:
	if not npc_id.is_empty():
		return Residents.where(npc_id, GameState.day_cycle.minutes) == Residents.Where.HOME
	if not night_key.is_empty():
		return Villager.is_night_for(night_key, GameState.day_cycle.minutes)
	var hour: float = GameState.day_cycle.minutes / 60.0
	if home_hours.x <= home_hours.y:
		return hour >= home_hours.x and hour < home_hours.y
	return hour >= home_hours.x or hour < home_hours.y


func _physics_process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = CHECK_INTERVAL
		var home: bool = is_home()
		if home != _present:
			_set_present(home)
	if _present:
		super(delta)


## Story "villagers_away" (festival) still wins, but it never shows a dweller who is out.
func _update_away() -> void:
	super()
	if not _present:
		visible = false


func _set_present(present: bool) -> void:
	_present = present
	visible = present
	_collision.set_deferred("disabled", not present)
	if not present:
		_release_spot()
		_path.clear()
		velocity = Vector2.ZERO
		_state = State.WAIT
