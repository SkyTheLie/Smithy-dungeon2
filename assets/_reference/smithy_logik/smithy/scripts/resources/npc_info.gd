class_name NpcInfo
extends RefCounted
## One fixed villager from npcs.json (ContentDB.npc_info). Typed on purpose: a misspelled field in
## the code does not compile, a misspelled or wrongly typed field in the JSON is reported when the
## content loads (from_json), and every default value lives here and nowhere else.
## Template for turning more JSON dictionaries into small classes (docs/ENTSCHEIDUNGEN.md).

## Game minutes on the way between two places of a roaming figure (Roaming) without "travel_minutes".
const DEFAULT_TRAVEL_MINUTES: float = 30.0
## Fields allowed in an npcs.json entry. Keys starting with "_" are notes for people.
const FIELDS: Array[String] = ["name", "job", "partner", "home", "resident", "look", "day", "work", "visits", "roam", "sleeps"]

var id: String = ""
## false if npcs.json has no entry with this id (ContentDB.npc_info then returns an empty one).
var exists: bool = false
var display_name: String = ""
var job: String = ""
var partner: String = ""
## Home: scene file name without .tscn and the name of its door spot (VillagerSpot), "" = none.
var home_scene: String = ""
var home_door: String = ""
## PixelLab sheet in assets/sprites/residents/ ("" = none, then `look`).
var resident: String = ""
## Look like in the character creator (Appearance save data), {} = none.
var look: Dictionary = {}
## [from, until): hours outside the house; empty = no daily schedule (always outside).
var day_hours: Array[float] = []
var work: Work = null
var visits: Visits = null
var roam: Roam = null
var sleeps: Sleeps = null


## "work": at work in another scene between `from` and `until` (e.g. Erna at her stall).
class Work:
	const FIELDS: Array[String] = ["scene", "leave_by", "from", "until"]
	var scene: String = ""
	## Exit spot (VillagerSpot) the figure walks out through.
	var leave_by: String = ""
	var from: float = 0.0
	var until: float = 24.0


## "visits": the figure comes only on some weekdays once `flag` is set (before: every day).
class Visits:
	const FIELDS: Array[String] = ["flag", "weekdays", "hours"]
	var flag: String = ""
	## 0 = Monday.
	var weekdays: Array[int] = []
	var from_hour: float = 0.0
	var until_hour: float = 24.0


## "roam": the figure moves between places once `flag` is set (Roaming).
class Roam:
	const FIELDS: Array[String] = ["flag", "day", "slot_hours", "travel_minutes", "spots"]
	var flag: String = ""
	var from_hour: float = 8.0
	var until_hour: float = 20.0
	var slot_hours: float = 3.0
	## Game minutes on the way between two places.
	var travel_minutes: float = DEFAULT_TRAVEL_MINUTES
	## place -> weight.
	var spots: Dictionary[String, float] = {}


## "sleeps": on `weekday` of every `every_weeks`-th week (from week `week`) nobody may see the
## figure; `text` is shown at the door (the goblin king).
class Sleeps:
	const FIELDS: Array[String] = ["weekday", "every_weeks", "week", "text"]
	var weekday: int = 2
	var every_weeks: int = 2
	var week: int = 0
	var text: String = ""


