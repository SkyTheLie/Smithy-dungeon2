class_name Rent
extends RefCounted
## Rent of the smithy (economy.json "rent": amount, days, landlady). Lives in
## GameState.rent. Renting pays the first period (`days`, 14 = two weeks) right away; then every `days` days the landlady
## collects the rent in the morning (GameState._start_new_day). Without enough gold the rent
## stays due, she tries again the next morning, and every missed morning costs reputation (economy.json "reputation.gains.rent_late").

## true once the smithy is rented.
var active: bool = false
## Day on which the next rent is collected.
var due_day: int = 0
## Rent set by the story (e.g. Oma Hilde raises it to 800). 0 = economy.json "amount".
var amount_override: int = 0
## Story (chapter 7): no rent before this day (0 = never free). Rent is due again on that day.
var free_until_day: int = 0
## Story: the player bought the smithy, no rent any more (active is false then).
var owned: bool = false


func get_amount() -> int:
	return amount_override if amount_override > 0 else int(_value("amount", 300))


func get_landlady() -> String:
	# After the raid (chapter 10) Oma Hilde's niece Lotte owns the smithy.
	if GameState.story.is_npc_gone("landlady"):
		return GameState.story.get_npc_name("niece")
	return str(ContentDB.economy("rent").get("landlady", Language.translate("Die Vermieterin")))


## Rented today: the first period is paid (the caller takes the gold).
func start(day: int) -> void:
	active = true
	due_day = day + int(_value("days", 14))


## No rent for `days` days from `day` on; then it goes on as before (story action "rent_free").
func set_free(day: int, days: int) -> void:
	free_until_day = day + days
	due_day = maxi(due_day, free_until_day)


## The smithy belongs to the player now: no more rent (story action "buy_smithy").
func buy() -> void:
	owned = true
	active = false


## Quest log: "800 Gold, nächste Zahlung am 3. Sommer" or "mietfrei bis ...".
func get_status_text() -> String:
	var next: String = GameCalendar.get_short_text(due_day)
	if due_day <= free_until_day:
		return Language.translate("mietfrei bis %s, danach %d Gold") % [next, get_amount()]
	return Language.translate("%d Gold, nächste Zahlung am %s") % [get_amount(), next]


## Morning of `day`: is the rent due?
func is_due(day: int) -> bool:
	return active and day >= due_day


## The rent was paid: next one in `days` days.
func paid() -> void:
	due_day += int(_value("days", 14))


func _value(key: String, default: float) -> float:
	return float(ContentDB.economy("rent").get(key, default))


func to_save_data() -> Dictionary:
	return {"active": active, "due_day": due_day, "amount": amount_override, "free_until_day": free_until_day,
			"owned": owned}


func load_save_data(data: Dictionary) -> void:
	active = bool(data.get("active", false))
	due_day = int(data.get("due_day", 0))
	amount_override = int(data.get("amount", 0))
	free_until_day = int(data.get("free_until_day", 0))
	owned = bool(data.get("owned", false))
