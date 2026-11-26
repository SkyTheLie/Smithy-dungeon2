# Prüfbericht: Architektur, Code, Tests, Arbeitsweise (2026-11-12)

Einmalige Prüfung des ganzen Projekts (ca. 55.000 Zeilen Spielcode, 317 Tests, 28 JSON-Dateien, Doku).
Es wurde nur gelesen, am Spiel ist nichts geändert. Zeilennummern: Stand Branch `fix/schmiede-ruckler`, 12.11.2026.

- **bestätigt** = im Code nachgelesen. **vermutet** = aus dem Code hergeleitet, Wirkung im Spiel nicht ausprobiert.
- Die Regeln, die sich daraus ergeben, stehen kurz in `docs/FEHLERKLASSEN.md` (wird jeder KI-Sitzung mitgegeben).
- Erledigte Punkte hier abhaken oder löschen; wer einen Punkt angeht, legt wie üblich einen Branch an.

---

## 1. Kurzfassung

Das Spiel ist für seine Größe ordentlich gebaut: Inhalte liegen als Daten vor, der Kampf ist reine Logik ohne Oberfläche, Speichern ist absturzsicher, die Daten sind in sich stimmig (0 kaputte Verweise in story.json, 0 fehlende Bildpfade). Die Schwächen liegen an vier Stellen:

1. **Speichern/Laden ist nicht abgesichert.** Mehrere Zustände werden nicht mitgespeichert, und es gibt keinen Test, der „speichern » laden » vergleichen“ prüft.
2. **Die Tests laufen auf den echten Spielständen und Einstellungen** des Rechners. Das erklärt die falschen Fehlschläge wegen der Sprache und kann den echten Autosave überschreiben.
3. **`GameState` ist zu groß** (2.800 Zeilen, ca. 170 Funktionen) und Spielregeln stecken zum Teil in Fenster-Skripten. Das macht Änderungen riskant und schwer testbar.
4. **Wiederkehrende Fehler werden nicht als Regel festgehalten.** 113 `fix/`-Branches fallen in etwa 10 Fehlerklassen (Abschnitt 8).

---

## 2. Zuerst beheben (echte Fehler, Datenverlust)

| # | Was | Wo | Stand |
|---|---|---|---|
| 1 | **Tests überschreiben echte Daten.** Es gibt kein eigenes `user://` für Tests. 11 Tests schlafen (`GameState.sleep()` » Autosave) und überschreiben damit `autosave.json` des Entwicklers; Admin-Panel- und Quest-Tracker-Tests schreiben in `settings.cfg`. Bei `-j 4` teilen sich vier Godot-Prozesse dieselben Dateien. | `game_state.gd:576`, z. B. `elves/test_part3_story.gd:51` | bestätigt |
| 2 | ✅ erledigt 13.11. **„Hauptmenü“ fragt nur auf Deutsch nach.** Der Knopf vergleicht seinen übersetzten Text mit dem deutschen Wort. In jeder anderen Sprache führt der erste Klick sofort ins Hauptmenü, Ungespeichertes ist weg. Lösung: eine Variable `_confirming` statt Textvergleich. | `hud.gd:490` | bestätigt |
| 3 | ✅ erledigt 13.11. **Bosskampf wird unvollständig gespeichert.** `phase`, `summons_done`, `used_once` und `_boss_ingot_rolled` fehlen im Spielstand. Nach dem Laden: Boss wieder in Phase 0 mit vollen Balken, alle Helfer-Wellen kommen auf einmal, Einmal-Skills sind wieder frei, im schweren Modus ein zweiter Barren. | `adventure.gd:1071-1143`, `combatant.gd:113/129` | bestätigt |
| 4 | ✅ erledigt 13.11. **Laden während eines Heldenturnier-Kampfs blockiert das Turnier.** `hero_tournament.reset()` kehrt bei laufendem Duell sofort zurück; das Duell selbst wird nicht gespeichert. Das Turnier bleibt für immer auf „kämpft“. Lösung: `reset(force)` beim Laden. | `game_state.gd:2779`, `hero_tournament.gd:111-113` | bestätigt |
| 5 | ✅ erledigt 13.11. (Esc und X bleiben wirkungslos, solange der Dialog noch etwas ausführen muss) **Esc schließt einen Dialog mitten in einer Cutscene.** `DialogueBox` erbt das Esc-Verhalten von `StationMenu` und hat keine eigene Prüfung. `on_end` wird übersprungen, Schleifen der Cutscene laufen weiter, Flags sind halb gesetzt. | `station_menu.gd:87-92`, `dialogue_box.gd` | Mechanik bestätigt, Folgen vermutet |
| 6 | ✅ erledigt 13.11. (`GameState.is_cutscene_running`) **F5 speichert mitten in Cutscenes.** `save_game` sperrt nur während des Schmiedeturniers. Gespeichert wird die Position mitten im automatischen Laufen (das durch Wände und Wasser geht). | `game_state.gd:2563-2569` | Sperre bestätigt, Feststecken vermutet |
| 7 | ✅ erledigt 13.11. **Der Autosave im Bett ignoriert die Turnier-Sperre.** `save_game` sperrt, `_autosave_in_bed` nicht. Während des Turniers liegt das echte Inventar nur im Speicher. | `game_state.gd:2582-2586` | Code bestätigt, ob erreichbar: vermutet |
| 8 | ✅ erledigt 13.11. (Platz-Art wird mitgespeichert, Überzähliges kommt in die Loot-Kiste) **Ninas Laden speichert nach Platznummer.** Ändert sich die Platzzahl in der JSON, landet Ware auf dem falschen Platz oder geht still verloren. Lösung: Platz-Art mitspeichern, Überzähliges in die Loot-Kiste. | `consignment_shop.gd:283-292` | bestätigt |
| 9 | ✅ erledigt 13.11. **Wartende Tipps gehen beim Speichern verloren.** Ein Tipp gilt sofort als „gezeigt“, die Warteschlange `pending_hints` wird aber nicht gespeichert. | `story.gd:168-169, 362, 391` | bestätigt |
| 10 | ✅ erledigt 13.11. (`extract_po.py` + `translate_agy.py` für en/es/fr/zh, alle 8.948 Texte gefüllt, nicht gegengelesen) **23 Story-Texte von heute fehlen in allen `.po`-Dateien** (großer Rat, Lottes Brief). `extract_po.py` wurde nicht ausgeführt. Dazu 67 bis 70 leere Übersetzungen je Sprache. | `locale/*.po` | bestätigt |
| 11 | ✅ erledigt 13.11. (`exclude_filter` gesetzt, noch nicht per Export geprüft) **Export packt zu viel ein.** `exclude_filter` ist leer: `docs/karten_uebersicht/` (15 MB), die Bilder im Projektstamm (auch zwei WhatsApp-Fotos) und `opencode.json` landen im Spiel. | `export_presets.cfg:11-13` | bestätigt |
| 12 | ✅ erledigt 13.11. (`DevTools.enabled()`, Marker `DEV-ONLY`) **Test-Funktionen haben zwei verschiedene Schalter.** Admin-Panel: `OS.has_feature("editor")`. Knopf „Sofort“: `OS.is_debug_build()`, er wäre also in einem Debug-Export sichtbar. Lösung: eine Abfrage `GameState.has_dev_tools()` für alles, Marker `# DEV-ONLY`. | `game_state.gd:413`, `adventure.gd:1032`, `dungeon_board_menu.gd:499`, `battle_window.gd:77/122` | bestätigt |

