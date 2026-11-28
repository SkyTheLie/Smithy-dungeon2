# Ideen – Smithy Dungeon 2 (sortiert)

Stand 2026-11-26. Ursprung: Ideen-Liste des Entwicklers, hier nur sortiert und ergänzt um offene Fragen.
Was gebaut wird, steht in `docs/ROADMAP.md`. Woher die Logik kommt: `docs/SMITHY_LOGIK.md`.

## 1. Die Kern-Schleife

```
   Dorf / Händler  ──►  Dungeon-Run (wie bisher)  ──►  zurück zum Händler
   kaufen, verkaufen,    Feuerball, Items, Synergien,    Gold, Materialien,
   ausrüsten, Tränke      Räume, Boss                     Gussformen mitgebracht
         ▲                                                       │
         └──────────── neue Ware freigeschaltet ◄────────────────┘
```

- Ein **Dungeon-Run** bleibt wie in Dungeon Smithy (Roguelike, Items im Run gehen am Ende verloren).
- **Neu:** Zwischen den Runs gibt es einen festen Ort (den Laden des Händlers). Was man dort kauft, **bleibt** (Ausrüstung, Tränke, Gold, Materialien) = RPG-/Roguelite-Teil.
- Ausrüstung wirkt im Run als Startwerte (mehr Schaden, mehr Herzen …), die Run-Items kommen obendrauf.

## 2. Der Händler (Story-Figur)

- Witziger Gauner, der ehrlich tut. Er „verspricht“ sich beim Vorstellen:
  > „Hey, ich bin der Gau… äh, der **Mann-Verkäufer**. Ich verkaufe Mann… *(Pause)* …**Ausrüstung**. Ja, genau. Ich verkaufe Ausrüstung.“
- Beziehung „du hilfst mir, ich helfe dir“: Der Spieler riskiert sein Leben in gefährlichen Dungeons und bringt ihm gute Sachen; der Händler verkauft ihm dafür bessere Ausrüstung.
- **Er betrügt dich** (zieht dich beim Verkauf über den Tisch) – aber genau so kommt man an neues Gear oder andere Relikte.
- **Name: Egon Ehrlich** (entschieden 2026-11-26). Charakter, Sprechweise, Running Gags und Dialog-Regeln: `docs/figuren/EGON_EHRLICH.md` – jeder Dialog wird aus dieser Datei gebaut.

## 3. Der Shop (Glücksspiel-Laden)

### Aufbau des Bildschirms

```
┌───────────────────────────────────────────────────────────┐
│ Ausrüstung │         TISCH (Ware)           │ Verkauf/     │
│ (Held wie  │   [ ] [ ] [ ] [ ] [ ]           │ Verlauf      │
│  in Smithy)│   Hebel: Tisch dreht sich →     │ [ ] [ ] [ ]  │
│ Kopf, Brust│   neue Ware                     │ (3 Plätze)   │
│ Waffe …    │                                 │              │
│ Trank-Slot │                                 │              │
├────────────┴─────────────────────────────────┴──────────────┤
│ INVENTAR (unten)  [ ][ ][ ][ ][ ][ ][ ][ ][ ][ ]            │
└───────────────────────────────────────────────────────────┘
```

- **Tisch** in der Mitte = die Ware. Der Händler zieht an einem **Hebel**, der Tisch **dreht sich um**, und neue Items liegen darauf (= neu würfeln).
- **Rechts 3 Plätze:** dort verkauft man Sachen; gleichzeitig der **Verlauf** (was zuletzt verkauft wurde, kann man evtl. zurückkaufen – offen).
- **Links:** Ausrüstung des Charakters (wie die Heldenansicht in Smithy, Vorlage `assets/_reference/vorlagen/helden_ansicht.png`).
- **Unten:** Inventar.

### Regeln (Nachricht vom 2026-11-26)

- Dungeon → **Materialien, Items, Gold** → beim Händler **verkaufen** → Händler verkauft dafür **Glücksspiel-Ware**.
- **Einmal pro Tag** darf man kostenlos würfeln (Tisch drehen). **Nochmal würfeln kostet Gold**, und zwar **jedes Mal mehr** (entschieden; am nächsten Tag wieder billig).
- Am Anfang gibt es nur **Kupfer-Sachen**, Seltenheit **R1**, meist 1–3 Stück auf dem Tisch.
- „Shop ist voll Gamba“: gute Ausrüstung bekommt man nur durch Glück beim Würfeln, sonst liegt viel Schrott auf dem Tisch.
- Materialien und **Gussformen** aus Dungeons **schalten beim Händler neue Items frei** (Eisen-Ware erst nach Eisen-Funden usw.).
- **Ein Tag = ein Dungeon-Run** (entschieden; nach jedem Run beginnt ein neuer Tag).

### Aussehen

- Jedes Item hat einen **Rahmen in seiner Seltenheits-Farbe** (R1 grau/weiß, R2 grün, R3 blau, R4 lila, R5 gold … wie in Smithy `Rarity`).
- Übersichtlich, „schön verpackt“: klare Bereiche, große Icons, Preis direkt am Item, Tooltip mit Werten.
- **UI leicht animiert:** Hintergrund bewegt sich (Fackel-Flackern, Staub, Glut), die Animationen gehen weich in den Hintergrund über (verschmelzen), Tisch-Dreh-Animation, Items „ploppen“ beim Würfeln auf, seltene Items leuchten.

## 4. Ausrüstung, Waffe, Relikte

- Der Charakter kann Ausrüstung **tragen, kaufen, (später) schmieden**. Ausrüstungsplätze wie bei Smithy-Helden.
- Magier → Feuerball. Den **Zauberstab** kann man **aufwerten** (→ mehr Schaden).
- Dem Zauberstab kann man **etwas hinzufügen** (Relikt/Kristall), das **das Geschoss verändert** (wie Run-Items, aber dauerhaft – z. B. „suchend“, „zerplatzt“).
- **Startwaffe** je Klasse (vom Händler geschenkt): **Kupfer-Zauberstab**, **Kupfer-Bogen**, **Kupfer-Schwert**.
### Relikte (Nachricht vom 2026-11-26)

