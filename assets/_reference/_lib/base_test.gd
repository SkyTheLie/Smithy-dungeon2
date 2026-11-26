extends SceneTree
## Base of headless tests (smaller version of the one in Smithy). A test is a file test_*.gd in
## assets/_reference/tests/ that starts with
##   extends "res://assets/_reference/_lib/base_test.gd"
## and overrides run(). It checks with check() / check_eq() and ends by itself: exit code 1 and
## "FAILED: n" if a check failed, else "ALL OK". Start tests only with assets/_reference/run_tests.sh
## (own empty user:// per test, German as language); started by hand this base refuses to run.

const TEST_DATA_MARK: String = "test_logs/userdata"

var failed: int = 0
var checks: int = 0


func _initialize() -> void:
	_boot.call_deferred()


func _boot() -> void:
	# One frame so the autoloads are in the tree and ready.
	await process_frame
	if not OS.get_user_data_dir().replace("\\", "/").contains(TEST_DATA_MARK):
		print("FAIL base_test: user:// is the real folder (%s). Start tests with run_tests.sh." % OS.get_user_data_dir())
		quit(1)
		return
	seed(1)
	TranslationServer.set_locale("de")
	await run()
	finish()


## The test itself: override it.
func run() -> void:
	pass


func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		print("FAIL ", text)


func check_eq(actual: Variant, expected: Variant, text: String) -> void:
	check(actual == expected, "%s: is %s, expected %s" % [text, str(actual), str(expected)])


## Waits (in game frames) until `condition` is true or `max_seconds` of game time passed.
func wait_until(condition: Callable, max_seconds: float) -> bool:
	var waited: float = 0.0
	while not condition.call():
		if waited >= max_seconds:
			return false
		await physics_frame
		waited += 1.0 / 60.0
	return true


## Loads a script by path (game classes are not known as types while a test compiles).
func script(path: String) -> Script:
	return load(path) as Script


func finish() -> void:
	if failed > 0:
		print("FAILED: %d of %d checks" % [failed, checks])
		quit(1)
	else:
		print("ALL OK (%d checks)" % checks)
		quit(0)