Kleinere bestätigte Fehler:

- Bei einer Niederlage steht „Keine Belohnung“, obwohl es Beute und Erfahrung gibt (`battle_window.gd:402-406`, `game_state.gd:2243`).
- ✅ erledigt 13.11.: `spend_gold` mit negativem Betrag schenkt Gold, `Inventory` nimmt Mengen ≤ 0 an (`game_state.gd:1969`, `inventory.gd:22-53`).
- ✅ erledigt 13.11.: `jewelry.gd:145` greift ohne Prüfung auf `STATS[stat]` zu: unbekannte ID aus der JSON = Absturz.
- ✅ erledigt 13.11.: `adventure.gd:907`: `every = 0` in der JSON teilt durch 0.
- Legierung mit mehr als 1 Stück je Zutat ließe ein Stück gratis entstehen (`alloy_smelter.gd:63-84`); heute sind alle 1:1, also noch kein Fehler im Spiel.
- Kein angreifbarer Gegner (z. B. alle verschleiert): der Kämpfer tut gar nichts mehr, auch kein Heilen (`adventure.gd:254`).
- Erz und Felsen hören auf E ohne die übliche Prüfung „bin ich das nächste Objekt“ (`ore_rock.gd:58`, `hard_boulder.gd:41`) (vermutet: E im Dialog schlägt zugleich zu).
- Figuren bleiben nach einem Cutscene-Weg bis zum Szenenwechsel durchlaufbar (`story_cutscene.gd:69-71`).
- `Guide.is_target()` setzt Tutorial-Flags beim bloßen Abfragen (`guide.gd:141-146`): ob ein Tutorial startet, hängt davon ab, ob gerade ein Rahmen im Bild fragt.
- ✅ erledigt 13.11. (werden jetzt gespeichert und zurückgesetzt): Nach „Neues Spiel“ aus dem Hauptmenü bleiben `last_donation`, `last_shop_payout` und `quencher_returns_when_cool` vom alten Spiel stehen (fehlen in `_apply_save_data`).

---

## 3. Architektur

### 3.1 GameState ist zu groß

`scripts/core/game_state.gd`: 2.800 Zeilen, ca. 170 Funktionen, 30 Signale. 220 von 355 Skripten greifen darauf zu (1.566 Stellen). Es enthält neben dem Zustand auch ganze Regelwerke.

Vorschlag (schrittweise, je ein Branch, Verhalten bleibt gleich; GameState behält dünne Weiterleitungen):

| Auslagern nach | Inhalt heute in GameState | Zeilen ca. |
|---|---|---|
| ✅ 13.11. `StoryActions` (`scripts/systems/story_actions.gd`, `GameState.run_story_action` leitet weiter) | `run_story_action`, `_run_single_story_action`, `_run_special_story_action`, Reisen der Story | 1483-1706 |
| ✅ 13.11. `QuestItems` (`scripts/systems/quest_items.gd`, `GameState.quest_items`, alte Namen leiten weiter) | Abgeben, Sets, `has_items`/`take_items`, Hand-in-Slots, Einkaufsliste | 940-1320 |
| ✅ 13.11. `ForgeFire` (`scripts/systems/forge_fire.gd`, GameState leitet die alten Namen weiter, Test `forge/test_forge_fire.gd`) | Esse: `forge_heat`, `forge_fuel`, Nachlegen (heute dritte Kopie der Brennstoff-Logik neben Schmelze und Phiolen) | 2442-2556 |
| ✅ 13.11. `DungeonRewards` (`scripts/systems/dungeon_rewards.gd`, `give(victory, adventure)`) | `_on_adventure_finished`, `_give_defeat_rewards` | 2180-2263 |
| ✅ 13.11. `SaveData` (`scripts/core/save_data.gd`: `collect()`, `apply()`; GameState leitet weiter) | `_collect_save_data`, `_apply_save_data`, alle Umwandlungen alter Spielstände | 2617-2811 |

