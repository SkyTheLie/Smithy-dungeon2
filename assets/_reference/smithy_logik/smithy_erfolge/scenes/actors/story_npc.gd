class_name StoryNpc
extends Station
## A story figure or object (e.g. Oma Hilde, the "Zu vermieten" sign). Talk to it with E: it
## plays its dialogue for the current story step (story.json "npcs.<npc_id>.dialogues", else
## "default") in its DialogueBox; E again shows the next line. "!" above it = it has something
## new for the current step. With an `appearance` the figure is drawn with CharacterBaker.
## With `walk_to_player` (and `auto_talk`) the figure walks up to the player before talking, and
## walks back to where it stood and vanishes once `hidden_when_flag` is set. Any other figure that
## leaves walks out of the map to the nearest spawn point (a door, the edge of the map) instead of
## vanishing on the spot, once the conversation it takes part in is over (see _leave).
## A figure whose `required_flag` is not set yet waits invisibly and appears as soon as the flag
## is set (e.g. a customer who comes along during a conversation). During `absent_steps` the
## figure is away (e.g. Gustav is inside the mine, not in front of it).

## Id in story.json "npcs".
@export var npc_id: String = ""
## Look of a figure (empty = no figure, e.g. a sign with its own picture).
@export var appearance: Appearance
## A hero template whose look this figure has (e.g. Bruno before he is hired).
@export var hero: Hero
## Picture of a figure instead of a generated look (48x48, e.g. the woodcutter).
@export var figure_texture: Texture2D
## Size of `figure_texture` (e.g. 2 for a boss standing in the world); the feet stay where they are,
## the name label moves up with the head.
@export var figure_scale: float = 1.0
## A PixelLab resident (assets/sprites/residents/<id>.png, player sheet layout) as the look,
## e.g. Lotte.
@export var resident: String = ""
## With `resident`: wears the cloak ("<resident>_hooded") until this story flag is set. The cut scene
## "hood_back" plays the sheet HOOD_BACK_SHEET in between (Nyra).
@export var hood_off_flag: String = ""
## The figure / object disappears once this story flag is set (e.g. the sign after renting).
## It only appears once `required_flag` (Station) is set.
@export var hidden_when_flag: String = ""
## Starts talking by itself when the scene loads and it has something new (cut scene).
@export var auto_talk: bool = false
## With auto_talk: walk up to the player first (e.g. Nina on the market).
@export var walk_to_player: bool = false
## The dialogue stays open when the player walks away (it carries a cutscene that must play to the end).
@export var keep_dialogue_open: bool = false
## Size of the talking area (e.g. (1, 2) = twice as deep, to talk across a counter).
@export var talk_area_scale: Vector2 = Vector2.ONE
## With auto_talk: only start talking when the player comes into the talking area.
@export var wait_for_player: bool = false
## With auto_talk: also starts talking when a new story step gives it something new while the
## player is in the scene (e.g. Gustav after the fight in the mine).
@export var talk_on_new_step: bool = false
## Story steps during which the figure is not here.
@export var absent_steps: PackedStringArray = []
## Story steps during which the figure is not here when the player enters the map, but if it is
## already standing here when the step begins it stays put instead of walking away (e.g. the council
## table on the summit of Sylvaris: the others stay at the table while the player goes to bed).
@export var linger_steps: PackedStringArray = []
## Lies on the ground (figure turned on its side, e.g. Bruno sleeping by the fountain).
@export var lying: bool = false
## Direction a generated figure looks at ("down", "up", "left", "right"), e.g. "up" in a crowd.
@export_enum("down", "up", "left", "right") var facing: String = "down"
## Nobody to see: no figure, name, "!" or body, only the dialogue (e.g. the narrator on the empty
## village square). Use with auto_talk and a big talk_area_scale.
@export var narrator: bool = false
## Once `hidden_when_flag` is set the figure vanishes on the spot instead of walking away (e.g. Bruno,
## who then walks along with the player as a Companion, or the lich slain in a cut scene).
@export var vanish_on_leave: bool = false
## When it leaves, the figure walks along these points (scene coordinates of its parent) and
## vanishes at the last one, e.g. out of the map on the right (with walk_to_player: instead of
## back home). Without walk_to_player it strolls and goes around obstacles between the points
## (VillageRoads), e.g. the villagers going home after the spring festival.
@export var leave_path: PackedVector2Array = []
## Doors (Door nodes) the figure leaves through instead of the nearest exit: the first one that is
## visible counts (e.g. the small or the big main door of the smithy, depending on the house level).
## It walks sideways until it is level with the door, then straight to it, and vanishes there.
@export var leave_doors: Array[NodePath] = []
## When its required_flag is set while the scene is open, the figure appears at the first of these
## points (scene coordinates of its parent) and walks along them to its place instead of popping up
## there (e.g. Faelan coming onto Aurelius' clearing from the south). Loaded later it just stands there.
@export var arrive_path: PackedVector2Array = []
## Only reacts to E while it has something for the current step ("!"); otherwise E goes to what
## else stands here (e.g. the old chest with the axe recipes, then the storage chest).
@export var silent_without_news: bool = false
## A figure that moves around the village (npcs.json "roam", see Roaming): this node is one of its
## places ("home", "smithy", "village_center", "market", "nina_shop") and the figure is only here
## while Roaming puts it here.
@export var roam_spot: String = ""
## Ways out of the scene for a roaming figure: {place it goes to (or comes from): way, "default":
## way for every other place}. A way is an exit point (Vector2) or points from here to the exit
## (PackedVector2Array), scene coordinates of the parent, or the path of a node (String, from the
## parent, e.g. "Smithy/DoorToSmithy": Lotte walks to the smithy door when she goes to the workshop).
## When its place changes the figure walks
## out along it and vanishes; when it arrives it walks in along it the other way round. A single
## exit point is reached along the streets if the scene has VillageRoads.
@export var roam_exits: Dictionary = {}
## Once `hidden_when_flag` is set the figure walks to this point (scene coordinates of its parent)
## and stays there, looking towards `aside_facing`, instead of leaving (e.g. the goblin guards who
## step aside from the bridge). ZERO = not used. Loaded with the flag set it stands there already.
@export var aside_position: Vector2 = Vector2.ZERO
@export_enum("down", "up", "left", "right") var aside_facing: String = "down"
## While `watch_flag` is set and `watch_until_flag` is not, the figure's place is next to this node
## (its position + `watch_offset`), looking towards `watch_facing`, e.g. Lotte beside the anvil
## during the side task "Lotte schaut zu". Follows the node if it was moved (build mode).
@export var watch_node: NodePath
@export var watch_offset: Vector2 = Vector2.ZERO
@export_enum("down", "up", "left", "right") var watch_facing: String = "down"
@export var watch_flag: String = ""
@export var watch_until_flag: String = ""

