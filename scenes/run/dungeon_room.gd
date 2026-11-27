class_name DungeonRoom
extends Node3D
## One room of a floor (built by Dungeon): knows its cell and type, which enemies wait in it and
## whether the player was here and beat it.

var cell: Vector2i = Vector2i.ZERO
## FloorLayout type: start, normal, item, shop, boss.
var type: String = FloorLayout.NORMAL
var visited: bool = false
var cleared: bool = false
## Enemy ids that appear when the player enters (rolled when the floor is built).
var spawn_list: Array[String] = []
var rocks: Array[Rock] = []
## Pedestals and pickups in the room (for the map).
var loot: Array[Node3D] = []
## Traps on the floor (lava, poison, spikes; Dungeon checks them).
var hazards: Array[Hazard] = []


func remove_rock(rock: Rock) -> void:
	rocks.erase(rock)
