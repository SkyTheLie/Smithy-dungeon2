class_name HeroClass
extends Resource
## A hero class (warrior, ranger ...). One .tres per class in res://data/hero_classes/.
## Which weapons a class may carry: weapon_types.json "classes" (WeaponType.allows_class).

const CLASS_PATH: String = "res://data/hero_classes/%s.tres"

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
## Color of the class name in lists and windows (warrior red, mage blue, healer white,
## ranger green; a thief would be violet).
@export var color: Color = Color.WHITE
@export_multiline var description: String = "":
	get:
		return Language.translate(description)
## Picture behind the skill tree (the class's typical weapons), see HeroWindow.
@export var skill_background: Texture2D
## Extra attribute points at level 1 on top of the start value (combat.json "start_attribute"):
## ItemAttribute.Type -> points, e.g. warrior {STRENGTH: 3}, paladin {CONSTITUTION: 2, RESISTANCE: 1}.
@export var attribute_bonuses: Dictionary = {}
## Old: skill ids of the class. The skills now come from its three trees in
## data/content/skill_trees.json (get_trees); this list is only used if the class has none there.
@export var skill_ids: Array[String] = []


## The three skill trees: [{"id": String, "name": String, "skills": Array[SkillData]}].
func get_trees() -> Array:
	var trees: Array = ContentDB.skill_trees(String(id))
	if not trees.is_empty():
		return trees
	var skills: Array[SkillData] = []
	for skill_id in skill_ids:
		var skill: SkillData = ContentDB.skill(skill_id)
		if skill:
			skills.append(skill)
	return [{"id": "main", "name": display_name, "skills": skills}]


## Every skill of all trees.
func get_skills() -> Array[SkillData]:
	var list: Array[SkillData] = []
	for tree: Dictionary in get_trees():
		list.append_array(tree["skills"])
	return list


func has_skill(skill: SkillData) -> bool:
	return get_skills().has(skill)


## Index of the tree the skill is in (-1 = none of this class).
func get_tree_index(skill: SkillData) -> int:
	var trees: Array = get_trees()
	for i in trees.size():
		if (trees[i]["skills"] as Array).has(skill):
			return i
	return -1


## The class with this id (data/hero_classes/<id>.tres), null if there is none.
static func load_class(class_id: String) -> HeroClass:
	return load(CLASS_PATH % class_id) as HeroClass if exists(class_id) else null


static func exists(class_id: String) -> bool:
	return not class_id.is_empty() and ResourceLoader.exists(CLASS_PATH % class_id)
