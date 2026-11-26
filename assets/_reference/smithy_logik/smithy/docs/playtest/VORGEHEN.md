# Playtest per Bot: Vorgehen (Übergabe)

Stand 2026-11-15. Ziel: Claude spielt die Story Kapitel für Kapitel, bis zum Ende des Spiels, und schreibt auf, was auffällt. **Nichts am Spiel ändern, nichts committen**, nur berichten. Der Nutzer entscheidet danach, was behoben wird.

## Regeln vom Nutzer

- Pro Abschnitt eine eigene Datei in `docs/playtest/`: `teil1_kap2-9.md` (bis zum Lich-Überfall), dann `teil2.md`, `teil3.md` …
- Nach jedem Kapitel die Ergebnisse sofort in die Datei schreiben, nicht erst am Ende.
- Bei etwa 95 % Session-Limit aufhören, speichern und auf den Nutzer warten.
- Kapitel 1 ist fertig: `docs/PLAYTEST_KAPITEL1.md`, die Bilder liegen in `assets/_reference/playtest/kapitel1/`.

## Kriterien je Kapitel

1. Grinden: wie viele Tage, Läufe und wie viel Gold bis zur nächsten Hürde
2. Unschlüssig: Story widerspricht der Welt oder sich selbst
3. Gesagt, aber nicht animiert (Regel 50 in FEHLERKLASSEN)
4. Komisch: Optik, Wiederholungen, Texte
5. Bugs: Skriptfehler im Log, Hänger
6. Sackgassen
7. Lernkurve, Tipps
8. Wirtschaft: Gold reicht? Preise?
9. Kampfbalance
10. Übersetzung
11. Platzhalter

Im Bericht nach Schwere ordnen: A wichtig, B komisch, C Kleinkram, dazu „Was gut war“ und „Nicht getestet“. Bei jedem Punkt Schritt-ID, Dialog-ID und Bildname angeben.

## Werkzeuge

| Datei | Wofür |
|---|---|
| `assets/_reference/playtest/sim_play_chapter1.gd` | Kapitel 1 vom Hauptmenü an, echtes Laufen mit WASD-Aktionen |
| `assets/_reference/playtest/sim_play_story.gd` | Story-Bot ab Kapitel 2: `-- <out_dir> <von_schritt> <stop_schritt>` |
| `assets/_reference/playtest/run_story.sh <name> <von> <stop>` | Startet den Bot mit eigenem leeren `user://` |

Start (Bash, aus `D:/Smithy/Smithy`), immer mit eigenem APPDATA, damit die echten Spielstände und `settings.cfg` sicher sind:

```bash
U=<scratch>/playtest_userdata_<name>; mkdir -p "$U/Godot/app_userdata/Smithy"
printf '[language]\n\nlocale="de"\n' > "$U/Godot/app_userdata/Smithy/settings.cfg"
APPDATA="$(cygpath -w "$U")" timeout 1500 /c/Users/matri/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe \
  --path . --resolution 1280x720 --fixed-fps 60 -s res://assets/_reference/playtest/sim_play_story.gd -- <out> find_customer go_to_market
```

- Läufe dauern mehrere Minuten, darum mit `run_in_background` starten.
- Ein Godot-Fenster geht auf; das ist erlaubt.
- Ergebnis: `<out>/log.txt` und die Bilder `NNN_<schritt>_<talk|tipp|...>.png`.

**Was der Story-Bot macht:**
- Er startet ein neues Spiel und springt mit `StorySkip.jump_to(von)` zum Startschritt, Gold 500.
- Danach spielt er jeden Schritt selbst:
  - Einkaufslisten kauft er wie `ShopDialog`.
  - Benötigte Items (`QuestJump.required_items`, `quest_ready`) „schmiedet“ er selbst: Qualität 70, die Materialkosten zahlt er in Gold. **Die Minispiele werden nicht gespielt.**
  - Er reist zu der Figur, die `QuestJump.location_of` nennt, und drückt E.
  - Dialoge klickt er durch, „Später“ oder „Nein“ wählt er nie.
  - Schlafen geht über `GameState.sleep()`.
  - Dungeons laufen über `GameState.send_party` als echte Kämpfe.
- Hängt ein Schritt nach 6 Versuchen: Er schreibt „BOT HÄNGT“ ins Log und springt mit StorySkip weiter.
- Die Log-Zeilen `ZEILE [sprecher] text {action}` zeigen, ob eine Zeile eine Animation hat.

## Fallen, die schon passiert sind

