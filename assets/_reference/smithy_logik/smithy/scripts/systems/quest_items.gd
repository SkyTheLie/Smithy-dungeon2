class_name QuestItems
extends RefCounted
## Everything about things the player has to own or hand in for the story, side tasks and quests:
## "is this piece like the wanted one", counting, taking, sets (set_items), handing in bit by bit
## (deliver), the hand-in slots of dialogues and the shopping list of a story step.
## Lives in GameState.quest_items; GameState keeps the old names (has_items, take_items, deliver,
## get_set_progress ...) and passes them on. Logic without a scene; it reads the player's things
## from GameState (inventory, equipped tools, heroes, gold) and the story (flags, side tasks,
## delivered amounts).
##
## Hand-in: while run_with_hand_in() runs, counting and taking only see the stacks lying in the
## hand-in slots of the dialogue, not the inventory.

## Stacks in the hand-in slots while a hand-in runs (run_with_hand_in). Not saved on purpose: it
## only lives during one call.
var _hand_in: Array[InventorySlot] = []
var _hand_in_active: bool = false


## Progress of a side task's set: one entry per wanted item type (story.json "set_items": item
## type -> shown name, e.g. {"weapon": "Waffe", "helmet": "Helm"}) of the material "set_material"
## (e.g. "copper"): [{"name", "have"}].
## Counts cooled pieces in the inventory and on the heroes; each piece needs a part of that metal.
## With "hand_in" (the pieces are handed to someone, see hand_in_set) "given" says whether that
## piece was handed in already: [{"name", "type", "have", "given"}].
func get_set_progress(task: Dictionary) -> Array[Dictionary]:
	var owned: Array[InventorySlot] = GameState.inventory.slots.duplicate()
	for hero in GameState.heroes:
		for stack: InventorySlot in hero.equipment.values():
			owned.append(stack)
	var progress: Array[Dictionary] = []
	var wanted: Dictionary = task.get("set_items", {})
	for type_key: String in wanted:
		var have: bool = owned.any(func(stack: InventorySlot) -> bool: return is_set_piece(task, type_key, stack))
		progress.append({"name": wanted[type_key], "type": type_key, "have": have,
				"given": GameState.story.has_flag(_set_given_flag(task, type_key))})
	return progress


## Story action "hand_in_set:<side task id>": the player hands every piece of the set that is in
## the inventory and was not handed in yet (one per type). Once all are handed in, the side task's
## "complete_flag" is set. Returns false if nothing could be handed in.
func hand_in_set(task_id: String) -> bool:
	var task: Dictionary = GameState.story.get_side_task(task_id)
	var handed: bool = false
	for type_key: String in task.get("set_items", {}):
		var flag: String = _set_given_flag(task, type_key)
		if GameState.story.has_flag(flag):
			continue
		if _hand_in_active:
			for stack in _hand_in:
				if is_set_piece(task, type_key, stack):
					_take_from_hand_in(stack, 1)
					GameState.story.set_flag(flag)
					handed = true
					break
			continue
		for i in GameState.inventory.slots.size():
			if is_set_piece(task, type_key, GameState.inventory.slots[i]):
				GameState.inventory.remove_from_slot(i, 1)
				GameState.story.set_flag(flag)
				handed = true
				break
	if get_set_progress(task).all(func(entry: Dictionary) -> bool: return entry["given"]):
		GameState.story.set_flag(task.get("complete_flag", task.get("done_flag", "")))
	return handed


## Flag that remembers a handed-in set piece, e.g. "copper_set_given_helmet".
func _set_given_flag(task: Dictionary, type_key: String) -> String:
	return "%s_given_%s" % [task.get("id", ""), type_key]


## Whether `stack` is a cooled piece of item type `type_key` (e.g. "helmet") or of that item id
## (e.g. "sword") with a part of the task's "set_material", at least of the task's
## "set_min_rarity" (e.g. "R5", default R1).
func is_set_piece(task: Dictionary, type_key: String, stack: InventorySlot) -> bool:
	if stack == null or stack.is_empty() or stack.hot:
		return false
	if stack.rarity < int(str(task.get("set_min_rarity", "R1")).trim_prefix("R")) - 1:
		return false
	var metal: String = ContentDB.material_name(task.get("set_material", ""))
	return (stack.item.type == ItemData.ItemType.keys().find(type_key.to_upper()) or String(stack.item.id) == type_key) \
			and stack.components.any(func(part: ItemData) -> bool: return part.material_name == metal)


## true if the inventory (or a tool slot) has the item of `spec` with exactly these parts
## (any rarity, cooled).
func has_stack_like(spec: String) -> bool:
	var wanted: InventorySlot = ContentDB.make_stack(spec)
	return wanted != null and count_like(wanted) > 0


