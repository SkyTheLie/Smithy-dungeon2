class_name WaterTap
extends Station
## The water tap in the greenhouse: E fills every watering can in the inventory (Garden).
## Story flag "watering_can_filled" the first time a can gets water.

const FILLED_FLAG: String = "watering_can_filled"


func _ready() -> void:
	super()
	interacted.connect(_fill)


func _fill() -> void:
	var inventory: Inventory = GameState.inventory
	if not Garden.has_watering_can(inventory):
		GameState.show_message(Language.translate("Ein Wasserhahn. Mit einer Gießkanne im Inventar kannst du hier Wasser holen."))
		return
	var added: int = Garden.fill_watering_cans(inventory)
	if added == 0:
		GameState.show_message(Language.translate("Deine Gießkanne ist schon voll."))
		return
	GameState.show_message(Language.translate("Du füllst deine Gießkanne: %d Wasser.") % Garden.count_water(inventory))
	GameState.story.set_flag(FILLED_FLAG)
