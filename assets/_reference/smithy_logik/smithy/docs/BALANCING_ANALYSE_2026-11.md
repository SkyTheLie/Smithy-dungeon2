# Balancing-Analyse 2026-11 (Teil 1: messen und berichten)

Stand: 2026-11-15, Branch `feature/balancing-analyse` (von `main` 46cc3fc52). An Spieldaten und Code wurde nichts geändert. Neu sind nur zwei Simulatoren und dieser Bericht.

## 0. Wie gemessen wurde

| Skript | Was es misst | Läufe für diesen Bericht |
|---|---|---|
| `balancing/sim_party.gd` (vorhanden) | Siegquote je Dungeon: Krieger + Priester + Magier mit Stufen-Erz R1, Erz davor R1 und R2, dazu Paladin + Waldläufer + Schurke | 3 Durchgänge × 40 Läufe = 120 Kämpfe je Zelle; `tune` 40 Läufe je Faktor |
| `balancing/sim_progress.gd` (vorhanden) | Spieltag, Heldenlevel, Spieler-Level, Dungeon-Kosten je Story-Teil | Szenario `trio`, R1, Seeds 1, 2, 3 |
| `balancing/sim_duels.gd` (vorhanden) | 18 Bäume 1 gegen 1 (Lv 50, Gold R1) | 4 Kämpfe je Paarung, nur Ausgabe (duels.md nicht überschrieben) |
| `balancing/sim_balance.gd` (**neu**) | Gruppen mit und ohne Heiler, alle 18 Bäume als dritter Held, Beschwörer, Werte-Tabellen; Varianten nur im Speicher (Monster stärker/schwächer, Beschwörungs-Werte, Verschnaufpause, Tränke, Ringe) | Heiler: Seeds 1–3 × 30 Läufe = 90 Kämpfe je Zelle; Bäume: Seeds 1–2 × 30 = 60; Varianten: Seeds 1–2 × 20 = 40 (wenn nicht anders angegeben) |
| `balancing/sim_forge_quality.gd` (**neu**) | Seltenheit von Waffe und Rüstung bei gleichem Spielerstand, mit den echten Regeln (`ForgeQuality`, `Crafting.roll_mixed_rarity`) | 2000 Stücke je Zelle (Seed 1, Gegenprobe Seed 2: Abweichung höchstens 0,03 Stufen); „Schwierig“ und „Sehr schwer“ je 1000 |

Aufruf jedes Skripts steht oben in der Datei. Alle Läufe hatten ein eigenes, leeres `user://` (wie `run_tests.sh`, über `APPDATA`); keiner der Simulatoren schreibt Spielstände.

**Grenzen, die für alle Zahlen gelten:**

- Die Simulatoren kennen keine Verzauberungen, Sockel, Kristall-Aufwertungen und (außer in den Ring-Varianten) keinen Schmuck. Die Zufalls-Attribute seltener Teile sind dabei (sie hängen an der Seltenheit).
- Leder ist im Simulator immer Rattenleder (Kupfer) oder Wolfsleder (alles andere).
- Builds: die festen Builds aus `sim_party.gd`, dazu je Baum ein Build „Baum in seiner Reihenfolge, mit den Skillpunkten des Levels“. Ein echter Spieler skillt gezielter.
- 40 Kämpfe je Zelle heißt: ± 15 Prozentpunkte Zufall. Unterschiede unter 15 Punkten bei den Varianten sind keine Aussage.
- Die Minispiele kann kein Skript spielen. `sim_forge_quality.gd` nimmt eine Trefferquote an (70 / 90 / 100 % grüne Schläge), die Annahmen stehen im Skript-Kopf und in Abschnitt 7.
- Bekannter Fehler nur im Simulator: Steigt ein Held im Lauf auf, bricht `Hero.add_experience` nach dem Levelaufstieg mit „AudioManager nicht gefunden“ ab. Das Level zählt trotzdem, nur `emit_changed` fehlt. Kein Einfluss auf die Ergebnisse, aber die Logs sind voll davon.

Schreibweise: „R3.14“ = Schnitt Seltenheit R3 mit Qualität 14. „87 / 62“ = Siegquote mit Stufen-Erz R1 / mit dem Erz davor R1.

---

## 1. Kurzfassung

### Die 10 wichtigsten Probleme

| # | Stufe | Problem | Zahl |
|---|---|---|---|
| 1 | kritisch | Ohne Priester geht ab Gosse II nichts mehr. Der Kampf verlangt, dass 55–75 % des Schadens weggeheilt werden, und nur der Priester kann das. | Gruppe ohne Heiler: Leonheim 19–44 %, ab Vulkan 0–4 % Siege, mit Priester 72–94 % |
| 2 | kritisch | Mondglanz-Trank hat keine Obergrenze pro Item: +100 Qualität pro Trank, beliebig oft, bis R8. | 7 Tränke (21 Mondlilien) machen aus R1 ein R8-Teil; aus den Regeln gerechnet |
| 3 | kritisch | R6–R7-Waffen am ersten Tag in Leonheim: der Schwarzmarkt verkauft Eisen- und Bronzebarren R3–R4 für rund 20–40 Gold. | Eisenbarren R4, ohne Skills, 90 % Treffer: 81 % der Schwerter ≥ R6; mit Meisterhand 3: 100 % ≥ R6, 38 % R7 |
| 4 | groß | Rüstung liegt bei gleichem Spielerstand 1–3 Seltenheitsstufen unter der Waffe. R7 ist mit R1-Leder nicht erreichbar. | Barren R4, alle Skills: Schwert R7.56, Helm R4.28 (0 % ≥ R7) |
| 5 | groß | Später Beschwörer (ab Lv 40, 4–5 Beschwörungen) ist klar stärker als der Elementarist; mit zwei Beschwörungs-Ringen noch mehr. Vor Lv 40 ist er eher schwach. | Monster ×1,3: Finsterstadt 68 % gegen 10 %, Altar 48 % gegen 8 %; Arena 100 % |
| 6 | groß | Viele Dungeons liegen neben den Zielen; ab Platin reicht meist das alte Erz, weil die Metall-Sprünge schrumpfen (Silber » Gold +16 %, Gold » Platin +12 %). | rund 25 von 51 gemessenen Dungeons verfehlen mindestens ein Ziel, Liste in Abschnitt 2.2 |
| 7 | groß | Alte Dungeons auf ×5 sind mit späteren Helden gefahrlos und geben 3 Barren R4–R5 pro Lauf. | Rattenkeller, Rattennest, Wolfshöhle ×5 mit Eisen/Bronze Lv 15–25: 100 % Siege |
| 8 | groß | Meisterhand ist zu früh und zu billig, die Amboss-Upgrades sind dagegen fast wirkungslos. | 3 Skillpunkte ab Lv 2: +0,74 Stufen; Amboss Stufe 1–3 (23.000 Gold): +6 % Qualitätsgewinn ≈ +0,1 Stufen |
| 9 | klein | Sechs Bäume sind als dritter Held deutlich schwächer als der Rest: Segens-Priester, Arkanist, Schurke Schatten und Gift, Beschwörer vor Lv 40, Schütze. | Segens-Priester 69 % / 3 % (normal / Monster ×1,3), bester Baum 99 % / 62 % |
| 10 | klein | Helden sind in Teil 3–4 5–13 Level über den Dungeons. Unterwelt I und II gewinnt jede Gruppe zu 100 %. | Ende Teil 3: Lv 40–42, Sturmgipfel ist Lv 29–35 |

Optional: Dungeon-Kosten übersteigen ab Teil 3 vermutlich das Auftrags-Einkommen (Abschnitt 8, nur gerechnet).

### Deine vier Beobachtungen

| Beobachtung | Urteil | Beleg |
|---|---|---|
| 1. Beschwörer sehr stark, bis zu 5 Gehilfen | **teilweise bestätigt** | 5 gleichzeitig stimmt (eine pro Art, 5 Arten), aber erst ab Lv 38–40; im Schnitt leben 2,2–2,5. Vor Lv 40 macht er 19–30 % des Gruppenschadens (Elementarist 31–44 %). Ab Lv 40 56–60 %, mit zwei Ringen 67–69 %, und er gewinnt 40–58 Punkte öfter als der Elementarist. |
| 2. Heiler ist ein Muss | **bestätigt** | Ab Vulkan 0–4 % Siege ohne Priester, 72–94 % mit. Auch der Segens-Paladin ersetzt ihn nur in Leonheim (79 %), danach 12–63 %. |
| 3. Früh R6–R7-Waffen, Rüstung R7–R8 fast unmöglich | **bestätigt** | Siehe Problem 3 und 4. Rüstung mit Barren R4 und Leder R4, alle Skills: R5.80, 36 % ≥ R6, 0 % ≥ R7. |
| 4. Upgrades und Schmied-Skills zu stark oder zu schwach? | **beides** | Zu stark: Meisterhand (+0,74 Stufen für 3 Punkte ab Lv 2), Härtekunst (+0,5), Materialkunde (+0,55, wenn das Metall eine Stufe über dem Rang liegt). Zu schwach: Amboss-Upgrades (+2/4/6/9 % für 2.000–40.000 Gold), Esse-Upgrades. |

---

## 2. Fragen 1–10

### Frage 1: Helden gegen Monster

Messung: `sim_balance.gd stats 1 1`.

**Helden pro Level** (Standard-Build, Eisen R1, ohne Ausrüstungswechsel):

| Level | Krieger Leben | Treffer | Priester Leben | Mana | Mana/s | Magier Magie-Treffer |
|---|---|---|---|---|---|---|
| 1 | 30 | 14–20 | 30 | 13 | 0,1 | 12–17 |
| 20 | 150 | 26–32 | 141 | 37 | 2,5 | 16–25 |
| 40 | 279 | 38–44 | 255 | 62 | 3,7 | 21–32 |
| 60 | 428 | 51–57 | 372 | 87 | 6,1 | 26–40 |
| 100 | 694 | 76–82 | 603 | 137 | 9,7 | 36–55 |

Pro Level also rund +6,7 Leben und +0,6 Schaden. Das Level allein verdoppelt den Schaden erst in 40 Leveln. Den Rest trägt das Erz: Klinge + Griff im Schnitt Kupfer 5,5, Eisen 11, Bronze 17,5, Silber 25,5, Gold 29,5, Platin 33, Palladium 41,5 (Sprünge +100 %, +59 %, +46 %, **+16 %, +12 %**, +26 %). Rüstung des Kriegers: 37 (Kupfer), 58, 74, 96 (Silber), 114 (Platin). Rüstung 100 halbiert den Schaden, mehr Rüstung bringt immer weniger.

**Monster nach `enemy_scale`** (Schnitt über alle Arten des Dungeons) und was das für den Krieger der Stufe heißt:

| Dungeon (Level, Erz) | Faktor | Monster-Leben | Monster-Treffer | Schläge, bis ein Monster fällt | Treffer, bis der Krieger fällt |
|---|---|---|---|---|---|
| Rattenkeller (1, Kupfer) | 1,0 | 9 | 1,5 | 0,8 | 27 |
| Wolfshöhle (13, Kupfer) | 0,9 | 59 | 5,1 | 3,3 | 26 |
| Kanalisation (12, Eisen) | 1,8 | 124 | 13,1 | 5,3 | 11 |
| Gosse III (18, Eisen) | 4,05 | 305 | 22,6 | 11,8 | 9 |
| Magmahallen (28, Bronze) | 1,7 | 557 | 21,1 | 16,3 | 17 |
| Wassergrotte (35, Silber) | 2,0 | 1200 | 36,8 | 27,0 | 13 |
| Eisbrücken (48, Platin) | 1,75 | 1173 | 40,5 | 22,3 | 18 |
| Altar Süd (57, Palladium) | 2,2 | 3328 | 64,9 | 55,3 | 15 |
| Altar Lake (59, Palladium) | 2,4 | 4272 | 70,8 | 69,1 | 14 |

