# Audio

> Teil von `docs/SYSTEME.md` (dort das Inhaltsverzeichnis). Der Text der Einträge stammt unverändert aus der früheren einen Datei.
> Neue Einträge: oben unter „Abschnitte“ als eigener Abschnitt `## Name (Datum, Branch)`; gilt etwas nicht mehr, den alten Eintrag ändern statt einen zweiten zu schreiben.

**Zweck:** Geräusche, Musik, Lautstärke-Regler, Stimmen der Völker.

**Meistgenannte Dateien:** `scripts/systems/voice.gd`

**Daten:** `audio.json`, `story.json`

**Genannte Tests:** `assets/_reference/story_umbau/test_voice.gd` (alle über `bash assets/_reference/run_tests.sh`)

**Fallen:** bekannte Probleme stehen in `docs/PROBLEME.md` (nach dem System-Namen suchen), wiederkehrende Fehler in `docs/FEHLERKLASSEN.md`.

## Kurzfassung

- **Musik und Sounds:** `AudioManager` (Autoload) + `data/content/audio.json` (alle Pfade zum Austauschen): Hintergrundmusik (Stück oder Playlist im Wechsel, pro Szene wählbar `scene_music`, nach Story-Flags `flag_music`; Dorf: drei Stücke im Wechsel, Wald `forest_01.wav`, Mine `mine_02.wav`, Vulkan und Goblin-Karten `volcano_01.wav`, Leonheim `city_01.wav`, Schloss `palace_01.wav`, Überfall `scarry_psycho_moment.wav`), Amboss-Treffer, Skills, Level-Up (Platzhalter). Level-Up lässt die Figur golden aufleuchten (`LevelUpGlow`). Einstellungen: Musik/Geräusche 0–100 % und an/aus (`AudioSettings`, `user://settings.cfg`).

# Abschnitte (neueste oben, wie sie entstanden sind)

## Völker sprechen verschieden (2026-10-28, Branch `feature/rassen-sprache`)

- **Regeln pro Volk:** `docs/DIALOGE.md`, Abschnitt „Völker – wie sie sprechen“ (Echsen zischen, Goblins chaotisch und gierig, Elfen gehoben, Wasservolk knapp, Halbdämonen trocken-spöttisch).
- **`Voice`** (`scripts/systems/voice.gd`): verändert den fertigen, übersetzten Text nach der Sprechart. `"hiss"`: S am Wortanfang und jedes ss/ß wird zu drei s („Sand“ » „Sssand“, „muss“ » „musss“); von Hand verlängerte S und Namen wie „Ssiva“ zählen einmal, zweimal anwenden ändert nichts. Gilt für jede Sprache.
- **Wo:** `DialogueBox` (Sprechart der Figur aus story.json `npcs.<id>.voice`, `Story.get_npc_voice`) und Händler-Begrüßungen (`Merchant.voice`). Zischen: alle Echsen (Ssarok, Ishra, Brakk, Kesh, Mira, Zahir, Echsenwachen, Muhme Grisla) und die Händler Ssiva und Tuk in Sahrim.
- **Goblins:** 18 Zeilen von Goldzahn, seinen Wachen, dem Aufseher, der Menge und dem dünnen Goblin neu geschrieben (`assets/_reference/story_umbau/patch_goblins.py`). Test: `assets/_reference/story_umbau/test_voice.gd`.
