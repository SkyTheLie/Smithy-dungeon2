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
- **Daten:** alles Spielbare als JSON in `data/` (Items, Synergien, Gegner, Ebenen, Charaktere, Startwerte, Töne, Beute `loot.json`, Spielstand-Regeln `meta.json`, Dungeons `dungeons.json`, Ausrüstung `gear.json`, Laden `shop.json`, Texte der Figuren `story.json`) – nie im Code. Anleitung: `docs/CONTENT.md`
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

**Später:** Schmieden mit Smithy-Minispielen, Zauberstab-Relikte, mehrere Dungeons mit Materialstufen, Koop.

## 7. Fortschritt

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Projekt angelegt, Assets und Logik aller Smithy-Spiele, Ideen sortiert | erledigt (2026-11-26) |
| 1 | Spielstand und Laden | Beute, Inventar, Spielstand (Plätze A/B/C), Dose, Ausrüstung, Laden mit Hebel/Kaufen/Anlegen, Dungeon-Brett: erledigt (2026-11-26); Verkaufen und Dose im Laden offen |
| 2 | Intro und Händler-Story | Intro mit Dialog vor dem Dungeon-Eingang, geführter erster Laden-Besuch: erledigt (2026-11-26); Klassen-Frage offen |
| 3 | Ausrüstung im Run, Tränke | Rüstung = Schild-Herzen, Waffe = Schaden: erledigt (2026-11-26); Tränke, Relikte offen |

## 8. Aktuelle Aufgabe

**Zuletzt gebaut (2026-11-26):** `feature/geld-schatulle`: Im Dungeon gibt es kein Geld mehr, nur Beute und Items. Alles Gold zu Hause liegt in der Dose (über 200 kann Egon klauen). Der Händler im Dungeon-Shop kauft Beute an (Tab, Rechtsklick), übriges Gold kommt nach dem Run in die Dose. Münz-Items geben Beute, Goldnase = mehr Gold beim Händler. Bosse rufen höchstens 5 Helfer gleichzeitig. Im Spiel testen: Neues Spiel → Tour (50 Gold landen in der Dose, kein Münzsack) → Dungeon: keine Münzen in Steinen/Räumen → Beute sammeln → Shop-Raum: Hinweis, Tab, Rechtsklick auf Beute → Gold in der Tasche → Item kaufen → flüchten → Rest in der Dose. Boss mit Helfern (Rattenkönig, Ork-Häuptling): nie mehr als 5 auf einmal.

**Nächster Schritt:** Laden-Skills (mehr Ware, bessere Chancen auf R2/R3, Chancen steigen mit jedem Neu-Würfeln, `docs/IDEEN.md`); Run-Shop-Preise im Spiel prüfen; Tränke (Phase 3).

**Entschieden (2026-11-26):** Ein Tag = ein Run · neu würfeln wird teurer · Ausrüstung bleibt beim Tod, Tasche und Dungeon-Gold sind weg · Gold zu Hause nur in der Dose, im Dungeon kein Geld zu finden · Händler = Egon Ehrlich · Dungeon 1 : 1 wie Dungeon Smithy.

**Offen:** Relikt-Stufen 1–10 und Seltenheitsfarben; Preis-Stufen fürs Würfeln (siehe `docs/IDEEN.md`).

## 9. Bekannte Probleme

Siehe `docs/PROBLEME.md` (aus Dungeon Smithy übernommen).
