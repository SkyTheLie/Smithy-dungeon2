class_name StorySkip
extends RefCounted
## Test tool (admin panel, tab "Kapitel"): jumps to the first step of a chapter, forwards or
## backwards. Every step before it counts as played: its "reached_" flag and progress flags are set
## and the lasting results of its dialogues happen (flags, recipes, molds, heroes joining or dying,
## renting the smithy); paying, handing in and receiving items is skipped. Flags of the target step
## and of everything after it are taken back, heroes that died later come back. Then the overnight
## changes (story.json "overnight") and "implied_flags" are applied, the clock runs (no intro) and the
## target step begins. An approximation: what the game itself sets while playing (purchases, quests)
## is not repeated. Of a decision (choices with "decision": true, e.g. whom to save on the ice wall)
## only the first answer counts as chosen.

## Chapters in story order: [title, first step] (docs/STORY.md).
const CHAPTERS: Array = [
	["Kapitel 1: Eine eigene Schmiede", "find_smithy"],
	["Kapitel 2: Holgers Axt", "find_customer"],
	["Kapitel 3: Hallo Dungeon", "go_to_sleep"],
	["Kapitel 4: Ninas Laden und Gustavs Spitzhacke", "go_to_market"],
	["Kapitel 5: Die erste Miete und der erste Kunde", "first_rent"],
	["Kapitel 6: Ratten in der Mine", "mine_tour"],
	["Kapitel 7: Die verschwundene Nichte", "grandma_begs"],
	["Kapitel 8: Das Dorffest", "festival_rumors"],
	["Kapitel 9: Der Überfall", "raid_wake"],
	["Teil 2, Kapitel 1: Der Wiederaufbau", "rebuild_call"],
	["Teil 2, Kapitel 2: Ein Hauch von Magie", "forest_mage"],
	["Teil 2, Kapitel 3: Die Königsstadt", "royal_carriage"],
	["Teil 2, Kapitel 4: Die Gosse", "king_question"],
	["Teil 2, Kapitel 5: Die neun Steine", "search_mage"],
	["Teil 2, Kapitel 6: Die verzauberte Gruft", "chapter14_end"],
	["Teil 2, Kapitel 7: Der Goblinkönig", "to_volcano"],
	["Teil 2, Kapitel 8: Der Drache", "to_goblin_castle"],
	["Teil 2, Kapitel 9: Der Feuerkristall", "crystal_to_king"],
	["Teil 3, Kapitel 1: Der Kriegsrat", "council_call"],
	["Teil 3, Kapitel 2: Das Schmiedeturnier", "tournament_announced"],
	["Teil 3, Kapitel 3: Waffen für Sylvaris", "elf_return"],
	["Teil 3, Kapitel 4: Die Nacht in Sylvaris", "elf_elder_evening"],
	["Teil 3, Kapitel 5: Der Krisenrat", "crisis_council"],
	["Teil 4, Kapitel 1: Die Stadt im Eis", "water_departure"],
	["Teil 4, Kapitel 2: Das Turnier der Gezeiten", "kahn_audience"],
	["Teil 4, Kapitel 3: Gefangen im Sand", "to_desert"],
	["Teil 4, Kapitel 4: Der Sturmtempel", "storm_temple"],
	["Teil 4, Kapitel 5: Der leere Thron", "crystal_to_lord"],
	["Teil 5, Kapitel 1: Ohne König", "rescue_council"],
	["Teil 5, Kapitel 2: Die Sumpfhechse", "to_swamp"],
	["Teil 5, Kapitel 3: Vor der Finsterburg", "to_camp"],
	["Teil 5, Kapitel 4: Der Sturm auf die Finsterburg", "sneak_in"],
	["Teil 5, Kapitel 5: Der dunkle Ritter", "throne_hall"],
	["Teil 6, Kapitel 1: Asche und Sternenlicht", "forest_wake"],
	["Teil 6, Kapitel 2: Die Glut in deinen Händen", "glow_lesson"],
	["Teil 6, Kapitel 3: Unter Freunden", "return_home"],
	["Teil 6, Kapitel 4: Das Gesetz der Strömung", "eisquell_blade"],
	["Teil 6, Kapitel 5: Wo das Eis singt", "climb_wall"],
	["Teil 6, Kapitel 6: Der Kampf um den Eiskristall", "singing_wall"],
	["Teil 7, Kapitel 1: Die Stadt im Schatten", "finster_start"],
	["Teil 7, Kapitel 2: Der Widerstand", "resistance_hideout"],
	["Teil 7, Kapitel 3: Zurück in die Finsterburg", "sneak_castle"],
	["Teil 7, Kapitel 4: Die rechtmäßige Erbin", "halvard_freed"],
	["Teil 8, Kapitel 1: Der große Rat", "grand_council"],
	["Teil 8, Kapitel 2: Das Tor öffnet sich", "to_altar"],
	["Teil 8, Kapitel 3: Die Schlacht am Altar", "altar_west"],
	["Teil 8, Kapitel 4: Licht in der Dunkelheit", "lake_awakens"],
	["Teil 8, Kapitel 5: Die wahre Fassung", "final_forge"],
]
## Story actions whose result lasts and that cost nothing (run for the skipped steps).
const LASTING_ACTIONS: Array[String] = ["set_flag", "unlock_recipes", "unlock_molds", "hire_hero", "lose_hero",
	"expand_nina_shop", "buy_smithy", "set_rent", "read_rent_sign"]
