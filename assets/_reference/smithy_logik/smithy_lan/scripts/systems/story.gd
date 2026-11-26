class_name Story
extends RefCounted
## Progress of the story (data/content/story.json, format: docs/CONTENT.md). Lives in
## GameState.story. The story is a chain of steps ("find_smithy" -> "visit_landlady" -> ...);
## the current step is the task shown in the quest log. Flags remember single events
## ("smithy_rented", "cobweb_anvil", "station_water_trough" ...): doors, stations and story
## figures check them. A step with "progress_flags" ends by itself when all of them are set (one with
## "shopping_done" only once its whole shopping list is done).
## Tips (hints) are shown once each: they wait in `pending_hints` until the HUD shows them.
## Side tasks (story.json "side_tasks") run next to the chain of steps: one starts when its
## "start_flag" is set and is over once its "done_flag" is set (GameState checks them).

## Step, flags or hints changed.
signal changed
## A new tip is waiting (the HUD shows it).
signal hint_added
## A new step began (GameState runs its "on_start" actions).
signal step_started(step: String)

const DONE: String = "done"

## Current step id ("" = no story, e.g. before a new game).
var step: String = ""
## Flags that are set (flag -> true).
var flags: Dictionary = {}
## Ids of tips that were shown already (each tip only once).
var shown_hints: Array[String] = []
## Tips that wait to be shown: [{"title", "text"}] (texts not formatted yet).
var pending_hints: Array[Dictionary] = []
## What was handed in bit by bit for side tasks (GameState.deliver): task id -> {spec or "gold": amount}.
var delivered: Dictionary = {}


## Beginning of a new game: first step, no flags.
func start_new() -> void:
	flags.clear()
	delivered.clear()
	shown_hints.clear()
	pending_hints.clear()
	step = ""
	advance(str(get_data("start").get("step", DONE)))


## For quick tests (GameState.SKIP_TITLE_SCREEN) and saves from before the story: everything the
## story unlocks is unlocked, no tips.
func complete_all() -> void:
	step = DONE
	for flag: String in get_data("skip_flags"):
		flags[flag] = true
	pending_hints.clear()
	changed.emit()


## How much of `key` (a "show_items" spec or "gold") was handed in for a side task so far.
func get_delivered(task_id: String, key: String) -> int:
	return int(delivered.get(task_id, {}).get(key, 0))


func add_delivered(task_id: String, key: String, amount: int) -> void:
	if not delivered.has(task_id):
		delivered[task_id] = {}
	delivered[task_id][key] = get_delivered(task_id, key) + amount
	changed.emit()


func is_running() -> bool:
	return step != "" and step != DONE


func has_flag(flag: String) -> bool:
	return flag.is_empty() or flags.has(flag)


## true if every flag of the list is set.
func has_flags(flag_list: Array) -> bool:
	return flag_list.all(func(flag: String) -> bool: return has_flag(flag))


func set_flag(flag: String) -> void:
	if flags.has(flag):
		return
	flags[flag] = true
	_check_progress()
	changed.emit()


## Takes flags back (e.g. the test trigger of the raid, so the raid can be played again).
func clear_flags(flag_list: Array) -> void:
	for flag: String in flag_list:
		flags.erase(flag.strip_edges())
	changed.emit()


## Goes to the next step and queues its tips. Sets the flag "reached_<step>" (figures can
## appear from a step on, see Station.required_flag).
func advance(next_step: String) -> void:
	if next_step != DONE and not next_step.is_empty() and not get_data("steps").has(next_step):
		# A typing error in story.json or in code: stay in the current step instead of landing in
		# an empty one, where the story would stop without a word.
		push_error("Story: unknown step '%s' (still in '%s')." % [next_step, step])
		return
	step = next_step
	flags["reached_" + next_step] = true
	for hint_id: String in get_step().get("hints", []):
		show_hint(hint_id)
	changed.emit()
	step_started.emit(next_step)
	# Its progress flags may be set already (e.g. a side task finished before the step began).
	if step == next_step:
		_check_progress()


func get_step() -> Dictionary:
	return get_data("steps").get(step, {})


