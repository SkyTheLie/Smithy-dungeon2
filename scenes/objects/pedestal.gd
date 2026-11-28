class_name Pedestal
extends Node3D
## Stone pedestal with something floating above it: an item (item room, boss reward, shop) or
## shop goods (heart, bomb, key). Walking against it takes it; in the shop only if the coins are
## enough (price shown above it). Empty afterwards.
## Test room: refill() fills it again, show_item() puts another item on it; goods RESET and
## PAGE show a text instead of a picture and only send `taken` (the Dungeon does the rest).

signal taken(pedestal: Pedestal)
## The player stands at it without enough coins (German text key for the HUD).
signal message_requested(text: String)

const TAKE_DISTANCE: float = 0.95
const STONE: String = "res://assets/sprites/rooms/styles/wall_obsidian.png"
const RESET: String = "reset"
const PAGE: String = "page"

## Item id, or "" for goods.
var item_id: String = ""
## "heart", "bomb", "key" for goods (or RESET in the test room).
var goods: String = ""
var price: int = 0
## Glutpakt: costs this many heart containers instead of coins (0 = none).
var heart_price: int = 0
var run: RunState
var player: Node3D

var _icon: Sprite3D
var _label: Label3D
var _time: float = 0.0
var _empty: bool = false
## Shows "not enough coins" only once per approach.
var _warned: bool = false
## After refill(): the player has to step away once before it can be taken again.
var _wait_for_leave: bool = false


func setup(the_item: String, the_goods: String, the_price: int, run_state: RunState, the_player: Node3D) -> void:
	item_id = the_item
	goods = the_goods
	price = maxi(0, the_price)
	run = run_state
	player = the_player


func is_empty() -> bool:
	return _empty


## The picture floating above it (for the map); null when empty or a test-room button.
func map_icon() -> Texture2D:
	return _icon.texture if _icon and not _empty and visible else null


## The price now (half with "discount").
func current_price() -> int:
	if price > 0 and run and run.stats.has("discount"):
		return maxi(1, ceili(price * float((Content.player().get("effects", {}) as Dictionary).get("discount", 0.5))))
	return price


func _ready() -> void:
	RoomBuilder.box(self, Vector3(0.8, 0.8, 0.8), Vector3(0, 0.4, 0),
			RoomBuilder.tiled_material(STONE, Vector3(0.8, 0.8, 0.8), Color(0.8, 0.8, 0.85)), RoomBuilder.LAYER_ROCKS)
	_make_icon()
	if goods == RESET:
		_label = _make_label(Language.translate("Alle Items ablegen"), Color(1, 0.45, 0.35))
		_label.position.y = 1.3
	elif goods == PAGE:
		_label = _make_label(Language.translate("Nächste Seite"), Color(0.55, 0.85, 1.0))
		_label.position.y = 1.3
	elif price > 0:
		_label = _make_label("%d" % price, Color(1, 0.86, 0.4))
		_label.position.y = 1.85
	elif heart_price > 0:
		_label = _make_label(Language.translate("%d Herzen") % heart_price, Color(1, 0.35, 0.3))
		_label.position.y = 1.85
	var glow := OmniLight3D.new()
	glow.light_color = Color(1, 0.35, 0.25) if _is_button() else Color(1, 0.85, 0.5)
	glow.light_energy = 0.6
	glow.omni_range = 2.5
	glow.position.y = 1.4
	add_child(glow)


## Test room: full again (the same item or goods).
func refill() -> void:
	if not _empty:
		return
	_empty = false
	_wait_for_leave = true
	_make_icon()


## Test room: another item on this pedestal ("" = none: hidden and switched off).
func show_item(id: String) -> void:
	item_id = id
	if _icon:
		_icon.queue_free()
		_icon = null
	visible = not id.is_empty()
	process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED
	_empty = id.is_empty()
	if visible:
		_make_icon()


## Test room buttons (no item, only a text).
func _is_button() -> bool:
	return goods == RESET or goods == PAGE


func _make_icon() -> void:
	if _is_button():
		return
	var texture: Texture2D = null
	if not item_id.is_empty():
		texture = load(String(Content.item(item_id).get("icon", ""))) as Texture2D
	else:
		texture = Pickup.icon(goods)
	if texture:
		_icon = Fx.billboard(texture, 0.6)
		_icon.position.y = 1.25
		add_child(_icon)


func _make_label(text: String, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.pixel_size = 0.012
	label.font_size = 32
	label.outline_size = 8
	label.modulate = color
	add_child(label)
	return label


func _physics_process(delta: float) -> void:
	_time += delta
	if _icon:
		_icon.position.y = 1.25 + sin(_time * 2.5) * 0.06
	if _empty or player == null or run == null:
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	if offset.length() > TAKE_DISTANCE:
		_warned = false
		_wait_for_leave = false
		return
	if _wait_for_leave:
		return
	if _label and price > 0 and not _is_button():
		_label.text = "%d" % current_price()
	if price > 0 and run.coins < current_price():
		if not _warned:
			_warned = true
			AudioManager.play_sound("denied")
			message_requested.emit("Zu wenig Münzen")
		return
	if not goods.is_empty() and goods == "heart" and run.health >= run.max_hearts * 2:
		return
	if heart_price > 0:
		if run.take_pact(item_id, heart_price):
			_take_pact()
		elif not _warned:
			_warned = true
			AudioManager.play_sound("denied")
			message_requested.emit("Das kostet zu viel Leben")
		return
	_take()


## The pact was paid (RunState.take_pact added the item): only the pedestal empties.
func _take_pact() -> void:
	_empty = true
	AudioManager.play_sound("item")
	if _icon:
		_icon.queue_free()
		_icon = null
	if _label:
		_label.queue_free()
		_label = null
	taken.emit(self)


func _take() -> void:
	if price > 0 and not run.spend(current_price()):
		return
	if price > 0:
		AudioManager.play_sound("buy")
	_empty = true
	if _icon:
		_icon.queue_free()
		_icon = null
	if _label and not _is_button():
		_label.queue_free()
		_label = null
	if not item_id.is_empty():
		AudioManager.play_sound("item")
		run.add_item(item_id)
	else:
		match goods:
			"heart":
				run.heal(2)
			"bomb":
				run.add_bombs(1)
			"key":
				run.add_keys(1)
		AudioManager.play_sound("pickup")
	taken.emit(self)


## Glutpakt: from now on it costs `hearts` heart containers (label in red).
func set_heart_price(hearts: int) -> void:
	heart_price = maxi(0, hearts)
	if _label:
		_label.queue_free()
	_label = _make_label(Language.translate("%d Herzen") % heart_price, Color(1, 0.35, 0.3))
	_label.position.y = 1.85
