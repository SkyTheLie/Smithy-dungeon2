class_name DefenseSaves
extends RefCounted
## The one save of the forge defense (`user://defense_save.json`, written by DefenseRun.save_meta).
## The main menu offers "Weiterspielen" (this save) or "Neues Spiel" (deletes it).
## Older saves (FEHLERKLASSEN 6): the six slots `user://defense_slot_<n>.json` and before them
## `user://defense_meta.json`; the newest of them becomes the one save (once, the others stay as files).

const PATH: String = "user://defense_save.json"
const OLD_SLOT_PATH: String = "user://defense_slot_%d.json"
const OLD_SLOT_COUNT: int = 6
const OLD_CURRENT_PATH: String = "user://defense_current.json"
const OLD_META_PATH: String = "user://defense_meta.json"


## The save file (an older save is moved there first).
static func path() -> String:
	_move_old_save()
	return PATH


static func exists() -> bool:
	return FileAccess.file_exists(path())


static func delete() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## The saved data ({} if none or broken).
static func read() -> Dictionary:
	if not exists():
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data if data is Dictionary else {}


## One line about the save: part, best wave, coins, when it was saved (translated).
static func summary() -> String:
	var data: Dictionary = read()
	if data.is_empty():
		return ""
	var when: Dictionary = Time.get_datetime_dict_from_unix_time(FileAccess.get_modified_time(PATH))
	return "  ·  ".join([
			Language.translate("Teil %s") % DamageKinds.format_number(int(data.get("parts_beaten", 0)) + 1),
			Language.translate("Beste Welle %s") % DamageKinds.format_number(int(data.get("best_wave", 0))),
			Language.translate("%s Münzen") % DamageKinds.format_number(int(data.get("coins", 0))),
			"%02d.%02d. %02d:%02d" % [when.day, when.month, when.hour, when.minute]])


## No save yet but older ones: the newest slot file (or the save from before slots) becomes the save.
static func _move_old_save() -> void:
	if FileAccess.file_exists(PATH):
		return
	var newest: String = ""
	var newest_time: int = -1
	var candidates: Array[String] = [OLD_META_PATH]
	for slot in range(1, OLD_SLOT_COUNT + 1):
		candidates.append(OLD_SLOT_PATH % slot)
	for candidate: String in candidates:
		if FileAccess.file_exists(candidate) and FileAccess.get_modified_time(candidate) > newest_time:
			newest = candidate
			newest_time = FileAccess.get_modified_time(candidate)
	if newest.is_empty():
		return
	DirAccess.rename_absolute(ProjectSettings.globalize_path(newest), ProjectSettings.globalize_path(PATH))
	# The other old files are kept as "<name>.old", so a new game later never brings one back.
	for candidate: String in candidates + [OLD_CURRENT_PATH]:
		if FileAccess.file_exists(candidate):
			DirAccess.rename_absolute(ProjectSettings.globalize_path(candidate), ProjectSettings.globalize_path(candidate + ".old"))
