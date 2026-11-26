class_name BrewData
extends Resource
## A brew of the mortar (data/content/mortar.json "brews", see docs/CONTENT.md): exactly these
## ingredients (or their dust) + a vial make `item`. Its rarity is the one of the `rarity_from`
## ingredient (the lowest if it is in the mortar several times), without it R1.
## Hero potions (ItemData.hero_potion, e.g. +IQ) are drunk at the hero window, quality potions
## (ItemData.quality_points) are poured over a weapon or armor piece at the enchanting table.

@export var id: StringName
## The wanted ingredients, one per mortar slot (the same item may be there several times).
@export var ingredients: Array[ItemData] = []
## Ingredient whose rarity the result takes (null = the item's own rarity).
@export var rarity_from: ItemData
## The brewed item.
@export var item: ItemData
## true = only once unlocked by the story ("unlock_recipes:<id>", saved in
## GameState.unlocked_recipes); until then the mix fails like any unknown one.
@export var locked: bool = false


## Whether the player can brew it (and sees it in the recipe lists).
func is_known() -> bool:
	if not locked:
		return true
	var tree := Engine.get_main_loop() as SceneTree
	var game_state: Node = tree.root.get_node_or_null("GameState") if tree else null
	return game_state != null and (game_state.get("unlocked_recipes") as Array).has(String(id))


## Whether `items` (dusts count as their source, empty slots left out) are exactly the ingredients.
func matches(items: Array[ItemData]) -> bool:
	if items.size() != ingredients.size():
		return false
	var rest: Array[ItemData] = ingredients.duplicate()
	for given in items:
		var index: int = rest.find(Enchanting.get_base(given))
		if index < 0:
			return false
		rest.remove_at(index)
	return true


## "Kamille + Salbei + Phiole" for the recipe list.
func get_recipe_text() -> String:
	var names: Array[String] = []
	for ingredient in ingredients:
		names.append(ingredient.display_name)
	names.append(Language.translate("Phiole"))
	return " + ".join(names)
