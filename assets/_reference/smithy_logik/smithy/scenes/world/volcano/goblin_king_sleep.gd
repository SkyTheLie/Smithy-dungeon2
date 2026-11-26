class_name GoblinKingSleep
extends Area2D
## On the goblin king's sleep days (GoblinKingAnim.is_sleep_day, every second Wednesday) nobody may
## see him: when the cave is entered the crowd shuts the lane to the throne again (GoblinCrowd
## close_lane), the crowd's talk and the king's own talk are off, and walking up to the crowd (this
## area, at the mouth of the lane) shows npcs.json "goblin_king.sleeps.text". On other days it does
## nothing. Checked once when the scene loads (the day does not change inside the cave).

@export var crowd: GoblinCrowd
## The figure that asks the player in (CrowdTalk), off for the day.
@export var crowd_talk: Node
@export var king: StoryNpc
## Seconds before the text shows again when the player comes back.
const REPEAT_AFTER: float = 6.0

var _asleep: bool = false
var _shown_at: float = -1000.0


func _ready() -> void:
	_asleep = GoblinKingAnim.is_sleep_day(GameState.day_cycle.day)
	monitoring = _asleep
	if not _asleep:
		return
	body_entered.connect(_on_body_entered)
	_shut.call_deferred()


## true if the king sleeps today (this visit).
func is_asleep() -> bool:
	return _asleep


func _shut() -> void:
	if crowd:
		crowd.close_lane()
	if is_instance_valid(crowd_talk):
		crowd_talk.queue_free()
	if king:
		king.auto_talk = false
		(king.get_node("InteractionArea") as Area2D).set_deferred("monitoring", false)
		var marker := king.get_node_or_null("Marker") as CanvasItem
		if marker:
			marker.modulate.a = 0.0


func _on_body_entered(body: Node2D) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if not body is Player or now - _shown_at < REPEAT_AFTER:
		return
	_shown_at = now
	var sleeps: NpcInfo.Sleeps = ContentDB.npc_info("goblin_king").sleeps
	var text: String = sleeps.text if sleeps else ""
	if not text.is_empty():
		GameState.show_message(Language.translate(text))
