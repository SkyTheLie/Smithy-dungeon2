class_name IngotChoice
extends RefCounted
## Ingots the player chose at the forge (ingredient slot: picker, drag or right click in the
## inventory), e.g. iron ingots R2. The choice stays until those ingots are used up or the player
## takes them out of the slot again: after every casting, on another mould and when the window
## opens again, the forge window lays the same kind back in (CraftingMenu._fill_from_choices).
## A kind is item + rarity (iron ingots R2), whatever the quality: when the chosen stack is used up,
## ingots of the same kind with another quality follow. One sample per chosen kind (amount 1); a
## new choice for an ingredient replaces the old ones it would also have matched.
## Lives in GameState.ingot_choice, saved with the game.

## Samples of the chosen ingots (amount 1, same properties as the chosen stack).
var samples: Array[InventorySlot] = []


## The player chose `stack` for `ingredient`: earlier choices that ingredient takes are dropped.
func choose(ingredient: Ingredient, stack: InventorySlot) -> void:
	if stack == null or stack.is_empty():
		return
	forget(ingredient)
	samples.append(stack.copy_with_amount(1))


## Drops every choice `ingredient` takes (the player took the ingots out of the slot).
func forget(ingredient: Ingredient) -> void:
	samples.assign(samples.filter(func(sample: InventorySlot) -> bool: return not _fits(ingredient, sample)))


## Drops the choice of the kind of `stack` (those ingots are used up).
func forget_kind(stack: InventorySlot) -> void:
	samples.assign(samples.filter(func(sample: InventorySlot) -> bool: return not is_same_kind(sample, stack)))


## Same item and rarity (the quality may differ).
static func is_same_kind(a: InventorySlot, b: InventorySlot) -> bool:
	return a.item == b.item and a.rarity == b.rarity


## The chosen kind `ingredient` takes (newest choice first), or null.
func find(ingredient: Ingredient) -> InventorySlot:
	for i in range(samples.size() - 1, -1, -1):
		if _fits(ingredient, samples[i]):
			return samples[i]
	return null


func _fits(ingredient: Ingredient, sample: InventorySlot) -> bool:
	return ingredient.matches(sample.item) and (ingredient.min_rarity < 0 or int(sample.rarity) >= ingredient.min_rarity)


func to_save_data() -> Array:
	var data: Array = []
	for sample in samples:
		data.append(sample.to_save_data())
	return data


func load_save_data(data: Array) -> void:
	samples.clear()
	for entry: Variant in data:
		if entry is Dictionary:
			var sample := InventorySlot.from_save_data(entry)
			if not sample.is_empty():
				samples.append(sample)
