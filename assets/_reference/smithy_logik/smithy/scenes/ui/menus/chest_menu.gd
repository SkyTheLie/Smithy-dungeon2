class_name ChestMenu
extends StationMenu
## Window of the reward chest (GameState.reward_chest, 6x5, grows by rows; the window always
## shows 5 rows and scrolls when there are more): daily rewards and dungeon loot
## wait here, and gold (GameState.reward_chest_gold, e.g. Nina's money; button "Gold nehmen"). Clicking a slot takes that stack into the inventory, "Alles nehmen" takes as
## much as fits. Items can't be put in (it is a reward chest, not a storage chest).
## Opening it lets what is new since the last look pop up one after another, the rarest last;
## from Fein (R3) on the last one rings (item_reveal).
## Once Lotte shops for the player (Assistant.is_unlocked) "An Lotte verkaufen" switches to picking:
## everything she can sell is marked at once, a click on a slot unmarks (or marks) it, and the
## button hands the marked stacks to her (Assistant.give_for_sale).

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const COLUMNS: int = 6
## Seconds between two new stacks popping up, and how long one pops.
const POP_STEP: float = 0.08
const POP_SECONDS: float = 0.25
## The rarest new stack rings from this rarity on.
const RING_RARITY: Rarity.Tier = Rarity.Tier.FINE

var _slot_uis: Array[ItemSlotUI] = []
## Tint of a slot marked for Lotte.
const MARK_COLOR: Color = Color(1.0, 0.8, 0.35)

## true while the player picks stacks for Lotte; _marked = their slot indexes.
var _picking: bool = false
var _marked: Array[int] = []
## What each slot held when the chest was last open ("" = empty), to find the new stacks.
var _seen: Array[String] = []

@onready var _chest: Inventory = GameState.reward_chest
@onready var _grid: GridContainer = %Grid
@onready var _status_label: Label = %StatusLabel
@onready var _gold_button: Button = %GoldButton
@onready var _sell_button: Button = %SellButton
@onready var _sale_label: Label = %SaleLabel


func _ready() -> void:
	super()
	_grid.columns = COLUMNS
	_add_missing_slots()
	%TakeAllButton.pressed.connect(_take_all)
	_gold_button.pressed.connect(GameState.take_reward_chest_gold)
	_sell_button.pressed.connect(_on_sell_pressed)
	GameState.assistant.changed.connect(_refresh)
	_chest.changed.connect(_on_chest_changed)
	GameState.reward_chest_filled.connect(_refresh)
	visibility_changed.connect(_refresh)
	visibility_changed.connect(_on_visibility_changed)
	_seen.fill("")
	_refresh()


## The chest can grow (GameState._grow_reward_chest), and a loaded save can have fewer slots.
func _add_missing_slots() -> void:
	while _slot_uis.size() > _chest.slots.size():
		_slot_uis.pop_back().queue_free()
		_marked.erase(_slot_uis.size())
	for i in range(_slot_uis.size(), _chest.slots.size()):
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_grid.add_child(slot_ui)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(i))
		slot_ui.drag_out = true
		_slot_uis.append(slot_ui)
	_seen.resize(_chest.slots.size())


func _refresh() -> void:
	_add_missing_slots()
	var empty: bool = true
	for i in _slot_uis.size():
		_slot_uis[i].display(_chest.slots[i])
		empty = empty and _chest.slots[i].is_empty()
	_gold_button.visible = GameState.reward_chest_gold > 0
	_gold_button.text = Language.translate("%d Gold nehmen") % GameState.reward_chest_gold
	empty = empty and GameState.reward_chest_gold <= 0
	_status_label.text = Language.translate("Die Loot-Kiste ist leer.") if empty else Language.translate("Klicken zum Nehmen.")
	_refresh_sale()


## Button "An Lotte verkaufen", the marks and what she has (pending: next morning, selling: gold tomorrow).
func _refresh_sale() -> void:
	var assistant: Assistant = GameState.assistant
	var unlocked: bool = Assistant.is_unlocked(GameState.story)
	_sell_button.visible = unlocked
	if not unlocked:
		_picking = false
		_marked.clear()
	for i in _slot_uis.size():
		_slot_uis[i].modulate = MARK_COLOR if i in _marked else Color.WHITE
		_slot_uis[i].extra_tooltip = ""
		if _picking and not _chest.slots[i].is_empty():
			var price: int = Assistant.get_sale_price(_chest.slots[i])
			_slot_uis[i].extra_tooltip = Language.translate("Lotte bringt dafür %d Gold.") % price if price > 0 					else Language.translate("Das kauft dir niemand ab.")
	if _picking:
		var gold: int = 0
		for index in _marked:
			gold += Assistant.get_sale_price(_chest.slots[index])
		_sell_button.text = Language.translate("Lotte mitgeben (%d Gold)") % gold if not _marked.is_empty() 				else Language.translate("Abbrechen")
		_status_label.text = Language.translate("Sachen für Lotte anklicken.")
	else:
		_sell_button.text = Language.translate("An Lotte verkaufen")
	var lines: Array[String] = []
	if not assistant.sale_pending.is_empty():
		lines.append(Language.translate("Lotte holt morgen früh %d Sachen ab (etwa %d Gold).") % [assistant.sale_pending.size(), assistant.get_pending_gold()])
	if not assistant.sale_selling.is_empty():
		lines.append(Language.translate("Lotte verkauft gerade für dich: morgen %d Gold.") % assistant.sale_gold)
	_sale_label.visible = unlocked and not lines.is_empty()
	_sale_label.text = "\n".join(lines)


