class_name Merchant
extends Station
## Market stall with its merchant. Talk to him with E (opens the ShopDialog): he sells all of
## `offers` at fixed prices (Economy, from the item values) and buys from the player.
## With `npc_id` (npcs.json) the merchant is a fixed villager: drawn from its "look" and only at
## the stall during its work hours ("work.from" - "until"); otherwise the stall is closed.
## Every merchant only sells during the market hours (economy.json "market_hours", 6-19 Uhr),
## unless `keeps_market_hours` is off (the black market never closes).
## With a walk sheet (`walk_sheet`, or the look of its villager) a stall merchant walks off to
## `walk_exit` when he closes and comes back from there when he opens (MarketWalker), if the
## player is there to see it; the stall is closed until he is back behind the counter.

@export var merchant_name: String = "":
	get:
		return Language.translate(merchant_name)
@export var stall_texture: Texture2D
## Merchant sprite (48x48, facing south).
@export var merchant_texture: Texture2D
## Look drawn with CharacterBaker instead of merchant_texture (e.g. the lizardfolk of Sahrim).
@export var appearance: Appearance
## PixelLab sheet (assets/sprites/residents/<resident>.png), wins over `appearance`.
@export var resident: String = ""
## What the merchant says in the dialog.
@export_multiline var greeting: String = "":
	get:
		return Voice.apply(Language.translate(greeting), voice)
## How the merchant speaks (Voice, e.g. "hiss" for the lizard people).
@export var voice: String = ""
## What he sells (item ids, see ContentDB.make_stack). Composed items with their parts:
## "sword:iron_blade+iron_handle"; stations: "station:water_trough" (economy.json "stations").
## Every purchase gives one piece.
@export var offers: Array[String] = []
## Where the merchant's feet are, relative to the bottom of the stall (negative = further up).
## The merchant stands behind the stall, so the counter hides everything below its top edge.
@export var merchant_feet: float = -14.0
## Fixed villager this merchant is (npcs.json), empty = always there.
@export var npc_id: String = ""
## Market merchants: section of economy.json "market_stock" that decides the daily range
## (MerchantStock; item offers in `offers` are then ignored). Empty = `offers` with default amounts.
@export var stock_id: String = ""
## Closed outside economy.json "market_hours" (off = always open, e.g. the black market).
@export var keeps_market_hours: bool = true
## Walk animation (CharacterBaker layout: 7 frames x 4 rows of 48x48). Empty = no walking, the
## merchant just disappears / appears (a merchant with `npc_id` walks with his villager look).
@export var walk_sheet: Texture2D
## Where a walking merchant leaves the map / comes from (global, outside the camera).
@export var walk_exit: Vector2 = Vector2(-560, 0)
## Last point inside the walkable area on the way to `walk_exit`.
@export var walk_exit_inside: Vector2 = Vector2(-490, 0)

## Glows (GuideOutline) while it has a ware the story guide wants bought (Guide.has_buy_target).
func is_guide_target() -> bool:
	if blocked or Guide.get_buy_specs().is_empty():
		return false
	return Guide.has_buy_target(GameState.merchant_stock.get_entries(get_stock_key(), offers, stock_id))


## Space between the top of the stall picture and the name label.
const NAME_GAP: float = 12.0
## Feet of the 48x48 merchant sprite, measured from its centre.
const MERCHANT_FEET_FROM_CENTRE: float = 17.0
## Gap between the side of the stall and the point where the merchant comes round it.
const STALL_SIDE_GAP: float = 8.0

## Opening state the merchant is in or on his way to (null until the first check).
var _open: Variant = null
var _walker: MarketWalker

@onready var _dialog: ShopDialog = $ShopDialog
@onready var _name_label: Label = $NameLabel


func _ready() -> void:
	if stall_texture == null:
		_setup_without_stall()
		return
	# The stall picture is cut to its visible pixels and stands on the node's position.
	var stall: Sprite2D = $StallSprite
	stall.texture = stall_texture
	stall.offset = Vector2(0.0, -stall_texture.get_height() / 2.0)
	# The merchant is sorted just behind the stall (y slightly smaller), so the stall covers him.
	var merchant: Sprite2D = $MerchantSprite
	merchant.texture = merchant_texture
	merchant.offset = Vector2(0.0, merchant_feet - MERCHANT_FEET_FROM_CENTRE - merchant.position.y)
	var sheet: Texture2D = _get_figure_sheet()
	if sheet:
		# First frame of the walk sheet (facing south), the same figure that walks home.
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(0, 0, 48, 48)
		merchant.texture = frame
	_name_label.text = merchant_name
	_name_label.position.y = -stall_texture.get_height() - NAME_GAP
	_dialog.setup(merchant_name, greeting, offers, 1.0, get_stock_key(), stock_id)
	_update_open()


func _process(_delta: float) -> void:
	_update_open()