- **Relikt-Slot** in der Ausrüstung, am Anfang **nur 1 Slot** (mehr Slots später).
- Ein Relikt **verändert das Geschoss** (wie die Run-Items: Dreifach-Schuss, suchend, zerplatzend …).
- **Haltbarkeit:** ein normales Relikt hält **2 Dungeons**, dann ist es **kaputt** (verschwindet). Manche Relikte trägt man **dauerhaft** (später, sehr wertvoll).
- **Erstes Relikt:** Stirbt man im **nächsten Run** (dem Run nach dem Intro-Dungeon), verkauft der Händler einem danach ein Relikt: **Dreifach-Schuss** (3 Feuerbälle im Fächer, wie „Dreizack-Rune“ im Run). Der Händler erklärt dabei den Relikt-Slot.
- **Relikte kaufen:** liegen auch auf dem Glücksspiel-Tisch, aber **sehr selten**. Am Anfang gibt es nur **3 Relikte**, alle verändern das Geschoss (Vorschlag: Dreifach-Schuss, Suchender Funke, Abprallen).
- **Später** können alle Relikte auftauchen (viele Run-Items als Relikt-Version), dazu die dauerhaften.
- **10 Relikt-Stufen** (Nachricht vom 2026-11-26), von schwach (Stufe 1) bis stark (Stufe 10). Jede Stufe enthält **auch schwächere, nicht so tolle Relikte**, gemischt, aber ihrer Seltenheit ebenbürtig (kein Stufe-1-Müll in Stufe 9, aber auch nicht nur Volltreffer).
  - Jede Stufe ist ein eigener **Pool**. Am Anfang ist nur Stufe 1 offen (davon tauchen nur ein paar im Shop auf, siehe oben: 3 Stück).
  - Weitere Stufen werden **freigeschaltet** durch: Dungeons beenden, bestimmte Sachen zum Händler bringen, Quests.
  - Vorschlag für die Daten: `data/relics.json` mit `tier` 1–10 je Relikt und `data/relic_tiers.json` mit `unlock` je Stufe (wie `unlock` bei Items: `{"type": "wins", "count": 1}`, `{"type": "deliver", "id": "ruby", "count": 3}`, `{"type": "quest", "id": "…"}`).
  - Offen: Wie hängen die 10 Relikt-Stufen mit den 8 Item-Seltenheiten (R1–R8, Rahmenfarbe) zusammen? Vorschlag: eigene Rahmenfarbe je Stufe.
- Offen: Kann man ein kaputtes Relikt reparieren / schmieden? Zählt ein Relikt für Synergien mit Run-Items? *(Vorschlag: ja, das macht Spaß.)*

- Schmieden: dieselben Minispiele wie in Smithy (Amboss-Takt, Schleifstein, Werkbank)? → offen, eher später.
- **Tränke:** erstmal **ein Trank-Slot**, Trank heilt **2 Herzen**. Im Run per Taste trinken.

## 5. Klassen

- Am Anfang **nur Magier**, später **Bogenschütze** und **Schwertkämpfer** (Krieger). *(In Dungeon Smithy schon eingebaut: Bogenschütze nach 1 Sieg, Krieger ab Ebene 3.)*
- Jede Klasse hat ihre **Hauptwaffe als Start-Item** – Run-Waffen-Items ersetzen sie nicht mehr, sondern kreuzen sich über Synergien (erledigt in Dungeon Smithy, siehe `docs/SYNERGIEN.md`).
- Im Intro fragt der Händler die Klasse ab. Am Anfang kann man nur „Magier“ sagen; die anderen Antworten sind gesperrt / witzig abgelehnt (offen).

## 6. Story-Start (Intro)

1. Neues Spiel → Bildschirm schwarz, **Augen gehen auf** (Lider-Animation).
2. Ein Typ winkt dich zu sich: der Händler. Vorstellung (Witz oben).
3. „Schau mal hier“ → **Shop geht auf** → Shop wird Schritt für Schritt erklärt (Tisch, Hebel, Verkauf/Verlauf, Inventar unten, Ausrüstung links), mit Hervorhebung wie die Tipps in Smithy (`Guide`).
4. Der Händler „kauft“ dir eine Waffe und fragt dabei: **„[Klasse]?“** → „Ohh ja, du bist ein [Klasse]!“ → Kupfer-Zauberstab / -Bogen / -Schwert.
5. Ab in den **ersten Dungeon** – wie die erste Ebene bisher, aber **ohne Item-Raum und ohne Shop-Raum** (kommen später dazu).
6. **Ob man stirbt oder es schafft:** zurück beim Händler. Er zeigt **Tränke** und den **Trank-Slot** (1 Slot, +2 Herzen).
7. Danach frei: Ausrüstung verkaufen, neue kaufen, nächster Dungeon.
8. **Stirbt man im nächsten Run:** Der Händler verkauft einem das erste **Relikt** (Dreifach-Schuss) und erklärt den Relikt-Slot (siehe 4).

## 7. Dungeons

- Wie ein Isaac-artiger Run (Räume, Gegner, Items, Boss) – **mit unseren eigenen** Items, Räumen und Gegnern aus Dungeon Smithy (kein Nachbau eines bestimmten Spiels).
- Dungeons farmen: mehrere Dungeons mit Gefahrenstufe; gefährlicher = bessere Materialien (Kupfer → Eisen → Bronze … wie in Smithy).
- Beute, die den Run überlebt: Gold, Materialien, Gussformen, ggf. Ausrüstung. Run-Items verfallen.

## 7a. Beute, Inventar und die Dose (Nachricht vom 2026-11-26, **gebaut** auf `feature/beute-inventar`)

- Gegner lassen **Sachen fallen** (Fledermaus → Flughaut, Ratten → Rattenfell, Goblins → Kupfererz, Bosse immer etwas …), Tabelle in `data/loot.json`.
- Aufheben = drüberlaufen. **Tab** öffnet das **Inventar** (12 Plätze), dort per **Drag & Drop** sortieren oder **aus dem Fenster ziehen = auf den Boden werfen** (Platz machen). Die Karte liegt jetzt auf **M**.
- **Stirbt man, ist alles weg** – außer dem **sicheren Platz** (1 Platz mit goldenem Rahmen).
- **Geld** wird gedroppt und als **Geldbündel** im Inventar angezeigt; auch das ist beim Tod weg.
- Außerhalb des Dungeons hat der Spieler eine **kleine Dose** (hat er selbst mitgebracht). Bis **200 Gold** ist das Geld darin sicher. Liegt mehr darin, greift Egon an jedem neuen Tag zu: **20 %** Chance, dass ein Teil des Geldes **über** dem Limit fehlt, **1 %** Chance, dass **alles** weg ist (`data/meta.json`).
- Gold, das man bei sich trägt (nicht in der Dose), geht mit in den nächsten Dungeon und ist beim Tod weg.
- Ausrüstung bleibt beim Tod (entschieden).
- Noch nicht gebaut: der Bildschirm, an dem man Geld in die Dose legt (kommt mit dem Laden).

