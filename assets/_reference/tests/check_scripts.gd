extends "res://assets/_reference/_lib/base_test.gd"
## Compile check: loads every script and scene of the game; a parse error shows up as
## "SCRIPT ERROR" / "Parse Error" in the log and fails the run.

const FOLDERS: Array[String] = ["res://scripts", "res://scenes"]


func run() -> void:
	for folder: String in FOLDERS:
		_check_folder(folder)


func _check_folder(path: String) -> void:
	for file: String in ResourceLoader.list_directory(path):
		if file.ends_with("/"):
			_check_folder(path.path_join(file.trim_suffix("/")))
		elif file.get_extension() in ["gd", "tscn"]:
			var resource: Resource = load(path.path_join(file))
			check(resource != null, "loads: " + path.path_join(file))
			if resource is GDScript:
				check((resource as GDScript).can_instantiate(), "compiles: " + path.path_join(file))
