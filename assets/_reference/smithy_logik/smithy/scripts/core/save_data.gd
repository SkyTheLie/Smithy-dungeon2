class_name SaveData
extends RefCounted
## What a save file holds: collects the whole game state from GameState and its systems (collect)
## and puts a loaded one back (apply). The file itself is written and read by SaveSystem; GameState
## decides when (save_game, load_game, the autosave in bed, "Neues Spiel" = apply of an empty save).
## Every system saves itself with to_save_data() / load_save_data(); here is the list of them, the
## order of loading and everything that converts older saves ("Older saves: ..." below).
## A new field of GameState that changes during the game belongs into both functions; the test
## assets/_reference/_lib/test_save_roundtrip.gd compares a whole save before and after loading.


static func collect() -> Dictionary:
	var hero_data: Array = []
	for hero in GameState.heroes:
		hero_data.append(hero.to_save_data())
	var adventure_data: Array = []
	for adventure in GameState.adventures:
		if not adventure is ArenaDuel:
			adventure_data.append(adventure.to_save_data())
	var destinations: Array = []
	for destination in GameState.known_destinations:
		destinations.append(str(destination))
	return {
		"gold": GameState.gold,
		"play_time": roundi(GameState.play_time),
		"forge_heat": GameState.forge_heat,
		"forge_heat_carry": GameState.forge_heat_carry,
		"forge_fuel": GameState.forge_fuel.to_save_data(),
		"ingot_choice": GameState.ingot_choice.to_save_data(),
		"known_destinations": destinations,
		"unlocked_recipes": GameState.unlocked_recipes.duplicate(),
		"recipes_locked": true,
		"day_cycle": GameState.day_cycle.to_save_data(),
		"inventory": GameState.inventory.to_save_data(),
		"trash": GameState.trash.to_save_data(),
		"buyback": GameState.buyback.to_save_data(),
		"buyback_price": GameState.buyback_price,
		"admin_all_dungeons": GameState.admin_all_dungeons,
		"smelter": GameState.smelter.to_save_data(),
		"extra_smelters": GameState.get_extra_smelters_save_data(),
		"alloy_smelter": GameState.alloy_smelter.to_save_data(),
		"quencher": GameState.quencher.to_save_data(),
		"player": GameState.player_stats.to_save_data(),
		"heroes": hero_data,
		"adventures": adventure_data,
		"resource_fields": GameState.resource_fields.to_save_data(),
		"reward_chest": GameState.reward_chest.to_save_data(),
		"reward_chest_gold": GameState.reward_chest_gold,
		"last_donation": GameState.last_donation,
		"last_shop_payout": GameState.last_shop_payout,
		"quencher_returns_when_cool": GameState.quencher_returns_when_cool,
		"storage_chest": GameState.storage_chest.to_save_data(),
		"nina_shop": GameState.nina_shop.to_save_data(),
		"merchant_stock": GameState.merchant_stock.to_save_data(),
		"gambling_den": GameState.gambling_den.to_save_data(),
		"house": GameState.house.to_save_data(),
		"daily_rewards": GameState.daily_rewards.duplicate(true),
		"quest_states": GameState.quest_states.duplicate(),
		"quest_log": GameState.quest_log.duplicate(),
		"customers": GameState.customers.to_save_data(),
		"player_appearance": GameState.player_appearance.to_save_data(),
		"player_name": GameState.player_name,
		"story": GameState.story.to_save_data(),
		"story_step_day": GameState.story_step_day,
		"rent": GameState.rent.to_save_data(),
		"garden": GameState.garden.to_save_data(),
		"achievements": GameState.achievements.to_save_data(),
		"rare_drops": GameState.rare_drops.to_save_data(),
		"day_report": GameState.day_report.to_save_data(),
		"search_orders": GameState.search_orders.to_save_data(),
		"assistant": GameState.assistant.to_save_data(),
		"story_order_gold": GameState.story_order_gold.duplicate(),
		"fame": GameState.fame.to_save_data(),
		"reputation": GameState.reputation.to_save_data(),
		"tournament": GameState.tournament.to_save_data(),
		"ranking": GameState.ranking.to_save_data(),
		"desert": GameState.desert.to_save_data(),
		"class_unlock_days": GameState.class_unlock_days.duplicate(),
		"best_rarities": GameState.best_rarities.duplicate(),
		"lexicon": GameState.lexicon.to_save_data(),
		"collection": GameState.collection.to_save_data(),
		"tower": GameState.tower.to_save_data(),
		"owned_outfits": GameState.owned_outfits.duplicate(),
	}