## 8. Später / vielleicht

- **Koop** (LAN wie in `smithy_lan`) – großer Umbau, erst wenn das Einzelspiel steht.
- Schmieden mit den Smithy-Minispielen.
- Item-Raum und Shop-Raum im Dungeon wieder freischalten.

## Offene Fragen

Beantwortet am 2026-11-26: Dungeon bleibt 1 : 1 wie Dungeon Smithy (3D), ein Tag = ein Run, neu würfeln wird teurer, Ausrüstung bleibt beim Tod (Inventar und Geld bei sich sind weg), Händler = Egon Ehrlich.

1. Relikt-Stufen 1–10 und Item-Seltenheit R1–R8: eigene Farben je Relikt-Stufe?
2. Kann man ein kaputtes Relikt reparieren?
3. Zählt ein Relikt für Synergien mit Run-Items? *(Vorschlag: ja.)*
4. Wie viel steigt der Preis fürs erneute Würfeln? *(Vorschlag: 10, 20, 40, 80 … Gold, am nächsten Tag wieder 10.)*

## Laden-Skills (Nachricht vom 2026-11-26) – ✅ gebaut (`feature/laden-skills`)

- Skills, die man bei Egon kaufen kann und die den Laden verbessern, z. B. **mehr Ware auf dem Tisch**, **bessere Chance auf R2**, **Chance auf R3**.
- **Mit jedem Neu-Würfeln am selben Tag** steigt die Chance auf seltenere Stufen, die Chance auf R1 sinkt (zusätzlich zum steigenden Preis).

## Gras-Dungeon, Gegner-Muster, Tränke (Nachricht vom 2026-11-27) – ✅ größtenteils gebaut (`feature/wiese-traenke`)

- ✅ **Dungeon mit Rasen:** pro Feld 2D-Gras, ein paar Dutzend Zentimeter hoch; kleine Gegner sind schwerer zu sehen, unter dem Gras liegen Fallen, die man kaum sieht → „Wispernde Wiese“.
- ✅ **Bogenschützen-Boss:** steht auf Abstand, weicht Schüssen aus, spannt den Bogen (Vorwarnung), wirft ab und zu 3 Fallen um den Spieler; wer hineintritt, wird festgehalten, und der nächste Schuss trifft → „Der Wildhüter“.
- ✅ Feste Gegner (Riedwächter), Spinnen, die nur an der Wand klettern und schießen (Wandspinne), Laser-Strahl (Funkelstein, Kristallkoloss), Dreifach-Schuss (Wilderer, Wandspinne).
- ✅ Jeder Gegner eigen, Muster zum Lernen, jede Gefahr mit Vorwarnung, Rüstung fängt Fehler ab.
- ✅ **Tränke nach dem 2. Tod:** Egon zeigt Tränke, dreht den Tisch, schenkt einen, legt ihn in den Trank-Platz (an der Helden-Figur unten links).
- Gebaute Bausteine nach der Ideen-Liste: auf Linie stürmen, stehen und im Kreuz/Diagonal/abwechselnd schießen, springen (gab es), eingraben und beim Auftauchen schießen, fliehen und Helfer rufen, beim Tod teilen / explodieren / schießen, umfallen und wieder aufstehen, Panzer mit kurzem offenem Fenster, von vorne geschützt (gab es), abprallen.
- **Noch offen (Vorschläge, eigene Ausführung):**
  - Zwei-Teile-Boss: stirbt ein Teil, wird der andere wilder.
  - Wurm-Boss aus Gliedern, die einzeln zerstört werden und Hindernisse hinterlassen.
  - Boss, der den Raum nicht betritt, sondern aus den Türen und von oben angreift (Schatten vor dem Stampfen).
  - Boss, der Fliegen um sich kreisen lässt und dann auf den Spieler stößt.
  - Boss mit Pfützen, dem bei Schaden Teile abfallen, die selbst angreifen.
  - End-Boss mit Phasen (Kugelmuster, Laser, Beschwörungen im Wechsel).
  - Neue Muster auch in den alten Gebieten mischen (z. B. Wandspinnen in der Totengruft), damit Raum-Kombinationen schwierig werden.
  - Gras, das sich im Wind wiegt und beim Durchlaufen zur Seite biegt.
  - Trank-Skills „Mehr Tränke“, „Stärkere Tränke“; weitere Trank-Arten (Tempo, Schild).

## Eigene Fallen (Nachricht vom 2026-11-27) – Logik fertig, Inhalt offen

- Fallen, die der Spieler selbst legt und die Gegner treffen: aus **Relikten** oder einem **Projektil**, das beim Aufprall eine Falle hinterlässt. Arten bisher: Krähenfüße, Glutfleck, eigenes Fangeisen (`hazard_types` `owner: player`). Offen: Items/Relikte mit `traps`, eigene Bilder, ggf. Fallen werfen (Taste).

## Spielgefühl, Komfort, Behälter, Tausch (Nachricht vom 2026-11-28)

Reihenfolge zum Bauen (✅ = gebaut):