### 3.2 Speichern/Laden

Gut: Temp-Datei und Umbenennen, Versionsnummer, IDs statt Pfade, alte Spielstände werden umgewandelt.

Schwach:
- Umwandlungen alter Spielstände hängen an „Feld fehlt“ (`if not data.has(...)`) und sind über `_apply_save_data` verstreut, dazu drei Tabellen in story.json (`renamed_steps`, `legacy_recipes`, `implied_flags`). `FORMAT_VERSION` steht seit langem auf 2. Besser: pro Formatänderung die Version erhöhen und eine Funktion `_migrate(data, von_version)`.
- Quests werden über ihren Dateipfad gespeichert (`quest_states`), Szenen ebenso: Umbenennen einer Datei verliert den Stand.
- ✅ seit 13.11.: `_lib/test_save_roundtrip.gd` (speichern » alles zurücksetzen » laden » speichern, beide Dateien müssen gleich sein). Läuft in der Gruppe `kern` bei jeder Änderung an Kern-Dateien mit.
- `SaveSystem.SCENE_NAMES` kennt nur 18 Szenen, alle anderen zeigen im Lade-Fenster „?“ (`save_system.gd:18-37`).
- ✅ erledigt 13.11. (`start_adventure(..., restored)`): Laden startet Abenteuer über `start_adventure()`, das `adventure_started` sendet und `story_event` auslöst (`game_state.gd:2800`) (Wirkung vermutet). Besser eine eigene Funktion ohne Nebenwirkungen.

### 3.3 Spielregeln in Fenster-Skripten

Nicht ohne Oberfläche testbar, nicht wiederverwendbar:
- `assembly_menu.gd:531-566` (Zusammenbauen, Meisterwerk, EXP, Erfolge), `:924-960` (Brauen), `:1029-1051` (Verzaubern)
- `crafting_menu.gd:287-291` (EXP, Erfolge)
- `shop_dialog.gd:256-450` (Kaufen, Verkaufen, Rückkauf, Tagesbestand); `merchant_stock.gd:154` ruft umgekehrt die private UI-Methode `ShopDialog._is_unlocked` auf
- `hero_window.gd:432-605` (Ausrüsten, Zweihänder, Köcher, Tränke); dort fehlt auch die Prüfung, ob der Held gerade im Dungeon ist (vermutet)

Vorschlag: `Assembly.assemble()`, `Shop.buy()/sell()`, `HeroEquipment` in `scripts/systems`; das Fenster ruft nur auf und zeigt an.

### 3.4 Drei Wege zu GameState

- direkt (`GameState.x`), über übergebene Funktionen (`customers.gd:35-46`), und achtmal kopiert als untypisiertes `get_node("GameState")` (`forge_quality.gd:24`, `tournament_ranking.gd:389`, `story.gd:204/295`, `hero.gd:191/441`, `hero_tournament.gd:308`, DesertMaze, IceWall, StormTemple, GoblinKey). An diesen Stellen prüft Godot keine Typen, und ohne GameState stürzt es ab.
- Vorschlag: ein typisierter Zugang an einer Stelle; reine Logik (Story, Hero) bekommt Werte übergeben oder sendet ein Signal (`leveled_up`).

### 3.5 Story als freie Texte

- Story-Aktionen (`"give_items:..."`), Schritte und Flags sind freie Strings. `story.advance("tippfehler")` führt still zu einem leeren Schritt, die Story hängt. Rund 45 Flags werden dynamisch zusammengebaut (`"teleporter_%s_built"`).
- Der aktuelle Stand ist sauber (geprüft: 157 Cutscene-IDs, 237 Flags, 189 Spawnpunkte, 610 Dialoge). `story_anims/check_beats.py` prüft einen Teil, läuft aber nicht automatisch.
- ✅ erledigt 13.11. (ohne Flags): `push_error` bei unbekanntem Schritt in `advance`; Test `_lib/test_story_data.gd` prüft alle Aktionen und Schritte der story.json gegen den Code und läuft in der Gruppe `kern` mit.

### 3.6 Cutscenes

- `story_cutscene.gd` ist ein guter Baukasten (geschütztes `wait()`, Laufen mit Abbruch-Marke), wird aber nur von 14 Skripten benutzt. Rund 19 bauen alles selbst (`throne_duel_cutscene.gd`, `elf_attack_cutscene.gd`, `kerker_forge_cutscene.gd`, `ice_wall_cutscene.gd`, …): `_walk_npc` 4× kopiert ohne Abbruch-Marke, `_shake` 5×, `_flash` 3×, 75 rohe `await get_tree().create_timer(...)` ohne Schutz gegen Szenenwechsel (`throne_duel_cutscene.gd:237/241`).
- Vier verschiedene Arten, den Spieler zu sperren (Dialog, `set_physics_process(false)`, Auto-Lauf auf der Stelle, normaler Auto-Lauf), kein gemeinsames Entsperren. Vorschlag: `Player.lock(grund)` / `unlock(grund)`, bei Szenenwechsel geleert.
- Dauer doppelt gepflegt: `hide_for` in story.json muss von Hand zur Dauer im Code passen. Besser: die Cutscene meldet „fertig“.
- Start hängt an der Reihenfolge von `call_deferred` und Knoten (`elf_attack_cutscene.gd:90-97`) (vermutet). Sicherer: zusätzlich auf `story.step_started` hören wie `festival_show.gd:95`.
- Zwei Reisen können sich überlagern: `travel_to` hat keinen Schutz während einer Überblendung (`game_state.gd:516-541`) (vermutet).
- Timer laufen in der Pause weiter, Tweens nicht (`dialogue_box.gd:148`): `create_timer(t, false)` verwenden.

