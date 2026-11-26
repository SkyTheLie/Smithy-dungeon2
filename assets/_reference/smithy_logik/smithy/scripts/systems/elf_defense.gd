class_name ElfDefense
extends RefCounted
## Part 3, "Waffen für Sylvaris": after the smith tournament the player hands weapons and armor to
## General Hadmar on the forest floor of Sylvaris (ArmoryMenu, story action "open_menu:armory").
## Every piece gives hidden points (economy.json "elf_defense"): better metal and higher rarity
## give more (get_piece_points). Winning the eyrie on the storm peak (the griffin Sturmschwinge,
## dungeon "griffin_dungeon") adds "griffin_bonus": the Lich's bone birds can't cross the pass.
## The player never sees the number; the general says roughly how far it is (get_level, his
## dialogue lines with if_flag "elf_defense_level_<n>", set by update_flags).
## When the attack starts (story action "elf_defense_check", step elf_attack_canopy) WON_FLAG is
## set if the points reach "goal": the elves push the undead back, Lake comes to help and the Lich
## flees without the wind crystal; otherwise he takes it (as before).
## Points and pieces are kept in Story.delivered[TASK_ID] (saved with the story).

const TASK_ID: String = "elf_defense"
const WON_FLAG: String = "elf_defense_won"
## Flag of the general's verdict: 0 = hardly anything, 1 = a start, 2 = almost, 3 = enough.
const LEVEL_FLAG: String = "elf_defense_level_%d"
const MAX_LEVEL: int = 3
## Flag set while the griffin was not beaten yet (the general mentions the pass).
const GRIFFIN_OPEN_FLAG: String = "elf_defense_griffin_open"


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")


static func _config() -> Dictionary:
	return ContentDB.economy(TASK_ID)


## Whether the general takes this stack: a cold weapon or armor piece (shields count).
static func can_hand_in(stack: InventorySlot) -> bool:
	return stack != null and not stack.is_empty() and not stack.hot and stack.item != null \
			and not stack.item.story_item and (stack.item.is_weapon() or stack.item.is_armor())


## Material tier of a piece: the hardest of its parts (a silver sword with a wooden grip = silver).
static func get_tier(stack: InventorySlot) -> int:
	var tier: int = stack.item.material_tier
	for part: ItemData in stack.components:
		if part != null:
			tier = maxi(tier, part.material_tier)
	return tier


## Hidden points of one piece: (tier × per_tier, at least 1) × (1 + rarity × per_rarity), at least 1.
static func get_piece_points(stack: InventorySlot) -> int:
	if not can_hand_in(stack):
		return 0
	var config: Dictionary = _config()
	var by_tier: float = maxf(1.0, get_tier(stack) * float(config.get("per_tier", 1.0)))
	var by_rarity: float = 1.0 + int(stack.rarity) * float(config.get("per_rarity", 0.5))
	return maxi(1, roundi(by_tier * by_rarity)) * stack.amount


static func get_goal() -> int:
	return int(_config().get("goal", 80))


## Whether the heroes won the griffin's eyrie at least once.
static func is_griffin_beaten() -> bool:
	var dungeon_id: String = str(_config().get("griffin_dungeon", "mountain_summit"))
	return int(_game_state().achievements.counters.get("dungeon:" + dungeon_id, 0)) > 0


## Points so far: the handed-in pieces plus the griffin bonus.
static func get_points() -> int:
	var points: int = _game_state().story.get_delivered(TASK_ID, "points")
	if is_griffin_beaten():
		points += int(_config().get("griffin_bonus", 25))
	return points


static func get_pieces() -> int:
	return _game_state().story.get_delivered(TASK_ID, "pieces")


## Hands in the stacks (all of them, the caller removes them from wherever they lie).
## Returns the points they gave.
static func hand_in(stacks: Array[InventorySlot]) -> int:
	var story: Story = _game_state().story
	var points: int = 0
	var pieces: int = 0
	for stack in stacks:
		var stack_points: int = get_piece_points(stack)
		if stack_points <= 0:
			continue
		points += stack_points
		pieces += stack.amount
	if pieces > 0:
		story.add_delivered(TASK_ID, "points", points)
		story.add_delivered(TASK_ID, "pieces", pieces)
	update_flags()
	return points


## The general's verdict: 0 below "levels"[0] of the goal, ... MAX_LEVEL from the goal on.
static func get_level() -> int:
	var share: float = get_points() / float(maxi(1, get_goal()))
	if share >= 1.0:
		return MAX_LEVEL
	var level: int = 0
	for limit in _config().get("levels", [0.3, 0.7]):
		if share >= float(limit):
			level += 1
	return mini(level, MAX_LEVEL - 1)


## Sets exactly one LEVEL_FLAG and GRIFFIN_OPEN_FLAG while the griffin lives, so the general's
## dialogue lines (if_flag) say how far it is. Story action "elf_defense_update".
static func update_flags() -> void:
	var story: Story = _game_state().story
	var clear: Array = []
	for level in MAX_LEVEL + 1:
		clear.append(LEVEL_FLAG % level)
	clear.append(GRIFFIN_OPEN_FLAG)
	story.clear_flags(clear)
	story.set_flag(LEVEL_FLAG % get_level())
	if not is_griffin_beaten():
		story.set_flag(GRIFFIN_OPEN_FLAG)


## The night of the attack: WON_FLAG if the points reach the goal. Story action "elf_defense_check".
static func decide() -> bool:
	var won: bool = get_points() >= get_goal()
	if won:
		_game_state().story.set_flag(WON_FLAG)
	return won
