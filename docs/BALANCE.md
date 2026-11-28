# Balance – Zahlen und Ziele

Stand 2026-11-27 (`feature/balance`). Alle Zahlen stehen in `data/`; dieses Dokument erklärt, **warum** sie so sind.
Nachrechnen: `py assets/_reference/balance/balance.py` (liest die JSON-Dateien, ändert nichts).

## Die Idee

Der Spieler zockt: Er geht in den Dungeon, bringt Beute heim und muss entscheiden, was er mit dem Gold macht:

- **Ausrüstung** bei Egon (Glücksspiel-Tisch, Material und Seltenheit gewürfelt),
- **Skills** (kosten Gold *und* Skillpunkte, also sind sie durch die Stufe begrenzt),
- oder **sparen** – aber über dem Dosen-Limit klaut Egon nachts.

Kein Dungeon soll mit der Ausrüstung, die man beim Betreten erwarten kann, zu leicht oder zu schwer sein. Wer frisch anfängt, stirbt im ersten Dungeon meist auf Ebene 2–4 und braucht ein paar Einkäufe, bis er durchkommt.

## Vier Dungeons, fünf Materialien

| Dungeon | Gebiete | Leben × | EXP × | Shop × | Öffnet | Neues Material bei Egon |
|---|---|---|---|---|---|---|
| Dungeon der Glut | Rattenkeller, Goblinstollen, Totengruft | 1,0 | 1 | 1 | – | Kupfer (Bronze ab Stufe 3) |
| Moor der Irrlichter | Sumpfufer, Banditenlager, Tiefes Moor | 2,0 | 2 | 2,5 | nach Glut | **Eisen** |
| Wispernde Wiese (Neben-Dungeon) | Hohes Gras, Kristallwiese, Jagdgrund | 2,5 | 2,8 | 3,5 | nach Moor | – |
| Frostgipfel | Wolfswald, Eishöhle, Sturmgipfel | 3,0 | 3,5 | 5 | nach Moor | Silber |
| Glutschlund | Glutstollen, Magmakammer, Höllentor | 4,2 | 5,5 | 9 | nach Frost | Gold |

Jeder Dungeon hat 6 Ebenen wie der erste (zwei je Gebiet, die zweite schwerer: Leben ×1,0 / 1,25 / 1,1 / 1,4 / 1,25 / 1,55). Die neuen Dungeons haben **Fallen**: Giftpfützen (Moor), Stacheln (Banditen, Wald), Eisstacheln (Eis, Sturm), Lava (Vulkan), Fangeisen und versteckte Stacheln im hohen Gras (Wiese).

Materialien kommen auf Egons Tisch, sobald sie offen sind (`shop.json` `materials`). Ein Material, das zwei Stufen unter dem besten offenen liegt, kommt nur noch ¼ so oft (Kupfer wird selten, wenn Silber offen ist). Der Hebel kostet mit dem besten Material mehr (×1 / ×3 Eisen / ×7 Silber / ×15 Gold), sonst wäre Neu-Würfeln später geschenkt.

## Ausrüstung (R1-Werte, mal `gear.json` `rarity_stats` je Seltenheit)

| Teil | Wirkung | Kupfer | Bronze | Eisen | Silber | Gold |
|---|---|---|---|---|---|---|
| Waffe | Schaden | 0,2 | 0,4 | 0,8 | 1,3 | 1,9 |
| Handschuhe | Schaden | 0,1 | 0,2 | 0,3 | 0,45 | 0,6 |
| Helm | Schild-Herzen | 0,5 | 0,5 | 1 | 1 | 1,5 |
| Brust | Schild-Herzen | 0,5 | 1 | 1,5 | 2 | 2,5 |
| Beine | Schild-Herzen | 0,5 | 0,5 | 1 | 1,5 | 1,5 |
| Stiefel | Tempo | 0,2 | 0,3 | 0,4 | 0,5 | 0,6 |
| **Preis ×** | | 1 | 2,2 | 5 | 11 | 24 |

