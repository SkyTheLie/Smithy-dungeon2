# Roadmap – Smithy Dungeon 2

Kleine Schritte, jeder auf einem eigenen Branch (`feature/…`), jeder endet mit grünen Tests und einem Spieltest.
Ideen dazu: `docs/IDEEN.md`. Woher die Logik kommt: `docs/SMITHY_LOGIK.md`.

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Projekt angelegt: Kopie von Dungeon Smithy (Stand 2026-11-26, mit Startwaffen-Items), alle Smithy-Assets, Smithy-Logik als Nachschlage-Bibliothek, Ideen sortiert | erledigt (2026-11-26) |
| 1 | Dauerhafter Spielstand und Laden | Beute, Inventar, Spielstand, Dose, Spielstand-Plätze, Ausrüstung, Laden mit Hebel/Kaufen/Anlegen, Dungeon-Brett: erledigt (2026-11-26); Verkaufen, Dose im Laden offen |
| 2 | Intro und Händler-Story | Intro mit Dialog, geführter erster Laden-Besuch: erledigt (2026-11-26); Klassen-Frage offen |
| 3 | Ausrüstung wirkt im Run, Tränke | Schild-Herzen, Waffen-Schaden, Relikte: erledigt (2026-11-26); Trank-Platz, Q trinkt, Egons Trank-Vorführung nach dem 2. Tod: erledigt (2026-11-27); Trank-Skills offen |
| 4 | Fortschritt: Materialien, Gussformen, neue Ware, mehrere Dungeons | offen |
| 5 | Schmieden (Smithy-Minispiele), Zauberstab-Relikte | später |
| 6 | Koop (LAN) | später |

## Phase 1 – Spielstand und Laden

0. ✅ **Beute und Inventar** (2026-11-26): Gegner-Beute (`data/loot.json`), Tab-Inventar mit Drag & Drop, fallen lassen, sicherer Platz, Geldbündel, Karte auf M.
1. ✅ **Spielstand zwischen Runs** (`MetaState`, `user://save.cfg`): Geldbörse, Dose (Limit 200, Diebstahl 20 % / 1 %), mitgebrachte Beute, Tag (= ein Run). Fehlt noch: Ausrüstung, freier Wurf heute ja/nein.
2. ✅ (2026-11-26) **Ausrüstungs-Items als Daten** (`data/gear.json`): Kupfer-Zauberstab, -Bogen, -Schwert, Kupfer-Rüstungsteile, mit Seltenheit R1–R8 und Werten. Seltenheitsfarben aus Smithy (`Rarity`).
3. ✅ (2026-11-26) **Laden-Bildschirm** (2D, 640×360, Skizze `vorlagen/laden_skizze.png`): Tisch mit Ware oben, Hebel rechts, Inventar unten, Ausrüstung links, Item-Rahmen in Seltenheitsfarbe, Tooltip, Kaufen und Anlegen per Klick. Fehlt: 3 Verkaufs-/Verlaufsplätze.
4. ✅ (2026-11-26) **Würfeln:** einmal pro Tag frei, danach kostet es Gold, jedes Mal mehr (`data/shop.json`: Preis, Anzahl Items 1–3, Pool nach Freischaltung). Tisch-Dreh-Animation.
5. ✅ (2026-11-26, ein Ankauf-Platz statt 3, Rechtsklick) **Verkaufen:** Item auf einen der 3 Plätze ziehen → Gold (Händler zahlt wenig = „Betrug“). Mitgebrachte Beute (`MetaState.stash`) verkaufen.
5a. ✅ (2026-11-26) **Dose:** Geld einzahlen/abheben (`MetaState.deposit/withdraw`); Egon kommentiert `last_theft` (Ausreden aus `docs/figuren/EGON_EHRLICH.md`).
6. **Animierter Hintergrund:** Glut, Fackelflackern, Staub; Übergänge weich.
7. ✅ (2026-11-26) Hauptmenü „Neues Spiel“ → Intro → Laden; „Dungeons“ unten rechts → Dungeon-Brett (`data/dungeons.json`) → „Betreten“ → Charakter → Run; nach dem Run „Zum Laden“.
8. ✅ (2026-11-26) **Spielstand-Plätze A, B, C** nach der Sprachwahl; „Weiter“ im Hauptmenü, wenn der Platz belegt ist; gespeichert am Ende jedes Tages.

### Dungeon-Wünsche (2026-11-26, `feature/dungeon-flucht`)

