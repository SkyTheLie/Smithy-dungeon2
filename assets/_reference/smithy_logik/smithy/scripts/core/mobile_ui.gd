class_name MobileUi
extends RefCounted
## Rules for the phone (Android) build only. On PC `active()` is false and nothing changes.
## - Tapping an object in the world uses exactly that object (like E, but aimed): stations, story
##   figures, doors, teleporters, cash box (Station.INTERACT_GROUP) and things that are held
##   (ore rocks, trees, boulders: TAP_HOLD_GROUP, the finger works like holding E).
## - The forging minigame is bigger, draws its strike spots bigger still and counts taps a bit
##   around them.
## - Walking (setting "Laufen" in Einstellungen » Steuerung, saved in settings.cfg):
##   "stick" (default) = the left half of the screen is a stick that appears under the thumb; a
##             short tap is E.
##   "tap"   = tap the ground: the player walks there (TouchWalk finds the way); hold the finger:
##             he walks towards it; tap an object out of reach: he walks there and uses it.
## - Furnishing the house (HouseEditor, key B on PC): a "B" button switches the mode on and off in
##   every room that has one; in the mode "R" turns and the box button stores (right click on PC).
##   A tap lifts a thing; then it follows the finger while it is down and is put down where the
##   finger lets go. pointer() is where that finger is (not a tap on one of the round buttons).
## The taps themselves come from TouchControls (scripts/core/touch_controls.gd).

## Things that take a held E (mining): they implement wants_touch() -> bool (player in reach).
const TAP_HOLD_GROUP: StringName = &"tap_hold"
## Build modes (HouseEditor): while one is_active(), taps in the world use nothing.
const BUILD_GROUP: StringName = &"build_mode"
## A tap counts on an object up to this far (world pixels) outside its picture.
const TAP_MARGIN: float = 6.0
## Objects without a picture: tap radius around their origin (world pixels).
const TAP_RADIUS_NO_PICTURE: float = 18.0
## Forging minigame: strike spots this much bigger on the phone, and a tap still counts this much
## outside the drawn spot (fingers are less exact than a mouse).
const FORGE_SPOT_SCALE: float = 1.6
## Forging minigame: the whole window this much bigger on the phone.
const FORGE_WINDOW_SCALE: float = 1.5
const FORGE_HIT_SCALE: float = 1.25

## Settings: section/key in settings.cfg (WindowLayout) and the modes [id, name].
const SETTINGS_SECTION: String = "touch"
const SETTINGS_MOVE_MODE: String = "move_mode"
const MOVE_TAP: String = "tap"
const MOVE_STICK: String = "stick"
const MOVE_MODES: Array[Array] = [[MOVE_STICK, "Joystick"], [MOVE_TAP, "Tippen"]]

## DEV-ONLY: tests switch the phone rules on on PC.
static var forced: bool = false
## Object the current tap aims at (Station.is_nearest_interactable gives E only to it). Input of
## one finger, not game state. # not saved on purpose
static var touch_target: Node = null
## Where the finger last touched the screen beside the round touch buttons (screen pixels), INF =
## nowhere yet. Set by TouchControls. Input, not game state. # not saved on purpose
static var pointer_screen: Vector2 = Vector2.INF


static func active() -> bool:
	return forced or OS.has_feature("mobile")


## "stick" (default) or "tap".
static func get_move_mode() -> String:
	var mode: String = str(WindowLayout.get_setting(SETTINGS_SECTION, SETTINGS_MOVE_MODE, MOVE_STICK))
	return mode if mode == MOVE_TAP else MOVE_STICK


static func set_move_mode(mode: String) -> void:
	WindowLayout.set_setting(SETTINGS_SECTION, SETTINGS_MOVE_MODE, MOVE_TAP if mode == MOVE_TAP else MOVE_STICK)