### 3.7 Doppelte Listen und Werte

- Passive Fähigkeiten in zwei Listen (`combatant.gd:402-408`, `skill_data.gd:173`): fehlt eine neue in der ersten, wirkt sie im Kampf still nicht.
- Standardwerte widersprechen sich: `heal_power_per_wis` 0.005 (`combat_rules.gd:73`) gegen 0.01 (`skill_data.gd:523`), JSON sagt 0.003; `damage_per_str` 1 gegen 0.5. Heute ohne Wirkung, weil die JSON den Wert liefert.
- `estimate_skill` (`combatant.gd:794-877`) rechnet die Trefferformel ein zweites Mal nach.
- `InventorySlot`: 18 Felder, sechsmal von Hand aufgelistet (`inventory_slot.gd:74-176, 688-768`). Ein neues Feld muss an sechs Stellen eingetragen werden.
- Schmuck: `STATS` und `STAT_NAMES` doppelt (`jewelry.gd:14-49`). Gleicher Code in den Stationen („erst abkühlen“ 4×, „ein Stück verbrauchen“ 5×).
- Feste IDs und Zahlen im Code: `"coal"`, `"copper"`, `"wood"`, Namensregel `"mold_"` an vier Stellen, Turnier-Zahlen (`hero_tournament.gd:251`), `WEAPON_CLASS` (`battle_stage.gd:47-57`).

### 3.8 Weitere Punkte

- **Zustand in `static var`:** `hero_tournament.gd:40-42`, `smith_tournament.gd:61-65` (`venue`, `league`). Wird nicht gespeichert und nicht bei „Neues Spiel“ zurückgesetzt.
- **Caches überleben `ContentDB.reload()`:** `economy.gd:32`; `guild_level.gd:12-21` und `hero_offers.gd:98` lesen JSON an ContentDB vorbei. Wichtig für Tests, die die Sprache umstellen.
- **`Language.translate` auf Namen von Knoten und Typen:** `game_state.gd:385` („SteamBridge“), `story_prop.gd:42`, `story_hider.gd:33`, `sneak_zone.gd:25`, `house_editor.gd:367/410` („Door“), `elf_lift.gd:48`, `admin_panel.gd:467/669`. Übersetzt die KI „Door“ einmal zu „Puerta“, findet der Raum-Designer keine Türen mehr.
- **Deutsche Texte ohne Übersetzung** (das Spiel läuft auf Englisch): `battle_window.gd:164/340/343/363-369`, `hero_window.gd:105/387`, `skill_data.gd:366/439`, `hud.gd:610/629/729`, `assembly_menu.gd:870`, `game_state.gd:731/750`, `enchanting.gd:325`, `customers.gd:165`, `smith_tournament.gd:475`, `game_calendar.gd:73/88`, `water_arena.gd:75`. `skill_data.gd:546` setzt immer ein deutsches Komma.
- **JSON und `.tres` gemischt:** Aufträge in `data/quests/*.tres` und als `side_tasks` in JSON; Heldenklassen auf fünf Dateien verteilt; Teleporter-Ziel als `.tres`, Position in JSON; `data/rocks/` enthält auch Pflanzen und Bäume.
- **story.json: 707 KB in einer Datei**, 51 Commits in 7 Tagen, also bei zwei Entwicklern die wahrscheinlichste Konflikt-Datei. Vorschlag: Ordner `data/content/story/` (Schritte je Teil, Dialoge je Gebiet, Tipps, Figuren, Umwandlungs-Tabellen), ContentDB fügt zusammen.
- **Admin-Panel wird in jeder Szene gebaut**, auch im fertigen Spiel (`hud.gd:27/63/146`); nur die Taste ist gesperrt. Es liest dabei jede Karten-Datei als Text und baut alle Item-Einträge. Besser erst beim ersten Druck auf P laden (Ladezeit vermutet).
- **Tastennamen** zeigen die US-Belegung (`key_bindings.gd:90`), auf einer französischen Tastatur also falsche Buchstaben (vermutet).

---

## 4. Performance

Gleiches Muster wie der gerade behobene Schmiede-Ruckler: **Fenster bauen sich neu auf, obwohl sie zu sind.**

| Wo | Was |
|---|---|
| ✅ 13.11. `crafting_menu.gd:86/111/112` | Neuaufbau bei jeder Inventar-, Kisten- und Hitze-Änderung, für jeden Amboss und jede Esse der Szene |
| ✅ 13.11. `quest_detail_window.gd:24-27`, `quest_log_window.gd:31-34` | Neuaufbau bei jeder Inventar-Änderung, auch geschlossen |
| ✅ 13.11. `dungeon_board_menu.gd:80-82` | Neuaufbau bei `heroes_changed` (kommt jede Spielstunde) |
| ✅ 13.11. `hero_window.gd:143/380` | kompletter Neuaufbau bei jedem verschossenen Pfeil und jeder Kill-EXP, auch versteckt |
| ✅ 13.11. `assembly_menu.gd:491-509` | Werkbank: pro Teil ein `inventory.changed`, das alle obigen Fenster auslöst |
| ✅ 13.11. `shop_dialog.gd:65/272/384` | doppelter Neuaufbau pro Kauf (auch Raum-Designer, Werkstatt-Upgrades, Haus-Menü) |
| ✅ 13.11. `tournament_menu.gd:43-45`, `planter_menu.gd:53-55` | kompletter Neuaufbau in jedem Frame |
| ✅ 13.11. `compass_overlay.gd:73-133` | durchsucht alle 0,5 s die ganze Karte, auch ohne Kompass |
| ✅ 13.11. `battle_stage.gd:652-668, 797-887, 954-961` | pro Frame: Positionen mehrfach berechnet, Helden-Aussehen neu abgeleitet (mit `JSON.stringify`), neues `AtlasTexture` je Gegner (`enemy_data.gd:175`) |
| `game_state.gd:504-511` | Schlafen/Kutsche rechnet die Nacht in 0,1-s-Schritten nach (8.640 Durchläufe je Tag) (Ruckler vermutet) |
| ✅ 13.11. `window_layout.gd:43-45` | jeder Regler-Schritt schreibt `settings.cfg` auf die Platte |
| ✅ 13.11. `economy.gd:207-211`, `customers.gd:313`, `merchant_stock.gd:275/299` | lineare Suche über alle Rezepte/Items statt Zugriff per ID |

