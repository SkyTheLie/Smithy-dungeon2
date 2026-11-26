class_name SummonData
extends Resource
## A creature a hero calls into a fight (elementals of the mage, the ranger's wolf). Created by
## ContentDB from data/content/summons.json. A skill with "summon" calls it with a share of the
## summoner's values (SkillData.summon_share), see Combatant.from_summon and Adventure.

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
## Monster whose picture it uses (enemies.json), with its own tint / size on top.
@export var look: EnemyData
@export var tint: Color = Color.WHITE
@export var scale: float = 1.0
## Kinds of its basic hits: DamageKinds id -> share.
@export var damage_split: Dictionary = {"physical": 1.0}
## true = its basic hits are spells (from the summoner's magic damage).
@export var magic: bool = false
## Health x this, attack speed x this.
@export var health_factor: float = 1.0
@export var attack_speed: float = 1.0
## true = allies can heal and buff it (the wolf), false = they can't (elementals).
@export var buffable: bool = false
@export var skills: Array[SkillData] = []
## Effects its basic hits can apply: [{"effect": StatusEffectData, "chance": 0..1}].
@export var on_hit: Array[Dictionary] = []


## Picture for the battle stage (the look's first frame).
func get_texture() -> Texture2D:
	return look.get_frame(0) if look else null
