class_name UiScale
extends RefCounted
## Size of each part of the HUD, chosen by the player (settings, tab "Oberfläche"): the action bar,
## the gold, the clock, the side menu and every HUD window on its own. Saved in user://settings.cfg
## (section "ui_scale", WindowLayout). The HUD applies the sizes at the start and whenever one
## changes (group LISTENER_GROUP, method `apply_ui_scale`).
## Each part grows from the side it is anchored to (ANCHOR_*), so the action bar stays at the
## bottom, the side menu at the right edge and a window around its centre.

const SECTION: String = "ui_scale"
const LISTENER_GROUP: StringName = &"ui_scale_listeners"
## Slider in the settings: percent of the part's default size (100 % = default), in steps.
## Not down to 0 %: the part would vanish and could no longer be found or clicked.
const PERCENT_MIN: int = 10
const PERCENT_MAX: int = 200
const PERCENT_STEP: int = 5

enum Anchor { CENTER, BOTTOM, BOTTOM_LEFT, TOP, RIGHT }

## [id, name in the settings, default size]
const ELEMENTS: Array[Array] = [
	["hotbar", "Aktionsleiste", 1.5],
	["gold", "Goldanzeige", 1.5],
	["time", "Uhr", 1.0],
	["side_menu", "Seitenmenü", 1.0],
	["inventory", "Inventar", 1.0],
	["character", "Charakter", 1.0],
	["heroes", "Helden", 1.0],
	["battle", "Kampf", 1.0],
	["quests", "Aufträge", 1.0],
	["recipes", "Rezeptbuch", 1.0],
]


static func get_scale(id: String) -> float:
	return float(WindowLayout.get_setting(SECTION, id, _get_default(id)))


static func set_scale(id: String, value: float) -> void:
	WindowLayout.set_setting(SECTION, id, value)
	_notify()


## Size in percent of the default size (what the settings slider shows).
static func get_percent(id: String) -> float:
	return get_scale(id) / _get_default(id) * 100.0


static func set_percent(id: String, percent: float) -> void:
	set_scale(id, _get_default(id) * clampf(percent, PERCENT_MIN, PERCENT_MAX) / 100.0)


## Every part back to its default size.
static func reset_all() -> void:
	for element in ELEMENTS:
		WindowLayout.set_setting(SECTION, element[0], null)
	_notify()


## Scales `control` from the side given by `anchor`. Keeps doing so when its size changes
## (e.g. the gold gets another digit, a window gets new content).
static func apply(control: Control, value: float, anchor: Anchor) -> void:
	control.scale = Vector2(value, value)
	control.set_meta(&"ui_scale_anchor", anchor)
	_update_pivot(control)
	if not control.has_meta(&"ui_scale_follows_size"):
		control.set_meta(&"ui_scale_follows_size", true)
		control.resized.connect(func() -> void: _update_pivot(control))


## Where the scaled control really is on screen (position and size after scaling).
static func get_visual_rect(control: Control) -> Rect2:
	var offset: Vector2 = control.pivot_offset * (Vector2.ONE - control.scale)
	return Rect2(control.position + offset, control.size * control.scale)


## Moves the control so that its scaled picture starts at `visual_position`.
static func set_visual_position(control: Control, visual_position: Vector2) -> void:
	control.position = visual_position - control.pivot_offset * (Vector2.ONE - control.scale)


static func _update_pivot(control: Control) -> void:
	var size: Vector2 = control.size
	match control.get_meta(&"ui_scale_anchor", Anchor.CENTER):
		Anchor.BOTTOM:
			control.pivot_offset = Vector2(size.x / 2.0, size.y)
		Anchor.BOTTOM_LEFT:
			control.pivot_offset = Vector2(0, size.y)
		Anchor.TOP:
			control.pivot_offset = Vector2(size.x / 2.0, 0)
		Anchor.RIGHT:
			control.pivot_offset = Vector2(size.x, size.y / 2.0)
		_:
			control.pivot_offset = size / 2.0


static func _get_default(id: String) -> float:
	for element in ELEMENTS:
		if element[0] == id:
			return element[2]
	return 1.0


static func _notify() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.call_group(LISTENER_GROUP, "apply_ui_scale")
