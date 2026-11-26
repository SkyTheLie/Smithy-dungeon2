# PROJEKT.md – Smithy Roguelike

> Diese Datei gehört in den Wurzelordner des Godot-Projekts. Sie wird jedem neuen KI-Chat bzw. jeder Claude-Code-Sitzung als Kontext mitgegeben (bei Claude Code kann sie zusätzlich als `CLAUDE.md` abgelegt oder von dort verlinkt werden).
> Nach jedem abgeschlossenen Schritt aktualisieren: `docs/UEBERBLICK.md` (nur Name neuer Systeme), `docs/systeme/<system>.md` (Kurzfassung oben + Details; Inhaltsverzeichnis `docs/SYSTEME.md`), Abschnitt 8 und `docs/ENTSCHEIDUNGEN.md` (neue Entscheidungen), `docs/PROBLEME.md` (bekannte Probleme).
> Diese Datei kurz halten – sie wird bei jeder KI-Anfrage komplett mitgeschickt. Details gehören nach `docs/`. Abschnitt 8: nur die aktuelle Aufgabe und höchstens 5 Test-Einträge, Älteres nach `docs/VERLAUF.md`. Ordnerbaum und die Liste „Fertige Systeme“ stehen in `docs/UEBERBLICK.md`.

---

## 1. Projekt in Kürze

- **Titel:** Smithy Roguelike (Arbeitstitel), Godot-Projektname „Smithy Roguelike“
- **Was:** 2D-Pixel-Art-Roguelite (Turmverteidigung): Die Schmiede steht in der Mitte, Gegner kommen in endlosen Wellen von allen Seiten, der Spieler schlägt mit dem Hammer zu und ruft mit Kristallen Einheiten, die verteidigen. Ein Run endet, wenn die Schmiede fällt; zwischen den Runs Kristalle, dauerhafte Verbesserungen, Meisterschaft, Sammlung und Aufträge. Teile sind die 52 Dungeons des Schmiedespiels (Boden, Gegner, Boss je Dungeon). Alles Wichtige: `docs/systeme/verteidigung.md`.
- **Herkunft:** Abgespalten aus dem Schmiedespiel **Smithy** (Repo `SkyTheLie/Smithy`, Branch `feature/schmiede-verteidigung`, 2026-11-23). Die Verteidigung läuft auf dem Kern von Smithy (`GameState`, `ContentDB`, `Language`, `AudioManager`, Grafiken, Gegner, Dungeons); der Code des Schmiedespiels (Story, Karten, Schmieden, Helden) liegt deshalb noch im Projekt, ist aber vom Hauptmenü aus nicht erreichbar (`main_menu.gd`: `_start_story_game` ungenutzt). Die meiste Doku in `docs/` beschreibt noch das Schmiedespiel.
- **Plattform:** PC (Windows) als Hauptversion, dazu Android-APK aus demselben Projekt (Handy-Besonderheiten nur hinter `MobileUi.active()`, `docs/systeme/ui.md`). Einzelspieler.
- **Entwicklung:** Zu zweit (Informatikstudent als Hauptentwickler, **Anfänger in Spieleentwicklung und Godot**, plus ein Mitentwickler), ca. 10 Stunden pro Woche, mit KI-Unterstützung (Claude Code).
- **Erfolgskriterium:** Eine andere Person kann das Spiel starten, verstehen und spielen; ein Run dauert rund 1 Minute, macht Spaß, ist fair und läuft flüssig.

## 2. Technik