static func apply(data: Dictionary) -> void:
	GameState.gold = int(data.get("gold", 0))
	GameState.play_time = float(data.get("play_time", 0))
	GameState.best_rarities = (data.get("best_rarities", {}) as Dictionary).duplicate()
	GameState.forge_heat = int(data.get("forge_heat", 0))
	GameState.forge_heat_carry = float(data.get("forge_heat_carry", 0.0))
	GameState.forge_fuel = InventorySlot.from_save_data(data.get("forge_fuel", {}))
	GameState.ingot_choice.load_save_data(data.get("ingot_choice", []))
	GameState.known_destinations = GameState.START_DESTINATIONS.duplicate()
	for destination: String in data.get("known_destinations", []):
		if not GameState.known_destinations.has(StringName(destination)):
			GameState.known_destinations.append(StringName(destination))
	GameState.unlocked_recipes.clear()
	# Recipe ids (older saves: resource paths, ContentDB converts them).
	for value: String in data.get("unlocked_recipes", []):
		GameState.unlocked_recipes.append(ContentDB.normalize_id(value))
	# Saves from before "new games know no recipes": keep the recipes that used to be known from the start.
	if not data.has("recipes_locked"):
		GameState._unlock_recipe_ids(Story.get_data("legacy_recipes"))
	# Saves from before mold sets (e.g. a chest plate mold without the chest armor): add the sets.
	GameState._unlock_assembly_recipes()
	GameState.day_cycle.load_save_data(data.get("day_cycle", {}))
	GameState.inventory.load_save_data(data.get("inventory", []))
	GameState.trash = InventorySlot.from_save_data(data.get("trash", {}))
	GameState.trash_changed.emit()
	GameState.buyback = InventorySlot.from_save_data(data.get("buyback", {}))
	GameState.buyback_price = int(data.get("buyback_price", 0))
	GameState.admin_all_dungeons = bool(data.get("admin_all_dungeons", false))
	GameState.smelter.load_save_data(data.get("smelter", {}))
	GameState.load_extra_smelters(data.get("extra_smelters", []))
	GameState.alloy_smelter.load_save_data(data.get("alloy_smelter", {}))
	GameState.quencher.load_save_data(data.get("quencher", {}))
	GameState.player_stats.load_save_data(data.get("player", {}))
	GameState.resource_fields.load_save_data(data.get("resource_fields", {}))
	GameState.reward_chest.load_save_data(data.get("reward_chest", []))
	# Older saves had 5 columns: fill up to full rows of 6 (at least 6x5).
	GameState.reward_chest.resize(maxi(ceili(GameState.reward_chest.slots.size() / float(GameState.REWARD_CHEST_ROW)) * GameState.REWARD_CHEST_ROW, GameState.REWARD_CHEST_SIZE))
	GameState.reward_chest_gold = int(data.get("reward_chest_gold", 0))
	GameState.last_donation = int(data.get("last_donation", 0))
	GameState.last_shop_payout = int(data.get("last_shop_payout", 0))
	GameState.quencher_returns_when_cool = bool(data.get("quencher_returns_when_cool", false))
	GameState.storage_chest.load_save_data(data.get("storage_chest", []))
	GameState.update_inventory_size()
	# Tools that no longer fit their slot (weapon axes in the axe slot): into the bag, else the chest.
	for stack in GameState.player_stats.take_misplaced_tools():
		var left: int = GameState.inventory.add_stack(stack)
		if left > 0:
			stack.amount = left
			GameState.storage_chest.add_stack(stack)
	# Older saves: Aurelius' book still lies in the bag; it moves into the book slot.
	for i in GameState.inventory.slots.size():
		var slot: InventorySlot = GameState.inventory.slots[i]
		if not slot.is_empty() and GameState._put_into_book_slot(slot.copy_with_amount(1)):
			GameState.inventory.remove_from_slot(i, 1)
	GameState.nina_shop.load_save_data(data.get("nina_shop", {}))
	GameState.merchant_stock.load_save_data(data.get("merchant_stock", {}))
	GameState.gambling_den.load_save_data(data.get("gambling_den", {}))
	GameState.house.load_save_data(data.get("house", {}))
	# Saves from before: the bought forge sign lay in the bag; it belongs in the storage outside.
	GameState.house.forge_sign.take_from_inventory(GameState.inventory)
	# Wares whose place no longer exists (fewer places than in the save): into the loot chest.
	for stack in GameState.nina_shop.take_overflow() + GameState.house.shop.take_overflow():
		GameState.put_stack_into_reward_chest(stack)
	GameState.daily_rewards.clear()
	for reward: Dictionary in data.get("daily_rewards", []):
		GameState.daily_rewards.append(reward)
	GameState.quest_states.clear()
	var saved_states: Dictionary = data.get("quest_states", {})
	for path: String in saved_states:
		if ResourceLoader.exists(path):
			GameState.quest_states[path] = int(saved_states[path])
	GameState.quest_log.clear()
	for path: String in data.get("quest_log", []):
		if ResourceLoader.exists(path):
			GameState.quest_log.append(path)
	GameState.customers.load_save_data(data.get("customers", {}))
	GameState.player_appearance = Appearance.from_save_data(data.get("player_appearance", {}))
	GameState.player_name = str(data.get("player_name", ""))
	# Saves from before the story: the smithy is theirs already.
	if data.has("story"):
		GameState.story.load_save_data(data["story"])
		GameState.story_step_day = int(data.get("story_step_day", GameState.day_cycle.day))
		GameState._complete_bought_sets()
	else:
		GameState._complete_story()
	GameState._lock_early_compass_molds()
	# Saves that knew an armor mold before "recipe_actions" existed get the side task too.
	GameState._run_recipe_actions()
	GameState.rent.load_save_data(data.get("rent", {}))
	GameState.garden.load_save_data(data.get("garden", {}))
	# Saves from before the plant pots: what grew in the old beds comes back as seeds.
	for seed_id: String in GameState.garden.legacy_seeds:
		GameState.give_items(seed_id)
	GameState.garden.legacy_seeds.clear()
	GameState.achievements.load_save_data(data.get("achievements", {}))
	GameState.rare_drops.load_save_data(data.get("rare_drops", {}))
	GameState.fame.load_save_data(data.get("fame", {}))
	GameState.search_orders.load_save_data(data.get("search_orders", []))
	GameState.assistant.load_save_data(data.get("assistant", {}))
	GameState.story_order_gold = data.get("story_order_gold", {}).duplicate()
	if data.has("day_report"):
		GameState.day_report.load_save_data(data["day_report"])
	else:
		GameState.day_report.start(GameState.achievements)
	GameState.reputation.load_save_data(data.get("reputation", {}), GameState.customers.legacy_karma)
	GameState.tournament.load_save_data(data.get("tournament", {}))
	GameState.ranking.load_save_data(data.get("ranking", {}))
	GameState.hero_tournament.reset(true)
	GameState.desert.load_save_data(data.get("desert", {}))
	GameState.heroes.clear()
	for saved_hero: Dictionary in data.get("heroes", []):
		var hero: Hero = Hero.from_save_data(saved_hero)
		if hero:
			GameState.heroes.append(hero)
	# Running adventures go on at their saved stage (the fight of that stage starts fresh).
	GameState.adventures.clear()
	for saved_adventure: Dictionary in data.get("adventures", []):
		# Older saves name the dungeon by its .tres path (res://data/dungeons/<id>.tres).
		var dungeon_id: String = str(saved_adventure.get("dungeon", "")).get_file().get_basename()
		var dungeon: DungeonData = ContentDB.dungeon(dungeon_id) if not dungeon_id.is_empty() else null
		# Older saves have one "hero", newer ones a list "heroes".
		var ids: Array = saved_adventure.get("heroes", [saved_adventure.get("hero", "")])
		var party: Array[Hero] = []
		for id: Variant in ids:
			for hero in GameState.heroes:
				if str(hero.id) == str(id):
					party.append(hero)
		if dungeon and not party.is_empty():
			var adventure: Adventure = GameState.start_adventure(party, dungeon, int(saved_adventure.get("power", 1)), true)
			if adventure:
				adventure.load_progress(saved_adventure)
	GameState._load_lexicon(data.get("lexicon", {}))
	GameState._load_collection(data.get("collection", {}))
	GameState.tower.load_save_data(data.get("tower", {}))
	GameState.owned_outfits.assign((data.get("owned_outfits", []) as Array).map(func(id: Variant) -> String: return str(id)))
	GameState.sync_tower_start()
	GameState.wake_up_text = ""
	GameState.wake_up_report = ""
	GameState._stamina_hour_key = -1
	GameState.gold_changed.emit(GameState.gold)
	GameState.forge_heat_changed.emit(GameState.get_forge_heat())
	GameState.heroes_changed.emit()
	GameState.recipes_changed.emit()
	GameState.quests_changed.emit()
