class_name TextSize
extends RefCounted
## Size of the text in tips, dialogues, values and tasks, chosen by the player (settings, tab
## "Oberfläche", block "Textgröße" below the HUD sizes). Saved in user://settings.cfg (section "text_size",
## WindowLayout). Unlike UiScale (which scales a whole HUD part) only the letters get bigger.
## How: `attach(control, id)` gives the control its own small Theme with a bigger
## default_font_size. Every Label, Button and RichTextLabel below it without its own font size
## takes it, also the ones a window builds later (quest list, value rows). Widths given to
## `attach` (`grow`) grow with the text, so a line holds about as many words as before.
## A window that has to do more (e.g. a fixed page size) passes `on_change`, called after each
## change (and once in attach).

const SECTION: String = "text_size"
const GROUP: StringName = &"text_size_targets"
const BASE_FONT_SIZE: int = 11
## Slider in the settings, percent of the normal size.
const PERCENT_MIN: int = 100
const PERCENT_MAX: int = 200
const PERCENT_STEP: int = 25
## Widths grow with the text, but never past this (base resolution 640x360).
const MAX_WIDTH: float = 560.0
const MAX_HEIGHT: float = 280.0

## [id, name in the settings]
const ELEMENTS: Array[Array] = [
	["hints", "Tipps"],
	["dialogue", "Dialoge"],
	["stats", "Werte"],
	["quests", "Aufgaben"],
]


## Factor of the normal size (1.0 = 100 %).
static func get_factor(id: String) -> float:
	return get_percent(id) / 100.0


static func get_percent(id: String) -> float:
	return clampf(float(WindowLayout.get_setting(SECTION, id, 100.0)), PERCENT_MIN, PERCENT_MAX)


static func set_percent(id: String, percent: float) -> void:
	var value: float = clampf(snappedf(percent, PERCENT_STEP), PERCENT_MIN, PERCENT_MAX)
	WindowLayout.set_setting(SECTION, id, null if is_equal_approx(value, 100.0) else value)
	_notify()


static func reset_all() -> void:
	for element in ELEMENTS:
		WindowLayout.set_setting(SECTION, element[0], null)
	_notify()


## Font size for `base` (e.g. a label with its own size 9) at the size of `id`.
static func font_size(id: String, base: int = BASE_FONT_SIZE) -> int:
	return maxi(1, roundi(base * get_factor(id)))


## `value` (a width or height) grown with the text of `id`, at most `limit`.
static func grown(id: String, value: float, limit: float = MAX_WIDTH) -> float:
	return minf(value * get_factor(id), maxf(value, limit))


## Gives `control` (and everything below it) the text size `id`, now and after every change.
## `grow`: controls whose custom_minimum_size (as set in the scene) grows with the text.
static func attach(control: Control, id: String, grow: Array[Control] = [], on_change: Callable = Callable()) -> void:
	control.set_meta(&"text_size_id", id)
	for target in grow:
		target.set_meta(&"text_size_base_min", target.custom_minimum_size)
	control.set_meta(&"text_size_grow", grow)
	if on_change.is_valid():
		control.set_meta(&"text_size_on_change", on_change)
	control.add_to_group(GROUP)
	_apply(control)


## For a page of SlidingPages (fixed size, cuts off what sticks out): `pages` grows when `page`
## needs more room than the size set in the scene (bigger text), and shrinks back to it.
static func fit_pages(pages: Control, page: Control) -> void:
	if not pages.has_meta(&"text_size_base_min"):
		pages.set_meta(&"text_size_base_min", pages.custom_minimum_size)
	var fit := func() -> void:
		var base: Vector2 = pages.get_meta(&"text_size_base_min")
		pages.custom_minimum_size = base.max(page.get_combined_minimum_size())
	page.minimum_size_changed.connect(fit)
	fit.call()


static func _apply(control: Control) -> void:
	var id: String = String(control.get_meta(&"text_size_id", ""))
	var theme := Theme.new()
	theme.default_font_size = font_size(id)
	control.theme = theme
	for target: Control in control.get_meta(&"text_size_grow", []):
		if not is_instance_valid(target):
			continue
		var base: Vector2 = target.get_meta(&"text_size_base_min", target.custom_minimum_size)
		target.custom_minimum_size = Vector2(grown(id, base.x), grown(id, base.y, MAX_HEIGHT))
	var on_change: Callable = control.get_meta(&"text_size_on_change", Callable())
	if on_change.is_valid():
		on_change.call()


static func _notify() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group(GROUP):
		if node is Control:
			_apply(node)