func _on_sell_pressed() -> void:
	if not _picking:
		# Everything a merchant would buy is picked at once; a click on a slot takes it out again.
		_picking = true
		_marked.clear()
		for i in _chest.slots.size():
			if not _chest.slots[i].is_empty() and Assistant.get_sale_price(_chest.slots[i]) > 0:
				_marked.append(i)
	else:
		if not _marked.is_empty():
			# A copy: every stack taken out changes the chest, which clears _marked (_on_chest_changed).
			var count: int = GameState.assistant.give_for_sale(_marked.duplicate())
			if count > 0:
				AudioManager.play_sound("chest_open")
		_picking = false
		_marked.clear()
	_refresh()


## New loot or a taken stack moves the slots: the marks would point at other stacks.
func _on_chest_changed() -> void:
	_marked.clear()
	_refresh()


func _on_visibility_changed() -> void:
	if not visible:
		_picking = false
		_marked.clear()
	if visible:
		AudioManager.play_sound("chest_open")
		pop_new_stacks()
	else:
		_remember()


## Lets the stacks that are new since the last look pop up, sorted by rarity (rarest last).
## Returns the slot indexes in the order they pop.
func pop_new_stacks() -> Array[int]:
	var fresh: Array[int] = []
	for i in _chest.slots.size():
		if not _chest.slots[i].is_empty() and _describe(_chest.slots[i]) != _seen[i]:
			fresh.append(i)
	fresh.sort_custom(func(a: int, b: int) -> bool: return _chest.slots[a].rarity < _chest.slots[b].rarity)
	for n in fresh.size():
		var slot_ui: ItemSlotUI = _slot_uis[fresh[n]]
		# The grid resets the scale when it sorts (opening the window), so the pop starts from(0)
		# and the slot stays invisible until its turn.
		slot_ui.pivot_offset = slot_ui.size / 2.0
		slot_ui.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(POP_STEP * n)
		tween.tween_callback(func() -> void: slot_ui.modulate.a = 1.0)
		tween.tween_property(slot_ui, "scale", Vector2.ONE, POP_SECONDS).from(Vector2.ZERO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not fresh.is_empty() and _chest.slots[fresh[-1]].rarity >= RING_RARITY:
		get_tree().create_timer(POP_STEP * (fresh.size() - 1), false).timeout.connect(AudioManager.play_sound.bind("item_reveal", 1.0))
	_remember()
	return fresh


func _remember() -> void:
	for i in _chest.slots.size():
		_seen[i] = _describe(_chest.slots[i])


static func _describe(slot: InventorySlot) -> String:
	return "" if slot.is_empty() else "%s:%d:%d" % [slot.item.id, slot.amount, slot.rarity]


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if _picking:
			_toggle_mark(index)
			return
		if not _take(index):
			_status_label.text = Language.translate("Kein Platz im Inventar.")


## Picking for Lotte: marks or unmarks the stack (only ones a merchant would buy).
func _toggle_mark(index: int) -> void:
	if index in _marked:
		_marked.erase(index)
	elif Assistant.get_sale_price(_chest.slots[index]) > 0:
		_marked.append(index)
	_refresh()


func _take_all() -> void:
	GameState.take_reward_chest_gold()
	var everything_taken: bool = true
	for i in _chest.slots.size():
		if not _chest.slots[i].is_empty() and not _take(i):
			everything_taken = false
	if not everything_taken:
		_status_label.text = Language.translate("Nicht alles passt ins Inventar.")


## Moves as much of the stack as fits into the inventory. Returns true if all of it moved.
func _take(index: int) -> bool:
	var stack: InventorySlot = _chest.slots[index]
	if stack.is_empty():
		return true
	var amount: int = stack.amount
	var leftover: int = GameState.inventory.add_stack(stack.copy_with_amount(amount))
	_chest.remove_from_slot(index, amount - leftover)
	return leftover == 0