## All story figures of the scene (the dialogue box looks up other speakers here).
const GROUP: StringName = &"story_npcs"
const HOOD_BACK_SHEET: String = "res://assets/sprites/finster/nyra_hood_back.png"
const HOOD_BACK_TIME: float = 0.9

## E talks to a figure only this close: its normal talk area, scaled at most this much (see
## is_player_close; a bigger talk_area_scale only widens where it talks by itself).
const MAX_E_AREA_SCALE: float = 2.0
## Seconds between two checks whether a roaming figure moved on.
const ROAM_CHECK_INTERVAL: float = 2.0
## Seconds before an automatic conversation starts.
const AUTO_TALK_DELAY: float = 0.6
## Walking speed (pixels per second) and how close the figure comes before talking.
const WALK_SPEED: float = 95.0
const TALK_DISTANCE: float = 16.0
## Walking speed of a roaming figure on its way between two places (like the villagers).
const ROAM_SPEED: float = 36.0
## A figure that leaves this soon (seconds of game time) after a "fade" cut scene vanishes behind
## the black instead.
const FADE_LEAVE_SECONDS: float = 1.5
## An exit this close to a camera limit is a map edge (_exit_way); a leaving figure walks this far
## past it, out of the picture.
const EDGE_MARGIN: float = 64.0
const EDGE_WALK_OUT: float = 40.0
## A figure whose place is this close to a door came out of it and goes back in (_home_at_door).
const DOOR_HOME_DISTANCE: float = 48.0
## Camera2D limits at least this big count as "no limit" (Godot's default is 10 000 000).
const NO_LIMIT: int = 1000000
## Seconds between two checks whether this figure's name overlaps another figure's name, and the
## pixels between two stacked names (see _stack_name).
const NAME_CHECK_INTERVAL: float = 0.2
const NAME_GAP: float = 1.0

enum Walk { NONE, TO_PLAYER, BACK, AWAY, ROAM_OUT, ROAM_IN, OUT, ASIDE }

var _walk: Walk = Walk.NONE
## With ROAM_OUT / ROAM_IN: the points (global) to walk along, and the next one.
var _roam_path: PackedVector2Array = []
var _roam_point: int = 0
## Pixels per second along _roam_path (faster for an arrival along arrive_path).
var _roam_speed: float = ROAM_SPEED
## Time spent walking (for the walk frames) and the direction the figure looks at.
var _walk_time: float = 0.0
var _direction: String = "down"
var _home: Vector2
## false while the figure waits for its required_flag (invisible, can't be talked to).
var _present: bool = true
var _auto_talk_started: bool = false
## The dialogue it last started by itself when the player came close (wait_for_player).
var _last_auto_dialogue: Dictionary = {}
## The step whose dialogue is open now ("" = another one): marked as told when it closes.
var _telling_step: String = ""  # not saved on purpose: the told mark itself is saved in Story
## With Walk.AWAY: index of the leave_path point the figure walks to.
var _leave_point: int = 0
## true once it should leave; it goes as soon as no open conversation has a line of it any more.
var _leave_pending: bool = false
## Set from outside to make a figure on its way wait on the spot (e.g. FloatingStoneRing: at the
## edge of a gap until its stone bridge stands). Not saved: it is set again every frame.
var walk_held: bool = false
## true for FADE_LEAVE_SECONDS after a "fade" cut scene.
var _fade_recent: bool = false
## Where the figure picture stands upright (a lying figure gets back there in _stand_up).
var _figure_position: Vector2
## Own place (y) of the name and the "!" before _stack_name lifts them above another name.
var _name_base_y: float = 0.0
var _marker_base_y: float = 0.0

@onready var _dialogue: DialogueBox = $DialogueBox
@onready var _marker: Label = get_node_or_null("Marker")


