extends StationMenu
## Smelter window with two tabs that share the same slots on screen:
##   "Schmelzen": one place per smelter in use (GameState.get_smelters(), 1 to 4 side by side, more
##                with the smelter upgrades): ore slot, fuel slot below it, arrow, output slot and
##                its own "Einschmelzen" button, each place smelts on its own
##   "Legieren":  the first place only: two input slots side by side with a "+" (e.g. copper + iron
##                ingot), fuel slot, arrow, output slot (GameState.alloy_smelter, recipes =
##                items.json "alloy")
## Empty slots show a faint picture of what goes in (flame = fuel, ore, ingot) and a tooltip.
## All run on their own. Items are dragged in from the inventory (or right-clicked there:
## fuel -> a fuel slot, the rest -> a place with the same ore or the first empty one); clicking a
## slot (left or right) moves its items back to the inventory.

enum Tab { SMELT, ALLOY }

@onready var _lanes_box: HBoxContainer = %Lanes
@onready var _first_lane: VBoxContainer = %Lane
@onready var _tab_bar: TabBar = %TabBar

const HINT_FIRE: Texture2D = preload("res://assets/sprites/ui/slot_hints/fire.png")
const HINT_ORE: Texture2D = preload("res://assets/sprites/ui/slot_hints/ore.png")
const HINT_INGOT: Texture2D = preload("res://assets/sprites/ui/slot_hints/ingot.png")

## One entry per place on screen: {"box", "ore", "second", "plus", "fuel", "output", "time",
## "start"} (nodes); the first is the place in the scene, the others are copies of it.
var _lanes: Array[Dictionary] = []


func _ready() -> void:
	super()
	_lanes.append(_lane_nodes(_first_lane))
	for i in GameState.MAX_EXTRA_SMELTERS:
		var copy: VBoxContainer = _first_lane.duplicate()
		_clear_unique_names(copy)
		_lanes_box.add_child(copy)
		_lanes.append(_lane_nodes(copy))
	for index in _lanes.size():
		var lane: Dictionary = _lanes[index]
		_setup_slot(lane["ore"], index, "ore", true)
		_setup_slot(lane["second"], index, "second", true)
		_setup_slot(lane["fuel"], index, "fuel", true)
		_setup_slot(lane["output"], index, "output", false)
		(lane["start"] as Button).pressed.connect(func() -> void: _get_smelter(index).start())
		_set_hint(lane["second"], HINT_INGOT, Language.translate("Zweiter Barren"))
		_set_hint(lane["output"], HINT_INGOT, Language.translate("Ergebnis"))
	_tab_bar.tab_changed.connect(_on_tab_changed)
	for smelter in [GameState.smelter, GameState.alloy_smelter] + GameState.extra_smelters:
		smelter.changed.connect(_refresh_slots)
	GameState.house.changed.connect(_refresh_slots)
	visibility_changed.connect(_refresh_slots)
	_on_tab_changed(Tab.SMELT)
	# Guide (first smelting): the empty ore and fuel slot, the full output slot, then the button.
	var smelting_tab: Callable = func() -> bool: return _tab_bar.current_tab == Tab.SMELT
	var first: Smelter = GameState.smelter
	GuideFrame.attach(_lanes[0]["ore"], func() -> bool:
		return smelting_tab.call() and Guide.is_target("smelter:ore") and first.ore_slot.is_empty())
	GuideFrame.attach(_lanes[0]["fuel"], func() -> bool:
		return smelting_tab.call() and Guide.is_target("smelter:fuel") and first.fuel_slot.is_empty() and not first.has_glow())
	GuideFrame.attach(_lanes[0]["output"], func() -> bool:
		return smelting_tab.call() and Guide.is_target("smelter:output") and not first.output_slot.is_empty())
	GuideFrame.attach(_lanes[0]["start"], func() -> bool:
		return smelting_tab.call() and Guide.is_target("smelter:ore") and first.can_start())


func _lane_nodes(box: VBoxContainer) -> Dictionary:
	return {
		"box": box,
		"ore": box.get_node("Row/Inputs/InputRow/OreSlot"),
		"second": box.get_node("Row/Inputs/InputRow/SecondSlot"),
		"plus": box.get_node("Row/Inputs/InputRow/Plus"),
		"fuel": box.get_node("Row/Inputs/FuelSlot"),
		"output": box.get_node("Row/OutputSlot"),
		"time": box.get_node("Row/Middle/TimeLabel"),
		"start": box.get_node("StartButton"),
	}


## A copied place must not take the %names of the first one.
func _clear_unique_names(node: Node) -> void:
	node.unique_name_in_owner = false
	for child in node.get_children():
		_clear_unique_names(child)


func _process(_delta: float) -> void:
	if not visible:
		return
	for index in _lanes.size():
		var lane: Dictionary = _lanes[index]
		if not (lane["box"] as Control).visible:
			continue
		var smelter: Smelter = _get_smelter(index)
		(lane["start"] as Button).disabled = not smelter.can_start()
		var label: Label = lane["time"]
		if smelter.is_smelting():
			var seconds: int = ceili(smelter.get_batch_time_left())
			label.text = "%d:%02d" % [floori(seconds / 60.0), seconds % 60]
		else:
			label.text = ""


