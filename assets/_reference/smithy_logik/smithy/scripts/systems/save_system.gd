class_name SaveSystem
extends RefCounted
## Save files: one JSON file per slot in user://saves/ (on Windows under
## %APPDATA%/Godot/app_userdata/<project>/saves/). Slot 0 is the autosave (written when the
## player goes to sleep), slots 1-3 are saved by hand. What goes into a save is collected and
## applied by GameState (to_save_data / load_save_data of the single systems).
## Every file has a format version so older saves can be converted later.

const SAVE_DIR: String = "user://saves/"
const AUTOSAVE_SLOT: int = 0
## Slots the player can save into by hand: 1..MANUAL_SLOTS.
const MANUAL_SLOTS: int = 3
## Quicksave (F5 saves, F7 loads); its own file, so it never overwrites slots 1..3.
const QUICKSAVE_SLOT: int = 99
## 2: items and recipes are stored by id instead of resource path (version 1 is converted on load).
const FORMAT_VERSION: int = 2


static func get_slot_path(slot: int) -> String:
	if slot == AUTOSAVE_SLOT:
		return SAVE_DIR + "autosave.json"
	if slot == QUICKSAVE_SLOT:
		return SAVE_DIR + "quicksave.json"
	return SAVE_DIR + "slot_%d.json" % slot


static func get_slot_name(slot: int) -> String:
	if slot == QUICKSAVE_SLOT:
		return Language.translate("Schnellspeicherung")
	return Language.translate("Slot 0: Autospeicherung") if slot == AUTOSAVE_SLOT else Language.translate("Slot %d") % slot


## All slots in the order of the save window: autosave, quicksave, then the manual ones.
static func get_all_slots() -> Array[int]:
	var slots: Array[int] = [AUTOSAVE_SLOT, QUICKSAVE_SLOT]
	for slot in range(1, MANUAL_SLOTS + 1):
		slots.append(slot)
	return slots


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot))


## Writes the data to a temporary file first and then replaces the old save, so a crash while
## writing never destroys the previous save. Returns false on errors.
static func write(slot: int, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	data["version"] = FORMAT_VERSION
	data["saved_at"] = int(Time.get_unix_time_from_system())
	var path: String = get_slot_path(slot)
	var temp_path: String = path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s (error %d)." % [temp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var error: Error = DirAccess.rename_absolute(temp_path, path)
	if error != OK:
		push_error("Could not replace %s (error %d)." % [path, error])
		return false
	return true


## Contents of a slot, or {} if it is empty, broken or from a newer game version.
static func read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var text: String = FileAccess.get_file_as_string(get_slot_path(slot))
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_warning("Save %s is broken." % get_slot_path(slot))
		return {}
	if int(data.get("version", 0)) > FORMAT_VERSION:
		push_warning("Save %s is from a newer version of the game." % get_slot_path(slot))
		return {}
	return data


## The slot saved last (autosave, quicksave or manual), or -1 if there is no loadable save.
static func get_newest_slot() -> int:
	var newest_slot: int = -1
	var newest_time: int = -1
	for slot in get_all_slots():
		var data: Dictionary = read(slot)
		if data.is_empty():
			continue
		var saved_at: int = int(data.get("saved_at", 0))
		if saved_at > newest_time:
			newest_time = saved_at
			newest_slot = slot
	return newest_slot


static func delete(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(get_slot_path(slot))


## One line for the slot list, e.g. "Mi, 3. Frühling · Lv 4 · 250 Gold · Schmiede", or "" if empty.
static func get_summary(slot: int) -> String:
	var data: Dictionary = read(slot)
	if data.is_empty():
		return ""
	var day: int = int(data.get("day_cycle", {}).get("day", 1))
	var level: int = int(data.get("player", {}).get("level", 1))
	# the name of the map (map_names.json); "?" only for a save without a scene
	var place: String = ContentDB.map_name(str(data.get("scene", "")))
	if place.is_empty():
		place = "?"
	return Language.translate("%s · Lv %d · %d Gold · %s") % [GameCalendar.get_short_text(day), level, int(data.get("gold", 0)), place]


## Play time and when the slot was saved, e.g. "Spieldauer 3 h 05 min · 13.10.2026 14:05",
## or "" if empty. Saves from before the play time only show the date.
static func get_saved_at_text(slot: int) -> String:
	var data: Dictionary = read(slot)
	if data.is_empty():
		return ""
	var time: Dictionary = Time.get_datetime_dict_from_unix_time(
			int(data.get("saved_at", 0)) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	var date: String = "%02d.%02d.%d %02d:%02d" % [time.day, time.month, time.year, time.hour, time.minute]
	if not data.has("play_time"):
		return date
	return Language.translate("Spieldauer %s · %s") % [format_play_time(int(data["play_time"])), date]


## Seconds as "45 min" or "3 h 05 min".
static func format_play_time(seconds: int) -> String:
	var minutes: int = floori(seconds / 60.0)
	if minutes < 60:
		return Language.translate("%d min") % minutes
	return Language.translate("%d h %02d min") % [floori(minutes / 60.0), minutes % 60]


## Loads a resource by path; null (with a warning) if it no longer exists, so an old save
## with a deleted item does not crash the game.
static func load_resource(path: String) -> Resource:
	if path.is_empty() or not ResourceLoader.exists(path):
		if not path.is_empty():
			push_warning("Save refers to a missing resource: %s" % path)
		return null
	return load(path)
