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
