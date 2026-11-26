# Steam – Erfolge

Das Spiel meldet seine Erfolge an Steam, sobald das GodotSteam-Plugin im Projekt ist und es in `data/content/achievements.json` eingeschaltet wird. Ohne Plugin (oder ausgeschaltet) läuft alles wie bisher, nichts muss entfernt werden.

## Wie es funktioniert

- Die Erfolge selbst stehen wie bisher in `data/content/achievements.json` (`Achievements`, Reiter „Erfolge“ im Charakter-Fenster).
- **Jede Stufe ist bei Steam ein eigener Erfolg.** „Rattenjäger“ mit 5 Stufen wird zu `ACH_RAT_HUNTER_1` bis `ACH_RAT_HUNTER_5`, ein Erfolg mit einer Stufe zu `ACH_STORY_RENTED`. Ergibt zurzeit 87 Steam-Erfolge.
- `SteamBridge` (`scripts/core/steam_bridge.gd`, Kind von `GameState`) schickt jede erreichte Stufe an Steam (`setAchievement` + `storeStats`). Nach dem Laden eines Spielstands schickt sie alle erreichten Stufen noch einmal, damit auch ohne Steam Erreichtes ankommt.
- Optional zeigt eine Steam-Statistik den Fortschritt eines Zähler-Erfolgs (`steam_stat`, z. B. „Ratten besiegt“). Statistiken werden höchstens alle 5 Sekunden hochgeladen.

## Einstellungen in achievements.json

```json
"steam": {
	"enabled": false,
	"app_id": 480,
	"name_pattern": "ACH_{ID}_{LEVEL}",
	"single_pattern": "ACH_{ID}"
}
```

- `enabled`: `true` = an Steam melden.
- `app_id`: 480 ist Steams Testspiel „Spacewar“ (zum Ausprobieren). Später die eigene App-ID von Steamworks eintragen.
- `name_pattern` / `single_pattern`: So heißen die Erfolge bei Steam. `{ID}` = `steam_id` oder die id in Großbuchstaben, `{LEVEL}` = Stufe.

Pro Erfolg (alle optional):

| Feld | Bedeutung |
|---|---|
| `steam_id` | Name bei Steam statt der id, z. B. `"RAT_HUNTER"` |
| `steam` | `false` = dieser Erfolg kommt nicht zu Steam |
| `steam_stat` | Name einer Steam-Statistik für den Fortschritt, z. B. `"STAT_RATS"` |

**Wichtig:** Sobald die Erfolge bei Steam angelegt sind, dürfen sich die API-Namen nicht mehr ändern (id, `steam_id`, Muster und Anzahl der Stufen). Will man eine id im Spiel umbenennen, die alte als `steam_id` eintragen. Neue Stufen hinten anhängen geht (dann bei Steam den neuen Erfolg anlegen).

## Schritte bis zu Steam

1. **Liste und Icons erzeugen:** `python assets/_reference/steam/make_steam_list.py` (aus dem Projektordner). Ergebnis in `assets/_reference/steam/`: `steam_achievements.csv` (API-Name, Anzeigename, Beschreibung, versteckt, Statistik) und `icons/` mit je einem farbigen und einem grauen Icon (256×256 JPG) pro Steam-Erfolg. Die Icons sind die hochskalierten Bilder aus dem Spiel; bessere Icons einfach mit gleichem Dateinamen ersetzen.
2. **Steamworks:** Auf partner.steamgames.com unter „Stats & Achievements“ jeden Erfolg aus der CSV anlegen (API-Name, Name, Beschreibung, „Hidden“ bei versteckten, beide Icons). Optional die Statistiken (`steam_stat`, Typ INT). Danach „Publish“.
3. **GodotSteam einbauen:** Im Godot-Editor in der AssetLib „GodotSteam GDExtension“ (passend zu Godot 4.x) installieren; das legt `addons/godotsteam/` an. Keine Code-Änderung nötig, `SteamBridge` findet den Singleton `Steam` selbst.
4. **Testen:** Steam-Client starten und angemeldet sein. Im Projektordner eine Datei `steam_appid.txt` mit der App-ID (zum Test `480`) anlegen (nicht committen). In `achievements.json` `"enabled": true` setzen und das Spiel starten. Mit 480 sieht man die Erfolge nicht im Overlay (Spacewar kennt unsere Namen nicht), die echte App-ID braucht die angelegten Erfolge aus Schritt 2. Erfolge zurücksetzen geht in GodotSteam mit `Steam.resetAllStats(true)`.
5. **Export:** `steam_appid.txt` gehört nicht ins fertige Spiel (Steam startet es selbst mit der richtigen ID). Die DLLs von GodotSteam kommen beim Export automatisch mit.

## Bekannte Grenzen

- Erfolge, die im Spiel wieder auf 0 fallen (neuer Spielstand), bleiben bei Steam erreicht – so ist Steam gedacht.
- Spielstand-übergreifend zählt nichts: jeder Spielstand hat eigene Zähler, Steam merkt sich nur das jeweils Beste.
- Andere Steam-Funktionen (Cloud-Speicher, Overlay-Pause, Rich Presence) gibt es noch nicht.