## figure_scale: the picture grows upwards from its feet, the name and the "!" go up with it.
func _scale_figure(figure: Sprite2D) -> void:
	var half: float = figure_texture.get_height() / 2.0
	var feet: float = figure.position.y + half
	figure.scale = Vector2.ONE * figure_scale
	figure.position.y = feet - half * figure_scale
	var rise: float = half * 2.0 * (figure_scale - 1.0)
	for part_name in ["NameLabel", "Marker"]:
		var part := get_node_or_null(part_name) as Control
		if part:
			part.position.y -= rise


## Guide target of a story figure: "npc:<npc_id>" (e.g. "npc:landlady").
func get_guide_id() -> String:
	return guide_id if not guide_id.is_empty() else "npc:" + npc_id


func _ready() -> void:
	var stepped_aside: bool = false
	if not hidden_when_flag.is_empty() and GameState.story.has_flag(hidden_when_flag):
		if aside_position == Vector2.ZERO:
			queue_free()
			return
		position = aside_position
		facing = aside_facing
		stepped_aside = true
	add_to_group(GROUP)
	# _ready does not call super(): join the list E picks from (Station.is_nearest_interactable) here,
	# else a station next to the figure takes every E, even while its conversation is open (anvil in
	# the dungeon forge opened its menu instead of turning Halvard's page)
	add_to_group(INTERACT_GROUP)
	Events.cutscene_requested.connect(_on_cutscene)
	if hero and appearance == null:
		appearance = hero.get_appearance()
	var figure := get_node_or_null("Figure") as Sprite2D
	if figure and figure_texture:
		figure.texture = figure_texture
		figure.region_enabled = false
		if not is_equal_approx(figure_scale, 1.0):
			_scale_figure(figure)
	elif figure and _get_resident_sheet():
		figure.texture = _get_resident_sheet()
		figure.region_rect = CharacterBaker.get_frame_rect("down")
	elif figure and appearance:
		figure.texture = CharacterBaker.get_sheet(appearance)
		figure.region_rect = CharacterBaker.get_frame_rect("down")
		figure.scale = Vector2.ONE * appearance.get_scale()
	if figure:
		_figure_position = figure.position
	if figure and lying:
		figure.rotation_degrees = -90.0
		figure.position = Vector2(0, -6)
	_face(facing)
	var name_label := get_node_or_null("NameLabel") as Label
	if name_label:
		name_label.text = GameState.story.get_npc_name(npc_id)
	if narrator:
		for part in [figure, name_label, _marker]:
			if part:
				part.hide()
		_marker = null
		($CollisionShape2D as CollisionShape2D).disabled = true
	$InteractionArea.scale = talk_area_scale
	_home = position
	if stepped_aside:
		auto_talk = false
	# deferred: moved stations get their saved place in their own _ready / layout first
	_apply_watch_spot.call_deferred()
	interacted.connect(_on_interacted)
	player_left.connect(_on_player_left)
	_dialogue.finished.connect(_on_dialogue_finished)
	GameState.story.changed.connect(_on_story_changed)
	GameState.story.step_started.connect(_on_step_started)
	if _should_be_here():
		_try_auto_talk()
	else:
		_set_present(false)
	_update_marker()
	if not roam_spot.is_empty():
		var timer := Timer.new()
		timer.wait_time = ROAM_CHECK_INTERVAL
		timer.autostart = true
		timer.timeout.connect(_on_story_changed)
		add_child(timer)
	if name_label and not narrator:
		_name_base_y = name_label.position.y
		_marker_base_y = _marker.position.y if _marker else 0.0
		var name_timer := Timer.new()
		name_timer.wait_time = NAME_CHECK_INTERVAL
		name_timer.autostart = true
		name_timer.timeout.connect(_stack_name)
		add_child(name_timer)


## Two figures side by side (e.g. Nyra holding Halvard): the names would lie on top of each other
## and over the heads. The figure that came later into the tree lifts its name (and "!") above the
## other one's.
func _stack_name() -> void:
	var name_label := get_node_or_null("NameLabel") as Label
	if name_label == null or not name_label.is_visible_in_tree():
		return
	var lift: float = 0.0
	name_label.position.y = _name_base_y
	for _round in 3:
		var mine: Rect2 = _name_rect(name_label)
		var moved: bool = false
		for other in get_tree().get_nodes_in_group(GROUP):
			if other == self or not other is StoryNpc or other.get_instance_id() > get_instance_id():
				continue
			var other_label := (other as Node).get_node_or_null("NameLabel") as Label
			if other_label == null or not other_label.is_visible_in_tree():
				continue
			var theirs: Rect2 = (other as StoryNpc)._name_rect(other_label)
			if mine.intersects(theirs):
				var up: float = mine.end.y - theirs.position.y + NAME_GAP
				lift += up
				name_label.position.y -= up
				mine = _name_rect(name_label)
				moved = true
		if not moved:
			break
	if _marker:
		_marker.position.y = _marker_base_y - lift


## The part of the name label the text covers (global), not the whole 80 px box.
func _name_rect(label: Label) -> Rect2:
	var font: Font = label.get_theme_font("font")
	var size: int = label.get_theme_font_size("font_size")
	var text_width: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var box: Rect2 = label.get_global_rect()
	var height: float = font.get_height(size) * 0.7
	return Rect2(box.get_center().x - text_width / 2.0, box.get_center().y - height / 2.0, text_width, height)


