class_name StatusEffectData
extends Resource
## A buff or debuff (poison, bleeding, rage ...). Created by ContentDB from
## data/content/status_effects.json (format: docs/CONTENT.md). It runs for `duration`
## seconds on a fighter (see Combatant) and then expires.
## Stacking "stack": every new application adds a stack (up to max_stacks) and resets the
## duration; values per second count per stack. "refresh": only the duration starts again.
## Instant effects (cleanse, revive_percent) act once and are not added to the fighter.

enum Kind { BUFF, DEBUFF }
enum Stacking { STACK, REFRESH }

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export_multiline var description: String = "":
	get:
		return Language.translate(description)
## Small picture (16x16) for the buff list in the battle window.
@export var icon: Texture2D
@export var kind: Kind = Kind.DEBUFF
## Seconds until it runs out (a skill or item can lengthen it, see Combatant.apply_effect).
@export var duration: float = 5.0
@export var stacking: Stacking = Stacking.REFRESH
@export var max_stacks: int = 1
## Damage per second and stack (e.g. poison), of this element.
@export var damage_per_second: float = 0.0
@export var element: Element.Type = Element.Type.NONE
## Extra damage per second and stack that grows with whoever applied it: this share of his
## average spell damage (weapon magic damage x factor of `damage_attribute`, e.g. the shadow
## priest's pain: 0.25 of a spell with wisdom). 0 = only damage_per_second.
@export var damage_from_magic: float = 0.0
@export var damage_attribute: ItemAttribute.Type = ItemAttribute.Type.INTELLIGENCE
## Damage in % of the bearer's max health per second and stack (e.g. poison: 0.75).
@export var damage_percent_per_second: float = 0.0
## Damage in % of max health when it runs out (e.g. bleeding: 5).
@export var damage_percent_on_expire: float = 0.0
## Healing in % of max health per second (e.g. recovery: 3).
@export var heal_percent_per_second: float = 0.0
## Shield: absorbs damage up to this % of max health (used up = gone, see Combatant).
@export var shield_percent: float = 0.0
## Shield from the caster: absorbs level of the caster + 5 x their wisdom (combat.json
## "shield_per_caster_level", "shield_per_caster_wis"), like extra health on top.
@export var caster_shield: bool = false


func is_shield() -> bool:
	return shield_percent > 0.0 or caster_shield


## Attribute points of `caster` that make a caster_shield (shield_attributes or shield_attribute).
## `caster`: Combatant or Hero (both have get_attribute).
func get_shield_points(caster: Object) -> float:
	if shield_attributes.is_empty():
		return caster.get_attribute(shield_attribute)
	var points: float = 0.0
	for type: ItemAttribute.Type in shield_attributes:
		points += caster.get_attribute(type) * float(shield_attributes[type])
	return points


## Shield points of a caster_shield cast by `caster` (level and attributes of a Combatant).
func get_caster_shield(caster: Object) -> float:
	return CombatRules.caster_shield(caster.level, get_shield_points(caster)) * shield_factor
## While active the fighter does not regenerate health (bleeding).
@export var block_health_regen: bool = false
## Attribute multipliers, ItemAttribute.Type -> factor (e.g. rage: strength 1.1 = +10 %).
@export var attribute_multipliers: Dictionary = {}
## Resistance changes while active: DamageKinds id -> value (negative = weaker).
@export var resistances: Dictionary = {}
## Extra crit chance (0.1 = +10 %) and crit damage (0.5 = +50 %) while active.
@export var crit_chance: float = 0.0
@export var crit_damage: float = 0.0
## More (or less) damage of every hit while active (0.4 = +40 %), e.g. the bandit boss' bear blood.
@export var damage_bonus: float = 0.0
## Attack speed change while active (0.3 = 30 % faster, -0.3 = 30 % slower basic hits).
@export var attack_speed: float = 0.0
## Armor / magic resistance of the carrier changes by this share while active
## (-0.3 = 30 % less, 0.3 = 30 % more). Counted before the attacker's penetration.
@export var armor_percent: float = 0.0
@export var magic_resistance_percent: float = 0.0
## Penetration of the carrier's hits while active (CombatRules.penetration, e.g. later a buff
## "armor_percent" 0.2 = ignores 20 % armor).
@export var penetration: Dictionary = {}
## Stunned: no basic hits and no skills while active.
@export var stun: bool = false
## Taunt: while active the other side can only hit this fighter with single-target attacks
## (area skills still reach everybody), e.g. the shield bandit's "Herausfordern".
@export var taunt: bool = false
## Chance to dodge hits completely (0.3 = 30 %), while active.
@export var evasion: float = 0.0
## Part of the hit damage the fighter deals that heals him (0.3 = 30 %), while active.
@export var lifesteal: float = 0.0
## Instant: removes all debuffs from the target (the effect itself does not stay).
@export var cleanse: bool = false
## Instant: brings a fallen ally back with this % of max health (the effect does not stay).
@export var revive_percent: float = 0.0
## Instant cleanse: how many debuffs it removes (0 = all).
@export var cleanse_count: int = 0
## Damage the carrier takes changes by this share (0.15 = 15 % more, -1 = no damage at all).
@export var damage_taken: float = 0.0
## Silenced: no skills (basic hits still work).
@export var silence: bool = false
## Can't be picked as a single target (area attacks still hit), e.g. the rogue's veil.
@export var untargetable: bool = false
## Health can't drop below 1 while active.
@export var undying: bool = false
## Stuns can't reach the carrier.
@export var stun_immune: bool = false
## Attackers get this share of the hit damage back as magic damage (0.15 = 15 %).
@export var thorns: float = 0.0
## Share of the damage the carrier's allies take that the carrier takes instead (0.5 = 50 %).
@export var guard_share: float = 0.0
## Every hit of the carrier deals this share extra as `extra_damage_kind` (e.g. 0.2 light).
@export var extra_damage: float = 0.0
@export var extra_damage_kind: String = ""
## Physical / magic hit damage of the carrier changes by this share (0.1 = +10 %).
@export var physical_damage: float = 0.0
@export var magic_damage: float = 0.0
## Mana per second while active.
@export var mana_regen: float = 0.0
## Healing in % of max health when it runs out (e.g. the warrior's "Unbeugsam").
@export var heal_percent_on_expire: float = 0.0
## Every hit of the carrier puts this effect (status effect id) on the target with this chance.
@export var on_hit_effect_id: String = ""
@export var on_hit_chance: float = 0.0
## When the carrier dies, its poison and this effect jump to another fighter of its side.
@export var spread_on_death: bool = false
## Basic hits of the carrier hit every opponent.
@export var cleave: bool = false
## caster_shield: attribute of the caster instead of wisdom, and a factor on the shield.
@export var shield_attribute: ItemAttribute.Type = ItemAttribute.Type.WISDOM
@export var shield_factor: float = 1.0
## caster_shield from several attributes: ItemAttribute.Type -> weight (e.g. wisdom 1, resistance 1:
## level + 5 x (wisdom + resistance)). Empty = only shield_attribute.
@export var shield_attributes: Dictionary = {}
## Colour of the name in the battle window.
@export var color: Color = Color.WHITE
## Loop at the carrier's feet while it lasts: BattleVfx sheet "aura_<aura>" (e.g. "burn"); "" = none.
@export var aura: String = ""
## Effect when it is put on (BattleVfx kind, e.g. "cleanse"); "" = arrows up (buff) or down (debuff).
@export var apply_vfx: String = ""


func is_instant() -> bool:
	return cleanse or revive_percent > 0.0