- **Engine:** Godot 4.x (aktuelle stabile Version, Standard-Version, nicht .NET)
- **Sprache:** GDScript (statisch typisiert)
- **Renderer / Ansicht:** 2D, Pixel Art, Top-Down (entschieden, siehe Abschnitt 8); Basisauflösung 640×360, Stretch-Modus `canvas_items` (nicht ganzzahlig, wegen `HiResTexture` und 1600×900), Renderer GL Compatibility
- **Daten:** Items, Materialien, Rezepte, Status-Effekte, Skills, Skillbäume, Beschwörungen, Gegner, Dungeons, Kampf-Formeln und Schmiede-Muster als JSON in `data/content/` (inkl. Sockel-Boni `sockets.json`; Anleitung: `docs/CONTENT.md`), übrige Daten (Aufträge, Steine, Helden, Klassen, Teleport-Ziele …) als Godot-Resources (`.tres`) – nie im Code hartkodiert
- **Speichern:** ein Spielstand `user://defense_save.json` (`DefenseSaves`, seit 2026-11-25; vorher 6 Plätze). Das Nutzerverzeichnis hängt am Projektnamen: Smithy Roguelike hat ein eigenes, getrennt von Smithy.
- **Versionsverwaltung:** Git + GitHub (`SkyTheLie/Smithy-roguelike`), Arbeit auf Branches, siehe Abschnitt 4a. Zu zweit entwickelt.
- **Export:** Windows (`smithy_roguelike.exe`) und Android (`SmithyRoguelike.apk`, Paket `com.am.smithy.roguelike`, lässt sich neben Smithy installieren), beide aus `export_presets.cfg`; APK bauen und aufs Handy: `docs/ANDROID.md`

## 3. Ordnerstruktur

```
res://
├── assets/        # audio/, fonts/, ui/ (Theme), sprites/ (alle Spielgrafiken), _reference/ (NICHT im Spiel: Tests, Back-Skripte, Vorlagen)
├── data/          # content/ (JSON: Items, Rezepte, Gegner, Dungeons, Story …), dazu .tres: quests/, heroes/, hero_classes/, rocks/, destinations/, player_skills/
├── docs/          # Doku (Liste: docs/UEBERBLICK.md)
├── locale/        # Übersetzungen <sprache>.po (docs/SPRACHEN.md)
├── scenes/        # actors/, stations/, ui/ (hud, menus, heroes, minigames …), story/, world/ (eine Karte je Szene, nach Gebiet)
├── scripts/       # core/ (Autoloads Events, GameState und AudioManager, ContentDB, SaveData, DevTools, Language), resources/ (Resource-Klassen), systems/ (Logik ohne Szene)
├── CLAUDE.md      # lädt PROJEKT.md und docs/FEHLERKLASSEN.md in jede Sitzung
└── PROJEKT.md
```

Der vollständige Ordnerbaum mit Beschreibung jedes Ordners und die Liste aller Doku-Dateien stehen in `docs/UEBERBLICK.md` (bei Bedarf lesen; neue Ordner und Doku-Dateien dort eintragen).

**Regeln:**

- Skripte, die zu genau einer Szene gehören, liegen direkt neben ihrer Szene (z. B. `scenes/actors/player.gd`). `scripts/` ist für szenenunabhängigen Code (Autoloads, Systeme, Resource-Klassen).
- Alles, was nicht ins Spiel gehört (Entwürfe, KI-Bilder, Rohdaten), kommt nach `assets/_reference/`. Die Datei `.gdignore` dort sorgt dafür, dass Godot den Ordner nicht importiert.
- Dateien möglichst im Godot-Editor verschieben/umbenennen (FileSystem-Dock), damit Verweise automatisch angepasst werden.

## 4. Konventionen

