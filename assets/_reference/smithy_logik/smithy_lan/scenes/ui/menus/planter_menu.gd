class_name PlanterMenu
extends StationMenu
## Window of a plant pot (Planter): the soil of the pot and one button per field.
## Soil: "Erde einfüllen" takes a soil item (items.json "soil") from the inventory; it stays in the
## pot for good. "Erde tauschen" puts another soil in (only while nothing grows), the old one comes
## back into the inventory. A field: click on an empty one plants the first seed from the
## inventory, on a growing plant scatters ash (once, harvest one rarity tier better and half the
## growing time, Garden.ASH_GROW_FACTOR), on a blooming one harvests it. Right click on a seed or soil in the inventory does the same
## (try_quick_move). "Gießen" (or right click on a watering can) waters every growing plant that
## was not watered today, one charge of the watering cans each (Garden.water).
## Story flags: "pot_soil_filled", "planted_<seed id>", "harvested_<crop id>", "plant_watered".

const FIELD_SIZE := Vector2(26, 26)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)
const COLOR_OK: Color = Color(0.55, 0.85, 0.5)
const SOIL_FLAG: String = "pot_soil_filled"
const WATER_FLAG: String = "plant_watered"

var _planter: Planter

@onready var _soil_label: Label = %SoilLabel
@onready var _soil_button: Button = %SoilButton
@onready var _fields: GridContainer = %Fields
@onready var _water_button: Button = %WaterButton
@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	super()
	_soil_button.pressed.connect(_on_soil_pressed)
	_water_button.pressed.connect(_water_all)


func open_for(planter: Planter) -> void:
	_planter = planter
	_title_bar.title = House.get_furniture(planter.furniture_id).get("name", Language.translate("Pflanztopf"))
	for child in _fields.get_children():
		_fields.remove_child(child)
		child.queue_free()
	_fields.columns = planter.size
	for field in planter.size * planter.size:
		var button := Button.new()
		button.custom_minimum_size = FIELD_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_on_field_pressed.bind(field))
		_fields.add_child(button)
	_message_label.text = ""
	show()
	_refresh()


func _process(_delta: float) -> void:
	if visible and _planter:
		_refresh()


func _refresh() -> void:
	if _planter == null or not is_instance_valid(_planter):
		close()
		return
	var garden: Garden = GameState.garden
	var soil: ItemData = garden.get_soil(_planter.uid)
	_soil_label.text = Language.translate("Erde: %s") % (soil.display_name if soil else Language.translate("keine"))
	var other_soil: ItemData = _find_soil_in_inventory(soil)
	if soil == null:
		_soil_button.text = Language.translate("Erde einfüllen")
		_soil_button.disabled = other_soil == null
		_soil_button.tooltip_text = "" if other_soil else Language.translate("Du hast keine Erde dabei. Gartenerde gibt es bei der Möbelhändlerin am Markt.")
		_soil_button.show()
	else:
		_soil_button.text = Language.translate("Erde tauschen")
		_soil_button.visible = other_soil != null
		_soil_button.disabled = garden.has_plants(_planter.uid)
		if _soil_button.disabled:
			_soil_button.tooltip_text = Language.translate("Erst ernten, dann die Erde tauschen.")
		elif other_soil:
			_soil_button.tooltip_text = Language.translate("%s statt %s einfüllen.") % [other_soil.display_name, soil.display_name]
	var day: int = GameState.day_cycle.day
	for field in _fields.get_child_count():
		var button := _fields.get_child(field) as Button
		var bed: String = _planter.get_bed_id(field)
		button.icon = Planter.get_field_texture(bed)
		button.disabled = soil == null
		button.tooltip_text = _get_field_tooltip(bed, day, soil != null)
	_refresh_water_button(day)


func _refresh_water_button(day: int) -> void:
	var inventory: Inventory = GameState.inventory
	var thirsty: int = _get_thirsty_fields(day).size()
	var water: int = Garden.count_water(inventory)
	_water_button.visible = GameState.garden.has_plants(_planter.uid)
	_water_button.text = Language.translate("Gießen (Wasser: %d)") % water if Garden.has_watering_can(inventory) else Language.translate("Gießen")
	_water_button.disabled = thirsty == 0 or water == 0
	if not Garden.has_watering_can(inventory):
		_water_button.tooltip_text = Language.translate("Du hast keine Gießkanne. Die Gussform für den Kannenkörper verkauft der Gussform-Händler am Markt.")
	elif thirsty == 0:
		_water_button.tooltip_text = Language.translate("Alles ist für heute gegossen.")
	elif water == 0:
		_water_button.tooltip_text = Language.translate("Deine Gießkanne ist leer. Am Wasserhahn im Gewächshaus auffüllen.")
	else:
		_water_button.tooltip_text = Language.translate("Gießt %d Pflanzen (je 1 Wasser). Gegossen wächst eine Pflanze heute Nacht doppelt so schnell.") % thirsty


