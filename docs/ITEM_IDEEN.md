# Item-Ideen (noch nicht gebaut)

Gesammelt aus Ideen-Listen, die wir uns angeschaut haben. Hier stehen nur **Mechaniken**: Namen, Bilder und Zahlen denken wir uns selbst aus, damit Dungeon Smithy kein Nachbau eines anderen Spiels wird.

**Aufwand:**
- **klein:** ein paar Zeilen Code, meist ein neues Flag
- **mittel:** neue Funktion oder neuer Teil in Schuss, Gegner oder Raum
- **groß:** ein ganz neues System

Was es schon gibt, steht unten unter „Schon gebaut“.

## Schuss-Effekte

| Idee | Was passiert | Aufwand | Anmerkung |
|---|---|---|---|
| Gift | Getroffene Gegner verlieren eine Weile Leben (grün) | klein | wie `burn`, eigene Farbe und Werte |
| Einfrieren | Getroffener Gegner bleibt kurz stehen | klein | wie `slow`, nur mit Tempo 0 |
| Furcht | Getroffene Gegner laufen weg | klein | gibt es schon beim Brot (`bread`), als eigenes Flag |
| Verwirrung | Getroffene Gegner laufen zufällig herum | klein | neuer KI-Zustand in `Enemy` |
| Effekt mit Chance | Effekte wirken nur bei x % der Schüsse | mittel | Grundlage für viele Ideen hier (z. B. „20 % Gift“) |
| Durch Steine | Schüsse fliegen durch Steine, nicht durch Wände | klein | Steine-Ebene beim Strahl weglassen |
| Schuss nach hinten | Manchmal fliegt ein Schuss zusätzlich nach hinten | klein | in `Weapon._fire` |
| Kreuzschuss | Manchmal Schüsse in alle 4 Richtungen | klein | in `Weapon._fire` |
| Schrumpfender Riesenschuss | Startet riesig und stark, wird im Flug kleiner und schwächer | klein | Gegenteil von `grow` |
| Platzen am Ende | Am Ende der Reichweite zerfällt der Schuss in 4 kleine | klein | wie `split`, aber bei `_end` |
| Weiterfliegen nach Kill | Tötet der Schuss, fliegt er mit dem restlichen Schaden weiter | klein | in `Projectile._on_enemy` |
| Linke/rechte Hand | Jeder zweite Schuss macht mehr Schaden | klein | Zähler in `Weapon` |
| Schweben bis loslassen | Schüsse bleiben in der Luft stehen, beim Loslassen fliegen alle los | mittel | |
| Kreisende Schüsse | Schüsse kreisen um den Spieler, bis sie fallen | mittel | |
| Ein gelenkter Feuerball | Ein einziger Feuerball folgt dem Fadenkreuz und brennt dauernd | mittel | neuer `mode` |
| Gelegentlicher Strahl | Ab und zu feuert neben den Feuerbällen ein Strahl mit | mittel | |
| Feuer am Boden | Schüsse hinterlassen kurz brennende Flecken | mittel | neues Objekt „Bodenfeuer“ |
| Magnetschuss | Schüsse ziehen Gegner und Pickups an | mittel | |
| Zufallseffekt | Alle paar Sekunden oder pro Raum ein anderer Schuss-Effekt | mittel | |
| Lenkrakete / Luftschlag | Zielmarke statt Schuss, Einschlag von oben | groß | neuer `mode` |
| Nahkampfwaffe | Eine Klinge statt Feuerbällen, Aufladen macht sie weiter | groß | neuer `mode` |

## Bomben

| Idee | Was passiert | Aufwand | Anmerkung |
|---|---|---|---|
| Größere Bomben | Mehr Radius und Schaden | klein | neuer Wert, z. B. `bomb_size` |
| Feuerring | Die Bombe schießt beim Explodieren Feuerbälle ringsum | klein | `spawn_projectile` in `PlacedBomb` |
| Explosionen heilen | Eigene Explosionen heilen statt zu schaden | klein | baut auf `blast_proof` auf |
| Feuerbombe | Hinterlässt brennenden Boden | mittel | braucht „Bodenfeuer“ (siehe oben) |
| Giftbombe | Giftwolke nach der Explosion | mittel | braucht Gift |
| Zielsuchende gelegte Bomben | Gelegte Bomben (E) rollen zum Gegner | mittel | bei geworfenen Bomben gibt es das schon |
| Doppelbomben | Bomben-Pickups zählen doppelt | klein | in `Pickup` |

## Begleiter (neues System)

Es gibt noch keine Begleiter. Einmal gebaut, ergeben sie viele Items über Daten (`data/familiars.json`).

