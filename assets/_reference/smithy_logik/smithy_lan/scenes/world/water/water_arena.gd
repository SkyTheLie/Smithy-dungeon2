class_name WaterArena
extends Node2D
## The tide arena of Eisquell, Kahn's hero tournament (HeroTournament). The crier opens the
## tournament window (story action "open_menu:hero_tournament"). Before each fight of the player's
## hero both heroes step into the ring and face each other while the crowd cheers, then the fight
## runs in the battle window. Between the rounds both stay in the ring.

## Seconds the heroes face each other before the fight starts.
const STEP_IN_SECONDS: float = 1.6
const TEXT_ANNOUNCE: String = "%s! %s gegen %s!"
const TEXT_CANT_FIGHT: String = "Der Kampf kann gerade nicht beginnen."

## Where the player's hero and his opponent stand (scene coordinates).
@export var player_spot: Vector2 = Vector2(-60, 10)
@export var opponent_spot: Vector2 = Vector2(60, 10)

var _fighters: Array[AnimatedSprite2D] = []
var _shown_heroes: Array[Hero] = [null, null]
var _label: Label

@onready var _menu: HeroTournamentMenu = $HeroTournamentMenu


func _ready() -> void:
	for spot: Vector2 in [player_spot, opponent_spot]:
		var sprite := AnimatedSprite2D.new()
		sprite.position = spot
		sprite.offset = Vector2(0, -13)
		sprite.visible = false
		add_child(sprite)
		_fighters.append(sprite)
	_label = Label.new()
	_label.position = Vector2(-120, -60)
	_label.size = Vector2(240, 14)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	_label.z_index = 10
	_label.hide()
	add_child(_label)
	Events.story_menu_requested.connect(_on_menu_requested)
	_menu.fight_requested.connect(_on_fight_requested)
	GameState.hero_tournament.changed.connect(_update_fighters)
	GameState.hero_tournament.fight_finished.connect(_on_fight_finished)
	_update_fighters()


func _on_menu_requested(menu: String) -> void:
	if menu == "hero_tournament":
		_menu.show()


## Both heroes stand in the ring while the tournament runs (the player's hero looks right).
func _update_fighters() -> void:
	var tournament: HeroTournament = GameState.hero_tournament
	var opponent: Dictionary = tournament.get_opponent() if tournament.is_running() else {}
	var heroes: Array = [tournament.player_hero if tournament.is_running() else null,
			opponent.get("hero") if not opponent.is_empty() else null]
	for i in _fighters.size():
		var hero: Hero = heroes[i]
		_fighters[i].visible = hero != null
		if hero == null or hero == _shown_heroes[i]:
			continue
		_shown_heroes[i] = hero
		_fighters[i].sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(hero.get_appearance()))
		_fighters[i].play(&"idle_right" if i == 0 else &"idle_left")


func _on_fight_requested() -> void:
	var tournament: HeroTournament = GameState.hero_tournament
	_update_fighters()
	var opponent: Dictionary = tournament.get_opponent()
	if tournament.player_hero and not opponent.is_empty():
		_label.text = TEXT_ANNOUNCE % [HeroTournament.round_name(tournament.round_index),
				tournament.player_hero.display_name, (opponent["hero"] as Hero).display_name]
		_label.show()
	await get_tree().create_timer(STEP_IN_SECONDS, false).timeout
	_label.hide()
	if tournament.start_fight() == null:
		GameState.show_message(Language.translate(TEXT_CANT_FIGHT))


func _on_fight_finished(_victory: bool, text: String) -> void:
	GameState.show_message(text)
