# PROJEKT.md – Smithy Dungeon 2

> Wird jeder KI-Sitzung mitgegeben (über `CLAUDE.md`). Kurz halten, Details in `docs/`.
> Nach jedem Schritt aktualisieren: `docs/SYSTEME.md` (Systeme), `docs/ROADMAP.md` (Status), `docs/ENTSCHEIDUNGEN.md`, `docs/PROBLEME.md`, Abschnitt 8 hier.

## 1. Projekt in Kürze

- **Titel:** Smithy Dungeon 2 (Arbeitstitel)
- **Was:** Roguelite-RPG. Dungeon-Runs wie in **Dungeon Smithy** (Ego-Sicht, Feuerbälle, Items mit Synergien, Räume, Boss). **Neu:** Zwischen den Runs ein Laden beim gaunerhaften **Händler**: Beute verkaufen, Glücksspiel-Ware würfeln (einmal am Tag frei), Ausrüstung und Tränke kaufen und anlegen. Die Ausrüstung bleibt über Runs erhalten. Story-Intro mit dem Händler. Am Anfang nur der Magier, später Bogenschütze und Schwertkämpfer.
- **Herkunft:** Kopie von Dungeon Smithy (`SkyTheLie/Smithy-dungeon`, `main` vom 2026-11-26). Grafik und Ton aus **allen** Smithy-Spielen in `assets/`, deren Spiellogik als Nachschlage-Bibliothek in `assets/_reference/smithy_logik/` (`docs/SMITHY_LOGIK.md`).
- **Ideen (sortiert):** `docs/IDEEN.md` · **Plan:** `docs/ROADMAP.md`
- **Plattform:** PC (Windows), Einzelspieler (Koop später).
- **Entwicklung:** zu zweit, Hauptentwickler Anfänger in Godot, mit Claude Code.
- **Kein Nachbau eines bestimmten Spiels:** eigene Items, eigene Namen, eigene Grafik (Smithy).

## 2. Technik

- **Engine:** Godot 4.7 (Standard, nicht .NET), Renderer GL Compatibility, GDScript statisch typisiert
- **Ansicht:** Dungeon: 3D-Welt in einem `SubViewport` 640×360, scharf hochskaliert (Pixel-Look). Laden und Menüs: 2D, 640×360, Stretch `canvas_items`
- **Daten:** alles Spielbare als JSON in `data/` (Items, Synergien, Gegner, Ebenen, Charaktere, Startwerte, Töne, Beute `loot.json`, Spielstand-Regeln `meta.json`, Dungeons `dungeons.json`, Ausrüstung `gear.json`, Laden `shop.json`, Tränke `potions.json`, Texte der Figuren `story.json`) – nie im Code. Anleitung: `docs/CONTENT.md`
- **Speichern:** Ein Run wird nicht gespeichert. Gespeichert: Einstellungen (`user://settings.cfg`), Fortschritt (`user://progress.cfg`), Spielstand je Platz A/B/C (`user://save_<platz>.cfg`, `MetaState`: Dose (alles Gold zu Hause), mitgebrachte Beute, Tag; gespeichert am Ende jedes Tages). Eigener `user://`-Ordner („Smithy Dungeon 2“), getrennt von Dungeon Smithy.
- **Sprachen:** deutscher Text = Schlüssel, `locale/<sprache>.po`, 9 Sprachen. Ablauf: `docs/SPRACHEN.md`

## 3. Ordner

```
res://
├── assets/      # Grafik/Ton aus allen Smithy-Spielen: sprites/, audio/, fonts/, ui/
│   └── _reference/   # nicht im Spiel (.gdignore): Tests, Übersetzungs-Skript, smithy_logik/ (Code aller Smithy-Spiele), vorlagen/ (Skizzen)
├── data/        # JSON: items, synergies, enemies, floors, characters, player, audio
├── docs/        # Doku (IDEEN, ROADMAP, SMITHY_LOGIK, SYSTEME, CONTENT …)
├── locale/      # <sprache>.po
├── scenes/      # actors/, objects/, run/ (Dungeon), ui/ (Menüs, HUD)
└── scripts/     # core/ (Autoloads Game, AudioManager; Content, Language, Controls, WindowLayout), systems/ (RunState, ShotStats, FloorLayout, Fx, Progress)
```

