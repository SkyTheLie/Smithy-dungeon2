class_name Guide
extends RefCounted
## Golden guidance for the first steps: what glows right now (world: GuideOutline on stations,
## merchants and story figures; windows: GuideFrame on wares, slots, tabs, recipes and buttons).
## Comes from the current story step (story.json, see docs/CONTENT.md):
## - "shopping" entries with "buy" (shop offer spec, e.g. "copper_ore", "station:water_trough",
##   "recipe:copper_blade"): until the entry is done the ware glows in the shop (target
##   "buy:<spec>") and so does every merchant that has it today (Merchant).
## - "guide": stages, checked top to bottom; the first whose "if" holds is shown. "show" lists the
##   targets, a target may be {"target": ..., "if": ...} to glow only under its own condition.
## Targets: "station:<scene name>" (Station.get_guide_id, e.g. "station:smelter"), "npc:<npc id>",
## "recipe:<recipe id>" (recipe button, its tab and category, then the craft button),
## "smelter:ore" / "smelter:fuel" / "smelter:output" (empty ore / fuel slot, full output slot,
## then the start button), "trough:slot", "inv:<item id>" (inventory slots with this item),
## "dungeon:<id>" / "hero:<id>" (dungeon board: region tab, dungeon, hero slot, hero, send button).
## Conditions ("if", comma = and, "!" in front = not): "has:<id>" (in the inventory, glowing or
## not), "cold:<id>", "hot:<id>", "smelter_busy", "smelter_ready" (ingots in the output slot),
## "trough_busy" (something lies in the water trough), "flag:<story flag>".
## A target may contain "*" (any text), e.g. "recipe:*_staff_rod", "inv:*_staff_rod".
## Conditions ("if", comma = and, "|" = or, "!" in front = not): ... "part:<part>" (a cold piece of
## this part type, e.g. "part:leather"), "weapon:<weapon type id>" (e.g. "weapon:staff"),
## "order_item" (a cold item that fits an open customer order). Item ids may contain "*".
## Story steps happen once, so everything glows only the first time.
## Tutorials (story.json "tutorials", only while the story step has no "guide" of its own): a
## tutorial starts once its "start" holds (flag "tutorial_<id>", shows its tip "hint"), shows its
## "guide" stages like a story step and ends for good once "done" holds (flag "tutorial_<id>_done").
## Stage targets "buy:<spec>" make the ware and its merchants glow like a shopping entry.
## Tips (story.json "hints") may have "glow": targets that glow while the tip is on screen,
## e.g. "menu:settings", "menu:save", "menu:load" (buttons of the side menu, HUD).

## Targets are worked out again at most this often (the markers ask several times a second).
const REFRESH_MSEC: int = 200

## Targets of the tip shown right now (HintPanel), glow regardless of the story step.
static var hint_targets: Array = []
static var _targets: Dictionary = {}
## Targets with "*" (String.match).
static var _patterns: Array[String] = []
static var _buy_specs: Array[String] = []
static var _computed_msec: int = -REFRESH_MSEC


static func is_target(target: String) -> bool:
	if hint_targets.has(target):
		return true
	_update()
	if _targets.has(target):
		return true
	for pattern in _patterns:
		if target.match(pattern):
			return true
	return false


## true if anything glows right now (quick check before looking at single targets).
static func has_targets() -> bool:
	if not hint_targets.is_empty():
		return true
	_update()
	return not _targets.is_empty() or not _patterns.is_empty()


## Shop offer specs that glow right now ("copper_ore", "station:water_trough" ...).
static func get_buy_specs() -> Array[String]:
	_update()
	return _buy_specs


## true if one of these stock entries (MerchantStock, {"spec", "amount"}) is a ware to buy now.
static func has_buy_target(entries: Array) -> bool:
	var wanted: Array[String] = get_buy_specs()
	if wanted.is_empty():
		return false
	for entry: Dictionary in entries:
		if wanted.has(str(entry.get("spec", ""))) and int(entry.get("amount", -1)) != 0:
			return true
	return false


## The targets are worked out anew on the next question (e.g. right after a purchase).
static func invalidate() -> void:
	_computed_msec = -REFRESH_MSEC


