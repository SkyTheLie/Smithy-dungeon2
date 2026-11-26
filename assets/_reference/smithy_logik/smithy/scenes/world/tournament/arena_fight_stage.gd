class_name ArenaFightStage
extends Node2D
## The ring of an arena hall (ArenaHall; DuelRing in leonheim_ring, sahrim_ring, finster_ring). The
## arena keeper in the hall sends the player here before every fight of his hero
## (HeroTournament.request_arena_fight): the player is hidden (locked) and so is the HUD except the
## battle window (HUD.show_battle_window_only). The screen above the ring is an ArenaOverlay: two
## boards ("Held" top left, "Gegner" top right, each with the fighter's equipment), the button
## "Ausrüstung" on the right that shows them again at any time, and the announcement in a box at
## the bottom. Both fighters walk in from the left and right edge, the round is announced (the box
## stays until the round is over), then the boards go and the fight runs in the battle window
## (the button brings them back over it). When it is over and the
## battle window is closed: after the last fight of a league tournament (won or out) the winner is
## celebrated (only if it is the player's hero: the opponent goes, the hero hops in the middle, the
## crowd hops, confetti) and the result window shows the place and the rewards
## (TournamentResultWindow, TournamentRanking.last_result); then the tournament is over (reset).
## The player goes back into the hall (spawn point HeroTournament.hall_spawn()), where the arena
## keeper's window opens by itself (HeroTournament.reopen_desk). The great tournament of Eisquell runs
## here too: at its end the same result window (place and prize, no ranks, HeroTournament.story_result);
## after the victory the window does not open in the hall, Kahn talks there.
## Coming here any other way (e.g. an old save in the ring): the ring stays empty, the door leads
## into the hall.

const OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/heroes/arena_overlay.tscn")
const RESULT_SCENE: PackedScene = preload("res://scenes/ui/heroes/tournament_result_window.tscn")
const TEXT_WINNER: String = "%s gewinnt die %s!"
## Seconds the winner is celebrated in the ring before the result window opens.
const CELEBRATE_SECONDS: float = 2.6
const LOCK_REASON: StringName = &"arena_fight"
const TEXT_ANNOUNCE: String = "%s! %s gegen %s!"
const TEXT_CANT_FIGHT: String = "Der Kampf kann gerade nicht beginnen."
## Seconds the heroes face each other (with the announcement) before the fight starts.
const FACE_SECONDS: float = 1.6
## Seconds before going back into the hall after the fight (when the battle window is closed).
const BACK_SECONDS: float = 1.0

## Where the player's hero and his opponent stand (local coordinates).
@export var player_spot: Vector2 = Vector2(-44, 0)
@export var opponent_spot: Vector2 = Vector2(44, 0)
## How far from their spots (to the left and right) the fighters start walking in.
@export var walk_in_distance: float = 230.0
## Walking speed of the fighters (px/s).
@export var walk_speed: float = 70.0

var _fighters: Array[AnimatedSprite2D] = []
var _overlay: ArenaOverlay
var _player: Player


func _ready() -> void:
	for spot: Vector2 in [player_spot, opponent_spot]:
		var sprite := AnimatedSprite2D.new()
		sprite.position = spot
		sprite.offset = Vector2(0, -13)
		sprite.visible = false
		add_child(sprite)
		_fighters.append(sprite)
	_overlay = OVERLAY_SCENE.instantiate()
	add_child(_overlay)
	var tournament: HeroTournament = GameState.hero_tournament
	tournament.fight_finished.connect(_on_fight_finished)
	if tournament.take_walk_in():
		_play.call_deferred()


## True while the walk-in or the fight of this visit runs (tests).
func is_busy() -> bool:
	return _player != null and _player.is_locked()


## The screen above the ring (boards, button, announcement).
func get_overlay() -> ArenaOverlay:
	return _overlay