**Wo es kippt:** in Leonheim. Bis zur Wolfshöhle braucht ein Monster 1–3 Schläge und der Held hält 21–41 Treffer aus (Verhältnis unter 0,15). In Leonheim springt `enemy_scale` von 0,9 auf 1,8–4,05: 5–12 Schläge pro Monster bei 7–15 ausgehaltenen Treffern (Verhältnis rund 1). Ab dem Vulkan sind es 16–69 Schläge pro Monster bei 12–21 Treffern (Verhältnis 1–5). Die Kämpfe werden also viel länger, ohne dass die Helden länger durchhalten.

Gemessen an der Referenzgruppe (`sim_balance.gd healer` und `summoner`, je 60–90 Kämpfe):

| Dungeon | Schaden auf die Gruppe pro s | Kampfdauer | Schaden im ganzen Lauf ÷ Leben der Gruppe | davon Heilung | davon Schilde |
|---|---|---|---|---|---|
| Kanalisation | 5,9 | 57 s | 1,2 | 31 % | 7 % |
| Gosse III | 10,5 | 100 s | 2,7 | 55 % | 10 % |
| Magmahallen | 24,0 | 119 s | 5,0 | 72 % | 14 % |
| Wassergrotte | 25,5 | 142 s | 5,2 | 72 % | 16 % |
| Eisbrücken | 43,0 | 133 s | 6,1 | 70 % | 17 % |
| Finster-Kanäle | 38,8 | 190 s | 7,3 | 75 % | 19 % |

**Ursache für Problem 1:** Ab dem Vulkan nimmt die Gruppe in einem Lauf das Fünf- bis Siebenfache ihres Lebens an Schaden. Helden behalten ihr Leben zwischen den Stufen, es gibt keine Erholung zwischen den Kämpfen und keine Heiltränke im Kampf. Die eigene Regeneration (2–3 Leben/s pro Held) deckt rund 25 %. Den Rest muss ein Heiler liefern.

Vorschlag: siehe Frage 4. Die Monster-Werte selbst sind in Ordnung, das Problem ist die fehlende zweite Quelle für Leben.

### Frage 2: Schwierigkeitskurve

Messung: `sim_party.gd 40`, dreimal. Ziel: Stufen-Erz 75–90 %, Erz davor höchstens 35–50 %, Erz davor in R2 50–85 %.

#### 2.1 Alle Dungeons

| Dungeon (Level) | Stufen-Erz R1 | Erz davor R1 | Erz davor R2 | ohne Heiler (Pal + Wald + Schurke) |
|---|---|---|---|---|
| Rattenkeller (1) | 100 | – | – | – |
| Tiefer Keller (3) | 92 | – | – | – |
| **Rattennest (7)** | **33** | – | – | – |
| Mine (7) | 97 | – | – | – |
| Lichter Hain (8) | 98 | – | – | – |
| Dornendickicht (10) | 89 | – | – | – |
| Wolfshöhle (13) | 80 | – | – | – |
| Kanalisation (12) | 86 | 66 | 86 | 76 |
| Gosse I (14) | 88 | 17 | 80 | 68 |
| Katakomben (15) | 90 | 33 | 78 | 67 |
| Gosse II (16) | 90 | 13 | 72 | 11 |
| Gruft der Könige (18) | 82 | 25 | 47 | 12 |
| Gosse III (18) | 82 | 7 | 60 | 4 |
| **Gosse IV (20)** | **62** | 5 | 46 | 81 |
| Verzauberte Gruft (22) | 89 | 29 | 60 | 14 |
| **Aschegänge (25)** | 87 | **62** | 75 | 13 |
| **Magmahallen (28)** | 85 | **71** | 80 | 1 |
| **Lavagolem (30)** | 74 | **64** | 75 | 0 |
| **Drachenkammer (36)** | **58** | 4 | 8 | 0 |
| **Bergfuß (29)** | **95** | **74** | 88 | 10 |
| Felsenhänge (32) | 94 | 41 | 54 | 64 |
| Horst (35) | 96 | 34 | 58 | 0 |
| Küste (33) | 89 | 33 | 39 | 0 |
| Wasserhöhle (35) | 94 | 33 | 54 | 0 |
| Grotte (37) | 76 | 10 | 20 | 0 |
| Tiefe Grotte (38) | 81 | 8 | 10 | 0 |
| Gießerei (37) | 88 | 52 | 70 | 0 |
| Obsidian (39) | 85 | 11 | 22 | 0 |
| Windhöhle (39) | 75 | 5 | 18 | 63 |
| Wurzeln (37) | 84 | 33 | 62 | 6 |
| **Sumpf I (40)** | **97** | **94** | 94 | 1 |
| Sumpf II Hydrateich (42) | 83 | 60 | 79 | 0 |
| **Sumpf III Nebelfürst (44)** | **40** | 5 | 18 | 0 |
| Bergfried (45) | 73 | 53 | 74 | 0 |
| **Eisquell brennt (46)** | **95** | **90** | 98 | 0 |
| **Eisfälle (47)** | **99** | **93** | 94 | 2 |
| Eisbrücken (48) | 74 | 42 | 58 | 0 |
| Windbruch (49) | 85 | 66 | 84 | 0 |
| **Mauerkrone (50)** | **58** | 41 | 56 | 0 |
| **Finster-Asche (51)** | **95** | **80** | 84 | 0 |
| Finster-Kanäle (52) | 81 | 58 | 74 | 0 |
| Finster-Türme (53) | 93 | 75 | 88 | 0 |
| Sternenkrater (54) | 68 | 24 | 39 | 0 |
| **Altar-Tor (55)** | **98** | **99** | 99 | 4 |
| Altar Nord (55) | 79 | 56 | 61 | 0 |
| **Altar Ost (58)** | **98** | **85** | 93 | 0 |
| Altar Süd (57) | 73 | 59 | 71 | 0 |
| Altar West (56) | 86 | 62 | 80 | 0 |
| Altar Lake (59) | 86 | 64 | 65 | 0 |
| **Unterwelt Straße (62)** | **100** | **100** | 100 | 100 |
| **Unterwelt Turm (65)** | **100** | **100** | 100 | 100 |

Hinweis zum Sumpf: Der Simulator rechnet dort mit Platin als Stufen-Erz. Laut `docs/systeme/schmieden.md` gibt es im Sumpf aber nur Gold, Platin erst ab der Finsterburg. Für den Spieler gilt im Sumpf also die Spalte „Erz davor“: Sumpf III mit Gold **5 %** (R2 18 %), Bergfried mit Gold 53 %.

#### 2.2 Außerhalb der Ziele

- **Zu schwer mit Stufen-Erz:** Rattennest 33 %, Gosse IV 62 %, Drachenkammer 58 %, Sumpf III 40 % (mit Gold 5 %), Mauerkrone 58 %.
- **Zu leicht mit Stufen-Erz (über 90 %) und altes Erz reicht:** Bergfuß 95 / 74, Sumpf I 97 / 94, Eisquell brennt 95 / 90, Eisfälle 99 / 93, Finster-Asche 95 / 80, Altar-Tor 98 / 99, Altar Ost 98 / 85, Unterwelt 100 / 100.
- **Altes Erz reicht (über 50 %), obwohl das neue nötig sein soll:** Kanalisation 66 (als Einstieg gewollt), Aschegänge 62, Magmahallen 71, Lavagolem 64, Gießerei 52, Hydrateich 60, Bergfried 53, Windbruch 66, Finster-Kanäle 58, Finster-Türme 75, Altar Nord bis Lake 56–64.

**Sprünge zwischen Kapiteln:** Wolfshöhle » Leonheim ist der große Sprung (Faktor 0,9 » 1,8–4,05, erstmals Priester nötig). Vulkan III » Drache: mit Eisen 64 % » 4 %. Sumpf II » III: 83 % » 40 %. Eiswand: 99 / 74 / 85 / 58, also zwei leichte und zwei schwere abwechselnd.

**Ursache für „altes Erz reicht“ ab Platin:** die kleinen Metall-Sprünge (Frage 1). Im Vulkan ist es etwas anderes: dort wurde auf 75–90 % mit Bronze eingestellt, aber Eisen hält mit, weil der Schaden im Vulkan Feuer ist und Platten bis Bronze keine Magieresistenz haben. Mehr Rüstung hilft dort wenig.

**Die Kurve ist sehr steil.** `sim_party.gd tune`, 40 Läufe:

| Dungeon | Faktor jetzt » Sieg | Faktor Probe » Sieg (Stufen-Erz / Erz davor) | Vorschlag |
|---|---|---|---|
| Aschegänge | 1,8 » 87 / 62 | 2,1 » 30 / 10 | etwa 1,9 |
| Magmahallen | 1,7 » 85 / 71 | 2,0 » 30 / 8 | etwa 1,8 |
| Lavagolem | 1,35 » 74 / 64 | 1,5 » 43 / 13 | etwa 1,4 |
| Drachenkammer | 1,3 » 58 / 4 | **1,2 » 83 / 13**, 1,1 » 93 / 53 | **1,2** |
| Bergfuß | 1,85 » 95 / 74 | 2,2 » 45 / 8 | etwa 2,0 |
| Sumpf I | 2,4 » 97 / 94 | 2,8 » 50 / 33 | etwa 2,6 |
| Sumpf III | 2,35 » 40 / 5 | 2,15 » 95 / 53, 2,0 » 95 / 85 | etwa 2,25 |
| Eisquell brennt | 2,3 » 95 / 90 | 2,7 » 58 / 50 | etwa 2,5 |
| Eisfälle | 1,65 » 99 / 93 | 2,0 » 70 / 48 | etwa 1,9 |
| Finster-Asche | 2,85 » 95 / 80 | 3,2 » 73 / 35 | **3,2** |

15 % mehr Monster-Stärke kosten rund 50 Prozentpunkte. Fett = gemessen im Ziel; „etwa“ = zwischen zwei Messpunkten geschätzt, vor dem Eintragen mit `autotune` bestätigen. Ab Platin erfüllt kein einzelner Faktor beide Ziele (z. B. Eisquell 2,7: 58 / 50), dort hilft nur ein größerer Metall-Sprung (Frage 6).

**Leveln (`sim_progress.gd trio 0 <seed>`, Seeds 1–3):**

| Ende von | Tag | Story-Helden | Dungeons des Teils | Unterschied | Spieler-Level |
|---|---|---|---|---|---|
| Teil 1 | 29 | 17 | Wolfshöhle 13 | +4 | 7–8 |
| Teil 2 | 55–60 | 37–39 | Drache 36 | +1 bis +3 | 13–16 |
| Teil 3 | 60–65 | 40–42 | Sturmgipfel 29–35 | **+5 bis +13** | 15–18 |
| Teil 4 | 68–74 | 44–46 | Wasser 33–38, Kompass 37–39 | **+6 bis +12** | 19–22 |
| Teil 5 | 75–80 | 48–49 | Bergfried 45 | +3 | 23–25 |
| Teil 6 | 82–87 | 52–53 | Mauerkrone 50 | +3 | 27–28 |
| Teil 7 | 88–93 | 56 | Finsterstadt 51–53 | +3 bis +5 | 30–31 |
| Teil 8 | 96–106 | 60–61 | Altar Lake 59 | +1 | 34–37 |