- **Dateien und Ordner:** `snake_case` (`iron_sword.tres`, `forge_station.tscn`)
- **Klassen (`class_name`):** `PascalCase` (`ItemData`)
- **Variablen und Funktionen:** `snake_case`, Konstanten `GROSSBUCHSTABEN`
- **Signale:** Vergangenheitsform, z. B. `item_crafted`, `rent_paid`
- **Sprache im Code:** Bezeichner und Kommentare auf **Englisch** (festgelegt). Spieltexte werden auf Deutsch geschrieben (der deutsche Text ist der Schlüssel) und über `locale/<sprache>.po` übersetzt; jeder sichtbare Text läuft durch `Language.translate` (`docs/SPRACHEN.md`). Das Spiel startet ohne gewählte Sprache auf Englisch.
- **Statische Typisierung:** `var gold: int = 0`, `func add_item(item: ItemData) -> void:`
- **Grafiken für zusammengesetzte Items (Baukasten):** Alle Teile einer Waffenart (z. B. Klinge, Griff eines Schwerts) werden auf **derselben Leinwand** gezeichnet (Item-Icons: 24×24 px), jedes Teil an der Stelle, an der es im fertigen Item sitzt, der Rest transparent. Das fertige Icon entsteht automatisch durch Übereinanderlegen (`ItemIcons.compose`, Reihenfolge über `layer_order`, höher = oben). Fertige Kombinationen werden **nicht** gezeichnet. Tipp: In Aseprite eine Vorlage mit einer Ebene pro Teil anlegen und jede Ebene einzeln exportieren.
- **Kommunikation zwischen Systemen:** über Signale bzw. einen zentralen Event-Bus, keine festen Pfadabhängigkeiten zwischen weit entfernten Nodes.

## 4a. Zusammenarbeit mit Git (Branches)

Wir arbeiten zu zweit. `main` ist der stabile Stand und muss immer starten und spielbar sein. **Niemand committet direkt auf `main`.**

**Ablauf pro Aufgabe:**

1. Aktuellen Stand holen: `git switch main` und `git pull`.
2. Eigenen Branch anlegen: `git switch -c feature/kurze-beschreibung` (Fehlerbehebung: `fix/...`, nur Doku: `docs/...`). Namen klein, mit Bindestrichen, z. B. `feature/spitzhacken`.
3. In kleinen Schritten committen, jeder Commit lauffähig. Commit-Nachricht kurz auf Deutsch: was und warum.
4. Branch hochladen: `git push -u origin feature/kurze-beschreibung` (`origin` = `SkyTheLie/Smithy-roguelike`; im Worktree `smithy_defense` neben Smithy heißt das Remote `roguelike` und ist dort Standard, `origin` ist dort Smithy).
5. Auf GitHub einen **Pull Request** nach `main` öffnen. Der andere schaut drüber und testet kurz.
6. Mergen (am besten „Squash and merge“), danach Branch löschen und lokal wieder bei Schritt 1 anfangen.

**Godot-spezifisch:**

- Nicht gleichzeitig dieselbe Szene (`.tscn`) bearbeiten. Konflikte in Szenen sind schwer aufzulösen. Vorher absprechen, wer welche Szene anfasst.
- `.uid`- und `.import`-Dateien mit committen, den Ordner `.godot/` nicht (steht in `.gitignore`).
- Vor dem Branch-Wechsel Godot-Szenen speichern oder schließen; nach dem Wechsel/Pull Godot das Projekt neu einlesen lassen.
- Bei Merge-Konflikten in `PROJEKT.md` beide Änderungen übernehmen.

## 5. Regeln für die KI

