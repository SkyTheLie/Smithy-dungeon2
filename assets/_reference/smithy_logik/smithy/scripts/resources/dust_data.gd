class_name DustData
extends Resource
## A dust from the mortar (data/content/mortar.json "dusts", see docs/CONTENT.md): one `source`
## (a crystal or the moon lily) is crushed into it at the enchanting table (tab "Mörser"), with
## the rarity of the source. In potions a dust counts like its source (ruby dust = ruby).
## The dust itself is an item with the same id.

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
## Item crushed into this dust.
@export var source: ItemData
## The dust item.
@export var item: ItemData
