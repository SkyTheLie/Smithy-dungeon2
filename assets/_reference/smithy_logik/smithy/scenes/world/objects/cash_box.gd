extends Station
## The cash box of the player's own shop (the counter): with E the player takes the money the
## shop made (House.shop.pending_gold). Money left there goes into the loot chest in the morning.

## Other picture of the counter (bottom centre on the node), e.g. the long shop counter.
## Empty = the small counter of the scene. The collision gets as wide as the picture.
@export var counter_texture: Texture2D


func _ready() -> void:
	super()
	if is_queued_for_deletion() or counter_texture == null:
		return
	var sprite: Sprite2D = $Sprite2D
	sprite.texture = counter_texture
	sprite.offset = Vector2(-counter_texture.get_width() / 2.0, -counter_texture.get_height())
	var body := RectangleShape2D.new()
	body.size = Vector2(counter_texture.get_width() - 6, 12)
	$CollisionShape2D.shape = body
	$CollisionShape2D.position = Vector2(0, -6)
	var area := RectangleShape2D.new()
	area.size = Vector2(counter_texture.get_width() + 8, 40)
	$InteractionArea/CollisionShape2D.shape = area


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact") and is_nearest_interactable(self):
		get_viewport().set_input_as_handled()
		var gold: int = GameState.house.shop.collect()
		if gold > 0:
			GameState.add_gold(gold)
			GameState.show_message(Language.translate("Du nimmst %d Gold aus der Kasse.") % gold)
		else:
			GameState.show_message(Language.translate("Die Kasse ist leer."))
