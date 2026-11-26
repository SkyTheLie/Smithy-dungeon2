# Spiellogik aus allen Smithy-Spielen

Unter `assets/_reference/smithy_logik/` liegt der Code (`.gd`, `.tscn`, `.tres`, `.json`, `.md`) aller Smithy-Spiele, Stand 2026-11-26:

| Ordner | Spiel | Was drin ist |
|---|---|---|
| `smithy/` | Smithy (Hauptspiel, Repo `SkyTheLie/Smithy`) | **komplett**: Schmieden, Helden, Inventar, Händler, Story, Tränke … |
| `gambel_smithy/` | Smithy Gamba (`SkyTheLie/Smithy-Gamba`) | nur Dateien, die neu oder anders sind als in Smithy: Glücksschmiede (`scenes/gamba/`, `gamba_run.gd`, `gamba_sword.gd`), Verteidigung |
| `smithy_defense/` | Smithy Verteidigung | nur Abweichungen: `scenes/defense/`, `defense_run.gd` |
| `smithy_erfolge/` | Smithy Erfolge | nur Abweichungen: Erfolge, Wasser-Arena |
| `smithy_features/`, `smithy_kleidung/` | Smithy Feature-/Kleidungs-Branch | nur Abweichungen: Kleidung beim Schneider (`tailor.gd`) |
| `smithy_lan/` | Smithy LAN-Koop | nur Abweichungen: `scripts/core/net.gd`, `MULTIPLAYER_PLAN.md` |

Das Spiel selbst liegt **nicht** in diesem Ordner: Der Ordner hat eine `.gdignore`, Godot lädt ihn nicht (sonst gäbe es doppelte Klassennamen wie `Language`). Er ist eine **Bibliothek zum Nachschlagen und Übernehmen**. Wer ein System übernimmt, kopiert die Datei nach `scripts/` oder `scenes/`, passt sie an (kein `GameState`/`ContentDB` aus Smithy, Daten nach `data/`) und schreibt einen Test.

Alle Grafiken und Töne aller Smithy-Spiele liegen schon in `assets/` (Smithy-Satz + Kleider, Rucksack-Rahmen, Vorhang, vier Flaggen aus den Forks).

## Welche Idee braucht welche Datei

| Idee (`docs/IDEEN.md`) | Vorlage in `smithy_logik/smithy/` |
|---|---|
| Seltenheit R1–R8 mit Farben | `scripts/resources/rarity.gd` |
| Item-Rahmen, Tooltip, Inventar-Raster | `scenes/ui/inventory/item_slot.gd`, `item_tooltip.gd`, `inventory_grid.gd`, `scenes/ui/common/rich_tooltip.gd`, `hover_card.gd` |
| Inventar (Stapel, Plätze) | `scripts/systems/inventory.gd`, `scripts/resources/inventory_slot.gd` |
| Ausrüstung links (Figur mit Plätzen) | `scenes/ui/common/equipment_doll.gd`, `scenes/ui/heroes/hero_window.gd`; Vorlage-Bild `assets/_reference/vorlagen/helden_ansicht.png` |
| Händler, Ware, Preise | `scripts/systems/merchant_stock.gd`, `economy.gd`, `consignment_shop.gd`, `scenes/ui/menus/shop_dialog.gd`, `scenes/actors/merchant.gd` |
| Glücksspiel (Würfeln, Eimer, Spielautomat) | `gambel_smithy/scenes/gamba/gamba_buckets.gd`, `gamba_game.gd`; `scenes/ui/minigames/slot_machine.gd`, `shell_game.gd`, `higher_lower_menu.gd`, `scripts/systems/gambling_den.gd` |
| Dialoge, Story-Schritte | `scenes/ui/dialogue/dialogue_box.gd`, `scripts/systems/story.gd`, `story_actions.gd`, `scenes/actors/story_npc.gd`, `npc_acting.gd` |
| Erklärung mit Hervorhebung | `scripts/systems/guide.gd`, `scenes/ui/common/intro_help.gd` |
| Tränke | `scripts/resources/potion_data.gd`, `brew_data.gd` |
| Klassen freischalten | `scripts/systems/class_unlocks.gd`, `scripts/resources/hero_class.gd` |
| Zauberstab aufwerten, Relikt einsetzen | `scripts/systems/upgrading.gd`, `scripts/resources/upgrade_data.gd`, `socket.gd`, `socket_bonus.gd`, `scripts/systems/enchanting.gd`; Vorlage-Bild `assets/_reference/vorlagen/zauberstab_vorlage.png` |
| Schmiede-Minispiele | `scenes/ui/minigames/forging_minigame.gd`, `sharpening_minigame.gd`, `workbench_minigame.gd`, `riveting_minigame.gd`, `stirring_minigame.gd`, `timing_bar.gd`; `scripts/systems/forge_quality.gd`, `crafting.gd`, `joining.gd` |
| Gussformen, Materialstufen (Kupfer → Palladium) | `scripts/resources/recipe_data.gd`, `data/content/materials.json`, `docs/systeme/schmieden.md` |
| Dungeon-Beute | `scripts/systems/dungeon_rewards.gd`, `rare_drops.gd`, `scripts/resources/rare_drop_rule.gd` |
| Spielstand | `scripts/systems/save_system.gd`, `scripts/core/save_data.gd`; `gambel_smithy/scripts/systems/gamba_saves.gd` (kleiner, ein JSON) |
| Erfolge | `scripts/systems/achievements.gd` (+ `smithy_erfolge/`) |
| Koop | `smithy_lan/scripts/core/net.gd`, `smithy_lan/MULTIPLAYER_PLAN.md` |
