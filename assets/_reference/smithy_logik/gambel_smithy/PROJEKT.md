# PROJEKT.md – Smithy Gamba

> Diese Datei gehört in den Wurzelordner des Godot-Projekts. Sie wird jedem neuen KI-Chat bzw. jeder Claude-Code-Sitzung als Kontext mitgegeben (bei Claude Code kann sie zusätzlich als `CLAUDE.md` abgelegt oder von dort verlinkt werden).
> Nach jedem abgeschlossenen Schritt aktualisieren: `docs/UEBERBLICK.md` (nur Name neuer Systeme), `docs/systeme/<system>.md` (Kurzfassung oben + Details; Inhaltsverzeichnis `docs/SYSTEME.md`), Abschnitt 8 und `docs/ENTSCHEIDUNGEN.md` (neue Entscheidungen), `docs/PROBLEME.md` (bekannte Probleme).
> Diese Datei kurz halten – sie wird bei jeder KI-Anfrage komplett mitgeschickt. Details gehören nach `docs/`. Abschnitt 8: nur die aktuelle Aufgabe und höchstens 5 Test-Einträge, Älteres nach `docs/VERLAUF.md`. Ordnerbaum und die Liste „Fertige Systeme“ stehen in `docs/UEBERBLICK.md`.

---

## 1. Projekt in Kürze

- **Titel:** Smithy Gamba (Arbeitstitel), Godot-Projektname „Smithy Gamba“, im Spiel „Die Glücksschmiede“
- **Was:** 2D-Pixel-Art-Roguelite mit Glücksspiel-Mechanik: Schwerter erhitzen und auf dem Amboss schlagen; jeder Schlag zieht aus fünf Eimern (zerbrochen | beschädigt | nichts | verbessert | verbessert ++), mit jedem Schlag wird Zerbrechen wahrscheinlicher. Abends Abgabe in Schwertwert an die Zunft, dreimal zu wenig beendet den Run; Relikte (gegen Schwerter im Reliktschrein), Händler, Raserei. Ein Run = 21 Tage. Alles Wichtige: `docs/systeme/gluecksschmiede.md`.
- **Herkunft:** Kopie von **Smithy Roguelike** (Repo `SkyTheLie/Smithy-roguelike`, Stand `feature/kristallpfad-balancing`, 2026-11-25), das selbst aus dem Schmiedespiel **Smithy** stammt. Läuft auf dem Kern von Smithy (`GameState`, `ContentDB`, `Language`, `AudioManager`, Grafiken). Der Code der Verteidigung (`scenes/defense/`) und des Schmiedespiels liegt noch im Projekt, ist vom Hauptmenü aus nicht erreichbar. Die meiste Doku in `docs/` beschreibt noch diese Spiele.
- **Plattform:** PC (Windows) als Hauptversion, dazu Android-APK aus demselben Projekt (Handy-Besonderheiten nur hinter `MobileUi.active()`, `docs/systeme/ui.md`). Einzelspieler.
- **Entwicklung:** Zu zweit (Informatikstudent als Hauptentwickler, **Anfänger in Spieleentwicklung und Godot**, plus ein Mitentwickler), ca. 10 Stunden pro Woche, mit KI-Unterstützung (Claude Code).
- **Erfolgskriterium:** Eine andere Person kann das Spiel starten, verstehen und spielen; ein Tag dauert wenige Minuten, das Glücksspiel macht Spaß, ist fair und läuft flüssig.

## 2. Technik

- **Engine:** Godot 4.x (aktuelle stabile Version, Standard-Version, nicht .NET)
- **Sprache:** GDScript (statisch typisiert)
- **Renderer / Ansicht:** 2D, Pixel Art, Top-Down (entschieden, siehe Abschnitt 8); Basisauflösung 640×360, Stretch-Modus `canvas_items` (nicht ganzzahlig, wegen `HiResTexture` und 1600×900), Renderer GL Compatibility
- **Daten:** Items, Materialien, Rezepte, Status-Effekte, Skills, Skillbäume, Beschwörungen, Gegner, Dungeons, Kampf-Formeln und Schmiede-Muster als JSON in `data/content/` (inkl. Sockel-Boni `sockets.json`; Anleitung: `docs/CONTENT.md`), übrige Daten (Aufträge, Steine, Helden, Klassen, Teleport-Ziele …) als Godot-Resources (`.tres`) – nie im Code hartkodiert
- **Speichern:** ein Spielstand `user://gamba_save.json` (`GambaSaves`), automatisch nach jedem Tag. Das Nutzerverzeichnis hängt am Projektnamen: Smithy Gamba hat ein eigenes, getrennt von Smithy und Smithy Roguelike.
- **Versionsverwaltung:** Git + GitHub (`SkyTheLie/Smithy-Gamba`), Arbeit auf Branches, siehe Abschnitt 4a. Zu zweit entwickelt.
- **Export:** Windows (`smithy_gamba.exe`) und Android (`SmithyGamba.apk`, Paket `com.am.smithy.gamba`, lässt sich neben Smithy installieren), beide aus `export_presets.cfg`; APK bauen und aufs Handy: `docs/ANDROID.md`

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
4. Branch hochladen: `git push -u origin feature/kurze-beschreibung` (`origin` = `SkyTheLie/Smithy-Gamba`, Ordner `gambel_smithy`).
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

