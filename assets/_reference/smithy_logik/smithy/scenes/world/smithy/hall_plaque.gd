class_name HallPlaque
extends Station
## The plaque on the back wall of the hall of fame: E opens the HallPlaqueMenu next to it.

@onready var _menu: HallPlaqueMenu = $HallPlaqueMenu


func _ready() -> void:
	super()
	interacted.connect(_menu.toggle)
	player_left.connect(_menu.close)
