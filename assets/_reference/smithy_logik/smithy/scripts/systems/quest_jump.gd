class_name QuestJump
extends RefCounted
## Test tool (admin panel, tab "Quests"): jumps to any single story step (StorySkip.jump_to does
## the flags), gives the items the step asks for and finds the place where it happens, so the
## story can be clicked through step by step with every dialogue and follow-up quest in the game.
## The place is a guess: the scene of a story figure with a dialogue for the step (where it is not
## away or hidden), else the scene of an "enter:" event, else the bed after a "sleep" event, else
## the current scene.

const WORLD_ROOT: String = "res://scenes/world"
const BED_SCENE: String = "res://scenes/world/smithy/bedroom.tscn"
const BED_SPAWN: StringName = &"InBed"
## The player stands this far below the figure (scene pixels), facing it.
const OFFSET_FROM_NPC: Vector2 = Vector2(0, 22)
## Story actions in dialogues whose items the player needs for the step.
const ITEM_ACTIONS: Array[String] = ["has_items", "take_items"]
## Story actions that finish a step (see score_of).
const FINISHING_ACTIONS: Array[String] = ["advance", "take_items", "pay_gold", "pay_rent", "hand_in_set", "story_order"]
const SCORE_FINISHES: int = 2
const SCORE_OWN: int = 1
const SCORE_WAITING: int = 0

## npc_id -> scene paths that contain a StoryNpc with it (built once, by reading the scene files).
static var _npc_scenes: Dictionary = {}


## [[chapter title, [step ids]], ...] in story order (StorySkip.CHAPTERS); steps before the first
## chapter go under "Anfang".
static func chapters_with_steps() -> Array:
	var starts: Dictionary = {}
	for chapter: Array in StorySkip.CHAPTERS:
		starts[chapter[1]] = chapter[0]
	var result: Array = []
	for step_id: String in Story.get_data("steps"):
		if starts.has(step_id) or result.is_empty():
			result.append([starts.get(step_id, "Anfang"), []])
		result[-1][1].append(step_id)
	return result


## The step after `step_id` in story order ("" at the end).
static func next_step(step_id: String) -> String:
	var steps: Array = Story.get_data("steps").keys()
	var index: int = steps.find(step_id)
	return steps[index + 1] if index >= 0 and index + 1 < steps.size() else ""


## Item lists (like give_items) the step asks for: "have_item", "show_items" and the has_items /
## take_items of the dialogues the figures have during it.
static func required_items(step_id: String) -> Array[String]:
	var step: Dictionary = Story.get_data("steps").get(step_id, {})
	var result: Array[String] = []
	for key: String in ["have_item", "show_items"]:
		if not str(step.get(key, "")).is_empty():
			result.append(str(step[key]))
	for specs: Variant in step.get("show_items_until", {}).values():
		result.append(str(specs))
	var seen: Array = []
	for npc_id: String in _npcs_of_step(step_id):
		_collect_items(str(Story.get_data("npcs")[npc_id].get("dialogues", {})[step_id]), result, seen)
	return result


## Story figures with a dialogue for the step.
static func _npcs_of_step(step_id: String) -> Array[String]:
	var result: Array[String] = []
	var npcs: Dictionary = Story.get_data("npcs")
	for npc_id: String in npcs:
		if npcs[npc_id].get("dialogues", {}).has(step_id):
			result.append(npc_id)
	return result


static func _collect_items(dialogue_id: String, result: Array[String], seen: Array) -> void:
	if dialogue_id.is_empty() or seen.has(dialogue_id):
		return
	seen.append(dialogue_id)
	var dialogue: Dictionary = Story.get_data("dialogues").get(dialogue_id, {})
	var actions: Array[String] = [str(dialogue.get("on_end", ""))]
	for line: Dictionary in dialogue.get("lines", []):
		actions.append(str(line.get("action", "")))
	for choice: Dictionary in dialogue.get("choices", []):
		actions.append(str(choice.get("action", "")))
		_collect_items(str(choice.get("then", "")), result, seen)
	_collect_items(str(dialogue.get("then", "")), result, seen)
	for text: String in actions:
		for action in text.split(";", false):
			action = action.strip_edges()
			if action.get_slice(":", 0) in ITEM_ACTIONS:
				var specs: String = action.substr(action.find(":") + 1)
				if not result.has(specs):
					result.append(specs)