## Actions that rent the smithy: only their flag and the rent are kept.
const RENT_ACTIONS: Dictionary = {"rent_smithy": "smithy_rented", "pay_rent": "first_rent_paid"}


## Jumps to `target_step` (one of CHAPTERS).
static func jump_to(target_step: String) -> void:
	var story: Story = GameState.story
	var steps: Array = Story.get_data("steps").keys()
	var target_index: int = steps.find(target_step)
	if target_index < 0:
		push_error("StorySkip: unknown step '%s'." % target_step)
		return
	# Take back what the target step and everything after it did.
	# figures tell the dialogues of these steps again by themselves
	for npc_id: String in story.told_steps.keys():
		if steps.find(story.told_steps[npc_id]) >= target_index:
			story.told_steps.erase(npc_id)
	var later_flags: Array = []
	for step_id: String in steps.slice(target_index):
		later_flags.append("reached_" + step_id)
		var effects: Dictionary = _effects_of_step(step_id, true)
		later_flags.append_array(effects.flags)
		for hero_id: String in effects.lost_heroes:
			if not GameState.has_hero(StringName(hero_id)):
				GameState.run_story_action("hire_hero:" + hero_id)
	for entry: Dictionary in Story.get_data("overnight"):
		if later_flags.has(entry.get("if", [""])[0]):
			later_flags.append(entry.get("set", ""))
	# Everything else that happened from the target step on (cut scenes, side dialogues, puzzles,
	# letters ...): the world goes back to how it was when the step began.
	for flag: String in story.flag_steps:
		if steps.find(story.flag_steps[flag]) >= target_index:
			later_flags.append(flag)
	story.clear_flags(later_flags)
	# Play everything before it; what a step sets counts as set in that step.
	for step_id: String in steps.slice(0, target_index):
		var before: Array = story.flags.keys()
		story.flags["reached_" + step_id] = true
		for flag: String in Story.get_data("steps")[step_id].get("progress_flags", []):
			story.flags[flag] = true
		for action: String in _effects_of_step(step_id).actions:
			_run_lasting(action)
		for flag: String in story.flags:
			if not before.has(flag):
				story.flag_steps[flag] = step_id
	_apply_overnight()
	_apply_implied()
	story.drop_future_flags(target_step)
	_letters_read()
	story.set_flag(str(Story.get_data("start").get("clock_stops_until", "")))
	story.advance(target_step)