846–946 Läufe, davon 62–72 verloren (7–8 %). Zu schnell gelevelt wird in Teil 3 und 4: Der Drache (Lv 36) zieht die Helden hoch, danach kommen Dungeons ab Lv 29. Diese Dungeons sind mit passendem Level schon bei 89–96 %, mit +6 bis +13 Leveln sind sie in der Praxis geschenkt. Vorschlag: Sturmgipfel auf Lv 37 / 39 / 41, Wasser auf 40–44, Kompass 42–44, jeweils mit `autotune` neu einstellen (Paket 1).

### Frage 3: Beschwörer

**Wie viele gleichzeitig und warum:** `Adventure._is_useful` erlaubt jede Art einmal. Der Magier hat fünf Beschwörungs-Skills, also höchstens 5. Sie brauchen 0 / 4 / 10 / 16 / 19 Punkte im Baum, bei einem Skillpunkt pro 2 Level also Lv 2 / 8 / 20 / 32 / 38. Gemessen: höchstens 2 bei Lv 18, 3 bei Lv 28–35, 5 ab Lv 40.

**Werte** (`Combatant.from_summon`): Eine Beschwörung bekommt einen Anteil aller Werte des Magiers (Attribute, Leben, Rüstung, Magieresistenz, Resistenzen) und seinen Zauberschaden samt Intelligenz-Faktor mal Anteil. Ausrüstung und Level wirken also voll mit.

| Beschwörung | Anteil Stufe 1 » 5 | Leben | Tempo | Dauer / Abklingzeit | Mana Stufe 1 » 5 | Besonderes |
|---|---|---|---|---|---|---|
| Feuerelementar | 10 % » 50 % | ×1 | 1,0 | 20 s / 30 s | 15 » 30 | Brand 10 % |
| Eiselementar | 15 % » 55 % | ×2 | 1,0 | 20 s / 35 s | 18 » 36 | Spott, verlangsamt immer |
| Sturmgeist | 20 % » 60 % | ×1 | 2,0 | 20 s / 40 s | 24 » 48 | Betäubung 15 % |
| Erdgolem | 40 % » 80 % | ×3 | 0,8 | 30 s / 60 s | 35 » 70 | physisch (nutzt den schwachen Waffenschaden des Magiers) |
| Elementarfürst | 80 % » 100 % (3 Stufen) | ×2 | 1,0 | 25 s / 90 s | 50 » 75 | Feuerball, Eislanze, Meteor |

„Bindung“ verlängert jede um bis zu 10 s. Der Bernstein- und der Smaragd-Ring geben „Beschwörungs-Schaden“ 8 % × Seltenheits-Faktor (R1 ×1 bis R8 ×4) × Metall-Faktor (bis ×1,6); zwei Ring-Plätze. Faktoren laut `economy.json`: R4 ×1,75, R5 ×2, R7 ×3. Zwei Platinringe R5 sind rund +45 %, zwei Palladiumringe R7 rund +77 % (in den Messungen unten als +44 % und +80 % eingesetzt). Zum Vergleich: der Element-Ring des Elementaristen hat den Grundwert 5 %.

**Messung** (`sim_balance.gd`, Krieger + Priester + dritter Held; `summoner_max` = alle fünf Beschwörungen, Bindung, Seelenband, ohne „Opfern“; der Build `summoner` aus sim_party opfert seine Elementare und ist schwächer):

| Dungeon (Level) | Elementarist normal / ×1,3 | Beschwörer normal / ×1,3 | Beschwörungen im Schnitt / höchstens | Anteil am Gruppenschaden |
|---|---|---|---|---|
| Gosse III (18) | 92 / 0 | 95 / 2 | 0,7 / 2 | 8 % |
| Magmahallen (28) | 82 / 5 | 80 / 3 | 0,7 / 3 | 9 % |
| Wasserhöhle (35) | 93 / 18 | 94 / 8 | 0,9 / 3 | 21 % |
| Sumpf I (40) | 95 / 38 | 95 / 50 | 1,8 / 5 | 39 % |
| Eisbrücken (48) | 66 / 0 | 70 / 5 | 1,7 / 5 | 43 % |
| Finster-Kanäle (52) | 93 / 10 | 100 / **70** | 2,5 / 5 | 60 % |
| Altar Süd (57) | 75 / 8 | 90 / **43** | 2,2 / 5 | 56 % |

Seeds 1–2 × 30 Läufe. Gegenprobe mit Seeds 1–3 × 20 bei ×1,3: Sumpf 48 gegen 30, Finster 68 gegen 10, Altar 48 gegen 8.

Mit starker Ausrüstung (alles R6, 5 Level über dem Dungeon, Monster ×1,8; 40 Kämpfe je Zelle):

| | Wasserhöhle | Eisbrücken | Finster-Kanäle | Altar Süd |
|---|---|---|---|---|
| Elementarist | 85 | 20 | 45 | 35 |
| Elementarist + 2 Element-Ringe (+28 % / +50 %) | 60 / 75 | 32 / 25 | 52 / 75 | 42 / 38 |
| Beschwörer | 88 | 30 | 85 | 55 |
| Beschwörer + 2 Ringe (+44 % / +80 %) | 88 / 78 | 40 / 35 | 85 / 95 | 60 / 80 |

Mit Ringen kommen 67–69 % des Gruppenschadens von den Beschwörungen. Arena (`sim_duels.gd 4`): Beschwörer 100 %, wie schon am 2026-11-08.

**Ursache:** (a) Die zwei späten Beschwörungen sind zusammen 180 % eines zweiten Magiers, und der Fürst zaubert selbst. (b) Beschwörungen fangen Treffer ab (Eiselementar spottet, Golem hat 3-faches Leben), die Gruppe nimmt weniger Schaden. (c) Der Ring-Wert 8 % multipliziert den ganzen Beschwörungs-Schaden, der Element-Ring (5 %) wird nur zu anderen Boni addiert. Vor Lv 40 fehlen Golem und Fürst, dann ist der Baum schwächer als der Elementarist.

**Nerf-Varianten** (starke Ausrüstung, Monster ×1,8, Seeds 1–2 × 20; Ausgangswert Beschwörer 88 / 30 / 85 / 55, Schnitt 65; Elementarist Schnitt 46):

| Variante | Wasserhöhle | Eisbrücken | Finster-Kanäle | Altar Süd | Schnitt |
|---|---|---|---|---|---|
| Obergrenze 3 gleichzeitig | 80 | 30 | 78 | 70 | 65 |
| Obergrenze 2 gleichzeitig | 82 | 35 | 82 | 60 | 65 |
| Mana-Kosten ×1,5 | 88 | 28 | 82 | 72 | 68 |
| Dauer ×0,7 | 68 | 20 | 75 | 55 | 55 |
| Anteil aller Beschwörungen ×0,75 | 75 | 2 | 70 | 38 | **46** |

Nur Golem und Fürst schwächer (normale Ausrüstung, Monster ×1,3, Seeds 1–3 × 20): Anteil ×0,75: Finster 68 » 43, Altar 48 » 33; ×0,6: 42 und 32 (Elementarist 10 und 8).

**Ergebnis:** Eine Obergrenze und höhere Mana-Kosten ändern nichts (im Schnitt leben ohnehin nur rund 2, und der Magier ruft die teuersten zuerst). Wirksam sind nur der Anteil und, halb so stark, die Dauer.

**Vorschlag (Paket 3):**
1. Erdgolem 40 % +10 » 30 % +8 pro Stufe, Elementarfürst 80 % +10 » 60 % +8 (entspricht etwa „×0,75 nur die späten“): gemessen −15 bis −25 Punkte im Endspiel, der Beschwörer bleibt dort 25–35 Punkte über dem Elementaristen.
2. Ring „Beschwörungs-Schaden“ 8 » 5 (wie der Element-Ring). Nicht einzeln gemessen; nach der Ring-Tabelle oben kostet das etwa die Hälfte des Ring-Vorteils.
3. Früh nichts schwächen. Der Beschwörer ist vor Lv 40 schon unter dem Elementaristen.
4. Für die Arena getrennt lösen (dort bekommen Beschwörungen das vervierfachte Leben mit, siehe `docs/PROBLEME.md`).

Ob der Abstand ganz weg soll (dann Anteil aller ×0,75) oder der Elementarist stattdessen stärker wird, ist deine Entscheidung (Abschnitt 4).

### Frage 4: Heiler

Messung: `sim_balance.gd healer 30 <seed>`, Seeds 1–3, Stufen-Erz R1. Schnitt über die Dungeons des Kapitels.

| Kapitel | Krieger + **Priester** + Magier | Krieger + **Segens-Paladin** + Magier | beste Gruppe ohne Heiler | Krieger + Magier + Waldläufer |
|---|---|---|---|---|
| Leonheim (8) | 83 | 79 | 44 (Pal + Wald + Schurke) | 19 |
| Vulkan (4) | 73 | 12 | 4 | 0 |
| Sturmgipfel (3) | 94 | 63 | 23 | 6 |
| Wasser (4) | 86 | 14 | 0 | 0 |
| Kompass (4) | 83 | 43 | 15 | 9 |
| Sumpf, Bergfried (4) | 72 | 29 | 1 | 0 |
| Eis (5) | 81 | 40 | 1 | 0 |
| Finsterstadt, Krater (4) | 85 | 54 | 0 | 0 |
| Altar (6) | 89 | 42 | 3 | 0 |

Der Abstand ist 40 Punkte in Leonheim und 70–90 danach. Ziel waren 15–25.

**Warum es ohne nicht geht** (Zahlen aus Frage 1): Die Gruppe muss im Lauf das Fünf- bis Siebenfache ihres Lebens aushalten. Was die Alternativen heute liefern:

- Eigene Regeneration: 2–3 Leben/s pro Held, rund 25 % des Schadens.
- „Wunden heilen“ des Körper-Kriegers: 0,4–3,2 Leben/s gemessen, 5–15 % des Schadens auf ihn.
- Schilde des Bollwerk-Paladins: 2–4 Leben/s, rund 10–15 %.
- Lebensraub: nur über Onyx- und Rubin-Ringe (2 % × Faktoren) und einzelne Skills; im Simulator ohne Schmuck nicht dabei.
- Heiltränke im Kampf: gibt es nicht. Der Mörser macht nur Verzauberungs- und Helden-Tränke.
- Erholung zwischen den Stufen: gibt es nicht.
- Mehr Rüstung: Monster ×0,8 Schaden hebt die Gruppen ohne Heiler nur auf 0–22 % (Gosse II), ab Vulkan 0–8 %.

**Varianten** (Seeds 1–2 × 20; „Pause“ = nach jeder geschafften Stufe bekommt jeder lebende Held so viel seines Lebens zurück; „Tränke“ = jeder Held hat n Tränke pro Dungeon und trinkt unter 35 % Leben; beides gibt es im Spiel nicht, nur im Simulator):

