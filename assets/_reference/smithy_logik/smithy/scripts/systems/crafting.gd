class_name Crafting
extends RefCounted
## Crafting logic for recipes (forge, anvil, workbench).
## Weapons/armor get damage/armor bonus and random attributes from their rarity (see Rarity).
## A new piece inherits rarity and quality from the pieces it is made of (ForgeQuality.inherit,
## 50/50 rule for mixed rarities); the anvil minigame then adds or takes quality points.
## A blank cast in a mold (forge) starts at ForgeQuality.cast_quality instead of the ingot's quality.


## `extra`: more places the ingredients may come from after the inventory (e.g. the storage
## chest next to the bed). `rarities`: ingredient index -> rarity to use (missing / -1 = any).
## `placed`: what the player laid into the ingredient slots (forge), used before everything else.
static func can_craft(recipe: RecipeData, inventory: Inventory, extra: Array[Inventory] = [],
		rarities: Dictionary = {}, placed: Inventory = null) -> bool:
	for i in recipe.ingredients.size():
		var ingredient: Ingredient = recipe.ingredients[i]
		var from_placed: int = placed.count_matching(ingredient.matches, -1, ingredient.min_rarity) if placed else 0
		if from_placed + count_available(ingredient, [inventory] + extra, rarities.get(i, -1)) < ingredient.amount:
			return false
	return true


## How many pieces of `ingredient` (of `rarity`, -1 = any) all `sources` have together.
static func count_available(ingredient: Ingredient, sources: Array, rarity: int = -1) -> int:
	var total: int = 0
	for source: Inventory in sources:
		total += source.count_matching(ingredient.matches, rarity, ingredient.min_rarity)
	return total


## Removes the ingredients (from the inventory first, then from `extra`) and adds the result to
## the inventory. Returns the produced stack, or null (and changes nothing) if ingredients are
## missing or the result does not fit.
## `points` = quality points from the anvil minigame (ForgeQuality.anvil_points), added to what
## the piece inherits from its ingredients. `rarities`, `placed`: see can_craft (the rarity choice
## only applies to what is not in `placed`).
static func craft(recipe: RecipeData, inventory: Inventory, points: int = 0, extra: Array[Inventory] = [],
		rarities: Dictionary = {}, placed: Inventory = null) -> InventorySlot:
	if not can_craft(recipe, inventory, extra, rarities, placed):
		return null
	# Where each taken piece came from, to give it back if the result does not fit.
	var taken: Array[Array] = []
	var groups: Array = []
	for i in recipe.ingredients.size():
		var ingredient: Ingredient = recipe.ingredients[i]
		var rarity: int = rarities.get(i, -1)
		var pieces: Array[InventorySlot] = []
		var missing: int = ingredient.amount
		var sources: Array[Inventory] = [inventory]
		sources.append_array(extra)
		if placed:
			sources.push_front(placed)
		for source: Inventory in sources:
			var source_rarity: int = -1 if source == placed else rarity
			var amount: int = mini(missing, source.count_matching(ingredient.matches, source_rarity, ingredient.min_rarity))
			if amount <= 0:
				continue
			var from_source: Array[InventorySlot] = source.take_matching(ingredient.matches, amount, source_rarity, ingredient.min_rarity)
			for piece in from_source:
				taken.append([source, piece])
			pieces.append_array(from_source)
			missing -= amount
		groups.append(pieces)
	var start: Dictionary = ForgeQuality.inherit(groups)
	var quality: int = start["quality"]
	if recipe.get_mold_part():
		quality = ForgeQuality.cast_quality()
	var result: InventorySlot = create_result(recipe.result, recipe.result_amount, quality, start["rarity"])
	# Skill "Formenbauer": sometimes the mold gives one blank more.
	if recipe.get_mold_part() and randf() < ForgeQuality._game_state().player_stats.get_cast_extra_chance():
		result.amount += 1
	if points != 0:
		ForgeQuality.add(result, points)
	result.hot = recipe.result_is_hot
	if inventory.get_free_space(result) < result.amount:
		# Inventory full: give the ingredients back.
		for entry in taken:
			(entry[0] as Inventory).add_stack(entry[1])
		return null
	inventory.add_stack(result)
	return result


## Creates a new item stack. Weapons and armor get their random attributes from the rarity.
## `components` = parts of a composed item (e.g. [blade, handle]), see InventorySlot.
static func create_result(item: ItemData, amount: int, quality: int, rarity: Rarity.Tier,
		components: Array[ItemData] = []) -> InventorySlot:
	var result := InventorySlot.new()
	result.item = item
	result.amount = amount
	result.quality = quality
	result.rarity = rarity
	result.components = components.duplicate()
	if item.is_weapon() or item.is_armor() or item.is_jewelry():
		result.bonus_attributes = Rarity.roll_attributes(rarity)
	return result


## Base rarity of an item; for composed items the main (first) part decides, e.g. the blade.
static func get_base_rarity(item: ItemData, components: Array[ItemData] = []) -> Rarity.Tier:
	if not components.is_empty():
		return components[0].base_rarity
	return item.base_rarity


## Rarity of a piece made from several others (ForgeQuality.inherit, the assembly menu).
## `groups`: per ingredient of the recipe the rarities of its slots, e.g. [[R2], [R1]] or
## [[R1, R2, R2]]. Per ingredient one slot is picked at random (R1, R2, R2 -> 1/3 R1, 2/3 R2);
## then the result is evenly spread over all tiers from the lowest to the highest pick
## (plate R1 + leather R4 -> 25 % each R1, R2, R3, R4).
static func roll_mixed_rarity(groups: Array) -> Rarity.Tier:
	var lowest: int = Rarity.Tier.MYTHIC
	var highest: int = 0
	for group: Array in groups:
		var pick: int = group.pick_random()
		lowest = mini(lowest, pick)
		highest = maxi(highest, pick)
	return randi_range(lowest, highest) as Rarity.Tier


## Chances of roll_mixed_rarity: {tier: probability 0-1}, only tiers above 0.
static func get_mixed_rarity_chances(groups: Array) -> Dictionary:
	var chances: Dictionary = {}
	_add_mixed_chances(groups, 0, Rarity.Tier.MYTHIC, 0, 1.0, chances)
	return chances


static func _add_mixed_chances(groups: Array, index: int, lowest: int, highest: int, probability: float,
		chances: Dictionary) -> void:
	if index == groups.size():
		var spread: int = highest - lowest + 1
		for tier in range(lowest, highest + 1):
			chances[tier] = chances.get(tier, 0.0) + probability / spread
		return
	var group: Array = groups[index]
	for pick: int in group:
		_add_mixed_chances(groups, index + 1, mini(lowest, pick), maxi(highest, pick),
				probability / group.size(), chances)
