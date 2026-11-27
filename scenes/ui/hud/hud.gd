class_name Hud
extends CanvasLayer
## Everything drawn over the 3D view: hearts (top left), bombs / keys, the potion taken along
## (picture + key, only with a potion; Q drinks it), the map (Minimap, M), the
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
## Seconds the boss bar still fills up after the boss came (BossAltar.WAKE_TIME).
var _boss_fill_left: float = 0.0
var _banner_tween: Tween
var _message_tween: Tween
## The potion taken along (built in code under the counters): picture and key.
var _potion_row: HBoxContainer
var _potion_icon: TextureRect
var _potion_key: Label
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
	# The boss hall scene: only the picture, no HUD.
	dungeon.cutscene_changed.connect(func(active: bool) -> void: visible = not active)
	dungeon.boss_defeated.connect(_boss_box.hide)
	dungeon.message.connect(show_message)
	player.hurt.connect(_on_hurt)
	player.potion_tried.connect(_on_potion_tried)
	_build_potion_row()
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


func _process(delta: float) -> void:
	if _boss_fill_left > 0.0:
		_boss_fill_left -= delta
	elif _boss and is_instance_valid(_boss) and _boss.alive:
		_boss_bar.value = _boss.hp / _boss.max_hp * 100.0


func _update_counters() -> void:
	_bombs.text = "%02d" % run.bombs
	_keys.text = "%02d" % run.keys
	_refresh_potion()


func _build_potion_row() -> void:
	_potion_row = HBoxContainer.new()
	_potion_row.name = "PotionRow"
	_potion_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_potion_row.add_theme_constant_override("separation", 3)
	_potion_icon = TextureRect.new()
	_potion_icon.custom_minimum_size = ITEM_ICON_SIZE
	_potion_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_potion_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_potion_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_potion_row.add_child(_potion_icon)
	_potion_key = Label.new()
	_potion_key.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_potion_key.add_theme_font_size_override("font_size", 12)
	_potion_key.add_theme_constant_override("outline_size", 4)
	_potion_row.add_child(_potion_key)
	_bombs.get_parent().get_parent().add_child(_potion_row)
	_refresh_potion()


## Shows the first potion taken along (none: the row is hidden).
func _refresh_potion() -> void:
	if _potion_row == null:
		return
	_potion_row.visible = not run.potions.is_empty()
	if run.potions.is_empty():
		return
	var path: String = String(Content.potion(String(run.potions[0]["id"])).get("icon", ""))
	_potion_icon.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	var count: String = " ×%d" % run.potions.size() if run.potions.size() > 1 else ""
	_potion_key.text = "[%s]%s" % [Controls.key_name(Controls.get_key(Controls.POTION)), count]


func _on_potion_tried(drunk: bool) -> void:
	if drunk:
		_hurt.color = Color(0.3, 1.0, 0.4, 0.35)
		create_tween().tween_property(_hurt, "color:a", 0.0, 0.5)
	elif run.potions.is_empty():
		show_message("Kein Trank dabei")
	else:
		show_message("Du bist schon gesund")


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


## An achievement was reached (data/achievements.json): banner and sound.
func show_achievement(id: String) -> void:
	var data: Dictionary = Content.achievement(id)
	AudioManager.play_sound("achievement")
	show_banner(Language.translate("Erfolg: %s") % Language.translate(String(data.get("name", id))),
			Language.translate(String(data.get("desc", ""))))


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
	# The bar fills up while the boss wakes (it gets its life).
	_boss_bar.value = 0.0
	_boss_fill_left = BossAltar.WAKE_TIME
	create_tween().tween_property(_boss_bar, "value", 100.0, BossAltar.WAKE_TIME)
	_boss_box.show()


func _on_hurt() -> void:
	_hurt.color = Color(0.85, 0.05, 0.05, 0.45)
	create_tween().tween_property(_hurt, "color:a", 0.0, 0.4)


func _on_charge_changed(amount: float) -> void:
	_charge.visible = amount > 0.0
	_charge.value = amount * 100.0