| Variante | Gruppe | Gosse II | Magmahallen | Wasserhöhle | Eisbrücken | Altar Süd |
|---|---|---|---|---|---|---|
| heute | mit Priester | 89 | 79 | 92 | 70 | 90 |
| heute | ohne (drei Gruppen) | 0–8 | 0 | 0 | 0 | 0 |
| Monster-Schaden ×0,8 | mit / ohne | 100 / 10–65 | 100 / 0–8 | 100 / 0–2 | 100 / 0 | 100 / 0 |
| Regeneration aus Konstitution ×2,5 | mit / ohne | 100 / 5–22 | 98 / 0–18 | 100 / 0–10 | 90 / 0–2 | 90 / 0 |
| Pause 15 % | mit / ohne | 98 / 80–100 | 95 / 22–60 | 95 / 12–28 | 82 / 5–8 | 85 / 0 |
| Pause 25 % | mit / ohne | 100 / 100 | 95 / 65–95 | 98 / 52–58 | 72 / 15–40 | 72 / 0–2 |
| Pause 35 % | mit / ohne | 100 / 100 | 100 / 88–98 | 98 / 78–88 | 70 / 35–58 | 88 / 0–2 |
| 3 Tränke zu 50 % | mit / ohne | 100 / 98–100 | 98 / 35–90 | 100 / 18–58 | 100 / 8–48 | 100 / 0–2 |
| Pause 20 % + 2 Tränke zu 40 % | mit / ohne | 100 / 100 | 100 / 92–98 | 100 / 88–95 | 98 / 40–85 | 98 / 2–25 |
| Pause 20 % + 3 Tränke zu 50 % | mit / ohne | 100 / 100 | 100 / 98–100 | 100 / 100 | 100 / 75–95 | 100 / 25–68 |
| dasselbe, Monster ×1,15 | mit / ohne | 100 / 100 | 100 / 68–88 | 98 / 58–80 | 68 / 22–35 | 92 / 0–2 |

**Ergebnis:**

- Weniger Monster-Schaden oder mehr Regeneration verschieben nur die Gruppe mit Priester auf 100 %, ohne Heiler bleibt es bei 0. Das ist der falsche Hebel.
- Eine Pause zwischen den Stufen plus wenige Heiltränke ist die kleinste Änderung, die wirkt: bis zur Wasserhöhle (Teil 4) kommen Gruppen ohne Heiler auf 58–95 % bei 98–100 % mit Priester. Der Priester bleibt die sichere Wahl, ist aber nicht mehr Pflicht.
- Mit Priester wird dadurch alles zu leicht; die Dungeons brauchen danach rund +15 % `enemy_scale` (letzte Zeile).
- Ab Teil 6 reicht das nicht (Eisbrücken 22–35 %, Altar 0–2 % nach dem Nachziehen). Dort entscheiden lange Boss-Kämpfe, in denen eine Pause nichts bringt. Für das Endspiel braucht es zusätzlich Dauer-Erholung im Kampf bei Klassen ohne Heiler (Lebensraub und Schilde, die mitwachsen). Das habe ich nicht gemessen, es gehört in Paket 2.

**Vorschlag (Paket 1):** `combat.json` `stage_rest_heal` 0,2 (neue Regel in `Adventure`, 20 % des max. Lebens nach jeder Stufe) und Heiltränke als Schmiede-Produkt (Mörser: 2 pro Held und Dungeon, 40 %), danach alle Dungeons ab Leonheim mit `autotune` neu auf 80 %. Erwartung nach der Tabelle: ohne Heiler bis Teil 4 etwa 60–90 %, Abstand zum Priester 10–40 Punkte statt 80–90; Teil 6–8 bleibt vorerst Heiler-Gebiet.

### Frage 5: Skills der Helden

**Skalierung** (Prüfung von `skills.json` und `skill_trees.json` per Skript): Alle 52 aktiven Schadens-Skills der 18 Bäume haben `scaling`, außer zwei, die es absichtlich nicht haben: Schildstoß (rechnet aus Rüstung und Leben) und „Fass!“ (Angriff des Wolfs). Alle Heil-Skills heilen einen Anteil des max. Lebens des Ziels × Heilkraft (0,3 % je Weisheit), wachsen also mit. Auffällig:

- „Wunden heilen“ (Krieger), „Heilkräuter“ (Waldläufer) und „Handauflegen“ (Paladin) wachsen nur mit Weisheit, die Krieger und Waldläufer nicht steigern. Gemessen liefert „Wunden heilen“ 0,4–3,2 Leben/s.
- Die kleinen Faktoren bei „Tausend Schnitte“ (0,5), „Sturmsalve“ (0,9) und „Toxischer Ausbruch“ (0,4) sind kein Fehler: es sind 8 bzw. 6 Treffer bzw. Schaden pro Gift-Stapel.
- Erdgolem: physischer Angriff aus dem Waffenschaden des Magiers (Stab 1–4 + Stärke), also sehr schwacher Schaden. Sein Wert ist das Leben.

**Jeder Baum als dritter Held** (`sim_balance.gd trees 30 <seed>`, Seeds 1–2, neben Krieger + Priester, Schnitt über 7 Dungeons von Gosse III bis Altar Süd; Monster normal / ×1,3 / Schadensanteil des Helden):

| Baum | Siege normal | Siege ×1,3 | Schadensanteil | Arena (4 Kämpfe je Gegner) |
|---|---|---|---|---|
| Paladin Segen | 99 | **62** | 28 % | 21 % |
| Priester Licht (zweiter Heiler) | 96 | 47 | 12 % | 44 % |
| Waldläufer Tierfreund | 96 | 39 | 59 % | 88 % |
| Waldläufer Natur | 94 | 36 | 40 % | 69 % |
| Paladin Vergeltung | 92 | 28 | 55 % | 59 % |
| Paladin Bollwerk | 89 | 22 | 33 % | 29 % |
| Krieger Schwert | 86 | 19 | 55 % | 84 % |
| Priester Schatten | 93 | 19 | 37 % | 62 % |
| Waldläufer Schütze | 78 | 10 | 55 % | 81 % |
| Krieger Körper | 82 | 9 | 29 % | 10 % |
| Krieger Glut und Fels | 80 | 8 | 37 % | 9 % |
| Magier Elementarist | 80 | 7 | 45 % | 41 % |
| Schurke Zwei Klingen | 79 | 7 | 50 % | 50 % |
| Magier Beschwörer (Baum-Reihenfolge, mit Opfern) | 77 | 5 | 32 % | 100 % |
| Magier Arkanist | 74 | 4 | 27 % | 29 % |
| Schurke Schatten | 71 | 4 | 33 % | 57 % |
| Priester Segen | 69 | 3 | 12 % | 0 % |
| Schurke Gift | 75 | 3 | 42 % | 66 % |

**Lesart:** Im Dungeon gewinnt, was Leben bringt oder Schaden abfängt (zweiter Heiler, Wolf als Zusatz-Ziel, Heilkräuter, Steinhaut, Schilde). Reine Schadens-Bäume stehen unten, obwohl sie 45–55 % des Schadens machen. Das ist dieselbe Ursache wie bei Frage 4. Die Arena zeigt fast das umgekehrte Bild. Nach einer Pause- und Trank-Regel sollten die Abstände kleiner werden; die Liste muss dann neu gemessen werden, bevor einzelne Bäume angefasst werden.

**Welche Bäume nimmt kein Referenz-Build:** Segens-Priester, Arkanist, Schurke Schatten und Gift, Krieger Körper und Glut. Das sind zugleich die sechs schwächsten.

**Passive gegen Aktive, starke Skills zu früh:** nicht einzeln gemessen (Annahme aus den Daten): Die Passiven liegen in einer Größe (Klingenschärfe +30 % Schnitt, Elementarmeister +30 % Element, Gepanzert +40 % Rüstung, Zähigkeit +17 % Leben auf Stufe 5). Früh auffällig sind nur das Eiselementar (Spott und sichere Verlangsamung ab 4 Punkten, Lv 8) und „Heilendes Licht“ ab 0 Punkten, auf das alles abgestimmt ist.

**Vorschlag (Paket 3, erst nach Paket 1 neu messen):** Segens-Priester und Arkanist brauchen einen eigenen Schadens- oder Heil-Skill früh im Baum; Heil-Skills von Kriegern und Waldläufern auf das Hauptattribut der Klasse umstellen (`scaling` gibt es für Heilung noch nicht, das wäre eine kleine Code-Änderung).

### Frage 6: Waffenstufe pro Kapitel, Seltenheit, Verzauberungen

**Metall pro Kapitel** (aus der Story-Reihenfolge, `sim_progress.gd` PATH): Teil 1 Kupfer; Teil 2 Eisen (Leonheim), dann Bronze (Vulkan); Teil 3 Silber; Teil 4 Silber, dann Gold (Wüste); Teil 5 Gold (Platin nur als Beute der Finsterburg); Teil 6 Platin; Teil 7–8 Palladium.

**Seltenheit eines normalen Spielers** (aus `sim_forge_quality.gd`, 90 % Treffer, Schwierigkeit „Normal“; welche Skills er wann hat, ist eine Annahme aus dem Spieler-Level in `sim_progress`):

| Zeitpunkt | Spielerstand (Annahme) | Waffe aus R1-Barren | Rüstung (Leder R1) | Waffe aus R2-Barren |
|---|---|---|---|---|
| Teil 1, Anfang | keine Skills | R3.14 | R2.07 | R4.13 |
| ab Kapitel 5 (Spieler Lv 5) | Meisterhand 3 | R3.88 | R2.44 | R4.88 |
| Teil 2 (Lv 10–15) | + Härtekunst 5 | R4.38 | R2.70 | R5.38 |
| ab Teil 3 | + Meisteramboss, Meisterhandschuhe | R4.54 | R2.77 | R5.55 |

Ist das Metall eine Stufe über dem Ruf-Rang („Schwierig“): rund −0,55 Stufen; zwei Stufen darüber („Sehr schwer“): rund −1,1.

**Was eine Seltenheitsstufe bringt** (`Rarity`): +2 Schaden bzw. Rüstung pro Stufe und Teil, fest. Dazu Zufalls-Attribute ab R4: R4 +2, R5 +4, R6 +6 und +2, R7 +8 und +4, R8 +10, +6 und +2 pro Teil (Attribut-Art zufällig).

- Früh ist der feste Bonus riesig: Kupferschwert 4–7 » R2 6–9 (+36 %). Deshalb ist Kupfer R2 so gut wie Eisen R1 (Kanalisation 86 % gegen 86 %).
- Spät ist er klein: Palladiumschwert 34–49 » R2 +5 %. Spät zählen die Attribute: 12 Plätze in R8 sind 216 Attributpunkte.

Gemessen (Referenzgruppe, ganzer Satz in einer Seltenheit, 20 Kämpfe, Seed 1): Monster ×1,3: R1 0–20 %, R3 0–50 %, **R5 50–100 %** Siege. Schwerer Modus ×2 im Dungeon der eigenen Stufe: erst mit R7 15–30 % (Gosse III 100 %); ×3: auch mit R7 0–15 %. Ein ganzer Satz R5 ist also rund 30 % Monster-Stärke wert.

**Verzauberungen und Sockel** (nur aus `sockets.json` gelesen, der Simulator kennt sie nicht, also keine Messung):

| Was | Werte R1 » R8 | Einordnung (gerechnet) |
|---|---|---|
| Element-Verzauberung der Waffe | +5 % » +40 % Zusatzschaden | stärkste Waffen-Verzauberung, solange das Ziel dem Element nicht widersteht |
| Federtrank (Tempo) | +4 % » +25 % | wirkt auch auf Treffer-Effekte, sonst unter dem Element |
| Segen (Attribut) | +1 » +10 | klein |
| Fluch (Effekt beim Treffer) | 3–5 % » 15–25 % Chance | nicht einschätzbar ohne Messung |
| Schutz gegen ein Element, pro Rüstungsteil | +3 » +28 | 8 Teile + Schild in R3: 63 Resistenz = −39 % Schaden dieses Elements; in R8: 252 = −72 % |
| Sockel Schärfe | +5 / 10 / 15 % Schaden | bis 4 Sockel pro Teil, Chance 35 % ab R4 |

