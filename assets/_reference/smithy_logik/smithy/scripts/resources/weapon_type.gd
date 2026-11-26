class_name WeaponType
extends Resource
## A kind of weapon (e.g. "Schwerter", "Zauberstäbe"). Created by ContentDB from
## res://data/content/weapon_types.json (format: docs/CONTENT.md). Stations list all weapon
## types they make as categories, even before a recipe for them exists.

## How the weapon is held. New values only at the end (JSON uses the names).
enum Hands { ONE, TWO, EITHER, LEFT }

const HAND_NAMES: Array[String] = ["Einhand", "Zweihand", "In beiden Händen haltbar", "Nur linke Hand"]

## Unique name in weapon_types.json, e.g. "sword". Weapons refer to it with "weapon_type".
@export var id: StringName
## Plural name, also the category in the station menu (e.g. "Schwerter").
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export var hands: Hands = Hands.ONE
## Station that lists this type ("workbench" or "enchanting_table").
@export var station: StringName = &"workbench"
## Attack speed factor of a hero with this weapon: 1.0 = normal (sword), 1.4 = 40 % more hits
## (dagger), 0.7 = slower, heavy weapons (two-handed sword).
@export var attack_speed: float = 1.0
## Shoots arrows (bows): each hit uses one arrow from the left hand, see Combatant.
@export var uses_arrows: bool = false
## Hero classes allowed to carry it (HeroClass ids, e.g. ["warrior", "rogue"]). Empty = all (shields).
@export var classes: Array[String] = []
## How a hero attacks with it in the battle window (FighterMotion.POSES, e.g. "swing", "thrust").
@export var attack_anim: String = "swing"
## Effect of a plain hit with it (BattleVfx kind, e.g. "hit_axe"). "" = from the pose.
@export var hit_vfx: String = ""


func get_hands_name() -> String:
	return Language.translate(HAND_NAMES[hands])


## Whether a hero of this class may carry it.
func allows_class(class_id: String) -> bool:
	return classes.is_empty() or classes.has(class_id)


## e.g. "Krieger, Paladin, Schurke" ("" = all classes).
func get_classes_text() -> String:
	var names: Array[String] = []
	for class_id in classes:
		var hero_class: HeroClass = HeroClass.load_class(class_id)
		names.append(hero_class.display_name if hero_class else class_id)
	return ", ".join(names)
