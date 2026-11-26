class_name GambaGame
extends Node2D
## The lucky forge (roguelite, rules in GambaRun, numbers in gamba.json): inside the smithy, the
## forge in the back, the anvil in front. Left the bench with the swords of the day, right the
## guild's table with tonight's tribute and the bell; above the anvil the five buckets of the next
## strike. "Schmieden" heats a sword in the forge and lays it on the anvil; then every click into the
## picture (or Space / "Schlagen") is one hammer strike. "Reliktschrein" (top bar) trades a sword
## for a guild mark and marks for relics. After the bell: day result, every third day the merchant;
## the run is saved after each of them (GambaSaves). Esc pauses (DefensePauseMenu: settings, give
## up, main menu, quit).

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu/main_menu.tscn"
const MUSIC_KEY: String = "gamba"
const MUSIC_ID: String = "den"
const FIRE_SIZE: int = 64
const FIRE_FPS: float = 12.0
const FORGE_LIGHT := Vector2(321, 196)
const ANVIL_TOP := Vector2(318, 247)
## The hammer (title_hammer.png) swings around its grip; these angles in degrees.
const HAMMER_RAISED: float = 35.0
const HAMMER_REST: float = 80.0
const HOT_TINT := Color(1.0, 0.62, 0.38)
const ICON_SIZE := Vector2(24, 24)
const GOOD_COLOR := Color(0.45, 0.9, 0.45)
const BAD_COLOR := Color(1.0, 0.45, 0.4)
## Space kept free above and below the popup; the cards never get lower than this when they scroll.
const POPUP_MARGIN: float = 8.0
const POPUP_MIN_ITEMS_HEIGHT: float = 60.0

var run: GambaRun
## Seconds until the next strike is allowed.
var _cooldown: float = 0.0
## A sword is on its way through the forge (no other action until it lies on the anvil).
var _heating: bool = false
var _was_frenzy: bool = false
var _fire_time: float = 0.0
var _shake: float = 0.0
## A shrine relic waiting for a full slot to be freed (drop choice).
var _pending_relic: String = ""
## Counts popup fits; a fit still waiting for its frame stops when a newer popup has opened.
var _popup_fit: int = 0  # not saved on purpose
var _forge_glow: Sprite2D
var _anvil_glow: Sprite2D
var _sparks: CPUParticles2D
var _shards: CPUParticles2D
var _hammer_tween: Tween
## Unknown outcome names and colours are read once.
var _outcome_names: Dictionary[String, String] = {}
var _outcome_colors: Dictionary[String, Color] = {}

@onready var _camera: Camera2D = $Camera
@onready var _fire: Sprite2D = $World/Fire
@onready var _forge_sword: Node2D = $World/ForgeSword
@onready var _anvil_sword: Node2D = $World/AnvilSword
@onready var _hammer: Node2D = $World/Hammer
@onready var _buckets: GambaBuckets = %Buckets
@onready var _popup: PanelContainer = %Popup
@onready var _pause_menu: DefensePauseMenu = %PauseMenu
@onready var _card_style: StyleBox = (%CardStyle as Panel).get_theme_stylebox("panel")


func _ready() -> void:
	# Nothing of the smithy game (day, workshop, autosave) runs here.
	GameState.in_main_menu = true
	for outcome: String in GambaRun.OUTCOMES:
		_outcome_names[outcome] = GambaRun.outcome_name(outcome)
		_outcome_colors[outcome] = GambaRun.outcome_color(outcome)
	_fire.hframes = maxi(1, floori(float(_fire.texture.get_width()) / FIRE_SIZE))
	_build_effects()
	_hammer.rotation_degrees = HAMMER_REST
	AudioManager.set_music_override(MUSIC_KEY, MUSIC_ID)
	AudioManager.update_ambience()
	%StrikeButton.pressed.connect(strike)
	%TakeOffButton.pressed.connect(_on_take_off)
	%WardButton.pressed.connect(_on_ward)
	%UndoButton.pressed.connect(_on_undo)
	%BellButton.pressed.connect(ring_bell)
	%ShrineButton.pressed.connect(open_shrine)
	# Space strikes: no button may keep the focus (Space would press it, e.g. the bell).
	for button: Button in [%StrikeButton, %TakeOffButton, %WardButton, %UndoButton, %BellButton, %ShrineButton]:
		button.focus_mode = Control.FOCUS_NONE
	_pause_menu.main_menu_requested.connect(_to_main_menu)
	_pause_menu.give_up_requested.connect(_give_up)
	run = GambaRun.new()
	run.gold_changed.connect(func(_gold: int) -> void: _refresh_top())
	var saved: Dictionary = GambaSaves.read()
	if not saved.is_empty() and not bool(saved.get("ended", false)):
		run.load_save(saved)
		_refresh_all()
		_show_next_popup()
	else:
		start_new_run()