## Title of the chapter that contains `step_id` ("" before the first one).
static func chapter_of(step_id: String) -> String:
	var steps: Array = Story.get_data("steps").keys()
	var index: int = steps.find(step_id)
	var title: String = ""
	for chapter: Array in CHAPTERS:
		if index >= 0 and steps.find(chapter[1]) <= index:
			title = chapter[0]
	return title


## {"actions": lasting actions, "flags": flags they set, "lost_heroes": heroes that die} of a step:
## its on_start and the dialogues the story figures have during it (with their follow-ups). With
## `all_answers` every answer of a decision counts (to take all of them back), else only the first.
static func _effects_of_step(step_id: String, all_answers: bool = false) -> Dictionary:
	var result: Dictionary = {"actions": [], "flags": [], "lost_heroes": []}
	_collect_actions(str(Story.get_data("steps")[step_id].get("on_start", "")), result)
	var seen: Array = []
	for npc: Dictionary in Story.get_data("npcs").values():
		var dialogue_id: String = npc.get("dialogues", {}).get(step_id, "")
		if not dialogue_id.is_empty():
			_collect_dialogue(dialogue_id, result, seen, all_answers)
	return result


static func _collect_dialogue(dialogue_id: String, result: Dictionary, seen: Array, all_answers: bool) -> void:
	if dialogue_id.is_empty() or seen.has(dialogue_id):
		return
	seen.append(dialogue_id)
	var dialogue: Dictionary = Story.get_data("dialogues").get(dialogue_id, {})
	for line: Dictionary in dialogue.get("lines", []):
		_collect_actions(str(line.get("action", "")), result)
	_collect_actions(str(dialogue.get("on_end", "")), result)
	for choice: Dictionary in dialogue.get("choices", []):
		_collect_actions(str(choice.get("action", "")), result)
		_collect_dialogue(str(choice.get("then", "")), result, seen, all_answers)
		if choice.get("decision", false) and not all_answers:
			break
	_collect_dialogue(str(dialogue.get("then", "")), result, seen, all_answers)


static func _collect_actions(actions: String, result: Dictionary) -> void:
	for action in actions.split(";", false):
		action = action.strip_edges()
		var name: String = action.get_slice(":", 0)
		var parameter: String = action.substr(action.find(":") + 1) if ":" in action else ""
		if name == "set_flag":
			result.flags.append(parameter)
		elif name == "lose_hero":
			result.lost_heroes.append(parameter)
		elif RENT_ACTIONS.has(name):
			result.flags.append(RENT_ACTIONS[name])
		if name in LASTING_ACTIONS or RENT_ACTIONS.has(name):
			result.actions.append(action)


static func _run_lasting(action: String) -> void:
	var name: String = action.get_slice(":", 0)
	if RENT_ACTIONS.has(name):
		GameState.story.flags[RENT_ACTIONS[name]] = true
		if not GameState.rent.active:
			GameState.rent.start(GameState.day_cycle.day)
		return
	GameState.run_story_action(action)


## Letters of the skipped steps count as read: Lotte does not come running with all of them after
## the jump (only the letter of the target step itself comes, its on_start sets it on advance).
static func _letters_read() -> void:
	var story: Story = GameState.story
	for entry: Dictionary in Story.get_data("side_dialogues"):
		if entry.get("courier", false) and story.has_flag(str(entry.get("flag", ""))):
			var done: String = str(entry.get("done_flag", ""))
			if not done.is_empty() and not story.flags.has(done):
				story.flags[done] = true
				story.flag_steps[done] = story.flag_steps.get(str(entry.get("flag", "")), story.step)


## story.json "overnight": what happens over night once its flags are set (e.g. the greenhouse).
static func _apply_overnight() -> void:
	for entry: Dictionary in Story.get_data("overnight"):
		if GameState.story.has_flags(entry.get("if", [])):
			GameState.story.flags[str(entry.get("set", ""))] = true


static func _apply_implied() -> void:
	var implied: Dictionary = Story.get_data("implied_flags")
	for flag: String in implied:
		if GameState.story.flags.has(flag):
			for other: String in implied[flag]:
				GameState.story.flags[other] = true
