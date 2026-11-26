# PROJEKT.md – Smithy

> Diese Datei gehört in den Wurzelordner des Godot-Projekts. Sie wird jedem neuen KI-Chat bzw. jeder Claude-Code-Sitzung als Kontext mitgegeben (bei Claude Code kann sie zusätzlich als `CLAUDE.md` abgelegt oder von dort verlinkt werden).
> Nach jedem abgeschlossenen Schritt aktualisieren: `docs/UEBERBLICK.md` (nur Name neuer Systeme), `docs/systeme/<system>.md` (Kurzfassung oben + Details; Inhaltsverzeichnis `docs/SYSTEME.md`), Abschnitt 8 und `docs/ENTSCHEIDUNGEN.md` (neue Entscheidungen), `docs/PROBLEME.md` (bekannte Probleme).
> Diese Datei kurz halten – sie wird bei jeder KI-Anfrage komplett mitgeschickt. Details gehören nach `docs/`. Abschnitt 8: nur die aktuelle Aufgabe und höchstens 5 Test-Einträge, Älteres nach `docs/VERLAUF.md`. Ordnerbaum und die Liste „Fertige Systeme“ stehen in `docs/UEBERBLICK.md`.

---

## 1. Projekt in Kürze

- **Titel:** Smithy (Arbeitstitel)
- **Was:** 2D-Pixel-Art-Schmiedespiel. Der Spieler ist ein Schmied in einem Dorf, schmiedet Waffen, Rüstungen und Zubehör, nimmt Aufträge an, zahlt Miete und schickt angeheuerte Helden in Dungeons.
- **Plattform:** PC (Windows) als Hauptversion, dazu Android-APK aus demselben Projekt (Handy-Besonderheiten nur hinter `MobileUi.active()`, `docs/systeme/ui.md`). Einzelspieler.
- **Entwicklung:** Zu zweit (Informatikstudent als Hauptentwickler, **Anfänger in Spieleentwicklung und Godot**, plus ein Mitentwickler), ca. 10 Stunden pro Woche, mit KI-Unterstützung (Claude Code).
- **Ausführliches Design:** siehe GDD (Game Design Document). Bei Widersprüchen gilt das GDD.
- **Erfolgskriterium:** Eine andere Person kann das Spiel starten, verstehen und spielen.

## 2. Technik

- **Engine:** Godot 4.x (aktuelle stabile Version, Standard-Version, nicht .NET)
- **Sprache:** GDScript (statisch typisiert)
- **Renderer / Ansicht:** 2D, Pixel Art, Top-Down (entschieden, siehe Abschnitt 8); Basisauflösung 640×360, Stretch-Modus `canvas_items` (nicht ganzzahlig, wegen `HiResTexture` und 1600×900), Renderer GL Compatibility
- **Daten:** Items, Materialien, Rezepte, Status-Effekte, Skills, Skillbäume, Beschwörungen, Gegner, Dungeons, Kampf-Formeln und Schmiede-Muster als JSON in `data/content/` (inkl. Sockel-Boni `sockets.json`; Anleitung: `docs/CONTENT.md`), übrige Daten (Aufträge, Steine, Helden, Klassen, Teleport-Ziele …) als Godot-Resources (`.tres`) – nie im Code hartkodiert
- **Speichern:** Spielstand als Datei im Nutzerverzeichnis (`user://`), mehrere Speicherplätze
- **Versionsverwaltung:** Git + GitHub (`SkyTheLie/Smithy`), Arbeit auf Branches, siehe Abschnitt 4a. Zu zweit entwickelt.
- **Export:** Windows (`game.exe`) und Android (`Smithy.apk`), beide aus `export_presets.cfg`; APK bauen und aufs Handy: `docs/ANDROID.md`

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
4. Branch hochladen: `git push -u origin feature/kurze-beschreibung`.
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

## 6. Umfang Version 1 (Vertical Slice)

> Stand 2026-11: Dies ist der ursprüngliche Plan. Das Spiel ist längst darüber hinaus (Story Teil 1–8, 52 Dungeons, Verzaubern, Zauberstäbe, Handel …); was gebaut ist, steht in `docs/UEBERBLICK.md`. Für neue Aufgaben gilt: nur bauen, was angefragt ist.

**Enthalten:**

