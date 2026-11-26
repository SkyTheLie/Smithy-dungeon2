class_name TailorStall
extends Station
## The tailor's counter in her house on the market (scenes/world/homes/market_house_e.tscn; until
## 2026-11-26 a stall on the market): E opens the TailorMenu (buy new clothes, change clothes).
## `stall_texture` = the counter. The tailor is a villager of npcs.json ("tailor": name and look,
## drawn by CharacterBaker) and stands behind her counter during the market hours
## (Merchant.is_market_open), like the merchants; outside them the shop is closed.

const NPC_ID: String = "tailor"
## Feet of the tailor relative to the bottom of the stall (behind the counter, like Merchant).
const FIGURE_FEET: float = -14.0
const FIGURE_FEET_FROM_CENTRE: float = 17.0
const NAME_GAP: float = 12.0

@export var stall_texture: Texture2D

var _open: bool = false

@onready var _stall: Sprite2D = $StallSprite
@onready var _figure: Sprite2D = $FigureSprite
@onready var _name_label: Label = $NameLabel
@onready var _menu: TailorMenu = $TailorMenu


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	_stall.texture = stall_texture
	_stall.offset = Vector2(0.0, -stall_texture.get_height() / 2.0) if stall_texture else Vector2.ZERO
	var frame := AtlasTexture.new()
	frame.atlas = CharacterBaker.get_sheet(get_look())
	frame.region = CharacterBaker.get_frame_rect("down", 0)
	_figure.texture = frame
	_figure.offset = Vector2(0.0, FIGURE_FEET - FIGURE_FEET_FROM_CENTRE - _figure.position.y)
	_name_label.position.y = -(stall_texture.get_height() if stall_texture else 48) - NAME_GAP
	_open = not Merchant.is_market_open(GameState.day_cycle.minutes)
	_update_open()


func _process(_delta: float) -> void:
	_update_open()


## The tailor's look (npcs.json "tailor" "look").
static func get_look() -> Appearance:
	return Appearance.from_save_data(ContentDB.npc_info(NPC_ID).look)


static func get_tailor_name() -> String:
	var info: NpcInfo = ContentDB.npc_info(NPC_ID)
	return info.display_name if not info.display_name.is_empty() else Language.translate("Schneiderin")


func _update_open() -> void:
	var open: bool = Merchant.is_market_open(GameState.day_cycle.minutes)
	if open == _open:
		return
	_open = open
	blocked = not open
	_figure.visible = open
	_name_label.text = get_tailor_name() if open else Language.translate("%s (geschlossen)") % get_tailor_name()
	if not open:
		_menu.close()