- ✅ Tab = Inventar und daneben die ganze Karte (rausgezoomt).
- ✅ Ausgang im Startraum: flüchten und alles behalten.
- ✅ Tod: Tasche weg (sicherer Platz bleibt, entschieden).
- ✅ ~~Münze aufheben = 8–12 Münzen.~~ Ersetzt (2026-11-26, `feature/geld-schatulle`): keine Münzen im Dungeon, Gold nur fürs Verkaufen beim Händler im Dungeon-Shop, alles Gold zu Hause in der Dose.
- ✅ HUD: Münz-Anzeige und Werte-Spalte weg, Herzen größer.
- ✅ Bosse rufen höchstens 5 Helfer gleichzeitig (`enemies.json` `summon_max`).
- Offen: Preise im Run-Shop im Spiel prüfen (Gold kommt nur aus Beute).

### Raster-Inventar und Tutorial (2026-11-27, `feature/raster-inventar`)

- ✅ Inventar-Fenster kleiner und übersichtlicher.
- ✅ Inventar als Raster 8×3, Beute mit Größen (Fell 2×2, Zauberstab 4×1, Rubin 3×3), drehen mit R / Rechtsklick, sicherer Platz 2×2.
- ✅ Rucksäcke (2×2 bis 5×3) im Skillbaum (Gold), bei Egon ans Inventar anbauen.
- ✅ Tutorial im ersten Run: laufen, umsehen, schießen, Übungsratte, Beute aufheben, Tab, sicherer Platz.
- ✅ (2026-11-27, `feature/laden-raster`) Laden nach neuer Skizze: Tisch und Lager (5×4) als Raster, Reiter Ausrüstung/Inventar, Rucksäcke aus dem Lager anbauen, Rucksäcke auf Egons Tisch, Knöpfe unten.
- ✅ (2026-11-27) Kaufen, Verkaufen, Anlegen per Drag & Drop; Quest-Platz und Quest-Fenster; Egons Quest-Kette schaltet die Dungeons frei, Egon zieht um; Skillbaum wächst zur Seite.
- ✅ (2026-11-27, `feature/inventar-bleibt`) Beute bleibt im Inventar zwischen den Runs; Inventar im Laden größer, Beute zwischen Inventar, Lager und Tisch ziehen.
- Offen: Rucksack-Preise im Spiel prüfen; Lager vergrößern (Skill?); Quest-Belohnungen (Gold) im Spiel prüfen.

## Phase 2 – Intro

1. ✅ (2026-11-26) Intro: schwarz → hell, Mine, Egon winkt, in 3 Bildern auf ihn zu, dann der Laden (`scenes/story/intro.gd`).
2. ✅ (2026-11-26) Dialog-Fenster (`DialogBox`, Texte in `data/story.json`, übersetzt) mit dem Vorstellungs-Witz; Intro jetzt draußen vor dem Dungeon-Eingang (Skizze `vorlagen/intro_skizze.png`).
3. ✅ (2026-11-26) Geführte Laden-Erklärung: Egon zieht den Hebel, Geschenke leuchten, er kauft sie, zieht dich an und schickt dich in den Dungeon (Brett lässt sich nicht schließen).
4. Klassen-Frage → Kupfer-Startwaffe der Klasse (bisher schenkt Egon immer den Kupfer-Zauberstab).
5. ✅ (2026-11-26, teils) Ebene 1 ohne Item-Raum (`item_room` in `floors.json`), ab Ebene 2 Item-Raum hinter Schlüssel-Tür. Offen: Shop-Raum je Ebene abschaltbar.
6. ✅ (2026-11-27, `feature/wiese-traenke`) Nach dem **zweiten Tod**: Egon zeigt Tränke, dreht einmal den Tisch, schenkt einen Heiltrank und legt ihn in den Trank-Platz.

## Phase 3 – Ausrüstung im Run

1. ✅ (2026-11-26, teils) Ausrüstung gibt Startwerte für `RunState`: Rüstung = weiße Schild-Herzen, Waffe = Schaden. Offen: Die Hauptwaffe ist die ausgerüstete Waffe statt `start_items`.
2. ✅ (2026-11-27) Trank-Slot: 1 Platz an der Helden-Figur (unten links), Taste Q trinkt, heilt 2 Herzen (`data/potions.json`).
3. Run-Ende: Gold und Materialien wandern in den Spielstand, Run-Items verfallen.
4. ✅ (2026-11-26) **Relikt-Slot** (1 Platz; Haltbarkeit je Stufe statt immer 2, schwache für immer; Daten in `data/relics.json`): Relikte als Daten (`data/relics.json`: Wirkung wie Item-`flags`/`stats`, `durability` in Dungeons, `permanent`). Ausgerüstetes Relikt wirkt im Run wie ein Item (zählt für Synergien). Nach jedem Dungeon −1 Haltbarkeit, bei 0 kaputt.
5. Erstes Relikt: Tod im zweiten Run → Händler verkauft Dreifach-Schuss (2 Dungeons) und erklärt den Slot.
6. Relikte auf dem Glücksspiel-Tisch: sehr selten, anfangs nur 3 (Dreifach-Schuss, Suchend, Abprallen); später alle und dauerhafte.
7. **10 Relikt-Stufen** als Pools (`tier` 1–10), jede Stufe mit starken und schwächeren Relikten; Stufe 1 offen, die anderen per Dungeon-Sieg, Abgabe beim Händler oder Quest freischalten.