- Spielfigur, kleines Dorf, Schmiede
- Inventar, Geld, Miete
- Ein kompletter Schmiedeablauf: Erz → Barren → Waffe (Rezept wählen → Form gießen → Amboss-Minispiel → im Wasser abkühlen → am Arbeitstisch zusammenbauen)
- Brennstoff: Holz (1× schmieden), optional Steinkohle (5×)
- Erze: Kupfer, Eisen, Silber (Vorschlag)
- ca. 5–8 Gegenstände, ca. 5–10 Aufträge
- Story-Einstieg: Schmiede mieten, Holzfäller (Holzaxt gratis, danach 1 Holz pro Tag), Betrunkener als erster Held
- Ein Held, ein Dungeon (vereinfacht, läuft automatisch ab, Ergebnis nach Zeit)
- Leveln, Rezepte freischalten
- Speichern und Laden
- Grundlegende Soundeffekte, einfache Hintergrundmusik

**Nicht in Version 1 (Backlog):** Legieren (neu erhitzen → Öl → neu erhitzen → Wasser), Klingen schärfen, Verzaubern, Ausrüstung der Schmiede aufwerten/kaufen (Hammer, Ofen, Amboss), Handel, Dorfausbau, Feuerorb (20 Schmiedevorgänge, mit Magie auffüllbar), Zauberstäbe und Elementmagie, Bögen mit Pfeilarten, Zusatzstationen (Leder, Bogensehnen, Pflanzen), weitere Dungeons, Konkurrenz-Schmiede, Multiplayer, große offene Welt. Status jeder Idee: siehe `ideen.txt`.

## 7. Fortschritt

Roadmap-Phasen (Status bei Abschluss eintragen; Stand 2026-11-13 aus der Doku nachgezogen, bitte gegenlesen):

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Vorbereitung: Godot, Git, Tutorial, PROJEKT.md | erledigt |
| 1 | Spielerfigur und Welt (Bewegung, Kamera, Karten) | erledigt (2026-10-13); seither rund 100 Karten, Böden als gebackene Bilder statt TileMap, offene Grafiken in `docs/PIXELLAB_TODO.md` |
| 2 | Datenbasis: Items, Rezepte, Inventar | erledigt (2026-10-13) |
| 3 | Schmiede-Kern: Schmelzen, Amboss, Minispiel, Waffe | erledigt (kompletter Ablauf inkl. Abkühlen und Zusammenbau, dazu Legieren, Schärfen, Verzaubern, Schmuck, Tränke) |
| 4 | Wirtschaft: Kunden, Aufträge, Geld, Miete, Level | erledigt: Tageszeit, Spieler-Level/Skills, Aufträge, Kunden, Ruf, Miete, Händler, Ninas Laden, Hausausbau, Turniere; Zahlen nicht ausbalanciert (Abschnitt 9) |
| 5 | Held und Dungeon (vereinfacht) | erledigt (2026-10-13): Gilde, Ausrüstung, Level 1–100, Skillbäume für 6 Klassen, Idle-Kampf mit Skills; seither 52 Dungeons, Bosse mit Phasen, Heldenturnier |
| 6 | Speichern/Laden, Menü, Tutorial, Sound, echte Grafik | teilweise: Hauptmenü, Story komplett (Teil 1–8), Kalender, Speichern/Laden, Lehrgänge und goldenes Leuchten als Tutorial, elf Sprachen (Deutsch, Englisch, Spanisch, Französisch, Chinesisch, Persisch, Russisch, Japanisch, Portugiesisch, Koreanisch, Polnisch; weitere in `docs/SPRACHEN_TODO.md`), Geräusche mit 5 Lautstärke-Reglern; offen: restliche Platzhalter-Grafik (`docs/PIXELLAB_TODO.md`), eigene Musik |
| 7 | Playtest und Veröffentlichung | offen (Trailer-Testschnitt in Arbeit, Abschnitt 8) |

**Fertige Systeme:** Die Liste aller Namen steht in `docs/UEBERBLICK.md` (neue Namen dort hinten anhängen).

Beschreibung jedes Systems: eine Datei je System in `docs/systeme/` (oben Zweck, Dateien, Tests und Kurzfassung, darunter Details); `docs/SYSTEME.md` ist das Inhaltsverzeichnis. JSON-Felder: `docs/CONTENT.md`.

## 8. Aktuelle Aufgabe und Entscheidungen

**Aktuelle Aufgabe:** Trailer-Testschnitt ansehen (2026-11-02, Branch `feature/trailer-aufnahme`): 3 Szenen werden per Skript im echten Spiel aufgenommen (Godot Movie Maker, 1920×1080, 60 fps, Texte Englisch, ohne HUD): Amboss-Minispiel mit perfekten Treffern, Bosskampf gegen den Glutdrachen (für die Aufnahme kürzere Lebensbalken), Kamerafahrt über den Markt. `make_test_cut.sh` schneidet sie mit Texten und Endtafel zu `trailer_test.mp4`. Passen Tempo, Bildausschnitt, Texte? Aufnehmen: `sh assets/_reference/trailer/record.sh <anvil|boss|market> <Ordner>`, dann `sh assets/_reference/trailer/make_test_cut.sh <Ordner>`. Musik fehlt noch (lizenziertes Stück nötig).

