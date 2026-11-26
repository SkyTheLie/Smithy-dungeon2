# Fehlerklassen und Regeln dagegen

Diese Fehler sind im Projekt mehrfach passiert (Herleitung und Fundstellen: `docs/CODE_REVIEW_2026-11-12.md`).
Vor jeder Aufgabe lesen. **Jeder `fix/`-Branch trägt unten in der Liste „Ursachen“ eine Zeile ein;** passt keine Regel, kommt eine neue dazu. Diese Datei kurz halten.

## Speichern und Laden

1. Jedes neue Feld, das sich im Spiel ändert, kommt sofort in `to_save_data` **und** `load_save_data` (Felder von GameState: in `SaveData.collect` und `SaveData.apply`, `scripts/core/save_data.gd`), oder bekommt den Kommentar `# not saved on purpose`. Auch Warteschlangen und „schon gezeigt“-Merker. Der Test `_lib/test_save_roundtrip.gd` vergleicht einen ganzen Spielstand vor und nach dem Laden: neuen Zustand dort in `_build_state` mit aufbauen.
2. Gespeichert wird nach ID oder Schlüssel, nie nach Position in einer Liste und nie nach Dateipfad.
3. Kein Spielzustand in `static var`.
4. Jeder Weg zu speichern (Slot, Schnellspeichern, Autosave) prüft dieselben Sperren: nicht im Turnier, nicht in einer Cutscene, nicht beim automatischen Laufen.
5. Laden löst keine Spiel-Ereignisse aus (kein `story_event`, keine Tipps, keine Erfolge).
6. Wird eine ID, ein Flag oder ein Schritt umbenannt: Umwandlung für alte Spielstände eintragen und mit einem alten Spielstand laden.

## Sprache

7. Jeder sichtbare Text läuft durch `Language.translate`, auch Textstücke, die angehängt werden; bei `%`-Texten erst übersetzen, dann einsetzen. Zahlen über `DamageKinds.format_number`.
8. Nie übersetzten Text vergleichen (`button.text == "..."`); Zustand in einer Variable halten.
9. `Language.translate` nie auf Namen von Knoten, Typen oder IDs anwenden.
10. Nach neuen Texten `extract_po.py` laufen lassen, bevor die Aufgabe als fertig gilt.

## Oberfläche und Performance

11. Ein Fenster, das zu ist, baut nichts: Bei einem Signal nur „veraltet“ merken, beim Öffnen neu bauen, höchstens einmal pro Frame (Vorlagen: `hero_window._on_hero_changed` mit `_stale`, `crafting_menu._on_supplies_changed`, `quest_log_window._refresh_if_visible`). Signale von GameState, Inventar, Story oder Helden nie direkt mit `_refresh` verbinden.
12. In `_process` und `_draw` nichts neu anlegen und nichts durchsuchen (kein `load`, kein `find_children`, kein Neuaufbau von Listen).
13. Spielregeln (EXP, Erfolge, Flags, Gold, Bestand) stehen in `scripts/systems`, nie im Fenster-Skript. Das Fenster ruft auf und zeigt an.
14. Abfragen ändern nichts: `is_*` und `get_*` setzen keine Flags und zeigen keine Tipps.
15. Bei `bind` kommen die gebundenen Argumente **hinter** die Argumente des Signals.
16. Eine Lambda an einem Signal von `GameState` muss mit dem Knoten enden: als Methode des Knotens verbinden oder in `_exit_tree` trennen.

## Story und Cutscenes

17. Jede Cutscene erbt von `StoryCutscene`. Warten nur mit `wait()`, nie mit rohem `await get_tree().create_timer(...)`. Nach jedem `await` kann die Szene weg sein.
18. Ob eine Story-Figur da ist, hängt an genau einer Quelle (Flags in story.json), nie zusätzlich fest in der Karte.
19. Schritte, Flags und Aktionen der Story nicht frei tippen: aus der story.json kopieren. Nach jeder Änderung an story.json `bash assets/_reference/run_tests.sh kern` (Prüfer `_lib/test_story_data.gd`: unbekannte Aktionen, Schritte, Tipps, Dialoge, Sprecher, Items) und `py assets/_reference/story_anims/check_beats.py` (Cutscene-Beats).
20. Wer den Spieler sperrt, entsperrt ihn auf jedem Weg wieder (Ende, Esc, Laden, Szenenwechsel).
21. Start einer Cutscene hängt an einem Signal (`story.step_started`), nicht an der Reihenfolge der Knoten.

## Karten

22. Keine Position nur aus Koordinaten setzen: Karte danach rendern und ansehen, Begehbarkeit prüfen (`collision_audit/`).
23. E-Taste: jedes Objekt nimmt E nur an, wenn es das nächste ist und kein Dialog offen ist (`INTERACT_GROUP`).
24. Gegner schauen nach links, Helden nach rechts; nichts in der Welt steht schräg.

## Daten

25. Jeder Wert und jede Namensliste hat genau eine Quelle (JSON oder `CombatRules`). Kein zweiter Standardwert im Code, keine zweite Liste.
26. Was eine Funktion verbraucht, prüft sie vorher in genau derselben Menge. Mengen ≤ 0 und negative Preise abweisen.
27. Jeder Cache hängt an `ContentDB.reload()`. Kein JSON an ContentDB vorbei lesen. Neue Inhalte prüft ContentDB beim Laden mit `push_error`; der Test `_lib/test_content_loads.gd` verlangt 0 Meldungen.
28. Preise, Beute und Kampfwerte nur mit einem Lauf des Simulators ändern.
41. Ein Item mit `sell_price` bekommt auch `value` (sonst kostet es beim Händler 1–3 Gold); `balancing/test_buy_above_sell.gd` prüft das.

## Tests

