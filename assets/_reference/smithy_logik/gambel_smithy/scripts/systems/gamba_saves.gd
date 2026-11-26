class_name GambaSaves
extends RefCounted
## The one save of the lucky forge (`user://gamba_save.json`, GambaRun.to_save). Written after
## every day (the bell, the relic choice, the merchant), deleted when a run ends. The main menu
## offers "Weiterspielen" (this save) or "Neues Spiel" (deletes it).

const PATH: String = "user://gamba_save.json"


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func delete() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


static func write(run: GambaRun) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_error("GambaSaves: cannot write %s." % PATH)
		return
	file.store_string(JSON.stringify(run.to_save(), "\t"))
	file.close()


## The saved data ({} if none or broken).
static func read() -> Dictionary:
	if not exists():
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data if data is Dictionary else {}


## One line about the save: day, gold, failures, when it was saved (translated).
static func summary() -> String:
	var data: Dictionary = read()
	if data.is_empty():
		return ""
	var when: Dictionary = Time.get_datetime_dict_from_unix_time(FileAccess.get_modified_time(PATH))
	return "  ·  ".join([
			Language.translate("Tag %s") % DamageKinds.format_number(int(data.get("day", 1))),
			Language.translate("%s Gold") % GambaRun.format_gold(int(data.get("gold", 0))),
			Language.translate("Fehlschläge %s") % ("%d/%d" % [int(data.get("failures", 0)), int(ContentDB.gamba().get("max_failures", 3))]),
			"%02d.%02d. %02d:%02d" % [when.day, when.month, when.hour, when.minute]])
