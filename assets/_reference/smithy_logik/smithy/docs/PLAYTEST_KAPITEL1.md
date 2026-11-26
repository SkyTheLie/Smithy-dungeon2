# Testbericht Kapitel 1: „Eine eigene Schmiede“

Gespielt am 2026-11-15 von Claude, Sprache Deutsch, neuer Spielstand, Standardname, Aussehen „Zufällig“.
Der Bot spielt vom Hauptmenü an mit echten Tasten (Laufen mit WASD-Aktionen, E, Knöpfe im Dialog).
Er hat einen eigenen leeren Speicherordner, echte Spielstände bleiben unberührt.
Bot: `assets/_reference/playtest/sim_play_chapter1.gd`. Bilder und Protokoll liegen in `assets/_reference/playtest/kapitel1/`.

**Ergebnis:** Kapitel 1 lässt sich ohne Fehler durchspielen. Am Ende steht der Schritt auf `find_customer`, der Spieler hat 500 Gold, und es ist Tag 1, 10:29. Das Spiel-Log zeigt keine Skriptfehler.

## Übersicht

| # | Kriterium | Ergebnis |
|---|---|---|
| 1 | Grinden | Keins. 800 Gold Start, Miete 300, Kapitel dauert ca. 4 Spielstunden (06:42–10:29). |
| 2 | Unschlüssig | Schmiede „seit Jahren leer“, aber Feuer brennt (A1) |
| 3 | Gesagt, nicht animiert | Schlüsselübergabe, Klopfen (A2) |
| 4 | Komisch | Name „Schmied“ (B1), Hilde begrüßt dich zweimal gleich (B2) |
| 5 | Bugs | Keine Abstürze oder Skriptfehler. Miete-Tipp geht mitten im Gespräch auf (A3) |
| 6 | Sackgassen | Keine. Gesperrte Ausgänge erklären, warum (Markt, Dorftor, Wohnviertel, Schmiedetür) |
| 7 | Lernkurve | 6 Tipps am Anfang, 4 lange Stations-Tipps beim Spinnweben-Putzen (A4) |
| 8 | Wirtschaft | Nichts zu bewerten, nur Miete |
| 10 | Übersetzung | Untertitel im Titelbild englisch (C2) |
| 11 | Speichern und Laden | Nicht getestet |
| 12 | Platzhalter | Keine gesehen |

## A. Wichtig

**A1 · Die „leere“ Schmiede brennt schon.** Der Spieler sagt bei der Ankunft „Kalte Esse, verstaubter Amboss“. Hilde sagt „steht seit Jahren leer“ und „mach erst mal sauber, bevor du da drin Feuer machst“. Trotzdem raucht draußen der Schornstein, das Fenster leuchtet (`31_after_sign.png`), und drinnen glüht der Gussofen schon (`48_smithy_inside.png`).
Vorschlag: Rauch, Fensterlicht und Ofenglut erst ab `smithy_rented` zeigen, oder besser erst, wenn die Spinnweben weg sind.

**A2 · Gesagt, aber nicht gezeigt.**
- „Abgemacht! Hier ist der Schlüssel.“ (`landlady_rented`): Es gibt keine Übergabe, Hilde steht nur da. Das widerspricht Regel 50 in FEHLERKLASSEN. Eine kurze `give`-Geste von Hilde an den Spieler würde reichen.
- „Na, wer klopft denn da?“ (`landlady_offer`): Der Spieler läuft einfach durch die Tür ins Haus, niemand klopft. Entweder ein Klopf-Geräusch beim Betreten, oder den Text ändern („Na, wer kommt denn da herein?“).

**A3 · Miete-Tipp öffnet sich mitten im Gespräch.** Nach „Mieten“ startet der Schritt `clean_smithy` und bringt den Tipp „Miete“ mit. Hilde redet in dem Moment noch zwei Zeilen weiter. Der Tipp liegt hinter dem Dialogfenster, gleichzeitig kommt die Meldung „Erfolg: Ein eigenes Dach“ (`42_hilde_rent_tip.png`). Drei Dinge gleichzeitig. Besser: Tipps zurückhalten, solange ein Dialog offen ist.

