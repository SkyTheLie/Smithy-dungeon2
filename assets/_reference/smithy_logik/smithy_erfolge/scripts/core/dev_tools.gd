class_name DevTools
extends RefCounted
## The one switch for everything that only exists for testing: the admin panel (key P), free house
## levels at the builder, the button "Sofort" in dungeon fights, the frozen admin clock.
## On only when the game runs from the Godot editor, never in an exported game (also not in a debug
## export for testers). Every place that asks this carries the marker "DEV-ONLY" in a comment, so
## `grep -rn "DEV-ONLY\|DevTools.enabled\|has_dev_tools"` lists what to look at before a release.

## Feature tag of runs from the Godot editor (exported games don't have it).
const FEATURE: String = "editor"


static func enabled() -> bool:
	return OS.has_feature(FEATURE)