1. ✅ **Weniger Beute im Dungeon** (`feature/weniger-beute`): ein Raum gibt höchstens 1 Ding her (Beute, Münzen, Herz oder Bombe; `loot.json` `room_budget`), Münzen seltener.
2. ✅ **Relikt nach dem ersten Boss** (`feature/weniger-beute`): Egon nimmt den Rubin und schenkt ein Moorherz-Relikt (+1 Herz, 4 Runs).
3. ✅ **Behälter im Lager** (`feature/behaelter-tausch`): Taschen/Kisten, die man kauft oder geschenkt bekommt und öffnet. Je eine Art für Relikte, Rüstungen, Materialien, Waffen; zu Beginn 3–4 Plätze, später größere.
4. ✅ **Tausch-Reiter bei Egon** (`feature/behaelter-tausch`): Sachen eintauschen, z. B. 3 Rubine → Relikt-Behälter, 3 Rubine → Rucksack 3×3.
5. **Treffer-Gefühl:** kurzer Stillstand (~0,05 s) bei starkem Treffer/Kill; leichtes Bildschirmwackeln (Explosion, Boss-Aufprall, eigener Treffer), in den Einstellungen abschaltbar; Gegner blinken weiß und werden zurückgestoßen; Beute fliegt zum Spieler, „Pling“ wird bei mehreren Münzen hintereinander höher.
6. **Weniger Frust:** Tod-Zusammenfassung (was hat getötet, wie weit, was im sicheren Platz gerettet, Rekord); Egon kommentiert die Todesursache („Schon wieder die Fangeisen? Ich verkauf dir Stiefel… teure.“); bei 1 Herz Musik dumpfer, Herzschlag-Rand stärker, Trank-Taste Q leuchtet; ein Satz zum Boss vor dem Kampf, der sein Muster verrät.
7. **Laden als Zuhause:** Heimkehr-Moment (Egon sieht die Beute, schaut gierig, „Heute verdient: 340 Gold“); großer Auftritt bei R3+ am Hebel (Licht, eigener Ton, Egon staunt).
8. **Komfort:** Shift+Klick schiebt direkt ins Lager/Inventar; „Alle Beute verkaufen“ mit Rückfrage; Vergleich beim Darüberfahren (grüne/rote Pfeile gegen das Getragene); Text- und Fadenkreuz-Größe einstellbar; Farbenblind-Modus (Seltenheit auch als Symbol).
9. **Gründe für morgen:** Tagesangebot (ein besonderes Teil nur heute); kleine Ziele im Lexikon („10 Wandspinnen besiegt → Egon zahlt 10 % mehr für Spinnenseide“).

## Aussehen und Stimmung (Nachricht vom 2026-11-28)

Reihenfolge zum Bauen (zuerst, was schnell geht oder viel bringt; ✅ = gebaut auf `feature/stimmung`):

**Dungeon**
1. ✅ (`feature/deko`, `scenes/run/room_props.gd`) **Deko in den Räumen:** Kisten, Fässer, Knochen, Pilze, Steine als Billboards (wie die Fackeln) zufällig an den Wänden, je Thema eigene; Daten in `floors.json` (`"props": [...]`). Bringt am meisten.
2. ✅ (als Lichthof `Fx.halo`, Glow wirkt in GL Compatibility kaum) **Glow im WorldEnvironment** (`run.tscn`, geht mit GL Compatibility seit 4.3): Feuerbälle, Fackeln, Türrahmen, Kristalle leuchten. Schnell auszuprobieren.
3. ✅ **Treffer-Blitz:** Gegner 0,05 s weiß beim Treffer (Teil von „Treffer-Gefühl“, Punkt 5 oben).
4. ✅ **Fackeln flackern:** Lichtstärke leicht und zufällig schwanken lassen.
5. ✅ (`feature/luft`, `scenes/run/room_air.gd`) **Staub und Glut in der Luft:** wenige CPUParticles3D je Raum, je Thema: Staub, Glutfunken (Glutschlund), Schnee (Frostgipfel), Glühwürmchen (Wiese, `effects/fireflies.png` gibt es).
6. **Boden-Decals:** Blutflecken, Risse, Moos, damit nicht jeder Raum gleich aussieht.
7. **Vignette und Farbstimmung je Dungeon:** kleiner Bildschirm-Shader auf dem SubViewport (dunkle Ränder, Tönung: Glut warm, Frost kalt), optional Dithering.
8. **Head-Bob beim Laufen** und leichte Neigung der Waffe beim Drehen.

**Laden und Menüs**
9. **Rahmen in der Seltenheitsfarbe** für jedes Teil auf Tisch und Lager (siehe Abschnitt 3), pulsierendes Leuchten ab R3.
10. **Lebender Hintergrund bei Egon:** Kerzen flackern, Staub schwebt, beim Hebel-Zug ploppen die Waren nacheinander auf.
11. **Großer Moment bei R3+ am Hebel:** Licht, kurzes Wackeln, Egon staunt (siehe Punkt 7 oben).
12. **Weiche Übergänge** zwischen Laden und Dungeon (Abblenden) statt harter Schnitte.

## Besondere Räume und eigene Dungeons (Nachricht vom 2026-11-28)

### Mysterium-Raum (als Nächstes)

- Auf jeder Ebene gibt es mit **30 %** Chance **einen** Mysterium-Raum (höchstens einen je Ebene). Auf der Karte hat er ein **?**, an der Tür einen eigenen Rahmen. Erst beim Betreten zeigt sich, welche Art er ist.
- Die Art wird **zufällig** aus dieser Liste gezogen (Gewichte in den Daten, z. B. `data/mystery_rooms.json`: `"chance": 0.3`, `"types": [...]` mit `weight`, Belohnung, Werten wie Wellen-Anzahl oder Sekunden):
  1. **Wellen-Raum:** 3 Wellen Gegner hintereinander. Danach steht eine Truhe in der Mitte (bessere Belohnung).
  2. **Zeit-Raum:** Die Belohnung steht schon sichtbar im Raum. Leben die Gegner nach 20 Sekunden noch, verschwindet sie.
  3. **Verfluchter Raum:** Am Eingang ein Schild mit einem Fluch für diesen Raum (z. B. „Kein Heilen“, „Gegner doppelt so schnell“). Dafür gibt es seltene Beute.
  4. **Dunkler Raum:** keine Fackeln, nur der Feuerball (Lichthof `Fx.halo`) macht Licht.
  5. **Rätselraum:** 3 Hebel oder Druckplatten in der richtigen Reihenfolge. Ein falscher Versuch weckt eine Ratte. Ist es gelöst, geht ein Fach mit der Belohnung auf.
  6. **Altar der Wahl:** 2 Items stehen auf Sockeln. Nimmt man eins, versinkt das andere.
  7. **Spiegelraum:** Kampf gegen einen Schatten des Spielers, der mit dessen eigenen Items schießt.