Die Glücksschmiede ist in einer ersten Fassung gebaut (Stand 2026-11-25, `docs/systeme/gluecksschmiede.md`): Run über 21 Tage, Schmieden mit fünf Eimern und Drift der Lose, Raserei, Abgabe mit 3 Fehlschlägen, 14 Relikte über den Reliktschrein (Schwert » Zunftmarke » Relikt), 2 Verbrauchsgüter, Händler alle 3 Tage, Hauptmenü, Pausenmenü, ein Spielstand mit Autosave nach jedem Tag.

**Nicht ungefragt bauen:** neue Spielsysteme (z. B. Fortschritt zwischen den Runs), Story, Rückbau des Codes von Verteidigung und Schmiedespiel (siehe Abschnitt 1, „Herkunft“; erst mit dem Entwickler abstimmen). Ideen für später in `ideen.txt`.

## 7. Fortschritt

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Kopie aus Smithy Roguelike: eigenes Repo, Projektname, Export, Doku | erledigt (2026-11-25) |
| 1 | Spielbarer Kern: Run, Schmieden, Eimer, Raserei, Abgabe, Relikte, Händler, Spielstand | erste Fassung (2026-11-25), Zahlen mit `gamba/sim_gamba.gd` abgestimmt, nicht endgültig |
| 2 | Playtest: Spaß, Fairness, Verständlichkeit | offen |
| 3 | Eigene Grafik/Musik, Rückbau nicht gebrauchter Teile | offen |
| 4 | Veröffentlichung | offen |

Beschreibung jedes Systems: eine Datei je System in `docs/systeme/` (dieses Spiel: `gluecksschmiede.md`; `verteidigung.md` und die anderen beschreiben geerbte Spiele und den Kern); `docs/SYSTEME.md` ist das Inhaltsverzeichnis. JSON-Felder: `docs/CONTENT.md`, Daten dieses Spiels in `data/content/gamba.json`.

## 8. Aktuelle Aufgabe und Entscheidungen

**Aktuelle Aufgabe (Branch `feature/gluecksschmiede`):** Neues Spiel Smithy Gamba (2026-11-25): Kopie von Smithy Roguelike im Ordner `gambel_smithy`, Repo `SkyTheLie/Smithy-Gamba`, Projektname „Smithy Gamba“, Export `smithy_gamba.exe` / `SmithyGamba.apk`. Darin die Glücksschmiede nach Vorgabe und Skript `r.txt` (siehe „Außerdem testen“).

**Außerdem testen:** Relikt ablegen (2026-11-25, `fix/fenster-scrollen`): mit 5 Relikten ein sechstes im Schrein nehmen » Fenster zeigt alle 5 in 2 Reihen, passt auf den Bildschirm, Karten scrollen bei kleinem Fenster. Test `gamba/test_gamba.gd`.

Glücksschmiede (2026-11-25): Neues Spiel » Regeln (kein Gratis-Relikt); „Schmieden“ erhitzt ein Kupferschwert, Klick/Leertaste schlägt, fünf Eimer, Raserei nach 12 Schlägen; „Abgeben“, „Glocke läuten“, Händler nach Tag 3; oben „Reliktschrein“: Schwert ab R4 einzahlen » Marke » Relikt (1–3 Marken), neue Angebote nach jeder Glocke; schwer genug, aber fair? 3 Fehlschläge » Ende; „Weiterspielen“; Esc. Headless: `gamba/test_gamba.gd`, Simulator `gamba/sim_gamba.gd`.

**Davor (Smithy Roguelike):** Schmiede-Verteidigung (2026-11-23 bis 11-25), Doku `docs/systeme/verteidigung.md`, Test-Anleitungen in `docs/VERLAUF.md`.

Höchstens 5 „Außerdem testen“-Einträge (neueste oben), jeder kurz (ein Absatz, höchstens rund 500 Zeichen): was ansehen, welcher Test. Die ausführliche Anleitung kommt gleichzeitig in `docs/VERLAUF.md` unter „Noch zu testen“, dazu eine Zeile in `docs/TESTPLAN.md`. Die Test-Einträge des Schmiedespiels stehen dort weiter (bis 2026-11-22).

**Offene Entscheidungen:**

- [x] Perspektive: Top-Down, Basisauflösung 640×360
- [x] Sprache für Code und Kommentare: Englisch
- [x] Eigenes Repo statt Modus im Schmiedespiel (2026-11-23)
- [x] Glücksschmiede als eigenes Spiel in eigenem Repo (2026-11-25)
- [ ] Fortschritt zwischen den Runs (Meisterschaft, freischaltbare Relikte)? Noch nicht gebaut.
- [ ] Code der Verteidigung und des Schmiedespiels (Story, Karten, Schmieden, Helden) aus dem Projekt entfernen? Dafür müssen `GameState` und `ContentDB` vom Schmiedespiel gelöst werden (größerer Umbau).

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
