# Roadmap – Smithy Dungeon 2

Kleine Schritte, jeder auf einem eigenen Branch (`feature/…`), jeder endet mit grünen Tests und einem Spieltest.
Ideen dazu: `docs/IDEEN.md`. Woher die Logik kommt: `docs/SMITHY_LOGIK.md`.

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Projekt angelegt: Kopie von Dungeon Smithy (Stand 2026-11-26, mit Startwaffen-Items), alle Smithy-Assets, Smithy-Logik als Nachschlage-Bibliothek, Ideen sortiert | erledigt (2026-11-26) |
| 1 | Dauerhafter Spielstand und Laden | offen |
| 2 | Intro und Händler-Story | offen |
| 3 | Ausrüstung wirkt im Run, Tränke | offen |
| 4 | Fortschritt: Materialien, Gussformen, neue Ware, mehrere Dungeons | offen |
| 5 | Schmieden (Smithy-Minispiele), Zauberstab-Relikte | später |
| 6 | Koop (LAN) | später |

## Phase 1 – Spielstand und Laden

1. **Spielstand zwischen Runs** (`MetaState`, `user://save.json`): Gold, Inventar, Ausrüstung, Tag, freier Wurf heute ja/nein. Ein Tag = ein Run (offene Frage).
2. **Ausrüstungs-Items als Daten** (`data/gear.json`): Kupfer-Zauberstab, -Bogen, -Schwert, Kupfer-Rüstungsteile, mit Seltenheit R1–R8 und Werten. Seltenheitsfarben aus Smithy (`Rarity`).
3. **Laden-Bildschirm** (2D, 640×360): Tisch mit Ware, Hebel, 3 Verkaufs-/Verlaufsplätze rechts, Inventar unten, Ausrüstung links. Item-Rahmen in Seltenheitsfarbe, Tooltip.
4. **Würfeln:** einmal pro Tag frei, danach kostet es Gold (`data/shop.json`: Preis, Anzahl Items 1–3, Pool nach Freischaltung). Tisch-Dreh-Animation.
5. **Verkaufen:** Item auf einen der 3 Plätze ziehen → Gold (Händler zahlt wenig = „Betrug“).
6. **Animierter Hintergrund:** Glut, Fackelflackern, Staub; Übergänge weich.
7. Hauptmenü „Neues Spiel“ → Laden statt direkt Dungeon; „Los“ im Laden → Run; nach dem Run zurück in den Laden.

## Phase 2 – Intro

1. Augen-auf-Animation, Händler winkt.
2. Dialog-Fenster (Texte in `data/story.json`, übersetzt) mit dem Vorstellungs-Witz.
3. Geführte Laden-Erklärung mit Hervorhebung (wie `Guide` in Smithy).
4. Klassen-Frage → Kupfer-Startwaffe ins Inventar und ausgerüstet.
5. Erster Dungeon ohne Item-Raum und Shop-Raum (`data/floors.json` je Ebene abschaltbar).
6. Nach dem ersten Run: Händler erklärt Tränke und den Trank-Slot.

## Phase 3 – Ausrüstung im Run

1. Ausrüstung gibt Startwerte für `RunState` (Schaden, Herzen, Tempo …). Die Hauptwaffe ist die ausgerüstete Waffe statt `start_items`.
2. Trank-Slot: 1 Platz, Taste Q trinkt, heilt 2 Herzen.
3. Run-Ende: Gold und Materialien wandern in den Spielstand, Run-Items verfallen.
4. **Relikt-Slot** (1 Platz): Relikte als Daten (`data/relics.json`: Wirkung wie Item-`flags`/`stats`, `durability` in Dungeons, `permanent`). Ausgerüstetes Relikt wirkt im Run wie ein Item (zählt für Synergien). Nach jedem Dungeon −1 Haltbarkeit, bei 0 kaputt.
5. Erstes Relikt: Tod im zweiten Run → Händler verkauft Dreifach-Schuss (2 Dungeons) und erklärt den Slot.
6. Relikte auf dem Glücksspiel-Tisch: sehr selten, anfangs nur 3 (Dreifach-Schuss, Suchend, Abprallen); später alle und dauerhafte.

## Phase 4 – Fortschritt

1. Gegner und Bosse lassen Materialien und Gussformen fallen (`data/enemies.json` `loot`).
2. Funde schalten Ware beim Händler frei (Eisen, Bronze …).
3. Mehrere Dungeons mit Gefahrenstufe; Bogenschütze/Krieger über die Story freischalten.
