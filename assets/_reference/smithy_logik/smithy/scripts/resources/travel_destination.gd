class_name TravelDestination
extends Resource
## A place the teleport crystal can bring the player to. One .tres per place in res://data/destinations/.
## Only destinations whose id is in GameState.known_destinations are shown.

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export_file("*.tscn") var scene_path: String
## Spawn point (Marker2D in group "spawn_points") in that scene, normally next to its crystal.
@export var spawn_point: StringName = &"FromTeleporter"
