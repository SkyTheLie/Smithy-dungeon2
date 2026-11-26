class_name Carriage
extends RefCounted
## The carriages (world_map.json "carriage"): every carriage stop lets the player pick where to go,
## among the stops the story has opened (stop "flag"). The ride takes days: the distance between the
## two stops on the world map / "units_per_day", rounded up, at least "min_days". Those days pass
## like nights (GameState.pass_days: smelters, adventures, rent, customers, overnight story flags);
## the player arrives at "arrival_hour" and the morning screen says how long the ride was.


static func stops() -> Dictionary:
	return ContentDB.world_map().get("carriage", {}).get("stops", {})


static func get_stop(stop_id: String) -> Dictionary:
	return stops().get(stop_id, {})


## true once the story lets the carriage go to this stop.
static func is_open(stop_id: String) -> bool:
	var stop: Dictionary = get_stop(stop_id)
	return not stop.is_empty() and GameState.story.has_flag(str(stop.get("flag", "")))


## Stops the carriage at `from_id` can go to now, in file order (not `from_id` itself).
static func destinations_from(from_id: String) -> Array[String]:
	var result: Array[String] = []
	for stop_id: String in stops():
		if stop_id != from_id and is_open(stop_id):
			result.append(stop_id)
	return result


## Days of the ride between two stops (distance on the world map).
static func days_between(from_id: String, to_id: String) -> int:
	var settings: Dictionary = ContentDB.world_map().get("carriage", {})
	var from_at: Array = get_stop(from_id).get("at", [0, 0])
	var to_at: Array = get_stop(to_id).get("at", [0, 0])
	var distance: float = Vector2(from_at[0], from_at[1]).distance_to(Vector2(to_at[0], to_at[1]))
	return maxi(int(settings.get("min_days", 1)), ceili(distance / float(settings.get("units_per_day", 100.0))))


## Rides from `from_id` to `to_id`: the days pass, then the player is at the stop and the morning
## screen shows the ride and the news of those days.
static func ride(from_id: String, to_id: String) -> void:
	var stop: Dictionary = get_stop(to_id)
	var days: int = days_between(from_id, to_id)
	var hour: float = float(ContentDB.world_map().get("carriage", {}).get("arrival_hour", 9))
	var news: String = GameState.pass_days(days, hour)
	var ride_text: String = Language.translate("Nach %d Tagen mit der Kutsche erreichst du %s.") % [days, Language.translate(str(stop.get("name", to_id)))] \
			if days != 1 else Language.translate("Nach einem Tag mit der Kutsche erreichst du %s.") % Language.translate(str(stop.get("name", to_id)))
	GameState.wake_up_text = ride_text + "\n" + GameCalendar.get_long_text(GameState.day_cycle.day) + news
	GameState.travel_to(str(stop.get("scene", "")), StringName(str(stop.get("spawn", ""))))