func _should_be_here() -> bool:
	return GameState.story.has_flag(required_flag) and not absent_steps.has(GameState.story.step) \
			and not GameState.story.is_npc_gone(npc_id) \
			and (roam_spot.is_empty() or Roaming.is_at(npc_id, roam_spot))


## Portrait for the dialogue box.
func get_portrait() -> Texture2D:
	if _get_resident_sheet():
		return CharacterBaker.get_sheet_portrait(_get_resident_sheet())
	if appearance:
		return CharacterBaker.get_portrait(appearance)
	return figure_texture


func _get_resident_sheet() -> Texture2D:
	var name_of_sheet: String = resident
	if not hood_off_flag.is_empty() and not GameState.story.has_flag(hood_off_flag):
		name_of_sheet += "_hooded"
	var path: String = Villager.RESIDENT_DIR + name_of_sheet + ".png"
	return load(path) if not resident.is_empty() and ResourceLoader.exists(path) else null


## Gestures (act:<npc_id>:…, see NpcActing); the figure pushes the hood back (the end of the sheet is
## the look without the cloak).
func _on_cutscene(cutscene_id: String) -> void:
	if cutscene_id.begins_with("act:"):
		# a gesture of this figure (NpcActing), e.g. "act:goblin_king:bite:bronze_ingot"
		var parts: PackedStringArray = cutscene_id.split(":", true, 3)
		if parts.size() >= 3 and parts[1] == npc_id and _present and visible:
			NpcActing.play(self, parts[2], parts[3] if parts.size() > 3 else "")
		return
	if cutscene_id == "fade" and is_inside_tree():
		_fade_recent = true
		get_tree().create_timer(FADE_LEAVE_SECONDS, false).timeout.connect(_end_fade_window)
	var figure := get_node_or_null("Figure") as Sprite2D
	if cutscene_id != "hood_back" or hood_off_flag.is_empty() or figure == null:
		return
	var sheet: Texture2D = load(HOOD_BACK_SHEET)
	var count: int = sheet.get_width() / CharacterBaker.FRAME
	figure.texture = sheet
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		figure.region_rect = Rect2(mini(int(value), count - 1) * CharacterBaker.FRAME, 0, CharacterBaker.FRAME, CharacterBaker.FRAME),
		0.0, float(count), HOOD_BACK_TIME)
	await tween.finished
	figure.texture = _get_resident_sheet()
	_face(_direction)


func _on_story_changed() -> void:
	# the name can change with the story (story.json "names", e.g. Lake as the dark knight)
	var name_label := get_node_or_null("NameLabel") as Label
	if name_label and name_label.visible:
		name_label.text = GameState.story.get_npc_name(npc_id)
	# a step that starts while the scene is open (e.g. the morning after a night on the spot) moves
	# the figure to its watch spot at once
	if not _dialogue.visible:
		_apply_watch_spot()
	if not _present and _should_be_here():
		_set_present(true)
		_roam_in()
		_try_auto_talk()
	elif _present and not _should_be_here() and not _dialogue.visible and _walk == Walk.NONE \
			and not linger_steps.has(GameState.story.step):
		if not _roam_out() and not _walk_off(Walk.ROAM_OUT):
			_set_present(false)
	# Sent away by someone else's conversation (e.g. Oma Hilde after the first customer's order): goes
	# once that conversation has nothing more for it to say (see _physics_process).
	if _present and not _dialogue.visible and _walk == Walk.NONE and not hidden_when_flag.is_empty() \
			and GameState.story.has_flag(hidden_when_flag) and not _is_aside():
		_leave_pending = true
	if _present and _dialogue.visible and not hidden_when_flag.is_empty() \
			and GameState.story.has_flag(hidden_when_flag) and _replaced_by_other():
		_hide_body()
	_update_marker()


## true if another figure of the same person appears here now (e.g. Aurelius standing up after the
## tonic while the lying one still talks): this one must not be seen twice.
func _replaced_by_other() -> bool:
	for other in get_tree().get_nodes_in_group(GROUP):
		if other != self and other.get("npc_id") == npc_id and other.has_method("_should_be_here") \
				and other.call("_should_be_here"):
			return true
	return false


## Hides the figure, name and "!" but keeps the open conversation (it goes on with the other figure
## on screen); the node itself leaves when the conversation ends (_on_dialogue_finished).
## true if the figure can be seen now: in the scene and its body not hidden (e.g. the dark Lake
## whose body a cut scene hid while the light Lake takes his place).
func is_shown() -> bool:
	var figure := get_node_or_null("Figure") as CanvasItem
	return is_visible_in_tree() and (figure == null or figure.visible)


func _hide_body() -> void:
	for part_name in ["Figure", "NameLabel", "Shadow"]:
		var part := get_node_or_null(part_name) as CanvasItem
		if part:
			part.hide()
	if _marker:
		_marker.hide()
		_marker = null
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape:
		body_shape.set_deferred("disabled", true)


func _set_present(present: bool) -> void:
	_present = present
	visible = present
	blocked = not present
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape:
		body_shape.set_deferred("disabled", not present or narrator)