func _exit_tree() -> void:
	get_tree().paused = false
	AudioManager.set_music_override(MUSIC_KEY, "")


## A fresh run: the rules first.
func start_new_run() -> void:
	run.start_new()
	GambaSaves.write(run)
	_refresh_all()
	var rules: Array[String] = [
		Language.translate("Die Zunft verlangt jeden Abend eine Abgabe in Schwertwert. Nimm ein Schwert von der Werkbank, erhitze es und schlag es auf dem Amboss."),
		Language.translate("Jeder Schlag zieht aus fünf Eimern: Zerbrochen, Beschädigt, Nichts, Verbessert, Verbessert ++. Mit jedem Schlag wird Zerbrechen wahrscheinlicher."),
		Language.translate("Nach %d Schlägen an einem Schwert kommt die Raserei: ein paar Sekunden lang kann nichts brechen, schlag so schnell du kannst!") % run.frenzy_limit(),
		Language.translate("Leg fertige Schwerter auf den Tisch der Zunft und läute die Glocke. Dreimal zu wenig, und die Zunft schließt deine Schmiede. Halte %d Tage durch.") % run.contract_days(),
		Language.translate("Relikte gibt es nur im Reliktschrein: Ein Schwert ab %s bringt eine Zunftmarke, mit Marken kaufst du Relikte.") % GambaRun.level_short(GambaRun.coin_min_level()),
	]
	_open_popup(Language.translate("Die Glücksschmiede"), "\n".join(rules))
	_add_popup_button(Language.translate("Los geht's"), _show_next_popup)


func _process(delta: float) -> void:
	_fire_time += delta
	_fire.frame = int(_fire_time * FIRE_FPS) % _fire.hframes
	var flicker: float = 0.85 + 0.1 * sin(_fire_time * 7.0) + 0.05 * sin(_fire_time * 17.0)
	_forge_glow.modulate.a = flicker
	_cooldown = maxf(0.0, _cooldown - delta)
	run.tick(delta)
	var frenzy: bool = run.in_frenzy()
	if frenzy:
		%FrenzyBar.value = run.frenzy_left / maxf(0.01, run.frenzy_seconds())
	if frenzy != _was_frenzy:
		_was_frenzy = frenzy
		%FrenzyBar.visible = frenzy
		_refresh_anvil()
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 20.0)
		_camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_pause_menu.open(not run.ended)
		return
	if _popup.visible:
		return
	var click := event as InputEventMouseButton
	if (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT) or \
			(event is InputEventKey and event.is_pressed() and (event as InputEventKey).keycode == KEY_SPACE):
		get_viewport().set_input_as_handled()
		strike()


# --- Forge --------------------------------------------------------------------------------------

