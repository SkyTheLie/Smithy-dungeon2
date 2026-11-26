class_name DayCycle
extends RefCounted
## Time of day. A day starts at 06:00 and runs through morning, noon, evening and night.
## Only sleeping in the bed ends the day: at 02:00 the clock simply stops until the player
## sleeps. Outside the village (GameState.WILD_SCENES) the clock stops at nightfall (21:00).
## Lives in GameState.day_cycle and is ticked there.

## A new day has started (after sleeping).
signal day_started(day: int)
signal phase_changed(phase: Phase)

enum Phase { MORNING, NOON, EVENING, NIGHT }

const PHASE_NAMES: Dictionary = {
	Phase.MORNING: "Morgen",
	Phase.NOON: "Mittag",
	Phase.EVENING: "Abend",
	Phase.NIGHT: "Nacht",
}
## Hour at which each phase starts (hours after midnight; 26 = 02:00 of the next day).
const PHASE_START_HOURS: Dictionary = {
	Phase.MORNING: 6.0,
	Phase.NOON: 11.0,
	Phase.EVENING: 17.0,
	Phase.NIGHT: 21.0,
}
const DAY_START_HOUR: float = 6.0
const DAY_END_HOUR: float = 26.0
## Real seconds per in-game minute: 0.6 s -> one day (06:00 to 02:00) takes 12 real minutes.
const REAL_SECONDS_PER_MINUTE: float = 0.6
## Light colour over the day (hour -> colour), used by DayTint. Values in between are blended.
const TINT_KEYS: Array = [
	[6.0, Color(0.8, 0.76, 0.86)],
	[8.0, Color(1.0, 0.96, 0.9)],
	[12.0, Color(1.0, 1.0, 1.0)],
	[16.5, Color(1.0, 0.96, 0.88)],
	[19.0, Color(1.0, 0.76, 0.6)],
	[21.0, Color(0.55, 0.55, 0.8)],
	[22.5, Color(0.38, 0.4, 0.66)],
	[26.0, Color(0.38, 0.4, 0.66)],
]

var day: int = 1
## In-game minutes since midnight of the current day (can go past 24 * 60 at night).
var minutes: float = DAY_START_HOUR * 60.0

var _phase: Phase = Phase.MORNING


## Advances the clock. `max_minutes` = the clock does not go past this (e.g. nightfall while
## the player is in the forest); the day end (02:00) is always the limit.
func tick(delta: float, max_minutes: float = DAY_END_HOUR * 60.0) -> void:
	var limit: float = minf(max_minutes, DAY_END_HOUR * 60.0)
	if minutes >= limit:
		return
	minutes = minf(minutes + delta / REAL_SECONDS_PER_MINUTE, limit)
	_update_phase()


## Sets the clock to this time of the day (minutes after midnight, also backwards), e.g. the admin
## panel's clock.
func set_minutes(value: float) -> void:
	minutes = clampf(value, 0.0, DAY_END_HOUR * 60.0)
	_update_phase()


## Jumps forward to this hour (never backwards), e.g. "it gets evening" in the story.
func advance_to_hour(hour: float) -> void:
	minutes = maxf(minutes, hour * 60.0)
	_update_phase()


func is_night() -> bool:
	return get_phase() == Phase.NIGHT


func _update_phase() -> void:
	var phase: Phase = get_phase()
	if phase != _phase:
		_phase = phase
		phase_changed.emit(phase)


## Ends the day: next morning, 06:00.
func start_next_day() -> void:
	day += 1
	minutes = DAY_START_HOUR * 60.0
	_phase = Phase.MORNING
	phase_changed.emit(_phase)
	day_started.emit(day)


func get_hour() -> float:
	return minutes / 60.0


func get_phase() -> Phase:
	var current: Phase = Phase.MORNING
	for phase in PHASE_START_HOURS:
		if get_hour() >= PHASE_START_HOURS[phase]:
			current = phase
	return current


func get_phase_name() -> String:
	return Language.translate(PHASE_NAMES[get_phase()])


## Clock as "HH:MM" (after midnight it shows 00:xx / 01:xx again).
func get_clock_text() -> String:
	var total: int = int(minutes) % (24 * 60)
	return "%02d:%02d" % [total / 60, total % 60]


## Light colour for the current time (see TINT_KEYS).
func get_tint() -> Color:
	var hour: float = get_hour()
	for i in range(1, TINT_KEYS.size()):
		var next_key: Array = TINT_KEYS[i]
		if hour <= next_key[0]:
			var previous: Array = TINT_KEYS[i - 1]
			var weight: float = inverse_lerp(previous[0], next_key[0], hour)
			return (previous[1] as Color).lerp(next_key[1], clampf(weight, 0.0, 1.0))
	return TINT_KEYS.back()[1]


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"day": day, "minutes": minutes}


func load_save_data(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	minutes = clampf(float(data.get("minutes", DAY_START_HOUR * 60.0)), 0.0, DAY_END_HOUR * 60.0)
	_phase = get_phase()
	phase_changed.emit(_phase)