## With talk_on_new_step: a new step may give the figure something new to say.
## Not a figure that leaves with this step (hidden_when_flag just set, e.g. Kahn in the arena once
## "Rat in der Strömung" starts): that talk belongs to the figure in the other scene (his hall).
func _on_step_started(_step: String) -> void:
	var leaving: bool = not hidden_when_flag.is_empty() and GameState.story.has_flag(hidden_when_flag) and not _is_aside()
	if talk_on_new_step and _present and not leaving:
		_auto_talk_started = false
		_try_auto_talk()


func _try_auto_talk() -> void:
	if not auto_talk or wait_for_player or _auto_talk_started or not GameState.story.has_untold_news(npc_id):
		return
	_auto_talk_started = true
	get_tree().create_timer(AUTO_TALK_DELAY, false).timeout.connect(_start_auto_talk)


## With wait_for_player: talk as soon as the player comes close (and the figure has news).
func _on_interaction_area_body_entered(body: Node2D) -> void:
	super(body)
	if body is Player and auto_talk and wait_for_player and _present and not _dialogue.visible \
			and _walk != Walk.OUT and GameState.story.has_untold_news(npc_id):  # not while leaving
		# The same dialogue only once by itself (e.g. Halvard's "Am Amboss ..." while the player walks
		# round the anvil in his big area); after that only with E.
		var dialogue: Dictionary = GameState.story.get_npc_dialogue(npc_id)
		if dialogue == _last_auto_dialogue:
			return
		_last_auto_dialogue = dialogue
		_on_interacted()


func _start_auto_talk() -> void:
	# the delay is over: the figure may be leaving by now, or the news is told already
	if not _present or _walk == Walk.OUT or _leave_pending or not GameState.story.has_untold_news(npc_id):
		return
	# the fight that brought the news may still be on screen (tournament final): wait for its window
	var battle := get_tree().get_first_node_in_group(BattleWindow.GROUP) as Control
	if battle and battle.visible:
		get_tree().create_timer(AUTO_TALK_DELAY, false).timeout.connect(_start_auto_talk)
		return
	if walk_to_player:
		_walk = Walk.TO_PLAYER
	else:
		_on_interacted()


func _physics_process(delta: float) -> void:
	if _leave_pending and _walk == Walk.NONE and not _dialogue.visible and (vanish_on_leave or not _is_still_talking()):
		_leave_pending = false
		_leave()
	if _walk == Walk.NONE:
		return
	if _walk == Walk.ROAM_OUT or _walk == Walk.ROAM_IN or _walk == Walk.OUT:
		_walk_roam(delta)
		return
	var target: Vector2 = _home
	if _walk == Walk.ASIDE:
		target = (get_parent() as Node2D).to_global(aside_position)
	elif _walk == Walk.AWAY:
		target = (get_parent() as Node2D).to_global(leave_path[_leave_point])
	elif _walk == Walk.TO_PLAYER:
		var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
		if player == null:
			return
		target = player.global_position
	var offset: Vector2 = target - global_position
	var stop_distance: float = TALK_DISTANCE if _walk == Walk.TO_PLAYER else 1.0
	if offset.length() <= stop_distance:
		if _walk == Walk.TO_PLAYER:
			_walk = Walk.NONE
			($CollisionShape2D as CollisionShape2D).set_deferred("disabled", narrator)
			_face("down")
			_on_interacted()
		elif _walk == Walk.AWAY and _leave_point < leave_path.size() - 1:
			_leave_point += 1
		elif _walk == Walk.ASIDE:
			_walk = Walk.NONE
			position = aside_position
			_home = position
			($CollisionShape2D as CollisionShape2D).set_deferred("disabled", narrator)
			_face(aside_facing)
		else:
			queue_free()
		return
	# walks past the player instead of pushing him along (as in _start_roam)
	var body_shape := $CollisionShape2D as CollisionShape2D
	if not body_shape.disabled:
		body_shape.set_deferred("disabled", true)
	if _walk != Walk.AWAY and _walk != Walk.ASIDE:  # a leave_path / aside spot is laid out by hand
		offset = _next_point_towards(target) - global_position
	_walk_step(offset, WALK_SPEED, delta)


## The next point on the way to `target`: around obstacles if the map has roads (their navigation
## mesh), planned anew every step because the player moves.
func _next_point_towards(target: Vector2) -> Vector2:
	var roads: VillageRoads = _find_roads()
	if roads == null:
		return target
	var way: PackedVector2Array = roads.plan_through(global_position, PackedVector2Array([target]))
	return way[0] if not way.is_empty() else target


## Moves towards `offset` (at most `speed` * `delta`) and shows the walk frames in that direction.
func _walk_step(offset: Vector2, speed: float, delta: float) -> void:
	global_position += offset.limit_length(speed * delta)
	_walk_time += delta
	var frame: int = 1 + int(_walk_time * CharacterBaker.WALK_SPEED) % (CharacterBaker.COLUMNS - 1)
	if absf(offset.x) > absf(offset.y):
		_face("right" if offset.x > 0.0 else "left", frame)
	else:
		_face("down" if offset.y > 0.0 else "up", frame)


## Turns a generated figure (appearance) to a direction ("down", "up", "left", "right"); `frame`
## 1..6 are the walk frames, 0 is standing.
func _face(direction: String, frame: int = 0) -> void:
	_direction = direction
	var figure := get_node_or_null("Figure") as Sprite2D
	if figure and (appearance or not resident.is_empty()) and figure_texture == null:
		figure.region_rect = CharacterBaker.get_frame_rect(direction, frame)


