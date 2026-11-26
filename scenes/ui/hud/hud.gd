class_name Hud
extends CanvasLayer
## Everything drawn over the 3D view: hearts (top left), bombs / keys, the map (Minimap, M), the
## crosshair, collected items, the boss's life bar, the charge bar (Glutsammler), the name of a
## new item or synergy, short messages and the red flash when hit. Only shows values; the rules are
## in RunState and Dungeon.

const BANNER_TIME: float = 3.0
const MESSAGE_TIME: float = 2.2
const ITEM_ICON_SIZE := Vector2(16, 16)

var run: RunState
var dungeon: Dungeon
var player: Player

var _boss: Enemy = null
var _banner_tween: Tween
var _message_tween: Tween
@onready var _hearts: HeartBar = %Hearts
@onready var _bombs: Label = %Bombs
@onready var _keys: Label = %Keys
@onready var _minimap: Minimap = %Minimap
@onready var _items: HBoxContainer = %Items
@onready var _boss_box: Control = %BossBox
@onready var _boss_name: Label = %BossName
@onready var _boss_bar: ProgressBar = %BossBar
@onready var _charge: ProgressBar = %Charge
@onready var _banner: Control = %Banner
@onready var _banner_title: Label = %BannerTitle
@onready var _banner_text: Label = %BannerText
@onready var _message: Label = %Message
@onready var _hurt: ColorRect = %Hurt
@onready var _fade: ColorRect = %Fade


func setup(run_state: RunState, the_dungeon: Dungeon, the_player: Player) -> void:
	run = run_state
	dungeon = the_dungeon
	player = the_player
	_hearts.setup(run)
	_minimap.setup(dungeon, player)
	run.changed.connect(_update_counters)
	run.item_added.connect(_on_item_added)
	run.items_cleared.connect(_on_items_cleared)
	run.unlocked.connect(_on_unlocked)
	run.synergy_found.connect(_on_synergy_found)
	dungeon.boss_appeared.connect(_on_boss_appeared)
	dungeon.boss_defeated.connect(_boss_box.hide)
	dungeon.message.connect(show_message)
	player.hurt.connect(_on_hurt)
	player.weapon.charge_changed.connect(_on_charge_changed)
	_boss_box.hide()
	_charge.hide()
	_banner.modulate.a = 0.0
	_message.modulate.a = 0.0
	_update_counters()
	for id: String in run.items:
		_add_item_icon(id)
	var number: int = run.floor_index + 1
	show_banner(Language.translate("Ebene %d") % number, Language.translate(String(dungeon.floor_data.get("name", ""))))
	_fade.color.a = 1.0
	create_tween().tween_property(_fade, "color:a", 0.0, 0.6)


func toggle_map() -> void:
	_minimap.toggle()


func is_map_open() -> bool:
	return _minimap.expanded


func _process(_delta: float) -> void:
	if _boss and is_instance_valid(_boss) and _boss.alive:
		_boss_bar.value = _boss.hp / _boss.max_hp * 100.0


func _update_counters() -> void:
	_bombs.text = "%02d" % run.bombs
	_keys.text = "%02d" % run.keys


## Big text in the upper middle (new item, synergy, floor name), fades out by itself.
func show_banner(title: String, text: String) -> void:
	_banner_title.text = title
	_banner_text.text = text
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 1.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(BANNER_TIME)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


## Short line at the bottom ("Du brauchst einen Schlüssel"). `text` is the German key.
func show_message(text: String) -> void:
	_message.text = Language.translate(text)
	if _message_tween:
		_message_tween.kill()
	_message.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_TIME)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.5)


## Black over everything (floor change); returns when it is dark.
func fade_out(time: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, time)
	await tween.finished


func _on_item_added(id: String) -> void:
	var data: Dictionary = Content.item(id)
	show_banner(Language.translate(String(data.get("name", id))), Language.translate(String(data.get("desc", ""))))
	_add_item_icon(id)


func _on_unlocked(id: String) -> void:
	# An item or a character (data/characters.json).
	var data: Dictionary = Content.item(id) if not Content.item(id).is_empty() else Content.character(id)
	# After the item / synergy banners, so all can be read.
	await get_tree().create_timer(3.2, false).timeout
	show_banner(Language.translate("Freigeschaltet: %s") % Language.translate(String(data.get("name", id))),
			Language.translate("Kann ab jetzt im Dungeon auftauchen"))


func _on_items_cleared() -> void:
	for icon: Node in _items.get_children():
		icon.queue_free()


func _on_synergy_found(id: String) -> void:
	var data: Dictionary = Content.synergies().get(id, {})
	AudioManager.play_sound("synergy")
	# Comes right after the item banner; waits so both can be read.
	await get_tree().create_timer(1.6, false).timeout
	show_banner(Language.translate("Synergie: %s!") % Language.translate(String(data.get("name", id))), Language.translate(String(data.get("desc", ""))))


func _add_item_icon(id: String) -> void:
	var texture := load(String(Content.item(id).get("icon", ""))) as Texture2D
	if texture == null:
		return
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = ITEM_ICON_SIZE
	icon.tooltip_text = Language.translate(String(Content.item(id).get("name", id)))
	_items.add_child(icon)


func _on_boss_appeared(boss: Enemy) -> void:
	_boss = boss
	_boss_name.text = Language.translate(String(boss.data.get("name", "")))
	_boss_bar.value = 100.0
	_boss_box.show()


func _on_hurt() -> void:
	_hurt.color.a = 0.45
	create_tween().tween_property(_hurt, "color:a", 0.0, 0.4)


func _on_charge_changed(amount: float) -> void:
	_charge.visible = amount > 0.0
	_charge.value = amount * 100.0
