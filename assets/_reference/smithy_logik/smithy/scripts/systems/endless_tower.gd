class_name EndlessTower
extends RefCounted
## The endless tower after the end of the story (dungeon board, tab "Turm"; the dungeon itself is
## a TowerDungeon): the best floor ever reached ("Bestmarke: Etage 47"), where the next run starts
## (the last checkpoint, every "checkpoint_every" floors) and what a run brings (finish):
##   - every floor cleared: "exp_per_floor" PEXP, and the monsters' loot (all of it, a run always
##     ends with the heroes falling or being called back)
##   - every "checkpoint_every"-th floor reached for the first time a special reward
##     ("milestone": gold × the milestone's number, ingots of the best metal the story has reached,
##     rarer with every milestone, and a random unknown mold)
## Numbers: dungeons.json, entry of the tower, "tower". Lives in GameState.tower, saved.

## Highest floor ever cleared.
var best_floor: int = 0
## Highest milestone floor whose reward was paid (10, 20 ...).
var paid_milestone: int = 0


static func get_settings(dungeon: DungeonData) -> Dictionary:
	return (dungeon as TowerDungeon).settings if dungeon is TowerDungeon else {}


## First floor of the next run: the floor after the last checkpoint reached (best 47 -> 41).
func get_start_floor(dungeon: DungeonData) -> int:
	var every: int = maxi(1, int(get_settings(dungeon).get("checkpoint_every", 10)))
	return floori(best_floor / float(every)) * every + 1


## Floors a finished run cleared: up to the one before the floor it ended on (a win can't happen).
static func get_cleared_floor(adventure: Adventure) -> int:
	return adventure.stage if adventure.state == Adventure.State.VICTORY else adventure.stage - 1


## A run ended: new best, PEXP, loot into the loot chest, milestone rewards (all through `state`,
## GameState). Writes reward_gold / reward_experience / reward_items into the adventure for the
## battle window and returns the lines for the message.
func finish(adventure: Adventure, state: Node) -> Array[String]:
	var settings: Dictionary = get_settings(adventure.dungeon)
	var cleared: int = get_cleared_floor(adventure)
	var climbed: int = maxi(0, cleared - adventure.first_stage + 1)
	var lines: Array[String] = []
	if cleared > best_floor:
		best_floor = cleared
		lines.append(Language.translate("Neue Bestmarke im Endlosen Turm: Etage %d!") % best_floor)
	state.achievements.raise_to("tower", best_floor)
	adventure.reward_experience = climbed * int(settings.get("exp_per_floor", 0))
	state.player_stats.add_experience(adventure.reward_experience)
	for stack: InventorySlot in adventure.loot:
		if stack.item.purse_gold.size() >= 2:
			for i in stack.amount:
				state.put_gold_into_reward_chest(randi_range(stack.item.purse_gold[0], stack.item.purse_gold[1]))
		else:
			state.put_stack_into_reward_chest(stack)
	var every: int = maxi(1, int(settings.get("checkpoint_every", 10)))
	while paid_milestone + every <= best_floor:
		paid_milestone += every
		lines.append(_pay_milestone(paid_milestone / every, adventure, settings, state))
	return lines


## The special reward of the `number`-th checkpoint (floor 10 = 1, floor 20 = 2 ...).
func _pay_milestone(number: int, adventure: Adventure, settings: Dictionary, state: Node) -> String:
	var milestone: Dictionary = settings.get("milestone", {})
	var gold: int = int(milestone.get("gold", 0)) * number
	adventure.reward_gold += gold
	state.add_gold(gold)
	var parts: Array[String] = [Language.translate("%d Gold") % gold]
	var metal: String = _best_metal(state)
	var ingot_id: String = ContentDB.material_ingot(metal) if not metal.is_empty() else ""
	var ingots: int = int(milestone.get("ingots", 0))
	if not ingot_id.is_empty() and ingots > 0:
		var from: int = int(str(milestone.get("rarity_from", "R3")).trim_prefix("R")) - 1
		var rarity: int = mini(from + number - 1, Rarity.Tier.MYTHIC)
		var ingot: ItemData = ContentDB.item(ingot_id)
		state.put_into_reward_chest(ingot, ingots, rarity)
		adventure.reward_items[ingot] = int(adventure.reward_items.get(ingot, 0)) + ingots
		parts.append("%d× %s (%s)" % [ingots, ingot.display_name, Rarity.get_display_name(rarity as Rarity.Tier)])
	if milestone.get("mold", false):
		var unknown: Array[RecipeData] = state.get_unknown_molds(metal) if not metal.is_empty() else ([] as Array[RecipeData])
		if not unknown.is_empty():
			var mold: RecipeData = unknown.pick_random()
			adventure.unlocked_recipes.append_array(state.unlock_mold(mold))
			parts.append(Language.translate("eine neue Gussform"))
	return Language.translate("Endloser Turm, Etage %d: %s") % [number * maxi(1, int(settings.get("checkpoint_every", 10))), ", ".join(parts)]


## The highest cast metal the story has reached ("" = none).
static func _best_metal(state: Node) -> String:
	var best: String = ""
	for metal: String in ContentDB.get_cast_metals():
		if state.is_metal_unlocked(metal):
			best = metal
	return best


func to_save_data() -> Dictionary:
	return {"best_floor": best_floor, "paid_milestone": paid_milestone}


func load_save_data(data: Dictionary) -> void:
	best_floor = int(data.get("best_floor", 0))
	paid_milestone = int(data.get("paid_milestone", 0))