## Where the step happens: {"scene": path, "spawn": spawn point, "position": Vector2 (INF = the
## spawn point / normal start), "npc": npc_id or ""}. "scene" = "" means: stay in the current scene.
## Call after the jump, so the flags of the figures (hidden, required) are those of the step.
## In this order: the figure whose dialogue finishes the step (advance, hand-in, paying, a progress
## flag), a figure with a dialogue of its own for this step, the scene whose entering finishes the
## step, the bed for "sleep", else the current scene (where the step before happened). Waiting lines
## a figure says in many steps (e.g. the king during the whole goblin chapter) never count.
static func location_of(step_id: String, current_scene: String) -> Dictionary:
	var preferred: Array[String] = [current_scene]
	var entered: String = _entered_scene(step_id)
	if not entered.is_empty():
		preferred.push_front(entered)
	for wanted: int in [SCORE_FINISHES, SCORE_OWN]:
		var found: Dictionary = _find_npc(step_id, preferred, wanted)
		if not found.is_empty():
			return found
	var events: Dictionary = Story.get_data("steps").get(step_id, {}).get("events", {})
	for event: String in events:
		if event.begins_with("enter:"):
			var path: String = _scene_by_name(event.trim_prefix("enter:"))
			if not path.is_empty():
				return {"scene": path, "spawn": &"", "position": Vector2.INF, "npc": ""}
	if events.has("sleep"):
		return {"scene": BED_SCENE, "spawn": BED_SPAWN, "position": Vector2.INF, "npc": ""}
	if not entered.is_empty():
		return {"scene": entered, "spawn": &"", "position": Vector2.INF, "npc": ""}
	return {"scene": "", "spawn": &"", "position": Vector2.INF, "npc": ""}


## How much a figure's dialogue for the step matters: SCORE_FINISHES = it finishes the step (its
## dialogue or a follow-up advances the story, takes or pays something, or sets a progress flag of
## the step), SCORE_OWN = a dialogue only for this step (or two), SCORE_WAITING = the same lines in
## many steps.
static func score_of(npc_id: String, step_id: String) -> int:
	var dialogues: Dictionary = Story.get_data("npcs").get(npc_id, {}).get("dialogues", {})
	var dialogue_id: Variant = dialogues.get(step_id, "")
	if not dialogue_id is String or str(dialogue_id).is_empty():
		return SCORE_WAITING
	var actions: Array[String] = []
	_collect_all_actions(str(dialogue_id), actions, [])
	var progress: Array = Story.get_data("steps").get(step_id, {}).get("progress_flags", [])
	for action in actions:
		var name: String = action.get_slice(":", 0)
		if name in FINISHING_ACTIONS or (name == "set_flag" and action.get_slice(":", 1) in progress):
			return SCORE_FINISHES
	var uses: int = dialogues.values().filter(func(other: Variant) -> bool: return other == dialogue_id).size()
	return SCORE_OWN if uses <= 2 else SCORE_WAITING


## Every story action of a dialogue and its follow-ups (choices, "then").
static func _collect_all_actions(dialogue_id: String, actions: Array[String], seen: Array) -> void:
	if dialogue_id.is_empty() or seen.has(dialogue_id):
		return
	seen.append(dialogue_id)
	var dialogue: Dictionary = Story.get_data("dialogues").get(dialogue_id, {})
	var texts: Array[String] = [str(dialogue.get("on_end", ""))]
	for entry: Dictionary in dialogue.get("lines", []):
		texts.append(str(entry.get("action", "")))
	for choice: Dictionary in dialogue.get("choices", []):
		texts.append(str(choice.get("action", "")))
		_collect_all_actions(str(choice.get("then", "")), actions, seen)
	_collect_all_actions(str(dialogue.get("then", "")), actions, seen)
	for text in texts:
		for action in text.split(";", false):
			actions.append(action.strip_edges())


