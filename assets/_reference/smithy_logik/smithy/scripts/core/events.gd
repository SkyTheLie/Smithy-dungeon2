extends Node
## Event bus (autoload "Events"): signals that only ask a window or a scene to do something
## (open a map, show a message, play a cutscene part). Game state and its change signals stay in
## GameState; everything here carries no state and is not saved.

## Someone (e.g. the dungeon board) wants the battle window to show this adventure.
@warning_ignore("unused_signal")
signal adventure_view_requested(adventure: Adventure)
## Big banner in the upper third of the screen (HUD, RewardBanner), e.g. "Sieg!" after a smith
## tournament. Texts already translated.
@warning_ignore("unused_signal")
signal banner_requested(title: String, subtitle: String)
## Short message for the HUD (e.g. "Die Tür ist verschlossen.").
@warning_ignore("unused_signal")
signal message_requested(text: String)
## Story action "open_menu:<name>": a story figure should open its window (e.g. "house" = the
## builder's HouseMenu, see BuilderNpc).
@warning_ignore("unused_signal")
signal story_menu_requested(menu: String)
## Story action "cutscene:<id>": something in the scene plays by itself during a dialogue (e.g.
## "goblin_throw": the goblins throw one of theirs off the king's platform, GoblinThroneCutscene).
@warning_ignore("unused_signal")
signal cutscene_requested(cutscene_id: String)
## Opens the crystal map window (right click on the map in the inventory, see ItemSlotUI).
@warning_ignore("unused_signal")
signal crystal_map_requested
## The desert compass was used (right click in the inventory): show or hide it (CompassOverlay).
@warning_ignore("unused_signal")
signal compass_requested
## The sand map was used (right click in the inventory): open or close it (DesertMapWindow).
@warning_ignore("unused_signal")
signal desert_map_requested
## Fürst Ssarok's map of the storm paths was used (right click): open or close it (StormMapWindow).
@warning_ignore("unused_signal")
signal storm_map_requested
## Opens the recipe book at a tab (e.g. right click on Aurelius' book, see ItemSlot).
@warning_ignore("unused_signal")
signal recipe_book_requested(tab_name: String)
## The recipe book on the nightstand (RecipeBookStand): E opens / closes it, walking away closes it.
@warning_ignore("unused_signal")
signal recipe_book_toggle_requested
@warning_ignore("unused_signal")
signal recipe_book_close_requested
## Hand-in slots appeared (HandInSlots): the HUD opens the inventory so items can be dragged in.
@warning_ignore("unused_signal")
signal inventory_open_requested
## The window that asked for the inventory closed (shops, StationMenu.opens_inventory): the HUD
## closes it again if it opened it for that window and the player didn't pin it.
@warning_ignore("unused_signal")
signal inventory_close_requested
## Open the lexicon (key L) at an entry: "enemy:<id>", "item:<id>" or "" (just the window), see
## open_lexicon.
@warning_ignore("unused_signal")
signal lexicon_requested(link: String)
## A lucky strike at the workbench (ForgeQuality.try_lucky_strike): "rarity" (two tiers up) or
## "socket" (an extra socket). The next piece ItemReveal shows gets the lightning and its banner.
@warning_ignore("unused_signal")
signal lucky_strike_struck(kind: String)
## The player's look changed (tailor: other clothes or colour): the player figure bakes its sheets anew.
@warning_ignore("unused_signal")
signal player_look_changed