# --- roaming: walking out of the scene and into it ---------------------------------------------

## The place changed: walk out towards the next place. false if there is no way out (vanish), or
## the figure now walks along with the player (Assistant.FOLLOWING: a Companion takes over at once).
func _roam_out() -> bool:
	if roam_spot.is_empty() or not is_inside_tree() or Roaming.get_destination(npc_id) == Assistant.FOLLOWING:
		return false
	var way: PackedVector2Array = _roam_way(Roaming.get_destination(npc_id), false)
	if way.is_empty():
		return false
	_start_roam(Walk.ROAM_OUT, way)
	return true


## Just arrived (the scene was already open): appear at the exit towards where it came from and
## walk to its place.
func _roam_in() -> void:
	if roam_spot.is_empty() and not arrive_path.is_empty() and is_inside_tree():
		var parent := get_parent() as Node2D
		var path := PackedVector2Array()
		for point: Vector2 in arrive_path:
			path.append(parent.to_global(point))
		path.append(parent.to_global(_home))
		global_position = path[0]
		path.remove_at(0)
		_start_roam(Walk.ROAM_IN, path)
		_roam_speed = WALK_SPEED
		return
	if roam_spot.is_empty() or not is_inside_tree():
		return
	var way: PackedVector2Array = _roam_way(Roaming.get_origin(npc_id), true)
	if way.is_empty():
		return
	global_position = way[0]
	way.remove_at(0)
	_start_roam(Walk.ROAM_IN, way)


func _start_roam(walk: Walk, way: PackedVector2Array) -> void:
	_walk = walk
	_roam_path = way
	_roam_point = 0
	_roam_speed = ROAM_SPEED
	_walk_time = 0.0
	# walks past the player instead of pushing him or getting stuck on him
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)


## Stands next to `watch_node` while its flags say so (see watch_node).
func _apply_watch_spot() -> void:
	if watch_node.is_empty() or not GameState.story.has_flag(watch_flag) 			or (not watch_until_flag.is_empty() and GameState.story.has_flag(watch_until_flag)):
		return
	var target := get_node_or_null(watch_node) as Node2D
	if target == null:
		return
	_home = (get_parent() as Node2D).to_local(target.global_position + watch_offset)
	facing = watch_facing
	if _walk == Walk.NONE:
		position = _home
		_face(facing)


## Points (global) from the place to the exit towards `place` (`inward`: from the exit to the
## place, the first point is the exit). Empty if the scene has no way for it.
func _roam_way(place: String, inward: bool) -> PackedVector2Array:
	var entry: Variant = roam_exits.get(place, roam_exits.get("default"))
	var parent := get_parent() as Node2D
	if entry is String or entry is NodePath:
		var exit_node := parent.get_node_or_null(NodePath(str(entry))) as Node2D
		entry = parent.to_local(exit_node.global_position) if exit_node else roam_exits.get("default")
	if entry == null or entry is String or entry is NodePath:
		return PackedVector2Array()
	var home: Vector2 = parent.to_global(_home)
	if entry is Vector2:
		var exit: Vector2 = parent.to_global(entry)
		var roads: VillageRoads = _find_roads()
		if roads == null:
			return PackedVector2Array([exit, home]) if inward else PackedVector2Array([exit])
		if inward:
			var way_in := PackedVector2Array([exit])
			way_in.append_array(roads.find_path(exit, _closest_road(roads, home), home))
			return way_in
		return roads.find_path(home, _closest_road(roads, exit), exit)
	var way := PackedVector2Array()
	for point: Vector2 in entry:
		way.append(parent.to_global(point))
	if inward:
		way.reverse()
		way.append(home)
	return way


func _find_roads() -> VillageRoads:
	for child in get_parent().get_children():
		if child is VillageRoads:
			return child
	return null


func _closest_road(roads: VillageRoads, to: Vector2) -> Marker2D:
	var best: Marker2D = null
	for point in roads.get_children():
		if point is Marker2D and (best == null or point.global_position.distance_to(to) < best.global_position.distance_to(to)):
			best = point
	return best


func _walk_roam(delta: float) -> void:
	if _dialogue.visible or walk_held:  # stops to talk, or waits (e.g. for a bridge)
		_face(_direction)
		return
	if _roam_point >= _roam_path.size():
		if _walk == Walk.OUT:
			queue_free()
		else:
			_end_roam()
		return
	var offset: Vector2 = _roam_path[_roam_point] - global_position
	if offset.length() <= 1.0:
		_roam_point += 1
		return
	_walk_step(offset, _roam_speed, delta)


func _end_roam() -> void:
	var walked_out: bool = _walk == Walk.ROAM_OUT
	_walk = Walk.NONE
	position = _home
	_face(facing)
	if walked_out:
		_set_present(false)
	else:
		($CollisionShape2D as CollisionShape2D).set_deferred("disabled", narrator)
		if not _should_be_here():  # the place changed again on the way
			_on_story_changed()


