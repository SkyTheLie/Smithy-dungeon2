class_name Residents
extends RefCounted
## Fixed villagers (data/content/npcs.json): who they are, where they live and their day.
## A fixed villager with "day" is outside between those hours, at home otherwise; with "work"
## it is away at work (another scene) between "from" and "until". The Resident node walks them in
## and out of their home scene, a Merchant with `npc_id` is only at its stall during work hours.

enum Where { HOME, OUT, AWAY }


static func get_info(npc_id: String) -> NpcInfo:
	return ContentDB.npc_info(npc_id)


## Where the villager is at `minutes` (in-game minutes since midnight, DayCycle.minutes).
static func where(npc_id: String, minutes: float) -> Where:
	var day: Array[float] = get_info(npc_id).day_hours
	var hour: float = minutes / 60.0
	if day.size() == 2 and (hour < day[0] or hour >= day[1]):
		return Where.HOME
	if is_working(npc_id, minutes):
		return Where.AWAY
	return Where.OUT


## Whether the villager is at work (e.g. Erna at her stall) at `minutes`. No "work" = always.
static func is_working(npc_id: String, minutes: float) -> bool:
	var work: NpcInfo.Work = get_info(npc_id).work
	if work == null:
		return true
	var hour: float = minutes / 60.0
	return hour >= work.from and hour < work.until


## PixelLab sheet from npcs.json "resident" (assets/sprites/residents/, "" = none).
static func get_resident(npc_id: String) -> String:
	return get_info(npc_id).resident


## Look from npcs.json "look" (null if there is none).
static func get_look(npc_id: String) -> Appearance:
	var look: Dictionary = get_info(npc_id).look
	return Appearance.from_save_data(look) if not look.is_empty() else null


static func get_display_name(npc_id: String) -> String:
	var info: NpcInfo = get_info(npc_id)
	return info.display_name if not info.display_name.is_empty() else npc_id