## One hammer strike on the sword on the anvil (ignored while the hammer is still up).
func strike() -> void:
	if run.anvil == null or _heating or _cooldown > 0.0 or _popup.visible or run.ended:
		return
	var frenzy: bool = run.in_frenzy()
	_cooldown = float(GambaRun.data().get("frenzy_cooldown" if frenzy else "strike_cooldown", 0.2))
	_swing_hammer()
	var result: Dictionary = run.strike()
	if result.is_empty():
		return
	var outcome: String = String(result.outcome)
	_buckets.flash(outcome)
	_sparks.restart()
	var pitch: float = 1.0 + 0.04 * float(result.level)
	match outcome:
		"break":
			AudioManager.play_sound("rock_break")
			AudioManager.play_sound("wood_break", 1.3)
			_shards.restart()
			_shake = 6.0
			_float_text(_outcome_names["break"], _outcome_colors["break"], 1.4)
			if int(result.gold_back) > 0:
				_float_text("+" + GambaRun.format_gold(int(result.gold_back)), Color(1, 0.84, 0.3), 1.0, 14.0)
		"damage":
			AudioManager.play_sound("anvil_miss")
			_shake = 2.5
			var text: String = Language.translate("Bruch abgewehrt") if bool(result.shielded) else _outcome_names["damage"]
			_float_text(text, _outcome_colors["damage"], 1.0)
		"hold":
			AudioManager.play_sound("anvil_good", 0.85)
			_float_text(_outcome_names["hold"], _outcome_colors["hold"], 0.8)
		"success":
			AudioManager.play_sound("anvil_good", pitch)
			_shake = 1.0
			_float_text("+1  " + GambaRun.level_short(int(result.level)), GambaRun.level_color(int(result.level)), 1.0)
		"great":
			AudioManager.play_sound("anvil_perfect", pitch)
			AudioManager.play_sound("rarity_up", 1.2)
			_shake = 2.0
			_float_text("++  " + GambaRun.level_short(int(result.level)), GambaRun.level_color(int(result.level)), 1.3)
	if bool(result.frenzy_started):
		AudioManager.play_sound("level_up")
		_float_text(Language.translate("RASEREI!"), Color(1.0, 0.5, 0.2), 1.6, -26.0)
	_refresh_all()


## The sword goes into the fire, glows and lands on the anvil.
func forge_sword(sword: GambaSword) -> void:
	if _heating or _popup.visible or run.ended or sword == null:
		return
	_heating = true
	run.take_off_anvil()
	sword.offered = false
	_refresh_all()
	_set_sword_sprites(_forge_sword, sword)
	_forge_sword.visible = true
	_forge_sword.modulate = Color.WHITE
	AudioManager.play_sound("quench_hiss", 0.7)
	var heat: float = float(GambaRun.data().get("heat_seconds", 0.7))
	var glow := create_tween()
	glow.tween_property(_forge_sword, "modulate", HOT_TINT, heat * 0.7)
	glow.tween_property(_forge_sword, "position", ANVIL_TOP, heat * 0.3).set_ease(Tween.EASE_IN_OUT)
	await glow.finished
	_forge_sword.visible = false
	_forge_sword.position = Vector2(320, 214)
	_heating = false
	if not is_inside_tree():
		return
	run.put_on_anvil(sword)
	AudioManager.play_sound("anvil_good", 0.7)
	_refresh_all()


func _on_take_off() -> void:
	if _heating:
		return
	run.take_off_anvil()
	_refresh_all()


func _on_ward() -> void:
	if run.use_ward():
		AudioManager.play_sound("pillar_chime")
		_refresh_all()


func _on_undo() -> void:
	if run.undo_strike():
		AudioManager.play_sound("unlock")
		_float_text(Language.translate("Rückgängig"), Color(0.64, 0.86, 1), 1.0)
		_refresh_all()


# --- Day end ------------------------------------------------------------------------------------

## End of the day (the bell): result, then relic choice and merchant.
func ring_bell() -> void:
	if _heating or _popup.visible or run.ended:
		return
	AudioManager.play_sound("pillar_chime", 0.8)
	var result: Dictionary = run.ring_bell()
	if run.ended:
		GambaSaves.delete()
	else:
		GambaSaves.write(run)
	_refresh_all()
	var paid: bool = bool(result.paid)
	var text: String
	if paid:
		AudioManager.play_sound("coins")
		text = Language.translate("Die Zunft nimmt Schwerter im Wert von %s und zahlt dir alles aus.") % GambaRun.format_gold(int(result.amount))
	else:
		AudioManager.play_sound("anvil_miss", 0.7)
		text = Language.translate("Zu wenig: %s von %s. Die Zunft ist verärgert, die Schwerter gehen zurück auf die Werkbank.") % [
				GambaRun.format_gold(int(result.amount)), GambaRun.format_gold(int(result.demand))]
		text += "\n" + Language.translate("Fehlschläge: %d von %d.") % [run.failures, run.max_failures()]
	if run.ended:
		_show_result()
		return
	text += "\n" + Language.translate("Morgen verlangt sie %s.") % GambaRun.format_gold(run.demand())
	_open_popup(Language.translate("Abgabe erfüllt!") if paid else Language.translate("Abgabe verfehlt"), text)
	_add_popup_button(Language.translate("Weiter"), _show_next_popup)