- Regeln: nicht auf der ersten Ebene des ersten Dungeons (Tutorial), nicht als Start- oder Boss-Raum, zählt zum Raum-Budget der Beute (`loot.json` `room_budget`) mit eigener Belohnung obendrauf.
- Reihenfolge zum Bauen: zuerst das Gerüst (30 %, ?, zufällige Art) mit **Dunkler Raum** und **Wellen-Raum** (brauchen fast keine neue Grafik), dann Zeit-Raum, Verfluchter Raum, Altar der Wahl, Rätselraum, zuletzt Spiegelraum (am meisten Arbeit).

### Weitere besondere Räume (später, selten)

- **Hinterhalt:** Der Raum wirkt leer. Fällt die Tür zu, kommen Gegner aus Decke oder Boden. (Könnte auch eine 8. Mysterium-Art werden.)
- **Egons Lieferung:** Kiste mit Egons Stempel. Bringt man sie heil nach Hause, zahlt Egon. Belegt Inventar-Platz, beim Tod weg.
- **Gefangener:** eingesperrter Abenteurer. Befreit gibt er einen Hinweis oder Schlüssel oder taucht später bei Egon auf.
- **Schatzkammer hinter einer Bombenwand:** ein Riss in der Wand verrät sie.

### Raum-Formen

- Säulen in der Mitte (Deckung), Gruben, schmaler Steg über Lava oder Gift.
- L-förmige oder große 2×1-Räume.
- Kleine bewegliche Teile (wie die Räderkluft, nur klein): rollender Stein, Stacheln, die der Reihe nach hochkommen.

### Eine Regel je Dungeon

- **Glut:** Lava-Risse gehen auf und zu; in manchen Räumen wird es heißer, je länger man bleibt.
- **Moor:** Irrlichter locken zu falschen Türen oder versteckten Schätzen.
- **Frostgipfel:** Eisboden, auf dem man rutscht; Feuerbälle schmelzen Eiswände (neue Wege).
- **Glutschlund:** Der Boden bebt ab und zu, Steine fallen von der Decke (Schatten zeigt, wo).
- **Wiese:** Tag und Nacht wechseln im Run; nachts andere Gegner und Glühwürmchen.

### Kleine Dinge

- ✅ (`feature/kaputte-deko`) **Zerstörbare Deko:** Kisten und Fässer aus `room_props.gd` gehen durch Feuerbälle kaputt, manchmal mit Münze (braucht Kollision).
- ✅ (`feature/wand-schriften`) **Wand-Schriften:** kurze Sätze früherer Abenteurer (Story, z. B. über Egon; Texte nach `docs/figuren/`).
- ✅ (`feature/raum-ton`) **Ton je Raum:** Tropfen, Wind, Ketten, leise und zufällig.
- ✅ (`feature/mini-boss`, „Anführer“) **Mini-Boss** in der Mitte jeder Ebene mit eigenem Lebensbalken.

## Raum-Fallen, Vorwarnungen, Ton für alles (Nachricht vom 2026-11-28)

### Neue Raum-Fallen (Gefahren im Raum, treffen den Spieler)

Gehören zu `floors.json` `hazard_types` (wie Stacheln/Lava), Takt und Schaden in den Daten. Jede Falle **warnt vorher** (Bild + Ton), damit man reagieren kann.

1. ✅ (`feature/pfeil-waende`) **Pfeil-Wände:** Löcher in der Wand schießen Pfeile quer durch den Raum (`EnemyShot.arrow` gibt es schon).
   - Arten: im festen Takt; per **Druckplatte** ausgelöst; in Reihen nacheinander (Lauf-Muster).
   - Vorwarnung: Loch glimmt/rüttelt kurz, Klick-Ton (Mechanik spannt), dann Zisch beim Schuss.
   - Pfeile treffen auch Gegner (wer Gegner auf die Platte lockt, lässt sie sich selbst abschießen).
2. ✅ (`feature/stachelsteine`; Bahnen fest im Code: line_x, line_z, square, circle) **Wandernde Stachelsteine:** Steine mit Spitzen bewegen sich in **festen Mustern** durch den Raum (hin und her, im Kreis, an der Wand entlang, auf Schienen). Berührung = ½ Kohle Schaden und kurzer Rückstoß.
   - Muster in den Daten (`path`: Punkte, `speed`, `loop`/`pingpong`), damit man sie lernen kann.
   - Rumpeln/Schleifen als 3D-Ton, lauter je näher; Funken an der Wand beim Umdrehen.
   - Feuerbälle halten sie nicht auf (nicht zerstörbar), Bomben vielleicht kurz.
3. ✅ (`feature/monster-falle`) **Monster-Falle (Decke):** Eine versteckte Platte; tritt man darauf, **fallen Gegner von oben** in den Raum.
   - Vorwarnung: Klick unter dem Fuß, Staub rieselt von der Decke, Schatten am Boden, wo sie landen; dann Aufprall-Ton und Staubwolke.
   - Passt zum geplanten „Hinterhalt“-Raum (Abschnitt „Besondere Räume“).
   - Nach dem Auslösen ist die Platte sichtbar (kein zweites Mal).

### Gegner- und Boss-Aktionen mit Bild und Ton

Viele Angriffe gibt es schon (`burrow`, `teleport`, `leap`, `charge`, `laser` …, `docs/SYSTEME.md`). Jede Aktion bekommt einen **eigenen Effekt und einen eigenen Ton**, damit der Spieler sie erkennt, bevor sie trifft:

