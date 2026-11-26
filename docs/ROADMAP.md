# Roadmap – Smithy Dungeon 2

Kleine Schritte, jeder auf einem eigenen Branch (`feature/…`), jeder endet mit grünen Tests und einem Spieltest.
Ideen dazu: `docs/IDEEN.md`. Woher die Logik kommt: `docs/SMITHY_LOGIK.md`.

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Projekt angelegt: Kopie von Dungeon Smithy (Stand 2026-11-26, mit Startwaffen-Items), alle Smithy-Assets, Smithy-Logik als Nachschlage-Bibliothek, Ideen sortiert | erledigt (2026-11-26) |
| 1 | Dauerhafter Spielstand und Laden | Beute, Inventar, Spielstand, Dose, Spielstand-Plätze, Ausrüstung, Laden mit Hebel/Kaufen/Anlegen, Dungeon-Brett: erledigt (2026-11-26); Verkaufen, Dose im Laden offen |
| 2 | Intro und Händler-Story | Intro mit Dialog, geführter erster Laden-Besuch: erledigt (2026-11-26); Klassen-Frage offen |
| 3 | Ausrüstung wirkt im Run, Tränke | offen |
| 4 | Fortschritt: Materialien, Gussformen, neue Ware, mehrere Dungeons | offen |
| 5 | Schmieden (Smithy-Minispiele), Zauberstab-Relikte | später |
| 6 | Koop (LAN) | später |

## Phase 1 – Spielstand und Laden

0. ✅ **Beute und Inventar** (2026-11-26): Gegner-Beute (`data/loot.json`), Tab-Inventar mit Drag & Drop, fallen lassen, sicherer Platz, Geldbündel, Karte auf M.
1. ✅ **Spielstand zwischen Runs** (`MetaState`, `user://save.cfg`): Geldbörse, Dose (Limit 200, Diebstahl 20 % / 1 %), mitgebrachte Beute, Tag (= ein Run). Fehlt noch: Ausrüstung, freier Wurf heute ja/nein.
2. ✅ (2026-11-26) **Ausrüstungs-Items als Daten** (`data/gear.json`): Kupfer-Zauberstab, -Bogen, -Schwert, Kupfer-Rüstungsteile, mit Seltenheit R1–R8 und Werten. Seltenheitsfarben aus Smithy (`Rarity`).
3. ✅ (2026-11-26) **Laden-Bildschirm** (2D, 640×360, Skizze `vorlagen/laden_skizze.png`): Tisch mit Ware oben, Hebel rechts, Inventar unten, Ausrüstung links, Item-Rahmen in Seltenheitsfarbe, Tooltip, Kaufen und Anlegen per Klick. Fehlt: 3 Verkaufs-/Verlaufsplätze.
4. ✅ (2026-11-26) **Würfeln:** einmal pro Tag frei, danach kostet es Gold, jedes Mal mehr (`data/shop.json`: Preis, Anzahl Items 1–3, Pool nach Freischaltung). Tisch-Dreh-Animation.
5. **Verkaufen:** Item auf einen der 3 Plätze ziehen → Gold (Händler zahlt wenig = „Betrug“). Mitgebrachte Beute (`MetaState.stash`) verkaufen.
5a. **Dose:** Geld einzahlen/abheben (`MetaState.deposit/withdraw`); Egon kommentiert `last_theft` (Ausreden aus `docs/figuren/EGON_EHRLICH.md`).
6. **Animierter Hintergrund:** Glut, Fackelflackern, Staub; Übergänge weich.
7. ✅ (2026-11-26) Hauptmenü „Neues Spiel“ → Intro → Laden; „Dungeons“ unten rechts → Dungeon-Brett (`data/dungeons.json`) → „Betreten“ → Charakter → Run; nach dem Run „Zum Laden“.
8. ✅ (2026-11-26) **Spielstand-Plätze A, B, C** nach der Sprachwahl; „Weiter“ im Hauptmenü, wenn der Platz belegt ist; gespeichert am Ende jedes Tages.

### Dungeon-Wünsche (2026-11-26, `feature/dungeon-flucht`)

