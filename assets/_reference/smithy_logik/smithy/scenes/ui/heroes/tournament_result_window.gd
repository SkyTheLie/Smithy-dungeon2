class_name TournamentResultWindow
extends CanvasLayer
## Result of a league tournament in the arena (ArenaFightStage, after the last fight): the place in
## big letters in the colours of the place (1 gold, glowing, with confetti; 2 silver; 3 bronze;
## further back plain grey), league and hero, the RP won and the rewards (gold and items as slots,
## title, trophy). Only shows what TournamentRanking.last_result says. If the winner has a prize to
## pick ("prize", TournamentRewards: 3 cards, molds and gifts), one card per choice; a click claims
## it (TournamentRanking.claim_entry), a gift opens and shows what was inside, the gifts not taken
## open too (dimmed, TournamentRanking.last_gift_contents). "Weiter" only works
## once picked, then closes the window (closed).
## The story tournaments (great smith tournament, Kahn's tournament) use it too: their result has a
## "name" instead of a league and no rank points (SmithTournament / HeroTournament.story_result).

signal closed

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const ICON_GOLD: Texture2D = preload("res://assets/ui/icon_coin.png")
const ICON_GIFT: Texture2D = preload("res://assets/sprites/ui/gift.png")
## Size of a prize card.
const CARD_SIZE: Vector2 = Vector2(72, 54)
## Look per place: frame background, frame border, colour of the place, colour it glows towards
## (same = no glow), heading above it (German key).
const LOOKS: Dictionary = {
	1: {"bg": Color(0.26, 0.18, 0.04, 0.97), "border": Color(1.0, 0.82, 0.3), "text": Color(1.0, 0.86, 0.35),
			"glow": Color(1.0, 0.98, 0.75), "heading": "Turniersieg!"},
	2: {"bg": Color(0.16, 0.18, 0.22, 0.97), "border": Color(0.8, 0.84, 0.9), "text": Color(0.86, 0.9, 0.96),
			"glow": Color(1.0, 1.0, 1.0), "heading": "Zweiter Platz"},
	3: {"bg": Color(0.17, 0.11, 0.07, 0.97), "border": Color(0.6, 0.38, 0.22), "text": Color(0.72, 0.47, 0.28),
			"glow": Color(0.72, 0.47, 0.28), "heading": "Dritter Platz"},
}
const LOOK_OUT: Dictionary = {"bg": Color(0.13, 0.12, 0.12, 0.97), "border": Color(0.35, 0.34, 0.33), "text": Color(0.55, 0.53, 0.5),
		"glow": Color(0.55, 0.53, 0.5), "heading": "Ausgeschieden"}
const CONFETTI_COLORS: Array[Color] = [Color(1.0, 0.84, 0.3), Color(0.95, 0.35, 0.3), Color(0.4, 0.7, 1.0),
		Color(0.5, 0.9, 0.45), Color(0.85, 0.5, 1.0), Color(1, 1, 1)]

@onready var _frame: PanelContainer = %Frame
@onready var _crown_label: Label = %CrownLabel
@onready var _place_label: Label = %PlaceLabel
@onready var _league_label: Label = %LeagueLabel
@onready var _hero_label: Label = %HeroLabel
@onready var _line: ColorRect = %Line
@onready var _points_label: Label = %PointsLabel
@onready var _rewards: HBoxContainer = %Rewards
@onready var _extras_label: Label = %ExtrasLabel
@onready var _choice_label: Label = %ChoiceLabel
@onready var _choices: HBoxContainer = %Choices
@onready var _picked_label: Label = %PickedLabel
@onready var _continue_button: Button = %ContinueButton

## The pending prize of this result ({} = none to pick).
var _prize: Dictionary = {}


func _ready() -> void:
	%ContinueButton.pressed.connect(_on_continue)


