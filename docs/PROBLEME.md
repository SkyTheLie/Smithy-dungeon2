# Bekannte Probleme

- Alle Zahlen (Schaden, Leben der Gegner, Preise, Drop-Chancen) sind ein erster Vorschlag, nicht ausbalanciert.
- Gegner laufen geradeaus auf den Spieler zu, ohne Wegfindung; hinter Steinen können sie hängen bleiben.
- Gegner-Bilder sind Seitenansichten aus Smithy (kein Bild von vorne/hinten).
- Die Grafik wurde noch nicht im Spiel angesehen, nur headless getestet. Beim ersten Start auf Größen achten (Gegner, Fackeln, Sockel, Texte auf dem Boden).
- Platzhalter: Feuerball, Gegner-Kugel und Explosion sind im Code gezeichnete Kreise (`Fx`). Bombe = Smithy-Icon „Rauchbombe“, Herz = Arena-Herz, Item-Raum-Symbol = Truhe.
- Kein Gamepad.
- Beute: „Flughaut“ (Fledermaus) nutzt das Leder-Bild aus Smithy, es gibt kein Bild eines Fledermausflügels.
- Die Dose hat noch keinen Bildschirm (Einzahlen/Abheben gibt es nur im Code und im Test). Mitgebrachte Beute (`stash`) kann man noch nicht verkaufen. Beides kommt mit dem Laden.
- Wer einen Run über Pause → Hauptmenü verlässt, verliert die mitgenommene Geldbörse (wie beim Tod).
- Das Repository hat gemischte Zeilenenden (LF/CRLF, von Dungeon Smithy geerbt). Geänderte Dateien behalten ihre Zeilenenden; eine `.gitattributes` zum Vereinheitlichen wäre ein eigener Schritt.
- Waffen: Feuerlanze (Strahl) und Pulverhandschuh (Bomben) verdrängen noch die Hauptwaffe (z. B. das Schwert des Kriegers), weil der Modus Strahl > Bombe > Nahkampf > Feuer gilt. Abhilfe: weitere Waffen-Kreuzungen wie der Feuerhieb, Vorschläge in `docs/SYNERGIEN.md`. Die Kriegsaxt hat in der Hand nur das Bild des Axtkopfs.

## Ideen (Backlog)

Synergie-Lücken und Waffen-Kreuzungen: `docs/SYNERGIEN.md`. Weitere Themen, aktive Items mit Aufladung, Truhen, Champion-Gegner, eigene Musik, Bodenfeuer, Gift-/Feuerbomben, schwarze Herzen, Übungsgegner im Testraum. Aus dem Guide noch offen: Tages-Run (fester Seed pro Tag), Herausforderungen, schwerer Modus, Ehrenrunde (neuer Run mit einem Teil der Items), Zeit-Räume (z. B. Boss-Ansturm, wenn eine Ebene schnell geschafft wird). Ausführliche Liste: `docs/ITEM_IDEEN.md`.

Bekannt: Werte sind noch nicht ausbalanciert (203 Items, 6 Ebenen, Bosse). Krieger-Freischaltung (Ebene 3) ist ein Vorschlag. Die Waffe in der Hand ist ein Item-Bild ohne Animation außer dem Schwung. Gegner-Laute sind einfache Synth-Töne. Blaue Herzen gibt es nur über Items und Schrein/Opferstein, nicht als Pickup am Boden. Doppel-/Mehrfachschuss: bei gerader Schusszahl fliegt kein Schuss genau zum Fadenkreuz (Fächer 7° je Schuss). Zufallseffekte (`chance`) wirken nicht beim Strahl.