## After the day result (or after loading): the merchant, then the new day.
func _show_next_popup() -> void:
	_close_popup()
	if not run.shop.is_empty():
		_show_shop()


# --- Relic shrine -------------------------------------------------------------------------------

## The shrine: today's relic offers (bought with marks) and the swords that can be given up.
func open_shrine() -> void:
	if _heating or run.ended or (_popup.visible and _pending_relic.is_empty()):
		return
	_pending_relic = ""
	var min_level: String = GambaRun.level_short(GambaRun.coin_min_level())
	var text: String = Language.translate("Zunftmarken: %d") % run.coins
	text += "\n" + Language.translate("Gib ein Schwert ab %s für eine Marke ab. Nach jeder Glocke bietet der Schrein neue Relikte an.") % min_level
	if run.relic_offers.is_empty():
		text += "\n" + Language.translate("Heute bietet der Schrein nichts mehr an.")
	_open_popup(Language.translate("Reliktschrein"), text)
	for id: String in run.relic_offers:
		var info: Dictionary = GambaRun.relic_data(id)
		var cost: int = GambaRun.relic_cost(id)
		var label: String = Language.translate("1 Marke") if cost == 1 else Language.translate("%d Marken") % cost
		var button: Button = _add_popup_card(load(String(info.icon)), Language.translate(String(info.name)),
				Language.translate(String(info.text)), label, _on_shrine_relic.bind(id))
		button.disabled = not run.can_buy_relic(id)
	%PopupScroll.show()
	var any: bool = false
	for sword: GambaSword in run.swords:
		if run.can_deposit(sword):
			any = true
			%PopupList.add_child(_sword_card(sword, Language.translate("Einzahlen"), _on_deposit.bind(sword.id), "", Callable()))
	if not any:
		var empty := Label.new()
		empty.text = Language.translate("Kein Schwert ab %s auf der Werkbank.") % min_level
		empty.modulate = Color(1, 1, 1, 0.6)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		%PopupList.add_child(empty)
	_add_popup_button(Language.translate("Schließen"), _close_popup)


func _on_deposit(id: int) -> void:
	if run.deposit_sword(run.find_sword(id)):
		AudioManager.play_sound("coins", 0.8)
	_close_popup()
	_refresh_all()
	open_shrine()


func _on_shrine_relic(id: String) -> void:
	if not run.can_buy_relic(id):
		return
	if run.relics.size() >= run.relic_slots():
		_pending_relic = id
		_show_drop_choice()
		return
	_buy_shrine_relic(id, "")


func _buy_shrine_relic(id: String, drop: String) -> void:
	if run.buy_relic(id, drop):
		AudioManager.play_sound("item_reveal")
	_pending_relic = ""
	_close_popup()
	_refresh_all()
	open_shrine()


## All slots full: which old relic goes for the new one from the shrine?
func _show_drop_choice() -> void:
	_open_popup(Language.translate("Welches Relikt legst du ab?"), "")
	for id: String in run.relics:
		var info: Dictionary = GambaRun.relic_data(id)
		_add_popup_card(load(String(info.icon)), Language.translate(String(info.name)), Language.translate(String(info.text)),
				Language.translate("Ablegen"), _on_drop_picked.bind(id))
	_add_popup_button(Language.translate("Zurück"), _on_drop_cancelled)


func _on_drop_picked(drop: String) -> void:
	_buy_shrine_relic(_pending_relic, drop)


func _on_drop_cancelled() -> void:
	_pending_relic = ""
	_close_popup()
	open_shrine()