## Fields of the pot with a growing plant that was not watered today.
func _get_thirsty_fields(day: int) -> Array[String]:
	var beds: Array[String] = []
	for field in _planter.size * _planter.size:
		var bed: String = _planter.get_bed_id(field)
		if GameState.garden.can_water(bed, day):
			beds.append(bed)
	return beds


## Waters every thirsty plant of the pot as long as the watering cans have water.
func _water_all() -> void:
	var day: int = GameState.day_cycle.day
	var thirsty: Array[String] = _get_thirsty_fields(day)
	if thirsty.is_empty():
		_show(Language.translate("Alles ist für heute gegossen."), COLOR_ERROR)
		return
	if not Garden.has_watering_can(GameState.inventory):
		_show(Language.translate("Du hast keine Gießkanne."), COLOR_ERROR)
		return
	var watered: int = 0
	for bed in thirsty:
		if not Garden.use_water(GameState.inventory):
			break
		GameState.garden.water(bed, day)
		watered += 1
	if watered == 0:
		_show(Language.translate("Deine Gießkanne ist leer. Am Wasserhahn auffüllen."), COLOR_ERROR)
		return
	var text: String = Language.translate("Du gießt %s. Heute Nacht wächst %s doppelt so schnell.") % [
			"1 Pflanze" if watered == 1 else Language.translate("%d Pflanzen") % watered, "sie" if watered == 1 else "jede"]
	if watered < thirsty.size():
		text += Language.translate(" Die Kanne ist leer, am Wasserhahn auffüllen.")
	_show(text, COLOR_OK)
	GameState.story.set_flag(WATER_FLAG)
	_refresh()


func _get_field_tooltip(bed: String, day: int, has_soil: bool) -> String:
	var garden: Garden = GameState.garden
	if not has_soil:
		return Language.translate("Erst Erde in den Topf füllen.")
	var seed_item: ItemData = garden.get_seed(bed)
	if seed_item == null:
		return Language.translate("Leeres Feld. Klick: Samen aus dem Inventar pflanzen.")
	var crop: String = seed_item.grows_into.display_name
	if garden.get_stage(bed, day) == Garden.Stage.READY:
		if seed_item.full_moon_bonus and GameCalendar.is_full_moon(day):
			return Language.translate("%s blüht! Klick: ernten.") % crop + "\n" \
					+ Language.translate("Heute ist Vollmond: die Ernte wird eine Seltenheit besser.")
		return Language.translate("%s blüht! Klick: ernten.") % crop
	var days: int = garden.get_days_left(bed, day)
	var text: String = "%s, %s." % [crop, Language.translate("morgen fertig") if days == 1 else Language.translate("noch %d Tage") % days]
	text += "\n" + (Language.translate("Heute gegossen.") if garden.is_watered_today(bed, day)
			else Language.translate("Noch nicht gegossen (Gießkanne: wächst heute Nacht doppelt)."))
	if garden.is_fertilized(bed):
		text += Language.translate("\nMit Asche gedüngt.")
	else:
		text += Language.translate("\nKlick mit Asche im Inventar: düngen (wächst doppelt so schnell, Ernte eine Seltenheit besser).")
	return text


## First soil item in the inventory that is not `other_than` (null = none).
func _find_soil_in_inventory(other_than: ItemData) -> ItemData:
	for stack: InventorySlot in GameState.inventory.slots:
		if not stack.is_empty() and Garden.is_soil(stack.item) and stack.item != other_than:
			return stack.item
	return null


func _on_soil_pressed() -> void:
	var garden: Garden = GameState.garden
	var current: ItemData = garden.get_soil(_planter.uid)
	var soil: ItemData = _find_soil_in_inventory(current)
	if soil == null or (current and garden.has_plants(_planter.uid)):
		return
	_fill_soil(soil)


func _fill_soil(soil: ItemData) -> void:
	if not GameState.take_items(String(soil.id)):
		return
	var old: ItemData = GameState.garden.fill_soil(_planter.uid, soil)
	if old:
		GameState.give_items(String(old.id))
		_show(Language.translate("Du tauschst die Erde: %s statt %s.") % [soil.display_name, old.display_name], COLOR_OK)
	else:
		_show(Language.translate("Du füllst %s in den Topf. Jetzt kannst du pflanzen.") % soil.display_name, COLOR_OK)
	GameState.story.set_flag(SOIL_FLAG)
	_refresh()