- **Klassen-Namen im Bot-Skript** (`StorySkip`, `Hero`, `InventorySlot` …) als Typ oder direkt: Das Skript kompiliert dann nicht, weil Klassen vor den Autoloads geladen werden. Darum alles per `load(...)` in `_run` holen, Typen weglassen. `send_party` braucht ein typisiertes `Array[Hero]`: dafür `gs.heroes.duplicate()` und dann `clear()`.
- **`-s` lädt keine Hauptszene:** Das Hauptmenü selbst mit `change_scene_to_file` laden.
- **Story-Preise:** Gussformen kosten in manchen Phasen weniger (`MerchantStock.get_active_limit()["prices"]`). Der Bot muss das beachten, sonst meldet er fälschlich „zu wenig Gold“. **Noch nicht eingebaut.**
- **E-Bereiche:** StoryNpc 44×36, Mitte 8 px über der Figur. Steht der Bot 14 px darunter, passiert nichts. Das ist kein Spielfehler.
- **Bevor etwas als Spielfehler gilt:** immer prüfen, ob es nicht der Bot war (falscher Abstand, fehlender Preis, falsche API). Im Zweifel als „unsicher, bitte von Hand prüfen“ melden.
- **Godot-Prozess hängt:** Nur den eigenen beenden (CommandLine enthält `sim_play_story`). Den Editor des Nutzers nie beenden.
- **„Zufällig“ im Charakter-Editor** würfelt jedes Mal neu. Ein anderes Aussehen ist darum kein Fehler.

## Bot-Stand (2026-11-15, zweite Sitzung)

Eingebaut und geprüft:
- Story-Preise der Gussformen (`story_limits.prices`, wie `shop_dialog.gd:164`).
- Hinlaufen mit echter Steuerung bis `wants_interact()` (`approach`); ist die Figur weiter als 60 px weg, stellt er sich erst wie QuestJump davor. Kommt er nie in den E-Bereich: Log „E-BEREICH NICHT ERREICHT“.
- Quest-Abgabe an `QuestNpc` (Holger): Karte mit der Quest suchen, E, Item in den Abgabe-Slot (`try_quick_move`), „Abgeben“.
- Abgabe-Slots in Dialogen (`take_items`): alles Passende per `try_quick_move` hinein.
- Story-Aufträge am Auftragsbrett (`progress_flags` `order_done_<tag>`) über `GameState.complete_order`.
- Ninas Laden: fehlende Schwerter macht er selbst.
- Schritte mit `enter:<karte>` (z. B. `rat_fight_lost`): erst die Karte betreten.
- Morgen-Bildschirm („Klicken oder Taste drücken“, pausiert das Spiel): Leertaste, Text kommt als `MORGEN:` ins Log.
- Ausdauer fehlt: tagsüber Zeit vergehen lassen, erst ab 21 Uhr schlafen. Held noch unterwegs: warten.
- Bruno ohne Waffe (Kapitel-Sprung gibt keine): Kupferschwert R2 vom Bot, Log „AUSGERÜSTET … (Bot)“.
- Stopp bei „Stopp-Schritt oder später“ (manche Schritte springen sofort weiter).
- `run_story.sh <name> <von> <stop> [sekunden]`: viertes Argument = Zeitgrenze (Standard 1500).

**Wichtig:** Kapitel einzeln per Sprung zu spielen verfälscht Level, Gold und Ausrüstung (Bruno blieb Level 1 und ohne Schwert). Für Balance-Aussagen mehrere Kapitel in einem Lauf spielen. Einzelne Sprünge taugen nur für Texte und Szenen.

## Stand

- Kapitel 1: `docs/PLAYTEST_KAPITEL1.md`.
- **Teil 1 fertig** (Kapitel 2 bis `chapter10_end`): `docs/playtest/teil1_kap2-9.md`, Bilder und Logs in `assets/_reference/playtest/teil1/`.
- Nachträglich im Bot: `visit_all` (mehrere Figuren fragen, auch Neben-Dialoge aus `side.json`), `find_target` nimmt nur sichtbare Figuren mit `wants_interact` (vorher erwischte er die unsichtbare Begleiter-Lotte).
- Bot-Grenzen: schmiedet keine Rüstung, verkauft nichts, Neben-Aufgaben (z. B. `shoes_for_lotte`) überspringt er.
- **Teil 2 fertig** (`chapter10_end` bis `part2_end`): `docs/playtest/teil2.md`, Bilder/Logs in `assets/_reference/playtest/teil2/`.
- **Teil 3–8 fertig** (2026-11-16): `teil3.md` … `teil8.md`, Gesamtübersicht `ZUSAMMENFASSUNG.md`, Bilder/Logs in `assets/_reference/playtest/teil3/` … `teil7-8/`, Spielstände in `assets/_reference/playtest/saves/`.
- **Karten ohne Ausweg** geprüft: `karten_ausweg.md`, Werkzeug `assets/_reference/playtest/night_exits.py`.
- **Das Spiel ist einmal komplett durchgespielt.** Weiter nur auf Wunsch (z. B. ein Teil neu nach Änderungen: `SAVE=saves/<teil>.json run_story.sh <name> load:<schritt> <stop>`).

