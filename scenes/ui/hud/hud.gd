class_name Hud
extends CanvasLayer
## Everything drawn over the 3D view: hearts (top left), bombs / keys, the potion taken along
## (picture + key, only with a potion; Q drinks it), the map (Minimap, M), the
## crosshair, collected items, the boss's life bar, the charge bar (Glutsammler), the name of a
## new item or synergy, short messages, the red flash when hit and "[F] Mit dem Händler handeln"
## near the merchant of the dungeon shop (Dungeon.near_merchant). Only shows values; the rules are
## in RunState and Dungeon.

const BANNER_TIME: float = 3.0
const MESSAGE_TIME: float = 2.2
## Colour of the life bar for the boss (as in hud.tscn) and for a leader (mini boss).
const BOSS_BAR_COLOR := Color(1, 0.35, 0.3, 1)
const LEADER_BAR_COLOR := Color(1, 0.8, 0.25, 1)
## Seconds the leader's bar fills up when it comes.
const LEADER_FILL_TIME: float = 0.6
const ITEM_ICON_SIZE := Vector2(16, 16)

var run: RunState
var dungeon: Dungeon
var player: Player

var _boss: Enemy = null
## Seconds the boss bar still fills up after the boss came (BossAltar.WAKE_TIME).
var _boss_fill_left: float = 0.0
var _banner_tween: Tween
var _message_tween: Tween
## The guide's box (show_guide; null until the guide shows a line).
var guide_box: PanelContainer = null
var _guide_label: Label
## The potion taken along (built in code under the counters): picture and key.
var _potion_row: HBoxContainer
var _potion_icon: TextureRect
var _potion_key: Label
## "[F] Mit dem Händler handeln" (built in code, bottom middle).
var talk_prompt: Label
## "+2 Rattenfell" lines (right of the middle), newest at the bottom.
var _loot_popups: VBoxContainer
## Red pulsing edge while life is low (≤ LOW_LIFE_HALVES).
var _low_life: TextureRect
var _low_tween: Tween
const LOW_LIFE_HALVES: int = 2
const POPUP_TIME: float = 1.6
@onready var _crosshair: Crosshair = $Crosshair
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
	dungeon.leader_appeared.connect(_on_leader_appeared)
	dungeon.leader_defeated.connect(func() -> void:
		if _boss == null or not is_instance_valid(_boss) or _boss.is_leader:
			_boss_box.hide())
	dungeon.message.connect(show_message)
	player.hurt.connect(_on_hurt)
	player.potion_tried.connect(_on_potion_tried)
	_build_potion_row()
	_build_talk_prompt()
	_build_loot_popups()
	_build_low_life()
	run.loot_picked.connect(_on_loot_picked)
	dungeon.enemy_damaged.connect(func(_enemy: Enemy, _amount: float, killed: bool) -> void: _crosshair.show_hit(killed))
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
	talk_prompt.visible = dungeon.near_merchant()
	if _boss_fill_left > 0.0:
		_boss_fill_left -= delta
	elif _boss and is_instance_valid(_boss) and _boss.alive:
		_boss_bar.value = _boss.hp / _boss.max_hp * 100.0


func _update_counters() -> void:
	_bombs.text = "%02d" % run.bombs
	_keys.text = "%02d" % run.keys
	_refresh_potion()
	_refresh_low_life()


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


func _build_loot_popups() -> void:
	_loot_popups = VBoxContainer.new()
	_loot_popups.name = "LootPopups"
	_loot_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loot_popups.alignment = BoxContainer.ALIGNMENT_END
	_loot_popups.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_loot_popups.offset_left = -170
	_loot_popups.offset_right = -10
	_loot_popups.offset_top = -10
	_loot_popups.offset_bottom = 90
	add_child(_loot_popups)


