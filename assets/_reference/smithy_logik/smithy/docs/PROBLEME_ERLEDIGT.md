# Erledigte Probleme

> Archiv: Einträge aus `docs/PROBLEME.md`, die erledigt oder durch spätere Änderungen überholt sind. Nur zum Nachschlagen, wird nicht gepflegt. Neue Probleme gehören nach `PROBLEME.md`; wird dort etwas erledigt, hier unten anhängen (mit Datum und Nachweis).

## Aufgeräumt am 2026-11-10

Geprüft gegen Code, `data/content/*.json`, `locale/en.po` und die Test-Anleitungen in `PROJEKT.md` Abschnitt 8.

| Altes Problem | Erledigt durch |
|---|---|
| Max-Mana wächst nur über Intelligenz | `combat.json` `mana_per_level: 1` (+1 Max-Mana pro Level, 2026-11-05) |
| Sockel: nur 8 Beispiel-Boni, feste 35 % | 29 Boni in `sockets.json`, Skill Meisterwerk (45/55/65 %), Funkentrank würfelt Sockel neu (2026-11-08) |
| Juweliertisch: Amulettfassungen nur aus Silber, Icons immer mit Silberfassung | Gold-, Platin-, Palladium-Amulette, Ring und Amulett in Metallfarbe (2026-11-08) |
| Zauberstäbe aus anderen Metallen als Eisen fehlen | Zauberstäbe aller Metalle |
| Bronze- bis Palladium-Teile für Bögen fehlen | `*_bow_frame` für alle Metalle (2026-10-26) |
| Spitzhacken nur aus Kupfer und Eisen | Spitzhackenköpfe aus allen 7 Metallen |
| Platin-/Palladium-Gussformen nirgends, Silber- bis Palladiumerz fehlt | Alle Erze im Spiel (Erz-Stufen), Platin-Gussformen ab Teil 6 bei Quentin |
| Erfolge: Sets aus Bronze bis Palladium nicht schaffbar | Rüstungs-Gussformen aller Metalle einzeln bei Quentin/Krummfinger |
| Kundenaufträge bestellen nur Waffen und Schilde | Aufträge mit Rüstung, Bogen und Stab (2026-11-04) |
| Voller Köcher verkauft = Pfeile weg | `shop_dialog.gd` `_empty_quiver` legt die Pfeile ins Inventar (2026-10-31) |
| Rezeptbuch listet Eisen-Zauberstäbe einzeln | Zauberstab-Rezepte zusammengefasst (2026-11-05) |
| Beschwörungen ohne eigene Lauf-/Angriffs-Animationen | Beschwörungs-Animationen (2026-11-04) |
| Tränke für Skill-/Attributpunkte und Zurücksetzen ohne Fundort | Rezepte in `mortar.json`, Belohnungen in `leagues.json` |
| Pflanztöpfe: nur eine Erde (Gartenerde) | Waldhumus und Mondhumus beim Verzauberer (2026-11-05) |
| Keine Samen außer der Mondlilie | Sonnenblumen- und Nachtschatten-Samen |
| Feder und Kamille ohne Verwendung | Feder für Pfeile, Kamille für Sternentau und Trank des Wandels |
| Teleporter nur vor der Schmiede und in Leonheim | Weltkarte mit Teleportern in vielen Gebieten (2026-10-28) |
| Lavaberg: Felswände nur eine Kachel hoch, Höhleneingang klein | Höhere Felswände, größere Eingänge (2026-10-31) |
| Goblinminen: neue Steine wachsen nur als Gold und Silber | Erz-Reihenfolge: Kupfer und Eisen, Palladium erst ab `reached_finster_start` |
| Goldbarren ab R3 für die Goblinkrone | Krone aus Bronze (Erz-Reihenfolge, 2026-11-03) |
| Drache mit Gold R3 auf L36 sehr schwer | Vulkan auf Bronze eingestellt, alte Zahlen gelten nicht mehr |
| Bronze-Nebenaufgabe: Bronze-Gussformen gesperrt | Krummfinger verkauft sie |
| Heiliger Zorn und Frostfessel in `skills.json`, zu keiner Klasse | Entfernt; Strafgericht gehört wieder zu einem Skillbaum |
| Gosse: Kerker nur Text, Karte der heiligen Steine, Schatzkammer, Morwald fehlen, Aurelius verschwindet einfach | Kerker mit Zellen (2026-11-03), Kristallkarte, Morwald in `dungeons.json`, Figuren gehen zu Fuß weg (2026-11-03) |
| Lotte steht nach „Lotte schaut zu“ sofort in der Werkstatt | Sie läuft hin (2026-11-04) |
| Schmiedegasse ohne eigene Häuser | Häuser und Zelte (Karten-Runde 2026-10-31) |
| Übersetzungen fehlen (Spielende, Lotte, Sahrim, Schleich-Labyrinthe) | In `locale/en.po` vorhanden (bis auf einen Hadmar-Text) |
| Aufwertungstisch: Kristalle nur als R1 | R2-Kristalle beim Verzauberer |

## Teilweise erledigt (Rest steht weiter in PROBLEME.md)

- Heilige Kristalle: die Spitze von Sylvaris zeigt jetzt den animierten Windkristall (2026-11-04); Sturmtempel, Eismauer und Altar haben noch eigene Bilder.
- Goblinhöhle: der Goblin hat eigene Animationen (2026-11-06), die anderen neuen Monster nicht.
- Absturz bei der Flucht aus der Finsterburg: vermutlich mit dem Fix „global_position on previously freed“ im Thronsaal (2026-11-08) behoben, im Spiel noch nicht bestätigt.

## Doppelte Einträge entfernt

Diese Einträge standen zweimal in `PROBLEME.md`; behalten wurde je eine Fassung: Absturz Finsterburg, Goldenes Leuchten, Sahrim, Schleich-Labyrinthe, Spielende, Beinschutz, Ruf, Geräte und Möbel, Seltenheit und Qualität, Bögen und Pfeile, Skillbäume, Gosse, Ringe und Edelmetalle, Juweliertisch, Sturmgipfel, Aufwertungstisch und Köcher, Geräusche, Seltenheits-Glocke, Goblins in der Tiefe, Aufwertungstisch ausgebaut, `test_chapter_skip.gd`, Schmiedegasse (Ritter Edmund), Erfolge.
- 2026-11-10 – Heldenfenster: „Mehr anzeigen“ fehlte (Nutzer-Meldung): die Werte-Spalte war 28 px höher als die Seite (192 px), EXP-Balken und Knopf wurden abgeschnitten. Knopf jetzt in der Reiterzeile neben Ausrüstung/Fähigkeiten, Seite 200 px. Test `assets/_reference/hero_more_button/test_more_button_visible.gd`.