func wants_interact() -> bool:
	# A conversation that stays open (keep_dialogue_open) turns its pages with E wherever the player
	# stands, e.g. the dragon's wake-up, where a cutscene walks the player out of the talk area; so
	# does one that holds the player still while the figure walked off (see _on_player_left).
	if (keep_dialogue_open or _dialogue.freezes_player) and _dialogue.visible and visible and not blocked:
		return true
	if not super():
		return false
	if _dialogue.visible:
		return true
	# A narrator has nothing to say without news: its big talk area must not swallow E meant for
	# what stands in it (e.g. the herald on the tournament ground). A narrator with a standing text
	# ("default" or "daily", e.g. the mural and sockets at the storm temple) still answers E right in
	# front of it.
	if (silent_without_news or narrator) and not GameState.story.npc_has_news(npc_id):
		return narrator and not silent_without_news and is_player_close() \
				and not GameState.story.get_npc_dialogue(npc_id).is_empty()
	# A figure's big talk area (talk_area_scale) is for talking by itself (auto_talk); E only starts a
	# conversation near the figure, else E goes to what the player stands at (e.g. the lift in Sylvaris
	# while Aurelius fights across the map).
	return narrator or is_player_close()


## An open conversation keeps E (it turns the page), whatever stands nearer.
func interact_priority() -> int:
	return 1 if _dialogue.visible else 0


## true while the figure walks somewhere on its own (to the player, away, out of the map ...).
func is_walking() -> bool:
	return _walk != Walk.NONE


## true if the player stands within the normal talk area, at most MAX_E_AREA_SCALE times as big
## (enough to talk across a counter).
func is_player_close() -> bool:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var area := $InteractionArea as Node2D
	var shape_node := area.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape_node.shape as RectangleShape2D
	if player == null or rect == null:
		return true
	# In the area's own coordinates the scale is taken out again: the plain shape is the normal area.
	# Its offset shrinks with it, or the box of a big talk area (Aurelius in Sylvaris, 20x) would sit
	# far above the figure.
	var factor := Vector2(minf(talk_area_scale.x, MAX_E_AREA_SCALE) / talk_area_scale.x,
			minf(talk_area_scale.y, MAX_E_AREA_SCALE) / talk_area_scale.y)
	var local: Vector2 = area.to_local(player.global_position) - shape_node.position * factor
	var half: Vector2 = rect.size / 2.0 * factor
	return absf(local.x) <= half.x and absf(local.y) <= half.y


## Starts its dialogue for the current step from outside, e.g. FestivalShow once the player stands
## in the crowd.
func talk() -> void:
	if _present and not _dialogue.visible:
		_on_interacted()


## The player is out of the talking area: the dialogue closes, but only if he walked away himself.
## While the dialogue holds him still he can't, so it was the figure (or a cut scene) that moved
## (e.g. Ssarok walking to the gate in his own conversation): the dialogue stays open then.
func _on_player_left() -> void:
	if keep_dialogue_open or (_dialogue.visible and _dialogue.freezes_player):
		return
	_dialogue.close()


func _on_interacted() -> void:
	if _dialogue.visible:
		_dialogue.advance()
		return
	# A figure with several things to talk about (e.g. Lotte) asks first: "Reden", the topics, "Tschüss".
	var menu: Dictionary = GameState.story.get_npc_menu(npc_id)
	# the dialogue of this step: once it closes the figure does not start it again by itself
	var step_dialogues: Dictionary = Story.get_data("npcs").get(npc_id, {}).get("dialogues", {})
	_telling_step = GameState.story.step if menu.is_empty() and step_dialogues.has(GameState.story.step) else ""
	_dialogue.play(menu if not menu.is_empty() else GameState.story.get_npc_dialogue(npc_id), npc_id, get_portrait())


func _on_dialogue_finished() -> void:
	if not _telling_step.is_empty():
		GameState.story.mark_step_told(npc_id, _telling_step)
		_telling_step = ""
	if not hidden_when_flag.is_empty() and GameState.story.has_flag(hidden_when_flag) and not _is_aside():
		_leave()


## true if the figure stands at (or walks to) its aside_position and stays there.
func _is_aside() -> bool:
	return aside_position != Vector2.ZERO and (_walk == Walk.ASIDE or position.is_equal_approx(aside_position))


## A lying figure gets up (before it walks away along its leave_path).
func _stand_up() -> void:
	lying = false
	var figure := get_node_or_null("Figure") as Sprite2D
	if figure:
		figure.rotation_degrees = 0.0
		figure.position = _figure_position


## Walks along leave_path, or out of the map through the nearest exit (_exit_way), and vanishes;
## a figure that walked up to the player goes back where it came from if there is no exit; vanishes
## on the spot if it can't walk (see _walk_off).
func _leave() -> void:
	if aside_position != Vector2.ZERO and visible and is_inside_tree():
		auto_talk = false
		_walk = Walk.ASIDE
	elif walk_to_player and not vanish_on_leave and not leave_path.is_empty():
		_leave_point = 0
		_walk = Walk.AWAY
	elif not vanish_on_leave and not leave_path.is_empty() and visible and is_inside_tree():
		if lying:
			_stand_up()  # e.g. Bruno gets up from the grass by the fountain
		_start_roam(Walk.OUT, _leave_way())
	elif walk_to_player and not vanish_on_leave and _home_at_door():
		_walk = Walk.BACK  # came out of its shop or house: back in there
	elif not vanish_on_leave and _walk_off(Walk.OUT):
		pass
	elif walk_to_player and not vanish_on_leave:
		_walk = Walk.BACK
	elif _just_faded() and is_inside_tree():
		# behind the black of the fade, not before it
		get_tree().create_timer(GameState.FADE_SECONDS, false).timeout.connect(queue_free)
	else:
		queue_free()


