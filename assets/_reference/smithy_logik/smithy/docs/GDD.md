# Game Design Document – Smithy

*Version 2 (überarbeitet) · Solo-Entwicklung · Godot 4*

> Hinweis: Alles, was als **Vorschlag** markiert ist, stammt nicht aus deinen bisherigen Notizen, sondern ist ein Entwurf zum Prüfen und Anpassen.

## 1. Projektübersicht

|  |  |
| --- | --- |
| **Arbeitstitel** | Smithy |
| **Genre** | Indie, Schmiede-Simulation mit Management-Elementen |
| **Perspektive** | 2D, Pixel Art (Vorschlag: Top-Down) |
| **Plattform** | PC, zunächst Windows |
| **Spielmodus** | Einzelspieler |
| **Entwicklung** | Solo, mit KI-Unterstützung |
| **Engine** | Godot 4.x, GDScript |
| **Zeitbudget** | ca. 10 Stunden pro Woche |

## 2. Spielidee

Du bist ein Schmied in einem Dorf. Du baust deine Schmiede und das Dorf aus, stellst Waffen, Rüstungen und Schmuck her, erfüllst Aufträge und schickst angeheuerte Helden in Dungeons. Die Beute daraus bringt dir Ressourcen und neue Rezepte.

**Kernversprechen:** Das Schmieden selbst soll sich gut anfühlen. Vom Erz über den Barren bis zur fertigen Waffe durchläuft der Spieler einen greifbaren, handwerklichen Prozess mit Minispielen.

## 3. Story-Modus

**Ausgangslage:** Der legendäre Schmied des Dorfes ist verschollen. Das Dorf sucht einen neuen Schmied, viele Schmiede eröffnen deshalb eine Werkstatt und konkurrieren um den Titel.

**Der Spieler:** Er hatte den legendären Schmied als Kind zum Vorbild und wollte immer Schmied werden. Als Jugendlicher hat er hart gearbeitet und Geld gespart, um sich eine Schmiede leisten zu können.

**Einstieg (Tutorial-Handlung):**

1. Der Spieler mietet eine kleine Schmiede am Dorfrand. Die Besitzerin ist eine alte, kauzige Oma. Die erste Miete zahlt er aus seinen Ersparnissen.
2. Um die weitere Miete zu zahlen, braucht er Geld. Er geht in die Dorfmitte und sucht Kunden.
3. Ein Holzfäller sucht jemanden, der ihm eine Axt schmiedet. Alle anderen Schmiede verlangen Geld dafür. Der Spieler hat Mitleid und schmiedet ihm eine Holzaxt umsonst. Zum Dank bekommt er vom Holzfäller **ein Holz pro Tag** (Brennstoff für den Ofen).
4. Ein Betrunkener von der Straße wird der **erste Held**. Der Spieler schmiedet ihm Waffe und Rüstung und schickt ihn in den **ersten Dungeon**.

## 4. Spielablauf

**Programmablauf:**

1. Spiel starten
2. Charakter erstellen (in Version 1 nur minimal: Name)
3. Intro und Tutorial (die Story aus Abschnitt 3)
4. Frei spielen
5. Fortschritt speichern, leveln, Beute sammeln

**Spielschleife (Vorschlag):**

Auftrag oder Kundenwunsch annehmen → Material beschaffen oder einschmelzen → schmieden → abliefern, Geld und Erfahrung erhalten → Miete zahlen, Ausrüstung und Werkstatt verbessern → Helden ausrüsten und in Dungeons schicken → Beute und neue Rezepte → nächster Auftrag

## 5. Spielmechaniken

### 5.1 Schmiedeablauf

**Voraussetzung:** Zum Schmieden braucht man **Rezepte bzw. Gussformen**.

**Standardablauf für einen Gegenstand:**

1. Erz zu Barren einschmelzen
2. Rezept auswählen
3. Form gießen
4. Am Amboss schmieden (Minispiel)
5. Im Wasser abkühlen
6. Am Arbeitstisch zusammenbauen (z. B. Klinge und Griff)

**Erweiterter Ablauf – Legieren (Version 2):** Nach dem Amboss neu erhitzen → in Öl abkühlen → neu erhitzen → im Wasser abkühlen.

**Weitere Handwerksschritte:**

- **Schärfen** von Klingenwaffen (Minispiel)
- **Verzaubern** von Waffen, Rüstungen und Zubehör (Version 2)
- **Aufwerten** von Waffen, Rüstungen und Zubehör (Version 2)

### 5.2 Brennstoff und Ofen

| Brennstoff | Reichweite | Bemerkung |
| --- | --- | --- |
| Holz | 1× schmieden | Startbrennstoff, Holzfäller liefert täglich eins |
| Steinkohle | 5× schmieden |  |
| Feuerorb | 20× schmieden | Mit Magie wieder auffüllbar (Version 2) |

### 5.3 Materialien

**Erze und Barren:** Kupfer, Nickel, Eisen, Silber, Gold, Platin, Palladium. In Version 1 reichen 2–3 davon (Vorschlag: Kupfer, Eisen, Silber).

**Weitere Rohstoffe:** Holz, Steinkohle, Fell (wird zu Leder), Sehnen und Pflanzen (für Bogensehnen).

### 5.4 Waffen und Schadensarten

