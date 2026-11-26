# Nacht-Auftrag (gestellt 29.10.2026, 23:37 – Start 30.10. 01:30)

Der Nutzer ist NICHT erreichbar. Keine Fragen stellen, alles nach bestem Wissen entscheiden.
Memory-Regeln beachten (Stil, 4 Richtungen, PixelLab-Doku lesen, max 10 Jobs, agy auslagern, Platzhalter ersetzen, Headless-Tests).

## Aufgaben (Wortlaut sinngemäß)
1. **Spitzhacken + andere Werkzeug-Assets prüfen:** sehen komisch aus, Kopf und Stiel nicht verbunden – Lücke zwischen Spitzhackenkopf und Stiel. Alle betroffenen Assets prüfen und reparieren (pixelart_workbench oder neu generieren).
2. **Alle Monster für die Dungeons erstellen** (echte Grafiken statt Platzhalter).
3. **Kampfanimationen überarbeiten**, dafür gern neue Effekte generieren (vfx_workbench usw.).
4. **Dungeons generell schöner machen:** neue Hintergründe, mehr Platz für Kämpfe – Zuschauen soll ein Erlebnis sein. Dungeons sind fast ein Hauptbestandteil → großer Mehrwert.
5. Schauen, was PixelLab dafür bietet, selbst entscheiden.

### Zusatz, nur wenn danach noch Limit übrig ist (in dieser Reihenfolge)
6. **Rüstungen neu machen:** Jede Stufe soll sichtbar besser und prächtiger aussehen als die vorherige. Kupfer wirkt normal, Eisen schon etwas besser und so weiter. Palladium soll viel „krasser“ aussehen als Kupfer (z. B. mehr Verzierung, Glanz, Kanten, Leuchten). Das gilt für alle Rüstungsteile jeder Stufe.
7. **Holzfäll-Animation erstellen.**

## Fortschritt (laufend aktualisieren!)

**ALLES ERLEDIGT (30.10., ca. 05:30), in `main` gemergt, nicht gepusht.**
- [x] 1 Werkzeug-Assets (Spitzhacken-Köpfe mit Metallhülse, `_reference/items/fix_pickaxe_socket.py`; Axt/Hammer/Speer waren ok)
- [x] 2 Monster (106 Gegner mit eigenem PixelLab-Bild; nur der allgemeine „dragon“ (in keinem Dungeon) wartet noch)
- [x] 3 Kampfanimationen/Effekte (Atmen/Schweben, Schatten, Sprung + Stauchen beim Angriff, Stauchen bei Treffern, Zusammensacken beim Tod, Klauen-Effekt für Tiere)
- [x] 4 Dungeon-Optik/Platz (Bühne 496 statt 366 breit, 40 neue Hintergründe, gespiegelt gekachelt, Abdunklung)
- [x] 6 Rüstungen nach Stufe (42 Teile, `apply_armor.py`)
- [x] 7 Holzfäll-Animation (chop_<kleidung>.png, `bake_chop.py`; Spieler schwingt die Axt am Baum)
- Notizen:
  - Branch `feature/nacht-dungeon`. Kampf-Bild: `py`-frei mit `assets/_reference/battle_v3/shot_battle.gd -- <dungeon> <out.png>` (ohne --headless).
  - Monster: create_image_pro 48x48 (25 Kandidaten, 10 Gen.), Prompt „pixel art game enemy sprite, full body side view profile facing left, …“.
    Download: `py assets/_reference/battle_v3/fetch.py assets/_reference/battle_v3/monsters name=job …` → sheet_<name>.png.
    Auftrags-IDs: `assets/_reference/battle_v3/jobs.txt`, Auswahl: `assets/_reference/battle_v3/picks.json`.
    Im Spiel: frame_size [48,48], scale = alte scale × 0,5, tint weg.
  - Einbauen: `py assets/_reference/battle_v3/apply_monsters.py` (picks.json) und `apply_backgrounds.py` (backgrounds.json, Bilder in backgrounds/).
  - Abholer im Hintergrund: `py -u assets/_reference/battle_v3/daemon.py` (holt alle Aufträge aus jobs.txt).
  - Rüstungen: Test-Auftrag armor_palladium (24x24, alle Teile gemischt, 64 Kandidaten) → armor/; danach je Stufe ein Auftrag, Graustufen per Metall-Rampe umfärben (wie item_icons_v4/process.py).