## Whether `slot` is the thing `wanted` stands for: same item, same parts (if the spec names
## parts), cooled.
func is_like(slot: InventorySlot, wanted: InventorySlot) -> bool:
	if slot == null or slot.is_empty() or slot.hot or slot.item != wanted.item:
		return false
	if wanted.has_meta(ContentDB.MIN_RARITY_META):  # "@R4+": high enough, the named parts match
		return slot.rarity >= wanted.rarity 				and slot.components.slice(0, wanted.components.size()) == wanted.components
	return wanted.components.is_empty() or slot.components == wanted.components


## How many pieces like `wanted` the player has: inventory plus equipped tools.
func count_like(wanted: InventorySlot) -> int:
	var count: int = 0
	if _hand_in_active:
		for stack in _hand_in:
			if is_like(stack, wanted):
				count += stack.amount
		return count
	for slot in GameState.inventory.slots:
		if is_like(slot, wanted):
			count += slot.amount
	for tool_slot in PlayerStats.ToolSlot.values():
		if is_like(GameState.player_stats.get_tool(tool_slot), wanted):
			count += 1
	return count


## Story action "has_items:<spec>,<spec>" (e.g. "coal*5,pickaxe:copper_pickaxe_head+wooden_shaft").
func has_items(specs: String) -> bool:
	for spec in specs.split(",", false):
		var wanted: InventorySlot = ContentDB.make_stack(spec)
		if wanted == null or count_like(wanted) < wanted.amount:
			return false
	return true


## How many of each thing in `specs` the player has: [{"name", "have", "need"}] (quest log).
## With `task_id` what was handed in for that side task already (deliver) counts along.
func get_item_progress(specs: String, task_id: String = "") -> Array[Dictionary]:
	var progress: Array[Dictionary] = []
	for spec in specs.split(",", false):
		var wanted: InventorySlot = ContentDB.make_stack(spec)
		if wanted:
			var have: int = count_like(wanted) + GameState.story.get_delivered(task_id, spec)
			var name: String = wanted.get_display_name()
			if wanted.has_meta(ContentDB.MIN_RARITY_META):
				name += Language.translate(" (ab %s)") % Rarity.get_display_name(wanted.rarity)
			progress.append({"name": name, "have": mini(have, wanted.amount),
					"need": wanted.amount})
	return progress