| Idee | Was passiert | Aufwand |
|---|---|---|
| Schießender Begleiter | Fliegt mit und schießt in Blickrichtung | groß (Grundsystem) |
| Jäger | Jagt Gegner und beißt sie | mittel (wenn das System steht) |
| Sammler | Lässt alle paar Räume ein Herz, eine Münze, Bombe oder einen Schlüssel fallen | mittel |
| Beschützer | Kreist und blockt Gegner-Schüsse | klein (Glutmond gibt es schon) |
| Kleine Helfer | Bei Treffern oder Kills entstehen kurz kleine Kampf-Funken | mittel |
| Kugel an der Kette | Wird hinterhergezogen, trifft Gegner, zerbricht Steine | mittel |
| Begleiter-Verstärker | Alle Begleiter werden größer und stärker | klein |

## Leben und Verteidigung

| Idee | Was passiert | Aufwand | Anmerkung |
|---|---|---|---|
| Schadensgrenze | Kein Treffer nimmt mehr als ein halbes Herz | klein | in `RunState.take_damage` |
| Chance zu blocken | x % der Treffer gehen daneben | klein | |
| Schild nach Treffer | Nach einem Treffer einige Sekunden unverwundbar | klein | |
| Letzte Rettung | Beim letzten halben Herz: Schaden an allen Gegnern oder ein Schild | klein | |
| Dornen | Gegner, die dich berühren, nehmen Schaden | klein | |
| Stillstehen | Wer still steht und nicht schießt, ist unverwundbar | klein | |
| Regeneration | Langsam ein halbes Herz zurück | klein | |
| Heilung durch Kills | Alle x Kills ein halbes Herz | klein | |
| Doppelte Heilung | Herzen am Boden heilen doppelt | klein | |
| Wut | Stärker mit wenig Leben, oder Schaden steigt nach jedem Treffer | klein | |
| Kleiner werden | Kleinere Trefferfläche | klein | `Player.RADIUS` als Wert |
| Steine zertreten | Laufen zerbricht Steine | klein | |
| Rammen | Schnell gegen Gegner laufen macht Schaden | mittel | |
| Schwung | Tempo wächst im Kampf | mittel | |
| Zweites Leben | Nach dem Tod im vorigen Raum mit vollem Leben weiter | mittel | |
| Schwarze Herzen | Wie blaue, beim Verlust trifft eine Welle alle Gegner | mittel | baut auf blauen Herzen auf |
| Fliegen | Über Steine schweben | mittel | Gegner und Schüsse müssen das beachten |

## Geld, Karte, Räume

| Idee | Was passiert | Aufwand | Anmerkung |
|---|---|---|---|
| Rabatt | Shop-Preise halb | klein | in `Dungeon._build_shop` |
| Magnet | Pickups fliegen zum Spieler | klein | in `Pickup` |
| Zwei Boss-Items | Zwei zur Wahl, das andere verschwindet | klein | |
| Pech-Münzen | Bei Treffern fallen Münzen heraus | klein | |
| Vorratskiste | Ein Item, das mehrere Pickups auf den Boden wirft | klein | wie `give`, nur als Pickups |
| Goldene Gegner | Berührte Gegner werden kurz zu Gold und geben beim Tod Münzen | mittel | |
| Karte aufdecken | Spezialräume oder ganze Ebene auf der Karte | klein | Die große Karte zeigt **jetzt schon alles**. Zuerst müsste man unbekannte Räume verstecken. |
| Mehr Belohnungen | Geräumte Räume geben öfter etwas | klein | `room_drops` |

## Ganz neue Systeme (Backlog)

Diese Ideen brauchen erst ein eigenes System, dann sind viele Items nur noch Daten:
- **Aktive Items** mit Aufladung durch geräumte Räume, und Items, die die Aufladung beschleunigen
- **Truhen** (normal, verschlossen), Items für bessere Truhen
- **Geheimräume** (Bombe an die Wand) und Items, die sie zeigen. Erst dann bekommen `secret`-Items einen Sinn.
- **Verbrauchsgegenstände** (Karten, Tränke) und Items, die mehr davon tragen lassen
- **Flüche** pro Ebene und Items dagegen
- **Besondere Räume** nach dem Boss (Handel: Herzen gegen Items)
- **Chaos-Items:** alle Items neu würfeln, Werte angleichen, Werte zufällig hoch und runter

## Schon gebaut (zum Abhaken)

Schneller schießen, Schaden, Reichweite, Schusstempo, Laufen, Größe, Rückstoß · Doppel-, Dreifach-, Schrotschuss · Zielsuche · Durchschlag · Abprallen · Bumerang · Wellen · Splitter beim Treffer · Explosive Schüsse · Strahl · Aufladen · Bomben werfen (auch zielsuchend und als Streubomben) · Glutmond (kreist, blockt Schüsse) · Brennen · Verlangsamen · Schaden je Flugweite · Schaden je Münze · Schüsse zerstören Gegner-Schüsse · Explosionen schaden nicht · ein Treffer pro Raum wird abgefangen · Herz-Container · blaue Herzen · ganz heilen · Münzen, Bomben, Schlüssel beim Aufheben · Brot (Gegner fliehen) · Freischaltungen · Lexikon
