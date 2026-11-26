# Überblick

## Doku

- `PROJEKT.md` – Kurzfassung, aktuelle Aufgabe (wird jeder KI-Sitzung mitgegeben, über `CLAUDE.md`)
- `docs/IDEEN.md` – alle Ideen für Teil 2, sortiert; `docs/ROADMAP.md` – Phasen und Schritte
- `docs/SMITHY_LOGIK.md` – welche Smithy-Datei (in `assets/_reference/smithy_logik/`) zu welcher Idee passt
- `docs/SYNERGIEN.md` – alle Synergien und Items, die noch eine bräuchten
- `docs/SYSTEME.md` – jedes System mit Dateien und Funktionsweise
- `docs/CONTENT.md` – Items, Synergien, Gegner, Ebenen als JSON anlegen
- `docs/SPRACHEN.md` – Übersetzungen
- `docs/ENTSCHEIDUNGEN.md`, `docs/PROBLEME.md`, `docs/FEHLERKLASSEN.md`

## Fertige Systeme

Ablauf (Game, RunScene), RunState, ShotStats, FloorLayout, Dungeon, RoomBuilder, Tür, Pickup, Sockel (Item/Shop), Stein, Bombe, Falltür, Spieler, Waffe (Feuerball, Bombe, Strahl, Aufladen, Glutmond), Projektil, Gegner-KI (lurk, chase, fly, hop, shooter, boss), Gegner-Schuss, HUD, Minimap mit Tab-Übersicht, Pause, Ende, Einstellungen, Hauptmenü und Sprachwahl (aus Smithy), Sprachen (9), Audio, Tests.

## Assets aus Smithy

Kopiert aus `../smithy/assets` (`sprites/`, `audio/`, `fonts/`, `ui/`). Genutzt u. a.: `enemies/*` (Gegner), `items/*` (Item-Icons), `rooms/styles/*` (Boden, Wand, Türen), `props/torch_sheet.png`, `rocks/coal_rock.png`, `npcs/goblin_merchant.png` (Händler), `ui/title_*` (Hauptmenü), `ui/flags/*`.
