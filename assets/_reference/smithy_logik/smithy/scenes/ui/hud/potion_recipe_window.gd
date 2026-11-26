class_name PotionRecipeWindow
extends PanelContainer
## Recipe page of one potion (opened from the tab "Rezepte" of the character window): the mortar
## row as at the enchanting table (3 ingredient slots + vial » result), filled with what the
## potion needs (hover for the item tooltip), below where it is brewed and what it does.
## Works for enchanting potions (PotionData: crystal (+ second crystal) + plant + vial) and the other brews
## (BrewData: fixed ingredients + vial).

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_HEADER: Color = Color(0.95, 0.8, 0.45)

@onready var _title_bar: WindowTitleBar = $VBox/TitleBar
@onready var _ingredient_slots: Array[ItemSlotUI] = [%Slot1, %Slot2, %Slot3]
@onready var _vial_slot: ItemSlotUI = %VialSlot
@onready var _result_slot: ItemSlotUI = %ResultSlot
@onready var _info_label: RichTextLabel = %InfoLabel


## Shows the recipe of this potion item (an enchanting potion or a brew of mortar.json).
func show_potion(potion_item: ItemData) -> void:
	var potion: PotionData = ContentDB.potion_of_item(potion_item)
	var brew: BrewData = ContentDB.brew_of_item(potion_item)
	if potion == null and brew == null:
		return
	var ingredients: Array[ItemData] = []
	var lines: Array[String] = [_header("Wo:") + Language.translate(" Zaubertisch, Reiter Mörser")]
	if potion:
		ingredients = potion.get_ingredients()
		lines.append(_header(Language.translate("Wirkung")) + Language.translate(" (Stufe = Seltenheit des Tranks), z. B. Gewöhnlich:"))
		lines.append(potion.describe(Rarity.Tier.COMMON))
		lines.append(_hint(Language.translate("Statt Kristall und Pflanze geht auch ihr Staub (im Mörser zerkleinert). Die Seltenheit mischt sich aus den Zutaten.")))
		if not potion.crystal2:
			lines.append(_hint(Language.translate("Den Kristall ins dritte Feld noch einmal: ein starker Trank, eine Seltenheit besser.")))
		lines.append(_hint(Language.translate("Bei Vollmond gebraut eine Seltenheit besser; gut gerührt noch eine.")))
	else:
		ingredients = brew.ingredients
		if not potion_item.effect.is_empty():
			lines.append(_header(Language.translate("Wirkung:")) + " " + potion_item.effect)
		if brew.rarity_from:
			lines.append(_hint(Language.translate("Seltenheit wie die %s.") % brew.rarity_from.display_name))
		lines.append(_hint(Language.translate("Statt einer Zutat geht auch ihr Staub (im Mörser zerkleinert).")))
	if not potion_item.description.is_empty():
		lines.append(_hint(potion_item.description))
	for i in _ingredient_slots.size():
		_ingredient_slots[i].display(_stack_of(ingredients[i] if i < ingredients.size() else null))
	_vial_slot.display(_stack_of(ContentDB.mortar_item("vial")))
	_result_slot.display(_stack_of(potion_item))
	_title_bar.title = potion_item.display_name
	_info_label.text = "\n".join(lines)
	show()
	_title_bar.bring_to_front()


## One piece of `item` for a slot (empty stack for null).
func _stack_of(item: ItemData) -> InventorySlot:
	var stack := InventorySlot.new()
	if item:
		stack.item = item
		stack.amount = 1
	return stack


func _header(text: String) -> String:
	return "[color=#%s]%s[/color]" % [COLOR_HEADER.to_html(false), text]


func _hint(text: String) -> String:
	return "[color=#%s]%s[/color]" % [COLOR_HINT.to_html(false), text]