static func _update() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _computed_msec < REFRESH_MSEC:
		return
	_computed_msec = now
	_targets.clear()
	_patterns.clear()
	_buy_specs.clear()
	if GameState.in_main_menu:
		return
	var step: Dictionary = GameState.story.get_step() if GameState.story.is_running() else {}
	for entry: Dictionary in step.get("shopping", []):
		if entry.has("buy") and not GameState.is_shopping_entry_done(entry):
			_add_target("buy:" + str(entry["buy"]))
	if step.has("guide"):
		_show_stages(step["guide"])
		return
	for tutorial: Dictionary in _update_tutorials():
		_show_stages(tutorial.get("guide", []))


## Shows the targets of the first stage whose "if" holds.
static func _show_stages(stages: Array) -> void:
	for stage: Dictionary in stages:
		if not check(str(stage.get("if", ""))):
			continue
		for shown: Variant in stage.get("show", []):
			if shown is Dictionary:
				if check(str(shown.get("if", ""))):
					_add_target(str(shown.get("target", "")))
			else:
				_add_target(str(shown))
		return


static func _add_target(target: String) -> void:
	if target.begins_with("buy:") and not _buy_specs.has(target.trim_prefix("buy:")):
		_buy_specs.append(target.trim_prefix("buy:"))
	if target.contains("*"):
		_patterns.append(target)
	else:
		_targets[target] = true


## Starts and ends tutorials (story.json "tutorials"); returns the running ones.
static func _update_tutorials() -> Array[Dictionary]:
	var story: Story = GameState.story
	var running: Array[Dictionary] = []
	var tutorials: Dictionary = story.get_data("tutorials")
	for id: String in tutorials:
		if id.begins_with("_") or story.has_flag("tutorial_%s_done" % id):
			continue
		var tutorial: Dictionary = tutorials[id]
		if not story.has_flag("tutorial_" + id):
			if not check(str(tutorial.get("start", ""))):
				continue
			story.set_flag("tutorial_" + id)
			# Already done when it would start (e.g. an old save): no tip.
			if not check(str(tutorial.get("done", ""))):
				story.show_hint(str(tutorial.get("hint", "")))
		if check(str(tutorial.get("done", ""))):
			story.set_flag("tutorial_%s_done" % id)
			continue
		running.append(tutorial)
	return running


## Whether every condition of `conditions` holds ("" = always).
static func check(conditions: String) -> bool:
	for condition in conditions.split(",", false):
		condition = condition.strip_edges()
		var negated: bool = condition.begins_with("!")
		var holds: bool = false
		for option in condition.trim_prefix("!").split("|", false):
			if _holds(option.strip_edges()):
				holds = true
				break
		if holds == negated:
			return false
	return true


static func _holds(condition: String) -> bool:
	var parameter: String = condition.get_slice(":", 1)
	match condition.get_slice(":", 0):
		"has":
			return _count(parameter, -1) > 0
		"cold":
			return _count(parameter, 0) > 0
		"hot":
			return _count(parameter, 1) > 0
		"part":
			return _find(func(slot: InventorySlot) -> bool:
				return not slot.hot and ItemData.PartType.keys()[slot.item.part_type].to_lower() == parameter)
		"weapon":
			return _find(func(slot: InventorySlot) -> bool:
				return slot.item.weapon_type != null and String(slot.item.weapon_type.id) == parameter)
		"order_item":
			return _find(func(slot: InventorySlot) -> bool:
				return not slot.hot and GameState.customers.orders.any(func(order: CustomerOrder) -> bool: return order.matches(slot)))
		"flag":
			return GameState.story.has_flag(parameter)
		"smelter_busy":
			return GameState.smelter.is_smelting()
		"smelter_ready":
			return not GameState.smelter.output_slot.is_empty()
		"trough_busy":
			return not GameState.quencher.slot.is_empty()
	push_error("Guide: unknown condition '%s' (story.json \"guide\")." % condition)
	return false


## Pieces of `item_id` ("*" = any text) in the inventory: hot = -1 any, 0 only cold ones, 1 only
## glowing ones.
static func _count(item_id: String, hot: int) -> int:
	var count: int = 0
	for slot in GameState.inventory.slots:
		if not slot.is_empty() and String(slot.item.id).match(item_id) and (hot < 0 or slot.hot == (hot == 1)):
			count += slot.amount
	return count


## true if a non-empty inventory slot passes `test`.
static func _find(test: Callable) -> bool:
	return GameState.inventory.slots.any(func(slot: InventorySlot) -> bool: return not slot.is_empty() and test.call(slot))
