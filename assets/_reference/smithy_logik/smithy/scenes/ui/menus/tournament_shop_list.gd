class_name TournamentShopList
extends RefCounted
## Entries of the tournament shop (TournamentRewards.shop, bought with TournamentRanking.buy): a
## line with the marks the player has, then one button per ware ("<prize> - <cost> Marken"),
## greyed out with the reason as tooltip when it can't be bought. Used by the tournament master in
## the halls (TournamentDeskMenu) and the crier of the arenas (HeroTournamentMenu).


## Adds the shop to `box`.
static func fill(box: Container) -> void:
	var ranking: TournamentRanking = GameState.ranking
	var header := Label.new()
	header.text = Language.translate("Turnier-Händler: Du hast %d Turnier-Marken. Marken gibt es für Platz 1 bis 3 in den Ligen.") % ranking.marks
	header.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(header)
	var wares: Array[Dictionary] = TournamentRewards.shop()
	for index in wares.size():
		var ware: Dictionary = wares[index]
		var blocker: String = ranking.shop_blocker(index)
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = Language.translate("%s - %d Marken") % [TournamentRanking.describe_prize(str(ware["give"])), int(ware["cost"])]
		button.disabled = not blocker.is_empty()
		button.tooltip_text = blocker
		button.pressed.connect(_on_bought.bind(index))
		box.add_child(button)


static func _on_bought(index: int) -> void:
	var text: String = GameState.ranking.buy(index)
	if not text.is_empty():
		AudioManager.play_sound("coins")
		GameState.show_message(text)