## The object a tap at `world_pos` aims at: of everything that would take E now (in reach) and is
## under the finger, the one whose picture centre is nearest. null = none.
## `in_reach` false: any visible object under the finger, also far away (the player walks there).
static func find_tap_target(tree: SceneTree, world_pos: Vector2, in_reach: bool = true) -> Node:
	var best: Node = null
	var best_distance: float = INF
	var candidates: Array[Node] = tree.get_nodes_in_group(Station.INTERACT_GROUP)
	candidates.append_array(tree.get_nodes_in_group(TAP_HOLD_GROUP))
	for node: Node in candidates:
		var item := node as Node2D
		if item == null or not item.is_visible_in_tree():
			continue
		if node is Station and ((node as Station).blocked or not (node as Station).is_usable()):
			continue
		var wants: bool = node.wants_touch() if node.is_in_group(TAP_HOLD_GROUP) else node.wants_interact()
		if in_reach and not wants:
			continue
		var area: Rect2 = picture_rect(item)
		if not area.grow(TAP_MARGIN).has_point(world_pos):
			continue
		var distance: float = area.get_center().distance_to(world_pos)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best


## true while a build mode (furnishing the house) is on.
static func build_mode_active(tree: SceneTree) -> bool:
	for node: Node in tree.get_nodes_in_group(BUILD_GROUP):
		if node.is_active():
			return true
	return false


## true if this place has a build mode (the "B" button is shown): a room of the player's house.
static func build_mode_offered(tree: SceneTree) -> bool:
	for node: Node in tree.get_nodes_in_group(BUILD_GROUP):
		if node is CanvasItem and (node as CanvasItem).is_visible_in_tree():
			return true
	return false


## Where the player points, in world coordinates of `item`'s canvas: on PC the mouse; on the phone
## the last finger beside the round touch buttons (the mouse Godot makes out of touches jumps to
## every button that is pressed, a carried thing must not jump with it).
static func pointer(item: CanvasItem) -> Vector2:
	if not active() or pointer_screen == Vector2.INF:
		return item.get_global_mouse_position()
	return item.get_canvas_transform().affine_inverse() * pointer_screen


## true if `node` would take E (or the held E) now.
static func wants_now(node: Node) -> bool:
	if not is_instance_valid(node):
		return false
	return node.wants_touch() if node.is_in_group(TAP_HOLD_GROUP) else node.wants_interact()


## true if some figure has its conversation open (its E turns the page wherever one taps).
static func conversation_open(tree: SceneTree) -> bool:
	for node: Node in tree.get_nodes_in_group(Station.INTERACT_GROUP):
		if node.wants_interact() and node.interact_priority() > 0:
			return true
	return false


## The area of `item`'s picture in world coordinates: all visible Sprite2D / AnimatedSprite2D
## children together, else a small square around its origin.
static func picture_rect(item: Node2D) -> Rect2:
	var area := Rect2()
	var found: bool = false
	for child: Node in item.get_children():
		var rect := Rect2()
		if child is Sprite2D and (child as Sprite2D).visible and (child as Sprite2D).texture != null:
			var sprite: Sprite2D = child
			rect = sprite.get_global_transform() * sprite.get_rect()
		elif child is AnimatedSprite2D and (child as AnimatedSprite2D).visible:
			var animated: AnimatedSprite2D = child
			if animated.sprite_frames == null or not animated.sprite_frames.has_animation(animated.animation):
				continue
			var frame: Texture2D = animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
			if frame == null:
				continue
			var frame_size: Vector2 = frame.get_size()
			var top_left: Vector2 = animated.offset - (frame_size / 2.0 if animated.centered else Vector2.ZERO)
			rect = animated.get_global_transform() * Rect2(top_left, frame_size)
		else:
			continue
		area = rect if not found else area.merge(rect)
		found = true
	if not found:
		var half := Vector2(TAP_RADIUS_NO_PICTURE, TAP_RADIUS_NO_PICTURE)
		area = Rect2(item.global_position - half, half * 2.0)
	return area
