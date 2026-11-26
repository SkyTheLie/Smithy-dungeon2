class_name RecipeBookStand
extends Station
## The nightstand in the bedroom with the recipe book on it: E opens the recipe book
## (RecipeBookWindow in the HUD), E again closes it, walking away closes it too.


func _ready() -> void:
	super()
	interacted.connect(Events.recipe_book_toggle_requested.emit)
	player_left.connect(Events.recipe_book_close_requested.emit)