func _show_shop() -> void:
	_open_popup(Language.translate("Der Händler ist da"), Language.translate("Du hast %s Gold.") % GambaRun.format_gold(run.gold))
	for index in run.shop.size():
		var entry: Dictionary = run.shop[index]
		var icon: Texture2D = null
		var title: String = ""
		var text: String = ""
		match String(entry.kind):
			"sword":
				icon = load(String(GambaRun.material_data(String(entry.id)).get("blade", "")))
				title = Language.translate(String(GambaRun.material_data(String(entry.id)).get("name", "")))
				text = Language.translate("Startwert %s") % GambaRun.format_gold(run.value_at(String(entry.id), 0))
			"consumable":
				var good: Dictionary = GambaRun.consumable_data(String(entry.id))
				icon = load(String(good.icon))
				title = Language.translate(String(good.name))
				text = Language.translate(String(good.text))
		var label: String = Language.translate("Verkauft") if bool(entry.sold) else GambaRun.format_gold(int(entry.price))
		var button: Button = _add_popup_card(icon, title, text, label, _on_buy.bind(index))
		button.disabled = bool(entry.sold) or run.gold < int(entry.price)
	_add_popup_button(Language.translate("Weiter"), _on_shop_closed)


func _on_buy(index: int) -> void:
	if run.buy(index):
		AudioManager.play_sound("coins")
	_refresh_all()
	_show_shop()


func _on_shop_closed() -> void:
	run.close_shop()
	GambaSaves.write(run)
	_refresh_all()
	_show_next_popup()


func _show_result() -> void:
	var title: String = Language.translate("Vertrag erfüllt! Die Schmiede gehört dir.") if run.won \
			else Language.translate("Die Zunft schließt deine Schmiede.")
	var text: String = "\n".join([
			Language.translate("Tage: %d von %d") % [run.day, run.contract_days()],
			Language.translate("Gold verdient: %s") % GambaRun.format_gold(run.total_gold),
			Language.translate("Wertvollstes Schwert: %s") % GambaRun.format_gold(run.best_value),
			Language.translate("Zerbrochene Schwerter: %d") % run.swords_broken])
	if run.won:
		AudioManager.play_sound("achievement")
	_open_popup(title, text)
	_add_popup_button(Language.translate("Neuer Run"), _on_new_run)
	_add_popup_button(Language.translate("Hauptmenü"), _to_main_menu)


func _on_new_run() -> void:
	_close_popup()
	start_new_run()


func _give_up() -> void:
	run.ended = true
	run.won = false
	run.take_off_anvil()
	GambaSaves.delete()
	_refresh_all()
	_show_result()


func _to_main_menu() -> void:
	get_tree().paused = false
	MainMenu.skip_title_page = true
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)


# --- Popup --------------------------------------------------------------------------------------

func _open_popup(title: String, text: String) -> void:
	_clear(%PopupItems)
	_clear(%PopupButtons)
	_clear(%PopupList)
	%PopupScroll.hide()
	%PopupTitle.text = title
	%PopupText.text = text
	%PopupText.visible = not text.is_empty()
	%Dim.show()
	_popup.show()
	_center_popup.call_deferred()


## Fits the window to its content and puts it in the middle of the screen. If it would be taller
## than the screen (e.g. 5 relic cards in two rows), the cards scroll instead.
func _center_popup() -> void:
	_popup_fit += 1
	var fit: int = _popup_fit
	var scroll: ScrollContainer = %PopupItemsScroll
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 0.0
	scroll.scroll_vertical = 0
	# The card texts wrap only once the layout has run: measure one frame later, hidden until then.
	_popup.modulate.a = 0.0
	_popup.reset_size()
	await get_tree().process_frame
	if fit != _popup_fit or not is_inside_tree():
		return
	_popup.modulate.a = 1.0
	_popup.reset_size()
	var room: float = _popup.get_parent_area_size().y - 2.0 * POPUP_MARGIN
	if _popup.size.y > room:
		var height: float = maxf(scroll.size.y - (_popup.size.y - room), POPUP_MIN_ITEMS_HEIGHT)
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.custom_minimum_size.y = height
		_popup.reset_size()
	_popup.position = ((_popup.get_parent_area_size() - _popup.size) / 2.0).floor()


