class_name VillagerSpot
extends Marker2D
## A place villagers go to and what they do there (see Villager): walk into a house (DOOR: they
## disappear for a while), sit on a bench (BENCH: one seat per spot), look at something (LOOK:
## flowers, a garden, a stall), talk (TALK: two spots facing each other, `partner` is the other
## one) or just stop a moment (STROLL). Only one villager uses a spot at a time.
## Villagers walk there along the VillageRoads: from the road point `road` straight to the spot.

enum Kind { STROLL, DOOR, BENCH, LOOK, TALK }

@export var kind: Kind = Kind.STROLL
## Direction the villager faces at the spot: "down", "up", "left" or "right".
@export_enum("down", "up", "left", "right") var facing: String = "down"
## Seconds spent at the spot (random in this range); inside a house for DOOR.
@export var duration: Vector2 = Vector2(4.0, 10.0)
## Road point (Marker2D in VillageRoads) from where the spot is reached in a straight line.
@export var road: Marker2D
## TALK only: the spot of the other talker.
@export var partner: VillagerSpot

## Villager using the spot right now (null = free).
var occupant: Node = null