Skripte, die zu einer Szene gehören, liegen neben ihr. Klassen ohne Szene bauen ihre Kinder im Code.

## 4. Konventionen

Dateien `snake_case`, Klassen `PascalCase`, Bezeichner und Kommentare **Englisch**, Spieltexte **Deutsch** (Schlüssel für die Übersetzung), jeder sichtbare Text über `Language.translate` bzw. Godots Auto-Übersetzung, statische Typen, Signale in Vergangenheitsform.

## 4a. Git

Eigenes Repository, Remote `origin` = https://github.com/SkyTheLie/Smithy-dungeon2. `main` bleibt lauffähig, Arbeit auf Branches (`feature/…`, `fix/…`), kurze deutsche Commit-Nachrichten. `.godot/` nicht committen, `.import`/`.uid` schon.

## 5. Regeln für die KI

1. Godot 4 / GDScript 2.0, statisch typisiert.
2. Kleine Schritte, nur das Angefragte bauen (Reihenfolge: `docs/ROADMAP.md`). Neue Ideen in `docs/IDEEN.md`.
3. Kurz erklären, was der Code macht; der Entwickler ist Godot-Anfänger.
4. Vollständiger, lauffähiger Code, keine Platzhalter.
5. Daten statt Code: neue Items, Gegner, Ebenen, Ware nur in `data/`.
6. Vor Änderungen die Dateien lesen; keine großen Umbauten ohne Rückfrage.
7. Code aus `assets/_reference/smithy_logik/` nicht direkt laden, sondern nach `scripts/`/`scenes/` kopieren und anpassen (keine Smithy-Autoloads wie `GameState`, `ContentDB`).
8. Nach jeder Aufgabe: Tests (`bash assets/_reference/run_tests.sh`), sagen, was im Spiel zu testen ist, Doku nachziehen.
9. Neue Texte: `py assets/_reference/i18n/build_po.py` muss „0 problems“ melden.
10. Regeln gegen bekannte Fehler: `docs/FEHLERKLASSEN.md`.
11. **Dialoge:** Jeder Text einer Figur wird aus ihrer Charakter-Datei in `docs/figuren/` gebaut (Egon Ehrlich: `docs/figuren/EGON_EHRLICH.md`). Neue Fakten über eine Figur dort eintragen.

## 6. Umfang

**Übernommen aus Dungeon Smithy (läuft):** Hauptmenü und Sprachwahl, 6 Ebenen in 3 Themen, Item-Raum, Shop, Geheimraum, Opferstein, Glutpakt, Boss, 203 Items, 14 Synergien (Waffen-Kreuzung Feuerhieb), 28 Gegner, 3 Charaktere (Magier; Bogenschütze und Krieger freischaltbar, gespielt wird die Klasse der angelegten Waffe) mit Hauptwaffe als Start-Item, Lexikon, Testraum (P im Editor).

**Neu gebaut:** Beute von Gegnern, Inventar auf Tab (Drag & Drop, fallen lassen, sicherer Platz), Geldbündel, Spielstand A/B/C mit Dose und Diebstahl-Regel, Karte auf M, Intro mit Egon, Egons Laden (Hebel, Kaufen, Ausrüstung anlegen, Tour beim ersten Besuch), Dungeon-Brett.

**Ziel Version 1 (neu):** Laden mit Glücksspiel-Tisch, Ausrüstung mit Seltenheit, Trank-Slot, Intro mit dem Händler, erster Dungeon ohne Item-/Shop-Raum. Details und Reihenfolge: `docs/ROADMAP.md`.

