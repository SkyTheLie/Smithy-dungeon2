class_name DungeonExit
extends Node3D
## The way out of the dungeon, in a corner of every start room: a ladder up into daylight
## (a warm light from above, "Ausgang" over it). Stepping onto it sends `entered` once; the run
## scene then asks whether you want to flee (keep everything you carry). After "no" it only asks
## again once you walked away and came back.

signal entered

const ENTER_DISTANCE: float = 0.9
## You must be this far away before it asks again.
const REARM_DISTANCE: float = 1.8
const WOOD := Color(0.42, 0.3, 0.18)
const DAYLIGHT := Color(1.0, 0.93, 0.75)

var player: Node3D

var _armed: bool = false


func _ready() -> void:
	var wood := RoomBuilder.color_material(WOOD)
	# Two rails and the rungs of the ladder, leaning on the corner.
	for side: float in [-0.35, 0.35]:
		RoomBuilder.box(self, Vector3(0.1, RoomBuilder.WALL_H, 0.1), Vector3(side, RoomBuilder.WALL_H / 2.0, 0), wood, 0)
	for step in 6:
		RoomBuilder.box(self, Vector3(0.7, 0.06, 0.08), Vector3(0, 0.35 + step * 0.45, 0), wood, 0)
	# A bright patch of daylight on the floor and a light from above.
	RoomBuilder.box(self, Vector3(1.4, 0.02, 1.4), Vector3(0, 0.01, 0), RoomBuilder.color_material(DAYLIGHT, 0.6), 0)
	var light := OmniLight3D.new()
	light.light_color = DAYLIGHT
	light.light_energy = 1.6
	light.omni_range = 4.0
	light.position.y = RoomBuilder.WALL_H - 0.3
	add_child(light)
	var sign_label := Label3D.new()
	sign_label.text = Language.translate("Ausgang")
	var theme: Theme = ThemeDB.get_project_theme()
	if theme and theme.default_font:
		sign_label.font = theme.default_font
	sign_label.font_size = 48
	sign_label.outline_size = 10
	sign_label.pixel_size = 0.01
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sign_label.modulate = DAYLIGHT
	sign_label.position = Vector3(0, 2.2, 0.3)
	add_child(sign_label)


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	var distance: float = offset.length()
	if not _armed:
		_armed = distance > REARM_DISTANCE
	elif distance < ENTER_DISTANCE:
		_armed = false
		entered.emit()
