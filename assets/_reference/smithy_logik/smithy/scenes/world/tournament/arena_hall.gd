class_name ArenaHall
extends Node2D
## An arena hall (scenes/world/tournament/arena_hall_<city>.tscn, all inherit arena_hall.tscn): the
## entrance of the hero arena of a city. The arena keeper at the desk opens the tournament window
## (HeroTournamentMenu with the city's `venue` and the leaderboard): pick a hero and a league, see
## the bracket and the hero leaderboard. "Kampf beginnen" brings the player into the ring of the
## city (leagues.json "venues" "arena", spawn point TournamentHall.FROM_HALL), where both heroes
## walk in and fight (ArenaFightStage); afterwards he comes back here (TournamentHall.FROM_ARENA).
## The tournament messenger of the city brings him here (spawn point FromCity), the door leads out.
## Eisquell (Gezeitenhalle, arena_hall_eisquell): the crier of the story stands at the desk, his
## dialogue opens the window (story action "open_menu:hero_tournament").
## Sylvaris: no hall of its own, the node ArenaDesk in elf_canopy_low carries this script; the
## crier up in the canopy sends the fights down into the fighting glade (sylvaris_ring), back at
## the spawn point FromDuelRing (leagues.json "hall_spawn").

@onready var _menu: HeroTournamentMenu = $HeroTournamentMenu


func _ready() -> void:
	_menu.fight_requested.connect(_on_fight_requested)
	Events.story_menu_requested.connect(_on_story_menu_requested)
	# Back from the ring: the window opens by itself (next match, or after the end: register
	# again, leaderboard, close).
	# A tournament of this venue waiting for its next fight (e.g. after a scene change in between):
	# the window opens too, a tournament is only left by winning or losing.
	var tournament: HeroTournament = GameState.hero_tournament
	var waiting: bool = tournament.state == HeroTournament.State.READY and HeroTournament.venue == _menu.venue
	if tournament.take_reopen_desk() or waiting:
		_menu.show.call_deferred()


func _on_story_menu_requested(menu: String) -> void:
	if menu == "hero_tournament":
		_menu.show()


func _on_fight_requested() -> void:
	var arena: String = GameState.hero_tournament.request_arena_fight()
	if arena.is_empty():
		# No ring for this venue: the fight runs right away in the battle window.
		GameState.hero_tournament.start_fight()
		return
	GameState.travel_to(arena, TournamentHall.FROM_HALL, true)