Die eine Kombination, die alles schlägt, ist kein Kampf-Wert, sondern der Mondglanz-Trank (Frage 9). Im Kampf ist der Element-Schutz auf allen Teilen der stärkste Einzelhebel, aber nur in Dungeons mit einem Element (Vulkan), und dort ist er gewollt.

**Vorschlag (Paket 4):** Metall-Sprünge ab Gold vergrößern, damit das neue Erz wieder nötig ist: Gold = Eisen × 2,9 statt 2,65, Platin × 3,5 statt 3,0, Palladium × 4,3 statt 3,8 (Sprünge dann +26 %, +21 %, +23 %). Nicht gemessen, weil das `items.json` ändert; nach Regel 28 mit `sim_party` prüfen. Erwartung: Spalte „Erz davor“ fällt ab Sumpf von 53–99 % in Richtung 35–50 %.

### Frage 7: Waffen gegen Rüstungen

Messung: `sim_forge_quality.gd 2000 1 0`. Trefferquote 90 %, Schwierigkeit „Normal“. In Klammern: Anteil ≥ R6 / ≥ R7 / R8.

| Spielerstand | Barren | Schwert, Zweihänder, Bogen, Stab | Schild | Helm, Brust (Leder R1) | Helm, Brust (Leder wie Barren) | Umhang (Leder wie Barren) |
|---|---|---|---|---|---|---|
| keine Skills | R1 | R3.14 | R2.68 | R2.07 | – | R1.46 |
| keine Skills | R2 | R4.13 | R3.68 | R2.58 | R3.08 | R2.46 |
| keine Skills | R4 | R6.12 (81 / 0 / 0) | R5.68 | R3.60 | R5.08 | R4.46 |
| Meisterhand 3 | R1 | R3.88 | R3.22 | R2.44 | – | R1.68 |
| Meisterhand 3 | R4 | R6.88 (100 / 38 / 0) | R6.23 | R3.95 | R5.46 (30 / 0 / 0) | R4.67 |
| + Härtekunst 5 | R1 | R4.38 | R3.73 | R2.70 | – | R1.68 |
| + Härtekunst 5 | R4 | R7.37 (100 / 73 / 0) | R6.75 | R4.19 | R5.71 (37 / 0 / 0) | R4.67 |
| + Amboss 6 %, Handschuhe 5 % | R1 | R4.54 | R3.86 | R2.77 | – | R1.72 |
| + Amboss 6 %, Handschuhe 5 % | R4 | R7.56 (100 / 93 / 6) | R6.85 | R4.28 | R5.80 (36 / 0 / 0) | R4.72 |

Trefferquote: 70 % kostet gegenüber 90 % rund 0,3–0,45 Stufen, 100 % bringt +0,15–0,25. Der Abstand Waffe gegen Rüstung ändert sich dadurch kaum.

**Woher der Unterschied kommt** (Punkte, 100 = eine Stufe; g = Qualitätsgewinn, q = Härtekunst):

| Schritt | Waffe (Klinge + Griff) | Schild | Rüstungsteil (Platte + Leder) | Umhang |
|---|---|---|---|---|
| Guss | 50 | 50 | 50 (nur die Platte) | – |
| Amboss, alles grün | +80 × (1+g) | +80 × (1+g) | +80 × (1+g) (nur die Platte) | – |
| Abkühlen | +q | +q | +q (nur die Platte) | – |
| Zusammenbau: Vererbung | beide Teile gleich, nichts geht verloren | nichts geht verloren | **Qualität = Schnitt mit dem Leder (0): halbiert. Seltenheit = Zufall zwischen Leder und Platte: im Schnitt −50 je Stufe Abstand** | nur Leder |
| Werkbank perfekt | +50 × (1+g) | +50 × (1+g) | +50 × (1+g) | +50 × (1+g) |
| Schleifstein | +50 × (1+g) | **–** | **–** | **–** |
| Summe ohne Skills, Barren R1 | 230 (R3.30) | 180 (R2.80) | 115 (R2.15) | 50 (R1.50) |

Drei Ursachen: (1) kein Schleifstein für Rüstung (−50 bis −78), (2) das Leder halbiert die Qualität der Platte und zieht die Seltenheit zu sich herunter, (3) Leder gibt es fast nur in R1–R2 (Monster-Drop, R2 zu 35 %) und nichts hebt seine Seltenheit außer dem Skill „Gerber“. Meisterhand und Härtekunst vergrößern den Abstand, weil sie auf mehr Schritte der Waffe wirken: ohne Skills 115 Punkte Abstand, mit allem 180–190. Die Zahl der Teile und die 2 Barren der Brustplatte spielen keine Rolle (Brust = Helm, Zweihänder = Schwert), solange alle Barren dieselbe Seltenheit haben.

**Wie früh R6/R7-Waffen möglich sind:**

- Schwarzmarkt in Leonheim (`black_market.tscn`, Händler Vex): `iron_ingot@R3-R4`, `bronze_ingot@R3-R4`. Preis nach `Economy.get_buy_price`: Eisen R4 = 10 × 1,75 × 1,25 = 22 Gold. Leonheim erreicht man laut `sim_progress` an Tag 30–35 (rund 5 Stunden Spielzeit). Zwei Barren, ohne Skills: R6.12, 81 % ≥ R6. Mit Meisterhand 3 (Spieler Lv 5 schon in Kapitel 5): 38 % R7.
- Alte Dungeons auf ×5 (Frage 9): Kupferbarren R4–R5.
- Mondglanz-Trank (Frage 9): jede Seltenheit, auch für Rüstung.

**Vorschläge (Paket 4), gemessen mit den Varianten des Skripts** (`... 1000 1 0 <gewinn> <abkühlen> <variante>`, 90 % Treffer):

| Variante | Barren | Schwert | Schild | Helm (Leder R1) |
|---|---|---|---|---|
| heute, alle Skills (Gewinn 56 %, Abkühlen 50) | R1 / R4 | R4.54 / R7.56 | R3.86 / R6.85 | R2.77 / R4.28 |
| A: Leder zählt nicht für die Seltenheit, wenn eine Platte dabei ist (wie Holz), und Rüstung darf einmal poliert werden (wie Schärfen) | R1 / R4 | R4.57 / R7.54 | R4.54 / R7.56 | R4.56 / R7.54 |
| B: schwächere Skills (Meisterhand 8 % statt 15 % pro Stufe, Härtekunst 5 statt 10; Gewinn 35 %, Abkühlen 25) | R1 / R4 | R3.97 / R6.97 | R3.37 / R6.36 | R2.51 / R4.01 |
| A + B | R1 / R3 / R4 | R3.97 / R5.97 / R6.97 | R3.95 / R5.97 / R6.97 | R3.96 / R5.98 / R6.98 |
| B, nur „Leder zählt nicht“ (ohne Polieren) | R1 / R4 | R3.98 / R6.97 | R3.37 / R6.37 | R3.36 / R6.37 |

Mit A + B und Schwarzmarkt nur noch R2–R3: beste Waffe und beste Rüstung aus gekauften Barren R5.97 (61 % ≥ R6, 0 % R7). R7 braucht dann R4-Barren, die es nur noch aus schweren Modi gäbe; R8 braucht R5-Barren. Das trifft „R6–R7 als Höhepunkt später Kapitel, R8 seltenes Endziel, Waffe und Rüstung gleich schwer“.

### Frage 8: Werkstatt-Upgrades und Schmied-Skills

**Skillpunkte:** 1 pro Spieler-Level, Höchstlevel 50, also 49 Punkte. Alle 19 Skills zusammen haben 64 Stufen: man hat nie alles. Am Story-Ende ist der Spieler Lv 34–37 (`sim_progress`), also 33–36 Punkte. Zurücksetzen kostet 50 Gold pro Punkt.

| Skill | pro Stufe | Stufen | ab Lv | Nutzen (M = gemessen mit sim_forge_quality, R = gerechnet, A = Annahme) | Urteil |
|---|---|---|---|---|---|
| Meisterhand | +15 % Qualitätsgewinn, Schleif-Minispiel leichter | 3 | 2 | M: Waffe +0,74 Stufen, Rüstung +0,37 | Pflicht, zu früh und zu stark |
| Härtekunst | +10 Qualität pro abgekühltem Teil | 5 | 5 | M: Waffe +0,50, Rüstung +0,26 | sehr stark |
| Materialkunde | Metall zählt 1 Stufe leichter | 1 | 10 | M: +0,55 Stufen, wenn das Metall über dem Rang liegt, sonst nichts | Pflicht ab Silber |
| Gefolgschaft | +1 Dungeon gleichzeitig | 2 | 4 | R: +1 Gruppe = mehr PEXP und Beute; `sim_progress` rechnet mit beiden Stufen | Pflicht |
| Ruhige Hand, gutes Auge | Amboss-Zonen +1 Punkt (Grundwert 5) | 5 | 1 | A: grüne Zone bis doppelt so breit, wirkt über die Trefferquote (70 » 90 % = +0,3–0,45 Stufen) | stark, nicht messbar |
| Passgenau | Werkbank-Zone +0,5 Punkte | 5 | 2 | A: wie oben, nur ein Schritt (+50 Punkte) | mittel |
| Gerber | Leder +1 Seltenheit beim Gerben | 1 | 4 | R: Rüstung im Schnitt +0,5 Stufen (halber Stufen-Abstand) | einziger Rüstungs-Skill, lohnt |
| Feldschmied | +5 Helden-Leben für Helden, die nur selbst geschmiedete Ausrüstung tragen (ob Prozent oder Punkte, habe ich nicht geprüft) | 3 | 5 | nicht gemessen | unklar |
| Meisterwerk | Sockel-Chance +10 % (Grund 35 %) | 3 | 10 | nicht gemessen | Geschmack |
| Feuerprobe / Formenbauer | 5 % Chance auf einen Barren / Rohling mehr | 3 / 3 | 3 | R: +5–15 % Material | schwach |
| Goldene Zunge / Verkaufstalent / Oma-Nichte | +5 % Gold | 3 / 5 / 2 | 3–4 | R: +15–25 % Einkommen aus einer Quelle | schwach bis mittel |
| Glücksfund | +3 % seltene Funde beim Abbau | 5 | 1 | R: 5 % » 20 % R2-Erz | mittel, früh |
| Kräftiger Schlag, Flinker Hammer, Glutwächter, Pflanzen pflücken | Komfort | | | | lohnt für Qualität nie |

Der Qualitäts-Kern (Meisterhand 3, Härtekunst 5, Materialkunde 1 = 9 Punkte) ist mit Spieler-Lv 10 komplett, also mitten in Teil 2.

**Werkstatt-Upgrades** (`house.json`):

| Upgrade | Kosten (Gold + Material) | Wirkung | ab | Urteil |
|---|---|---|---|---|
| Amboss 1 / 2 | 2.000 + 10 Eisen / 6.000 + 10 Bronze, 20 Kohle | +2 % / +4 % Qualitätsgewinn | sofort / Bronze | M: +11 % (Amboss 6 % + Handschuhe 5 %) bringen +0,16 Stufen. Ein Amboss-Schritt von 2 % sind rund 0,03 Stufen. Lohnt nie. |
| Amboss 3 | 15.000 + 10 Silber, 5 Gold | +6 % | Schmiedeturnier gewonnen | wie oben |
| Amboss 4 | 40.000 + 10 Platin, 1 Sternenstahl | +9 % | nach der Story | Trophäe |
| Schmelze 1 / 2 / 3 | 1.500 / 5.000 / 14.000 | +15 / 30 / 50 % Tempo, je +1 Platz | sofort / sofort / nach dem Drachen | R: Stufe 1 verdoppelt den Durchsatz. Lohnt früh. |
| Esse 1 / 2 / 3 | 1.500 / 5.000 / 16.000 | +20 / 40 / 75 % Güsse pro Brennstoff | wie Schmelze | A: Kohle ist billig, lohnt kaum |
| Haus 2–5 | 1.500 / 2.500 / 7.500 / 25.000 | Platz, eigene Verkaufstische | Ruf-Rang E / D / C | Verkauf nicht simuliert |