Vorlage für die Lösung gibt es schon im Projekt: `character_window._refresh_if_visible` (`:113`) und `heroes_window.gd:55-59` (gesammelt per `call_deferred`). Für Serien von Inventar-Änderungen gibt es seit 13.11. `Inventory.begin_batch()/end_batch()`, für mehrere Signale pro Aktion `StationMenu._queue_refresh()`.

Nicht dringend: `GuideFrame` läuft in hunderten Knoten pro Frame, prüft aber nur bei sichtbarem Ziel und schon gestaffelt (`guide_frame.gd:35-49`).

---

## 5. Was gut ist und so bleiben soll

- **Kampf als reine Logik:** `Adventure` läuft ohne Oberfläche, `BattleStage` zeigt nur an und hängt nur über Signale daran. Formeln stehen in `CombatRules`, Werte in `combat.json`.
- **Daten sind stimmig:** ContentDB prüft beim Laden mit 99 Fehlermeldungen; alle Verweise in story.json, alle Bildpfade (auch Groß-/Kleinschreibung) und alle Platzhalter der vier Sprachen stimmen.
- **Speichern** mit Temp-Datei, Version und IDs; alte Spielstände laden weiter.
- **Fenster:** alle 37 Stationsfenster nutzen `StationMenu`, `WindowTitleBar` regelt Ziehen und Anpinnen, `RecipeBrowser` wird geteilt, das HUD trennt seine Signale beim Verlassen.
- **Welt:** alle 100 Karten haben Kamera-Grenzen an allen vier Seiten; Spieler-Platzierung läuft zentral über `next_spawn_point`.
- **Tests:** jeder Test läuft in einem eigenen Godot-Prozess, `run_tests.sh` ist kompakt, mit Kompilier-Check vorab.
- **Code-Stil:** durchgehend typisiert (0 untypisierte `var x = ...`), englische Bezeichner, fast jede Funktion kommentiert.

---

## 6. Tests

317 Tests in `assets/_reference/`, alle `extends SceneTree`.

**Probleme**

1. **Echte Daten** (Abschnitt 2, Punkt 1). Lösung an einer Stelle: `run_tests.sh` gibt jedem Test ein eigenes Datenverzeichnis (unter Windows z. B. `APPDATA=<ordner je Test>` vor dem Godot-Aufruf; mit einem Lauf prüfen, ob `user://` dem folgt) und legt dort eine feste `settings.cfg` mit `locale="de"` ab. Damit sind Sprache, eingefrorene Admin-Uhr (wirkt heute in 36 Tests) und parallele Läufe auf einmal gelöst, und die Sicherungs-Bastelei in 6 Tests kann weg.
2. **Sprache:** `Language.get_current()` liest die echte `settings.cfg`, sonst die Systemsprache. Nur 15 von 317 Tests stellen Deutsch ein, 5 davon ohne `ContentDB.reload()`. Etwa 21 Tests vergleichen deutsche Texte ohne die Sprache festzulegen (vermutet), z. B. `hud/test_toasts.gd`, `lexicon/test_lexicon.gd`.
3. **35 Tests prüfen nichts** (kein FAIL, kein `quit(1)`), z. B. fast alle in `playtest/`, `residents/`, `characters/`, `festival/`. Weitere 53 enden immer mit Exit 0 und fallen nur auf, weil das Skript nach „FAIL“ sucht.
4. **Die Auswahl „passend zu den Änderungen“ findet bei `game_state.gd` 0 Tests** (kein `class_name`, kein Test nennt den Pfad), obwohl 238 Tests GameState benutzen. Gleiches gilt für mehrere JSON-Dateien, gelöschte Dateien, `locale/*.po`, `project.godot`. Lösung: feste Zuordnung (Kern-Dateien » Gruppen), und das Wort `GameState` im Test als Treffer werten.
5. **Wiederholung verdeckt Wackel-Tests:** ein Fehlschlag wird einmal allein wiederholt und zählt dann still als „ok“. Ein „bekannt kaputter“ Test, der wieder grün ist, wird nicht gemeldet. `docs/PROBLEME.md:118/120` nennt zwei rote Tests, die in `test_known_failures.txt` fehlen.
6. **Zufall ohne Seed:** 31 Tests lassen Kämpfe laufen, keiner setzt einen Seed; 12 Systeme nutzen das globale `randf`. 29 Tests warten feste Sekunden (bis 8 s).
7. **163 Tests greifen auf private Felder zu** (1.135 Stellen). Jeder Umbau im Spiel bricht Tests. Genau das zeigten die heutigen Reparaturen: ein Test hing an `hud._toast_queue`, einer an einem festen Ordner, einer war seit einer Entscheidung vom 25.10. rot und stand einfach auf der Liste.
8. **Jeder Test kopiert sein Gerüst:** `_check` 252× in 8 Varianten, 5 Namen für den Fehlerzähler, 6 Formen der Zusammenfassung, kein gemeinsames „neues Spiel“.

**Lücken in der Abdeckung**

