class_name ItemReveal
extends CanvasLayer
## Shows a finished piece of equipment big in the middle of the screen (GameState.item_revealed,
## sent by the workbench, bow table and enchanting table): the screen darkens, rays in the colour of
## its rarity turn behind it (more and brighter the rarer), the icon pops up, the name appears letter
## by letter, below it rarity and quality. If joining it raised the rarity, "Seltenheit gestiegen!"
## pulses on top with its own fanfare. A click or any key closes it (after a short moment, so the
## click that finished the minigame doesn't close it at once). Several pieces wait in a queue.
## Built in code, lives in the HUD above every station window (LAYER, or above the topmost window).
## While it is shown every window is invisible (WindowTitleBar.set_windows_hidden) and comes back
## after the last piece.

const LAYER: int = 20
const ICON_SIZE: Vector2 = Vector2(96, 96)
const DIM: Color = Color(0.04, 0.03, 0.05, 0.7)
## Rays behind the icon: count for the lowest rarity, + per tier, their length and turn speed.
const RAYS_BASE: int = 6
const RAYS_PER_TIER: int = 2
const RAY_LENGTH: float = 150.0
const RAY_SPEED: float = 0.35
const COLOR_RISE: Color = Color(1.0, 0.85, 0.3)
const COLOR_HINT: Color = Color(0.7, 0.7, 0.7)
## Seconds before input closes it, and per letter of the name.
const INPUT_DELAY: float = 0.45
const LETTER_SECONDS: float = 0.04
const TEXT_HINT: String = "Klicken zum Weitermachen"
const TEXT_RISE: String = "Seltenheit gestiegen!"

## Waiting pieces: {"slot": InventorySlot, "rarity_up": bool}.
var _queue: Array[Dictionary] = []
var _showing: bool = false
var _shown_for: float = 0.0
var _time: float = 0.0
var _rays: int = RAYS_BASE
var _ray_color: Color = Color.WHITE
## 1 right after it opened (white flash), fades to 0.
var _flash: float = 0.0

var _stage: Control
var _icon: TextureRect
var _name_label: Label
var _detail_label: Label
var _rise_label: Label
var _hint_label: Label


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_stage.hide()
	GameState.item_revealed.connect(show_item)


## Queues `slot` (a copy is kept) to be shown; `rarity_up` = its rarity rose while it was made.
func show_item(slot: InventorySlot, rarity_up: bool = false) -> void:
	_queue.append({"slot": slot.copy_with_amount(slot.amount), "rarity_up": rarity_up})
	if not _showing:
		_show_next()


func is_showing() -> bool:
	return _showing


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		_stage.hide()
		WindowTitleBar.set_windows_hidden(false)
		return
	var entry: Dictionary = _queue.pop_front()
	var slot: InventorySlot = entry["slot"]
	var rarity_up: bool = entry["rarity_up"]
	_showing = true
	_shown_for = 0.0
	_flash = 1.0
	_ray_color = Rarity.get_color(slot.rarity)
	_rays = RAYS_BASE + RAYS_PER_TIER * int(slot.rarity)
	_icon.texture = slot.get_icon()
	_icon.pivot_offset = ICON_SIZE / 2.0
	_icon.scale = Vector2.ZERO
	create_tween().tween_property(_icon, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_name_label.text = slot.get_display_name()
	_name_label.add_theme_color_override("font_color", _ray_color)
	_name_label.visible_characters = 0
	create_tween().tween_property(_name_label, "visible_characters", _name_label.text.length(),
			LETTER_SECONDS * _name_label.text.length()).set_delay(0.2)
	_detail_label.text = ForgeQuality.describe(slot.rarity, slot.quality)
	_detail_label.add_theme_color_override("font_color", _ray_color)
	_rise_label.visible = rarity_up
	_hint_label.modulate.a = 0.0
	create_tween().tween_property(_hint_label, "modulate:a", 1.0, 0.3).set_delay(INPUT_DELAY)
	AudioManager.play_sound("rarity_up" if rarity_up else "item_reveal")
	_stay_on_top()
	_stage.show()


## Window layers keep growing (WindowTitleBar.bring_to_front); stay above the topmost one and keep
## the windows invisible. Checked every frame, because the station window comes back (deferred)
## right as the piece is revealed.
func _stay_on_top() -> void:
	layer = maxi(LAYER, WindowTitleBar.get_top_layer() + 1)
	WindowTitleBar.set_windows_hidden(true)


func _exit_tree() -> void:
	if _showing:
		WindowTitleBar.set_windows_hidden(false)


func _process(delta: float) -> void:
	if not _showing:
		return
	_stay_on_top()
	_time += delta
	_shown_for += delta
	_flash = maxf(0.0, _flash - delta * 3.0)
	if _rise_label.visible:
		var pulse: float = 1.0 + 0.08 * sin(_time * 8.0)
		_rise_label.pivot_offset = _rise_label.size / 2.0
		_rise_label.scale = Vector2(pulse, pulse)
	_stage.queue_redraw()


func _input(event: InputEvent) -> void:
	if not _showing:
		return
	# Every input is taken while it is shown (E, Esc ... don't reach the station window behind).
	get_viewport().set_input_as_handled()
	if _shown_for < INPUT_DELAY or event.is_echo() or not event.is_pressed():
		return
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton:
		_show_next()


func _build() -> void:
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.draw.connect(_draw_stage)
	add_child(_stage)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(column)
	_rise_label = _label(22, COLOR_RISE)
	_rise_label.text = Language.translate(TEXT_RISE)
	column.add_child(_rise_label)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = ICON_SIZE
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(_icon)
	_name_label = _label(22, Color.WHITE)
	column.add_child(_name_label)
	_detail_label = _label(11, Color.WHITE)
	column.add_child(_detail_label)
	_hint_label = _label(11, COLOR_HINT)
	_hint_label.text = Language.translate(TEXT_HINT)
	column.add_child(_hint_label)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Darkened screen, the turning rays around the icon and the white flash when it opens.
func _draw_stage() -> void:
	var screen: Vector2 = _stage.size
	_stage.draw_rect(Rect2(Vector2.ZERO, screen), DIM)
	var center: Vector2 = _icon.get_global_rect().get_center() - _stage.get_global_rect().position
	var width: float = TAU / (_rays * 2.0)
	for i in _rays:
		var angle: float = _time * RAY_SPEED + TAU * i / _rays
		var tip_a: Vector2 = center + Vector2.from_angle(angle - width / 2.0) * RAY_LENGTH
		var tip_b: Vector2 = center + Vector2.from_angle(angle + width / 2.0) * RAY_LENGTH
		var inner := Color(_ray_color, 0.35)
		var outer := Color(_ray_color, 0.0)
		_stage.draw_polygon(PackedVector2Array([center, tip_a, tip_b]), PackedColorArray([inner, outer, outer]))
	_stage.draw_circle(center, ICON_SIZE.x * 0.45, Color(_ray_color, 0.18))
	if _flash > 0.0:
		_stage.draw_rect(Rect2(Vector2.ZERO, screen), Color(1, 1, 1, _flash * 0.6))
