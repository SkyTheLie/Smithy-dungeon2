class_name LotteCourier
extends RefCounted
## Lotte as the messenger: while she has a "courier" side dialogue open (story.json
## "side_dialogues", e.g. a letter from the king in the morning), she comes to the player wherever
## they are (own bedroom, an inn, the summit of Sylvaris): she steps in at the nearest door, walks
## up to the player, plays the dialogue (it hands over the letter) and goes back out the same door.
## Checked from GameState._check_story_conditions (every 0.5 s). Not while a conversation, a fight
## or a scene change is going on, and not if a Lotte stands in the scene already (that one has the
## speech bubble and plays it when the player talks to her).

const NPC_ID: String = "niece"
## Lotte's PixelLab look (assets/sprites/residents/emma.png), as in the workshop.
const RESIDENT: String = "emma"
const STORY_NPC_SCENE: String = "res://scenes/actors/story_npc.tscn"
## Name of the spawned node (also how a test finds her).
const NODE_NAME: StringName = &"LotteCourier"
## Without a door in the scene she appears this far to the side of the player.
const FALLBACK_OFFSET: Vector2 = Vector2(56, 0)


## Spawns the courier in the current scene if a letter waits and the moment fits. Returns the new
## figure (null = nothing spawned).
static func check(tree: SceneTree) -> Node2D:
	var story: Story = GameState.story
	if GameState.in_main_menu or tree == null:
		return null
	var entry: Dictionary = story.get_courier_entry(NPC_ID)
	if entry.is_empty():
		return null
	var player := tree.get_first_node_in_group(Player.GROUP) as Node2D
	if player == null or not player.is_inside_tree() or player.get_parent() == null:
		return null
	if _busy(tree) or _lotte_here(tree):
		return null
	var npc := (load(STORY_NPC_SCENE) as PackedScene).instantiate() as Node2D
	npc.name = NODE_NAME
	npc.set("npc_id", NPC_ID)
	npc.set("resident", RESIDENT)
	npc.set("required_flag", str(entry.get("flag", "")))
	npc.set("hidden_when_flag", str(entry.get("done_flag", "")))
	npc.set("auto_talk", true)
	npc.set("walk_to_player", true)
	npc.set("keep_dialogue_open", true)
	var parent: Node2D = player.get_parent() as Node2D
	npc.position = parent.to_local(_entry_point(tree, player))
	parent.add_child(npc)
	return npc


## true while something else has the screen: an open conversation, a fight, a fade.
static func _busy(tree: SceneTree) -> bool:
	for box in tree.get_nodes_in_group(DialogueBox.GROUP):
		if box is CanvasItem and (box as CanvasItem).is_visible_in_tree():
			return true
	var battle := tree.get_first_node_in_group(BattleWindow.GROUP) as Control
	return battle != null and battle.visible


## true if a Lotte is in the scene already (the courier, the one in the workshop, a companion).
static func _lotte_here(tree: SceneTree) -> bool:
	for node in tree.get_nodes_in_group(StoryNpc.GROUP):
		if node.get("npc_id") == NPC_ID and (node as CanvasItem).visible:
			return true
	return false


## Where she comes in (global): the door nearest to the player, else a spawn point, else beside them.
## Hidden doors (e.g. the hall-of-fame door in the bedroom before the hall is built) don't count.
static func _entry_point(tree: SceneTree, player: Node2D) -> Vector2:
	var best: Node2D = null
	for group in [Door.EXIT_GROUP, &"spawn_points"]:
		for node in tree.get_nodes_in_group(group):
			if node is Node2D and node.is_inside_tree() and (node as Node2D).is_visible_in_tree() \
					and (best == null \
					or player.global_position.distance_to(node.global_position) \
					< player.global_position.distance_to(best.global_position)):
				best = node
		if best:
			break
	if best == null or best.global_position.distance_to(player.global_position) < 8.0:
		return player.global_position + FALLBACK_OFFSET
	return best.global_position