**Gold pro Tag gegen Kosten** (gerechnet, nicht simuliert; Annahmen: Auftrag = Schwert im Metall des Kapitels nach der Formel in `Economy`, alle Aufträge des Tages erledigt, Kunden pro Tag nach Ruf-Rang, Auftrags-Arten im Schnitt ×1,1):

| Kapitel | Metall | Gold pro Auftrag | Aufträge pro Tag | Einkommen pro Tag | Dungeon-Kosten pro Tag (`sim_progress`, gemessen) |
|---|---|---|---|---|---|
| Teil 1 | Kupfer | 96 | 1–2 | rund 160 | 76 |
| Teil 2 | Eisen, Bronze | 125–155 | 2–2,5 | 290–465 | 490–550 |
| Teil 3–4 | Silber, Gold | 200–265 | 3–3,5 | 760–1.200 | rund 1.500 |
| Teil 5–6 | Gold, Platin | 265–345 | 3,5–4 | 1.200–1.900 | rund 2.500 |
| Teil 7–8 | Palladium | 455 | 4 | rund 2.500 | rund 3.600 |

Miete: 300 Gold alle 14 Tage, ab Teil 2 ohne Bedeutung. Dungeon-Kosten bis zum Ende: 120.000–143.000 Gold bei 6.000–8.000 Gold Beutel-Beute (gemessen). Wer alle Gruppen dauernd schickt, zahlt ab Teil 2 mehr, als Aufträge bringen. Laden-Verkäufe, verkaufte Beute und Turniere fehlen in der Rechnung, deshalb ist das eine offene Frage und kein Befund.

**Vorschläge (Paket 4):** Meisterhand 15 % » 8 % pro Stufe und ab Lv 6 statt 2; Härtekunst 10 » 5; Amboss-Upgrades 2 / 4 / 6 / 9 % » 5 / 10 / 15 / 20 %. Dann trägt die Werkstatt (Gold) etwa so viel wie die Skills (Punkte): alles zusammen Gewinn 24 % + 15 % + 5 % = 44 % statt heute 56 %, davon ein Drittel aus dem Amboss. Wirkung auf die Seltenheit: siehe Zeile B in Frage 7 (dort mit 35 % gerechnet; 44 % liegt rund 0,15 Stufen darüber).

### Frage 9: Exploits, nach Auswirkung

| # | Kombination | Auswirkung | Beleg |
|---|---|---|---|
| 1 | **Mondglanz-Trank ohne Grenze** (3 Mondlilien, +100 Qualität bei R1, +15 pro Seltenheit der Lilie; `Enchanting.use_potion` prüft nur „schon R8 Q100“) | jedes Teil, auch Rüstung und Schmuck, auf R8. 7 Tränke von R1. Mondlilie: 7 Tage, mit Asche und Gießen deutlich kürzer; Pflanztopf bis 16 Felder; Samen bei der Kräuterhändlerin und am Schwarzmarkt. Hebelt die ganze Schmiede-Kurve aus. | Regel gelesen, nicht simuliert |
| 2 | **Schwarzmarkt-Barren R3–R4 + Schleifstein (+ Meisterhand)** | R6–R7-Waffen ab Tag 30–35 für rund 45 Gold | gemessen (Frage 7) |
| 3 | **Alte Dungeons auf ×5 mit späteren Helden** | Rattenkeller, Rattennest (Eisen, Lv 15–21) und Wolfshöhle (Bronze, Lv 25) ×5: 100 % Siege (30 Läufe). Pro Lauf sicher 3 Kupferbarren R4 (65 %) oder R5 (35 %), alle Drops mindestens R3, PEXP ×3, für 10–40 Gold. Dagegen: Gosse ×3 mit Bronze und ×5 mit Silber 0 %, Aschegänge ×5 mit Platin 0 %. Das Loch sind nur die auf Bruno allein eingestellten Dungeons. | gemessen |
| 4 | **Meisterhand + Härtekunst + hoher Rang + leichtes Material** | +1,24 Stufen auf jede Waffe für 8 Skillpunkte, ab Spieler-Lv 9. Mit R5-Barren aus #3: Kupfer-R8. | gemessen |
| 5 | **Beschwörer + zwei Beschwörungs-Ringe** | Endspiel 85–95 % bei Monstern ×1,8, wo der Elementarist mit Ringen 38–75 % hat | gemessen (Frage 3) |
| 6 | **Zwei Heiler + Krieger** | Priester + Segens-Paladin: 99 % normal, 62 % bei ×1,3 (nächstbeste Gruppe ohne zweiten Heiler 39 %). Heilung + Rüstung ist die sicherste Gruppe, aber langsam. | gemessen (Frage 5) |
| 7 | **Kupfer R2 statt Eisen R1** | gewollt („besser schmieden ist der zweite Weg“), aber sehr stark: Kanalisation 86 % gegen 86 % | gemessen |
| 8 | **Schnelles Leveln + frühe starke Skills** | Teil 3–4: 5–13 Level über den Dungeons; kein einzelner Skill fällt auf | gemessen (Frage 2) |
| 9 | **Schwere Modi + seltene Barren im Dungeon der eigenen Stufe** | kein Exploit: ×2 braucht einen Satz R7, ×3 ist auch damit nicht zu schaffen | gemessen (Frage 6) |
| 10 | **Verzauberung + Sockel** | unbekannt, der Simulator kennt beides nicht | nicht gemessen |

Vorschläge: #1 jedes Item nur einmal (Merker am Item wie `sharpened`, muss gespeichert werden, Regel 1) oder Trank nur bis zur Seltenheit der Mondlilie. #2 Schwarzmarkt auf R2–R3 und Preis nach Seltenheit stärker staffeln. #3 schwere Modi geben Boss-Barren im Erz des Helden-Fortschritts nicht, sondern bleiben beim Dungeon-Erz, aber Rattenkeller, Mine und Wald bekommen für ×2–×5 einen eigenen Faktor für drei Helden (oder die Seltenheits-Verschiebung gilt erst ab Dungeon-Level 12).

### Frage 10: Blocker

**Was es im Vulkan schon gibt:** Aschegänge (Boss Magmaschläger), Magmahallen (Boss Salamanderkönigin, Zwischenboss Obsidianwächter), Schmiede des Lavagolems (Story-Sperre für das Kronen-Rezept, Boss Lavagolem mit 7.150 Leben nach Faktor), Drachenkammer (Ignar, der Glutdrache, Lv 36, zwei Lebensbalken, ruft Glutgeister; Story-Sperre am Ende von Teil 2). Dazu Glutdrachlinge als normale Gegner. In `enemies.json` liegt außerdem ein ungenutzter „Drache“ (Lv 50).

**Befund:** Der Vulkan hat seinen Feuerdrachen schon, und der ist mit Bronze eher zu schwer (58 %). Zu leicht ist der Weg dorthin, aber nur für das alte Erz: Aschegänge, Magmahallen und Lavagolem gehen mit Eisen zu 62–71 %. Der Vulkan verlangt also keine Bronze, bis der Drache kommt, und dann steht man vor einer Wand (Eisen 4 %).

**Vorschlag Vulkan:**

1. Erst die Faktoren richten (Tabelle in 2.2): Aschegänge etwa 1,9, Magmahallen etwa 1,8, Lavagolem etwa 1,4, Drachenkammer 1,2 (gemessen 83 / 13).
2. Feuerdrache als **Zwischenboss in den Magmahallen**, Stufe 6 (statt Obsidianwächter + Salamander), nicht als neue Story-Sperre. Name z. B. „Glutschwinge, Ignars Brut“: ein junger Drache, der zeigt, was am Ende wartet. Werte als Ausgangspunkt (vor Faktor): Lv 28, Leben 520–580 (Salamanderkönigin als Maß), Schaden 12–16 Feuer, Rüstung 22, Magieresistenz 16, Angriff alle 1,6 s, Skills `lava_bite` und `fireball`, Feuer-Resistenz 100, Eis −30. Ziel für den ganzen Dungeon: Bronze 75–85 %, Eisen höchstens 35 %. Die Werte sind ein Vorschlag, keine Messung; mit `sim_party.gd tune volcano_magma_halls` einstellen.
3. Als Story-Blocker würde ich ihn nicht bauen: Lavagolem und Ignar sperren schon zweimal.

**Andere Kapitel, je höchstens ein Vorschlag, nur wo messbar zu leicht:**

| Kapitel | Messung | Vorschlag |
|---|---|---|
| Teil 3, Sturmgipfel | 94–96 % mit Silber, Bergfuß 74 % mit Bronze, Helden 5–13 Level darüber, keine Story-Sperre im ganzen Teil | Sturmschwinge (Greif im Horst) als Bedingung für das Schmiedeturnier oder die Abreise; Dungeon-Level auf 37–41 |
| Teil 5, Sumpf I | 97 / 94 | Faktor etwa 2,6; kein neuer Boss nötig, Sumpf II und III haben welche |
| Teil 6, Eisquell brennt und Eisfälle | 95 / 90 und 99 / 93 | Faktor etwa 2,5 und 1,9; der Hafen-Angriff sollte sich wie eine Schlacht anfühlen, ein Elite-Schütze als Zwischenboss in Stufe 5 |
| Teil 7, Finster-Asche | 95 / 80 | Faktor 3,2 (gemessen 73 / 35) |
| Teil 8, Altar-Tor und Altar Ost | 98 / 99 und 98 / 85 | Torwächter: Faktor hoch, bis Platin unter 50 % fällt |
| Nach der Story, Unterwelt | 100 % für jede Gruppe, auch ohne Heiler | komplett neu einstellen (Leben-Faktor 3,0 / 2,6, Schaden 2,6 / 1,25 passen nicht) |

Teil 1, 2 (Leonheim) und 4 sind nicht zu leicht; dort keine neuen Blocker.

---

## 3. Umsetzungs-Pakete

Reihenfolge: erst Grundlagen, weil jedes spätere Paket auf den Siegquoten des vorigen aufbaut. Nach jedem Paket die Tabelle 2.1 neu messen.