- **SaveSystem: kein einziger Test schreibt und liest.** Kein Vergleich „Spielstand » JSON » Spielstand“, kein Test für alte Formate.
- Ohne Test: `ConsignmentShop`, `ResourceFields`, `ClassUnlocks`, `SkillCommand`, `DisplaySettings`, `AudioManager`. Kein eigener Test für `Inventory` (Stapeln, volle Tasche).
- 8 Test-Ordner passen in keine Gruppe (`paladin_battle`, `grand_council`, `martyr`, `loot_chest`, …) und laufen mit `kampf`/`story` nicht mit.

**Vorschlag: gemeinsame Basis** `assets/_reference/_lib/base_test.gd` (Name ohne `test_`, damit sie nicht als Test zählt):

```gdscript
extends SceneTree
var failed: int = 0
var gs: Node

func _initialize() -> void:
	_boot.call_deferred()

func _boot() -> void:
	await process_frame            # autoloads are ready
	seed(1)
	gs = root.get_node("GameState")
	use_german()
	gs.in_main_menu = false
	await run()
	finish()

func run() -> void:                # override in the test
	pass

func check(ok: bool, text: String) -> void:
	if not ok:
		failed += 1
		print("FAIL ", text)

func check_eq(actual: Variant, expected: Variant, text: String) -> void:
	check(actual == expected, "%s: is %s, expected %s" % [text, actual, expected])

func use_german() -> void:
	TranslationServer.set_locale("de")
	load("res://scripts/core/content_db.gd").reload()

func fresh_game() -> void:
	gs.reset_for_new_game()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func wait_until(condition: Callable, max_frames: int = 600) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await process_frame
	return false

func finish() -> void:
	print("FAILED: %d" % failed if failed > 0 else "ALL OK")
	quit(1 if failed > 0 else 0)
```

Ein Test: `extends "res://assets/_reference/_lib/base_test.gd"` und `func run() -> void:` mit den Prüfungen. Neue Tests sofort so schreiben, alte beim nächsten Anfassen umstellen.

**Die drei Tests, die am meisten bringen**

1. **Speicher-Rundlauf:** Spiel mit möglichst viel Zustand aufbauen (laufender Bosskampf in Phase 2, volle Läden, wartender Tipp), `_collect_save_data` » JSON-Text » `_apply_save_data` » erneut `_collect_save_data`, beide Ergebnisse vergleichen. Hätte Punkt 3, 8 und 9 aus Abschnitt 2 gefunden.
2. **Story-Prüfer:** jede Aktion, jeder Schritt, jedes Flag, jeder Sprecher der story.json ist dem Code bekannt.
3. **Inhalts-Prüfer:** ContentDB laden und 0 `push_error` verlangen; jede Karte laden und prüfen (Kamera-Grenzen, Spawnpunkte, jede Story-Figur genau einmal).

---

## 7. Doku und Arbeitsweise

- **`PROJEKT.md` hat 34.000 Zeichen** (ca. 9.000 bis 10.000 Tokens bei jeder Anfrage). Davon Ordnerbaum 35 %, „Außerdem testen“ 18 %, die Zeile „Fertige Systeme“ 3.000 Zeichen. Vorschlag: Ordnerbaum und Systemnamen nach `docs/`, Test-Anleitungen nur in `docs/VERLAUF.md`; Ziel unter 10.000 Zeichen.
- **Veraltete Stellen in `PROJEKT.md`:** Phase 0 „offen“; Phase 3 „Test ausstehend“ seit 13.10.; Abschnitt 6 nennt als „nicht in Version 1“ Dinge, die längst gebaut sind (Verzaubern, Zauberstäbe, Handel, 52 Dungeons), Regel 9 ist damit gegenstandslos; Zeile 23 „Dungeons als `.tres`“ (liegen in JSON); Zeile 68 nennt `dusts` (gibt es nicht), es fehlen `mortar`, `guild_heroes`, `light_points`; im Ordnerbaum fehlen mehrere Sprite-Ordner, `language.gd`, `ui_scale.gd`; Regeln sind 10, 12, 13, 11 nummeriert; Zeile 149 „Spieltexte sollen später in eigene Dateien“ ist überholt; `docs/SPRACHEN.md:3` widerspricht der Regel „Bezeichner auf Englisch“.
- **`docs/SYSTEME.md` (535 KB)** ist nach Branch und Datum gegliedert, nicht nach System; es gibt z. B. keine Überschrift „Kampf“. 12 Zeilen sind länger als 3.000 Zeichen. Vorschlag: eine Datei je System unter `docs/systeme/` mit festem Kopf (Zweck, Dateien, Daten, Tests, Fallen).
- **65 der letzten 300 Commits liegen direkt auf `main`**, entgegen Abschnitt 4a. Meist „Nach den Merges: Doku zusammengeführt“. Ursache sind die Dateien, die jeder Branch anfasst: `PROJEKT.md` (125 Commits in einer Woche), `ENTSCHEIDUNGEN.md` (83), `SYSTEME.md` (79), `story.json` (51), `en.po` (47). Kleinere Dateien je System lösen das.
- ✅ erledigt 13.11.: **`SKILL.md` der Tests** nennt „~160 Tests“, es sind 317.
- **Projektstamm:** `charpicker.png`, `langfix.png`, `zauberstab vorlage.png`, zwei WhatsApp-Fotos und `opencode.json` gehören nach `assets/_reference/` (die Fotos liegen so auch auf GitHub).
- **`assets/_reference`:** 33.600 Dateien, 33 Ordner mit Datum oder Version im Namen, 123 Hilfs-Skripte ohne Erwähnung in der Doku. Welches Skript welche Spielgrafik erzeugt, ist nur zum Teil nachvollziehbar. Vorschlag: im Asset-Katalog das erzeugende Skript nennen, fertige Einmal-Skripte nach `_archiv/`.

