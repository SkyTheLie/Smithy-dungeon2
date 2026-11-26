class_name CustomerDialog
extends StationMenu
## Dialog with a waiting customer (CustomerNpc): what he wants (item, parts, rarity in its
## colour), until when, and what he pays. "Annehmen" puts the order into the quest log,
## "Ablehnen" sends him away (no reputation change), "Später" just closes the dialog.
## In both first cases the customer leaves (the CustomerSpawner removes him).

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_REWARD: Color = Color(0.55, 0.85, 0.45)

var _visitor: Customers.Visitor

@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _text_label: RichTextLabel = %TextLabel


func _ready() -> void:
	super()
	%AcceptButton.pressed.connect(_on_accept_pressed)
	%DeclineButton.pressed.connect(_on_decline_pressed)
	%ByeButton.pressed.connect(close)


func setup(visitor: Customers.Visitor, portrait: Texture2D) -> void:
	_visitor = visitor
	var order: CustomerOrder = visitor.order
	_title_bar.title = Language.translate("Kunde")
	_name_label.text = order.customer_name
	_portrait.texture = portrait
	var days: int = order.days_left(GameState.day_cycle.day)
	var lines: Array[String] = [
		Language.translate("Guten Tag! Kannst du mir %s schmieden?") % _with_article(order),
		Language.translate("Seltenheit: mindestens %s") % _colored(Rarity.get_display_name(order.rarity), Rarity.get_color(order.rarity)),
		_colored(order.get_parts_text(), COLOR_HINT),
		Language.translate("Ich brauche es bis %s (%s).") % [GameCalendar.get_short_text(order.deadline_day), CustomerOrder.get_days_left_text(days)],
		Language.translate("Ich zahle %s.") % _colored(Language.translate("%d Gold und %d PEXP") % [order.gold, order.experience], COLOR_REWARD),
	]
	_text_label.text = "\n".join(lines)


func _on_accept_pressed() -> void:
	close()
	GameState.customers.accept(_visitor)


func _on_decline_pressed() -> void:
	close()
	GameState.customers.decline(_visitor)


## "ein Eisenschwert" / "eine Eisenkeule" - the article follows the base item's name.
func _with_article(order: CustomerOrder) -> String:
	var feminine: Array[String] = [Language.translate("Keule"), Language.translate("Zweihandaxt"), "Axt"]
	var article: String = Language.translate("eine") if feminine.has(order.item.display_name) else Language.translate("ein")
	return "%s %s" % [article, _colored(order.get_item_name(), Rarity.get_color(order.rarity))]


func _colored(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]
