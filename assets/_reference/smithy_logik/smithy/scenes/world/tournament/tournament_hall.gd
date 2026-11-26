class_name TournamentHall
extends Node2D
## A tournament hall (scenes/world/tournament/tournament_hall_<city>.tscn, all inherit
## tournament_hall.tscn): the reception of the league tournaments of a city. The tournament
## master at the desk (TournamentDeskMenu, its `venue` = the city's key in economy.json
## "smith_tournament" "venues", "" = Leonheim) registers the player and brings him into the arena
## of the city (leagues.json "venues" "arena", spawn point FROM_HALL); when the tournament is over
## the herald there sends him back here (spawn point FROM_ARENA). The way out (DoorOut) leads into
## the city, the tournament messenger of the city brings him here (spawn point FromCity).

## Spawn point in the arena when coming from the hall.
const FROM_HALL: StringName = &"FromHall"
## Spawn point in the hall when coming back from the arena.
const FROM_ARENA: StringName = &"FromArena"
