class_name StoryActions
extends RefCounted
## The actions of the story: what a dialogue, a story step or a side task makes happen
## (story.json "on_start", "on_end", "action", "on_complete", "recipe_actions", "item_actions"),
## written as text like "give_items:coal*5;set_flag:got_coal;advance:first_ingot".
## GameState.run_story_action passes everything on to run(); the actions change the game through
## GameState (gold, inventory, story, heroes, rent ...). Logic without a scene.
## A new action gets its line in _run_single (with a parameter after ":") or _run_special (a bare
## word); the test assets/_reference/_lib/test_story_data.gd reads both match blocks and checks
## that every action in the story data is known here.


## Runs the actions of a story dialogue (story.json "on_end" / "choices.action"), several are
## separated by ";". Besides the special ones below: "accept_quest:<id>" (data/quests/<id>.tres),
## "unlock_recipes:<id>,<id>", "unlock_molds:<mold id>,<mold id>", "set_flag:<flag>",
## "advance:<step>", "hint:<id>".
## Returns false if an action could not be done (e.g. not enough gold for the rent).
static func run(actions: String) -> bool:
	for action in actions.split(";", false):
		if not _run_single(action.strip_edges()):
			return false
	return true


static func _run_single(action: String) -> bool:
	# Everything after the first ":" (the parameter may contain ":" itself, e.g. "recipe:copper_blade").
	var parameter: String = action.substr(action.find(":") + 1) if ":" in action else ""
	match action.get_slice(":", 0):
		"accept_quest":
			var quest := SaveSystem.load_resource(GameState.QUEST_DIR + parameter + ".tres") as QuestData
			if quest == null:
				push_error("Story: quest '%s' not found in %s." % [parameter, GameState.QUEST_DIR])
				return false
			GameState.accept_quest(quest)
		"unlock_recipes":
			for recipe_id in parameter.split(",", false):
				if ContentDB.has_recipe(recipe_id.strip_edges()):
					GameState.unlock_recipe(ContentDB.recipe(recipe_id.strip_edges()))
				elif ContentDB.has_brew(recipe_id.strip_edges()) and not GameState.unlocked_recipes.has(recipe_id.strip_edges()):
					# Locked mortar brew (mortar.json "brews", "locked": true).
					GameState.unlocked_recipes.append(recipe_id.strip_edges())
					GameState.recipes_changed.emit()
		"unlock_molds":
			# Molds with their anvil recipe and the workbench recipes that become makeable.
			for mold_id in parameter.split(",", false):
				if ContentDB.has_recipe(mold_id.strip_edges()):
					GameState.unlock_mold(ContentDB.recipe(mold_id.strip_edges()))
		"set_flag":
			GameState.story.set_flag(parameter)
		"clear_flags":
			GameState.story.clear_flags(parameter.split(",", false))
		"lose_hero":
			lose_hero(StringName(parameter))
		"advance":
			GameState.story.advance(parameter)
		"hint":
			GameState.story.show_hint(parameter)
		"set_time":
			GameState.day_cycle.advance_to_hour(float(parameter))
		"hire_hero":
			var template := SaveSystem.load_resource("res://data/heroes/%s.tres" % parameter) as Hero
			if template:
				GameState.add_hero(template)
		"donate_gold":
			donate(int(parameter))
		"has_items":
			return GameState.quest_items.has_items(parameter)
		"take_items":
			return GameState.quest_items.take_items(parameter)
		"give_gold":
			GameState.add_gold(int(parameter))
		"give_items":
			GameState.give_items(parameter)
		"hand_in_set":
			return GameState.quest_items.hand_in_set(parameter)
		"set_rent":
			GameState.rent.amount_override = int(parameter)
		"story_order":
			return create_order(parameter)
		"pay_gold":
			return GameState.spend_gold(int(parameter))
		"deliver":
			return GameState.quest_items.deliver(parameter)
		"deliver_gold":
			return GameState.quest_items.deliver_gold(parameter)
		"has_gold":
			return GameState.gold >= int(parameter)
		"rent_free":
			GameState.rent.set_free(GameState.day_cycle.day, int(parameter))
		"start_adventure":
			return start_adventure(parameter)
		"travel":
			travel(parameter)
		"travel_fade":
			travel(parameter, true)
		"open_menu":
			Events.story_menu_requested.emit(parameter)
		"cutscene":
			if parameter == "fade":
				GameState.fade_blink()
			Events.cutscene_requested.emit(parameter)
		"temple_seal":
			# The storm temple (part 4): a seal into a socket of the gate, see StormTemple.
			return StormTemple.insert_seal(parameter)
		"temple_pillar":
			StormTemple.strike_pillar(int(parameter))
		"elf_defense_update":
			# Part 3: the general's verdict on the weapons for Sylvaris, see ElfDefense.
			ElfDefense.update_flags()
		"elf_defense_check":
			ElfDefense.decide()
		"ice_pillar":
			# The crown of the ice wall (part 6), see IceWall.
			IceWall.strike_pillar(int(parameter))
		"ice_mirror":
			return IceWall.place_mirror(int(parameter))
		"show_ending":
			# The end of the story: pages on a dark screen, then the actions of story.json "ending" "then".
			GameState.get_tree().root.add_child((load(GameState.ENDING_SCENE) as PackedScene).instantiate())
		"sleep_at":
			# The night ends somewhere else than in the own bed (e.g. the guest house of the elves):
			# "sleep_at:<scene path>,<spawn point>" = where the autosave of this night wakes up.
			# If that is another scene, the player wakes up there (e.g. the cage in the desert).
			var values: PackedStringArray = parameter.split(",")
			var spawn: StringName = StringName(values[1]) if values.size() > 1 else &""
			var scene: Node = GameState.get_tree().current_scene
			if scene != null and scene.scene_file_path != values[0] and ResourceLoader.exists(values[0]):
				# The HUD of the new scene shows the morning (HUD._ready), not the one of the old scene.
				GameState.sleep(values[0], spawn, false)
				GameState.travel_to(values[0], spawn)
			else:
				GameState.sleep(values[0], spawn)
		_:
			return _run_special(action)
	return true