- ✅ Tab = Inventar und daneben die ganze Karte (rausgezoomt).
- ✅ Ausgang im Startraum: flüchten und alles behalten.
- ✅ Tod: Tasche weg (sicherer Platz bleibt, entschieden).
- ✅ Münze aufheben = 8–12 Münzen.
- ✅ HUD: Münz-Anzeige und Werte-Spalte weg, Herzen größer.
- Offen: Preise im Run-Shop an den neuen Münzwert anpassen (Vorschlag ×10).

## Phase 2 – Intro

1. ✅ (2026-11-26) Intro: schwarz → hell, Mine, Egon winkt, in 3 Bildern auf ihn zu, dann der Laden (`scenes/story/intro.gd`).
2. ✅ (2026-11-26) Dialog-Fenster (`DialogBox`, Texte in `data/story.json`, übersetzt) mit dem Vorstellungs-Witz; Intro jetzt draußen vor dem Dungeon-Eingang (Skizze `vorlagen/intro_skizze.png`).
3. ✅ (2026-11-26) Geführte Laden-Erklärung: Egon zieht den Hebel, Geschenke leuchten, er kauft sie, zieht dich an und schickt dich in den Dungeon (Brett lässt sich nicht schließen).
4. Klassen-Frage → Kupfer-Startwaffe der Klasse (bisher schenkt Egon immer den Kupfer-Zauberstab).
5. ✅ (2026-11-26, teils) Ebene 1 ohne Item-Raum (`item_room` in `floors.json`), ab Ebene 2 Item-Raum hinter Schlüssel-Tür. Offen: Shop-Raum je Ebene abschaltbar.
6. Nach dem ersten Run: Händler erklärt Tränke und den Trank-Slot.

## Phase 3 – Ausrüstung im Run

1. ✅ (2026-11-26, teils) Ausrüstung gibt Startwerte für `RunState`: Rüstung = weiße Schild-Herzen, Waffe = Schaden. Offen: Die Hauptwaffe ist die ausgerüstete Waffe statt `start_items`.
2. Trank-Slot: 1 Platz, Taste Q trinkt, heilt 2 Herzen.
3. Run-Ende: Gold und Materialien wandern in den Spielstand, Run-Items verfallen.
4. ✅ (2026-11-26) **Relikt-Slot** (1 Platz; Haltbarkeit je Stufe statt immer 2, schwache für immer; Daten in `data/relics.json`): Relikte als Daten (`data/relics.json`: Wirkung wie Item-`flags`/`stats`, `durability` in Dungeons, `permanent`). Ausgerüstetes Relikt wirkt im Run wie ein Item (zählt für Synergien). Nach jedem Dungeon −1 Haltbarkeit, bei 0 kaputt.
5. Erstes Relikt: Tod im zweiten Run → Händler verkauft Dreifach-Schuss (2 Dungeons) und erklärt den Slot.
6. Relikte auf dem Glücksspiel-Tisch: sehr selten, anfangs nur 3 (Dreifach-Schuss, Suchend, Abprallen); später alle und dauerhafte.
7. **10 Relikt-Stufen** als Pools (`tier` 1–10), jede Stufe mit starken und schwächeren Relikten; Stufe 1 offen, die anderen per Dungeon-Sieg, Abgabe beim Händler oder Quest freischalten.

### Stufen und Skillbaum (2026-11-26, `feature/level-skillbaum`)

- ✅ EXP pro Kill, Stufen bis 30, Skillpunkte.
- ✅ Skillbaum wie Smithy Defense (12 Skills), Relikt-Plätze unter der Ausrüstung.
- Offen: Tränke (Trank-Platz, Q trinkt) und die Skills „Mehr Tränke“, „Stärkere Tränke“.

## Phase 4 – Fortschritt

1. Gegner und Bosse lassen Materialien und Gussformen fallen (`data/enemies.json` `loot`).
2. Funde schalten Ware beim Händler frei (Eisen, Bronze …).
3. Mehrere Dungeons mit Gefahrenstufe; Bogenschütze/Krieger über die Story freischalten.