1. **Godot 4 / GDScript 2.0.** Keine Godot-3-Syntax (z. B. kein `onready var` ohne `@`, kein `yield`, kein `KinematicBody2D`). Im Zweifel nachfragen oder die Version nennen.
2. **Kleine Schritte.** Immer nur die aktuelle Aufgabe umsetzen. Keine zusätzlichen Features einbauen, die nicht angefragt wurden.
3. **Erklären.** Kurz sagen, was der Code macht und welche Nodes bzw. Szenen angelegt werden müssen. Der Entwickler ist Anfänger in Godot, aber kann programmieren.
4. **Vollständig und lauffähig.** Vollständigen Code liefern, keine Platzhalter wie `# hier Code einfügen`. Angeben, in welche Datei er gehört.
5. **Szenenaufbau beschreiben.** Bei Szenen die Node-Hierarchie als Baum angeben, inklusive Node-Typen und benötigter Einstellungen.
6. **Daten statt Code.** Items, Rezepte und Aufträge als Daten, damit neue Inhalte ohne Codeänderung möglich sind.
7. **Bestehenden Code respektieren.** Vor Änderungen die vorhandenen Dateien lesen. Keine großen Umbauten ohne Rückfrage.
8. **Fehlersuche.** Bei Fehlermeldungen zuerst die Ursache erklären, dann die Lösung. Bei Unsicherheit nachfragen statt raten.
9. **Scope im Blick behalten.** Version-1-Umfang aus Abschnitt 6 gilt. Ideen für später in den Backlog, nicht sofort bauen.
10. **Nach jeder Aufgabe:** kurz sagen, was getestet werden sollte, und die Doku aktualisieren: Details in `docs/systeme/<system>.md` (welche Datei: `docs/SYSTEME.md`), Entscheidungen in `docs/ENTSCHEIDUNGEN.md`, bekannte Probleme in `docs/PROBLEME.md`, neue System-Namen in `docs/UEBERBLICK.md`, hier nur die aktuelle Aufgabe (8, ältere Test-Anleitungen nach `docs/VERLAUF.md`).
11. **Git:** Vor jeder neuen Aufgabe einen Branch von aktuellem `main` anlegen (Abschnitt 4a). Nie direkt auf `main` committen, nicht ungefragt pushen oder mergen.
12. **Tests:** Logik headless testen; keine Screenshots, außer der Entwickler meldet einen Fehler, der sich aus seiner Beschreibung nicht beheben lässt. Tests immer über `bash assets/_reference/run_tests.sh` starten (Claude-Skill `run-tests`, Anleitung `.claude/skills/run-tests/SKILL.md`): ohne Argumente laufen nur die Tests, die zu den Änderungen des Branches passen, plus ein Kompilier-Check; Ordner/Gruppen gezielt wählbar. Nie ungefragt alle Tests (`all`) laufen lassen, keine Test-Skripte einzeln mit Godot starten.
13. **Grafiken und Karten:** Neue Karten im Stil von Schmiedeplatz, Marktplatz und Dorfplatz. Jede Lichtquelle leuchtet im Dunkeln (`NightLight`). Die Kamera bleibt am Kartenrand stehen (`limit_*` am `Camera2D` des Spielers), die Figur läuft dort gegen die Wand – die Leere außerhalb der Karte darf nie zu sehen sein. Vor jeder neuen Grafik in `docs/ASSET_KATALOG.md` nachsehen und Vorhandenes wiederverwenden – außer Häuser und Figuren: die immer neu erzeugen, keine zwei dürfen gleich aussehen. Neue Grafiken im Katalog eintragen. Referenzbilder nur beschreiben, nie hochladen. Jeder neue Platzhalter (Skript, umgefärbt, Standard-Bild) kommt in `docs/PIXELLAB_TODO.md`; was dort mit PixelLab erledigt ist, wird gelöscht.
14. **Fehler nicht wiederholen:** Die Regeln in `docs/FEHLERKLASSEN.md` gelten für jede Aufgabe. Nach jeder Fehlerbehebung dort unter „Ursachen“ eine Zeile eintragen (Ursache + Regel-Nummer, oder eine neue Regel).

## 6. Umfang

Das Roguelite ist gebaut (Stand 2026-11-23, `docs/systeme/verteidigung.md`): Runs mit endlosen Wellen über alle 52 Dungeons, Hammer, Kristalle und Einheiten (R1–R5, Fähigkeiten), Laden mit Paketen, Verbesserungsbaum, Meisterschaft, Sammlung, Aufträge, Kristallmünzen, Musik je Teil, ein Spielstand.

**Nicht ungefragt bauen:** neue Spielsysteme, Story, Rückbau des Schmiedespiel-Codes (siehe Abschnitt 1, „Herkunft“; erst mit dem Entwickler abstimmen). Ideen für später in `ideen.txt`.

