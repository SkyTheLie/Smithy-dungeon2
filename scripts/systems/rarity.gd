class_name Rarity
extends RefCounted
## Rarity R1 .. R8 with name and frame colour, taken over from Smithy
## (assets/_reference/smithy_logik/smithy/scripts/resources/rarity.gd), so items look the same as
## there: grey, green, blue, violet, orange, red, gold, pink.

## German names (keys); shown through translated_name.
const NAMES: Array[String] = ["Gewöhnlich", "Solide", "Fein", "Ungewöhnlich", "Selten", "Episch", "Legendär", "Mythisch"]

const COLORS: Array[Color] = [
	Color(0.62, 0.62, 0.62),
	Color(0.35, 0.85, 0.35),
	Color(0.3, 0.55, 1.0),
	Color(0.72, 0.38, 1.0),
	Color(1.0, 0.6, 0.15),
	Color(1.0, 0.22, 0.22),
	Color(1.0, 0.86, 0.25),
	Color(1.0, 0.45, 0.85),
]


## `tier` counts from 1 (R1) like in the data files.
static func color(tier: int) -> Color:
	return COLORS[clampi(tier, 1, COLORS.size()) - 1]


## Translated name, e.g. "Solide (R2)".
static func label(tier: int) -> String:
	var index: int = clampi(tier, 1, NAMES.size())
	return "%s (R%d)" % [translated_name(index), index]


## Written out one by one so the translation script (build_po.py) finds every name.
static func translated_name(tier: int) -> String:
	match clampi(tier, 1, NAMES.size()):
		1: return Language.translate("Gewöhnlich")
		2: return Language.translate("Solide")
		3: return Language.translate("Fein")
		4: return Language.translate("Ungewöhnlich")
		5: return Language.translate("Selten")
		6: return Language.translate("Episch")
		7: return Language.translate("Legendär")
	return Language.translate("Mythisch")