**Gebaut (2026-11-27):** vier Dungeons mit Material-Stufen (Kupfer bis Gold), Fallen, Balance-Rechner; fünfter Dungeon Wispernde Wiese (hohes Gras, Fangeisen, 15 Gegner mit eigenen Mustern, Bosse Wildhüter und Kristallkoloss); Tränke mit Trank-Platz (Q), Egons Trank-Vorführung nach dem 2. Tod.

**Später:** Schmieden mit Smithy-Minispielen, Zauberstab-Relikte, Koop.

## 7. Fortschritt

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Projekt angelegt, Assets und Logik aller Smithy-Spiele, Ideen sortiert | erledigt (2026-11-26) |
| 1 | Spielstand und Laden | Beute, Inventar, Spielstand (Plätze A/B/C), Dose, Ausrüstung, Laden mit Hebel/Kaufen/Anlegen, Dungeon-Brett: erledigt (2026-11-26); Verkaufen und Dose im Laden offen |
| 2 | Intro und Händler-Story | Intro mit Dialog vor dem Dungeon-Eingang, geführter erster Laden-Besuch: erledigt (2026-11-26); Klassen-Frage offen |
| 3 | Ausrüstung im Run, Tränke | Rüstung = Schild-Herzen, Waffe = Schaden, Relikte: erledigt (2026-11-26); Tränke mit Trank-Platz: erledigt (2026-11-27); Trank-Skills offen |

## 8. Aktuelle Aufgabe