## Shows `result` (TournamentRanking.last_result) for `hero` (null = a smith league: the player's name).
func show_result(result: Dictionary, hero: Hero) -> void:
	var place: int = int(result.get("place", 0))
	var look: Dictionary = LOOKS.get(place, LOOK_OUT)
	var style: StyleBoxFlat = (_frame.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = look["bg"]
	style.border_color = look["border"]
	_frame.add_theme_stylebox_override("panel", style)
	_crown_label.text = Language.translate(str(look["heading"]))
	_crown_label.add_theme_color_override("font_color", look["border"])
	_place_label.text = Language.translate("Platz %d") % place
	# White letters, the colour comes from self_modulate (so it can glow).
	_place_label.add_theme_color_override("font_color", Color.WHITE)
	_place_label.self_modulate = look["text"]
	_line.color = Color(look["border"], 0.5)
	_league_label.text = str(result["name"]) if result.has("name") else TournamentRanking.league_name(int(result.get("league", 0)))
	_league_label.add_theme_color_override("font_color", Color(look["text"], 0.85))
	_hero_label.text = hero.display_name if hero else GameState.get_player_name()
	_hero_label.add_theme_color_override("font_color", HeroTournamentMenu.class_color(hero))
	var points: int = int(result.get("points", 0))
	_points_label.text = Language.translate("+%d RP") % points if points > 0 else Language.translate("Keine Rangpunkte")
	# Story tournaments have no ranks.
	_points_label.visible = not result.has("name")
	var rank_up: String = str(result.get("rank_up", ""))
	if not rank_up.is_empty():
		_points_label.text += "\n" + rank_up
	_build_rewards(result)
	var extras: Array[String] = []
	if not str(result.get("title", "")).is_empty():
		extras.append(Language.translate("Neuer Titel: %s") % str(result["title"]))
	if not str(result.get("trophy", "")).is_empty():
		extras.append(Language.translate("Pokal: %s (im Lager)") % str(result["trophy"]))
	if not str(result.get("sign_theme", "")).is_empty():
		extras.append(Language.translate("Neues Schild-Thema: %s") % str(result["sign_theme"]))
	if int(result.get("marks", 0)) > 0:
		extras.append(Language.translate("+%d Turnier-Marken (beim Turnier-Händler eintauschen)") % int(result["marks"]))
	if not str(result.get("room_theme", "")).is_empty():
		extras.append(Language.translate("Neues Schmiede-Thema: %s") % str(result["room_theme"]))
	_extras_label.text = "\n".join(extras)
	_extras_label.visible = not extras.is_empty()
	if not (look["glow"] as Color).is_equal_approx(look["text"]):
		var tween: Tween = create_tween().set_loops()
		tween.tween_property(_place_label, "self_modulate", look["glow"], 0.6)
		tween.tween_property(_place_label, "self_modulate", look["text"], 0.6)
	if place == 1:
		_add_confetti()
	_build_choices(result.get("prize", {}))
	show()


## Gold and items as slots (only shown, tooltips like everywhere).
func _build_rewards(result: Dictionary) -> void:
	for child in _rewards.get_children():
		child.queue_free()
	var gold: int = int(result.get("gold", 0))
	if gold > 0:
		var gold_slot: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_rewards.add_child(gold_slot)
		gold_slot.display_custom(ICON_GOLD, Language.translate("%d Gold") % gold, DamageKinds.format_number(gold))
	for spec: String in result.get("items", []):
		var stack: InventorySlot = ContentDB.make_stack(spec)
		if stack == null:
			continue
		var slot: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_rewards.add_child(slot)
		slot.display(stack)
	_rewards.visible = _rewards.get_child_count() > 0


## One card per choice of the pending prize (mold: picture and name of the part; gift: the gift).
## Nothing to pick: no cards, "Weiter" works right away.
func _build_choices(prize: Dictionary) -> void:
	_prize = prize if GameState.ranking.get_pending().has(prize) else {}
	var choices: Array = _prize.get("choices", [])
	_choice_label.visible = not choices.is_empty()
	_choices.visible = not choices.is_empty()
	_continue_button.disabled = not choices.is_empty()
	for index in choices.size():
		var entry: String = str(choices[index])
		var card := Button.new()
		card.focus_mode = Control.FOCUS_NONE
		card.custom_minimum_size = CARD_SIZE
		card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.tooltip_text = TournamentRanking.describe_prize(entry)
		if entry.begins_with(TournamentRewards.SURPRISE + ":"):
			card.icon = ICON_GIFT
			card.text = Language.translate("Überraschung")
		elif not entry.begins_with("mold:"):
			# Older saves: gold, items or a forge theme still pending from the smith prize pool.
			card.icon = _prize_icon(entry)
			card.text = TournamentRanking.describe_prize(entry)
		else:
			var part: ItemData = ContentDB.recipe(entry.get_slice(":", 1)).get_mold_part() if ContentDB.has_recipe(entry.get_slice(":", 1)) else null
			var stack: InventorySlot = ContentDB.make_stack(String(part.id)) if part else null
			card.icon = stack.get_icon() if stack else null
			card.text = part.display_name if part else entry
		card.pressed.connect(_on_choice_pressed.bind(index))
		_choices.add_child(card)


## Picture of a prize card that is no mold: gold, the first item, nothing for a theme.
func _prize_icon(entry: String) -> Texture2D:
	match entry.get_slice(":", 0):
		"gold":
			return ICON_GOLD
		"items":
			var stack: InventorySlot = ContentDB.make_stack(entry.get_slice(":", 1).get_slice(",", 0))
			return stack.get_icon() if stack else null
	return null


func _on_choice_pressed(index: int) -> void:
	var text: String = GameState.ranking.claim_entry(_prize, index)
	if text.is_empty():
		return
	AudioManager.play_sound("coins")
	var entry: String = str((_prize.get("choices", []) as Array)[index])
	var chosen: Button = _choices.get_child(index)
	for card_index in _choices.get_child_count():
		var card: Button = _choices.get_child(card_index)
		if card == chosen:
			# Stays bright, but does nothing any more.
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif GameState.ranking.last_gift_contents.has(card_index):
			# A gift not taken: it opens too, so the player sees what was inside.
			_show_gift_contents(card, GameState.ranking.last_gift_contents[card_index])
			card.disabled = true
			card.modulate = Color(1, 1, 1, 0.55)
		else:
			card.disabled = true
			card.modulate = Color(1, 1, 1, 0.3)
	if entry.begins_with(TournamentRewards.SURPRISE + ":"):
		# The gift opens: the item that was inside instead of the box, and as a slot next to it
		# (rarity frame, tooltip).
		var given: Array[InventorySlot] = GameState.ranking.last_surprise
		var gift_gold: int = GameState.ranking.last_surprise_gold
		if gift_gold > 0:
			chosen.icon = ICON_GOLD
			chosen.text = Language.translate("%s Gold") % DamageKinds.format_number(gift_gold)
			var gold_slot: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
			gold_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_choices.add_child(gold_slot)
			_choices.move_child(gold_slot, chosen.get_index() + 1)
			gold_slot.display_custom(ICON_GOLD, Language.translate("%s Gold") % DamageKinds.format_number(gift_gold), DamageKinds.format_number(gift_gold))
		elif not given.is_empty():
			chosen.icon = given[0].get_icon()
			chosen.text = given[0].get_display_name()
		for stack in given:
			var slot: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
			slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_choices.add_child(slot)
			_choices.move_child(slot, chosen.get_index() + 1)
			slot.display(stack)
		chosen.pivot_offset = chosen.size / 2.0
		var pop: Tween = create_tween()
		pop.tween_property(chosen, "scale", Vector2(1.15, 1.15), 0.12)
		pop.tween_property(chosen, "scale", Vector2.ONE, 0.12)
	_choice_label.text = Language.translate("Dein Siegerpreis")
	_picked_label.text = text
	_picked_label.show()
	_continue_button.disabled = false


## A gift card shows what was inside (`spec`: give_items spec or "gold:<amount>"): picture and name
## of the first item or the gold, everything in the tooltip.
func _show_gift_contents(card: Button, spec: String) -> void:
	var gold: int = TournamentRewards.gold_of(spec)
	var stacks: Array[InventorySlot] = TournamentRanking.gift_stacks(spec)
	if gold > 0:
		card.icon = ICON_GOLD
		card.text = Language.translate("%s Gold") % DamageKinds.format_number(gold)
	elif not stacks.is_empty():
		card.icon = stacks[0].get_icon()
		card.text = ("%d× " % stacks[0].amount if stacks[0].amount > 1 else "") + stacks[0].get_display_name()
	card.tooltip_text = TournamentRanking.describe_gift(spec)


## Confetti falling over the window (place 1).
func _add_confetti() -> void:
	# The frame has its size once the layout ran.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	for side in [-1.0, 1.0]:
		var confetti := CPUParticles2D.new()
		confetti.position = _frame.size * Vector2(0.5 + 0.3 * side, 0.0)
		confetti.amount = 40
		confetti.lifetime = 2.2
		confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		confetti.emission_rect_extents = Vector2(_frame.size.x * 0.25, 2)
		confetti.direction = Vector2(-side * 0.3, -1)
		confetti.spread = 50.0
		confetti.initial_velocity_min = 50.0
		confetti.initial_velocity_max = 110.0
		confetti.gravity = Vector2(0, 110)
		confetti.angular_velocity_min = -200.0
		confetti.angular_velocity_max = 200.0
		confetti.scale_amount_min = 1.5
		confetti.scale_amount_max = 2.5
		confetti.color_initial_ramp = confetti_colors()
		_frame.add_child(confetti)


## The colours confetti picks from (also for the confetti in the ring, ArenaFightStage).
static func confetti_colors() -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array()
	ramp.colors = PackedColorArray()
	for index in CONFETTI_COLORS.size():
		ramp.add_point(float(index) / (CONFETTI_COLORS.size() - 1), CONFETTI_COLORS[index])
	return ramp


func _on_continue() -> void:
	hide()
	closed.emit()
	queue_free()
