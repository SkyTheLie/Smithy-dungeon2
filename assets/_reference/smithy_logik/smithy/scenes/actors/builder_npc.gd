class_name BuilderNpc
extends StoryNpc
## Master builder Konrad (story figure "builder", Part 2). Talks like every StoryNpc; his dialogue
## choice "Haus ausbauen" (story action "open_menu:house") opens his HouseMenu: the next level of
## the player's house for gold (House, house.json "levels"). The scene is reloaded after every
## change (spawn point FromBuilder next to him).
## npcs.json "builder.visits": once its "flag" is set he only comes on these "weekdays" (0 = Monday)
## between these "hours" (Tuesday and Thursday on the market); before that he is here every day.
## One job at a time: while something he built is not done yet (House.get_builder_job) he plays
## the job's house.json "builder_jobs" "dialogue" instead of his offer "builder_idle".

const HOUSE_MENU: String = "house"
## Story action "open_menu:workshop": the workshop upgrades (WorkshopUpgradeMenu).
const WORKSHOP_MENU: String = "workshop"
## Seconds between two checks whether his visiting hours began or ended.
const VISIT_CHECK_INTERVAL: float = 2.0
## His dialogue with the offers, replaced while he is busy.
const OFFER_DIALOGUE: String = "builder_idle"

@onready var _house_menu: HouseMenu = $HouseMenu
@onready var _workshop_menu: WorkshopUpgradeMenu = $WorkshopUpgradeMenu


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	Events.story_menu_requested.connect(_on_menu_requested)
	player_left.connect(_house_menu.close)
	player_left.connect(_workshop_menu.close)
	var timer := Timer.new()
	timer.wait_time = VISIT_CHECK_INTERVAL
	timer.autostart = true
	timer.timeout.connect(_on_story_changed)
	add_child(timer)


## Outside his visiting hours he only leaves once the player is not with him (otherwise he would
## vanish right after the greenhouse offer, which starts his weekly visits, or in the middle of
## building at 18 o'clock).
func _should_be_here() -> bool:
	return super() and (is_visiting(npc_id) or (_present and (_player_in_range or _house_menu.visible or _workshop_menu.visible)))


## true if a figure with npcs.json "visits" is here right now (always before its "flag").
static func is_visiting(id: String) -> bool:
	var visits: NpcInfo.Visits = ContentDB.npc_info(id).visits
	if visits == null or not GameState.story.has_flag(visits.flag):
		return true
	var cycle: DayCycle = GameState.day_cycle
	var weekday: int = GameCalendar.get_weekday(cycle.day)
	return visits.weekdays.has(weekday) and cycle.get_hour() >= visits.from_hour and cycle.get_hour() < visits.until_hour


func _on_menu_requested(menu: String) -> void:
	if not visible or not _player_in_range:
		return
	if menu == HOUSE_MENU:
		_house_menu.show()
	elif menu == WORKSHOP_MENU:
		_workshop_menu.show()


func _on_interacted() -> void:
	var job: String = GameState.house.get_builder_job()
	var story: Story = GameState.story
	if _dialogue.visible or job.is_empty() or story.get_npc_dialogue(npc_id) != story.get_dialogue(OFFER_DIALOGUE):
		super()
		return
	var busy_id: String = str(ContentDB.house("builder_jobs").get(job, {}).get("dialogue", ""))
	_dialogue.play(story.get_dialogue(busy_id), npc_id, get_portrait())
