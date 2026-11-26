class_name DevTools
extends RefCounted
## The one switch for everything that only exists for testing: the admin panel (key P), free house
## levels at the builder, the button "Sofort" in dungeon fights, the frozen admin clock.
## On when the game runs from the Godot editor, and in an export whose preset has the custom
## feature TESTER_FEATURE (only the preset "Android Test"; the release presets "Smithy" and "Android"
## must never have it, assets/_reference/android/build_release.sh checks the Android one). Every place that asks this carries the marker "DEV-ONLY" in a comment, so
## `grep -rn "DEV-ONLY\|DevTools.enabled\|has_dev_tools"` lists what to look at before a release.

## Feature tag of runs from the Godot editor (exported games don't have it).
const FEATURE: String = "editor"
## Custom feature of a tester export (export_presets.cfg, "custom_features").
const TESTER_FEATURE: String = "dev_tools"
## settings.cfg section of the admin panel's switches (GameState.ADMIN_SECTION points here).
const ADMIN_SECTION: String = "admin"
## settings.cfg key of the admin switch "Knopf „Sofort“ in Dungeons" (tab Events).
const INSTANT_BUTTON_KEY: String = "instant_button"


static func enabled() -> bool:
	return OS.has_feature(FEATURE) or OS.has_feature(TESTER_FEATURE)


## DEV-ONLY: the dungeon board and the battle window show "Sofort" (Adventure.finish_instantly) while
## the admin switch is on; always off without the test tools, so never in a release export.
static func instant_button_on() -> bool:
	return enabled() and bool(WindowLayout.get_setting(ADMIN_SECTION, INSTANT_BUTTON_KEY, false))


static func set_instant_button_on(on: bool) -> void:
	WindowLayout.set_setting(ADMIN_SECTION, INSTANT_BUTTON_KEY, on)
