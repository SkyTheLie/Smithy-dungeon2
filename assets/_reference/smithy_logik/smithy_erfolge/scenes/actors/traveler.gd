extends Station
## The travelling merchant: a covered wagon full of goods, pulled by a camel, the merchant
## next to it. He stands outside the village gate only on his weekday (economy.json
## "traveler.weekday", Sunday) and sells rare things at a high price: silver ring and amulet bands
## ("always_offers") and a few R3-R4 crystals for the jewel table ("offers", fixed prices "=250");
## random molds of one material tier only if "mold_count" is above 0. The choice changes every week
## (random, but the same all day). The goods on the wagon are only decoration for now.
## With `at_home` he stands in Sahrim, his home in the desert, on every other day: not on his
## market day and not on the day before and after it (he is on the road then).

## Look of the rider (drawn with CharacterBaker).
@export var appearance: Appearance
## PixelLab sheet of the rider (assets/sprites/residents/<resident>.png), wins over `appearance`.
@export var resident: String = ""
## Rashid at home in Sahrim (greeting economy.json "traveler.home_greeting") instead of at the gate.
@export var at_home: bool = false

@onready var _dialog: ShopDialog = $ShopDialog


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	if not is_here(GameState.day_cycle.day, at_home):
		queue_free()
		return
	var settings: Dictionary = ContentDB.economy("traveler")
	var rider := $Rider as Sprite2D
	var sheet: Texture2D = CharacterBaker.get_resident_sheet(resident)
	if sheet or appearance:
		rider.texture = sheet if sheet else CharacterBaker.get_sheet(appearance)
		rider.region_rect = CharacterBaker.get_frame_rect("down")
	$NameLabel.text = settings.get("name", Language.translate("Reisender"))
	var greeting: String = settings.get("home_greeting" if at_home else "greeting", settings.get("greeting", ""))
	# Rashid is one of the lizard people: his greeting hisses (economy.json "traveler.voice", Voice).
	greeting = Voice.apply(greeting, str(settings.get("voice", "")))
	_dialog.setup(settings.get("name", Language.translate("Reisender")), greeting,
			get_offers(GameState.day_cycle.day), float(settings.get("price_factor", 2.0)), "traveler")
	interacted.connect(_dialog.toggle)
	player_left.connect(_dialog.close)


## Whether he is at the gate (market day) or at home in Sahrim (`at_home`: any day but the market
## day and the travel days next to it) on this day.
static func is_here(day: int, at_home: bool) -> bool:
	if not at_home:
		return GameState.is_traveler_day(day)
	return not (GameState.is_traveler_day(day - 1) or GameState.is_traveler_day(day) or GameState.is_traveler_day(day + 1))


## Offers of this day: molds of the material tiers economy.json "mold_tier" (number or list, [4, 5] = silver and gold,
## "mold:<part>=<price>"; a metal in "mold_material_flags" only once its story flag is set, e.g.
## gold; "mold_count" [0, 0] = none), "always_offers" and items from "offers". Random per day, the
## same all day long.
static func get_offers(day: int) -> Array[String]:
	var settings: Dictionary = ContentDB.economy("traveler")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("traveler_%d" % day)
	var offers: Array[String] = []
	var tier_setting: Variant = settings.get("mold_tier", [4, 5])
	var tiers: Array[int] = []
	for value: Variant in (tier_setting if tier_setting is Array else [tier_setting]):
		tiers.append(int(value))
	var material_flags: Dictionary = settings.get("mold_material_flags", {})
	var parts: Array[String] = []
	for item: ItemData in ContentDB.get_all_items():
		if item.part_type != ItemData.PartType.NONE and item.material_id != "" and item.material_tier in tiers \
				and GameState.story.has_flag(str(material_flags.get(item.material_id, ""))) \
				and ContentDB.has_recipe("mold_" + String(item.id)):
			parts.append(String(item.id))
	parts.sort()
	var price: int = int(settings.get("mold_price", 450))
	for i in _roll_count(rng, settings.get("mold_count", [1, 3])):
		if parts.is_empty():
			break
		offers.append("mold:%s=%d" % [parts.pop_at(rng.randi() % parts.size()), price])
	var always: Array = settings.get("always_offers", [])
	for spec: String in always:
		offers.append(spec)
	var items: Array = (settings.get("offers", []) as Array).filter(func(spec: String) -> bool: return not always.has(spec))
	for i in _roll_count(rng, settings.get("offer_count", [1, 2])):
		if items.is_empty():
			break
		offers.append(str(items.pop_at(rng.randi() % items.size())))
	return offers


static func _roll_count(rng: RandomNumberGenerator, range_value: Variant) -> int:
	var values: Array = range_value if range_value is Array and not (range_value as Array).is_empty() else [1]
	return rng.randi_range(int(values[0]), int(values[values.size() - 1]))
