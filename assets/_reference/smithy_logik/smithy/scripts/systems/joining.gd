class_name Joining
extends RefCounted
## Rules of the workbench minigame (joining two parts, see WorkbenchMinigame).
## Both parts carry a green strip in the middle and a yellow strip on each side. When the upper
## part comes down, the horizontal distance between the two middles decides the grade:
##   green on green  -> PERFECT: the item gets many quality points
##   green on yellow -> GOOD:    a few quality points
##   yellow on yellow -> OKAY:   no change
##   no colour meets -> FAIL:    nothing is built, every part loses quality points (its rarity
##                               can drop with it); the player has to try again.
## Points: ForgeQuality.joining_points (economy.json "crafting_quality.joining").
## Zone widths come from PlayerStats (get_joining_green_zone_width / ..._yellow_...) and the
## difficulty of the material (ForgeQuality.get_difficulty).

enum Grade { FAIL, OKAY, GOOD, PERFECT }

const NAMES: Array[String] = ["Fehlgeschlagen", "Okay", "Gut", "Perfekt!"]
## combine(): lowest average (FAIL 0 .. PERFECT 3) for each grade.
const COMBINE_PERFECT: float = 2.75
const COMBINE_GOOD: float = 1.75
const COMBINE_OKAY: float = 1.0


## Grade for the distance between the two middles. `green` = full width of a green strip,
## `yellow` = width of ONE yellow strip (same unit as `offset`).
## Strips touch as soon as the distance is smaller than half of both widths added up.
static func grade(offset: float, green: float, yellow: float) -> Grade:
	var distance: float = absf(offset)
	if green > 0.0 and distance < green:
		return Grade.PERFECT
	if yellow > 0.0 and distance < green + yellow:
		return Grade.GOOD
	if yellow > 0.0 and distance < green + 2.0 * yellow:
		return Grade.OKAY
	return Grade.FAIL


## Grade of several hits together (riveting: one grade per rivet): their average, where FAIL = 0
## and PERFECT = 3. A single failed rivet among perfect ones still makes a GOOD piece.
static func combine(grades: Array[Grade]) -> Grade:
	if grades.is_empty():
		return Grade.FAIL
	var total: float = 0.0
	for result in grades:
		total += int(result)
	var average: float = total / grades.size()
	if average >= COMBINE_PERFECT:
		return Grade.PERFECT
	if average >= COMBINE_GOOD:
		return Grade.GOOD
	if average >= COMBINE_OKAY:
		return Grade.OKAY
	return Grade.FAIL


static func get_display_name(result: Grade) -> String:
	return Language.translate(NAMES[result])


## Failed joining: every part loses the FAIL points (ForgeQuality.joining_points).
## Parts without rarity worth keeping (wood, rope) lose them too, but they stay R1 Q0.
static func damage_parts(parts: Array[InventorySlot]) -> void:
	var loss: int = ForgeQuality.joining_points(Grade.FAIL)
	for part in parts:
		if not part.is_empty():
			ForgeQuality.add(part, loss)
