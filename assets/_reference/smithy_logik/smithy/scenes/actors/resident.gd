class_name Resident
extends Villager
## A fixed villager from npcs.json (e.g. Gustav) in the scene of its home. Looks and name come
## from the file, the clock decides where it is (Residents.where):
##   HOME  inside its house (hidden) - in the evening it walks to its door and goes in,
##         in the morning it comes out of the door
##   OUT   walks around like any villager, but only goes into its own house
##   AWAY  at work in another scene (hidden) - it walks off through its exit spot
##         ("work.leave_by", a VillagerSpot under `exits`) and comes back the same way
## Use: villager.tscn with this script, `npc_id`, `spots`, `roads` and `exits` set.

## How often (seconds) the clock is checked.
const CHECK_INTERVAL: float = 0.5
const NAME_OFFSET: Vector2 = Vector2(-40, -50)

## Id in npcs.json.
@export var npc_id: String = ""
## Parent of the exit spots (VillagerSpot, not among the normal `spots`).
@export var exits: Node2D

var _where: Residents.Where = Residents.Where.OUT
## Where it is walking to right now to disappear (HOME or AWAY), -1 = nothing.
var _heading: int = -1
var _check_left: float = 0.0
var _home_door: VillagerSpot
var _exit: VillagerSpot


func _ready() -> void:
	appearance = Residents.get_look(npc_id)
	if resident.is_empty():
		resident = Residents.get_resident(npc_id)
	super()
	var info: NpcInfo = Residents.get_info(npc_id)
	if not info.exists:
		push_error("Resident: '%s' is not in npcs.json." % npc_id)
	_home_door = spots.get_node_or_null(info.home_door) as VillagerSpot if spots and not info.home_door.is_empty() else null
	var leave_by: String = info.work.leave_by if info.work else ""
	_exit = exits.get_node_or_null(leave_by) as VillagerSpot if exits and not leave_by.is_empty() else null
	var label := Label.new()
	label.text = Residents.get_display_name(npc_id)
	label.add_theme_font_size_override("font_size", 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(80, 0)
	label.position = NAME_OFFSET
	add_child(label)
	# Start where the clock says, without walking.
	_where = _wanted()
	if _where == Residents.Where.OUT:
		var start: VillagerSpot = _home_door if _home_door else null
		if start:
			global_position = start.global_position
	else:
		_set_present(false)


func _physics_process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = CHECK_INTERVAL
		_follow_clock()
	if _where != Residents.Where.OUT and _heading < 0:
		return
	super(delta)


func _wanted() -> Residents.Where:
	return Residents.where(npc_id, GameState.day_cycle.minutes)


func _follow_clock() -> void:
	var wanted: Residents.Where = _wanted()
	if wanted == _where or _heading >= 0:
		return
	if _where == Residents.Where.OUT:
		# Finish sitting / talking / a visit first, then walk to the door or the exit.
		if _state != State.WAIT or not visible:
			return
		var target: VillagerSpot = _home_door if wanted == Residents.Where.HOME else _exit
		if target == null:
			_where = wanted
			_set_present(false)
			return
		_heading = wanted
		_release_spot()
		_spot = null
		_path = roads.find_path(global_position, target.road, target.global_position) if target.road and roads.is_ready() \
				else PackedVector2Array([target.global_position])
		_start_walking()
	elif wanted == Residents.Where.OUT:
		# Comes out of the house in the morning, back from work in the evening.
		var from: VillagerSpot = _home_door if _where == Residents.Where.HOME else _exit
		if from:
			global_position = from.global_position
		_where = wanted
		_set_present(true)
		_state = State.WAIT
		_wait = randf_range(pause.x, pause.y)
	else:
		_where = wanted  # home <-> work while hidden


func _arrive() -> void:
	if _heading < 0:
		super()
		return
	velocity = Vector2.ZERO
	_where = _heading as Residents.Where
	_heading = -1
	_state = State.WAIT
	_set_present(false)


## Getting stuck on the way home just tries again from where it is.
func _give_up() -> void:
	if _heading < 0:
		super()
		return
	_heading = -1
	_state = State.WAIT
	_wait = 0.5


## After the villagers come back (e.g. from the festival) it stays hidden while it is at home.
func _update_away() -> void:
	super()
	if _where != Residents.Where.OUT and _heading < 0:
		_set_present(false)


## Its day comes from npcs.json ("day"), not from the villagers' evening hours.
func _uses_bedtime() -> bool:
	return false


## Only its own front door, no other houses.
func _can_use_spot(spot_to_check: VillagerSpot) -> bool:
	return spot_to_check.kind != VillagerSpot.Kind.DOOR or spot_to_check == _home_door


func _set_present(present: bool) -> void:
	visible = present
	_collision.set_deferred("disabled", not present)