## Bot-Stand (2026-11-16, Teil 2)

- **Weiterspielen statt Springen:** `SAVE=<autosave.json> bash run_story.sh <name> load <stop> [sekunden]` kopiert den Autosave in das eigene `user://` und lädt ihn (`load` statt Startschritt). Gesicherte Stände: `assets/_reference/playtest/saves/teil1_ende.json` (Schritt `raid_morning`), `teil2_ende.json` (Schritt `fight_dragon`, Tag 53).
- `run_story.sh` nimmt den Scratchpad aus `PLAYTEST_S` (sonst fest eingetragen, bei neuer Sitzung anpassen).
- Ausrüstung wie `sim_progress.gd`: volles Set im Metall der Story-Stufe (`METAL_FROM`), R1, Q0, Material in Gold; Punkte nach `sim_party.gd` BUILDS. **Skills immer komplett nach Plan neu verteilen** (sonst nur die ersten Skills voll, Helden 10 % statt 80 %).
- Vor Story-Dungeons farmen bis Empfehlung −1 (`farm_for`), unter 3 Helden anheuern (fehlende Rolle zuerst).
- Nach jedem Lauf Loot-Kiste leeren und Beute verkaufen (`loot_out`). Fehlte in Teil 1.
- Schlaf-Schritte: nach einem Gespräch schlafen; `wait_days`: Nächte schlafen; Preis in einer Wahl („500 Gold“) zu hoch: `earn_gold`.
- Rätsel in `special_step` (Teleporter, Felsen, Goblin-Schlüssel); neue Rätsel dort eintragen.
- Figuren, die als eigene Szene in einer Karte stecken (Konrad), findet `scenes_with`.
- Prüfwerkzeuge: `sim_party_check.gd` (Bot-Gruppe vs. Referenz im Simulator), `sim_hero_compare.gd -- <save>` (Heldenwerte aus einem Spielstand neben Simulator-Helden, Siegquoten).

## Erledigt: Karten ohne Ausweg (Wunsch Nutzer, 2026-11-16)

- **Karten ohne Ausweg prüfen:** In welchen Karten kann der Spieler (je nach Tageszeit, Story-Stand, verschlossenen Türen, Figuren im Weg) die Karte nicht mehr verlassen und steckt fest? Dem Nutzer ist das 1–2-mal passiert („durch die Zeit“, z. B. Türen nachts zu?). Der Knopf „Ich stecke fest“ im Menü bringt zur Schmiede, soll aber nicht nötig sein. Eigener Bericht `docs/playtest/karten_ausweg.md`.
- Hinweis vom Nutzer: abends, Meldung „Es ist Nacht, das Dorf verlässt man jetzt besser nicht.“ (`GameState.NIGHT_BLOCKED_MESSAGE`). Spur: `GameState.is_blocked_at_night` sperrt nachts jede Tür in eine „wilde“ Karte (`WILD_SCENES`), außer sie führt näher nach Hause (`WILD_STEPS_HOME`; fehlt eine Karte dort, gilt 99, und 99 >= 99 sperrt). Prüfen: jede wilde Karte, deren Ausgänge alle in wilde Karten ohne kleineren Wert führen = Falle. Dazu Kutschen/Teleporter nachts.

## Bot-Stand (2026-11-16, Teil 3–8)

- `load:<schritt>`: Autosave laden, dann mit StorySkip zu einem Schritt springen (Helden, Gold, Ausrüstung bleiben).
- `special_step`: Schmiedeturnier (Q70, Zeit = par, loggt Punkte gegen den Gegner), Heldenturnier (Kämpfer statt Heiler, echte Duelle), Hadmars Waffen (`ElfDefense`), Sturmtempel (`StormTemple`), Eismauer (`IceWall`), Blitzstab.
- `_prefer`: bevorzugte Antwort in einer Wahl (z. B. „Mehr habe ich nicht“).
- Neue Sets nur für die drei stärksten Helden.
- Offene Bot-Lücken: Fessel aufschmieden (`break_shackle`), Schleichen, Sumpf-Dungeons vor dem Trank, Turnier-Herold (spielt das Intro nicht).