func _play() -> void:
	var tournament: HeroTournament = GameState.hero_tournament
	var opponent: Dictionary = tournament.get_opponent()
	if tournament.player_hero == null or opponent.is_empty():
		_back_to_hall()
		return
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if _player:
		_player.lock(LOCK_REASON)
		# Only the heroes are on stage: the player is not shown (the camera stays with him).
		_player.visible = false
	_hide_hud()
	var heroes: Array[Hero] = [tournament.player_hero, opponent["hero"]]
	_overlay.show_fighters(heroes[0], heroes[1])
	var duration: float = walk_in_distance / maxf(1.0, walk_speed)
	var tween: Tween = create_tween().set_parallel(true)
	for index in _fighters.size():
		var sprite: AnimatedSprite2D = _fighters[index]
		var side: float = -1.0 if index == 0 else 1.0
		var spot: Vector2 = player_spot if index == 0 else opponent_spot
		sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(heroes[index].get_appearance()))
		sprite.position = spot + Vector2(side * walk_in_distance, 0)
		sprite.play(&"walk_right" if index == 0 else &"walk_left")
		sprite.show()
		tween.tween_property(sprite, "position", spot, duration)
	await tween.finished
	if not is_inside_tree():
		return
	_fighters[0].play(&"idle_right")
	_fighters[1].play(&"idle_left")
	# The announcement stays until the round is over (_on_fight_finished).
	_overlay.announce(Language.translate(TEXT_ANNOUNCE) % [tournament.get_round_title(),
			heroes[0].display_name, heroes[1].display_name])
	await get_tree().create_timer(FACE_SECONDS, false).timeout
	if not is_inside_tree():
		return
	# The battle window takes over; the button "Ausrüstung" brings the boards back over it.
	_overlay.set_boards_visible(false)
	_hide_hud()
	if tournament.start_fight() == null:
		GameState.show_message(Language.translate(TEXT_CANT_FIGHT))
		_back_to_hall()


func _on_fight_finished(_victory: bool, text: String) -> void:
	if _player == null:
		GameState.show_message(text)
		return
	_overlay.hide_announcement()
	await get_tree().create_timer(BACK_SECONDS, false).timeout
	if not is_inside_tree():
		return
	var window := get_tree().get_first_node_in_group(BattleWindow.GROUP) as Control
	while window and window.is_visible_in_tree():
		await window.visibility_changed
		if not is_inside_tree():
			return
	var tournament: HeroTournament = GameState.hero_tournament
	# After winning the great tournament the story goes on in the hall (Kahn talks): no window there.
	var reopen: bool = not (tournament.state == HeroTournament.State.WON and not HeroTournament.is_league())
	if tournament.is_over():
		# Leagues: place, RP and prizes; the great tournament (Eisquell): place and prize, no ranks.
		var result: Dictionary = GameState.ranking.last_result if HeroTournament.is_league() else tournament.story_result
		if not result.is_empty():
			_overlay.hide_all()
			if tournament.state == HeroTournament.State.WON:
				var line: String = text
				if HeroTournament.is_league():
					line = Language.translate(TEXT_WINNER) % [tournament.player_hero.display_name,
							TournamentRanking.league_name(HeroTournament.league)]
				await _celebrate(line)
				if not is_inside_tree():
					return
			var result_window: TournamentResultWindow = RESULT_SCENE.instantiate()
			add_child(result_window)
			result_window.show_result(result, tournament.player_hero)
			await result_window.closed
			if not is_inside_tree():
				return
		tournament.reset()
	tournament.reopen_desk = reopen
	_back_to_hall()


## The player's hero won the tournament: the opponent fades, the hero walks into the middle and
## hops, the crowd hops with him, confetti falls, `line` (already translated) names the winner.
func _celebrate(line: String) -> void:
	var hero_sprite: AnimatedSprite2D = _fighters[0]
	var rival_sprite: AnimatedSprite2D = _fighters[1]
	create_tween().tween_property(rival_sprite, "modulate:a", 0.0, 0.6)
	var walk: Tween = create_tween()
	hero_sprite.play(&"walk_right")
	walk.tween_property(hero_sprite, "position", Vector2.ZERO, absf(player_spot.x) / maxf(1.0, walk_speed))
	await walk.finished
	if not is_inside_tree():
		return
	hero_sprite.play(&"idle_down")
	_overlay.announce(line)
	ArenaCelebration.hop(hero_sprite, 4, 0.0)
	ArenaCelebration.cheer_crowd(get_parent())
	var confetti: CPUParticles2D = ArenaCelebration.make_confetti(360.0)
	confetti.position = Vector2(0, -120)
	add_child(confetti)
	await get_tree().create_timer(CELEBRATE_SECONDS, false).timeout


## Only the boards and the battle window: the HUD of the ring hides the rest (hotbar, gold,
## compass, side menu, tips). Called again when the fight starts (a tip may have come up).
func _hide_hud() -> void:
	var hud: Node = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("show_battle_window_only"):
		hud.show_battle_window_only()


func _back_to_hall() -> void:
	if _player:
		_player.unlock(LOCK_REASON)
	var hall: String = HeroTournament.hall_scene()
	if not hall.is_empty():
		GameState.travel_to(hall, HeroTournament.hall_spawn(), true)
