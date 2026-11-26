class_name DamageType
extends RefCounted
## Physical damage types of weapons: stab (spear), blunt (hammer), slash (sword).
## Shown in the tooltip; enemy resistances come later.

enum Type { NONE, STAB, BLUNT, SLASH }

const NAMES: Array[String] = ["", "Stich", "Stumpf", "Schnitt"]


static func get_display_name(type: Type) -> String:
	return Language.translate(NAMES[type])