func _on_field_pressed(field: int) -> void:
	var garden: Garden = GameState.garden
	var bed: String = _planter.get_bed_id(field)
	var day: int = GameState.day_cycle.day
	if not garden.has_soil(_planter.uid):
		_show(Language.translate("Erst Erde in den Topf füllen."), COLOR_ERROR)
		return
	match garden.get_stage(bed, day):
		Garden.Stage.EMPTY:
			var index: int = _find_seed_slot()
			if index < 0:
				_show(Language.translate("Du hast keine Samen dabei."), COLOR_ERROR)
			else:
				_plant(field, index)
		Garden.Stage.READY:
			_harvest(bed)
		_:
			var crop: String = garden.get_seed(bed).grows_into.display_name
			if garden.is_fertilized(bed):
				_show(Language.translate("Die %s ist schon gedüngt.") % crop, COLOR_ERROR)
			elif GameState.take_items(Garden.ASH_ID):
				garden.fertilize(bed, day)
				_show(Language.translate("Du streust Asche auf das Feld. Die %s wächst schneller und wird prächtiger.") % crop, COLOR_OK)
			else:
				_show(Language.translate("Die %s wächst noch. Mit Asche gedüngt ginge es schneller.") % crop, COLOR_ERROR)
	_refresh()


func _find_seed_slot() -> int:
	var slots: Array[InventorySlot] = GameState.inventory.slots
	for i in slots.size():
		if not slots[i].is_empty() and Garden.is_seed(slots[i].item):
			return i
	return -1


## Plants the seed of inventory slot `index` into `field`.
func _plant(field: int, index: int) -> void:
	var seed_item: ItemData = GameState.inventory.slots[index].item
	if not GameState.garden.plant(_planter.get_bed_id(field), seed_item, GameState.day_cycle.day):
		return
	GameState.inventory.remove_from_slot(index, 1)
	_show(Language.translate("Du pflanzt %s. In %d Tagen ist es so weit.") % [seed_item.display_name, seed_item.grow_days], COLOR_OK)
	GameState.story.set_flag("planted_" + String(seed_item.id))


func _harvest(bed: String) -> void:
	var seed_item: ItemData = GameState.garden.get_seed(bed)
	var preview := InventorySlot.new()
	preview.item = seed_item.grows_into
	preview.amount = seed_item.harvest_amount
	if GameState.inventory.get_free_space(preview) < preview.amount:
		_show(Language.translate("Dein Inventar ist voll."), COLOR_ERROR)
		return
	var crop: InventorySlot = GameState.garden.harvest(bed, GameState.day_cycle.day, GameState.player_stats.get_plant_rarity_chance())
	GameState.inventory.add_stack(crop)
	# The seeds come back (with a chance for one more); what does not fit goes to the loot chest.
	var seeds: InventorySlot = Garden.roll_seeds(seed_item)
	var seed_count: int = seeds.amount
	var leftover: int = GameState.inventory.add_stack(seeds)
	if leftover > 0:
		GameState.put_stack_into_reward_chest(seeds.copy_with_amount(leftover))
	_show(Language.translate("Du erntest %d× %s (%s) und %d× %s.") % [crop.amount, crop.item.display_name, Rarity.get_display_name(crop.rarity),
			seed_count, seed_item.display_name], COLOR_OK)
	GameState.story.set_flag("harvested_" + String(crop.item.id))
	GameState.achievements.count("harvest")


## Right click on a seed (plants it into the first empty field) or soil (fills / swaps it).
func try_quick_move(inventory_index: int, _amount: int = -1) -> bool:
	if not visible or _planter == null:
		return false
	var stack: InventorySlot = GameState.inventory.slots[inventory_index]
	if stack.is_empty():
		return false
	var garden: Garden = GameState.garden
	if Garden.is_watering_can(stack):
		_water_all()
		return true
	if Garden.is_soil(stack.item):
		if garden.get_soil(_planter.uid) == stack.item or garden.has_plants(_planter.uid):
			return false
		_fill_soil(stack.item)
		return true
	if not Garden.is_seed(stack.item) or not garden.has_soil(_planter.uid):
		return false
	for field in _planter.size * _planter.size:
		if garden.get_stage(_planter.get_bed_id(field), GameState.day_cycle.day) == Garden.Stage.EMPTY:
			_plant(field, inventory_index)
			_refresh()
			return true
	_show(Language.translate("Alle Felder sind belegt."), COLOR_ERROR)
	return false


func _show(text: String, color: Color) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)
