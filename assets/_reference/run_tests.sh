#!/usr/bin/env bash
# Runs the headless tests (assets/_reference/tests/test_*.gd) and prints a short summary.
#
# Usage (from the project folder, Git Bash):
#   bash assets/_reference/run_tests.sh                    # all tests (there are few, they are fast)
#   bash assets/_reference/run_tests.sh test_floor_layout  # tests whose name contains this
# Options:  -v  show the full output of failed tests
#
# Before the tests a compile check loads every script (tests/check_scripts.gd).
# Every test gets its own empty user:// (.godot/test_logs/userdata/<test>/, via APPDATA) with German
# as language, so tests never touch the real settings. Godot runs with --fixed-fps 60.
# Logs: .godot/test_logs/ (not in git).

set -u
shopt -s nullglob
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 2
REF="assets/_reference"
LOGS="$ROOT/.godot/test_logs"
APP="Smithy Dungeon 2"
VERBOSE=0
FILTER=()
for arg in "$@"; do
	case "$arg" in
		-v) VERBOSE=1 ;;
		*) FILTER+=("$arg") ;;
	esac
done

GODOT="${GODOT:-$(ls -1 "$ROOT"/../Godot_v*_console.exe 2>/dev/null | sort -V | tail -n 1)}"
if [ -z "$GODOT" ]; then
	echo "Godot console exe not found (next to the project folder, or set GODOT=...)."
	exit 2
fi
mkdir -p "$LOGS"

run_one() {
	local test="$1" name key data log code
	name="$(basename "$test" .gd)"
	key="$name"
	data="$LOGS/userdata/$key"
	log="$LOGS/$key.log"
	rm -rf "$data"
	mkdir -p "$data/Godot/app_userdata/$APP"
	{ echo '[language]'; echo; echo 'locale="de"'; } >"$data/Godot/app_userdata/$APP/settings.cfg"
	APPDATA="$(cygpath -w "$data" 2>/dev/null || echo "$data")" timeout 180 "$GODOT" --headless --fixed-fps 60 --path "$ROOT" -s "res://$test" >"$log" 2>&1
	code=$?
	if [ $code -eq 0 ] && grep -qE '^\s*FAIL|SCRIPT ERROR|Parse Error|Failed to load script' "$log"; then
		code=1
	fi
	if [ $code -eq 0 ]; then
		echo "  ok    $name"
	else
		echo "  FAIL  $name (exit $code, log: .godot/test_logs/$key.log)"
		if [ $VERBOSE -eq 1 ]; then sed 's/^/        /' "$log"; else grep -E 'FAIL|ERROR' "$log" | head -n 15 | sed 's/^/        /'; fi
	fi
	return $code
}

TESTS=("$REF/tests/check_scripts.gd")
for file in "$REF"/tests/test_*.gd; do
	name="$(basename "$file" .gd)"
	if [ ${#FILTER[@]} -eq 0 ]; then
		TESTS+=("$file")
	else
		for f in "${FILTER[@]}"; do
			case "$name" in *"$f"*) TESTS+=("$file"); break ;; esac
		done
	fi
done

FAILS=0
echo "Tests (${#TESTS[@]}):"
for test in "${TESTS[@]}"; do
	run_one "$test" || FAILS=$((FAILS + 1))
done
if [ $FAILS -eq 0 ]; then
	echo "ALL OK"
else
	echo "$FAILS failed"
	exit 1
fi
