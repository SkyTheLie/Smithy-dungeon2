# BINDUNG.md – Erfolgserlebnis und Spielerbindung

> Ideen, wie sich Fortschritt in Smithy besser anfühlt und Spieler länger dranbleiben (Stand 2026-10-23).
> [ ] offen, [~] teilweise, [x] erledigt. Fertiges wandert zusätzlich nach `docs/SYSTEME.md`.

## Befund

1. **Die großen Momente sind nur eine Textzeile.** Level-Up, Erfolg, Dungeon geschafft und neue Rezepte laufen alle über dieselbe Toast-Zeile im HUD; kommen zwei gleichzeitig, sieht man nur die letzte. Am Amboss gibt es nur „Perfekt!“ als Text, die fertige Waffe an der Werkbank wird nicht gezeigt, Dungeon-Beute liegt unsichtbar in der Loot-Kiste.
2. **Belohnungen kommen zu selten.** Spieler-Lv 2 erst in Kapitel 3, Lv 4–5 erst nach Kapitel 9; an manchen Tagen 0 Kunden; ein Gegenstand braucht 6 Stationen, das nutzt sich ab.
3. **Man sieht nicht, was die eigene Arbeit bewirkt.** Das geschmiedete Schwert verschwindet aus dem Blick, dabei ist es der Kern des Spiels.

## Paket 1 – Wucht (nur Code, kein PixelLab)

- [x] Amboss: Funken, schwebende Punktzahl, Bildschirm-Wackeln und kurzer Stillstand bei Treffern, Combo bei grünen Treffern in Folge (höherer Ton).
- [x] Fertige Ausrüstung an der Werkbank groß zeigen (Lichtstrahlen in der Farbe der Seltenheit, Name erscheint Buchstabe für Buchstabe, „Seltenheit gestiegen!“, wenn das Zusammensetzen eine Stufe gebracht hat).
- [x] Warteschlange für Meldungen (nichts überschreibt sich mehr); Level-Up und Ruf-Rang als große Einblendung.

## Paket 2 – Grund für „noch ein Tag“

- [x] **Tagesbilanz beim Schlafen** (Aufwach-Einblendung erweitern): Gold verdient, Teile geschmiedet, beste Seltenheit, Ruf-Balken – und darunter, was **morgen** ansteht („Mondlilie reif in 1 Tag“, „Rashid kommt am Sonntag“, „Bruno wieder ausgeruht“, „Noch 340 Gold bis Hausstufe 3“).
- [x] **Jeden Tag ein garantiertes Ziel:** umgesetzt als mindestens 1 Kunde pro Tag (`min_per_day`) und zu 50 % ein Eilauftrag (2 Tage Frist, +50 % Gold). Offen: Zettel direkt am Auftragsbrett statt Kunden vor der Schmiede.
- [~] **Ziele auf drei Ebenen** – Woche und langes Ziel stehen jetzt morgens in der Bilanz („Ziel: noch 340 Gold bis zum nächsten Hausausbau“); offen: dauerhaft im Quest-Tracker: heute (Auftrag), diese Woche (Miete, Reisender, Konrad), langfristig (Hausstufe, Ruf-Rang, nächstes Metall).

## Paket 3 – Takt der Belohnungen (nur Werte)

- [x] Spieler-Level-Kurve am Anfang schneller: Lv 2 nach ca. 10 Minuten, Lv 5 in Kapitel 4–5, später langsamer (`data/player_level_table.tres`: 25, 75, 150, 250, 900, 1260, danach die alte Kurve ab 2200; insgesamt 2 Level mehr).
- [x] Teilbelohnung bei verlorenem Dungeon (z. B. 30 % der Beute statt nichts).
- [x] Loot-Kiste: Beute einzeln aufploppen lassen, das Seltenste zuletzt.

## Paket 4 – Die eigene Arbeit sichtbar machen

- [x] **Waffen mit Geschichte:** jede selbst geschmiedete Waffe zählt mit („Geschmiedet am 3. Frühling · 47 Ratten · hat den Rattenkönig besiegt“), ab einer Schwelle bekommt sie einen Namen („Rattenbeißer“). Zähler pro Item analog zu `Achievements.count`.
- [~] **Ruhmeswand im Haus:** zuerst als Reiter „Ruhm“ im Charakter-Fenster umgesetzt (berühmte Waffen + Meisterstück jeder Art). Offen: echte Wand im Haus mit Trophäen (braucht Grafiken, nach dem 13.11.).
- [x] **Kunden reagieren:** bei R3+ kommt der Kunde Tage später zurück und erzählt, was die Waffe erlebt hat, oder bringt einen Freund mit.

## Paket 5 – Größer, aber stark

- [ ] **Wettbewerb um den Titel** (offene Entscheidung in PROJEKT.md): 2–3 Rivalen, einmal pro Jahreszeit ein Schmiede-Wettstreit beim Fest, Rangliste im Dorf. Langes Ziel, Gegner zum Schlagen und ein mögliches Spielende („Titel gewonnen“).
- [ ] **Meisterschaft statt Wiederholung:** wer ein Teil 10× perfekt geschmiedet hat, darf das Minispiel überspringen (feste Qualität) oder ganze Stapel schmelzen/gießen.

## Außerdem

- Alpha-Tester fragen, **an welcher Stelle** sie aufgehört haben (erste Miete ohne Geld? leerer Tag?). Das sagt mehr als jede allgemeine Regel.
