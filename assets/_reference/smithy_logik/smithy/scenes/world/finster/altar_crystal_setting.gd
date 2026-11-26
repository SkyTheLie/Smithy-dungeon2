class_name AltarCrystalSetting
extends StoryStation
## The true setting in the altar of the first smith (Altar of the Nine): after the story E here opens
## the window of the nine crystals (CrystalSettingMenu, AltarCrystals). It stands on the anvil of the
## altar and wins E over it (the anvil was only there for forging the setting).


# In _init, not _ready: the flag is there as soon as the scene is loaded (admin/test_interact_overlap
# reads it from the scene without adding it to the tree).
func _init() -> void:
	open_flag = AltarCrystals.OPEN_FLAG


func interact_priority() -> int:
	return 1
