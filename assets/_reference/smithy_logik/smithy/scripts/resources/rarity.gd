class_name Rarity
extends RefCounted
## Item rarity tiers with display name, color, stat bonus and random attributes.
## Rarity belongs to each item stack (InventorySlot.rarity), not to the item type.
## Every material starts at R1; together with the quality 0-100 inside a tier the rarity rises
## and falls like experience (see ForgeQuality). Short names: R1 = Common ... R8 = Mythic.

enum Tier { COMMON, STURDY, FINE, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }

const NAMES: Array[String] = [
	"Gewöhnlich",
	"Solide",
	"Fein",
	"Ungewöhnlich",
	"Selten",
	"Episch",
	"Legendär",
	"Mythisch",
]

## Also the frame colour of item slots (ItemSlotUI).
const COLORS: Array[Color] = [
	Color(0.62, 0.62, 0.62), # R1 Common: grey
	Color(0.35, 0.85, 0.35), # R2 Sturdy: green
	Color(0.3, 0.55, 1.0), # R3 Fine: blue
	Color(0.72, 0.38, 1.0), # R4 Uncommon: violet
	Color(1.0, 0.6, 0.15), # R5 Rare: orange
	Color(1.0, 0.22, 0.22), # R6 Epic: red
	Color(1.0, 0.86, 0.25), # R7 Legendary: gold
	Color(1.0, 0.45, 0.85), # R8 Mythic: pink
]


## Damage (weapons) / armor (armor pieces) bonus per tier: Sturdy +2, Fine +4, ...
const STAT_BONUS_PER_TIER: int = 2
## Tier at which the first random attribute appears. Every 2 tiers another one is added.
## Each random attribute starts at +2 and grows by +2 per tier:
## Uncommon +2 | Rare +4 | Epic +6, +2 | Legendary +8, +4 | Mythic +10, +6, +2
const FIRST_ATTRIBUTE_TIER: int = 3
const ATTRIBUTE_TIER_STEP: int = 2
const ATTRIBUTE_VALUE_PER_TIER: int = 2


static func get_display_name(tier: Tier) -> String:
	return Language.translate(NAMES[tier])


static func get_color(tier: Tier) -> Color:
	return COLORS[tier]


## Flat bonus on damage / armor for this tier.
static func get_stat_bonus(tier: Tier) -> int:
	return tier * STAT_BONUS_PER_TIER


## Values of the random attributes for this tier, e.g. Epic -> [6, 2].
static func get_attribute_values(tier: Tier) -> Array[int]:
	var values: Array[int] = []
	var start_tier: int = FIRST_ATTRIBUTE_TIER
	while tier >= start_tier:
		values.append((tier - start_tier + 1) * ATTRIBUTE_VALUE_PER_TIER)
		start_tier += ATTRIBUTE_TIER_STEP
	return values


## Rolls the random attributes for an item of this tier (each attribute type at most once).
static func roll_attributes(tier: Tier) -> Array[ItemAttribute]:
	var attributes: Array[ItemAttribute] = []
	var types: Array = ItemAttribute.Type.values()
	types.shuffle()
	var values: Array[int] = get_attribute_values(tier)
	for i in mini(values.size(), types.size()):
		attributes.append(ItemAttribute.create(types[i], values[i]))
	return attributes


## "R1" ... "R8".
static func get_short_name(tier: Tier) -> String:
	return "R%d" % (tier + 1)


## Tier raised by `steps`, capped at the highest tier.
static func raise(tier: Tier, steps: int) -> Tier:
	return mini(tier + steps, Tier.MYTHIC) as Tier