## Current task for the quest log: {"title", "text", "goal", "done": int, "total": int, "items": specs}
## ("goal" = story.json step "goal", the short line in the quest tracker, {done}/{total} = progress;
## ("items" = story.json "show_items", things to bring, e.g. "coal*5,iron_ore*2"; the quest
## window shows how many the player has).
func get_objective() -> Dictionary:
	var data: Dictionary = get_step()
	var progress: Array = data.get("progress_flags", [])
	var done: int = progress.filter(func(flag: String) -> bool: return flags.has(flag)).size()
	return {"title": data.get("title", ""), "text": data.get("text", ""), "goal": data.get("goal", ""), "done": done,
			"total": progress.size(), "items": data.get("show_items", "")}


## Story tasks the player has finished, in story order: [{"title", "text"}] (quest log, tab
## "Erledigt"). A step counts once it was reached and is no longer the current one; the
## "Fortsetzung folgt" placeholders are left out.
func get_finished_steps() -> Array[Dictionary]:
	var finished: Array[Dictionary] = []
	var steps: Dictionary = get_data("steps")
	for step_id: String in steps:
		var data: Dictionary = steps[step_id]
		if step_id != step and flags.has("reached_" + step_id) and data.get("title", "") != "Fortsetzung folgt":
			finished.append({"title": data.get("title", ""), "text": data.get("text", "")})
	return finished


## Side tasks that are running now: [{"id", "title", "text", ...}] (story.json "side_tasks").
func get_side_tasks() -> Array[Dictionary]:
	return _side_tasks(false)


## Side tasks the player has finished (quest log, tab "Erledigt").
func get_finished_side_tasks() -> Array[Dictionary]:
	return _side_tasks(true)


func get_side_task(task_id: String) -> Dictionary:
	var task: Dictionary = get_data("side_tasks").get(task_id, {}).duplicate()
	if not task.is_empty():
		task["id"] = task_id
	return task


func _side_tasks(finished: bool) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for task_id: String in get_data("side_tasks"):
		var task: Dictionary = get_side_task(task_id)
		if flags.has(task.get("start_flag", "")) and has_flag(task.get("done_flag", "")) == finished:
			list.append(task)
	return list


## Queues a tip from story.json "hints" (only the first time).
func show_hint(hint_id: String) -> void:
	var hint: Dictionary = get_data("hints").get(hint_id, {})
	if hint.is_empty() or shown_hints.has(hint_id):
		return
	shown_hints.append(hint_id)
	pending_hints.append(hint)
	hint_added.emit()


## Queues a tip made in code (only the first time per `hint_id`), e.g. a new hero class.
## `prefix` replaces "Tipp: " before the title.
func show_custom_hint(hint_id: String, title: String, text: String, prefix: String = "Tipp: ") -> void:
	if shown_hints.has(hint_id):
		return
	shown_hints.append(hint_id)
	pending_hints.append({"title": title, "text": text, "prefix": prefix})
	hint_added.emit()


## Queues a popup that may come more than once (no id, not remembered), e.g. new offers of the
## furniture trader (UnlockNotices.check).
func show_notice(title: String, text: String, prefix: String = "Tipp: ") -> void:
	pending_hints.append({"title": title, "text": text, "prefix": prefix})
	hint_added.emit()


func take_pending_hint() -> Dictionary:
	return pending_hints.pop_front() if not pending_hints.is_empty() else {}


## The dialogue a story figure (story.json "npcs") has right now: the one for the current step,
## else an open side dialogue (story.json "side_dialogues"), else its "default". {} = nothing to say.
func get_npc_dialogue(npc_id: String) -> Dictionary:
	var dialogues: Dictionary = get_data("npcs").get(npc_id, {}).get("dialogues", {})
	var dialogue_id: String = dialogues.get(step, "")
	if dialogue_id.is_empty():
		dialogue_id = _get_side_dialogue(npc_id)
	if dialogue_id.is_empty() and dialogues.has("daily"):
		# "daily": a different dialogue each day, in turn (e.g. Zahir's hints in the desert town).
		var daily: Array = dialogues["daily"]
		var day: int = (Engine.get_main_loop() as SceneTree).root.get_node("GameState").day_cycle.day
		dialogue_id = str(daily[posmod(day, daily.size())]) if not daily.is_empty() else ""
	if dialogue_id.is_empty():
		dialogue_id = dialogues.get("default", "")
	return get_dialogue(dialogue_id)