func _is_alloy() -> bool:
	return _tab_bar.current_tab == Tab.ALLOY


## The smelter behind place `index` in the open tab.
func _get_smelter(index: int) -> Smelter:
	if _is_alloy():
		return GameState.alloy_smelter
	return GameState.smelter if index == 0 else GameState.extra_smelters[index - 1]


## Places shown in the open tab.
func _lane_count() -> int:
	return 1 if _is_alloy() else GameState.get_smelters().size()


func _on_tab_changed(_tab: int) -> void:
	var alloy: bool = _is_alloy()
	for lane in _lanes:
		(lane["second"] as Control).visible = alloy
		(lane["plus"] as Control).visible = alloy
		_set_hint(lane["ore"], HINT_INGOT if alloy else HINT_ORE,
				Language.translate("Erster Barren") if alloy else Language.translate("Erz oder Sand"))
		(lane["start"] as Button).text = Language.translate("Legieren") if alloy else Language.translate("Einschmelzen")
	_refresh_slots()


## The slot behind a slot UI of place `index` in the open tab ("ore", "second", "fuel", "output").
func _get_slot(index: int, role: String) -> InventorySlot:
	var smelter: Smelter = _get_smelter(index)
	match role:
		"ore":
			return smelter.ore_slot
		"second":
			return GameState.alloy_smelter.second_slot
		"fuel":
			return smelter.fuel_slot
	return smelter.output_slot


func _setup_slot(slot_ui: ItemSlotUI, index: int, role: String, accepts_drops: bool) -> void:
	slot_ui.gui_input.connect(_on_slot_gui_input.bind(index, role))
	slot_ui.drag_out = true
	if accepts_drops:
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(index, role), _drop_into.bind(index, role))


func _set_hint(slot_ui: ItemSlotUI, picture: Texture2D, tooltip: String) -> void:
	slot_ui.placeholder = picture
	slot_ui.placeholder_tooltip = tooltip


func _refresh_slots() -> void:
	if _lanes.is_empty():
		return
	var count: int = _lane_count()
	for index in _lanes.size():
		var lane: Dictionary = _lanes[index]
		(lane["box"] as Control).visible = index < count
		if index >= count:
			continue
		var smelter: Smelter = _get_smelter(index)
		(lane["ore"] as ItemSlotUI).display(_get_slot(index, "ore"))
		(lane["second"] as ItemSlotUI).display(_get_slot(index, "second"))
		# Glow left in the oven (coal smelts 2 ores): shown in the fuel slot's tooltip.
		var glow: int = floori(smelter.heat_left + Smelter.HEAT_EPSILON)
		var glow_text: String = Language.translate("Glut im Ofen: reicht noch für %d ohne neuen Brennstoff") % glow if glow > 0 else ""
		var fuel_ui: ItemSlotUI = lane["fuel"]
		fuel_ui.extra_tooltip = glow_text
		fuel_ui.placeholder = HINT_FIRE
		fuel_ui.placeholder_tooltip = glow_text if glow > 0 else Language.translate("Brennstoff: Holz (1 Erz) oder Kohle (2 Erze)")
		fuel_ui.display(_get_slot(index, "fuel"))
		(lane["output"] as ItemSlotUI).display(_get_slot(index, "output"))
	# fewer places: the window shrinks back around them
	var panel := _lanes_box.get_parent().get_parent() as Control
	panel.reset_size.call_deferred()


func _on_slot_gui_input(event: InputEvent, index: int, role: String) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_get_smelter(index).take_into(_get_slot(index, role), GameState.inventory)


func _can_drop_into(_at_position: Vector2, data: Variant, index: int, role: String) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return _get_smelter(index).can_insert(_get_slot(index, role), source.item, source.rarity)


func _drop_into(_at_position: Vector2, data: Variant, index: int, role: String) -> void:
	var inventory_index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	var inserted: int = _get_smelter(index).insert(_get_slot(index, role), source.item, get_move_amount(data, source), source.rarity)
	GameState.inventory.remove_from_slot(inventory_index, inserted)


## Right click in the inventory: ore to a place with the same ore and rarity (topping up), else to
## the first empty place; fuel to the first place that has ore but no heat, else one with the
## same fuel, else the first empty fuel slot.
func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	var targets: Array[Array] = []  # [index, role, priority]
	for index in _lane_count():
		var smelter: Smelter = _get_smelter(index)
		var roles: Array[String] = ["fuel", "ore"]
		if _is_alloy():
			roles.append("second")
		for role in roles:
			var slot: InventorySlot = _get_slot(index, role)
			var priority: int = 2
			if role == "fuel" and not smelter.ore_slot.is_empty() and not smelter.has_heat():
				priority = 0
			elif slot.item == source.item and slot.rarity == source.rarity:
				priority = 1
			targets.append([index, role, priority])
	# stable: by priority, then place and role order
	var ordered: Array[Array] = []
	for priority in 3:
		ordered.append_array(targets.filter(func(target: Array) -> bool: return target[2] == priority))
	for target in ordered:
		if _can_drop_into(Vector2.ZERO, data, target[0], target[1]):
			_drop_into(Vector2.ZERO, data, target[0], target[1])
			return true
	return false