## "+2 Rattenfell" in the rarity colour of the loot: pops in, stays, fades.
func _on_loot_picked(id: String, count: int) -> void:
	var data: Dictionary = Content.material(id)
	var line := Label.new()
	line.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	line.text = "+%d %s" % [count, Language.translate(String(data.get("name", id)))]
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_theme_font_size_override("font_size", 12)
	line.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if id == Bag.GOLD else Rarity.color(int(data.get("rarity", 1))))
	line.add_theme_color_override("font_outline_color", Color.BLACK)
	line.add_theme_constant_override("outline_size", 4)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loot_popups.add_child(line)
	while _loot_popups.get_child_count() > 5:
		_loot_popups.get_child(0).free()
	line.pivot_offset = Vector2(160, 8)
	line.scale = Vector2(1.4, 1.4)
	var tween := line.create_tween()
	tween.tween_property(line, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(POPUP_TIME)
	tween.tween_property(line, "modulate:a", 0.0, 0.4)
	tween.tween_callback(line.queue_free)


## A red glow around the edges (radial gradient), shown and pulsing while life is low.
func _build_low_life() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	gradient.colors = PackedColorArray([Color(0.8, 0.0, 0.0, 0.0), Color(0.8, 0.0, 0.0, 0.0), Color(0.85, 0.05, 0.05, 0.5)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 1.0)
	texture.width = 64
	texture.height = 36
	_low_life = TextureRect.new()
	_low_life.name = "LowLife"
	_low_life.texture = texture
	_low_life.stretch_mode = TextureRect.STRETCH_SCALE
	_low_life.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_low_life.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_low_life.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_low_life.modulate.a = 0.0
	_low_life.hide()
	add_child(_low_life)
	move_child(_low_life, 0)


## Low life (red + blue halves ≤ LOW_LIFE_HALVES, more than one heart in all): the edge pulses
## like a heartbeat and the hearts beat with it.
func _refresh_low_life() -> void:
	if _low_life == null:
		return
	var low: bool = run.health + run.blue <= LOW_LIFE_HALVES and run.health > 0 and run.max_hearts > 1
	if low == _low_life.visible:
		return
	_low_life.visible = low
	if _low_tween:
		_low_tween.kill()
	_hearts.scale = Vector2.ONE
	if not low:
		return
	_hearts.pivot_offset = Vector2(8, 8)
	_low_tween = create_tween().set_loops()
	_low_tween.tween_property(_low_life, "modulate:a", 1.0, 0.18)
	_low_tween.parallel().tween_property(_hearts, "scale", Vector2.ONE * 1.12, 0.18)
	_low_tween.tween_property(_low_life, "modulate:a", 0.35, 0.5)
	_low_tween.parallel().tween_property(_hearts, "scale", Vector2.ONE, 0.5)


## true while the low-life warning shows (tests).
func is_low_life_shown() -> bool:
	return _low_life != null and _low_life.visible


func _build_talk_prompt() -> void:
	talk_prompt = Label.new()
	talk_prompt.name = "TalkPrompt"
	talk_prompt.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	talk_prompt.text = "[%s] %s" % [Controls.key_name(Controls.get_key(Controls.TALK)), Language.translate("Mit dem Händler handeln")]
	talk_prompt.add_theme_font_size_override("font_size", 12)
	talk_prompt.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	talk_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	talk_prompt.add_theme_constant_override("outline_size", 4)
	talk_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	talk_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	talk_prompt.offset_top = -78
	talk_prompt.offset_bottom = -62
	talk_prompt.offset_left = -160
	talk_prompt.offset_right = 160
	talk_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	talk_prompt.hide()
	add_child(talk_prompt)


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


## The guide of the first run (DungeonGuide): one line in a box at the top middle, until the
## next step ("" hides it). `text` is already translated.
func show_guide(text: String) -> void:
	if guide_box == null:
		guide_box = PanelContainer.new()
		guide_box.name = "GuideBox"
		guide_box.theme_type_variation = &"HudPanel"
		guide_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		guide_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		guide_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
		guide_box.offset_top = 38
		_guide_label = Label.new()
		_guide_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_guide_label.add_theme_font_size_override("font_size", 12)
		_guide_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.65))
		_guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_guide_label.custom_minimum_size = Vector2(260, 0)
		guide_box.add_child(_guide_label)
		add_child(guide_box)
	guide_box.visible = not text.is_empty()
	if text.is_empty():
		return
	_guide_label.text = text
	guide_box.reset_size()
	guide_box.offset_left = -guide_box.get_combined_minimum_size().x / 2.0
	guide_box.offset_right = guide_box.get_combined_minimum_size().x / 2.0
	# A little hop, so the new step catches the eye.
	guide_box.pivot_offset = guide_box.get_combined_minimum_size() / 2.0
	guide_box.scale = Vector2(1.15, 1.15)
	create_tween().tween_property(guide_box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
	_boss_bar.modulate = BOSS_BAR_COLOR
	# The bar fills up while the boss wakes (it gets its life).
	_boss_bar.value = 0.0
	_boss_fill_left = BossAltar.WAKE_TIME
	create_tween().tween_property(_boss_bar, "value", 100.0, BossAltar.WAKE_TIME)
	_show_phase_marks(true)
	_boss_box.show()


## Thin marks on the boss bar where its phases begin (enemies.json boss_phases "at"); not for
## leaders.
func _show_phase_marks(shown: bool) -> void:
	for mark: Node in _boss_bar.get_children():
		if mark.has_meta("phase_mark"):
			mark.queue_free()
	if not shown:
		return
	for at: Variant in BossBrain.phase_rules().get("at", []):
		var mark := ColorRect.new()
		mark.set_meta("phase_mark", true)
		mark.color = Color(1, 1, 1, 0.8)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.anchor_left = float(at)
		mark.anchor_right = float(at)
		mark.anchor_top = 0.0
		mark.anchor_bottom = 1.0
		mark.offset_left = 0.0
		mark.offset_right = 1.0
		_boss_bar.add_child(mark)


## The leader (mini boss) of the floor: the same bar as the boss, golden, filling up quickly.
func _on_leader_appeared(leader: Enemy) -> void:
	_boss = leader
	_boss_name.text = Language.translate("Anführer: %s") % Language.translate(String(leader.data.get("name", "")))
	_boss_bar.modulate = LEADER_BAR_COLOR
	_show_phase_marks(false)
	_boss_bar.value = 0.0
	_boss_fill_left = LEADER_FILL_TIME
	create_tween().tween_property(_boss_bar, "value", 100.0, LEADER_FILL_TIME)
	_boss_box.show()


func _on_hurt() -> void:
	_hurt.color = Color(0.85, 0.05, 0.05, 0.45)
	create_tween().tween_property(_hurt, "color:a", 0.0, 0.4)


func _on_charge_changed(amount: float) -> void:
	_charge.visible = amount > 0.0
	_charge.value = amount * 100.0