| Typ | Schadensart |
| --- | --- |
| Speer | Stich |
| Hammer | Blunt (Wucht) |
| Schwert | Schlitz |
| Dolch | Stich/Schlitz (Vorschlag) |
| Bogen | Schaden durch Pfeile: Stich, Schlitz oder Blunt je nach Pfeilart |
| Zauberstab | Magieschaden plus Schaden des Grundelements |

Waffen haben **Grundangriffswerte** je Schadensart.

**Magie-Elemente:** Feuer, Wasser, Erde, Luft, Dunkel, Licht, Blitz, Eis.

**Ausrüstungsarten:** Waffen, Rüstungen, Amulette, Ringe, weiteres Zubehör.

### 5.5 Helden und Dungeons

- **Helden anheuern** in der **Abenteurergilde**.
- Helden haben **Fähigkeiten**, z. B. Schwertschlag, Dolchwurf, Federschuss, Heilen und Elementmagie.
- Der Spieler **schickt Helden in Dungeons**, die von Monstern bewohnt werden. Sie sollen den Dungeon räumen.
- **Belohnung:** Ressourcen und Beute sowie eine Möglichkeit, **Rezepte und Gussformen freizuschalten**.
- Version 1 (Vorschlag): Der Dungeon läuft automatisch ab. Der Spieler rüstet den Helden aus, schickt ihn los und erhält nach einer Zeit das Ergebnis.

### 5.6 Wirtschaft, Aufträge und Fortschritt

- **Aufträge** annehmen (Schmieden auf Bestellung)
- **Handel** mit Waren (Version 2)
- **Miete** muss regelmäßig gezahlt werden (Druck für die Spielschleife)
- **Leveln** durch Schmieden und Aufträge
- **Rezepte** freischalten oder kaufen
- **Ressourcen farmen**
- **Dorf ausbauen** (Version 2)

### 5.7 Werkstatt-Ausbau

- Besserer Hammer, besserer Ofen, besserer Amboss (beeinflussen Qualität und Geschwindigkeit)
- **Zusätzliche Stationen:** Fell → Leder, Sehnenmaterial und Bogensehne aus Pflanzen, weitere Station (noch offen)

## 6. Umfang der Versionen

### Version 1 – Der spielbare Kern

Ein vollständiger Spielabschnitt mit folgendem Inhalt (**Vorschlag**, bitte prüfen):

- Spielfigur, kleines Dorf, Schmiede
- Inventar, Geld, Miete
- Ein vollständiger Schmiedeablauf: Erz → Barren → Waffe, mit einem Schmiede-Minispiel
- Brennstoff: Holz, optional Steinkohle
- Eine überschaubare Anzahl an Waffen, Rüstungen und Zubehör (ca. 5–8 Gegenstände)
- Erste Aufträge (ca. 5–10), Story-Einstieg aus Abschnitt 3
- Ein Held, ein Dungeon (vereinfacht)
- Leveln und Rezepte freischalten
- **Speicherstände** (Speichern und Laden)
- Grundlegende Soundeffekte und einfache Hintergrundmusik

### Version 2 und später (Backlog)

- Legieren, Verzaubern, Aufwerten
- Handel und Dorfausbau
- Feuerorb und Magie-Auffüllen
- Alle Erze, Zauberstäbe, Elementmagie
- Bögen mit verschiedenen Pfeilarten
- Zusätzliche Stationen (Leder, Bogensehnen)
- Mehrere Helden und Dungeons, Heldenfähigkeiten
- Konkurrenz-Schmiede und Titelwettbewerb
- Umfangreicherer Charakter-Editor

## 7. Grafik und Audio

- Einfache, schlichte Pixel-Art-Grafik
- Wenige, gezielt eingesetzte Soundeffekte
- Musik: nur einfache Hintergrundmusik
- **Vorschlag:** In der Entwicklung zuerst Platzhalter-Grafik, dann fertige Asset-Packs (Lizenz prüfen), nur wenn nötig eigene Grafik

## 8. Technische Anforderungen (Vorschlag)

- **Engine:** Godot 4.x (aktuelle stabile Version), Skriptsprache GDScript
- **Zielplattform:** Windows-Export, spätere Plattformen offen
- **Daten:** Gegenstände, Rezepte und Aufträge als Godot-Resources oder JSON, nicht im Code
- **Speichern:** Spielstand als Datei im Nutzerverzeichnis (JSON oder Resource), mehrere Speicherplätze
- **Auflösung:** Pixel-Art mit niedriger Basisauflösung, skaliert auf Bildschirmgröße (genauer Wert noch festlegen)
- **Eingabe:** Tastatur und Maus; Controller später
- **Versionsverwaltung:** Git

## 9. Nicht-Ziele für Version 1

- Kein Online-Multiplayer
- Keine riesige offene Welt
- Kein umfangreicher Charakter-Editor
- Keine komplexen Crafting- oder Wirtschaftssysteme ohne zwingenden Spielzweck

## 10. Erfolgskriterium

Eine andere Person kann das Spiel starten, verstehen und spielen.

## 11. Offene Fragen

- Perspektive: Top-Down oder Seitenansicht?
- Wie läuft der Wettbewerb um den Titel des Schmieds ab? Gibt es Konkurrenten als NPCs, und wann gewinnt man?
- Wie sieht das Schmiede-Minispiel konkret aus (Timing, Rhythmus, Temperatur)?
- Gibt es ein Spielende in Version 1?
- Wie wird die Miete bestraft, wenn sie nicht gezahlt wird?
- Welche dritte Station fehlt noch in der Werkstatt-Liste?