### Stufen und Skillbaum (2026-11-26, `feature/level-skillbaum`)

- ✅ EXP pro Kill, Stufen bis 30, Skillpunkte.
- ✅ Skillbaum wie Smithy Defense (12 Skills), Relikt-Plätze unter der Ausrüstung.
- ✅ Tränke (Trank-Platz, Q trinkt). Offen: die Skills „Mehr Tränke“, „Stärkere Tränke“.

## Phase 4 – Fortschritt

1. Gegner und Bosse lassen Materialien und Gussformen fallen (`data/enemies.json` `loot`).
2. Funde schalten Ware beim Händler frei (Eisen, Bronze …).
3. Mehrere Dungeons mit Gefahrenstufe; Bogenschütze/Krieger über die Story freischalten.

### Balance und neue Dungeons (2026-11-27, `feature/balance`)

- ✅ Vier Dungeons (Glut, Moor der Irrlichter, Frostgipfel, Glutschlund), je 6 Ebenen in 3 Gebieten, der nächste öffnet nach dem Sieg.
- ✅ 65 neue Gegner und Bosse, 23 neue Beute-Sorten, Fallen (Gift, Stacheln, Eisstacheln, Lava).
- ✅ Materialien bei Egon: Kupfer, Bronze (ab Stufe 3), Eisen (nach Dungeon 1), Silber, Gold; Hebel teurer mit besserem Material.
- ✅ Balance-Rechner und `docs/BALANCE.md`; Stufen, Skill-Preise, Seltenheits-Stufen angepasst; Skill „Größere Dose“.
- Offen: im Spiel ausprobieren und nachjustieren (Liste in `docs/BALANCE.md`).

### Wispernde Wiese und Gegner-Muster (2026-11-27, `feature/wiese-traenke`)

- ✅ Fünfter Dungeon „Wispernde Wiese“ (nach dem Moor) mit hohem Gras, versteckten Fallen und Fangeisen.
- ✅ 15 neue Gegner mit eigenen Mustern (Ansturm auf Linie, Laser, Wandkletterer, Panzer, Abpraller, Fliehender Brüter, Umfallen und Aufstehen, Teilen, Explodieren), 2 neue Bosse (Wildhüter mit Bogen und Fallen, Kristallkoloss mit Lasern).
- Offen: im Spiel prüfen, ob jedes Muster fair und lesbar ist (Vorwarnzeiten in `enemies.json`/`boss_brain.gd`); alte Gebiete mit den neuen Mustern mischen (`docs/IDEEN.md`).

### Fallen-Grafik, eigene Fallen, Vulkandrache (2026-11-27)

- ✅ Tauben (`city_7_walk`) auf sichtbaren Fallen, fliegen beim Hineintreten auf.
- ✅ Logik für eigene Fallen (treffen nur Gegner; Item-Feld `traps`).
- ✅ Vulkandrache als großer End-Boss des Glutschlunds mit eigener Arena.
- Offen: Items/Relikte, die Fallen legen.

### Boss-Halle und Admin-Menü (2026-11-27)

- ✅ Boss-Raum = Vorhalle mit Tor; dahinter die große Halle (2 × 2 Räume) mit Altar der Neun und 9 Kristallsäulen; Szene: Kristalle fliegen ein, fallen in den Altar, Energie läuft zu den Säulen, Stille, Boss fällt herein, Rock-Musik.
- ✅ Admin-Menü auf P (nur im Editor): Reisen, Items, Ausrüstung/Relikte/Tränke, Cheats.
- Offen: Szene im Spiel ansehen und Zeiten nachjustieren; echten Rock-Track statt erzeugtem Loop suchen (lizenzfrei).

### Räderkluft (2026-11-28, `feature/raederkluft`)

- ✅ Neue Boss-Halle über einem Abgrund (`scenes/run/gear_chasm.gd`, `data/gear_chasm.json`): feste Mitte mit Boss-Podest, vier Tür-Plattformen, innerer Ring (4, gegen den Uhrzeigersinn) und äußerer Ring (4, im Uhrzeigersinn) auf Schienen; Absturz = ½ Herz, zurück auf festen Boden.
- ✅ Endboss-Halle des Moors (`dungeons.json` `end_room`): Portal nach der letzten Ebene → Räderkluft, die Sumpfhydra steht fest auf dem Podest, ihre Schleime bleiben auf den Plattformen; danach goldenes Licht auf der Mitte.
- Offen: eigener Boss mit Mustern für die Halle; Bomben über dem Abgrund.