## Checklist of a side task (story.json "todo"): [{"name", "done", "have"/"need" for items}].
## An entry with "items" counts what the player has (like show_items), one with "flag" is done
## once the flag is set. A later flag entry that is done ticks off everything before it (the
## herbs are gone once the potion is brewed), so does the finished task. Entries with "own": true
## (things collected in any order, e.g. the four compass molds) tick off only themselves.
func get_todo_progress(task: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for todo: Dictionary in task.get("todo", []):
		if todo.has("items"):
			for entry in get_item_progress(todo["items"]):
				entry["done"] = entry["have"] >= entry["need"]
				entries.append(entry)
		else:
			entries.append({"name": todo.get("name", ""), "done": GameState.story.has_flag(todo.get("flag", "")),
					"own": bool(todo.get("own", false))})
	var later_done: bool = GameState.story.has_flag(task.get("done_flag", "@"))
	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		if later_done:
			entry["done"] = true
			if entry.has("need"):
				entry["have"] = entry["need"]
		elif entry["done"] and not entry.has("need") and not entry.get("own", false):
			later_done = true
	return entries


## Story action "take_items:<spec>,<spec>": removes them (inventory first, then equipped tools).
## Takes nothing and returns false if something is missing.
func take_items(specs: String) -> bool:
	if not has_items(specs):
		return false
	for spec in specs.split(",", false):
		var wanted: InventorySlot = ContentDB.make_stack(spec)
		_take_like(wanted, wanted.amount)
	return true


## Takes `amount` pieces like `wanted` from the hand-in slots (while a hand-in runs) or else from
## the inventory and the equipped tools.
func _take_like(wanted: InventorySlot, amount: int) -> void:
	var remaining: int = amount
	if _hand_in_active:
		for stack in _hand_in:
			if remaining > 0 and is_like(stack, wanted):
				remaining -= _take_from_hand_in(stack, remaining)
		return
	for i in GameState.inventory.slots.size():
		if remaining > 0 and is_like(GameState.inventory.slots[i], wanted):
			var taken: int = mini(remaining, GameState.inventory.slots[i].amount)
			GameState.inventory.remove_from_slot(i, taken)
			remaining -= taken
	for tool_slot in PlayerStats.ToolSlot.values():
		if remaining > 0 and is_like(GameState.player_stats.get_tool(tool_slot), wanted):
			GameState.player_stats.unequip_tool(tool_slot)
			remaining -= 1


# --- Handing in bit by bit (side tasks with show_items / show_gold) -----------------

## Story action "deliver:<side task id>": hands in as much of the side task's "show_items" as the
## player has (the hand-in slots while a hand-in runs), up to what is still missing; Story.delivered
## counts it. Once everything and the "show_gold" are there, the task's "done_flag" is set.
## false if nothing could be handed in.
func deliver(task_id: String) -> bool:
	var handed: bool = false
	for entry in _missing_deliveries(task_id):
		var amount: int = mini(entry["missing"], count_like(entry["wanted"]))
		if amount > 0:
			_take_like(entry["wanted"], amount)
			GameState.story.add_delivered(task_id, entry["spec"], amount)
			handed = true
	_check_delivered(task_id)
	return handed


## Story action "deliver_gold:<side task id>": pays as much of the side task's "show_gold" as is
## still missing and the player has. false if nothing was paid.
func deliver_gold(task_id: String) -> bool:
	var missing: int = int(GameState.story.get_side_task(task_id).get("show_gold", 0)) - GameState.story.get_delivered(task_id, "gold")
	var amount: int = mini(missing, GameState.gold)
	if amount <= 0:
		return false
	GameState.spend_gold(amount)
	GameState.story.add_delivered(task_id, "gold", amount)
	_check_delivered(task_id)
	return true


## The things of a side task's "show_items" not handed in completely yet:
## [{"spec", "wanted": InventorySlot, "missing": int}].
func _missing_deliveries(task_id: String) -> Array[Dictionary]:
	var missing: Array[Dictionary] = []
	for spec in str(GameState.story.get_side_task(task_id).get("show_items", "")).split(",", false):
		var wanted: InventorySlot = ContentDB.make_stack(spec)
		var left: int = wanted.amount - GameState.story.get_delivered(task_id, spec) if wanted else 0
		if left > 0:
			missing.append({"spec": spec, "wanted": wanted, "missing": left})
	return missing


func _check_delivered(task_id: String) -> void:
	var task: Dictionary = GameState.story.get_side_task(task_id)
	if _missing_deliveries(task_id).is_empty() 			and GameState.story.get_delivered(task_id, "gold") >= int(task.get("show_gold", 0)):
		GameState.story.set_flag(task.get("done_flag", ""))


## Gold of a side task's "show_gold" for the quest log: [have, need]; what was paid already counts
## along with the player's gold.
func get_gold_progress(task_id: String) -> Array[int]:
	var need: int = int(GameState.story.get_side_task(task_id).get("show_gold", 0))
	return [mini(GameState.story.get_delivered(task_id, "gold") + GameState.gold, need), need]


# --- Hand-in slots -----------------------------------------------------------------

## What a story action hands in (its take_items / hand_in_set), one entry per slot of HandInSlots:
## {"name", "amount", "icon", "accepts": Callable(InventorySlot) -> bool}. Empty = nothing to hand in.
func get_hand_in_requests(actions: String) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	for action in actions.split(";", false):
		action = action.strip_edges()
		var parameter: String = action.substr(action.find(":") + 1)
		if action.begins_with("take_items:"):
			for spec in parameter.split(",", false):
				var wanted: InventorySlot = ContentDB.make_stack(spec)
				if wanted:
					requests.append({"name": wanted.get_display_name(), "amount": wanted.amount,
							"icon": wanted.get_icon(), "accepts": is_like.bind(wanted)})
		elif action.begins_with("deliver:"):
			for entry in _missing_deliveries(parameter):
				var wanted: InventorySlot = entry["wanted"]
				requests.append({"name": wanted.get_display_name(), "amount": entry["missing"],
						"icon": wanted.get_icon(), "accepts": is_like.bind(wanted)})
		elif action.begins_with("hand_in_set:"):
			var task: Dictionary = GameState.story.get_side_task(parameter)
			var wanted_types: Dictionary = task.get("set_items", {})
			for type_key: String in wanted_types:
				if GameState.story.has_flag(_set_given_flag(task, type_key)):
					continue
				requests.append({"name": wanted_types[type_key], "amount": 1, "icon": get_set_piece_icon(task, type_key),
						"accepts": func(stack: InventorySlot) -> bool: return is_set_piece(task, type_key, stack)})
	return requests


## Picture of a set piece in the set's metal (e.g. a copper helmet for "helmet"), shown faded in
## empty hand-in slots. Built like the armor merchant's pieces; null if there is no such recipe.
func get_set_piece_icon(task: Dictionary, type_key: String) -> Texture2D:
	var material: String = task.get("set_material", "")
	var type_index: int = ItemData.ItemType.keys().find(type_key.to_upper())
	var armor_stock: Dictionary = ContentDB.economy("market_stock").get("armor", {})
	var part_materials: Dictionary = armor_stock.get("equipment", {}).get("part_materials", {})
	for recipe in ContentDB.get_all_recipes():
		if recipe.result == null or (recipe.result.type != type_index and String(recipe.result.id) != type_key):
			continue
		var spec: String = MerchantStock.equipment_spec(String(recipe.result.id), material, part_materials)
		var stack: InventorySlot = ContentDB.make_stack(spec) if not spec.is_empty() else null
		if stack and stack.get_icon():
			return stack.get_icon()
	return null


## The hand-in slot of a quest (QuestDialog): its wanted item, as many as it needs.
func get_quest_hand_in(quest: QuestData) -> Array[Dictionary]:
	var wanted: InventorySlot = ContentDB.make_stack(quest.required_item_id)
	return [{"name": quest.requirement_name, "amount": quest.required_amount,
			"icon": wanted.get_icon() if wanted else null, "accepts": quest.matches}]


## Runs `action` (e.g. run_story_action.bind(...) or complete_quest.bind(quest)) so that it only
## sees and takes the stacks lying in the hand-in slots. What it does not take stays in `stacks`
## (the slots give it back). Returns what the action returns.
func run_with_hand_in(stacks: Array[InventorySlot], action: Callable) -> bool:
	_hand_in = stacks
	_hand_in_active = true
	var result: bool = action.call()
	_hand_in_active = false
	_hand_in = []
	return result


## Takes up to `amount` pieces from a hand-in stack. Returns how many were taken.
func _take_from_hand_in(stack: InventorySlot, amount: int) -> int:
	var taken: int = mini(amount, stack.amount)
	if taken == stack.amount:
		stack.clear()
	else:
		stack.amount -= taken
	return taken


## story.json step "extra_goals": more lines under the step's goal, each shown once its "if_flag" is
## set (empty = always) and done once its "flag" is set, e.g. "0/1 Aurelius fragen" after getting
## lost in the desert. Returns [{"name", "done"}].
func get_extra_goals(step_data: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Dictionary in step_data.get("extra_goals", []):
		var shown_from: String = str(entry.get("if_flag", ""))
		if shown_from.is_empty() or GameState.story.has_flag(shown_from):
			list.append({"name": str(entry.get("name", "")), "done": GameState.story.has_flag(str(entry.get("flag", "")))})
	return list


## story.json step "shopping" (first steps, before the copper set): what to buy where, e.g.
## [{"name": "Wassertrog", "where": "Möbelhändlerin", "flag": "station_water_trough"}]. An entry is
## done once its "flag" is set or the player has its "items" (spec like show_items).
## Returns [{"name", "where", "done", "have", "need"}]: "need" is the amount from "items" ("wood*2"
## -> 2, the name carries no number), 1 for a flag entry.
func get_shopping_list(step_data: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Dictionary in step_data.get("shopping", []):
		var done: bool = is_shopping_entry_done(entry)
		var have: int = 0
		var need: int = 0
		if entry.has("items"):
			for progress in get_item_progress(str(entry["items"])):
				have += progress["have"]
				need += progress["need"]
		if need == 0:
			need = 1
		have = need if done else mini(have, need)
		list.append({"name": entry.get("name", ""), "where": entry.get("where", ""), "done": done,
				"have": have, "need": need})
	return list


func is_shopping_entry_done(entry: Dictionary) -> bool:
	if entry.has("flag") and GameState.story.has_flag(str(entry["flag"])):
		return true
	return entry.has("items") and has_items(str(entry["items"]))


## How many matching items the player carries for the quest (checks whole stacks, e.g. the
## parts of an axe, not only the item type).
func count_quest_items(quest: QuestData) -> int:
	var count: int = 0
	for slot in (_hand_in if _hand_in_active else GameState.inventory.slots):
		if quest.matches(slot):
			count += slot.amount
	return count


func take_quest_items(quest: QuestData) -> void:
	var remaining: int = quest.required_amount
	if _hand_in_active:
		for stack in _hand_in:
			if remaining > 0 and quest.matches(stack):
				remaining -= _take_from_hand_in(stack, remaining)
		return
	for i in GameState.inventory.slots.size():
		if remaining == 0:
			break
		var slot: InventorySlot = GameState.inventory.slots[i]
		if quest.matches(slot):
			var taken: int = mini(remaining, slot.amount)
			GameState.inventory.remove_from_slot(i, taken)
			remaining -= taken