## true if the figure has a dialogue just for the current step or an open side dialogue (shows "!").
func npc_has_news(npc_id: String) -> bool:
	return get_data("npcs").get(npc_id, {}).get("dialogues", {}).has(step) or not _get_side_dialogue(npc_id, true).is_empty()


## Side dialogues happen outside the chain of steps: {"npc", "flag" (needed), "done_flag" (set
## by the dialogue, then it is over; empty = never over), "flags" (more flags that must be set),
## "dialogue", "quiet" (true = no "!" above
## the figure, e.g. an offer that stays open for a long time), "topic" (button text in the figure's
## talk menu, see get_npc_topics), "courier" (true = the figure brings it to the player wherever
## they are and it plays first, without the talk menu, see get_courier_entry and LotteCourier)}.
## E.g. Nina's calendar once she sold enough.
func _get_side_dialogue(npc_id: String, only_news: bool = false) -> String:
	var courier: Dictionary = get_courier_entry(npc_id)
	if not courier.is_empty():
		return courier.get("dialogue", "")
	for entry: Dictionary in _open_side_dialogues(npc_id):
		if not (only_news and entry.get("quiet", false)):
			return entry.get("dialogue", "")
	return ""


## The first open side dialogue of `npc_id` with "courier" (e.g. Lotte bringing a letter), {} = none.
func get_courier_entry(npc_id: String) -> Dictionary:
	for entry: Dictionary in _open_side_dialogues(npc_id):
		if entry.get("courier", false):
			return entry
	return {}


## The side dialogues of `npc_id` that are open now, in their order in story.json.
func _open_side_dialogues(npc_id: String) -> Array[Dictionary]:
	var open: Array[Dictionary] = []
	for entry: Dictionary in get_data("side_dialogues"):
		var done_flag: String = entry.get("done_flag", "")
		if entry.get("npc", "") == npc_id and has_flag(entry.get("flag", "")) and has_flags(entry.get("flags", [])) \
				and (done_flag.is_empty() or not has_flag(done_flag)):
			open.append(entry)
	return open


## Topics for the talk menu of a figure with story.json "npcs.<id>.menu" (e.g. Lotte): every open
## side dialogue with a "topic" (button text) as {"topic", "dialogue"}, the same topic only once.
## Empty while the figure has a dialogue for the current step or brings something (courier): that
## one plays directly.
func get_npc_topics(npc_id: String) -> Array[Dictionary]:
	var topics: Array[Dictionary] = []
	var npc: Dictionary = get_data("npcs").get(npc_id, {})
	if str(npc.get("menu", "")).is_empty() or npc.get("dialogues", {}).has(step) 			or not get_courier_entry(npc_id).is_empty():
		return topics
	var seen: Array[String] = []
	for entry: Dictionary in _open_side_dialogues(npc_id):
		var topic: String = entry.get("topic", "")
		if not topic.is_empty() and not seen.has(topic):
			seen.append(topic)
			topics.append({"topic": topic, "dialogue": entry.get("dialogue", "")})
	return topics


## The talk menu of a figure with topics (get_npc_topics): its "menu" dialogue (a greeting line) with
## the choices "Reden" (its small talk), one per topic and "Tschüss". {} = no topics, the figure talks
## as always (get_npc_dialogue).
func get_npc_menu(npc_id: String) -> Dictionary:
	var topics: Array[Dictionary] = get_npc_topics(npc_id)
	if topics.is_empty():
		return {}
	var menu: Dictionary = get_dialogue(get_data("npcs")[npc_id]["menu"]).duplicate(true)
	var choices: Array = [{"text": menu.get("talk_text", "Reden"), "then": _get_npc_talk(npc_id)}]
	for topic: Dictionary in topics:
		choices.append({"text": topic["topic"], "then": topic["dialogue"]})
	choices.append({"text": menu.get("bye_text", "Tschüss")})
	menu["choices"] = choices
	return menu


## Small talk of a figure with a menu: the first open side dialogue without "topic", else its
## "daily" / "default" dialogue (id).
func _get_npc_talk(npc_id: String) -> String:
	for entry: Dictionary in _open_side_dialogues(npc_id):
		if str(entry.get("topic", "")).is_empty():
			return entry.get("dialogue", "")
	var dialogues: Dictionary = get_data("npcs").get(npc_id, {}).get("dialogues", {})
	var daily: Array = dialogues.get("daily", [])
	if not daily.is_empty():
		var day: int = (Engine.get_main_loop() as SceneTree).root.get_node("GameState").day_cycle.day
		return str(daily[posmod(day, daily.size())])
	return dialogues.get("default", "")


