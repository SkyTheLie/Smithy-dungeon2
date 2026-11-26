class_name Economy
extends RefCounted
## Prices of customer orders, from the item values (items.json "value") and the factors in
## economy.json "prices" (format: docs/CONTENT.md).
##
##   material cost = per part: cast part -> its ingot + fuel_per_cast_part × fuel item,
##                             carved part -> its raw material (e.g. wood)
##   reward (gold)  = (material cost × (1 + work_share + order_bonus) + order_base_gold
##                     + order_gold_per_tier per part and material tier)
##                    × (1 + rarity_bonus_per_step × tiers above the material's rarity)
##                    × (1 + reputation pay bonus)
##   reward (EXP)   = gold × experience_per_gold
##
## Example: copper sword = 18 gold material × 1.7 + 65 = 96 gold at the material's own rarity
## (never less than order_min_gold, 90); iron sword 28 × 1.7 + 65 + 2 × 6 = 125 gold.
##
## Merchants: they sell at value × buy_markup (1.25). They buy raw goods at value × sell_factor
## (0.6) and things the player made (parts, weapons) at their material cost × sell_crafted_factor
## (1.2) × the rarity bonus (per tier above R1) - little profit, orders pay much better. Value of a made thing = its material cost
## plus the plain materials of its recipe that are no parts (crystal of a staff, rope of a bow), so a
## staff is always worth more than its crystal.
## A ring or amulet is worth its band plus its crystal (InventorySlot.jewel_crystal). The crystal
## part is not marked up like work: merchants pay it like the raw crystal (economy.json "jewelry"
## "crystal_sell_factor"), shops sell it at "shop_crystal_factor" (see ConsignmentShop.get_price),
## so setting a bought crystal earns little; the profit comes from rarity and the shop's furniture.
## Weapons the player forged sell for crafted_weapon_bonus (7) gold more per piece, at
## merchants and in Nina's/the own shop (get_crafted_bonus).
## Stations can be bought too ("station:<id>", economy.json "stations").


## Item id -> the recipe that makes it (null = none), see _find_recipe_for.
static var _recipe_for: Dictionary = {}
## ContentDB.generation the cache above was filled for.
static var _recipe_for_generation: int = -1


static func price(key: String, default: float) -> float:
	return float(ContentDB.economy("prices").get(key, default))


## What the material of one part costs (see above). Parts without a recipe (leather from the
## tanning rack) are worth their items.json "value".
static func get_part_cost(part: ItemData) -> float:
	var recipe: RecipeData = _find_recipe(String(part.id))
	if recipe == null or recipe.ingredients.is_empty():
		return float(part.value)
	var ingredient: Ingredient = recipe.ingredients[0]
	if recipe.station == &"anvil":
		# Cast part: the anvil turns the hot blank into the part; the blank comes from the mold.
		var mold: RecipeData = _find_recipe("mold_" + String(part.id))
		if mold == null or mold.ingredients.is_empty():
			return 0.0
		var fuel: ItemData = ContentDB.item(ContentDB.economy("prices").get("fuel_item", "coal"))
		var fuel_cost: float = price("fuel_per_cast_part", 2.0) * (fuel.value if fuel else 0)
		return mold.ingredients[0].item.value * mold.ingredients[0].amount + fuel_cost
	if ingredient.item:
		return ingredient.item.value * ingredient.amount
	return 0.0


static func get_material_cost(parts: Array[ItemData]) -> float:
	var total: float = 0.0
	for part in parts:
		total += get_part_cost(part)
	return total


## Gold for an order: `steps` = how many rarity tiers above the material's own rarity,
## `pay_bonus` = reputation bonus (0.1 = +10 %).
## Base = material × (1 + work_share + order_bonus) + order_base_gold + order_gold_per_tier for
## every part per material tier (materials.json "tier": wood 0, copper 1, iron 2 ...), then rarity and reputation;
## never less than order_min_gold.
## `extra_value`: worth of plain materials that are no parts (rope of a bow, crystal of a staff).
static func get_order_gold(parts: Array[ItemData], steps: int, pay_bonus: float, extra_value: float = 0.0) -> int:
	var gold: float = (get_material_cost(parts) + extra_value) * (1.0 + price("work_share", 0.5) + price("order_bonus", 0.2))
	gold += price("order_base_gold", 0.0)
	for part in parts:
		gold += price("order_gold_per_tier", 0.0) * part.material_tier
	gold *= 1.0 + price("rarity_bonus_per_step", 0.25) * steps
	gold *= 1.0 + pay_bonus
	return maxi(roundi(price("order_min_gold", 1.0)), roundi(gold))


static func get_order_experience(gold: int) -> int:
	return maxi(1, roundi(gold * price("experience_per_gold", 0.5)))


## What a stack is worth (one piece): made things (composed items, parts) = material cost,
## everything else = items.json "value".
static func get_value(stack: InventorySlot) -> float:
	if not stack.components.is_empty():
		return get_material_cost(stack.components) + get_recipe_extra_value(_find_recipe_for(stack.item)) 				+ get_crystal_value(stack)
	if stack.item.part_type != ItemData.PartType.NONE:
		return get_part_cost(stack.item)
	# Rare materials (e.g. an R3 ingot from the traveler) are worth more per tier above R1.
	return stack.item.value * (1.0 + price("rarity_bonus_per_step", 0.25) * stack.rarity)


## Price of one piece at a merchant.
static func get_buy_price(stack: InventorySlot) -> int:
	return maxi(1, ceili(get_value(stack) * price("buy_markup", 1.25)))


