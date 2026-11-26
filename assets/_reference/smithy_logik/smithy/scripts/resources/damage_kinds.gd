class_name DamageKinds
extends RefCounted
## All kinds of damage a hit can be made of, as ids used in the JSON files:
##   physical group: "physical" (no type), "stab", "blunt", "slash" - reduced by armor and the
##                   target's resistance against that type
##   elements:       "fire", "water", "earth", "air", "dark", "light", "lightning", "ice", "poison"
##   "magic":        magic without an element
##   elements and magic are reduced by the target's resistance (+ its RES attribute)
##   "true":         true damage, ignores armor and every resistance
## A hit is split into shares, e.g. {"fire": 0.5, "slash": 0.5} (see CombatRules.mitigation).

const PHYSICAL: String = "physical"
const MAGIC: String = "magic"
const TRUE_DAMAGE: String = "true"
const PHYSICAL_KINDS: Array[String] = ["physical", "stab", "blunt", "slash"]
const ELEMENT_KINDS: Array[String] = ["fire", "water", "earth", "air", "dark", "light", "lightning", "ice", "poison"]

const NAMES: Dictionary = {
	"physical": "Physisch", "stab": "Stich", "blunt": "Stumpf", "slash": "Schnitt",
	"fire": "Feuer", "water": "Wasser", "earth": "Erde", "air": "Luft", "dark": "Dunkelheit",
	"light": "Licht", "lightning": "Blitz", "ice": "Eis", "poison": "Gift",
	"magic": "Magie", "true": "Wahrer Schaden",
}
const COLORS: Dictionary = {
	"physical": Color(0.85, 0.82, 0.75), "stab": Color(0.78, 0.84, 0.9), "blunt": Color(0.82, 0.72, 0.6),
	"slash": Color(0.92, 0.78, 0.74),
	"fire": Color(1.0, 0.42, 0.2), "water": Color(0.25, 0.72, 0.85), "earth": Color(0.68, 0.5, 0.28),
	"air": Color(0.72, 0.95, 0.85), "dark": Color(0.42, 0.3, 0.55), "light": Color(1.0, 0.95, 0.6),
	"lightning": Color(0.45, 0.6, 1.0), "ice": Color(0.7, 0.92, 1.0), "poison": Color(0.5, 0.78, 0.35),
	"magic": Color(0.78, 0.6, 1.0), "true": Color(1.0, 0.88, 0.95),
}
## Element.Type -> id (same order as the enum).
const ELEMENT_IDS: Array[String] = ["", "fire", "water", "earth", "air", "dark", "light", "lightning", "ice", "poison"]
## DamageType.Type -> id (same order as the enum).
const DAMAGE_TYPE_IDS: Array[String] = ["physical", "stab", "blunt", "slash"]


static func is_valid(kind: String) -> bool:
	return NAMES.has(kind)


static func is_physical(kind: String) -> bool:
	return kind in PHYSICAL_KINDS


static func get_display_name(kind: String) -> String:
	return Language.translate(NAMES.get(kind, kind))


static func get_color(kind: String) -> Color:
	return COLORS.get(kind, Color.WHITE)


static func from_element(element: Element.Type) -> String:
	return ELEMENT_IDS[element]


static func from_damage_type(type: DamageType.Type) -> String:
	return DAMAGE_TYPE_IDS[type]


## Shares that add up to 1 (any numbers work in JSON: {"fire": 50, "slash": 50}).
static func normalized(split: Dictionary) -> Dictionary:
	var total: float = 0.0
	for kind: String in split:
		total += maxf(float(split[kind]), 0.0)
	if total <= 0.0:
		return {PHYSICAL: 1.0}
	var result: Dictionary = {}
	for kind: String in split:
		if float(split[kind]) > 0.0:
			result[kind] = float(split[kind]) / total
	return result


## The kind with the biggest share (for colours of numbers in fights).
static func get_main_kind(split: Dictionary) -> String:
	var best: String = PHYSICAL
	var best_share: float = -1.0
	for kind: String in split:
		if split[kind] > best_share:
			best = kind
			best_share = split[kind]
	return best


## Numbers for texts: 10.0 -> "10", 5.55 -> "5,6" (German decimal comma).
static func format_number(value: float) -> String:
	var rounded: float = snappedf(value, 0.1)
	if is_equal_approx(rounded, roundf(rounded)):
		return str(roundi(rounded))
	return str(rounded).replace(".", ",")


## BBCode text in the colour of the kind.
static func colored(text: String, kind: String) -> String:
	return "[color=#%s]%s[/color]" % [get_color(kind).to_html(false), text]


## "50 % Feuer · 50 % Schnitt", each part in its colour; a single kind without percent.
static func split_text(split: Dictionary) -> String:
	if split.size() == 1:
		var only: String = split.keys()[0]
		return colored(get_display_name(only), only)
	var parts: Array[String] = []
	for kind: String in split:
		parts.append(colored("%d %% %s" % [roundi(split[kind] * 100.0), get_display_name(kind)], kind))
	return " · ".join(parts)