29. Ein neuer Test erbt von `assets/_reference/_lib/base_test.gd` (`check`, `check_eq`, `wait_until`, `fresh_game`), prüft etwas und endet über die Basis. Skripte, die nur etwas ausgeben, heißen `sim_*` oder `shot_*`.
30. Tests nur über `run_tests.sh` starten: nur dort bekommt jeder Test ein eigenes, leeres `user://`. Einzeln mit Godot gestartet schreibt ein Test in die echten Spielstände (`GameState.sleep()` schreibt den Autosave).
31. Deutsche Texte erst nach `TranslationServer.set_locale("de")` **und** `ContentDB.reload()` vergleichen. Besser IDs und Zahlen prüfen als Texte.
32. Bei Zufall `seed(1)` setzen. Auf Bedingungen warten, nicht auf feste Sekunden.
33. Tests benutzen öffentliche Funktionen, keine `_privaten` Felder.
34. Wer Verhalten ändert, passt die Tests im selben Commit an. `test_known_failures.txt` ist nur für Fehler, die man nicht selbst verursacht hat, mit Datum und Grund.
35. Nach Änderungen an `game_state.gd`, `content_db.gd` oder `data/content/*.json` zusätzlich die passende Gruppe laufen lassen (`kampf`, `story`, `wirtschaft`); die automatische Auswahl findet dafür keine Tests.

39. Test-Funktionen fragen nur `DevTools.enabled()` (bzw. `GameState.has_dev_tools()`) und tragen den Kommentar `DEV-ONLY`. Nie `OS.is_debug_build()` dafür nehmen.
40. Nach einer neuen `class_name` einmal `--headless --path . --import` laufen lassen, sonst kennt ein Test die Klasse nicht.

## Grafik-Dateien

36. Alte Grafik im Spiel trotz neuer PNG: Import-Cache löschen (`.ctex` + `.md5`) und neu importieren.
37. In Szenen schlägt die `uid` den Pfad: beim Ersetzen einer Datei beide prüfen.
38. Ein Eintrag in `PIXELLAB_TODO.md` wird erst gelöscht, wenn das ganze Bild echt ist.

## Godot-Aufbau

41. Signale, die nur etwas anfordern (Fenster öffnen, Meldung zeigen, Cutscene-Teil abspielen, `*_requested`), stehen im Autoload `Events`, nicht in GameState. GameState sendet nur Änderungen seines Zustands.
42. Neue Karten erben von `scenes/world/_template/map_base.tscn` (Player, HUD, DayTint, Kamera-Grenzen, Spawnpunkt). `map_tools/test_map_setup.gd` prüft jede Karte.
43. JSON-Daten, die an mehreren Stellen gelesen werden, bekommen eine kleine Klasse mit `from_json` und Prüfung beim Laden (Vorlage `NpcInfo`), statt überall `.get("schluessel", standard)`. Neue Dictionaries typisieren (`Dictionary[String, int]`).
44. Neue Fenster als `.tscn` bauen; im Code nur Listeneinträge erzeugen. Alte Fenster nur beim Anfassen umbauen.
45. Timer pausieren mit dem Spiel: `create_timer(t, false)` (nur Knoten mit `PROCESS_MODE_ALWAYS` lassen `false` weg). Keine echten Zeilenumbrüche in Strings, immer `\n`.

## Ursachen (neueste oben)

Format: `Datum · Branch · was war die Ursache · Regel-Nummer (oder „neu“)`

- 2026-11-13 · fix/rote-kampf-tests · Quest-Teile aus Gussformen (Siegel, Dietrich, Kletterhaken, Fassung …) hatten `sell_price` ohne `value`; zwei Tests nicht nachgezogen, als Story-Kämpfe an `start_adventure` und Monster an eigene Sterbe-Animationen gingen · neu: 41, 34
- 2026-11-13 · feature/godot-architektur · Ein Übersetzungs-Umbau (2026-10-27) hatte `"\n"` in echte Zeilenumbrüche verwandelt; mit Windows-Zeilenenden wurden daraus `\r\n`, die Gussform-Gruppen im Charakterfenster trennten sich nicht mehr, der Pflanztopf zeigte „Language.translate(“; Timer liefen in der Pause weiter, Tweens nicht · neu: 45

- 2026-11-13 · fix/fenster-nur-sichtbar-neu · Fenster hörten auf Signale von GameState/Inventar und bauten sich auch geschlossen komplett neu (Heldenfenster bei jedem Pfeil, Dungeon-Brett jede Spielstunde, jedes Schmiede-Fenster der Szene bei jeder Inventar-Änderung) · 11
- 2026-11-13 · fix/speichern-rundlauf · Felder, die sich im Spiel ändern, fehlten im Spielstand (Boss-Phase, Helfer-Wellen, Einmal-Skills, wartende Tipps, letzte Spende); Laden-Ware nach Platznummer gespeichert; Laden löste `adventure_started` aus; kein Test verglich einen ganzen Spielstand · 1, 2, 5
- 2026-11-13 · fix/kleine-fehler-review · „Hauptmenü“ verglich übersetzten Knopftext mit dem deutschen Wort; Esc/X schlossen Dialoge mit offenen Aktionen; Speichern mitten in Cutscenes und Autosave im Turnier ohne Sperre; „Sofort“ hing an einem anderen Schalter als das Admin-Panel · 8, 4, 20, neu: 39
- 2026-11-13 · fix/tests-eigene-daten · Tests liefen auf den echten Spielständen und Einstellungen (Sprache vom Rechner, Autosave überschrieben); 38 Tests waren unbemerkt rot, weil nie alle liefen · 30, 34
- 2026-11-12 · fix/schmiede-ruckler · Fenster bauten sich bei jedem Signal neu auf, auch geschlossen · 11