func _close_popup() -> void:
	_popup.hide()
	%Dim.hide()


func _add_popup_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	%PopupButtons.add_child(button)
	return button


## A card in the popup: icon, name, text and a button. Returns the button.
func _add_popup_card(icon: Texture2D, title: String, text: String, button_text: String, action: Callable) -> Button:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style)
	card.custom_minimum_size = Vector2(90, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = Vector2(32, 32)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.add_child(picture)
	var name_label := Label.new()
	name_label.text = title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 0.86, 0.55))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)
	var info := Label.new()
	info.text = text
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(info)
	var button := Button.new()
	button.text = button_text
	button.pressed.connect(action)
	box.add_child(button)
	%PopupItems.add_child(card)
	return button


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


# --- Showing the state --------------------------------------------------------------------------

func _refresh_all() -> void:
	_refresh_top()
	_refresh_lists()
	_refresh_anvil()
	_refresh_bars()


func _refresh_top() -> void:
	%DayLabel.text = Language.translate("Tag %d / %d") % [run.day, run.contract_days()]
	%GoldLabel.text = GambaRun.format_gold(run.gold)
	%FailLabel.text = Language.translate("Fehlschläge %d/%d") % [run.failures, run.max_failures()]
	%FailLabel.add_theme_color_override("font_color", BAD_COLOR if run.failures > 0 else Color.WHITE)
	var every: int = maxi(1, int(GambaRun.data().get("merchant_every", 3)))
	var days_left: int = every - ((run.day - 1) % every)
	%MerchantLabel.text = Language.translate("Händler morgen") if days_left == 1 \
			else Language.translate("Händler in %d Tagen") % days_left
	%ShrineButton.text = Language.translate("Reliktschrein") + " (%d)" % run.coins
	%ShrineButton.tooltip_text = Language.translate("Zunftmarken: %d") % run.coins
	%ShrineButton.disabled = _heating or run.ended
	var demand: int = run.demand()
	var offered: int = run.offered_value()
	%DemandLabel.text = Language.translate("Verlangt: %s") % GambaRun.format_gold(demand)
	%OfferedLabel.text = Language.translate("Auf dem Tisch: %s") % GambaRun.format_gold(offered)
	%OfferedLabel.add_theme_color_override("font_color", GOOD_COLOR if offered >= demand else BAD_COLOR)


func _refresh_lists() -> void:
	_clear(%BenchList)
	_clear(%TableList)
	var on_bench: int = 0
	for sword: GambaSword in run.swords:
		if sword == run.anvil:
			continue
		if sword.offered:
			%TableList.add_child(_sword_card(sword, Language.translate("Zurück"), _on_unoffer.bind(sword.id), "", Callable()))
		else:
			on_bench += 1
			%BenchList.add_child(_sword_card(sword, Language.translate("Schmieden"), _on_forge.bind(sword.id),
					Language.translate("Abgeben"), _on_offer.bind(sword.id)))
	if on_bench == 0:
		var empty := Label.new()
		empty.text = Language.translate("Keine Schwerter mehr.")
		empty.modulate = Color(1, 1, 1, 0.6)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		%BenchList.add_child(empty)


func _sword_card(sword: GambaSword, first: String, first_action: Callable, second: String, second_action: Callable) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	card.add_child(row)
	row.add_child(_sword_icon(sword))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	row.add_child(box)
	var title := Label.new()
	title.text = "%s %s" % [GambaRun.level_short(sword.level), GambaRun.sword_name(sword)]
	title.add_theme_color_override("font_color", GambaRun.level_color(sword.level))
	title.clip_text = true
	box.add_child(title)
	var value := Label.new()
	value.text = Language.translate("Wert %s") % GambaRun.format_gold(run.sword_value(sword))
	if sword.strikes > 0:
		value.text += "  ·  " + Language.translate("Bruch %s %%") % DamageKinds.format_number(run.chances(sword)["break"] * 100.0)
	value.add_theme_font_size_override("font_size", 10)
	box.add_child(value)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 2)
	box.add_child(buttons)
	for pair: Array in [[first, first_action], [second, second_action]]:
		if String(pair[0]).is_empty():
			continue
		var button := Button.new()
		button.text = String(pair[0])
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(pair[1])
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = _heating
		buttons.add_child(button)
	return card


