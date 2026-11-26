class_name RaidChargeCutscene
extends StoryCutscene
## The counter attack on the burning market (chapter 10, dialogue "raid_market_scene"):
## - guild_charge: the view goes over to the guild hall, Hedwig and the adventurers storm out
##   (they start with the flag `raid_heroes`, set by the same line) and run at the zombies
## - bruno_charges: Bruno draws his sword and holds it up, then he stamps off to the Lich
##   (flag `charge_flag` hands him from his Companion over to his RaidFighter); the view follows
##   him to the Lich and comes back to the player

@export var bruno_companion: NodePath
@export var lich: NodePath
## Where the view looks while the adventurers come out (map coordinates).
@export var guild_point: Vector2 = Vector2(386, 90)
@export var charge_flag: String = "raid_bruno_charges"

const SWORD: String = "copper_blade+copper_handle"
const PAN_TIME: float = 0.7


func _ready() -> void:
	super()


func _play_beat(id: String) -> bool:
	match id:
		"guild_charge":
			_guild_charge()
		"bruno_charges":
			_bruno_charges()
		_:
			return false
	return true


func _guild_charge() -> void:
	var parent := get_parent() as Node2D
	await pan_camera(parent.to_global(guild_point) if parent else guild_point, PAN_TIME)
	AudioManager.play_sound("door")
	if not await wait(1.6):
		return
	await camera_home(PAN_TIME)


func _bruno_charges() -> void:
	var bruno := node2d(bruno_companion)
	var target := node2d(lich)
	if bruno and bruno.visible:
		bruno.call("face", "up")
		await NpcActing.play(bruno, "hold", SWORD)
		if not is_inside_tree():
			return
	GameState.story.set_flag(charge_flag)
	if target:
		await pan_camera(target.global_position, PAN_TIME * 2.0)
	if not await wait(0.9):
		return
	await camera_home(PAN_TIME)