### Flug-Items (2026-11-28, `feature/flug-items`)

- ✅ 10 Items mit `fly` (über Fallen und Abgründe, Sicht höher) bzw. `ghost` (Geistgestalt: auch durch Steine).
- Offen: Synergie Dunkle + Weiße Flügel; Gegner, die Flieger besonders treffen.

### Spielgefühl, Behälter, Tausch (Nachricht vom 2026-11-28, Liste in `docs/IDEEN.md`)

- ✅ Weniger Beute: höchstens 1 Ding je Raum (`loot.json` `room_budget`), Münzen seltener.
- ✅ Egon schenkt für den Rubin ein Moorherz-Relikt (4 Runs).
- ✅ Behälter im Lager (Relikte, Rüstung, Waffen, Materialien; klein und groß) und Tausch-Reiter bei Egon (`data/trades.json`).
- ✅ Bomben (bis 5 je Feld) und Schlüssel (je ein Feld) als Beute im Inventar; zerbrechliche Schlüssel aus dem Dungeon, Eisenschlüssel bleiben (Tausch bei Egon).
- Offen: Treffer-Gefühl, Tod-Zusammenfassung, Heimkehr, Komfort, Tagesangebot (Reihenfolge in `docs/IDEEN.md`).

### Aussehen und Stimmung (Nachricht vom 2026-11-28, Liste in `docs/IDEEN.md`)

- ✅ Treffer-Blitz (Gegner kurz weiß), Fackeln flackern, Lichthof um Feuerbälle und Fackeln statt Glow (`feature/stimmung`).
- ✅ Deko in den Räumen: 2–5 Bilder je Raum an den Wänden, je Thema eigene (`floors.json` `props`, `feature/deko`).
- ✅ In der Luft je Thema: Staub, Grabstaub, Sporen, Schnee, Schneesturm, Glut, Asche-Glut, Glühwürmchen (`floors.json` `air`/`air_types`, `feature/luft`).
- ✅ Anführer (Mini-Boss) in der Mitte jeder Ebene ab Ebene 2: groß, golden, eigener Balken, eigene Belohnung (`floors.json` `mini_boss`, `feature/mini-boss`).
- ✅ Leise Geräusche je Thema im Raum (Tropfen, Ketten, Wind, Frösche, Grillen …; `floors.json` `ambience`, `feature/raum-ton`).
- ✅ Wand-Schriften früherer Abenteurer (`story.json` `walls`, `floors.json` `writings`, `feature/wand-schriften`).
- ✅ Zerbrechliche Deko: Kisten, Fässer, Säcke, Kristalle gehen durch Schuss, Schwert und Bombe kaputt, manchmal Münzen (`floors.json` `props.break`, `feature/kaputte-deko`).
- Offen: Boden-Decals, Vignette/Farbstimmung, Head-Bob; im Laden Seltenheitsrahmen, lebender Hintergrund, R3-Moment, Abblenden.

### Gegner, Bosse, Fallen, Kisten (Nachrichten vom 2026-11-28, Listen in `docs/IDEEN.md`)

Reihenfolge (klein zuerst): Schuss-Farben → Untote stehen auf → Geister unsichtbar → Kisten und Stein-Kammer → Pfeil-Wände → Stachelsteine → Monster-Falle → Boss-Phasen → Wand-Geist → Wurm-Boss → Vogel-Boss → Egons Umzug mit Gimmicks → UI-Komfort im Laden und Tab.

- ✅ Schuss-Farben nach Schaden (`enemies.json` `shot_colors`, `feature/schuss-farben`).
- ✅ Stachelsteine auf festen Bahnen (`floors.json` `spike_stones`, `feature/stachelsteine`).
- ✅ Pfeil-Wände (Takt, Reihe, Druckplatte; Vorwarnung + Klick; treffen auch Gegner; `floors.json` `arrow_traps`, `feature/pfeil-waende`).
- ✅ Kisten (Holz, Schloss, Tresor) und Stein-Kammer (`data/chests.json`, `feature/kisten`).
- ✅ Geister werden unsichtbar (flüstern, greifen unsichtbar nicht an, Treffer zeigt sie; `invisible`, `feature/geister-unsichtbar`).
- ✅ Untote stehen wieder auf (jedes Mal mit 50 %, bis die Leiche zerstört ist; `revive` `times` 0, `feature/untote`).