## 7. Fortschritt

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Abspaltung aus Smithy: eigenes Repo, Projektname, Export, Doku | erledigt (2026-11-23) |
| 1 | Spielbarer Kern: Run, Wellen, Hammer, Kristalle, Einheiten, Verbesserungen, Spielstände | erledigt (2026-11-23), Zahlen mit `defense/sim_defense.gd` abgestimmt, nicht endgültig |
| 2 | Playtest: Spaß, Fairness, Tempo, Leistung mit vielen Gegnern | offen |
| 3 | Eigene Grafik/Musik, Rückbau nicht gebrauchter Schmiedespiel-Teile | offen |
| 4 | Veröffentlichung | offen |

Beschreibung jedes Systems: eine Datei je System in `docs/systeme/` (Roguelike: `verteidigung.md`; die anderen beschreiben den geerbten Kern des Schmiedespiels); `docs/SYSTEME.md` ist das Inhaltsverzeichnis. JSON-Felder: `docs/CONTENT.md`, Roguelike-Daten in `data/content/defense.json`.

## 8. Aktuelle Aufgabe und Entscheidungen

**Aktuelle Aufgabe (Branch `feature/seltenheit-ereignisse-laden`):** vier Ideen aus `skrpt3.txt` (seltener durch Siege, Ansturm und Gebietsregeln, Laden-Jackpot, Gebäude-Banner), siehe „Außerdem testen“. **Davor (Branch `feature/kristallpfad-balancing`):** Kristall-Pfad und Abstimmung 2. **Vorher (Branch `feature/roguelike-aufraeumen`):** Projekt als eigenes Spiel aufstellen (2026-11-23): Projektname „Smithy Roguelike“ (eigenes `user://`, getrennt von Smithy), Export `smithy_roguelike.exe` / `SmithyRoguelike.apk` (Paket `com.am.smithy.roguelike`), README, diese Datei. Testen: Spiel starten, Hauptmenü » Neues Spiel, ein Run bis zum Fall der Schmiede, Speichern/Laden. Spielstände aus der Zeit in Smithy liegen in `%APPDATA%\Godot\app_userdata\Smithy\defense_*.json` und werden nicht mehr gefunden; zum Weiterspielen samt `settings.cfg` nach `...\app_userdata\Smithy Roguelike\` kopieren (bei Anton am 2026-11-23 erledigt). Headless: `defense/test_defense.gd`.

**Außerdem testen:** Schmiede mit Körper und gelbe Angebote (2026-11-25): Einheiten laufen um die Schmiede herum statt hindurch; stirbt beim Bosskampf an der Schmiede die Einheit vor dem Boss, schlägt er nicht die Schmiede, sondern die nächste Einheit; „Angebot!“-Karten im Laden gelb umrandet. Headless: `defense/test_defense.gd`. Einheiten-Verbesserung nach Kristall (2026-11-25): Tab Sammlung, Feuer-/Erd-Einheiten kosten 20, Finster-Einheiten 102, Licht-Einheiten 342 Meisterschaft für Stufe 1 (je Stufe ×2). Headless: `defense/test_defense.gd`. Vier Teile aus `skrpt3.txt` (2026-11-25, `feature/seltenheit-ereignisse-laden`): Einheiten durch Siege seltener (R2 nach 5), Aufträge je Einheit (+1 Einkommen), Gebietsregel und Ansturm ab Teil 2, Laden-Jackpot, Kaserne/Tempel als Banner an der Schmiede, HUD durchsichtig über Figuren, späte Meisterschafts-Felder teurer; Bosse mit Rundumschlag, Fähigkeiten je Gebiet (Rattenkönig ruft Ratten) und Raserei beim schnelleren Tempo; Einheiten leuchten ab R2 farbig; Relikt-Liste ohne eingesetzte. Headless: `defense/test_defense.gd`. Bosskampf und Reliktplatz (2026-11-25): lebt nur noch der Boss, nach 10 s ×1,5, nach 15 s ×2 (Text an der Schmiede), danach wieder normal; Reliktplatz kostet 100 / 800 / 1600 Meisterschaft. Headless: `defense/test_defense.gd`. Sammelwunsch (2026-11-25): Bäume ziehen/zoomen, Feuer-/Erdkristall 2/3 Schläge, Sicht kleiner, Gegner ×1,4, Stopp bei neuer Einheit, Pakete mit 3 Bildern/gemischt/billiger, Filter „Im Laden“, mehr Meisterschaft später, Körper, ein Spielstand, Sprache einmal, Truhe mit Relikt-Karte, Relikt-Stufen und Relikt im Laden; Hammer ohne Schadenszahlen und stößt nicht über den Rand, kein Wackeln im Stillstand, Boss ohne Rückstoß und greift trotz Hämmern an; weniger Kristallmünzen später (Einheiten ×1,3), Esc = Pausenmenü; ein Kristall ruft 1 Einheit (30 % zwei), dafür stärker; Teile nach Thema, kein Gebiet kommt wieder; Boss und Truhe bleiben im Bild, Esc-Menü mit „Run aufgeben“. Headless: `defense/test_defense.gd`.

**Davor (in Smithy gebaut):** Schmiede-Verteidigung als Roguelite (2026-11-23). Ein Run = endlose Wellen bis die Schmiede fällt (Teil 1: 15, 25, 40 Ratten, Boss; Teil 2 Goblins, Teil 3 Orks, dann stärker von vorn). Run startet beim ersten unbesiegten Teil, ~1 min, Boss nach ~5 Versuchen. Macht es Spaß, ist es fair, läuft es flüssig? Doku: `docs/systeme/verteidigung.md`.

Höchstens 5 „Außerdem testen“-Einträge (neueste oben), jeder kurz (ein Absatz, höchstens rund 500 Zeichen): was ansehen, welcher Test. Die ausführliche Anleitung kommt gleichzeitig in `docs/VERLAUF.md` unter „Noch zu testen“, dazu eine Zeile in `docs/TESTPLAN.md`. Die Test-Einträge des Schmiedespiels stehen dort weiter (bis 2026-11-22).

**Offene Entscheidungen:**

- [x] Perspektive: Top-Down, Basisauflösung 640×360
- [x] Sprache für Code und Kommentare: Englisch
- [x] Eigenes Repo statt Modus im Schmiedespiel (2026-11-23)
- [ ] Code des Schmiedespiels (Story, Karten, Schmieden, Helden) aus dem Projekt entfernen? Dafür müssen `GameState` und `ContentDB` vom Schmiedespiel gelöst werden (größerer Umbau).

**Entscheidungslog:** steht in `docs/ENTSCHEIDUNGEN.md` (neue Entscheidungen dort unten anhängen).

## 9. Bekannte Probleme

Vollständige Liste: `docs/PROBLEME.md` (vor Änderungen an einem System dort nach dem Namen suchen; neue Probleme dort eintragen, erledigte löschen).

Wichtig für jede Aufgabe:

- Die Schrift Micro 5 hat keine Zeichen „→“ und „✓“ – in Spieltexten „»“ bzw. Wörter verwenden.
- Viele Zahlen (Preise, Kampf-, Seltenheits- und Skillwerte) sind ein erster Vorschlag und nicht ausbalanciert.
- Keine TileMap: Böden sind gebackene Bilder je Karte. Offene Grafiken: `docs/PIXELLAB_TODO.md`.

## 10. Nützliche Quellen

- Godot-Dokumentation: https://docs.godotengine.org
- Tutorial „Your first 2D game“ (in der Dokumentation unter „Getting started“)
- Asset-Quellen für Platzhalter und Grafik (Lizenz immer prüfen): Kenney.nl, itch.io, OpenGameArt.org
- PixelLab (pixellab.ai): KI-Pixel-Art (Figuren, Stationen in 8 Rotationen). In Claude Code als MCP-Server einrichtbar: `claude mcp add pixellab https://api.pixellab.ai/mcp -t http -H "Authorization: Bearer <eigener-schlüssel>"` – jeder mit eigenem Schlüssel, Schlüssel nie ins Repository.
