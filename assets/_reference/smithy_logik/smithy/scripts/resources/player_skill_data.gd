class_name PlayerSkillData
extends Resource
## A skill of the player (blacksmith). One .tres per skill in res://data/player_skills/,
## all of them listed in data/player_skills/skill_tree.tres.
## Every rank changes one player value (`stat`) by `value_per_rank`.
## With `achievement` the skill is not learned with skill points: its rank is the level of that
## achievement (e.g. "Pflanzen pflücken": first harvest = rank 1, 1000 harvests = rank 5).

@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export_multiline var description: String = "":
	get:
		return Language.translate(description)
@export var icon: Texture2D
## Value this skill changes (see PlayerStats.Stat).
@export var stat: PlayerStats.Stat = PlayerStats.Stat.GREEN_ZONE
## Change per learned rank, e.g. 0.01 = +1 % zone width, -1 = one strike less.
@export var value_per_rank: float = 0.01
## Added once from rank 1 on, before the ranks: value = base_value + value_per_rank × rank
## (e.g. "Feuerprobe" 0.1 + 0.05 per rank = 15 / 20 / 25 %). 0 = only the ranks.
@export var base_value: float = 0.0
@export var max_rank: int = 1
## Player level needed to learn the first rank.
@export var required_level: int = 1
## Player levels every further rank needs on top (Meisterhand: 10, then 15, then 20). 0 = none.
@export var level_per_rank: int = 0
## Story flag needed before it can be learned (e.g. "lotte_errands"), "" = none. Until then
## the skill tree shows `flag_hint`.
@export var required_flag: String = ""
@export var flag_hint: String = "":
	get:
		return Language.translate(flag_hint)
## Achievement id (achievements.json) whose level is the rank. Empty = learned with skill points.
@export var achievement: String = ""


## Player level needed to learn the rank after `rank` (0 = the first one).
func get_required_level(rank: int) -> int:
	return required_level + level_per_rank * maxi(rank, 0)