Grundpreise (Kupfer R1): Waffe 30, Brust 25, Helm/Handschuhe 20, Beine/Stiefel 15. R2 kostet ×2, R3 ×4.

## Was ein Run bringt (Rechner, alles verkauft)

| Dungeon | Sieg: Gold / EXP | Tod auf Ebene 3: Gold / EXP |
|---|---|---|
| Glut | 850 / 825 | 120 / 200 |
| Moor | 2100 / 1650 | 260 / 400 |
| Frost | 3600 / 2900 | 570 / 700 |
| Vulkan | 7300 / 4500 | 1050 / 1100 |

Wirklich heim kommt weniger: Die Tasche hat 4 Plätze (Beute stapelt nicht), man muss beim Händler im Dungeon verkaufen und gibt dort Gold für Items aus. Faustregel: 60–70 %.

So passt es: Ein früher Run im ersten Dungeon (≈ 80 Gold heim) reicht für **ein** Kupfer-/Bronze-Teil **oder** einen Skill. Ein Eisen-Teil (75–150) kostet im Moor etwa einen Run, Silber/Gold ein bis zwei Runs.

## Stufen und Skills

Stufen: `levels.json` `exp_table` [64, 90] für den Anfang (erster Run ≈ 80 % von Stufe 1), danach `base_exp` 30 × `growth` 1,25 (Stufe 10 ≈ 1 200 EXP, 15 = 3 300, 20 = 10 300, 25 = 31 600, 30 = 96 800). Mit dem EXP-Faktor der Dungeons ist man nach dem ersten Dungeon etwa Stufe 14, nach dem Moor 20, nach Frost 23, nach dem Vulkan 26–28. Die Seltenheiten bei Egon kommen passend dazu: R2 ab 5, R3 ab 10, R4 ab 16, R5 ab 21, R6 ab 25, R7 ab 28.

Skill-Preise richten sich nach der Stufe, ab der man sie lernen kann (dann ist man in diesem Dungeon und verdient so viel): Stufe 1–6 ≈ 30–180 Gold, 8–14 ≈ 150–600, 15–20 ≈ 500–1 200, ab 22 ≈ 1 500–4 000. So bleibt „Skill oder Ausrüstung?“ in jedem Dungeon eine echte Frage.

### Skill-Überarbeitung (2026-11-28, `feature/skills-dungeons`)

Nachrechnen: `py assets/_reference/balance/balance.py`, Abschnitt „Skills: Preis, Freischaltung, Wert“ (zeigt je Stufe Gold, Punkte, Spielerstufe, Dungeon und was sie dann bringt).

Was vorher nicht stimmte:

- **Keine Wahl bei den Punkten:** Alle Punkt-Skills zusammen kosteten 28 Punkte, Stufe 30 gibt 29. Wer lange spielt, bekommt alles. Jetzt kosten sie **31**, am Ende (Stufe ~27) hat man etwa **26**: man muss sich entscheiden (z. B. Weitblick oder Dicke Haut 2).
- **Kraft war viel stärker als der Rest:** Kraft 1 bringt am Anfang +38 % Schaden für 1 Punkt, Flinke Hände nur +6 %. Kraft kostet jetzt mehr Punkte ab Stufe 3 (1/1/2/2/3), Flinke Hände bringen +9 % statt +6 % je Stufe (Feuerpause ×0,92), Leichtfuß +0,25 statt +0,2 Tempo.
- **Blaues Herz war ein Schnäppchen:** ein zusätzliches Leben in jedem Run für 1 Punkt ab Stufe 2. Jetzt 2 Punkte ab Stufe 3.
- **Tote Stufen:** Weitblick 3, Dicke Haut 2, Reliktschutz 4 brauchten Stufe 30 (praktisch nie erreicht), Relikt-Platz 2 Stufe 25. Jetzt Stufe 20 / 22 / 26 / 22.