## The name of a figure (story.json "npcs.<id>.name"). "names" can give it another name for a time:
## [{"name", "if_flag", "unless_flag"}], the first that fits wins (e.g. Lake as the dark knight from
## lake_fallen until lake_redeemed).
func get_npc_name(npc_id: String) -> String:
	var npc: Dictionary = get_data("npcs").get(npc_id, {})
	for entry: Dictionary in npc.get("names", []):
		var if_flag: String = str(entry.get("if_flag", ""))
		var unless_flag: String = str(entry.get("unless_flag", ""))
		if (if_flag.is_empty() or has_flag(if_flag)) and (unless_flag.is_empty() or not has_flag(unless_flag)):
			return str(entry.get("name", npc_id))
	return npc.get("name", npc_id)


## How the figure speaks (story.json "npcs.<id>.voice", see Voice), "" = plain.
func get_npc_voice(npc_id: String) -> String:
	return str(get_data("npcs").get(npc_id, {}).get("voice", ""))


## true while story.json "villagers_away" sends the walking villagers away: one {"from", "until"}
## pair of flags or a list of them (e.g. the spring festival, the raid at night).
func are_villagers_away() -> bool:
	var away: Variant = get_data("villagers_away")
	var periods: Array = away if away is Array else [away]
	for period: Dictionary in periods:
		var from: String = period.get("from", "")
		var until: String = period.get("until", "")
		if not from.is_empty() and flags.has(from) and (until.is_empty() or not flags.has(until)):
			return true
	return false


## true once the figure's "gone_flag" (story.json "npcs.<id>.gone_flag") is set: it is gone from
## every scene for good (e.g. Nina after the raid).
func is_npc_gone(npc_id: String) -> bool:
	var gone_flag: String = get_data("npcs").get(npc_id, {}).get("gone_flag", "")
	return not gone_flag.is_empty() and flags.has(gone_flag)


func get_dialogue(dialogue_id: String) -> Dictionary:
	return get_data("dialogues").get(dialogue_id, {})


## One section of story.json.
static func get_data(section: String) -> Variant:
	return ContentDB.story_section(section)


func _check_progress() -> void:
	var data: Dictionary = get_step()
	var progress: Array = data.get("progress_flags", [])
	# With "shopping_done" the whole list ends the step (GameState), the flags only count along.
	if progress.is_empty() or not data.has("next") or data.get("shopping_done", false):
		return
	for flag: String in progress:
		if not flags.has(flag):
			return
	advance(data["next"])


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	# pending_hints: tips that count as shown already but still wait for the HUD (else a save
	# between queueing and showing would lose them for good).
	return {"step": step, "flags": flags.keys(), "shown_hints": shown_hints.duplicate(), "delivered": delivered.duplicate(true),
			"pending_hints": pending_hints.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	step = str(data.get("step", DONE))
	flags.clear()
	for flag: String in data.get("flags", []):
		flags[flag] = true
	# Steps that no longer exist (e.g. an old "Fortsetzung folgt") continue at their new step
	# (story.json "renamed_steps").
	var renamed: String = get_data("renamed_steps").get(step, "")
	if not renamed.is_empty():
		step = renamed
		flags["reached_" + step] = true
	# Flags that older saves did not know yet (story.json "implied_flags": flag -> more flags).
	var implied: Dictionary = get_data("implied_flags")
	for flag: String in implied:
		if flags.has(flag):
			for other: String in implied[flag]:
				flags[other] = true
	delivered.clear()
	var saved_delivered: Dictionary = data.get("delivered", {})
	for task_id: String in saved_delivered:
		delivered[task_id] = {}
		for key: String in saved_delivered[task_id]:
			delivered[task_id][key] = int(saved_delivered[task_id][key])
	shown_hints.clear()
	for hint_id: String in data.get("shown_hints", []):
		shown_hints.append(hint_id)
	pending_hints.clear()
	for hint: Variant in data.get("pending_hints", []):
		if hint is Dictionary:
			pending_hints.append(hint)
	changed.emit()