## No stall (e.g. a shop in the capital): the merchant stands in front of his shop door, with his
## feet on the node's position, and only he is in the way.
func _setup_without_stall() -> void:
	var merchant: Sprite2D = $MerchantSprite
	merchant.texture = merchant_texture
	var sheet: Texture2D = _get_figure_sheet()
	if sheet:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(0, 0, 48, 48)
		merchant.texture = frame
	merchant.position = Vector2.ZERO
	merchant.offset = Vector2(0.0, -MERCHANT_FEET_FROM_CENTRE)
	var body := RectangleShape2D.new()
	body.size = Vector2(14, 6)
	($StallCollision as CollisionShape2D).shape = body
	($StallCollision as CollisionShape2D).position = Vector2(0, -3)
	_name_label.text = merchant_name
	_name_label.position.y = -merchant.texture.get_height() - 8.0
	# The stall scene sorts its children by y: the label (above the head) would be drawn behind
	# the shop wall, so it goes one layer up.
	_name_label.z_index = 1
	_dialog.setup(merchant_name, greeting, offers, 1.0, get_stock_key(), stock_id)
	_update_open()


## Key of this merchant's stock (MerchantStock): scene + node path, e.g. two "Waffenhändler"
## (market and Leonheim) have their own goods.
func get_stock_key() -> String:
	var scene_root: Node = owner if owner else get_tree().current_scene
	return "%s:%s" % [scene_root.scene_file_path, scene_root.get_path_to(self)]


## Closed outside the market hours and the work hours of its fixed villager: nobody behind the
## counter, no shop. When this changes while the scene is running, a stall merchant with a walk
## sheet walks off / comes back (the first check after loading just shows the state).
func _update_open() -> void:
	var minutes: float = GameState.day_cycle.minutes
	var market_open: bool = not keeps_market_hours or is_market_open(minutes)
	var open: bool = market_open and (npc_id.is_empty() or Residents.is_working(npc_id, minutes))
	if open == _open:
		# Something else (e.g. the StoryHider at the end of the raid) may have shown him again.
		if not open and $MerchantSprite.visible:
			$MerchantSprite.visible = false
		return
	var walks: bool = _open != null and stall_texture != null and _get_walk_sheet() != null
	_open = open
	if is_instance_valid(_walker):
		_walker.queue_free()
	if not open:
		_set_present(false)
		if walks:
			_walk(true)
	elif walks:
		_walk(false)
	else:
		_set_present(true)


## Merchant behind the counter and the shop usable, or nobody there.
func _set_present(present: bool) -> void:
	blocked = not present
	$MerchantSprite.visible = present
	_name_label.text = merchant_name if present else "%s (geschlossen)" % merchant_name
	if not present:
		_dialog.close()


## Walks from behind the counter round the stall to the exit (`leaving`) or back.
func _walk(leaving: bool) -> void:
	var behind: Vector2 = global_position + Vector2(0.0, merchant_feet)
	var side_x: float = signf(walk_exit.x - global_position.x)
	var side: Vector2 = behind + Vector2(side_x * (stall_texture.get_width() / 2.0 + STALL_SIDE_GAP), 0.0)
	var roads := owner.get_node_or_null("Roads") as VillageRoads if owner else null
	var path: PackedVector2Array
	if leaving:
		path = PackedVector2Array([side])
		path.append_array(roads.plan_through(side, PackedVector2Array([walk_exit_inside])) if roads else PackedVector2Array([walk_exit_inside]))
		path.append(walk_exit)
	else:
		path = roads.plan_through(walk_exit_inside, PackedVector2Array([side])) if roads else PackedVector2Array([side])
		path.insert(0, walk_exit_inside)
		path.append(behind)
	_walker = MarketWalker.new()
	# Next to the stall in the same y-sorted parent: drawn behind the counter while behind it.
	get_parent().add_child(_walker)
	_walker.setup(_get_walk_sheet(), behind if leaving else walk_exit, path, _get_other_counters())
	if not leaving:
		_walker.arrived.connect(_set_present.bind(true))


## Counters of the other stalls next to this one (global rects of their StallCollision): the
## walking merchant turns its corners so it doesn't cut through them.
func _get_other_counters() -> Array[Rect2]:
	var counters: Array[Rect2] = []
	for other in get_parent().get_children():
		if other != self and other is Merchant and other.stall_texture:
			var collision: CollisionShape2D = other.get_node("StallCollision")
			var shape := collision.shape as RectangleShape2D
			if shape:
				counters.append(Rect2(collision.global_position - shape.size / 2.0, shape.size))
	return counters


## The figure's sheet: PixelLab resident, else generated look (of npc_id, or `appearance`).
func _get_figure_sheet() -> Texture2D:
	var sheet: Texture2D = CharacterBaker.get_resident_sheet(Residents.get_resident(npc_id) if not npc_id.is_empty() else resident)
	if sheet:
		return sheet
	var look: Appearance = Residents.get_look(npc_id) if not npc_id.is_empty() else appearance
	return CharacterBaker.get_sheet(look) if look else null


## Walk sheet: the villager's figure (npc_id) or `walk_sheet`.
func _get_walk_sheet() -> Texture2D:
	var sheet: Texture2D = _get_figure_sheet() if not npc_id.is_empty() else null
	return sheet if sheet else walk_sheet


## true during economy.json "market_hours" ({"from": 6, "until": 19}).
static func is_market_open(minutes: float) -> bool:
	var hours: Dictionary = ContentDB.economy("market_hours")
	var hour: float = minutes / 60.0
	return hour >= float(hours.get("from", 6)) and hour < float(hours.get("until", 19))