## true while an open conversation (its own or someone else's) still has a line of this figure.
func _is_still_talking() -> bool:
	for box in get_tree().get_nodes_in_group(DialogueBox.GROUP):
		if box.visible and box.speaks_later(npc_id):
			return true
	return false


func _just_faded() -> bool:
	return _fade_recent


func _end_fade_window() -> void:
	_fade_recent = false


## Starts walking out of the map through the nearest exit (_exit_way; `walk`: OUT = vanish there, ROAM_OUT =
## away until it is needed here again). false if it should vanish on the spot instead: nobody to
## see walking (narrator, lying, a picture), right after a fade, or the same person stays in the
## scene in another form (e.g. Subar wounded on the ground).
func _walk_off(walk: Walk) -> bool:
	if not visible or not is_inside_tree() or narrator or lying or figure_texture != null \
			or (appearance == null and resident.is_empty()) or _just_faded():
		return false
	for other in get_tree().get_nodes_in_group(GROUP):
		# the group also holds Companions and RaidFighters; a RaidFighter has no _should_be_here
		if other == self or other.npc_id != npc_id:
			continue
		if other.call("_should_be_here") if other.has_method("_should_be_here") else other.visible:
			return false
	var door: Node2D = _leave_door()
	if door:
		_start_roam(walk, PackedVector2Array([Vector2(door.global_position.x, global_position.y), door.global_position]))
		return true
	# a figure with a leave_path takes it (over bridges and ways), not the straight line to an exit
	if not leave_path.is_empty():
		_start_roam(walk, _leave_way())
		return true
	var way: PackedVector2Array = _exit_way()
	if way.is_empty() or global_position.distance_to(way[way.size() - 1]) < 1.0:
		return false
	var roads: VillageRoads = _find_roads()
	_start_roam(walk, roads.plan_through(global_position, way) if roads else way)
	return true


## The first visible door of leave_doors, null if there is none.
func _leave_door() -> Node2D:
	for path in leave_doors:
		var door := get_node_or_null(path) as Node2D
		if door and door.is_visible_in_tree():
			return door
	return null


## Points (global) to the nearest way out on foot: a map edge (Door at the camera limits, then a
## bit past the edge, out of the picture), else the nearest door (into a house), else the nearest
## spawn point. Hidden doors (not built yet) don't count. Empty if there is none.
func _exit_way() -> PackedVector2Array:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var edges: Array[Node2D] = []
	var doors: Array[Node2D] = []
	for exit in get_tree().get_nodes_in_group(Door.EXIT_GROUP):
		if exit is Node2D and exit.is_inside_tree() and (exit as Node2D).is_visible_in_tree():
			if camera and _edge_side(camera, exit.global_position) != Vector2.ZERO:
				edges.append(exit)
			else:
				doors.append(exit)
	var exit: Node2D = _nearest(edges)
	if exit:
		var side: Vector2 = _edge_side(camera, exit.global_position)
		return PackedVector2Array([exit.global_position, exit.global_position + side * EDGE_WALK_OUT])
	exit = _nearest(doors)
	if exit == null:
		var points: Array[Node2D] = []
		points.assign(get_tree().get_nodes_in_group("spawn_points").filter(func(p: Node) -> bool: return p is Node2D))
		exit = _nearest(points)
	return PackedVector2Array([exit.global_position]) if exit else PackedVector2Array()


## true if the figure's own place is right at a door that is not a map edge (Nina in front of her
## shop): it came out of there.
func _home_at_door() -> bool:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var home: Vector2 = (get_parent() as Node2D).to_global(_home)
	for exit in get_tree().get_nodes_in_group(Door.EXIT_GROUP):
		if exit is Node2D and home.distance_to(exit.global_position) <= DOOR_HOME_DISTANCE \
				and (camera == null or _edge_side(camera, exit.global_position) == Vector2.ZERO):
			return true
	return false


func _nearest(nodes: Array[Node2D]) -> Node2D:
	var best: Node2D = null
	for node in nodes:
		if best == null or global_position.distance_to(node.global_position) < global_position.distance_to(best.global_position):
			best = node
	return best


## The side of the map `point` lies on (e.g. Vector2.RIGHT), ZERO if it is not near a camera limit.
static func _edge_side(camera: Camera2D, point: Vector2) -> Vector2:
	if camera.limit_left <= -NO_LIMIT:  # a camera without limits: no map edges known
		return Vector2.ZERO
	if point.x - camera.limit_left <= EDGE_MARGIN:
		return Vector2.LEFT
	if camera.limit_right - point.x <= EDGE_MARGIN:
		return Vector2.RIGHT
	if point.y - camera.limit_top <= EDGE_MARGIN:
		return Vector2.UP
	if camera.limit_bottom - point.y <= EDGE_MARGIN:
		return Vector2.DOWN
	return Vector2.ZERO


## Points (global) out of the map along leave_path, around obstacles if the map has VillageRoads.
func _leave_way() -> PackedVector2Array:
	var parent := get_parent() as Node2D
	var way := PackedVector2Array()
	for point in leave_path:
		way.append(parent.to_global(point))
	var roads: VillageRoads = _find_roads()
	return roads.plan_through(global_position, way) if roads else way


func _update_marker() -> void:
	if _marker:
		_marker.visible = _present and GameState.story.npc_has_news(npc_id)