| # | Branch | Inhalt | Dateien | Simulator vorher / nachher | Tests |
|---|---|---|---|---|---|
| 1 | `feature/balancing-erholung` | Pause nach jeder Stufe (`stage_rest_heal` 0,2), Heiltränke für Helden (Mörser-Rezept, 2 Plätze pro Held, trinkt unter 35 %); danach alle Dungeons ab Leonheim per `autotune` auf 80 %; Faktoren aus 2.2; Level von Sturmgipfel, Wasser, Kompass; Unterwelt | `combat.json`, `scripts/systems/adventure.gd`, `combatant.gd`, `hero.gd` (Trank-Plätze, speichern: Regel 1), `mortar.json`, `items.json`, `dungeons.json`, Heldenfenster | `sim_balance.gd healer`, `sim_party.gd` (alle), `sim_progress.gd` | `_lib/test_save_roundtrip.gd` (Tränke am Helden), Gruppe `kampf`; `sim_party.gd` und `sim_balance.gd` brauchen die Regel selbst (heute nur als Variante `rest=`, `potions=`) |
| 2 | `feature/balancing-ohne-heiler` | Dauer-Erholung für Klassen ohne Heiler im Endspiel: Heil-Skills von Krieger und Waldläufer skalieren mit dem Hauptattribut, Lebensraub und Schilde wachsen mit; Ziel: Abstand zum Priester 15–25 Punkte auch in Teil 6–8 | `skills.json`, `status_effects.json`, `skill_data.gd` (Skalierung für Heilung), `docs/SKILLBAEUME.md` | `sim_balance.gd healer`, `trees` | `balancing/test_skill_scaling.gd`, `test_skill_trees.gd` |
| 3 | `feature/balancing-klassen` | Beschwörer: Golem 30 % +8, Fürst 60 % +8, Ring 8 » 5; schwache Bäume (Segens-Priester, Arkanist, Schurke Schatten/Gift) anheben; Arena getrennt | `skills.json`, `items.json` (jewel), `summons.json`, `arena.json` | `sim_balance.gd summoner`, `trees`, `sim_duels.gd` (neue `duels.md`) | `test_skill_trees.gd`, `jewelry/test_metal_jewelry.gd` |
| 4 | `feature/balancing-schmiede` | Mondglanz-Trank begrenzen; Schwarzmarkt R2–R3; Leder zählt nicht für die Seltenheit, Rüstung polieren; Meisterhand 8 %, ab Lv 6; Härtekunst 5; Amboss 5 / 10 / 15 / 20 %; Metall-Sprünge ab Gold; schwere Modi der Bruno-Dungeons | `enchanting.gd`, `inventory_slot.gd` (Merker, speichern), `forge_quality.gd`, `sharpening.gd`, `economy.json`, `house.json`, `data/player_skills/master_hand.tres` u. a., `black_market.tscn`, `items.json`, `combat.json` (`hard_modes`), `dungeons.json` | `sim_forge_quality.gd` (alle Zustände), `sim_party.gd` (Metall-Sprünge), `sim_balance.gd run ... stress=5` für alte Dungeons | `material_tiers/test_material_tiers.gd`, `hard_modes/test_hard_rarity.gd`, `test_hard_modes.gd`, `balancing/test_buy_above_sell.gd`, Speicher-Rundlauf; Turnier-Gegner und Kunden-Seltenheiten neu abstimmen (stehen schon in `PROBLEME.md`) |
| 5 | `feature/balancing-blocker` | Glutschwinge in den Magmahallen, Sturmschwinge als Bedingung in Teil 3, Elite im Hafen | `enemies.json`, `dungeons.json`, Story-Dateien, Grafik (PixelLab, `PIXELLAB_TODO.md`) | `sim_party.gd tune <dungeon>` | `check_beats.py`, Gruppe `story`, `kern` |

Zu den Simulatoren selbst (kleines Vorab-Paket, `fix/sim-levelaufstieg`): Fehler beim Levelaufstieg im Simulator beheben; `sim_party.gd` TIERS für den Sumpf auf Gold stellen; `classes` in `sim_party.gd` ist nutzlos (alles 100 %, Bronze in einem Eisen-Dungeon) und kann durch `sim_balance.gd trees` ersetzt werden; Simulatoren Schmuck und Verzauberungen beibringen.

---

## 4. Offene Fragen an dich

1. **Heiler:** Sind Heiltränke im Kampf und eine Pause zwischen den Stufen gewollt? Das sind zwei neue Regeln, keine Zahlen-Änderung. Ohne eine neue Quelle für Leben ist das Ziel „ohne Heiler höchstens 15–25 Punkte schlechter“ mit den vorhandenen Hebeln nicht erreichbar (gemessen: Monster-Schaden −20 % und Regeneration ×2,5 bringen nichts).
2. **Heiler im Endspiel:** Soll das Ziel auch für Teil 6–8 gelten? Dann braucht es Paket 2, und das ändert Skills mehrerer Klassen.
3. **Beschwörer:** Soll er im Endspiel gleichauf mit dem Elementaristen liegen (dann Anteil aller Beschwörungen ×0,75) oder ein Stück darüber bleiben (nur Golem und Fürst)? Oder lieber den Elementaristen anheben?
4. **Mondglanz-Trank:** einmal pro Item, nur bis zur Seltenheit der Lilie, oder ganz streichen?
5. **Schwarzmarkt:** R2–R3 statt R3–R4, oder R3–R4 behalten und sehr teuer machen (Geldsenke fürs späte Spiel)?
6. **Rüstung:** Darf Rüstung einen eigenen Schritt wie das Schärfen bekommen („Polieren“ am Schleifstein), oder soll stattdessen die Waffe ihren Schleif-Bonus verlieren? Und soll Leder die Seltenheit weiter mitbestimmen (dann braucht es eine Quelle für seltenes Leder)?
7. **Meisterhand:** schwächen (8 %) oder nur später freigeben (z. B. Lv 10 / 20 / 30 je Stufe)?
8. **Rattennest (33 % mit Bruno Lv 7):** bekannt wegen des Regenerations-Sprungs bei 10 Konstitution. Soll das die erste Wand bleiben?
9. **Kupfer R2 = Eisen R1:** Der feste Bonus +2 pro Seltenheit ist früh sehr stark und spät fast nichts. Soll die Seltenheit prozentual wirken (z. B. +8 % pro Stufe)? Das wäre ein großer Hebel und verschiebt alle Siegquoten.
10. **Gold:** Sollen Dungeon-Gebühren das Auftrags-Einkommen übersteigen dürfen? Ich habe das Einkommen nur gerechnet. Wenn es wichtig ist, schreibe ich `sim_economy.gd` (Aufträge, Laden, Beute-Verkauf gegen Gebühren und Ausbau).
11. **Sumpf:** Der Simulator nimmt Platin an, das Spiel gibt dort Gold. Mit Gold steht Sumpf III bei 5 %. Ist der Nebelfürst als Neben-Herausforderung gedacht (dann passt es), oder soll er mit Gold machbar sein?

---

## 5. Umsetzung (2026-11-15, Branch `feature/balancing-umsetzung`)

Nach deinen Entscheidungen zu den Problemen 1–6, 8 und 10. Alle Zahlen unten sind nach der Umsetzung gemessen.

### 5.1 Was geändert wurde

| Problem | Entscheidung | Umsetzung |
|---|---|---|
| 1 Heiler ist Pflicht | jede Klasse eine kleine Heil-Mechanik | **Klassen-Instinkt** (combat.json `class_instinct`), wächst mit dem Heldenlevel (Level 1: 35 %, Level 35: 100 %, danach weiter). Werte bei Level 35: Krieger Lebensraub 6 %, Zweiter Atem 40 %, Verschnaufen 15 %; Paladin Regeneration 0,3 %/s, Zweiter Atem 20 %, Verschnaufen 12 %; Magier Skill-Lebensraub 8 %, Zweiter Atem 30 %, Verschnaufen 20 %; Waldläufer Heilung beim Sieg 5 %, Zweiter Atem 30 %, Verschnaufen 20 %; Schurke Heilung beim Sieg 6 %, Zweiter Atem 30 %, Verschnaufen 15 %; Priester Regeneration 0,3 %/s, Verschnaufen 10 %. „Zweiter Atem“ = einmal pro Stufe unter 35 % Leben; „Verschnaufen“ = nach jeder geschafften Stufe. |
| 2 Mondglanz-Trank | nur einmal | Merker am Teil, gespeichert |
| 3 Schwarzmarkt | sehr teuer | Eisenbarren R3 / R4: 2.250 / 2.625 Gold, Bronze 3.750 / 4.375 (vorher rund 20–40). Ein Schwert aus R4-Eisen kostet damit über 5.000 Gold. |
| 4 Rüstung | wie Schleifstein, für Rüstung | Rüstung wird am Schleifstein einmal poliert (gleiche Punkte wie Schärfen); Leder zählt bei Teilen mit Platte nicht mehr für Seltenheit und Qualität. Kein eigener Tisch, siehe offene Punkte. |
| 5 Beschwörer | im späten Spiel schwächer | Erdgolem 30 % (+8 %) statt 40 % (+10 %), Elementarfürst 60 % (+8 %) statt 80 % (+10 %), Ring „Beschwörungs-Schaden“ 5 statt 8. Mana-Kosten habe ich nicht erhöht: das war gemessen wirkungslos (Abschnitt Frage 3). |
| 6 altes Erz reicht | spätere Dungeons schwerer | Gold ×1,09, Platin ×1,17, Palladium ×1,26 stärker; alle 50 Dungeons neu eingestellt |
| 8 Meisterhand | später | Stufe 1 / 2 / 3 ab Spieler-Level 10 / 15 / 20; Amboss-Upgrades 5 / 10 / 15 / 20 % |
| 10 Level | anpassen | Sturmgipfel 36 / 38 / 40, Wasser 39–42, Kompass 41–42, Sumpf I / II 42 / 43; Unterwelt neu eingestellt |

### 5.2 Siegquoten danach

`sim_party.gd 40`, drei Durchgänge (120 Kämpfe je Zelle). Ziel: Erz der Stufe 75–90 %, Erz davor höchstens 35–50 %.

| Dungeon (Level) | Erz der Stufe | Sieg % | Erz davor R1 | Erz davor R2 |
|---|---|---|---|---|
| rat_cellar (1) | copp | 100 | – | – |
| rat_cellar_deep (3) | copp | 73 | – | – |
| rat_nest (7) | copp | 73 | – | – |
| mine_tunnels (7) | copp | 66 | – | – |
| forest_edge (8) | copp | 86 | – | – |
| forest_thicket (10) | copp | 75 | – | – |
| forest_den (13) | copp | 68 | – | – |
| capital_sewers (12) | iron | 87 | 80 | 83 |
| gutter_alleys (14) | iron | 76 | 2 | 39 |
| capital_catacombs (15) | iron | 77 | 21 | 72 |
| gutter_warehouse (16) | iron | 83 | 0 | 34 |
| capital_crypt (18) | iron | 74 | 18 | 35 |
| gutter_tavern (18) | iron | 67 | 0 | 24 |
| gutter_nest (20) | iron | 75 | 12 | 46 |
| capital_crypt_cursed (22) | iron | 84 | 51 | 59 |
| volcano_ash_tunnels (25) | bron | 81 | 59 | 66 |
| volcano_magma_halls (28) | bron | 80 | 63 | 69 |
| volcano_golem_forge (30) | bron | 69 | 46 | 62 |
| dragon_lair (36) | bron | 87 | 26 | 43 |
| mountain_foot (36) | silv | 77 | 27 | 64 |
| mountain_slope (38) | silv | 93 | 23 | 28 |
| mountain_summit (40) | silv | 88 | 24 | 39 |
| water_coast (39) | silv | 74 | 8 | 17 |
| water_cave (40) | silv | 78 | 15 | 19 |
| water_grotto (41) | silv | 65 | 9 | 18 |
| water_deep_grotto (42) | silv | 79 | 5 | 9 |
| compass_foundry (41) | silv | 80 | 35 | 53 |
| compass_obsidian (42) | silv | 83 | 3 | 7 |
| compass_windcave (42) | silv | 73 | 4 | 12 |
| compass_roots (41) | silv | 86 | 38 | 66 |
| swamp_mire (42) | gold | 84 | 62 | 72 |
| swamp_bones (43) | gold | 73 | 37 | 60 |
| swamp_hydra (44) | gold | 80 | 0 | 28 |
| dark_keep (45) | gold | 79 | 50 | 69 |
| eisquell_burning (46) | plat | 76 | 60 | 67 |
| ice_falls (47) | plat | 77 | 39 | 51 |
| ice_bridges (48) | plat | 80 | 48 | 55 |
| ice_windbreak (49) | plat | 71 | 34 | 38 |
| ice_wall_lake (50) | plat | 80 | 61 | 70 |
| finster_ash (51) | pall | 79 | 46 | 47 |
| finster_canals (52) | pall | 83 | 47 | 50 |
| finster_towers (53) | pall | 75 | 25 | 43 |
| star_crater (54) | pall | 79 | 25 | 26 |
| altar_gate (55) | pall | 65 | 27 | 38 |
| altar_north (55) | pall | 80 | 46 | 59 |
| altar_east (58) | pall | 74 | 44 | 50 |
| altar_south (57) | pall | 74 | 49 | 54 |
| altar_west (56) | pall | 80 | 60 | 63 |
| altar_lake (59) | pall | 74 | 56 | 58 |
| underworld_road (62) | pall | 74 | 46 | 58 |
| underworld_tower (65) | pall | 86 | 36 | 41 |