static func _run_special(action: String) -> bool:
	match action:
		"read_rent_sign":
			GameState.story.set_flag("read_rent_sign")
			if GameState.story.step == "find_smithy":
				GameState.story.advance("visit_landlady")
		"collect_shop_gold":
			return GameState.collect_shop_gold()
		"errand_hand_over":
			# Lotte gives what she bought on the market and the change (Assistant).
			return GameState.assistant.hand_over()
		"pay_rent":
			if not GameState.spend_gold(GameState.rent.get_amount()):
				return false
			# Paid early: the next rent stays on its day; paid late: two weeks from today.
			if GameState.rent.active and GameState.day_cycle.day < GameState.rent.due_day:
				GameState.rent.paid()
			else:
				GameState.rent.start(GameState.day_cycle.day)
			GameState.story.set_flag(GameState.FIRST_RENT_FLAG)
		"buy_smithy":
			GameState.rent.buy()
			GameState.story.set_flag("smithy_owned")
		"expand_nina_shop":
			GameState.nina_shop.expand()
		"rob_player":
			rob_player()
		"sleep":
			# The night ends without the bed (e.g. keeping watch after the raid): next morning.
			GameState.sleep()
		"rent_smithy":
			if not GameState.spend_gold(GameState.rent.get_amount()):
				return false
			GameState.rent.start(GameState.day_cycle.day)
			GameState.story.set_flag("smithy_rented")
			GameState.story.advance("clean_smithy")
		"":
			pass
		_:
			push_error("Unknown story action '%s' (see GameState.run)." % action)
	return true


## Story action "rob_player" (the raid, chapter 10): thieves took everything the player left
## behind in the smithy: all gold, the whole inventory, the storage chest, the storage boxes and the loot chest (items and gold). Known
## recipes and molds stay, so do the tools the player wears and the heroes' gear.
static func rob_player() -> void:
	GameState.gold = 0
	GameState.gold_changed.emit(GameState.gold)
	for chest: Inventory in [GameState.inventory, GameState.reward_chest, GameState.storage_chest] + GameState.house.get_all_boxes():
		for slot in chest.slots:
			slot.clear()
		chest.emit_changed()
	GameState.reward_chest_gold = 0