## Handle under blade, both 24x24 on the same canvas.
func _sword_icon(sword: GambaSword) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = ICON_SIZE
	var info: Dictionary = GambaRun.material_data(sword.material)
	for key: String in ["handle", "blade"]:
		var part := TextureRect.new()
		part.texture = load(String(info.get(key, "")))
		part.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		part.size = ICON_SIZE
		holder.add_child(part)
	return holder


func _set_sword_sprites(holder: Node2D, sword: GambaSword) -> void:
	var info: Dictionary = GambaRun.material_data(sword.material)
	(holder.get_node("Handle") as Sprite2D).texture = load(String(info.get("handle", "")))
	(holder.get_node("Blade") as Sprite2D).texture = load(String(info.get("blade", "")))


func _on_forge(id: int) -> void:
	forge_sword(run.find_sword(id))


func _on_offer(id: int) -> void:
	run.set_offered(run.find_sword(id), true)
	AudioManager.play_sound("coins", 1.3)
	_refresh_all()


func _on_unoffer(id: int) -> void:
	run.set_offered(run.find_sword(id), false)
	_refresh_all()


func _refresh_anvil() -> void:
	var sword: GambaSword = run.anvil
	_anvil_sword.visible = sword != null
	_anvil_glow.visible = sword != null
	%StrikeButton.disabled = sword == null
	%TakeOffButton.disabled = sword == null
	%WardButton.disabled = not run.can_use_ward()
	%UndoButton.disabled = not run.can_undo()
	if sword == null:
		%AnvilInfo.text = ""
		%Hint.text = Language.translate("Wähle links ein Schwert: Schmieden. Fertige Schwerter: Abgeben.") if not run.ended else ""
		%StrikeInfo.text = Language.translate("Kein Schwert auf dem Amboss")
		var nothing: Dictionary[String, float] = {}
		_buckets.set_chances(nothing, false)
		return
	_set_sword_sprites(_anvil_sword, sword)
	_anvil_sword.modulate = HOT_TINT
	%AnvilInfo.text = "%s %s  ·  %s" % [GambaRun.level_short(sword.level), GambaRun.sword_name(sword), GambaRun.format_gold(run.sword_value(sword))]
	%AnvilInfo.add_theme_color_override("font_color", GambaRun.level_color(sword.level))
	%AnvilInfo.tooltip_text = GambaRun.level_name(sword.level)
	if run.in_frenzy():
		%Hint.text = Language.translate("RASEREI! Nichts kann brechen. Schlag zu!")
		%StrikeInfo.text = Language.translate("Raserei")
	else:
		%Hint.text = Language.translate("Klick ins Bild oder Leertaste: Schlagen.")
		var until: int = run.frenzy_limit() - sword.frenzy_strikes
		%StrikeInfo.text = Language.translate("Schläge %d  ·  Raserei in %d") % [sword.strikes, until]
		if run.ward_active:
			%StrikeInfo.text += "  ·  " + Language.translate("Schutzrune aktiv")
	_buckets.set_chances(run.chances(sword), run.in_frenzy() or run.ward_active)