## Scene the player entered to start this step (the step before has "enter:<scene>" » this step).
static func _entered_scene(step_id: String) -> String:
	var steps: Array = Story.get_data("steps").keys()
	var index: int = steps.find(step_id)
	if index <= 0:
		return ""
	var events: Dictionary = Story.get_data("steps")[steps[index - 1]].get("events", {})
	for event: String in events:
		if event.begins_with("enter:") and events[event] == step_id:
			return _scene_by_name(event.trim_prefix("enter:"))
	return ""


## The figure with a dialogue for the step that scores exactly `wanted` (score_of): the first one
## that is there now (not away, hidden or still waiting for its flag), scenes in `preferred` first.
## Falls back to one that is not there yet.
static func _find_npc(step_id: String, preferred: Array[String], wanted: int) -> Dictionary:
	var fallback: Dictionary = {}
	for npc_id: String in _npcs_of_step(step_id):
		if score_of(npc_id, step_id) != wanted:
			continue
		var scenes: Array = _scenes_with_npc(npc_id).duplicate()
		scenes.sort_custom(func(a: String, b: String) -> bool:
			return _rank(a, preferred) < _rank(b, preferred))
		for path: String in scenes:
			var packed: PackedScene = load(path) as PackedScene
			if packed == null:
				continue
			var root: Node = packed.instantiate()
			for node: Node in root.find_children("*", "StoryNpc", true, false):
				var npc := node as StoryNpc
				if npc.npc_id != npc_id or step_id in npc.absent_steps or not npc.roam_spot.is_empty():
					continue
				var hit: Dictionary = {"scene": path, "spawn": &"", "position": _scene_position(npc) + OFFSET_FROM_NPC,
					"npc": npc_id}
				var hidden: bool = not npc.hidden_when_flag.is_empty() and GameState.story.has_flag(npc.hidden_when_flag)
				if not hidden and GameState.story.has_flag(npc.required_flag):
					root.free()
					return hit
				if fallback.is_empty():
					fallback = hit
			root.free()
	return fallback


static func _rank(path: String, preferred: Array[String]) -> int:
	var index: int = preferred.find(path)
	return index if index >= 0 else preferred.size()


## Position of a node in the coordinates of its scene (the scene is not in the tree).
static func _scene_position(node: Node) -> Vector2:
	var transform := Transform2D.IDENTITY
	var current: Node = node
	while current:
		if current is Node2D:
			transform = (current as Node2D).transform * transform
		current = current.get_parent()
	return transform.origin


static func _scenes_with_npc(npc_id: String) -> Array:
	if _npc_scenes.is_empty():
		_index_scenes(WORLD_ROOT)
	return _npc_scenes.get(npc_id, [])


static func _index_scenes(folder: String) -> void:
	for sub_folder in DirAccess.get_directories_at(folder):
		_index_scenes(folder.path_join(sub_folder))
	for file in DirAccess.get_files_at(folder):
		var file_name: String = file.trim_suffix(".remap")
		if file_name.get_extension() != "tscn":
			continue
		var path: String = folder.path_join(file_name)
		var text: String = FileAccess.get_file_as_string(path)
		var at: int = text.find("npc_id = \"")
		while at >= 0:
			var start: int = at + "npc_id = \"".length()
			var npc_id: String = text.substr(start, text.find("\"", start) - start)
			if not _npc_scenes.has(npc_id):
				_npc_scenes[npc_id] = []
			if not _npc_scenes[npc_id].has(path):
				_npc_scenes[npc_id].append(path)
			at = text.find("npc_id = \"", start)


## Path of the scene with this file name (without .tscn) below WORLD_ROOT, "" if there is none.
static func _scene_by_name(scene_name: String) -> String:
	for map: Dictionary in AdminPanel.find_maps():
		if map.path.get_file().get_basename() == scene_name:
			return map.path
	return ""