---

## 8. Wiederkehrende Fehlerklassen (aus 113 `fix/`-Branches, Zahlen ±20 %)

| Fehlerklasse | Anzahl | Beispiele |
|---|---|---|
| Objekt oder Figur falsch platziert (im Weg, in der Mauer, Wand fehlt) | ~20 | `fix/finster-kiste-im-weg`, `fix/zellentrakt-wache` |
| Story-Figur doppelt, zu früh, weg; Dialog endet falsch | ~17 | `fix/aurelius-doppelt`, `fix/nyra-kerkerschmiede-eintritt` |
| Balance, Preise, Beute | ~18 | `fix/preise-balancing`, `fix/gold-ueber-silber` |
| Item-, Rezept- und Gussform-Logik | ~16 | `fix/holzfaelleraxt-metalle`, `fix/gussformen-einzeln` |
| Fenster: unsichtbar, Reihenfolge, Tooltip | ~14 | `fix/fenster-unsichtbar`, `fix/gussofen-auswahl-reihenfolge` |
| Alte Spielstände | 41 Stellen in der Doku | `renamed_steps`, `legacy_recipes` |
| Laufwege der Figuren | ~8 | `fix/npc-weggehen`, `fix/kein-laufen-im-dialog` |
| Blickrichtung und Animation | ~8 | `fix/gegner-blickrichtung` |
| Sprache (Lücken, Tests auf Englisch) | 3 Branches, 25 Commits | „englische Lücken geschlossen“ |
| Absturz durch freigegebene Knoten und Signale | 4 | `fix/kristallkarte-absturz` |

Die passenden Regeln stehen in `docs/FEHLERKLASSEN.md`.

---

## 9. Empfohlene Reihenfolge

1. ~~**Tests absichern**~~ erledigt 2026-11-13 (`fix/tests-eigene-daten`): `run_tests.sh` gibt jedem Test ein eigenes `user://` mit Sprache Deutsch, meldet Wackel-Tests und wieder grüne „bekannt kaputte“, Gruppe `kern`; gemeinsame Basis `assets/_reference/_lib/base_test.gd`. Der erste Gesamtlauf fand 38 schon vorher rote Tests (`docs/PROBLEME.md`, „Rote Tests“). Offen: alte Tests auf die Basis umstellen, die 35 Tests ohne Prüfung umbenennen.
2. ~~**Die kleinen echten Fehler**~~ erledigt 2026-11-13 (`fix/kleine-fehler-review`, Test `review_fixes/test_small_fixes.gd`), offen bleiben aus Abschnitt 2 nur die Punkte ohne Haken. Ursprünglich: Hauptmenü-Knopf, Esc/F5 in Cutscenes, Autosave im Turnier, `spend_gold`, Export-Filter, ein Schalter für Test-Funktionen, `extract_po.py` laufen lassen.
3. ~~**Speicher-Rundlauf-Test schreiben**~~ erledigt 2026-11-13 (`fix/speichern-rundlauf`): Test `_lib/test_save_roundtrip.gd`; Boss-Phase, Helfer-Wellen, Einmal-Skills, Boss-Barren, wartende Tipps, Laden-Plätze nach Art, Heldenturnier nach dem Laden, Laden ohne Spiel-Ereignisse. Offen aus 3.2: Umwandlungen alter Spielstände nach Versionsnummer, Quests und Szenen nach ID statt Dateipfad, `SCENE_NAMES`.
4. ~~**Story-Prüfer und Inhalts-Prüfer**~~ erledigt 2026-11-13 (`feature/story-inhalts-pruefer`): `_lib/test_story_data.gd` (jede Story-Aktion ist dem Code bekannt, Schritte, Tipps, Dialoge, Sprecher, Items, Rezepte, Szenen existieren) und `_lib/test_content_loads.gd` (ContentDB lädt ohne eine einzige Fehlermeldung), beide in der Gruppe `kern`; `Story.advance` lehnt unbekannte Schritte mit Fehlermeldung ab. Offen: Flags (werden zum Teil zusammengebaut), Prüfung jeder Karte (Kamera-Grenzen, Spawnpunkte, jede Story-Figur genau einmal), `check_beats.py` automatisch.
5. **Fenster nur neu bauen, wenn sichtbar**: zum Teil erledigt 2026-11-13 (`fix/fenster-nur-sichtbar-neu`, Test `review_fixes/test_closed_windows.gd`): Schmiede-/Guss-Fenster, Auftragsbuch, Auftrags-Details, Dungeon-Brett, Heldenfenster, Kompass (Zeilen mit Haken in Abschnitt 4). Zweiter Teil 2026-11-13 (`feature/fenster-performance`, Test `review_fixes/test_window_performance.gd`): Werkbank-Kette mit `Inventory.begin_batch()/end_batch()`, Laden/Raum-Designer/Werkstatt-Upgrades/Haus-Menü mit `StationMenu._queue_refresh()`, Turnier-Fenster im Sekundentakt, Pflanztopf-Fenster nur noch bei Änderungen, Kampfbühne (Bilder der Gegner einmal geschnitten, Aufstellung einmal je Besetzung, Helden-Aussehen einmal je Held). Dritter Teil 2026-11-13 (`fix/pruefbericht-kleinreste`): Einstellungen werden gebündelt geschrieben (`WindowLayout.flush`), `ContentDB.get_part_items` / `get_recipe_making` und `Ingredient.get_candidates` statt Suche über alle Items und Rezepte. Damit ist Abschnitt 4 abgearbeitet (die Nacht bricht seit `feature/godot-architektur` früher ab).
6. **GameState schrittweise aufteilen** (Abschnitt 3.1): erster Schritt erledigt 2026-11-13 (`feature/esse-eigene-klasse`): die Esse als `ForgeFire`. Zweiter Schritt (`feature/spielstand-eigene-datei`): Sammeln und Anwenden des Spielstands als `SaveData`, GameState damit von 2.820 auf 2.620 Zeilen. Dritter Schritt (`feature/gamestate-aufteilen`, Test `story_actions/test_gamestate_parts.gd`): `StoryActions`, `QuestItems`, `DungeonRewards`, GameState jetzt 1.990 Zeilen. Vierter Schritt 2026-11-13 (`fix/pruefbericht-kleinreste`): Schmelze (`Smelter.fire`) und Phiolen-Tisch (`VialMaking`) brennen über `ForgeFire` (`base_charges`), die Brennstoff-Logik gibt es nur noch einmal. Muster für die nächsten Schritte: Logik in eine Klasse ohne Szene, GameState behält die alten Funktionsnamen als Weiterleitung, der Rundlauf-Test muss grün bleiben.
7. ~~**Cutscenes auf `StoryCutscene` umstellen**, `Player.lock()`~~ erledigt 2026-11-13 (`feature/cutscenes-storycutscene`): alle 15 übrigen Cutscene-Skripte erben von `StoryCutscene` (Signal über `_play_beat`, `wait()` statt 63 roher Timer, kopierte `_node`/`_player`/`_shake`/`_walk_npc` durch die der Basis ersetzt); acht Cutscene-Knoten in Szenen sind dafür `Node2D` statt `Node`. `Player.lock(grund)`/`unlock(grund)`/`is_locked()` ersetzt `set_physics_process(false)` (Ankunft, Kerkerschmiede), Speichern ist währenddessen gesperrt. Offen aus 3.6: Dauer doppelt gepflegt (`hide_for`), Start über `story.step_started`, Schutz gegen zwei Reisen zugleich; in Thronduell und Lich-Angriff laufen die 28 Wartezeiten jetzt über `wait()`, brechen aber wie bisher nicht ab, wenn die Szene weg ist (dort steht danach meist eine eigene Prüfung).
8. **Doku verschlanken**: zum Teil erledigt 2026-11-13 (`docs/projekt-md-schlank`): `PROJEKT.md` von 36.000 auf 22.000 Zeichen (Ordnerbaum und Liste der fertigen Systeme nach `docs/UEBERBLICK.md`), veraltete Stellen berichtigt (Phase 0, Dungeons als JSON, Spieltexte/Übersetzung, TileMap, Regeln in Zahlenfolge, Hinweis zum überholten Umfang von Version 1), die drei falsch benannten Aufnahme-Skripte heißen `shot_*`. Zweiter Teil 2026-11-13 (`docs/systeme-und-story-aufteilen`): `SYSTEME.md` ist Inhaltsverzeichnis, der Text liegt unverändert je System in `docs/systeme/` (13 Dateien); story.json ist der Ordner `data/content/story/` (18 Dateien, Dialoge je Gebiet, `ContentDB.read_story`, Werkzeuge in `assets/_reference/story_split/`); die Vorlagen-Bilder aus dem Projektstamm liegen in `assets/_reference/vorlagen/` (`opencode.json` bleibt, das Werkzeug sucht es dort). Die „Außerdem testen“-Absätze sind gekürzt (ausführlich in `VERLAUF.md`), die Phasen-Tabelle ist nachgezogen (`fix/pruefbericht-kleinreste`). Früher offen: Phasen-Tabelle (Phase 3 „Test ausstehend“) von euch bestätigen lassen.

