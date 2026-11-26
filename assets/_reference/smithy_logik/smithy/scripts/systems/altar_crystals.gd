class_name AltarCrystals
extends RefCounted
## The nine holy crystals in the true setting on the Altar of the Nine, after the story (OPEN_FLAG).
## The setting is their store: the player can take a crystal out into the inventory and put it back
## (CrystalSettingMenu). A crystal that is out has the story flag OUT_FLAG % element (saved with the
## story flags; general.json "future_flags" drops them on a chapter jump back). Its pillar goes dark
## while it is out (AltarElements.refresh_crystals).
## Elements: the `elements` of AltarElements in the altar scene (one per pillar).

## From this flag on the setting can be opened (the gate is sealed, the ending is told).
const OPEN_FLAG: String = "story_complete"
const OUT_FLAG: String = "altar_crystal_out_%s"
const ITEM: String = "holy_%s_crystal"

const TEXT_FULL: String = "Dein Inventar ist voll."
const TEXT_MISSING: String = "Du hast den Kristall nicht dabei."
const TEXT_TAKEN: String = "Aus der Fassung genommen: %s"
const TEXT_PUT_BACK: String = "Zurück in der Fassung: %s"


static func is_open() -> bool:
	return GameState.story.has_flag(OPEN_FLAG)


static func item_of(element: String) -> ItemData:
	var id: String = ITEM % element
	return ContentDB.item(id) if ContentDB.has_item(id) else null


## true if the crystal of `element` sits in the setting.
static func is_in_setting(element: String) -> bool:
	return is_open() and not GameState.story.has_flag(OUT_FLAG % element)


## Takes the crystal out of the setting into the inventory. Returns "" on success, else the reason
## (German, untranslated).
static func take_out(element: String) -> String:
	var item: ItemData = item_of(element)
	if item == null or not is_in_setting(element):
		return TEXT_MISSING
	var stack := InventorySlot.new()
	stack.item = item
	stack.amount = 1
	if GameState.inventory.get_free_space(stack) < 1:
		return TEXT_FULL
	GameState.inventory.add_item(item)
	GameState.story.set_flag(OUT_FLAG % element)
	return ""


## Puts the crystal from the inventory back into the setting. Returns "" on success, else the reason.
static func put_back(element: String) -> String:
	var item: ItemData = item_of(element)
	if item == null or not is_open() or is_in_setting(element):
		return TEXT_MISSING
	if not GameState.inventory.remove_item(item):
		return TEXT_MISSING
	GameState.story.clear_flags([OUT_FLAG % element])
	return ""


## The element whose crystal `item` is, "" if it is none of `elements`.
static func element_of(item: ItemData, elements: PackedStringArray) -> String:
	if item == null:
		return ""
	for element in elements:
		if item.id == ITEM % element:
			return element
	return ""
