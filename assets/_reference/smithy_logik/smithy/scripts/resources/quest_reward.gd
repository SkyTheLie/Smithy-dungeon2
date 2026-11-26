class_name QuestReward
extends Resource
## One reward of a quest. `hidden` rewards are shown as "[?]" until the player gets them.

enum Kind { EXPERIENCE, GOLD, ITEM, DAILY_ITEM }

@export var kind: Kind = Kind.EXPERIENCE
@export var amount: int = 1
## For ITEM and DAILY_ITEM: item id from items.json.
@export var item_id: String = ""
## true = the player only finds out what it is when he gets it.
@export var hidden: bool = false


func get_item() -> ItemData:
	return ContentDB.item(item_id)


## Text for the quest window, e.g. "40 EXP", "Holz ×1 jeden Tag", or "[?]" if hidden.
func get_text(reveal: bool = false) -> String:
	if hidden and not reveal:
		return "[?]"
	match kind:
		Kind.EXPERIENCE:
			return Language.translate("%d PEXP") % amount
		Kind.GOLD:
			return Language.translate("%d Gold") % amount
		Kind.ITEM:
			return "%s ×%d" % [get_item().display_name, amount]
		Kind.DAILY_ITEM:
			return Language.translate("%s ×%d jeden Tag (in der Loot-Kiste)") % [get_item().display_name, amount]
	return ""
