class_name ItemAttribute
extends Resource
## One attribute bonus of an item, e.g. "Stärke: +2".

enum Type { STRENGTH, AGILITY, CONSTITUTION, INTELLIGENCE, WISDOM, RESISTANCE }

## Display names (STR, AGI, CON, INT, WIS, RES).
const NAMES: Array[String] = ["Stärke", "Beweglichkeit", "Konstitution", "Intelligenz", "Weisheit", "Widerstand"]
## What each attribute does (tooltips; numbers from combat.json, see CombatRules).
const EFFECTS: Array[String] = [
	"Pro Punkt +0,5 Schaden bei Angriffen und Waffen-Skills (Skills je nach Anteil, siehe Skill), alle 10 Punkte +1 Leben.",
	"Pro Punkt +1 % Krit-Chance und mehr Schaden bei Bogen-, Dolch- und Natur-Skills, alle 10 Punkte +2,5 % Ausweichen.",
	"Pro Punkt +2 Leben, alle 10 Punkte +1 Leben-Regeneration.",
	"Pro Punkt +2 % Zauberschaden und +1 Mana, alle 10 Punkte +1 Mana-Regeneration.",
	"Pro Punkt +0,3 % Heil- und Schildkraft, alle 10 Punkte +2 Leben.",
	"Pro Punkt +1 auf alle Resistenzen, alle 10 Punkte +3 % Zähigkeit (kürzere Debuffs).",
]

@export var type: Type = Type.STRENGTH
@export var value: int = 1


static func create(attribute_type: Type, attribute_value: int) -> ItemAttribute:
	var attribute := ItemAttribute.new()
	attribute.type = attribute_type
	attribute.value = attribute_value
	return attribute


func get_display_name() -> String:
	return Language.translate(NAMES[type])
