class_name GambaSword
extends RefCounted
## One sword of the lucky forge (GambaRun): material, rarity level (0 = R1), its own lottery
## tickets per outcome (they drift with every strike) and what happened to it so far.

## Unique in the run, so the scene can follow a sword (saved).
var id: int = 0
## Key in gamba.json "materials".
var material: String = ""
## 0 = R1 (Gewöhnlich), 1 = R2 ... above 7 it stays Mythisch with "+n".
var level: int = 0
## Highest level it ever had.
var peak_level: int = 0
var strikes: int = 0
## Strikes since the last frenzy (frenzy starts when it reaches the frenzy limit).
var frenzy_strikes: int = 0
## Outcome -> tickets (GambaRun.OUTCOMES).
var tickets: Dictionary[String, float] = {}
var damages: int = 0
var broken: bool = false
## Lies on the guild's table for tonight's tribute. Not saved on purpose: the game saves only
## between days, when the table is empty.
var offered: bool = false
## Was heated and lies on the anvil. Not saved on purpose (see offered).
var hot: bool = false


func to_dict() -> Dictionary:
	return {
		"id": id, "material": material, "level": level, "peak_level": peak_level, "strikes": strikes,
		"frenzy_strikes": frenzy_strikes, "tickets": tickets.duplicate(),
		"damages": damages, "broken": broken,
	}


static func from_dict(data: Dictionary) -> GambaSword:
	var sword := GambaSword.new()
	sword.id = int(data.get("id", 0))
	sword.material = String(data.get("material", ""))
	sword.level = int(data.get("level", 0))
	sword.peak_level = int(data.get("peak_level", sword.level))
	sword.strikes = int(data.get("strikes", 0))
	sword.frenzy_strikes = int(data.get("frenzy_strikes", 0))
	var saved: Dictionary = data.get("tickets", {})
	for outcome: String in saved:
		sword.tickets[outcome] = float(saved[outcome])
	sword.damages = int(data.get("damages", 0))
	sword.broken = bool(data.get("broken", false))
	return sword


func copy() -> GambaSword:
	var twin: GambaSword = GambaSword.from_dict(to_dict())
	twin.offered = offered
	twin.hot = hot
	return twin