**Zuletzt gebaut (2026-11-27):** **Karte zeigt liegende Dinge:** Herzen, Bomben, Schlüssel, Beute und Items auf Sockeln als kleine Bilder (Minimap im Raum; große Karte M/Tab: Reihe unten in jedem besuchten Raum, zu viele = „+“). Im Spiel testen: Raum mit Beute verlassen → M → Bilder im Raum, aufheben → verschwindet. Davor (Liste `docs/AUFGABEN.md`, alle 14 erledigt): Händler im Dungeon mit F (Handelsfenster, Relikt kaufen); Start ohne Schlüssel, Schlüssel zerbrechen beim Verlassen (Egon erklärt es); erste Ebene mit 6 Räumen (Boss + Opferraum); „Hier klicken“ nur einmal; Gegner-Töne in 3D; jede Skill-Stufe ein eigenes Feld, Punkte-Skills links, Gold-Skills rechts; Seil nur nach Boss-Sieg, Falltür wie vorher; Blaues Herz statt Zähigkeit, Reliktschutz; Maus-Empfindlichkeit wie CS2; Fadenkreuz wie CS2; Blickrichtungs-Keil unter Gegnern; langsameres Leveln am Anfang; Dungeon-Brett nur offene Dungeons, Gegner im Lexikon; Schadenszahlen, Treffer-Marker, Konfetti, Beute-Popups, Herzschlag-Rand, federnde Knöpfe, EXP-Feier. Davor: **Schlüssel sehr selten:** eine Chance für alle Gegner (`data/loot.json` `key_chance`, 0,3 %), keine Schlüssel mehr aus Raum-Belohnungen; Inventar-Fenster nur so hoch wie sein Inhalt. Davor: **Boss-Halle** (`scenes/run/boss_hall.gd`, `data/boss_hall.json`): Boss-Raum = Vorhalle mit Tor, dahinter große Halle mit Altar der Neun und 9 Säulen; Szene mit fliegenden Kristallen, Energie in den Rillen, Stille, Boss fällt herein, Rock-Musik (`boss_rock`). **Admin-Menü** auf P (nur im Editor): Reisen, Items, Ausrüstung/Relikte, Cheats. Im Spiel testen: Dungeon starten → P → „Boss-Halle“ → zum Altar laufen → ganze Szene ansehen; Admin: Ebene/Dungeon wechseln, Items geben, Ausrüstung anlegen. Davor: Tauben (`city_7_walk`) auf sichtbaren Fallen, die beim Hineintreten auffliegen; Logik für eigene Fallen des Spielers (treffen nur Gegner, Item-Feld `traps`); Vulkandrache als großer End-Boss des Glutschlunds (128×96-Bild, eigene Arena mit Lava). Im Spiel testen: Glutschlund Ebene 6 (Testraum/Sieg) → Drache groß, Feuer-Bild beim Spucken, Lava in der Arena; Moor → Tauben auf Giftpfützen, hineintreten → sie fliegen weg. Davor `feature/wiese-traenke`: **Tränke** (`data/potions.json`): nach dem 2. Tod zeigt Egon sie (Hebel gratis, Heiltrank geschenkt, in den Trank-Platz neben den Füßen der Helden-Figur), danach liegen Tränke auf dem Tisch; Q trinkt im Dungeon (+2 Herzen). **Wispernde Wiese** (nach dem Moor): hohes Gras (`scenes/run/meadow.gd`), versteckte Fallen und Fangeisen (hält fest), 15 neue Gegner mit eigenen Mustern (`scenes/actors/enemy_moves.gd`, Laser `enemy_beam.gd`), Bosse Wildhüter (Abstand, Ausweichen, Bogen mit Ziel-Linie, 3 Fangeisen) und Kristallkoloss (Laser). Im Spiel testen: zweimal sterben → Laden: Egons Vorführung → im Dungeon Leben verlieren, Q drücken. Moor schaffen (oder `win_dungeon`) → Wiese betreten: Gras, Fangeisen, jedes neue Muster, Ebene 6 Wildhüter. Davor `feature/balance`: vier Dungeons (Glut, Moor der Irrlichter, Frostgipfel, Glutschlund; der nächste öffnet nach dem Sieg), 65 neue Gegner/Bosse, Fallen (Gift, Stacheln, Eis, Lava), Materialien bei Egon (Kupfer, Bronze ab Stufe 3, Eisen nach Dungeon 1, Silber, Gold), Balance nach Rechner (`docs/BALANCE.md`). Im Spiel testen: neues Spiel → Dungeon-Brett zeigt Moor gesperrt → im ersten Dungeon prüfen, ob Ebene 2–3 machbar ist → mit Testraum/Sieg das Moor öffnen → Giftpfützen und Stacheln (Takt, Schaden) → bei Egon taucht Eisen auf, Hebel teurer. Davor `feature/laden-skills`: Bei Egon wird jeder weitere Hebel-Zug am selben Tag besser (5 % von R1 zu den selteneren Stufen, höchstens 25 %, R1 nie unter 10 %). Neue Skill-Gruppe „Laden“: Mehr Ware, Glückliches Händchen (R2), Seltene Ware (R3). Davor `feature/geld-schatulle`: kein Geld im Dungeon, alles Gold in der Dose, Händler im Dungeon-Shop kauft Beute (Tab, Rechtsklick), Bosse höchstens 5 Helfer. Im Spiel testen: Laden mit Spielerstufe 5+ → Chancen-Balken ansehen → Hebel mehrmals ziehen, R2-Anteil steigt → nächster Tag wieder 85/15. Skills → Spalte „Laden“ lernen → Balken und Anzahl der Ware ändern sich.

**Nächster Schritt:** Wiese und Tränke im Spiel prüfen (Vorwarnzeiten, Fairness); Balance (`docs/BALANCE.md`); Trank-Skills.

**Entschieden (2026-11-26):** Ein Tag = ein Run · neu würfeln wird teurer · Ausrüstung bleibt beim Tod, Tasche und Dungeon-Gold sind weg · Gold zu Hause nur in der Dose, im Dungeon kein Geld zu finden · Händler = Egon Ehrlich · Dungeon 1 nach Dungeon Smithy, tiefer etwas mehr Leben · vier Dungeons mit Material-Stufen (`docs/BALANCE.md`).

**Offen:** Relikt-Stufen 1–10 und Seltenheitsfarben; Preis-Stufen fürs Würfeln (siehe `docs/IDEEN.md`).

## 9. Bekannte Probleme

Siehe `docs/PROBLEME.md` (aus Dungeon Smithy übernommen).