## Story action "lose_hero:<hero id>": the hero died (Bruno in the raid, chapter 10). He leaves the
## party for good; what he wore goes into the loot chest.
static func lose_hero(hero_id: StringName) -> void:
	for hero in GameState.heroes.duplicate():
		if hero.id != hero_id:
			continue
		for stack: InventorySlot in hero.equipment.values():
			if stack and not stack.is_empty():
				GameState.put_stack_into_reward_chest(stack)
		hero.equipment.clear()
		GameState.heroes.erase(hero)
		GameState.heroes_changed.emit()


## Story action "start_adventure:<dungeon id>,<hero id>[,<hero id>]": these heroes fight the
## dungeon right away (e.g. Bruno against the rats in the mine, a dungeon that is not on the board)
## and the battle window opens. false if a hero is missing or already on an adventure.
static func start_adventure(parameter: String) -> bool:
	var values: PackedStringArray = parameter.split(",", false)
	var dungeon: DungeonData = ContentDB.dungeon(values[0].strip_edges()) if not values.is_empty() else null
	var party: Array[Hero] = []
	for hero_id in values.slice(1):
		for hero in GameState.heroes:
			if String(hero.id) == hero_id.strip_edges():
				party.append(hero)
	if dungeon == null or party.size() != values.size() - 1:
		return false
	var adventure: Adventure = GameState.start_adventure(party, dungeon)
	if adventure:
		adventure.story_started = true
		Events.adventure_view_requested.emit(adventure)
	return adventure != null


## Story action "travel:<scene path>,<spawn point>[,<only from scene>]", e.g.
## "travel:res://scenes/world/mine/mine_entrance.tscn,FromMine,mine": the player runs out of the
## mine (only if he is in it right now; the third value is a scene file name without .tscn).
## "travel_fade:..." does the same with a fade to black (e.g. the carriage ride to the capital).
static func travel(parameter: String, fade: bool = false) -> void:
	var values: PackedStringArray = parameter.split(",")
	var scene: Node = GameState.get_tree().current_scene
	if values.size() >= 3 and (scene == null or scene.scene_file_path.get_file().get_basename() != values[2]):
		return
	if not ResourceLoader.exists(values[0]):
		push_error("Story: travel to unknown scene '%s'." % values[0])
		return
	GameState.travel_to(values[0], StringName(values[1]) if values.size() >= 2 else &"", fade)


## Story action "story_order:<tag>,<item spec>,<rarity>,<days>", e.g.
## "first_customer,sword:copper_blade+copper_handle,R2,3": the customer (story figure <tag>)
## orders this item; it is in the quest log right away, handed in at the order board, and does
## not expire. Handing it in sets the flag "order_done_<tag>".
static func create_order(parameter: String) -> bool:
	var values: PackedStringArray = parameter.split(",")
	var wanted: InventorySlot = ContentDB.make_stack(values[1]) if values.size() >= 4 else null
	if wanted == null:
		push_error("Story: bad story_order '%s'." % parameter)
		return false
	var order := CustomerOrder.new()
	order.story_tag = values[0]
	order.customer_name = GameState.story.get_npc_name(values[0])
	order.appearance = Appearance.from_seed(values[0])
	order.item = wanted.item
	order.parts = wanted.components
	order.rarity = clampi(int(values[2].trim_prefix("R")) - 1, 0, Rarity.Tier.MYTHIC) as Rarity.Tier
	var steps: int = maxi(0, order.rarity - Crafting.get_base_rarity(order.item, order.parts))
	order.gold = Economy.get_order_gold(order.parts, steps, GameState.customers.get_pay_bonus())
	order.experience = Economy.get_order_experience(order.gold)
	order.deadline_day = GameState.day_cycle.day + int(values[3])
	GameState.customers.add_story_order(order)
	return true


## Story: gives away `amount` gold (all gold if there is less), see story.json. Remembered in
## last_donation.
static func donate(amount: int) -> void:
	GameState.last_donation = clampi(amount, 0, GameState.gold)
	if GameState.last_donation == 0:
		GameState.story.set_flag("donated_nothing")
	GameState.spend_gold(GameState.last_donation)
