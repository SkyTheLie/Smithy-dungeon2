class_name AltarCrystalSetting
extends StoryStation
## The true setting in the altar of the first smith (Altar of the Nine): after the story E here opens
## the window of the nine crystals (CrystalSettingMenu, AltarCrystals). It stands on the anvil of the
## altar and wins E over it (the anvil was only there for forging the setting).


func _ready() -> void:
	open_flag = AltarCrystals.OPEN_FLAG
	super()


func interact_priority() -> int:
	return 1
