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
## Enemy id of the leader waiting here (floors.json "mini_boss"), "" = none.
var leader: String = ""
var rocks: Array[Rock] = []
## Crates, barrels … that break (RoomProps, Dungeon.break_prop).
var breakables: Array[BreakableProp] = []
## Pedestals and pickups in the room (for the map).
var loot: Array[Node3D] = []
## Chests (data/chests.json; Dungeon opens them).
var chests: Array[Chest] = []
## Stone chamber: radius of its outer ring of rocks around the middle (0 = none), kept free of
## spawning enemies and other things.
var chamber_radius: float = 0.0
## Traps on the floor (lava, poison, spikes; Dungeon checks them).
var hazards: Array[Hazard] = []
## Drops this room still gives from normal enemies and its reward (data/loot.json room_budget;
## -1 = not counted yet, Dungeon sets it the first time).
var drops_left: int = -1


func remove_rock(rock: Rock) -> void:
	rocks.erase(rock)