**Außerdem testen:** Bindungs-Paket (2026-11-25, acht Branches `feature/glueckstreffer` bis `feature/spiel-protokoll`): Glückstreffer an der Werkbank + Skill Glückshand, Powernap im Bett, Wunsch-Kunden, Ziele im Tracker, Sammelbuch im Lexikon, Endloser Turm (nach dem Ende), Schmiedin + Schneiderin Wilma am Markt, Spiel-Protokoll `play_log.csv`. Anleitung: `docs/VERLAUF.md` (Abschnitte 1, 2, 9). Headless: `lucky_strike/`, `power_nap/`, `wish_customers/`, `goals/`, `collection_book/`, `endless_tower/`, `tailor/`, `play_log/`.
**Außerdem testen:** Koreanisch und Polnisch (2026-11-24, `feature/sprache-ko-pl`): zehnte und elfte Flagge „한국어“ und „Polski“ in der Sprachwahl; Oberfläche, Tipps, Story und Namen übersetzt, Hangul scharf im Pixel-Stil (Fusion Pixel), polnische Zeichen (ą ę ł ż …) in Micro 5, keine Kästchen, nichts abgeschnitten; Item-Namen „구리 검“ bzw. „Miecz (Miedź)“. Headless: `i18n/test_korean.gd`, `i18n/test_polish.gd`.
**Außerdem testen:** Portugiesisch/Brasilien (2026-11-24, `feature/sprache-portugiesisch`): neunte Flagge „Português“ (Brasilien) in der Sprachwahl; Oberfläche, Tipps, Story und Namen portugiesisch, Akzente (ã, ç, é …) im Pixel-Stil, nichts abgeschnitten (portugiesische Texte sind länger); Item-Namen „Espada de Cobre“, Kundenwunsch „um(a) …“. Headless: `i18n/test_portuguese.gd`.
**Außerdem testen:** Sprechblase statt „!“ (2026-11-24, `feature/sprechblase-marker`): Story-Figuren mit etwas Neuem zeigen eine goldene Sprechblase, nach dem zu Ende gelesenen Gespräch ist sie weg (auch nach Kartenwechsel). Auftraggeber (Holger): „!“ = neuer Auftrag, „?“ sofort nach dem Annehmen bis zum Abgeben. Kunden behalten „!“. Headless: `npc_markers/test_npc_markers.gd`.
**Außerdem testen:** Japanisch (2026-11-24, `feature/sprache-japanisch`): achte Flagge „日本語“ in der Sprachwahl; Oberfläche, Tipps, Story und Namen japanisch, Kanji und Kana scharf im Pixel-Stil (Fusion Pixel ja), keine Kästchen, Zeilen brechen sauber um, nichts abgeschnitten; Item-Namen „銅の剣“. Headless: `i18n/test_japanese.gd`.

Höchstens 5 „Außerdem testen“-Einträge (neueste oben), jeder kurz (ein Absatz, höchstens rund 500 Zeichen): was ansehen, welcher Test. Die ausführliche Anleitung kommt gleichzeitig in `docs/VERLAUF.md` unter „Noch zu testen“ (oben in den passenden Bereich), dazu eine Zeile in `docs/TESTPLAN.md`. Kommt ein neuer Eintrag dazu, fällt der älteste hier weg (in VERLAUF steht er schon). Ältere Test-Anleitungen: dort.

**Offene Entscheidungen:**

- [x] Perspektive: Top-Down
- [x] Sprache für Code und Kommentare: Englisch
- [x] Basisauflösung für die Pixel-Art-Darstellung: 640×360
- [x] Wie sieht das Schmiede-Minispiel konkret aus? → Takt-Klickspiel, siehe Abschnitt 7
- [x] Gibt es in Version 1 ein Spielende? → Ja: Abspann nach Teil 8, Aufwachen in der Schmiede, danach geht das Spiel frei weiter
- [x] Nicht gezahlte Miete: Oma versucht es jeden Morgen erneut, jeder Tag kostet Ruf (früher 10 Karma, siehe `docs/ENTSCHEIDUNGEN.md`)
- [ ] Wie läuft der Wettbewerb um den Titel des Schmieds ab (Konkurrenten, Siegbedingung)?

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