**Skills hängen am Dungeon-Fortschritt** (`skills.json` `dungeon` je Stufe): die großen Stufen gehen erst, wenn der passende Dungeon offen ist, nicht nur bei genug Erfahrung. So passt der Skill zum Material bei Egon und man kann nicht im ersten Dungeon alles hochfarmen:

| Dungeon offen | Skill-Stufen |
|---|---|
| Moor (Eisen bei Egon) | Eisen-Rucksack, Kraft 4, Flinke Hände 3, Glückspilz 3, Geheimtasche 2, Rucksack-Riemen 2, Reliktschutz 3, Goldnase 2, Mehr Ware 3, Seltene Ware 2, Größere Dose 3 |
| Frostgipfel (Silber) | Silber-Rucksack, Kraft 5, Dicke Haut 2, Relikt-Platz 2, Rucksack-Riemen 3, Reliktschutz 4, Goldnase 3, Größere Dose 4 |
| Glutschlund (Gold) | Karawanen-Rucksack, Rucksack-Riemen 4 |

Gold-Preise blieben: Sie liegen wie geplant bei etwa einem Run des Dungeons, in dem man die Stufe lernen kann (Eisen-Rucksack 900 ≈ ein Moor-Run, Karawanen-Rucksack 6 000 ≈ ein Glutschlund-Sieg). Spieler-Stufe *und* Dungeon müssen passen; der Baum zeigt beides im Tooltip („Erst wenn offen: …“), gesperrte Stufen sind grau.

**Größere Dose** (Gruppe „Laden“): +300 sicheres Gold je Stufe (bis 1 400). Ohne sie ist das Limit 200 – wer später sparen will, muss das Risiko tragen oder in die Dose investieren.

## Schwierigkeit: Schüsse je Gegner

Der Rechner nimmt an, wie stark man beim Betreten ist (nur Waffe, Handschuhe und Kraft, ohne Items des Runs; tiefe Ebenen mit Items ×1,6):

| Spieler | Schaden | Ebene 1 | Ebene 6 | Boss Ebene 6 |
|---|---|---|---|---|
| Neu (Kupfer-Stab) | 1,3 | 2,9 | 8,8 | 135 |
| Ende Dungeon 1 (Bronze R2, Kraft 2) | 2,75 | 1,4 | 4,2 | 64 |
| Start Moor (Eisen R2, Kraft 3) | 3,9 | 2,6 | 5,9 | 90 |
| Start Frost (Silber R2, Kraft 4) | 5,2 | 3,8 | 6,2 | 108 |
| Start Vulkan (Gold R3, Kraft 5) | 7,3 | 3,6 | 7,5 | 109 |

Ziel: Ebene 1 eines Dungeons mit 2,5–4 Schüssen, Ebene 6 mit 6–8, Boss etwa 40 Sekunden. Gegner-Schaden steigt mit: 1–2 halbe Herzen im ersten Dungeon, 2–3 im Vulkan (dafür gibt es mehr Schild-Herzen aus Eisen/Silber/Gold).

## Was im Spiel geprüft werden muss

Die Zahlen sind gerechnet, nicht gespielt. Beim Spielen auf diese Punkte achten und die Werte in `data/` drehen:

- Schafft ein neuer Spieler Ebene 2 des ersten Dungeons? Wenn nicht: `floors.json` `floors` `hp_mult` senken.
- Wie viel Gold kommt wirklich heim (End-Bildschirm „Mit nach Hause“)? Liegt es weit unter 60 % der Tabelle, Beute-Werte (`loot.json` `value`) oder Taschen-Plätze (`meta.json` `bag`) anheben.
- Fallen: zu oft getroffen? `hazard_types` `damage` senken oder `hazards` [min, max] kleiner.
- Bosse zu lang? `dungeons.json` `hp_mult` senken (wirkt auf alle Gegner des Dungeons).