**A4 · Zu viele Tipps auf einmal, und zu früh.**
- Direkt nach der Ankunft kommen 4 Tipps nacheinander: Steuerung, Aufgaben, Alles nachlesen, Speichern.
- Beim Spinnweben-Putzen kommt an jeder Station ein langer Tipp: Gussofen, Schmelze, Werkbank, Amboss. Der Werkbank-Tipp hat 7 Zeilen und erklärt sogar schon das Nieten von Rüstung (`54_web_CobwebWorkbench_tip.png`). Der Amboss-Tipp spricht von Seltenheit und schweren Metallen.
- Problem: Der Spieler hat noch kein Erz, kein Rezept und kein Holz. Er klickt die Tipps weg, und da jeder Tipp nur einmal kommt, sieht er ihn in Kapitel 2 beim ersten echten Schmieden nicht mehr.
- Vorschlag: Stations-Tipps erst bei der ersten echten Benutzung zeigen (die Lehrgänge mit goldenem Leuchten gibt es ja schon). Beim Putzen reicht ein Satz, z. B. „Sauber! Das ist die Schmelze, hier werden aus Erz Barren.“

## B. Komisch

**B1 · Standardname „Schmied“.** Wer keinen Namen eintippt, liest im Intro „Du, Schmied, hast den legendären Schmied als Kind bewundert. Seitdem wolltest du nur eines: selbst Schmied werden.“ (`08_intro_page4.png`). Bei Hilde sagt er dann „Ich bin Schmied.“ Vorschlag: einen echten Vornamen als Standard nehmen, oder das Namensfeld leer lassen und ohne Namen nicht weitergehen.

**B2 · Zweimal die gleiche Begrüßung.** Wer bei Hilde „Ich überlege es mir noch“ wählt und sie gleich wieder anspricht, bekommt das ganze Gespräch neu: „Na, wer klopft denn da? Ein junges Gesicht, das sieht man hier selten.“ Und das, obwohl er gerade erst vor ihr stand. Vorschlag: ein kurzer zweiter Dialog („Na, doch entschieden? 300 Gold alle zwei Wochen.“) mit denselben Knöpfen.

**B3 · Figur unter der Leiste.** Beim Betreten des Wohnviertels steht die Figur am unteren Rand halb hinter der Schnellleiste (`32_residential.png`). Sie ist kurz kaum zu sehen.

## C. Kleinkram

- **C1** STORY.md nennt die vierte Station „Esse“, im Spiel heißt sie „Gussofen“. Das betrifft nur die Doku.
- **C2** Titelbild: „Crystal of the Nine“ bleibt im deutschen Spiel englisch, darunter steht deutsch „Hier klicken oder Leertaste“ (`02_main_menu.png`). Falls das Absicht ist (Logo), ist es okay.
- **C3** Beim Betreten der Schmiede war die Spinnwebe am Gussofen schon weg (1/4), bevor der Bot dort E gedrückt hat. Wahrscheinlich hat der E-Druck des Bots an der Tür sie mitgenommen. Unsicher, bitte einmal von Hand prüfen.

## Was gut war

- Ankunfts-Szene, Sprechblase und Tracker-Ziele sind klar. Das Ziel ist immer oben rechts zu sehen.
- Jeder gesperrte Weg sagt, warum: „Zum Markt gehst du später. Erst brauchst du eine Schmiede.“ (`20_try_ExitEast.png`), „Abgeschlossen. Am Schild steht, wer die Schmiede vermietet.“
- Die Spinnweben leuchten golden, man findet sie sofort.
- Der Erfolg „Ein eigenes Dach“ ist ein netter Moment.

## Nicht getestet

Speichern und Laden mitten im Kapitel, Geräusche und Musik, das Gefühl der Steuerung, Englisch und die anderen Sprachen.
