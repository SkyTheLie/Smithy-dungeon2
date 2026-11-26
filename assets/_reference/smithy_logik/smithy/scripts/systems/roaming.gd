class_name Roaming
extends RefCounted
## Story figures that move around the village (npcs.json "<id>.roam"), e.g. Lotte after the raid:
## every few hours she is somewhere else (at home, in front of the smithy, on the village square,
## on the market, in Nina's shop; as the smith's helper also in the workshop, see Assistant). The place is rolled from the day and the time slot, so it is the
## same in every scene and after loading. Each place has a StoryNpc with `roam_spot` = its name;
## only the one at the rolled place is visible.
## When the place changes the figure is first on the way (TRAVEL, in no scene) for
## "travel_minutes": it walks out of the old scene and later walks into the new one (StoryNpc).
## "roam": {"flag": needed story flag (before it the figure is only at "home"),
##          "day": [from, until] hours out of the house (otherwise "home"),
##          "slot_hours": hours per place, "spots": {place: weight},
##          "travel_minutes": game minutes on the way from one place to the next (default 30)}

const HOME: String = "home"
## Between two places.
const TRAVEL: String = "on_the_way"
const DEFAULT_TRAVEL_MINUTES: float = NpcInfo.DEFAULT_TRAVEL_MINUTES


## true if the figure `npc_id` is at the place `spot` right now.
static func is_at(npc_id: String, spot: String) -> bool:
	return get_spot(npc_id, GameState.day_cycle.day, GameState.day_cycle.get_hour()) == spot


## Place of the figure on `day` at `hour`: TRAVEL right after the place changed, else the place.
static func get_spot(npc_id: String, day: int, hour: float) -> String:
	var spot: String = _planned_spot(npc_id, day, hour)
	var travel: float = _travel_hours(npc_id)
	if travel > 0.0 and _planned_spot(npc_id, day, hour - travel) != spot:
		return TRAVEL
	return spot


## Where the figure is heading right now (its next place while it is on the way).
static func get_destination(npc_id: String) -> String:
	return _planned_spot(npc_id, GameState.day_cycle.day, GameState.day_cycle.get_hour())


## Where the figure came from, asked right after it arrived (shortly after its walk ended).
static func get_origin(npc_id: String) -> String:
	var hour: float = GameState.day_cycle.get_hour() - 2.0 * maxf(_travel_hours(npc_id), 0.1)
	return _planned_spot(npc_id, GameState.day_cycle.day, hour)


static func _travel_hours(npc_id: String) -> float:
	var roam: NpcInfo.Roam = ContentDB.npc_info(npc_id).roam
	return (roam.travel_minutes if roam else DEFAULT_TRAVEL_MINUTES) / 60.0


## Place the figure is meant to be at (without the way in between); HOME without "roam" or
## before its flag. Lotte's errands and lessons put her somewhere else (Assistant.get_spot).
static func _planned_spot(npc_id: String, day: int, hour: float) -> String:
	var forced: String = GameState.assistant.get_spot(npc_id, day, hour)
	if not forced.is_empty():
		return forced
	var roam: NpcInfo.Roam = ContentDB.npc_info(npc_id).roam
	if roam == null or not GameState.story.has_flag(roam.flag):
		return HOME
	if hour < roam.from_hour or hour >= roam.until_hour:
		return HOME
	var slot: int = int((hour - roam.from_hour) / roam.slot_hours)
	var spots: Dictionary[String, float] = roam.spots
	var total: float = 0.0
	for weight: float in spots.values():
		total += weight
	if total <= 0.0:
		return HOME
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|%d" % [npc_id, day, slot])
	var roll: float = rng.randf() * total
	for spot: String in spots:
		roll -= float(spots[spot])
		if roll < 0.0:
			return spot
	return HOME