---

## 10. Godot-Sicht (2026-11-13, Branch `feature/godot-architektur`)

Zweite Prüfung mit Blick auf Szenenaufbau, Datenmodell und Projekteinstellungen (was Abschnitt 1–9 nicht abdeckt).

| # | Befund | Stand |
|---|---|---|
| 1 | Alle 100 Karten bauen Player und HUD selbst ein (80 zusätzlich DayTint von Hand); das HUD samt Admin-Panel entsteht bei jedem Kartenwechsel neu, was eine Karte haben muss, war nirgends erzwungen. | ✅ Vorlage `scenes/world/_template/map_base.tscn`, Test `map_tools/test_map_setup.gd` für alle Karten. Offen (bewusst später): dauerhafte Hauptszene `Main` mit Platz `World`, Laden der nächsten Karte im Hintergrund beim Überblenden. |
| 2 | GameState war zugleich Spielstand und Event-Bus (14 `*_requested`-Signale). | ✅ Autoload `Events`. |
| 3 | Viele JSON-Bereiche kommen als rohes Dictionary (191 Funktionen `-> Dictionary`, über 1.900 `.get("…")`); Tippfehler liefern still den Standardwert, Standardwerte stehen mehrfach im Code. | ✅ Vorlage `NpcInfo` (npcs.json) mit Prüfung beim Laden. Offen: story, economy, arena, leagues, world_map beim nächsten Anfassen. |
| 4 | Renderer Forward+ für ein reines 2D-Spiel. | ✅ GL Compatibility. Ganzzahlige Skalierung bewusst nicht (HiResTexture, 1600×900). |
| 5 | 40 UI-Skripte bauen ihr Fenster nur im Code. | Regel 44 für neue Fenster; alte nur beim Anfassen. |
| 6 | 95 rohe Timer liefen in der Pause weiter; `_pass_night` rechnete immer 8.000 Schritte; Spielername beim Start übersetzt. | ✅ alle drei. Dabei gefunden und behoben: echte Zeilenumbrüche in 10 Strings (Charakterfenster » Gussformen, Pflanztopf zeigte „Language.translate(“). |