| Aktion | Bild (Vorwarnung) | Ton |
|---|---|---|
| Eingraben (`burrow`) | Erdbrocken fliegen, Erdhügel wandert unter dem Boden zum Spieler, rote Markierung | Graben, dumpfes Wühlen, beim Auftauchen Erd-Krachen |
| Teleport hinter den Spieler (`teleport`) | Gegner flimmert und zerfällt in Funken, **am Zielort** (hinter dem Spieler) erscheint kurz vorher ein Leuchten | „Wusch“ beim Verschwinden, leises Summen am Zielort, „Plopp“ beim Erscheinen |
| Sprung (`leap`) | duckt sich, Schatten wächst am Landepunkt | Grunzen beim Absprung, Aufprall mit Wackeln |
| Ansturm (`charge`) | scharrt mit dem Fuß, Staub, Ziel-Linie | Schnauben/Brüllen, schwere Schritte |
| Aufladen/Zaubern | Gegner leuchtet stärker, Teilchen sammeln sich | ansteigender Ton (höher = gleich geht's los) |
| Beschwören (`summon`) | Kreis/Rune am Boden, wo Helfer kommen | tiefes Murmeln, dann Knall |
| Unsichtbar (`phase`) | Flimmern, leichte Verzerrung, wo er ist | leises Atmen/Flüstern verrät die Richtung |

### Regel: Jede Aktion hat einen Ton

- **Alles, was passiert, macht ein Geräusch:** jeder Angriff, jede Vorwarnung, jeder Treffer, jede Falle, jedes Aufheben, jede Tür, jeder Knopf. Stille nur mit Absicht (z. B. Boss-Halle vor dem Kampf).
- **Angriffe kündigen sich hörbar an:** Der Ton kommt **vor** dem Treffer (Vorwarnung), nicht erst mit ihm. Der Abstand zwischen Ton und Treffer ist fair (Richtwert 0,4–0,8 s, in den Daten).
- **Ton passt zur Aktion und zum Gegner:** Ratte quiekt, Golem grollt, Magier summt; Graben klingt nach Erde, Teleport nach Magie.
- **Ton kommt aus der Richtung** der Quelle (3D-Ton über `Enemy.sound` / `AudioManager.play_sound_at`), damit man z. B. einen Teleport hinter sich hört.
- **Bild und Ton zusammen:** Jede gefährliche Aktion hat beides; wer nicht hinsieht, hört sie, wer leise spielt, sieht sie.
- Fehlt eine Datei, wird der Ton mit `SoundSynth` erzeugt (wie die Gegner-Rufe), Werte in den Daten (`voice`, `audio.json`).
- Prüfen: Neuer Gegner/Angriff/Falle ohne Ton = nicht fertig. Ein Test könnte prüfen, dass jeder Angriff und jede Falle in den Daten einen Ton hat.

## UI und Komfort: Laden und Tab (Nachricht vom 2026-11-28)

Ergänzt Punkt 8 „Komfort“ oben (Shift+Klick, „Alle Beute verkaufen“, Vergleichs-Pfeile, Farbenblind-Modus).

### Laden (Egon)

1. **Auto-Sortieren:** Knopf (oder Taste **T**) packt Lager und Inventar dicht; sortiert nach Art, Seltenheit oder Wert (Auswahl merkt sich das Spiel). Gesperrte Teile bleiben liegen.
2. **Sperren:** **Strg+Klick** setzt ein Schloss auf ein Teil. Gesperrtes wird nie verkauft (auch nicht bei „Alle Beute verkaufen“), nicht weggeworfen und nicht vom Sortieren bewegt.
3. **Rückkauf:** Verkauftes kann man **bis zum Ende des Tages** zum gleichen Preis zurückkaufen. Das sind die „3 Plätze Verlauf“ aus Abschnitt 3 (Verkauf/Verlauf rechts).
4. **Wert im Tooltip:** Jedes Teil zeigt „Egon zahlt: X Gold“. Mit **Alt** gedrückt: Gesamtwert des Inventars bzw. Lagers.
5. **„Kann ich mir leisten“:** Zu teure Ware abgedunkelt, Preis rot. Ware, die besser ist als das Getragene, hat schon auf dem Tisch einen kleinen grünen Pfeil (ohne Darüberfahren).
6. **Hebel-Kosten vorher:** „Nächster Zug: 40 Gold“ direkt am Hebel. Rückfrage, wenn die Dose danach unter einen Wert fällt (Wert in den Einstellungen oder `shop.json`).
7. **Bereit-Check vor dem Run:** Beim Dungeon-Start kurzer Hinweis, wenn etwas fehlt: „Trank-Platz leer“, „Relikt hält nur noch 1 Run“, „Inventar fast voll“. Weiter mit einem Klick, abschaltbar.
8. **Ausrüstungs-Sets:** Ein Set speichern und mit einem Klick wieder anlegen (wichtig, sobald es mehr Klassen gibt).

### Tab im Dungeon – ✅ gebaut (`feature/tab-komfort`; Tab hält das Spiel schon an, Run-Übersicht = Werte + Synergien-Zahl mit Namen)

1. **Pause oder Zeitlupe beim Öffnen:** Einstellung „Tab: Pause / Zeitlupe / läuft weiter“, damit Sortieren im Kampf kein Frust ist.
2. **Run-Übersicht:** alle Run-Items mit ihren Synergien, aktive Effekte, Werte mit Herkunft („Schaden 3,5 (+1,5 durch Items)“).
3. **Schnell-Wegwerfen:** Teil mit der Maus berühren und **X** halten (kurzer Balken) → fällt auf den Boden, ohne Ziehen. Gesperrte Teile nicht.
4. **Beute-Wert der Tasche:** unten im Fenster „Wert der Tasche: 230 Gold“ (was Egon dafür zahlt), damit man sieht, ob sich Umkehren lohnt.

### Für Laden und Tab gleich

- **Gleiche Steuerung überall:** Ziehen, **R** drehen, **Shift+Klick** schieben, **Rechtsklick**, **Strg+Klick** sperren, **X** wegwerfen machen im Laden und im Dungeon dasselbe.
- **Ton und Bild für jede Aktion:** Aufheben, Ablegen, Drehen, „Kein Platz“, Sperren, Verkaufen, Sortieren bekommen je einen kurzen Ton und einen kleinen Effekt (Ploppen, Wackeln, Rot-Blinken). Gilt nach der Regel „Jede Aktion hat einen Ton“ oben.
- **Tastenhilfe am Rand:** eine Zeile „R drehen · Shift schieben · Strg sperren · X wegwerfen“, in den Einstellungen abschaltbar; zeigt nur, was im Moment geht (z. B. „R drehen“ nur beim Ziehen).

## Gegner, Bosse, Schuss-Farben (Nachricht vom 2026-11-28)

### Schuss-Farbe = Schaden – ✅ gebaut (`feature/schuss-farben`; Farbenblind-Formen noch offen)

Jeder Gegner-Schuss bekommt seine Farbe **aus dem Schaden** (eine Tabelle in den Daten, z. B. `enemies.json` `shot_colors`; nie je Gegner von Hand). So sieht man sofort, wie gefährlich ein Schuss ist.

| Schaden | Farbe | Zusatz |
|---|---|---|
| ½ Kohle | **Grün** | klein, schwacher Lichthof |
| 1 Kohle | **Rot** | normaler Lichthof |
| 1½ Kohle | **Violett** | größer, flackert leicht |
| 2 Kohlen | **Schwarz mit weißem Kern** | dunkler Rauchschweif |
| ab 2½ | **Weiß-gold, pulsierend** | Funken, eigener Zisch-Ton |

- Gilt für Kugeln, Pfeile (Spitze/Schweif in der Farbe), Laser und Spucke.
- Farbenblind-Modus: zusätzlich Form oder Größe (½ = Punkt, 1 = Kugel, 1½ = Raute, 2 = Stern).
- Ausnahmen nur mit Absicht (z. B. Säure bleibt giftgrün, dann Schaden über die Größe zeigen).

### Geister: unsichtbar werden – ✅ gebaut (`feature/geister-unsichtbar`)

- Geister (normale Gegner, nicht nur Bosse; `phase` gibt es bei Bossen schon) werden alle paar Sekunden **unsichtbar**: Bild, Ring, Blickrichtungs-Keil und Lebensbalken verschwinden, sie bewegen sich weiter.
- Fair bleiben (Regel „Jede Aktion hat einen Ton“): beim Verschwinden ein Flimmern und „Wusch“, unsichtbar ein leises **Flüstern/Atmen aus ihrer Richtung** (3D-Ton), leichte Verzerrung in der Luft, wenn man genau hinsieht. Kurz vor dem Erscheinen ein Schimmer.
- Unsichtbar greifen sie nicht an (oder erst nach dem Auftauchen mit kurzer Vorwarnung). Treffer im unsichtbaren Zustand machen sie kurz sichtbar.
- Werte in den Daten: `invisible` {every, duration, hit_reveal}.

### Untote stehen wieder auf (Zombies, Skelette) – ✅ gebaut (`feature/untote`; Zertreten und Kreis-Balken noch offen, statt Balken ein wachsender Lichthof)

- Bei 0 Leben fallen sie **zu Boden** (liegen als „Leiche“, keine Kollision mit Schüssen außer gezielt am Boden). Nach **3 Sekunden** stehen sie wieder auf, mit **50 % ihres vollen Lebens**. Das passiert jedes Mal wieder (immer 50 %).
- Endgültig tot sind sie nur, wenn der Spieler die **Leiche zerstört**: liegend nochmal treffen (Feuerball, Schwert, Bombe) oder darüber laufen und zertreten (Taste oder mit Item „Steine zertreten“).
- Vorwarnung beim Aufstehen: Leiche zuckt, Knochen klappern, Stöhnen (Ton), grüner/blauer Schimmer, ein Kreis-Balken über der Leiche läuft ab (3 s).
- Baut auf `revive` (Strohmann) auf; neu: wiederholbar, Zeit und Leben in den Daten (`revive` {delay: 3, hp: 0.5, repeat: true}).
- Beute und EXP erst beim endgültigen Tod. Leichen zählen, damit der Raum erst offen ist, wenn alle Leichen weg sind.

### Boss: Wurm/Schlange aus dem Boden – ✅ gebaut als „Säurewurm“ (`feature/wurm-boss`, Boss im Tiefen Moor; Schwanzspitze in Phase 3 noch offen)

- Gräbt sich ein (Erdhügel wandert sichtbar, Wühl-Ton), **springt im Bogen aus dem Boden** auf den Spieler zu, landet auf der **Position, die der Spieler beim Absprung hatte**, und taucht wieder ab. Vorwarnung: Boden bebt, Risse und Schatten am Landepunkt, Brüllen beim Absprung.
- **Säure spucken:** taucht ab und zu auf, bleibt kurz stehen und spuckt Säure auf den Spieler und um ihn herum (Bogen-Schüsse, Landepunkte als grüne Kreise). Wo sie landet, bleibt eine **Säurepfütze** (Falle, wie `poison`), die beim Drüberlaufen Schaden macht und nach einiger Zeit austrocknet.
- **Fliegt der Spieler** (Flug-Items), tut die Pfütze nichts (wie alle Bodenfallen).
- Treffbar nur, wenn er draußen ist (Kopf), sonst nicht.
- Ab 50 %: zwei Sprünge hintereinander oder Pfützen bleiben länger; ab 25 %: Kopf und Schwanzspitze tauchen gleichzeitig auf (zwei Angriffe auf einmal).

### Boss: Vogel mit Meteoriten – ✅ gebaut als „Sturmadler“ (`feature/vogel-boss`, Boss am Sturmgipfel)

- Fliegt **hoch** (aus der Reichweite, Schatten am Boden zeigt, wo er ist) und lässt **Meteoriten** fallen: rote Kreise am Boden, die sich füllen, dann Einschlag mit Wackeln und Krater (Glut kurz liegen lassen). Der Spieler muss ausweichen.
- Weitere Angriffe:
  - **Sturzflug:** kreischt, legt die Flügel an, stürzt auf den Spieler (Ziel-Linie), schlägt auf und ist kurz **am Boden betäubt** (Moment zum Angreifen).
  - **Federhagel:** Fächer aus Federn (Schüsse) im Flug.
  - **Windstoß:** Flügelschlag drückt den Spieler weg (in Pfützen/Meteor-Kreise).
  - **Ruf:** kleine Vögel als Helfer.
- Ab 50 % mehr Meteoriten auf einmal, ab 25 % Meteoriten in Mustern (Ring um den Spieler, Linie quer durch den Raum).

### Boss-Phasen (für alle Bosse) – ✅ gebaut (`feature/boss-phasen`; Musik-Steigerung und Raum-Veränderung beim Wechsel noch offen)

Heute: unter 50 % schneller und mehr Schüsse. Neu als feste Regel mit Phasen in den Daten (`phases` [{at: 0.5, …}, {at: 0.25, …}]):

- **Phase 1 (100–50 %):** Grund-Muster, langsam, lernbar.
- **Phase 2 (ab 50 %):** **neues Muster** (neuer Angriff dazu oder Angriffe kombiniert), Übergang mit kurzer Pause: Boss brüllt, Bildschirm wackelt, Farbe/Aussehen ändert sich (z. B. rot glühende Augen), Musik wird intensiver. In der Pause ist er unverwundbar, aber greift nicht an.
- **Phase 3 (ab 25 %, „Wut“):** **schneller** (kürzere Pausen zwischen Angriffen, schnellere Schüsse), dafür etwas kürzere Vorwarnungen, aber nie unter dem fairen Mindestwert.
- Optional je Boss: beim Phasenwechsel Helfer rufen, Raum verändern (Lava steigt, Säulen fallen), Schwachstelle wird sichtbar.
- Lebensbalken zeigt die Phasen-Grenzen als Striche bei 50 % und 25 %.

### Geist aus der Wand (zieht den Spieler an) – ✅ gebaut als „Wandgeist“ (`feature/wand-geist`, in der Totengruft)

- Taucht **aus einer Wand** auf (Wand bekommt Risse und leuchtet vorher, Stöhnen/Heulen aus der Richtung).
- **Saugt den Spieler an:** zieht ihn langsam zur Wand (sichtbar als Luft-Strudel/Linien zum Geist, Saug-Ton wird lauter). Man kann dagegen anlaufen, kommt aber langsamer voran; Dash/Sprint hilft.
- Ist der Spieler **zu nah**, holt der Geist mit seiner **Kralle** aus (kurzes Ausholen mit Kratz-Ton als Vorwarnung, dann Treffer).
- Nach einigen Sekunden oder nach einem Treffer verschwindet er wieder in der Wand und kommt woanders heraus. Verwundbar nur, solange er draußen ist.
- Gut kombinierbar mit Fallen/Pfützen vor der Wand.

## Kisten, Stein-Kammern, Egons Umzug (Nachricht vom 2026-11-28)

### Kisten (Truhen-System, siehe Backlog „Truhen“ in `docs/ITEM_IDEEN.md`) – ✅ gebaut (`feature/kisten`; Kisten-Beute zählt nicht zum Raum-Budget)

Drei Arten, Werte und Beute in den Daten (z. B. `data/chests.json`: Art, Bild, Beute-Tabelle, `bomb_opens`, `key`):

| Art | Öffnen | Bomben | Beute |
|---|---|---|---|
| **Holzkiste** | einfach anfassen (F oder drüberlaufen) | gehen kaputt, Inhalt fällt heraus | normal |
| **Schlosskiste** (Eisenbeschläge, Vorhängeschloss) | mit **Schlüssel** | **aufsprengen** geht auch; dann ist ein Teil der Beute kaputt (z. B. ein Ding weniger oder schlechtere Stufe) | besser |
| **Tresorkiste** (dunkles Eisen, Runen) | **nur mit Schlüssel** | **kein Effekt**: Bombe prallt ab, „Klong“-Ton, Funken, Runen leuchten kurz | am besten |

- Jede Art sieht man sofort an (Farbe/Beschläge); Tooltip bzw. kurzer Text beim Anschauen: „Verschlossen“ / „Nur mit Schlüssel“.
- Ton je Aktion: Holz knarzt, Schloss klickt, Tresor-Runen summen, Aufsprengen splittert.
- Zählt zum Raum-Budget der Beute (`loot.json` `room_budget`) wie zerbrechliche Deko; Kisten geben ihre eigene Beute obendrauf nur, wenn der Raum das erlaubt (Wert in den Daten).
- Eisenschlüssel (bleibt über Runs) und zerbrechliche Schlüssel öffnen beide; auch Tresorkisten (entschieden 2026-11-28: „Schlüssel ist Schlüssel“).

### Stein-Kammer (Raum-Art) – ✅ gebaut (`feature/kisten`; Ringe 2,2 m/3,4 m, damit eine Bombe am Ring die Kiste nicht trifft; Hinweis-Text beim ersten Mal noch offen)

- Eine Kiste in der Mitte (oder in einer Ecke), **ringsum von Steinen eingemauert**. Man kommt nur heran, wenn man die Steine **wegbombt** (Bombe zerstört Steine im Umkreis, gibt es schon: `Dungeon.explode`).
- Varianten: einfacher Ring (1 Bombe reicht), doppelter Ring (2 Bomben), Steine mit Tresorkiste drin (Bombe für die Steine **und** Schlüssel für die Kiste).
- Achtung: Bombt man zu nah an einer Holzkiste, geht sie mit kaputt (Inhalt bleibt aber liegen); bei der Schlosskiste wird sie dabei aufgesprengt (Teil der Beute weg). So lohnt es sich zu zielen.
- Hinweis, damit man es versteht: auf der Karte ein Kisten-Symbol, beim ersten Mal ein kurzer Satz (Tutorial-Hinweis oder Wand-Schrift: „Wer keine Bombe hat, hat keine Kiste.“).

### Egons Umzug zu jedem neuen Dungeon – ✅ Gimmicks und Sprüche gebaut (`feature/egon-umzug`; Tisch auf Rädern ins Bild schieben, Hut/Schal-Bilder und Wüste noch offen)

Heute zieht Egon nach einer Quest schon um (`quests.json` `locations`: anderer Hintergrund, Ortsname). Neu dazu:

- **Umzugs-Moment:** Nach dem Freischalten Abblende, dann steht der Spieler mit Egon **vor dem Eingang des neuen Dungeons** (Hintergrund des Ladens = der neue Eingang). Egon schiebt seinen Tisch auf Rädern ins Bild, keucht.
- **Ein Gimmick je Ort** (Aussehen + Sprüche, in den Daten je `location`: Bild-Variante von Egon, Sprüche-Liste, evtl. Ton):
  - **Moor:** Gummistiefel, Mücken umschwirren ihn, er klatscht ab und zu.
  - **Wiese:** Strohhut, niest ständig (Heuschnupfen), Blumen am Tisch „zur Dekoration, Preis auf Anfrage“.
  - **Frostgipfel:** **friert**, zittert, Schal bis zur Nase, Eiszapfen an der Nase, Zähneklappern als Ton, Atemwolken.
  - **Glutschlund:** schwitzt, fächelt sich Luft zu, Tisch qualmt leicht.
  - **Wüste (später):** **Sonnenhut** und Sonnenbrille, Sand im Tisch, verkauft „Wasser“.
- Die Sprüche (Beispiele, Texte nach `docs/figuren/EGON_EHRLICH.md`) stehen dort im Abschnitt „Umzug und Orte“.