func _refresh_bars() -> void:
	_clear(%RelicBar)
	for id: String in run.relics:
		var info: Dictionary = GambaRun.relic_data(id)
		var icon := TextureRect.new()
		icon.texture = load(String(info.icon))
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = ICON_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = "%s\n%s" % [Language.translate(String(info.name)), Language.translate(String(info.text))]
		%RelicBar.add_child(icon)
	for i in run.relic_slots() - run.relics.size():
		var slot := Panel.new()
		slot.custom_minimum_size = ICON_SIZE
		slot.modulate = Color(1, 1, 1, 0.35)
		slot.tooltip_text = Language.translate("Freier Relikt-Platz")
		%RelicBar.add_child(slot)
	_clear(%ConsumableBar)
	for id: String in run.consumables:
		var info: Dictionary = GambaRun.consumable_data(id)
		var icon := TextureRect.new()
		icon.texture = load(String(info.icon))
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = ICON_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = "%s ×%d\n%s" % [Language.translate(String(info.name)), run.consumables[id], Language.translate(String(info.text))]
		%ConsumableBar.add_child(icon)
	var wards: int = run.consumables.get("ward", 0)
	var glasses: int = run.consumables.get("hourglass", 0)
	%WardButton.text = Language.translate("Schutzrune") + " ×%d" % wards
	%WardButton.tooltip_text = Language.translate(String(GambaRun.consumable_data("ward").get("text", "")))
	%WardButton.visible = wards > 0 or run.ward_active
	%UndoButton.text = Language.translate("Stundenglas") + " ×%d" % glasses
	%UndoButton.tooltip_text = Language.translate(String(GambaRun.consumable_data("hourglass").get("text", "")))
	%UndoButton.visible = glasses > 0


# --- Effects (only pictures) --------------------------------------------------------------------

func _build_effects() -> void:
	_forge_glow = _light(FORGE_LIGHT, Vector2i(220, 160), Color(1.0, 0.55, 0.25))
	$World.add_child(_forge_glow)
	$World.move_child(_forge_glow, _fire.get_index() + 1)
	_anvil_glow = _light(ANVIL_TOP, Vector2i(70, 40), Color(1.0, 0.5, 0.2, 0.7))
	$World.add_child(_anvil_glow)
	$World.move_child(_anvil_glow, _anvil_sword.get_index())
	_sparks = _particles(Color(1, 0.95, 0.6), Color(1, 0.6, 0.2), 24)
	_shards = _particles(Color(0.85, 0.85, 0.9), Color(0.5, 0.5, 0.55), 30)
	_shards.initial_velocity_max = 150.0
	_shards.lifetime = 1.0


func _particles(first: Color, second: Color, amount: int) -> CPUParticles2D:
	var sparks := CPUParticles2D.new()
	sparks.position = ANVIL_TOP + Vector2(0, -4)
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = amount
	sparks.lifetime = 0.6
	sparks.explosiveness = 1.0
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(10, 1)
	sparks.direction = Vector2.UP
	sparks.spread = 85.0
	sparks.initial_velocity_min = 50.0
	sparks.initial_velocity_max = 120.0
	sparks.gravity = Vector2(0, 260)
	var tint := Gradient.new()
	tint.colors = PackedColorArray([first, second])
	sparks.color_initial_ramp = tint
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	sparks.color_ramp = fade
	$World.add_child(sparks)
	return sparks


func _light(at: Vector2, area: Vector2i, color: Color) -> Sprite2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = area.x
	texture.height = area.y
	var light := Sprite2D.new()
	light.texture = texture
	light.position = at
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light.material = add
	return light


func _swing_hammer() -> void:
	if _hammer_tween != null and _hammer_tween.is_valid():
		_hammer_tween.kill()
	_hammer.visible = true
	_hammer.rotation_degrees = HAMMER_RAISED
	_hammer_tween = create_tween()
	_hammer_tween.tween_property(_hammer, "rotation_degrees", 0.0, 0.05).set_ease(Tween.EASE_IN)
	_hammer_tween.tween_property(_hammer, "rotation_degrees", HAMMER_RAISED, 0.12).set_ease(Tween.EASE_OUT)
	_hammer_tween.tween_interval(0.6)
	_hammer_tween.tween_property(_hammer, "rotation_degrees", HAMMER_REST, 0.25)
	_hammer_tween.tween_callback(_hammer.hide)


## A word rising from the anvil and fading.
func _float_text(text: String, color: Color, size_factor: float, rise_from: float = 0.0) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(14 * size_factor))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$World.add_child(label)
	label.reset_size()
	label.position = ANVIL_TOP + Vector2(-label.size.x / 2.0, -30.0 + rise_from)
	var rise := create_tween()
	rise.tween_property(label, "position:y", label.position.y - 26.0, 0.8).set_ease(Tween.EASE_OUT)
	rise.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.35)
	rise.tween_callback(label.queue_free)
