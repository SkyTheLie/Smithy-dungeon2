class_name QuestData
extends Resource
## A quest (order) from an NPC. One .tres per quest in res://data/quests/.
## The NPC (QuestNpc) offers it; accepted quests appear in the quest log. The player hands in
## `required_amount` items that match (`required_item_id`, optionally with `required_part_id` among
## its parts, e.g. an axe with a copper axe head) and gets the rewards.

enum State { AVAILABLE, ACTIVE, COMPLETED }

@export var title: String = "":
	get:
		return Language.translate(title)
## Who gives the quest and where he is (shown in the quest window).
@export var giver_name: String = "":
	get:
		return Language.translate(giver_name)
@export var location: String = "":
	get:
		return Language.translate(location)
## What the giver wants, for the quest window.
@export_multiline var description: String = "":
	get:
		return Language.translate(description)
## Short name of the wanted thing, e.g. "Kupferaxt".
@export var requirement_name: String = "":
	get:
		return Language.translate(requirement_name)
## Item id from items.json, e.g. "axe".
@export var required_item_id: String = ""
## Optional: this part must be in the item (e.g. copper axe head in an axe).
@export var required_part_id: String = ""
@export var required_amount: int = 1
## Story flag that must be set before the NPC offers the quest (empty = always), e.g. a follow-up
## quest (QuestNpc.follow_up_quests) only after Gustav showed the iron pickaxe.
@export var required_flag: String = ""
## Story flag set when the quest is accepted (empty = none), e.g. to put its mold up for sale.
@export var accept_flag: String = ""

@export_group("Dialog")
## What the NPC says when he offers the quest.
@export_multiline var offer_text: String = "":
	get:
		return Language.translate(offer_text)
## While the quest runs and the player has not got the item yet.
@export_multiline var reminder_text: String = "":
	get:
		return Language.translate(reminder_text)
## When the player hands it in.
@export_multiline var done_text: String = "":
	get:
		return Language.translate(done_text)
## After the quest is done.
@export_multiline var after_text: String = "":
	get:
		return Language.translate(after_text)

@export_group("Rewards")
@export var rewards: Array[QuestReward] = []
## Recipes the player needs for the quest, unlocked when he accepts it.
## Recipe ids, e.g. "mold_copper_axe_head".
@export var unlock_recipe_ids: Array[String] = []


## true if this stack can be handed in for the quest.
func matches(slot: InventorySlot) -> bool:
	if slot.is_empty() or slot.item.id != StringName(required_item_id) or slot.hot:
		return false
	if required_part_id.is_empty():
		return true
	for part in slot.components:
		if part.id == StringName(required_part_id):
			return true
	return false


func get_unlock_recipes() -> Array[RecipeData]:
	var list: Array[RecipeData] = []
	for id in unlock_recipe_ids:
		var recipe: RecipeData = ContentDB.recipe(id)
		if recipe:
			list.append(recipe)
	return list