- Erz der Stufe: 65–93 %, 42 von 51 Dungeons zwischen 70 und 88 %.
- Erz davor: ab den Wasser-Dungeons fast überall unter 50 % (vorher 53–99 %). Noch darüber: Kanalisation 80 % (als Einstieg gewollt), Vulkan I–II 59–63 % (Feuer-Schaden, Platten bis Bronze haben keine Magieresistenz), Sumpf I 62 %, Eisquell brennt 60 %, Mauerkrone 61 %, Altar West 60 %.
- Die Dungeons aus Teil 1 sind jetzt auf 66–86 % für Bruno allein eingestellt (vorher 80–98 %, Rattennest 33 %), weil die Instinkte auch ihm helfen.

**Mit und ohne Heiler** (`sim_balance.gd healer 30 <seed>`, Seeds 1–3, Schnitt je Kapitel):

| Kapitel | Krieger + Priester + Magier | Krieger + Segens-Paladin + Magier | Krieger + Magier + Magier | Krieger + Magier + Waldläufer | Bollwerk-Paladin + Magier + Waldläufer | Paladin + Waldläufer + Schurke |
|---|---|---|---|---|---|---|
| Leonheim | 78 | 89 | 49 | 75 | 64 | 85 |
| Vulkan | 76 | 62 | 20 | 30 | 27 | 28 |
| Sturmgipfel | 81 | 92 | 57 | 61 | 65 | 58 |
| Wasser | 73 | 92 | 50 | 38 | 37 | 22 |
| Kompass | 82 | 95 | 69 | 67 | 65 | 57 |
| Sumpf, Bergfried | 77 | 87 | 30 | 23 | 21 | 19 |
| Eis | 76 | 90 | 69 | 55 | 57 | 27 |
| Finsterstadt | 81 | 93 | 88 | 48 | 53 | 25 |
| Altar | 77 | 96 | 79 | 50 | 58 | 10 |

Vorher lag jede Gruppe ohne Heiler ab dem Vulkan bei 0–4 %. Jetzt liegt die jeweils beste bei 30–88 %, der Abstand zur Priester-Gruppe bei 0–25 Punkten, außer im Vulkan und im Sumpf (rund 45 Punkte, dort entscheiden lange Boss-Kämpfe).

**Beschwörer gegen Elementarist** (Monster ×1,3, 30 Kämpfe): Sumpf I 30 gegen 27, Eisbrücken 0 gegen 10, Finster-Kanäle 10 gegen 10, Altar Süd 13 gegen 13 (vorher 48–70 gegen 8–30). Die Beschwörungen machen noch 29–43 % des Gruppenschadens.

**Story-Tempo** (`sim_progress.gd trio 0 1`): Spielende an Tag 92 (vorher 96–106), 828 Läufe, 53 verloren. Helden am Ende von Teil 3: Level 41 bei Dungeons 36–40 (vorher 29–35), Teil 4: 46 bei 39–42.

### 5.3 Was offen bleibt

- **Segens-Paladin als Heiler ist jetzt stärker als der Priester** (87–96 % gegen 73–82 %). Er hat Instinkte und Heilung zugleich. Ich habe seine Instinkte schon gesenkt; mehr geht nur über seine Skills oder einen stärkeren Priester.
- **Leonheim ohne Heiler** (Paladin + Waldläufer + Schurke 85 %) ist dort etwas stärker als mit Priester (78 %).
- **Vulkan und Sumpf ohne Heiler** bleiben schwer (20–30 %).
- **18 Bäume als dritter Held** (Seed 1, 30 Kämpfe, normal / Monster ×1,3): oben Paladin Segen 98 / 48, Tierfreund 97 / 35, Priester Licht 89 / 32, Natur 91 / 27; unten Segens-Priester 55 / 2, Schurke Schatten 62 / 4, Beschwörer (Baum-Reihenfolge mit Opfern) 64 / 3, Arkanist 67 / 3. Die schwachen Bäume habe ich nicht angefasst (Paket 3 im Plan).
- **Alte Dungeons auf ×5:** Rattenkeller, Rattennest und Wolfshöhle gewinnt eine Eisen-Gruppe Level 15–27 weiter zu 100 % (3 Kupferbarren R4–R5 pro Lauf). Nicht behoben.
- **Blocker** (Feuerdrache in den Magmahallen, Bedingung in Teil 3): nicht gebaut, das braucht Story-Daten und Grafik.
- **Eigener Poliertisch:** Polieren läuft am Schleifstein. Ein eigener Tisch wäre eine neue Station mit Grafik, Kauf und Aufstellen.
- **Nicht im Spiel ausprobiert:** alles ist nur per Simulator und Headless-Test geprüft. Die Simulatoren kennen weiter keine Verzauberungen und Sockel.
- **Alte Spielstände:** wer Meisterhand schon hat, behält sie; Teile ohne Mondglanz-Merker können den Trank noch einmal bekommen; vorhandene Gold-, Platin- und Palladium-Teile sind sofort stärker, die Dungeons sofort schwerer.

---

## 6. Nachtrag (2026-11-16, Branch `feature/balancing-rest`)

Entscheidungen zu 5.3: Segens-Paladin schwächer; schwache Bäume „etwas anheben, es darf schwächere geben“; alte Dungeons auf ×5 und die Blocker (Glutschwinge, Sturmschwinge) bleiben, wie sie sind.

### 6.1 Neu gemessen nach Poliertisch, Beute und Leder je Stufe

Seit `feature/poliertisch-und-beute` tragen die Helden im Simulator das Leder ihrer Stufe (`HeroBuilder.leather_for`: Sumpf-, Flechten-, Höllenleder). `sim_party.gd 40`: ab Platin stieg die Siegquote mit dem Erz der Stufe auf 93–100 % (Eisquell brennt 95, Finster-Kanäle 100, Altar Ost 93, Unterwelt-Straße 93). `sim_party.gd 40 autotune 30 50` hat Sumpf bis Unterwelt neu eingestellt; geändert wurden nur diese Faktoren (die übrigen blieben gleich):

| Dungeon | alt | neu | Erz der Stufe | Erz davor |
|---|---|---|---|---|
| swamp_mire | 2,98 | 2,9 | 85 | 66 |
| eisquell_burning | 3,25 | 3,65 | 71 | 41 |
| ice_wall_lake | 2,9 | 3,1 | 75 | 46 |
| finster_ash | 4,13 | 4,5 | 81 | 20 |
| finster_canals | 3,85 | 4,05 | 83 | 36 |
| finster_towers | 3,59 | 3,85 | 83 | 30 |
| star_crater | 1,8 | 1,9 | 68 | 14 |
| altar_east | 2,64 | 2,9 | 70 | 21 |
| altar_south | 2,9 | 3,1 | 74 | 34 |
| altar_lake | 3,1 | 3,25 | 88 | 56 |
| underworld_road | 7,4 | 8,7 | 71 | 28 |

(80 Kämpfe je Zelle.) Mit dem Erz davor liegen jetzt nur noch Sumpf I (66), Bergfried (70) und Altar West / Lake (56–59) über 50 %.

### 6.2 Segens-Paladin

Ursache: Er heilt nicht mehr als der Priester (3,3 gegen 3,9 Leben/s), macht aber 28 % statt 13 % des Gruppenschadens und hält in Platte mehr aus. Heilung allein senken wirkt kaum (Handauflegen 21+7 » 16+4: 91 » 88 %; Märtyrer 30 s statt 20 s: kein Unterschied). Umgesetzt: Handauflegen 12 % (+3 %), Abklingzeit 16 s (vorher 21 % (+7 %), 14 s); Paladin-Instinkt „Zweiter Atem“ 20 » 10 % (kostet die Paladin-Gruppen ohne Heiler 1–2 Punkte; 0 % hätte 4–6 gekostet).

`sim_balance.gd healer 30 1` (alle Dungeons ab Leonheim, mit den neuen Faktoren): Krieger + Priester + Magier 82, Krieger + Segens-Paladin + Magier **76** (vorher 91), Krieger + Magier + Magier 58, Krieger + Magier + Waldläufer 54, Bollwerk-Paladin + Magier + Waldläufer 49, Körper-Krieger + Magier + Waldläufer 36, Paladin + Waldläufer + Schurke 41.

### 6.3 Schwache Bäume

Nur Werte, die in keiner Beschreibung stehen, außer bei den Segen des Priesters:

- Arkanist: Arkaner Pfeil 120 % (+18 %) statt 100 % (+15 %), Arkane Fessel 110 % (+15 %) statt 80 % (+10 %), Abklingzeit Manaschub 14 s (18), Bannfluch 14 s (16).
- Schurke Schatten: Tiefschlag 130 % (+15 %) statt 80 % (+10 %), Schattenschritt 280 % (+30 %) und 10 s statt 190 % (+20 %) und 14 s, Meucheln 400 % (+45 %) statt 300 % (+35 %), Verschleiern 20 s (25).
- Segens-Priester: Segen der Kraft und des Geistes +6 % statt +3 % pro Stufe, Eile +5 % statt +3 %; Abklingzeiten Segen 9 s (12), Eile 11 s (15), Göttliche Rüstung 18 s (22), Göttliche Gunst 36 s (45).

Gemessen als dritter Held neben Krieger + Priester (7 Dungeons der Baum-Messung, 30 Kämpfe je Dungeon, ±7 Punkte): Arkanist 69 » **75**, Schurke Schatten 57 » **61**, Segens-Priester 52 » **54**; Elementarist zum Vergleich 82. Schurke Gift (79) nicht angefasst. Der Segens-Priester bleibt der schwächste Baum: ein reiner Buff-Baum hilft als dritter Held neben einem Priester wenig, mehr ginge nur über eine neue Fähigkeit.

### 6.4 Simulator

`Hero.add_experience` sucht GameState und AudioManager jetzt über die Wurzel und bricht ohne Szenenbaum nicht mehr ab (vorher voller Log und fehlendes `emit_changed`).

### 6.5 Was offen bleibt

- Alte Dungeons auf ×5 (Kupfer R4–R5) und Blocker: bewusst nicht geändert.
- Vulkan und Sumpf ohne Heiler weiter schwer; Segens-Priester und Schurke Schatten weiter unten.
- Gold-Haushalt (Frage 10) nicht simuliert; Verzauberungen und Sockel kennt der Simulator weiter nicht.
- Alles nur per Simulator geprüft, nicht im Spiel.
