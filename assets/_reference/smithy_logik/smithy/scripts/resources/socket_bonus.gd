class_name SocketBonus
extends Resource
## A kind of socket bonus (data/content/sockets.json, see docs/CONTENT.md), e.g. "Wucht":
## +x % of the weapon's damage as extra blunt damage. A bonus has up to 9 levels (`levels` =
## value per level) with a chance per level (`chances`). `slots` says which equipment it can sit
## in. An item carries up to InventorySlot.MAX_SOCKETS of them (Socket = bonus + level).

## What a bonus does with its value:
##   EXTRA_DAMAGE      weapons: +value % of the damage as extra damage of `kind` (e.g. blunt)
##   DAMAGE_PERCENT    weapons: +value % damage (same kinds as before)
##   ATTRIBUTE         +value points of `attribute` (e.g. strength)
##   RESISTANCE        +value resistance against `kind` (e.g. fire)
##   ARMOR_PERCENT     +value % of the item's armor
##   MAGIC_RESISTANCE  +value magic resistance
##   CRIT_CHANCE       +value percentage points crit chance
##   CRIT_DAMAGE       +value percentage points crit damage
##   ATTACK_SPEED      weapons: +value % attack speed (shorter time between basic hits)
##   ON_HIT            weapons: value % chance that a physical hit puts the status effect `status`
##                     on the target (e.g. burn), see InventorySlot.get_socket_on_hit
##   COMBO             several bonuses at once (`combo`), each at `combo_factor` of its value, e.g.
##                     magma = fire and earth damage at 70 % each (InventorySlot.get_active_sockets)
enum Effect { EXTRA_DAMAGE, DAMAGE_PERCENT, ATTRIBUTE, RESISTANCE, ARMOR_PERCENT, MAGIC_RESISTANCE,
		CRIT_CHANCE, CRIT_DAMAGE, ATTACK_SPEED, ON_HIT, COMBO }

## JSON names of the effects.
const EFFECT_IDS: Dictionary = {
	"extra_damage": Effect.EXTRA_DAMAGE, "damage_percent": Effect.DAMAGE_PERCENT,
	"attribute": Effect.ATTRIBUTE, "resistance": Effect.RESISTANCE, "armor_percent": Effect.ARMOR_PERCENT,
	"magic_resistance": Effect.MAGIC_RESISTANCE, "crit_chance": Effect.CRIT_CHANCE,
	"crit_damage": Effect.CRIT_DAMAGE, "attack_speed": Effect.ATTACK_SPEED, "on_hit": Effect.ON_HIT,
	"combo": Effect.COMBO,
}
## Effects that need a "kind" (DamageKinds id).
const KIND_EFFECTS: Array[Effect] = [Effect.EXTRA_DAMAGE, Effect.RESISTANCE]
const MAX_LEVEL: int = 9
## Names in "slots" that stand for several item types.
const SLOT_GROUPS: Dictionary = {
	"armor_all": ["armor", "helmet", "shoulders", "boots", "gloves", "cloak", "legs"],
	"jewelry": ["necklace", "ring"],
	"hero_equipment": ["weapon", "shield", "armor", "helmet", "shoulders", "boots", "gloves", "cloak", "legs",
			"necklace", "ring"],
}
## Value texts per effect (%s = value, %s = name of the kind / attribute).
const TEXTS: Array[String] = [
	"+%s %% %s-Schaden", "+%s %% Schaden", "+%s %s", "+%s %s-Resistenz", "+%s %% Rüstung",
	"+%s Magieresistenz", "+%s %% Krit-Chance", "+%s %% Krit-Schaden", "+%s %% Angriffstempo",
	"%s %% Chance auf %s", "%s",
]

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export var effect: Effect = Effect.ATTRIBUTE
## DamageKinds id for EXTRA_DAMAGE and RESISTANCE (e.g. "blunt", "fire").
@export var kind: String = ""
## Attribute for ATTRIBUTE.
@export var attribute: ItemAttribute.Type = ItemAttribute.Type.STRENGTH
## Value per level, index 0 = level 1.
@export var levels: Array[float] = []
## Weight per level (same length as levels), e.g. [30, 20, 20, 20, 10] = 10 % level 5.
@export var chances: Array[float] = []
## Item type names (items.json "type"), "weapon:<weapon type>" or a SLOT_GROUPS name.
@export var slots: Array[String] = []
## Only given by enchanting potions (Enchanting), never rolled into a socket.
@export var enchant_only: bool = false
## ON_HIT: id of the status effect (status_effects.json).
@export var status_id: String = ""
## COMBO: the bonuses it gives together, each at combo_factor of its value.
@export var combo: Array[SocketBonus] = []
@export var combo_factor: float = 1.0


func get_max_level() -> int:
	return levels.size()


## Value at `level` (1 ... get_max_level()).
func get_value(level: int) -> float:
	return levels[clampi(level, 1, levels.size()) - 1]


## Random level by `chances`.
func roll_level() -> int:
	var total: float = 0.0
	for chance in chances:
		total += chance
	var pick: float = randf() * total
	for i in chances.size():
		pick -= chances[i]
		if pick < 0.0:
			return i + 1
	return chances.size()


## Chance of `level` in percent (for tooltips / testing).
func get_level_chance(level: int) -> float:
	var total: float = 0.0
	for chance in chances:
		total += chance
	return chances[level - 1] / total * 100.0 if total > 0.0 else 0.0


## Whether this bonus can sit in `item`.
func fits(item: ItemData) -> bool:
	if item == null:
		return false
	var type_key: String = String(ItemData.ItemType.keys()[item.type]).to_lower()
	for slot in slots:
		if slot.begins_with("weapon:"):
			if item.is_weapon() and item.weapon_type and String(item.weapon_type.id) == slot.get_slice(":", 1):
				return true
		elif type_key in SLOT_GROUPS.get(slot, [slot]):
			return true
	return false


## e.g. "+20 % Stumpf-Schaden"; `factor` scales the value (parts of a combo).
func get_effect_text(level: int, factor: float = 1.0) -> String:
	var value: String = _format(get_value(level) * factor)
	match effect:
		Effect.EXTRA_DAMAGE, Effect.RESISTANCE:
			return Language.translate(TEXTS[effect]) % [value, DamageKinds.get_display_name(kind)]
		Effect.ATTRIBUTE:
			return Language.translate(TEXTS[effect]) % [value, Language.translate(ItemAttribute.NAMES[attribute])]
		Effect.ON_HIT:
			var status: String = ContentDB.status_effect(status_id).display_name if ContentDB.has_status_effect(status_id) else status_id
			return Language.translate(TEXTS[effect]) % [value, status]
		Effect.COMBO:
			var texts: Array[String] = []
			for part in combo:
				texts.append(part.get_effect_text(mini(level, part.get_max_level()), combo_factor))
			return ", ".join(texts)
	return Language.translate(TEXTS[effect]) % value


static func _format(value: float) -> String:
	return str(roundi(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
