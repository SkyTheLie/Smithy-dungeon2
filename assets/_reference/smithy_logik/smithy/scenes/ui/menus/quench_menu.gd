extends StationMenu
## Water trough window: one slot for a glowing item (drag it in or right-click it in the
## inventory). It cools automatically (progress bar); clicking the cooled item takes it back.
## Once it is cool, the next glowing item can go straight in (right click / drag): the cooled
## one moves into the inventory by itself (Quencher.swap_in).
## Closing the window puts the cooled stack into the inventory; is it still cooling, it goes there
## by itself as soon as it is cool (GameState.quencher_returns_when_cool).
## While it cools, steam rises over the slot and hiss words ("Tshhh", "Schssss" ...) pop up around the slot and float away.

const TEXT_EMPTY: String = "Zieh ein glühendes Teil hinein."
const HISS_WORDS: Array[String] = ["Tshhh", "shhhh", "Schssss", "TZShhh", "Tschhhh", "Pssshh", "zzsch"]
## Seconds between two hiss words.
const HISS_INTERVAL: float = 0.3
## Seconds a hiss word floats until it is gone.
const HISS_TIME: float = 0.9
const HISS_COLOR: Color = Color(0.75, 0.88, 1.0)
const TEXT_DONE: String = "Abgekühlt!"
const STEAM_SHEET: Texture2D = preload("res://assets/sprites/effects/quench_steam.png")
const STEAM_ANIMATION: Script = preload("res://scenes/world/objects/sheet_animation.gd")
const TEXT_FULL: String = "Kein Platz im Inventar für das abgekühlte Teil."

@onready var _quencher: Quencher = GameState.quencher
@onready var _slot_ui: ItemSlotUI = %TroughSlot
@onready var _progress: ProgressBar = %CoolProgress
@onready var _status_label: Label = %StatusLabel

var _hiss_timer: float = 0.0
var _steam: Sprite2D


func _ready() -> void:
	super()
	_slot_ui.gui_input.connect(_on_slot_gui_input)
	_slot_ui.drag_out = true
	_slot_ui.set_drag_forwarding(Callable(), _can_drop_into, _drop_into)
	# Guide: the empty trough slot (put the glowing part in), then the cooled part (take it out).
	GuideFrame.attach(_slot_ui, func() -> bool:
		return Guide.is_target("trough:slot") and not _quencher.is_cooling())
	_steam = Sprite2D.new()
	_steam.texture = STEAM_SHEET
	_steam.hframes = 4
	_steam.vframes = 4
	_steam.set_script(STEAM_ANIMATION)
	_steam.set("frames_per_second", 12.0)
	_steam.z_index = 1
	add_child(_steam)
	_quencher.changed.connect(_refresh)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _on_visibility_changed() -> void:
	if visible:
		GameState.quencher_returns_when_cool = false
	else:
		_give_back()


func _exit_tree() -> void:
	# Scene change while the window is open: the stack still goes into the inventory.
	if visible:
		_give_back()


## The cooled stack goes into the inventory, a cooling one as soon as it is cool.
func _give_back() -> void:
	if _quencher.is_cooling():
		GameState.quencher_returns_when_cool = true
	else:
		_quencher.take_into(GameState.inventory)


func _process(delta: float) -> void:
	if not visible:
		return
	_progress.value = _quencher.get_progress()
	_steam.visible = _quencher.is_cooling()
	_steam.global_position = _slot_ui.global_position + Vector2(_slot_ui.size.x / 2.0, -14.0)
	if _quencher.is_cooling():
		_hiss_timer -= delta
		if _hiss_timer <= 0.0:
			_hiss_timer = HISS_INTERVAL
			_spawn_hiss()


## One hiss word next to the slot that rises and fades out.
func _spawn_hiss() -> void:
	var word: String = HISS_WORDS.pick_random()
	_status_label.text = word + " ..."
	var label := Label.new()
	label.text = word
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", HISS_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var center: Vector2 = _slot_ui.global_position + _slot_ui.size / 2.0
	label.position = center + Vector2(randf_range(-40.0, 24.0), randf_range(-14.0, 4.0))
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 14.0, HISS_TIME)
	tween.tween_property(label, "modulate:a", 0.0, HISS_TIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)


func _refresh() -> void:
	_slot_ui.display(_quencher.slot)
	if _quencher.slot.is_empty():
		_status_label.text = Language.translate(TEXT_EMPTY)
	elif _quencher.is_cooling():
		_hiss_timer = 0.0
	else:
		_status_label.text = Language.translate(TEXT_DONE)


func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	if not _can_drop_into(Vector2.ZERO, data):
		return false
	_drop_into(Vector2.ZERO, data)
	return true


func _can_drop_into(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return _quencher.can_insert(source) or _quencher.can_swap(source)


func _drop_into(_at_position: Vector2, data: Variant) -> void:
	var index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[index]
	var amount: int = get_move_amount(data, source)
	if _quencher.can_swap(source):
		if not _quencher.swap_in(GameState.inventory, index, amount):
			_status_label.text = Language.translate(TEXT_FULL)
		else:
			AudioManager.play_sound("quench_hiss")
		return
	var taken: int = _quencher.insert(source, amount)
	GameState.inventory.remove_from_slot(index, taken)
	if taken > 0:
		AudioManager.play_sound("quench_hiss")


func _on_slot_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_quencher.take_into(GameState.inventory)
