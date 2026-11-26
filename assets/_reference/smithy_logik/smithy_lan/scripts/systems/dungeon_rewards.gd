class_name DungeonRewards
extends RefCounted
## What a finished dungeon brings: gold, PEXP, loot into the loot chest, recipes and molds after a
## win; a share of the monster loot and of the PEXP after a defeat. Counts the win for the
## achievements (which also opens the next hard mode). The numbers are written into the adventure
## (reward_gold, reward_experience, reward_items, unlocked_recipes, loot) for the battle window.
## GameState calls give() when an adventure ends; arena duels bring nothing and never get here.
## Logic without a scene; it changes the game through GameState.


## Gives the rewards of `adventure` (won or lost).
static func give(victory: bool, adventure: Adventure) -> void:
	if victory:
		give_victory(adventure)
	else:
		give_defeat(adventure)


## Won dungeon: every reward has its own chance, a hard mode multiplies them.
static func give_victory(adventure: Adventure) -> void:
	var dungeon: DungeonData = adventure.dungeon
	var hard: Dictionary = adventure.hard_mode
	# Story items only on the first win (is_loot_unlocked): decided before this win is counted.
	var first_win: bool = not dungeon.was_won(GameState.achievements.counters)
	GameState.achievements.count("dungeon")
	GameState.achievements.count("dungeon:" + String(adventure.dungeon.id))
	# A won hard mode opens the next one (DungeonData.get_max_power).
	if adventure.power > 1:
		GameState.achievements.count(adventure.dungeon.get_win_counter(adventure.power))
	# Every reward has its own chance (a run can bring nothing, only EXP, ...); a hard mode
	# multiplies gold, PEXP and the amounts of the reward items.
	adventure.reward_gold = roundi(DungeonData.roll_amount(dungeon.reward_gold) * float(hard["gold_factor"]))
	GameState.add_gold(adventure.reward_gold)
	# Finishing a dungeon levels the player (PEXP); the heroes level only from their kills.
	adventure.reward_experience = roundi(DungeonData.roll_amount(dungeon.reward_experience) * float(hard["exp_factor"]))
	GameState.player_stats.add_experience(adventure.reward_experience)
	# Loot goes into the reward chest, so nothing is lost when the inventory is full.
	adventure.reward_items = dungeon.roll_reward_items(float(hard["drop_factor"]))
	for item: ItemData in adventure.reward_items.keys():
		if not (GameState.is_loot_unlocked(item, dungeon) or (first_win and item.story_item)):
			adventure.reward_items.erase(item)
	for item: ItemData in adventure.reward_items:
		# Ore and ingots are sometimes rarer (ForgeQuality.roll_loot_rarity), in a hard mode more often.
		# A hard mode with "rarity_shift" lifts it further (×3: R2 is the least, R3 comes often).
		var rarity: int = ForgeQuality.roll_loot_rarity(item, dungeon.level, float(hard["rarity_factor"]))
		if int(hard["rarity_shift"]) > 0:
			rarity = DungeonData.shift_rarity(item, item.base_rarity if rarity < 0 else rarity, int(hard["rarity_shift"]))
		GameState.put_into_reward_chest(item, adventure.reward_items[item], rarity)
	# Loot dropped by the monsters (with their rarity); coin purses become gold.
	for stack in adventure.loot:
		if stack.item.purse_gold.size() >= 2:
			for i in stack.amount:
				GameState.put_gold_into_reward_chest(randi_range(stack.item.purse_gold[0], stack.item.purse_gold[1]))
		else:
			GameState.put_stack_into_reward_chest(stack)
	for recipe in dungeon.get_reward_recipes():
		if GameState.unlock_recipe(recipe):
			adventure.unlocked_recipes.append(recipe)
	if not dungeon.random_mold_material.is_empty() and GameState.is_metal_unlocked(dungeon.random_mold_material) 				and randf() < dungeon.random_mold_chance:
		var molds: Array[RecipeData] = GameState.get_unknown_molds(dungeon.random_mold_material)
		if not molds.is_empty():
			adventure.unlocked_recipes.append_array(GameState.unlock_mold(molds.pick_random()))


## Lost dungeon: not nothing. Each piece of the monster loot comes along with combat.json
## "defeat_loot_share" (purses as gold), and the player gets that share of the dungeon's PEXP.
## adventure.loot keeps only what was saved.
static func give_defeat(adventure: Adventure) -> void:
	var share: float = ContentDB.combat_value("defeat_loot_share", 0.3)
	var saved: Array[InventorySlot] = []
	for stack in adventure.loot:
		var kept: int = 0
		for i in stack.amount:
			if randf() < share:
				kept += 1
		if kept == 0:
			continue
		var part: InventorySlot = stack.copy_with_amount(kept)
		saved.append(part)
		if part.item.purse_gold.size() >= 2:
			for i in kept:
				GameState.put_gold_into_reward_chest(randi_range(part.item.purse_gold[0], part.item.purse_gold[1]))
		else:
			GameState.put_stack_into_reward_chest(part)
	adventure.loot = saved
	adventure.reward_experience = roundi(DungeonData.roll_amount(adventure.dungeon.reward_experience)
			* ContentDB.combat_value("defeat_experience_share", 0.3))
	GameState.player_stats.add_experience(adventure.reward_experience)
