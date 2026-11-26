extends StoryCutscene
## Eisquell, step eisquell_blade (Torgai's blade from the Finsterburg; Torgai turns to the player
## with act:kahn_son:face_player). Beat:
## - subar_steps_up: Subar, who waited by the barrels, walks up beside the player
##   and holds the wanted poster up to him

@export var torgai: NodePath
@export var subar: NodePath
## Where Subar stops, relative to the player (beside him, on the side away from Torgai).
@export var subar_beside: Vector2 = Vector2(22, 2)

const SUBAR_SPEED: float = 70.0
## The wanted poster he holds up to the player once he stands beside him.
const POSTER: String = "res://assets/sprites/finster/poster_smith.png"


func _play_beat(id: String) -> bool:
	match id:
		"subar_steps_up":
			_subar_steps_up()
		_:
			return false
	return true


func _subar_steps_up() -> void:
	var guard := node2d(subar)
	var smith := player()
	if guard == null or smith == null:
		return
	var side: float = 1.0
	var son := node2d(torgai)
	if son and son.global_position.x > smith.global_position.x:
		side = -1.0
	var spot: Vector2 = smith.global_position + Vector2(subar_beside.x * side, subar_beside.y)
	# straight lines only: first across, then up or down
	await walk_npc(guard, PackedVector2Array([Vector2(spot.x, guard.global_position.y), spot]), SUBAR_SPEED,
			"left" if side > 0.0 else "right")
	if not is_instance_valid(guard) or not is_instance_valid(smith) or not is_inside_tree():
		return
	face_player("right" if side > 0.0 else "left")
	NpcActing.play(guard, "give", POSTER)