## Builds the entry `id` from its JSON object. Mistakes (unknown fields, wrong types) are added to
## `errors` as readable lines; the entry is still built with the defaults for the broken fields.
static func from_json(npc_id: String, data: Dictionary, errors: Array[String]) -> NpcInfo:
	var info := NpcInfo.new()
	info.id = npc_id
	info.exists = true
	var where: String = "npcs.json '%s'" % npc_id
	_check_fields(data, FIELDS, where, errors)
	info.display_name = _text(data, "name", where, errors)
	info.job = _text(data, "job", where, errors)
	info.partner = _text(data, "partner", where, errors)
	info.resident = _text(data, "resident", where, errors)
	var home: Dictionary = _object(data, "home", where, errors)
	_check_fields(home, ["scene", "door"], where + " home", errors)
	info.home_scene = _text(home, "scene", where + " home", errors)
	info.home_door = _text(home, "door", where + " home", errors)
	info.look = _object(data, "look", where, errors)
	var day: Array[float] = _hours(data, "day", where, errors)
	info.day_hours = day
	if data.has("work"):
		var source: Dictionary = _object(data, "work", where, errors)
		_check_fields(source, Work.FIELDS, where + " work", errors)
		var work := Work.new()
		work.scene = _text(source, "scene", where + " work", errors)
		work.leave_by = _text(source, "leave_by", where + " work", errors)
		work.from = _number(source, "from", work.from, where + " work", errors)
		work.until = _number(source, "until", work.until, where + " work", errors)
		info.work = work
	if data.has("visits"):
		var source: Dictionary = _object(data, "visits", where, errors)
		_check_fields(source, Visits.FIELDS, where + " visits", errors)
		var visits := Visits.new()
		visits.flag = _text(source, "flag", where + " visits", errors)
		for weekday: Variant in _list(source, "weekdays", where + " visits", errors):
			visits.weekdays.append(int(weekday))
		var hours: Array[float] = _hours(source, "hours", where + " visits", errors)
		if hours.size() == 2:
			visits.from_hour = hours[0]
			visits.until_hour = hours[1]
		info.visits = visits
	if data.has("roam"):
		var source: Dictionary = _object(data, "roam", where, errors)
		_check_fields(source, Roam.FIELDS, where + " roam", errors)
		var roam := Roam.new()
		roam.flag = _text(source, "flag", where + " roam", errors)
		var hours: Array[float] = _hours(source, "day", where + " roam", errors)
		if hours.size() == 2:
			roam.from_hour = hours[0]
			roam.until_hour = hours[1]
		roam.slot_hours = maxf(1.0, _number(source, "slot_hours", roam.slot_hours, where + " roam", errors))
		roam.travel_minutes = _number(source, "travel_minutes", roam.travel_minutes, where + " roam", errors)
		var spots: Dictionary = _object(source, "spots", where + " roam", errors)
		for spot: Variant in spots:
			roam.spots[str(spot)] = float(spots[spot])
		info.roam = roam
	if data.has("sleeps"):
		var source: Dictionary = _object(data, "sleeps", where, errors)
		_check_fields(source, Sleeps.FIELDS, where + " sleeps", errors)
		var sleeps := Sleeps.new()
		sleeps.weekday = int(_number(source, "weekday", sleeps.weekday, where + " sleeps", errors))
		sleeps.every_weeks = maxi(1, int(_number(source, "every_weeks", sleeps.every_weeks, where + " sleeps", errors)))
		sleeps.week = int(_number(source, "week", sleeps.week, where + " sleeps", errors))
		sleeps.text = _text(source, "text", where + " sleeps", errors)
		info.sleeps = sleeps
	return info


## The entry for an id that is not in npcs.json (all defaults, `exists` false).
static func missing(npc_id: String) -> NpcInfo:
	var info := NpcInfo.new()
	info.id = npc_id
	return info


static func _check_fields(data: Dictionary, allowed: Array[String], where: String, errors: Array[String]) -> void:
	for key: Variant in data:
		if not str(key).begins_with("_") and not allowed.has(str(key)):
			_push_error_to(errors, "%s: unknown field '%s' (allowed: %s)" % [where, key, ", ".join(allowed)])


static func _text(data: Dictionary, key: String, where: String, errors: Array[String]) -> String:
	var value: Variant = data.get(key, "")
	if not value is String:
		_push_error_to(errors, "%s: '%s' must be a text" % [where, key])
		return ""
	return value


static func _number(data: Dictionary, key: String, default: float, where: String, errors: Array[String]) -> float:
	var value: Variant = data.get(key, default)
	if not (value is float or value is int):
		_push_error_to(errors, "%s: '%s' must be a number" % [where, key])
		return default
	return float(value)


static func _object(data: Dictionary, key: String, where: String, errors: Array[String]) -> Dictionary:
	var value: Variant = data.get(key, {})
	if not value is Dictionary:
		_push_error_to(errors, "%s: '%s' must be an object { ... }" % [where, key])
		return {}
	return value


static func _list(data: Dictionary, key: String, where: String, errors: Array[String]) -> Array:
	var value: Variant = data.get(key, [])
	if not value is Array:
		_push_error_to(errors, "%s: '%s' must be a list [ ... ]" % [where, key])
		return []
	return value


## [from, until] in hours, or [] if the field is missing or broken.
static func _hours(data: Dictionary, key: String, where: String, errors: Array[String]) -> Array[float]:
	var result: Array[float] = []
	if not data.has(key):
		return result
	var value: Array = _list(data, key, where, errors)
	if value.size() != 2 or not value.all(func(hour: Variant) -> bool: return hour is float or hour is int):
		_push_error_to(errors, "%s: '%s' must be [from, until] in hours" % [where, key])
		return result
	result.append(float(value[0]))
	result.append(float(value[1]))
	return result


## Adds one readable mistake (ContentDB pushes them as errors; for developers, not translated).
static func _push_error_to(errors: Array[String], text: String) -> void:
	errors.append(text)
