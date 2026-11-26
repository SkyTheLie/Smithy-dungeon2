class_name Element
extends RefCounted
## The elements of the game (used by skills, later by staffs and enemy weaknesses).

enum Type { NONE, FIRE, WATER, EARTH, AIR, DARK, LIGHT, LIGHTNING, ICE, POISON }

const NAMES: Array[String] = ["", "Feuer", "Wasser", "Erde", "Luft", "Dunkel", "Licht", "Blitz", "Eis", "Gift"]


static func get_display_name(type: Type) -> String:
	return Language.translate(NAMES[type])


## Same colours as the damage kinds (DamageKinds.COLORS), e.g. fire orange-red, lightning blue.
static func get_color(type: Type) -> Color:
	return DamageKinds.get_color(DamageKinds.from_element(type)) if type != Type.NONE else Color.WHITE