## What a merchant pays for one piece (0 = he doesn't take it, e.g. glowing parts).
## Items with a fixed items.json "sell_price" (R1) pay sell_price × sell_price_factor per tier
## above R1 (factor from the item, else economy.json prices.sell_price_factor, 1.2).
static func get_sell_price(stack: InventorySlot) -> int:
	if stack.is_empty() or stack.hot:
		return 0
	if stack.item.sell_price >= 0:
		var step: float = stack.item.sell_price_factor if stack.item.sell_price_factor > 0.0 \
				else price("sell_price_factor", 1.2)
		return roundi(stack.item.sell_price * pow(step, stack.rarity)) + get_crafted_bonus(stack)
	var made: bool = not stack.components.is_empty() or stack.item.part_type != ItemData.PartType.NONE
	var factor: float = price("sell_crafted_factor", 1.1) if made else price("sell_factor", 0.6)
	if made:
		# Rarity: +rarity_bonus_per_step per tier above R1 (raw goods have it in get_value already).
		factor *= 1.0 + price("rarity_bonus_per_step", 0.25) * stack.rarity
	var crystal: float = get_crystal_value(stack)
	var crystal_price: float = 0.0
	if crystal > 0.0:
		# The crystal of a jewel counts like the raw crystal (no markup for the work).
		crystal_price = crystal * jewelry_setting("crystal_sell_factor", 0.6) 				* (1.0 + price("rarity_bonus_per_step", 0.25) * stack.rarity)
	return maxi(1, floori((get_value(stack) - crystal) * factor + crystal_price)) + get_crafted_bonus(stack)


## Worth of the crystal set into a ring or amulet (its items.json "value"), 0 for anything else.
static func get_crystal_value(stack: InventorySlot) -> float:
	if stack == null or stack.is_empty() or stack.jewel_crystal == null:
		return 0.0
	return float(stack.jewel_crystal.value)


## A number of economy.json "jewelry".
static func jewelry_setting(key: String, default: float) -> float:
	return float(ContentDB.economy("jewelry").get(key, default))


## Extra gold per piece for a weapon the player assembled (InventorySlot.crafted, bought
## ones don't count): economy.json "prices" crafted_weapon_bonus. 0 for everything else.
static func get_crafted_bonus(stack: InventorySlot) -> int:
	if stack.is_empty() or not stack.crafted or not stack.item.is_weapon():
		return 0
	return roundi(price("crafted_weapon_bonus", 0.0))


## Recipes / molds a merchant sells (economy.json "recipes"): {"name", "price", "unlock": [recipe ids], "icon"}.
static func get_recipe_offer(offer_id: String) -> Dictionary:
	return ContentDB.economy("recipes").get(offer_id, {})


## Price of a mold of this metal (economy.json "prices" mold_price_per_metal), the same at every
## merchant. 0 for an unknown metal.
static func get_mold_price(material_id: String) -> int:
	return int((ContentDB.economy("prices").get("mold_price_per_metal", {}) as Dictionary).get(material_id, 0))


## A secret potion recipe for sale (economy.json "potion_recipes", offer "potion_recipe:<id>"):
## {"name", "price", "potions": [potion ids], "unlock_flag", "rank"}. Buying it sets the flag
## Enchanting.FOUND_FLAG of each potion, as if it had been brewed once.
static func get_potion_recipe_offer(offer_id: String) -> Dictionary:
	return ContentDB.economy("potion_recipes").get(offer_id, {})


## Price of a merchant offer: "station:<id>", "recipe:<id>" or an item spec ("copper_ingot*2"
## = two pieces).
static func get_offer_price(spec: String) -> int:
	if spec.is_valid_int():
		return int(spec)
	if spec.begins_with("station:"):
		return int(get_station_offer(spec.get_slice(":", 1)).get("price", 0))
	if spec.begins_with("recipe:"):
		return int(get_recipe_offer(spec.get_slice(":", 1)).get("price", 0))
	if spec.begins_with("potion_recipe:"):
		return int(get_potion_recipe_offer(spec.get_slice(":", 1)).get("price", 0))
	var stack: InventorySlot = ContentDB.make_stack(spec)
	return get_buy_price(stack) * stack.amount if stack else 0


## A station that can be bought (economy.json "stations"): {"name", "price", "flag", "icon", "description"}.
static func get_station_offer(station_id: String) -> Dictionary:
	return ContentDB.economy("stations").get(station_id, {})


## Worth of the plain materials of a recipe that are no parts (rope of a bow, crystal of a staff).
## 0 for null.
static func get_recipe_extra_value(recipe: RecipeData) -> float:
	var value: float = 0.0
	if recipe == null:
		return value
	for ingredient in recipe.ingredients:
		if ingredient.part_type == ItemData.PartType.NONE and ingredient.item:
			value += ingredient.item.value * ingredient.amount
	return value


## The recipe that makes `item` (its own id first, else any recipe with it as result).
static func _find_recipe_for(item: ItemData) -> RecipeData:
	if item == null:
		return null
	var key: String = String(item.id)
	# The content was loaded again (language change, tests): the old recipes are gone.
	if _recipe_for_generation != ContentDB.generation:
		_recipe_for_generation = ContentDB.generation
		_recipe_for.clear()
	if _recipe_for.has(key):
		return _recipe_for[key]
	var recipe: RecipeData = _find_recipe(key)
	if recipe == null or recipe.result != item:
		recipe = null
		for other in ContentDB.get_all_recipes():
			if other.result == item:
				recipe = other
				break
	_recipe_for[key] = recipe
	return recipe


static func _find_recipe(id: String) -> RecipeData:
	return ContentDB.recipe(id) if ContentDB.has_recipe(id) else null
