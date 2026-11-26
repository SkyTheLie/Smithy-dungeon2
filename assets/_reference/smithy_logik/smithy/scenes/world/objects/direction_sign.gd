class_name DirectionSign
extends StaticBody2D
## Signpost at a road: board with a carved arrow (texture) and the place name in the game font.

const SIGN_CONTEXT: StringName = &"sign"

@export var texture: Texture2D
@export var text: String = ""


func _ready() -> void:
	$Sprite2D.texture = texture
	var board: Label = $Label
	board.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	# Board-sized name (context "sign" in the .po file), for names too long for it.
	var short: String = tr(text, SIGN_CONTEXT)
	board.text = short if short != text else tr(text)
