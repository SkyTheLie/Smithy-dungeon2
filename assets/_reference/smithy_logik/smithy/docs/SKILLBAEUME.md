# Skillbäume der Helden (Entwurf)

> Plan für 6 Klassen × 3 Bäume, **umgesetzt** (2026-10-19): Was im Spiel gilt, steht in `data/content/skills.json` (Werte), `data/content/skill_trees.json` (Bäume) und `data/content/summons.json` (Beschwörungen); Felder in `docs/CONTENT.md`. Wer hier Werte ändert, muss sie dort nachziehen (oder umgekehrt).
> Abweichungen beim Umsetzen: Ultimates brauchen 19 statt 20 Punkte (mit Lv 40 erreichbar), außer beim Magier höchstens 20 Mana, Rudelinstinkt ab 0 Punkten (siehe `docs/ENTSCHEIDUNGEN.md`).

## Legende und Balancing-Regeln

| Kürzel | Bedeutung |
|---|---|
| **a** / **p** | aktiver Skill / passiver Skill (wirkt immer, kein Mana, keine Abklingzeit) |
| **Pkt** | Punkte, die vorher **in diesem Baum** ausgegeben sein müssen (jede Skill-Stufe = 1 Punkt). Das Helden-Level spielt keine Rolle. Die Tabellen sind danach sortiert |
| **Max** | höchste Skill-Stufe |
| **CD** | Abklingzeit in Sekunden |
| **Schaden** | „150 % (+15 %)“ = 150 % auf Stufe 1, +15 % pro weiterer Stufe (Stufe 5 = 210 %) |
| **Aufteilung** | Anteil der Schadensarten in %, z. B. `Schnitt 80 / Feuer 20` |
| **Skal.** | Attribut, mit dem der Skill skaliert (STR, AGI, CON, INT, WIS, RES); **+W** = Waffenschaden kommt dazu |
| **benötigt** | Vorgänger-Skill (mind. Stufe 1). Im Baum-Bild stehen Folgeskills eingerückt darunter |
| 🆕 | braucht eine neue Mechanik oder einen neuen Status-Effekt (Liste am Ende) |

**Faustregeln (an diesen Rahmen halten, wenn du Werte änderst):**

| Stufe im Baum | Pkt im Baum | Mana | CD | Schaden (Einzelziel) | Schaden (alle Gegner) |
|---|---|---|---|---|---|
| Einstieg | 0–3 | 0–4 | 3–8 s | 100–150 % | – |
| Mitte | 4–9 | 4–10 | 8–16 s | 150–200 % | 90–130 % |
| Stark | 10–15 | 10–18 | 14–25 s | 200–260 % | 130–180 % |
| Ultimativ | 16–19 | 18–30 | 25–60 s | 280–400 % | 200–300 % |

- Alle Klassen außer dem Magier haben wenig Intelligenz und damit wenig Mana (Mana wächst seit 2026-10-19 auch mit dem Level, +0,5 pro Level: Lv 40 ohne Punkte in INT ≈ 42 Mana): ihre teuersten Skills kosten höchstens **20 Mana**. Nur der Magier darf bis **30**. Seit 2026-10-26 gibt auch Weisheit Mana-Regeneration (+1/s pro 10, `combat.json` `mana_regen_per_10_wis`); vorher hatten Priester mit Weisheit 2/3 der Kampfzeit kein Mana.
- Pro Stufe wächst der Schaden um ca. 10 % des Grundwerts, Effekte (Dauer, Chance) um kleine Schritte.
- Debuff-Dauer meist 3–8 s, Betäubungen höchstens 2–3 s (sonst zu stark bei Bossen).

---

## Elemente der Klassen und Rassen (2026-10-26)

Jede Klasse hat ihre typischen Elemente (in den Skills), jede Rasse einen kleinen Bonus (`appearance.json` `races`: `hero_bonus`, `hero_resistances`, `player_bonus`). Passen Rasse und Klasse zusammen, verstärkt die Rasse die Skills der Klasse (z. B. Halbdämon + Schatten-Priester, Elf + Waldläufer, Echse + Paladin).

| Klasse | Elemente | Wo |
|---|---|---|
| Krieger | Feuer, Erde | Glut und Fels (Feuerhieb, Glutklinge, Bodenschlag, Erdbeben, Vulkanklinge) |
| Paladin | Licht, Blitz | Vergeltung (Lichtschlag, Donnerschlag, Richtspruch, Hammer des Himmels), Segen (Lichtweihe) |
| Priester | Licht, Dunkelheit | Licht (Heilung), Schatten (Schmerz, Seelenentzug, Schattenflut) |
| Magier | Feuer, Eis, Blitz, Arkan | Elementarist, Beschwörer, Arkanist |
| Waldläufer | Luft, Erde, Gift | Natur (Windstoß, Dornenranken, Wirbelsturm), Schütze (Giftpfeil) |
| Schurke | Gift, Dunkelheit | Gift, Schatten (Schattenschritt, Meucheln) |

| Rasse | Bonus für Helden | Bonus für den Schmied |
|---|---|---|
| Mensch | Licht- und Erdschaden +5 %, Resistenz gegen Licht und Erde +5 | Verkauf in Läden +5 % Gold |
| Elf | Luftschaden +8 %, Ausweichen +2 %, Resistenz gegen Luft +5 | Werkbank: grüner Streifen +0,5 %-Punkte |
| Halbdämon | Dunkel- und Feuerschaden +5 %, Resistenz gegen Dunkelheit und Feuer +5 | Brennstoff hält 25 % länger |
| Halb-Fischmensch | Wasser- und Eisschaden +5 %, Resistenz gegen Wasser und Eis +5 | Gewächshaus: +10 % Chance auf seltenere Ernte |
| Tiervolk (Hund) | Max. Leben +10 % | Erz abbauen und Holz fällen +1 Schaden |
| Tiervolk (Katze) | Krit-Chance +3 %, Ausweichen +3 % | Amboss: grüne und gelbe Zone +1 %-Punkt |
| Tiervolk (Echse) | Blitzschaden +8 %, Resistenz gegen Blitz und Gift +5 | Seltene Funde beim Erzabbau +3 % |

Maßstab: Ein Spieler-Bonus ist etwa eine Stufe eines Spieler-Skills; ein Element-Bonus wirkt nur auf den Anteil dieses Elements am Schaden, daher +5 % für zwei Elemente bzw. +8 % für eines. Der Hund (+10 % Leben) hilft jeder Klasse, die Element-Rassen nur passenden Klassen, dafür stärker.

---

## Krieger – Bäume: Schwert · Körper · Glut und Fels

### Schwert (Klingenkunst, Schnittschaden, Stärke)

```
Schwertschlag (0)
├── Tiefer Schnitt (4)
│   └── Hinrichten (19)
└── Wirbelwind (6)
Klingenschärfe (2, p)
Schildbruch (8)
Parade (12, p)
Mächtiger Hieb (16)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Schwertschlag (`sword_strike`) | 5 | 0 | 5 | 150 % (+15 %); nur mit Schwert/Zweihandschwert | Schnitt 100 | STR +W | Gegner | – |
| 2 | p | Klingenschärfe | 5 | – | – | Schnittschaden +10 % (+5 %) | – | – | selbst | – |
| 4 | a | Tiefer Schnitt (`deep_cut`) | 5 | 4 | 8 | 100 % (+15 %), Blutung 100 % | Schnitt 100 | STR +W | Gegner | Schwertschlag |
| 6 | a | Wirbelwind (`whirlwind`) | 5 | 10 | 12 | 120 % (+7,5 %) an alle Gegner | Schnitt 100 | STR +W | alle Gegner | Schwertschlag |
| 8 | a | Schildbruch 🆕 | 5 | 8 | 14 | 80 % (+5 %), Debuff „Rüstung gebrochen“ −40 % (+5 %) Rüstung für 5 s (+1 s) | Stumpf 100 | STR +W | Gegner | – |
| 12 | p | Parade 🆕 | 5 | – | – | 8 % (+3 %) Chance, einen Einzelangriff komplett abzuwehren (nur mit Schwert) | – | – | selbst | – |
| 16 | a | Mächtiger Hieb | 5 | 16 | 20 | 280 % (+30 %), ignoriert 30 % Rüstung; nur mit Zweihandschwert | Schnitt 100 | STR +W | Gegner | – |
| 19 | a | Hinrichten (`execute`) 🆕 | 3 | 20 | 25 | 300 % (+40 %), doppelter Schaden gegen Gegner unter 30 % Leben | Schnitt 100 | STR +W | Gegner | Tiefer Schnitt |

### Körper (Ausdauer, Selbstheilung, Wut)

```
Abhärtung (0, p)
Wunden heilen (2)
└── Unbeugsam (19)
Kampfschrei (4)
PAIN! (6)
└── Blutdurst (10, p)
Eiserner Wille (8, p)
Lebensraub (14)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | p | Abhärtung | 5 | – | – | Max. Leben +5 % (+3 %) | – | – | selbst | – |
| 2 | a | Wunden heilen | 5 | 5 | 20 | heilt 10 % (+5 %) des max. Lebens | – | CON | selbst | – |
| 4 | a | Kampfschrei (`battle_cry`) | 5 | 4 | 18 | Rage für alle: Stärke +10 % (+2 %), 8 s | – | – | alle Verbündeten | – |
| 6 | a | PAIN! 🆕 | 5 | 0 | 25 | verletzt sich selbst (Blutung auf sich), erhält „Raserei“: Stärke +25 % (+5 %), Angriffstempo +15 %, 8 s | – | – | selbst | – |
| 8 | p | Eiserner Wille | 5 | – | – | Zähigkeit +5 % (+3 %), Rüstung +5 % (+2 %) | – | – | selbst | – |
| 10 | p | Blutdurst 🆕 | 5 | – | – | unter 50 % Leben: Schaden +10 % (+4 %), 3 % (+1 %) Lebensraub | – | – | selbst | PAIN! |
| 14 | a | Lebensraub (`lifesteal_strike`) | 5 | 9 | 11 | 150 % (+20 %), heilt um 30 % des Schadens | Schnitt 100 | STR +W | Gegner | – |
| 19 | a | Unbeugsam 🆕 | 3 | 20 | 60 | 10 s: fällt nicht unter 1 Leben, erleidet −30 % (+5 %) Schaden; danach Heilung 20 % max. Leben | – | CON | selbst | Wunden heilen |

### Glut und Fels (Feuer- und Erd-Hiebe, Stärke + Intelligenz)

Bis 2026-10-26 hieß der Baum „Arkaner Krieger“ (mit Eis und Blitz). Seitdem gehören Feuer und Erde zum Krieger, Blitz zum Paladin (siehe „Elemente der Klassen und Rassen“ unten). Die ids `frost_blade` und `elemental_blade` blieben, damit gelernte Stufen in Spielständen erhalten bleiben.

```
Feuerhieb (0)
├── Glutklinge (4)
└── Bodenschlag (6)
    └── Vulkanklinge (19)
Arkane Klinge (2, p)
Runenschild (8)
Elementarfluss (12, p)
Erdbeben (16)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Feuerhieb (ersetzt `fire_slash`) | 5 | 3 | 6 | 150 % (+15 %), 20 % Chance auf Brand | Schnitt 80 / Feuer 20 (= 120 % + 30 %) | STR +W | Gegner | – |
| 2 | p | Arkane Klinge | 5 | – | – | normale Angriffe +5 % (+2 %) Magieschaden (aus INT) | Magie | INT | selbst | – |
| 4 | a | Glutklinge (`frost_blade`) | 5 | 5 | 9 | 140 % (+15 %), Brand 100 % | Schnitt 70 / Feuer 30 | STR +W | Gegner | Feuerhieb |
| 6 | a | Bodenschlag (`ground_slam`, vorher Paladin) | 5 | 10 | 14 | 110 % (+15 %) an alle, Verlangsamung 3 s | Stumpf 50 / Erde 50 | STR +W | alle Gegner | Feuerhieb |
| 8 | a | Runenschild 🆕 | 5 | 8 | 18 | Schutzschild 10 % (+3 %) max. Leben; Angreifer erleiden 15 % ihres Schadens als Magie (Dornen) | Magie | INT | selbst | – |
| 12 | p | Elementarfluss | 5 | – | – | Magiedurchdringung +4 % (+4 %) für alle Element-Skills | – | – | selbst | – |
| 16 | a | Erdbeben (`earthquake`) | 5 | 18 | 22 | 200 % (+25 %) an alle, Verlangsamung 3 s | Stumpf 50 / Erde 50 | STR +W | alle Gegner | – |
| 19 | a | Vulkanklinge (`elemental_blade`) | 3 | 20 | 30 | 3 Hiebe à 120 % (+15 %): Feuer (Brand), Erde (Verlangsamung), Feuer und Erde (20 % Betäubung) | Schnitt 50 / Feuer 50 · Schnitt 50 / Erde 50 · Schnitt 50 / Feuer 25 / Erde 25 | STR + INT +W | Gegner | Bodenschlag |

---

## Magier – Bäume: Elementarist · Beschwörer · Arkanist

### Elementarist (Element-Schaden, Intelligenz)

```
Feuerball (0)
└── Inferno (14)
Eislanze (2)
└── Blizzard (10)
Elementarmeister (4, p)
Kettenblitz (6)
Meteor (19)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Feuerball (`fireball`) | 5 | 4 | 6 | 150 % (+20 %), 20 % Brand | Feuer 100 | INT +W | Gegner | – |
| 2 | a | Eislanze (`ice_lance`) | 5 | 5 | 8 | 160 % (+20 %), Verlangsamung 3 s | Eis 100 | INT +W | Gegner | – |
| 4 | p | Elementarmeister | 5 | – | – | Element-Schaden +6 % (+6 %) | – | – | selbst | – |
| 6 | a | Kettenblitz (`chain_lightning`) 🆕 | 5 | 12 | 12 | 180 % (+25 %) auf das erste Ziel, springt auf bis zu 3 weitere, −25 % pro Sprung | Blitz 100 | INT | Kette | – |
| 10 | a | Blizzard (`blizzard`) | 5 | 18 | 22 | 180 % (+20 %) an alle, Verlangsamung 4 s | Eis 100 | INT | alle Gegner | Eislanze |
| 14 | a | Inferno | 5 | 20 | 20 | 160 % (+20 %) an alle, Brand 100 % | Feuer 100 | INT | alle Gegner | Feuerball |
| 19 | a | Meteor (`meteor`) | 3 | 30 | 35 | 380 % (+40 %) an alle, Betäubung 1 s | Feuer 70 / Erde 30 | INT | alle Gegner | – |

### Beschwörer (Elementar-Kreaturen) 🆕

Beschwörungen kämpfen **20 s** (bzw. wie angegeben) oder bis sie kein Leben mehr haben. Sie **erben einen Anteil der Werte** des Magiers (Leben, Angriff, Attribute, Resistenzen). Elementare sind **nicht** heil- oder bufferbar (`buffable = false`). Pro Art nur eine gleichzeitig. Beschwörungen belegen **keinen** der 3 Helden-Plätze.

```
Feuerelementar (0)
├── Eiselementar (4)
│   ├── Sturmgeist (10)
│   └── Erdgolem (16)
└── Elementar opfern (6)
Bindung (2, p)
Seelenband (12, p)
Elementarfürst (19)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Feuerelementar | 5 | 8 | 30 | kleines Feuerwesen, erbt 10 % (+10 %) der Werte; greift mit Feuerkugel an (60 % INT) | Feuer 100 | INT | Beschwörung | – |
| 2 | p | Bindung | 5 | – | – | Beschwörungen bleiben +2 s (+2 s) länger | – | – | selbst | – |
| 4 | a | Eiselementar | 5 | 10 | 35 | Tank: erbt 15 % (+10 %), Leben ×2, zieht Angriffe auf sich (Herausfordern alle 8 s), Treffer verlangsamen | Eis 100 | INT | Beschwörung | Feuerelementar |
| 6 | a | Elementar opfern | 5 | 6 | 15 | lässt eine eigene Beschwörung explodieren: 150 % (+20 %) an alle, Element der Beschwörung | wie Beschwörung | INT | alle Gegner | Feuerelementar |
| 10 | a | Sturmgeist | 5 | 14 | 40 | schnell (Angriffstempo ×2), erbt 20 % (+10 %), 15 % Betäubung pro Treffer | Luft 60 / Blitz 40 | INT | Beschwörung | Eiselementar |
| 12 | p | Seelenband | 5 | – | – | solange eine Beschwörung lebt: Schaden des Magiers +5 % (+5 %), Mana-Regeneration +0,5/s (+0,5) | – | – | selbst | – |
| 16 | a | Erdgolem | 5 | 22 | 60 | erbt 40 % (+10 %), Leben ×3, 30 s, Stampfer 120 % an alle alle 6 s | Stumpf 50 / Erde 50 | INT | Beschwörung | Eiselementar |
| 19 | a | Elementarfürst | 3 | 30 | 90 | erbt 80 % (+10 %), 25 s; wirkt Feuerball, Eislanze und alle 10 s einen kleinen Meteor (200 %) | alle Elemente | INT | Beschwörung | – |

### Arkanist (Schilde, Buffs, Kontrolle)

```
Arkaner Pfeil (0)
└── Arkane Fessel (10)
    └── Zeitstillstand (19)
Arkane Kraft (2, p)
Arkaner Schild (4)
Manaschub (6)
Bannfluch (8)
Zauberflut (14, p)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Arkaner Pfeil (`arcane_bolt`) | 5 | 2 | 3 | 120 % (+18 %) | Magie 100 | INT +W | Gegner | – |
| 2 | p | Arkane Kraft | 5 | – | – | Mana-Regeneration +0,5/s (+0,5) | – | – | selbst | – |
| 4 | a | Arkaner Schild | 5 | 6 | 14 | Schutzschild auf den schwächsten Verbündeten: Level + 4 × INT (+20 %), 5 s | – | INT | Verbündeter | – |
| 6 | a | Manaschub (`mana_surge`) | 5 | 5 | 14 | Arkane Kraft: Intelligenz +15 % (+3 %), 8 s | – | – | selbst | – |
| 8 | a | Bannfluch | 5 | 8 | 14 | alle Gegner: Magieresistenz −30 % (`magic_break`), 5 s (+1 s) | – | – | alle Gegner | – |
| 10 | a | Arkane Fessel | 5 | 9 | 14 | 110 % (+15 %), Betäubung 2 s (+0,25 s) | Magie 100 | INT | Gegner | Arkaner Pfeil |
| 14 | p | Zauberflut | 5 | – | – | Abklingzeiten −3 % (+3 %) (Obergrenze 50 % aus `combat.json`) | – | – | selbst | – |
| 19 | a | Zeitstillstand | 3 | 28 | 45 | alle Gegner betäubt 2,5 s (+0,5 s); Verbündete: alle Abklingzeiten −3 s | – | – | alle | Arkane Fessel |

---

## Paladin – Bäume: Bollwerk · Segen · Vergeltung

### Bollwerk (Tanken, Rüstung, Resistenzen)

```
Schildschlag (0)
Gepanzert (2, p)
Herausfordern (4)
└── Schutzwall (16)
    └── Bastion (19)
Heilige Regeneration (6, p)
Göttlicher Schild (8)
Elementarschutz (12, p)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Schildschlag (`shield_bash`) 🆕 | 5 | 3 | 8 | 50 % der Rüstung + 8 % max. Leben (+10 %), Betäubung 20 % (+10 %, max 60 %), 1,5 s; nur mit Schild | Stumpf 100 | Rüstung + Leben | Gegner | – |
| 2 | p | Gepanzert | 5 | – | – | Rüstung +8 % (+8 %) | – | – | selbst | – |
| 4 | a | Herausfordern 🆕 | 5 | 5 | 18 | alle Gegner greifen 4 s (+0,5 s) nur den Paladin an; dabei Rüstung +30 % (`fortify`) | – | – | selbst | – |
| 6 | p | Heilige Regeneration | 5 | – | – | Lebensregeneration +0,4 % (+0,4 %) max. Leben pro Sekunde | – | – | selbst | – |
| 8 | a | Göttlicher Schild (`divine_shield`) | 5 | 6 | 14 | Schutzschild auf sich + Magieresistenz +30 % (`magic_ward`), 5 s (+0,5 s) | – | WIS | selbst | – |
| 12 | p | Elementarschutz | 5 | – | – | alle Element-Resistenzen +4 (+4) | – | – | selbst | – |
| 16 | a | Schutzwall 🆕 | 5 | 18 | 40 | 6 s (+1 s): fängt 50 % des Schadens ab, der Verbündete trifft; eigener erlittener Schaden −20 % | – | – | alle Verbündeten | Herausfordern |
| 19 | a | Bastion | 3 | 20 | 60 | 8 s: Rüstung und Resistenzen ×2, immun gegen Betäubung, Gruppe erhält `bulwark` | – | – | selbst + Gruppe | Schutzwall |

### Segen (Buffs für sich und Verbündete)

```
Segen der Stärke (0)
└── Lichtweihe (10)
Handauflegen (2)
└── Göttliche Intervention (19)
Segen der Weisheit (4)
Aura der Hingabe (6, p)
Märtyrer (14, p)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Segen der Stärke (`blessing_of_might`) | 5 | 3 | 15 | Stärke +10 % (+2 %), 12 s | – | – | Verbündeter | – |
| 2 | a | Handauflegen (`lay_on_hands`) | 5 | 7 | 16 | heilt 12 % (+3 %) max. Leben des schwächsten Verbündeten + Recovery | – | WIS | Verbündeter | – |
| 4 | a | Segen der Weisheit | 5 | 5 | 15 | Intelligenz +10 % (+2 %) und Mana-Regeneration +1/s, 12 s; **seit 2026-11-11** dazu Schild der Weisheit auf alle Verbündeten, 8 s: (Level + 5 × (WIS + RES)) × 12,5 % (+2,5 %) | – | WIS, RES | Verbündeter (Schild: alle) | – |
| 6 | p | Aura der Hingabe 🆕 | 5 | – | – | alle Verbündeten: Rüstung +3 % (+3 %) | – | – | alle Verbündeten | – |
| 10 | a | Lichtweihe 🆕 | 5 | 12 | 25 | 10 s: Angriffe aller Verbündeten machen +20 % (+4 %) zusätzlichen Lichtschaden | Licht | WIS | alle Verbündeten | Segen der Stärke |
| 14 | p | Märtyrer 🆕 | 5 | – | – | fällt ein Verbündeter unter 25 % Leben: Heilung 10 % (+3 %) max. Leben (höchstens alle 20 s) | – | WIS | Verbündeter | – |
| 19 | a | Göttliche Intervention 🆕 | 3 | 20 | 120 | belebt einen gefallenen Verbündeten mit 30 % (+10 %) Leben, 3 s unverwundbar; einmal pro Dungeon | – | – | gefallener Verbündeter | Handauflegen |

### Vergeltung (Keulen, Hämmer, Licht und Blitz)

```
Hammerschlag (0)
├── Lichtschlag (4)
│   └── Richtspruch (10)
│       └── Hammer des Himmels (19)
└── Donnerschlag (6)
Wucht (2, p)
Heiliger Eifer (14, p)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Hammerschlag (`hammer_blow`) | 5 | 0 | 5 | 140 % (+15 %); nur mit Hammer/Keule | Stumpf 100 | STR +W | Gegner | – |
| 2 | p | Wucht | 5 | – | – | Stumpfschaden +6 % (+6 %) | – | – | selbst | – |
| 4 | a | Lichtschlag (`holy_strike`) | 5 | 6 | 8 | 150 % (+20 %) | Stumpf 60 / Licht 40 | STR +W | Gegner | Hammerschlag |
| 6 | a | Donnerschlag (`thunder_strike`, vorher Krieger) | 5 | 10 | 14 | 110 % (+15 %) an alle, Betäubung 20 % (+5 %), 1,5 s | Stumpf 50 / Blitz 50 | STR +W | alle Gegner | Hammerschlag |
| 10 | a | Richtspruch (`judgment`) 🆕 | 5 | 11 | 14 | 200 % (+20 %), Betäubung 50 %, 1,5 s; +50 % Schaden gegen Dunkelheits-Gegner (Untote, Dämonen) | Licht 100 | WIS +W | Gegner | Lichtschlag |
| 14 | p | Heiliger Eifer | 5 | – | – | 3 % (+1 %) des Schadens aus diesem Baum heilt den Paladin | – | – | selbst | – |
| 19 | a | Hammer des Himmels (ersetzt `divine_wrath`) | 3 | 20 | 35 | 300 % (+30 %) an alle, Betäubung 1,5 s | Licht 50 / Blitz 30 / Stumpf 20 | STR + WIS +W | alle Gegner | Richtspruch |

---

## Priester – Bäume: Licht · Segen · Schatten

### Licht (Heilen, Schilde, Debuffs entfernen; bis 2026-10-26 „Heilung“)

```
Heilendes Licht (0)
└── Große Heilung (8)
    └── Kreis der Heilung (12)
Schutzgebet (2)
└── Schild des Glaubens (16)
Läuterung (4)
Gesegnete Hände (6, p)
Wiederbelebung (19)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Heilendes Licht (`healing_light`) | 5 | 4 | 8 | heilt 15 % (+3 %) max. Leben + Recovery | – | WIS | Verbündeter | – |
| 2 | a | Schutzgebet (`prayer_shield`) | 5 | 4 | 10 | Schutzschild (Level + 5 × WIS) +20 % pro Stufe, 5 s | – | WIS | Verbündeter | – |
| 4 | a | Läuterung (`purify`) | 3 | 5 | 12 | entfernt 1 Debuff (Stufe 2: 2, Stufe 3: alle) | – | – | Verbündeter | – |
| 6 | p | Gesegnete Hände | 5 | – | – | Heilkraft +6 % (+6 %) | – | – | selbst | – |
| 8 | a | Große Heilung (`greater_heal`) | 5 | 12 | 16 | heilt 40 % (+8 %) max. Leben | – | WIS | Verbündeter | Heilendes Licht |
| 12 | a | Kreis der Heilung | 5 | 16 | 22 | heilt alle Verbündeten um 20 % (+5 %) | – | WIS | alle Verbündeten | Große Heilung |
| 16 | a | Schild des Glaubens | 5 | 18 | 25 | Schutzschild auf alle Verbündeten (Level + 5 × WIS) +15 % pro Stufe | – | WIS | alle Verbündeten | Schutzgebet |
| 19 | a | Wiederbelebung (`resurrection`) | 3 | 20 | 90 | belebt einen gefallenen Verbündeten mit 25 % (+15 %) Leben | – | – | gefallener Verbündeter | – |

### Segen (Buffs)

```
Segen der Kraft (0)
└── Göttliche Gunst (19)
Segen des Geistes (2)
Eile (4)
Langer Segen (6, p)
Göttliche Rüstung (10)
Inspiration (14)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Segen der Kraft 🆕 | 5 | 3 | 9 | physischer Schaden +10 % (+6 %), 10 s | – | – | Verbündeter | – |
| 2 | a | Segen des Geistes 🆕 | 5 | 3 | 9 | Magieschaden +10 % (+6 %), Mana-Regeneration +1/s, 10 s | – | – | Verbündeter | – |
| 4 | a | Eile 🆕 | 5 | 5 | 11 | Angriffstempo +15 % (+5 %), 8 s | – | – | Verbündeter | – |
| 6 | p | Langer Segen | 5 | – | – | Buff-Dauer +10 % (+10 %) (erste Quelle für „Buff-Dauer“) | – | – | selbst | – |
| 10 | a | Göttliche Rüstung | 5 | 12 | 18 | alle: Rüstung und Magieresistenz +30 % (`fortify` + `magic_ward`), 6 s (+0,5 s) | – | – | alle Verbündeten | – |
| 14 | a | Inspiration | 5 | 14 | 30 | alle: Abklingzeiten sofort −2 s, Mana +10 % (+2 %) des Maximums | – | – | alle Verbündeten | – |
| 19 | a | Göttliche Gunst | 3 | 20 | 36 | alle: Schaden +25 % (+5 %), Angriffstempo +20 %, Krit +10 %, 10 s | – | – | alle Verbündeten | Segen der Kraft |

### Schatten (Schaden über Zeit, Flüche)

Seit 2026-10-26 statt „Bann“ (Heiliger Zorn, Frostfessel und Strafgericht sind weg, ihre Punkte sind in alten Spielständen wieder frei). „Strenger Glaube“ und „Bannkreis“ behielten ihre ids, damit gelernte Stufen erhalten bleiben. Schmerz wächst mit dem Priester: Schaden pro Sekunde = X % seines durchschnittlichen Zauberschadens (Magieschaden der Waffe × Weisheits-Faktor), `status_effects.json` `damage_from_magic`.

```
Schattenwort: Schmerz (0)
├── Seelenentzug (4)
│   └── Psychischer Schrei (14)
└── Schattenflut (19)
Schwächen (2)
└── Fluch der Verwundbarkeit (10)
Finsterer Glaube (6, p)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Schattenwort: Schmerz (`shadow_pain`) | 5 | 3 | 5 | 80 % (+10 %), dann 8 s Schmerz: 45 % (+8 %) des Zauberschadens pro Sekunde | Dunkel 100 | WIS +W | Gegner | – |
| 2 | a | Schwächen | 5 | 4 | 12 | Gegner macht −15 % (+3 %) Schaden, 6 s | – | – | Gegner | – |
| 4 | a | Seelenentzug (`soul_drain`) | 5 | 6 | 12 | 160 % (+20 %); alle Verbündeten heilen sich um 30 % des Schadens | Dunkel 100 | WIS +W | Gegner | Schattenwort: Schmerz |
| 6 | p | Finsterer Glaube (`strict_faith`) | 5 | – | – | Dunkelschaden +8 % (+8 %), Debuff-Dauer +8 % (+8 %) | – | – | selbst | – |
| 10 | a | Fluch der Verwundbarkeit | 5 | 10 | 18 | Gegner erleidet +15 % (+3 %) Schaden, 8 s | – | – | Gegner | Schwächen |
| 14 | a | Psychischer Schrei (`ban_circle`) | 5 | 16 | 26 | alle Gegner: Schweigen (keine Skills) 3 s (+0,5 s) + Verlangsamung | – | – | alle Gegner | Seelenentzug |
| 19 | a | Schattenflut (`shadow_flood`) | 3 | 20 | 40 | 180 % (+25 %) an alle, dazu 10 s starker Schmerz bei allen: 60 % (+10 %) des Zauberschadens pro Sekunde | Dunkel 100 | WIS +W | alle Gegner | Schattenwort: Schmerz |

Untote und Geister widerstehen Dunkelheit (25–100 %): gegen sie ist der Schatten-Priester schwach, der Paladin (Licht) stark.

---

## Waldläufer – Bäume: Schütze · Natur · Tierfreund

### Schütze (Bogen, Pfeile; jeder Treffer verbraucht einen Pfeil)

```
Schnellschuss (0)
├── Giftpfeil (2)
├── Feuerpfeil (4)
└── Gezielter Schuss (8)
    └── Durchschuss (12)
Adlerauge (6, p)
Pfeilhagel (16)
└── Sturmsalve (19)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Schnellschuss (`rapid_shot`) | 5 | 0 | 4 | 125 % (+15 %); nur mit Bogen/Langbogen | Stich 100 | AGI +W | Gegner | – |
| 2 | a | Giftpfeil (`poison_arrow`) | 5 | 3 | 6 | 110 % (+15 %), Gift 60 % (+8 %) | Stich 70 / Gift 30 | AGI +W | Gegner | Schnellschuss |
| 4 | a | Feuerpfeil | 5 | 5 | 8 | 120 % (+15 %), Brand 50 % (+10 %) | Stich 50 / Feuer 50 | AGI +W | Gegner | Schnellschuss |
| 6 | p | Adlerauge | 5 | – | – | mit Bogen: Krit-Chance +3 % (+3 %), Krit-Schaden +5 % (+5 %) | – | – | selbst | – |
| 8 | a | Gezielter Schuss (`aimed_shot`) | 5 | 7 | 10 | 200 % (+20 %), Krit-Chance +20 % | Stich 100 | AGI +W | Gegner | Schnellschuss |
| 12 | a | Durchschuss 🆕 | 5 | 12 | 14 | 250 % (+25 %) am ersten Gegner, durchschlägt alle, −30 % pro weiterem Gegner; ignoriert 20 % Rüstung | Stich 100 | AGI +W | Reihe | Gezielter Schuss |
| 16 | a | Pfeilhagel (`rain_of_arrows`) | 5 | 16 | 18 | 160 % (+20 %) an alle | Stich 100 | AGI +W | alle Gegner | – |
| 19 | a | Sturmsalve | 3 | 20 | 30 | 6 Pfeile à 90 % (+10 %) auf zufällige Gegner, je +30 % Krit-Chance | Stich 100 | AGI +W | zufällig | Pfeilhagel |

### Natur (Wind- und Erdmagie, etwas Heilung)

```
Windstoß (0)
└── Wirbelsturm (14)
    └── Zorn des Waldes (19)
Heilkräuter (2)
Dornenranken (4)
└── Steinhaut (10)
Einklang mit der Natur (6, p)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Windstoß | 5 | 2 | 5 | 100 % (+15 %), Verlangsamung 1 s | Luft 100 | INT | Gegner | – |
| 2 | a | Heilkräuter | 5 | 5 | 15 | heilt 10 % (+4 %) max. Leben + Recovery 4 s | – | WIS | Verbündeter | – |
| 4 | a | Dornenranken | 5 | 6 | 10 | 120 % (+15 %), verwurzelt (Verlangsamung 80 %) 3 s, Blutung 30 % | Erde 80 / Stich 20 | INT | Gegner | – |
| 6 | p | Einklang mit der Natur | 5 | – | – | Lebens- und Mana-Regeneration +0,3/s (+0,3), Ausweichen +2 % (+2 %) | – | – | selbst | – |
| 10 | a | Steinhaut | 5 | 9 | 20 | Rüstung +30 % (`fortify`) + Schutzschild 10 % (+3 %) max. Leben, 6 s | – | INT | Verbündeter | Dornenranken |
| 14 | a | Wirbelsturm | 5 | 16 | 20 | 170 % (+20 %) an alle; Gruppe Ausweichen +10 %, 4 s | Luft 100 | INT | alle Gegner | Windstoß |
| 19 | a | Zorn des Waldes | 3 | 20 | 40 | 280 % (+30 %) an alle, verwurzelt 3 s; Verbündete heilen sich um 10 % des Schadens | Erde 60 / Luft 40 | INT | alle Gegner | Wirbelsturm |

### Tierfreund (Wolf als Begleiter) 🆕

Der Wolf wird **einmal pro Dungeon** gerufen und bleibt, bis er stirbt. Er belegt **keinen** der 3 Helden-Plätze, **zählt im Kampf aber als Held**: Priester/Paladine können ihn heilen und buffen (`buffable = true`), Gegner können ihn angreifen. Er erbt Werte vom Waldläufer. Angriff: Biss 100 % seines Angriffs (Stich), 20 % Blutung.

```
Wolfsjunges rufen (0)
└── Wolf (4)
    ├── Schützen (6, p)
    ├── Fass! (8)
    └── Riesenwolf (12)
        └── Wilde Jagd (19)
Rudelinstinkt (0, p)
Heulen (16)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Wolfsjunges rufen | 1 | 6 | 1× pro Dungeon | kleiner Wolf, erbt 50 % der Werte | Stich 100 | alle Werte | Begleiter | – |
| 0 | p | Rudelinstinkt | 5 | – | – | Wolf: Schaden +8 % (+8 %), Leben +5 % (+5 %) | – | – | Wolf | – |
| 4 | p | Wolf | 1 | – | – | das Junge ist jetzt ein ausgewachsener Wolf: erbt 100 % | – | – | Wolf | Wolfsjunges rufen |
| 6 | p | Schützen | 5 | – | – | 10 % (+10 %) Chance: der Wolf wirft sich vor einen Angriff auf den Waldläufer und nimmt den ganzen Schaden | – | – | Wolf | Wolf |
| 8 | a | Fass! | 5 | 5 | 12 | der Wolf springt an: 200 % (+25 %) seines Angriffs, Blutung 100 % | Stich 100 | Wolf | Gegner | Wolf |
| 12 | p | Riesenwolf | 1 | – | – | der Wolf wird zum Riesenwolf: erbt 125 % | – | – | Wolf | Wolf |
| 16 | a | Heulen | 5 | 10 | 25 | alle Verbündeten: Stärke und Geschick +15 % (+3 %), 8 s; Gegner verlangsamt 2 s | – | – | alle | – |
| 19 | a | Wilde Jagd | 3 | 20 | 60 | 10 s: Angriffstempo von Waldläufer und Wolf +50 %, Bisse treffen alle Gegner, 20 % Lebensraub | – | – | selbst + Wolf | Riesenwolf |

---

## Schurke – Bäume: Zwei Klingen · Schatten · Gift

### Zwei Klingen (Dolche, später Schwerter)

```
Schneller Stich (0)
├── Doppelstich (2)
│   └── Beidhändig (6, p)
│       └── Zwei Schwerter (14, p)
└── Meuchelschlag (4)
Schwertkunst (10, p)
└── Zwei Schwerter (14, p)
Tausend Schnitte (19)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | a | Schneller Stich (`quick_stab`) | 5 | 0 | 3 | 120 % (+12 %) | Stich 100 | AGI +W | Gegner | – |
| 2 | a | Doppelstich | 5 | 2 | 6 | 2 Stiche à 75 % (+8 %), jeder kann einzeln kritisch treffen | Stich 100 | AGI +W | Gegner | Schneller Stich |
| 4 | a | Meuchelschlag (`backstab`) | 5 | 4 | 8 | 170 % (+20 %), Krit-Chance +25 %, Krit-Schaden +50 % | Stich 100 | AGI +W | Gegner | Schneller Stich |
| 6 | p | Beidhändig 🆕 | 5 | – | – | die Waffe in der linken Hand trifft härter: +20 % (+20 %) Schaden (seit 2026-11-10; die linke Hand schlägt beim Schurken immer mit, halb so oft wie die rechte, mit 50 % Schaden) | – | – | selbst | Doppelstich |
| 10 | p | Schwertkunst 🆕 | 1 | – | – | erlaubt ein Schwert in der rechten Hand (Skills dieses Baums gehen damit) | – | – | selbst | – |
| 14 | p | Zwei Schwerter 🆕 | 1 | – | – | erlaubt auch links ein Schwert | – | – | selbst | Schwertkunst + Beidhändig |
| 19 | a | Tausend Schnitte | 3 | 20 | 30 | 8 Treffer à 50 % (+6 %), je 15 % Blutung | Schnitt 50 / Stich 50 | AGI +W | Gegner | Meuchelschlag |

### Schatten (Heimlichkeit, Ausweichen)

```
Flink (0, p)
Tiefschlag (2)
Verschleiern (4)
├── Aus dem Schatten (6, p)
└── Schattenschritt (12)
    └── Meucheln (19)
Rauchbombe (8)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | p | Flink | 5 | – | – | Ausweichen +2 % (+2 %) | – | – | selbst | – |
| 2 | a | Tiefschlag (`cheap_shot`) | 5 | 5 | 10 | 130 % (+15 %), Betäubung 1,5 s (+0,2 s) | Stumpf 100 | AGI +W | Gegner | – |
| 4 | a | Verschleiern 🆕 | 5 | 8 | 20 | 5 s (+1 s) nicht angreifbar, außer durch Flächenangriffe | – | – | selbst | – |
| 6 | p | Aus dem Schatten | 5 | – | – | Angriffe während Verschleiern: +20 % (+5 %) Schaden | – | – | selbst | Verschleiern |
| 8 | a | Rauchbombe (`smoke_bomb`) | 5 | 9 | 20 | alle Verbündeten: Ausweichen +20 % (+3 %), 5 s | – | – | alle Verbündeten | – |
| 12 | a | Schattenschritt (`shadow_step`) | 5 | 10 | 10 | 280 % (+30 %); aus dem Verschleiern immer kritisch; danach Ausweichen 3 s | Stich 60 / Dunkel 40 | AGI +W | Gegner | Verschleiern |
| 19 | a | Meucheln (`assassinate`) | 3 | 20 | 30 | 400 % (+45 %), ignoriert 30 % Rüstung; unter 25 % Leben dreifacher Schaden; tötet er, ist die Abklingzeit sofort vorbei | Stich 60 / Dunkel 40 | AGI +W | Gegner | Schattenschritt |

### Gift

```
Giftklinge (0)
└── Lähmgift (6)
Ätzende Gifte (2, p)
Giftbombe (4)
└── Toxischer Ausbruch (14)
    └── Seuche (19)
Virulenz (10, p)
```

| Pkt | | Skill (id) | Max | Mana | CD | Wirkung (Stufe 1, + pro Stufe) | Aufteilung | Skal. | Ziel | benötigt |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | p | Giftklinge (`poisoned_blade`) 🆕 | 5 | – | – | passiv (seit 2026-11-10, vorher Buff 8 s): jeder Angriff vergiftet mit 10 % (+5 %) | – | – | selbst | – |
| 2 | p | Ätzende Gifte | 5 | – | – | Giftschaden +10 % (+10 %) | – | – | selbst | – |
| 4 | a | Giftbombe | 5 | 8 | 14 | 90 % (+12 %) an alle, 2 Stapel Gift | Gift 100 | AGI | alle Gegner | – |
| 6 | a | Lähmgift | 5 | 5 | 12 | 100 % (+12 %), Gift 1 Stapel, Verlangsamung 50 % 4 s | Gift 100 | AGI +W | Gegner | Giftklinge |
| 10 | p | Virulenz | 5 | – | – | vergiftete Gegner erleiden +4 % (+4 %) Schaden vom Schurken | – | – | selbst | – |
| 14 | a | Toxischer Ausbruch 🆕 | 5 | 14 | 22 | löst alles Gift bei allen Gegnern aus: pro Stapel sofort 40 % (+5 %) | Gift 100 | AGI | alle Gegner | Giftbombe |
| 19 | a | Seuche 🆕 | 3 | 20 | 40 | alle Gegner: 5 Stapel Gift, 10 s; stirbt ein Vergifteter, springt sein Gift auf einen anderen Gegner über | Gift 100 | AGI | alle Gegner | Toxischer Ausbruch |

---

## Was dafür neu gebaut werden müsste 🆕

**Mechaniken:**

1. **Passive Skills.** `SkillData` kennt nur aktive Skills. Gebraucht wird ein Feld `passive: true` mit Boni (z. B. `{"stat": "armor_percent", "per_level": 8}`), die der Combatant beim Kampfstart einrechnet.
2. **Effekt-Stärke pro Stufe.** Bisher gelten Effekte fest (z. B. `armor_break` −30 %). Für Schildbruch, Eile usw. brauchen Effekte `value`, `value_per_level`, `duration_per_level` am Skill.
3. **Beschwörungen/Begleiter.** Ein neuer Combatant auf Helden-Seite: erbt X % der Werte, hat eine Dauer (oder bleibt bis zum Tod), Feld `buffable` (heilbar/bufferbar ja/nein), „einmal pro Dungeon“. Bei Bossen gibt es schon `summon`, das kann man als Vorlage nutzen.
4. **Kette und Durchschlag.** Treffer auf mehrere Ziele mit abnehmendem Schaden (Kettenblitz, Durchschuss).
5. **Mehrfachtreffer.** Ein Skill mit n Treffern, jeder würfelt einzeln Krit und Effekte (Doppelstich, Sturmsalve, Tausend Schnitte, Klinge der Elemente).
6. **Bedingter Schaden.** Gegner unter X % Leben (Hinrichten, Meucheln), Gegner mit Element Dunkelheit (Richtspruch, Strafgericht), eigenes Leben unter 50 % (Blutdurst).
7. **Nicht angreifbar außer durch Flächenangriffe** (Verschleiern), **Abfangen** (Schützen, Schutzwall), **Herausfordern** für Helden (bisher nur Monster).
8. **Waffen-Freischaltung durch Skills** (Schwertkunst, Zwei Schwerter) und **Beidhändig** (Dolch links trifft härter; mitschlagen tut er seit 2026-11-10 immer). Das behebt das bekannte Problem, dass Dolche links nicht mitkämpfen.
9. **Auren**: passive Boni für die ganze Gruppe (Aura der Hingabe).
10. **Wiederbeleben im Kampf** (Göttliche Intervention, Wiederbelebung), **nicht unter 1 Leben** (Unbeugsam), **Dornen** (Runenschild).

**Neue Status-Effekte** (Ergänzung zu `status_effects.json`): Brand (Feuer-Schaden pro Sekunde), Raserei (Stärke + Angriffstempo), Eile (Angriffstempo), Eingefroren (wie Betäubt, eigenes Icon), Schweigen (keine Skills), Geschwächt (weniger Schaden), Verwundbar (mehr erlittener Schaden), Verwurzelt (starke Verlangsamung), Verschleiert, Segen der Kraft / des Geistes (Schaden physisch/magisch +%), Unbeugsam.

**Vorhandene Skills, die wegfallen oder umziehen:** `armor_pierce` (Krieger; ersetzt durch Schildbruch), `fire_slash` (wird Feuerhieb), `meditation` (Magier; ersetzt durch Arkane Kraft), `fan_of_knives` (Schurke), `holy_smite` beim Paladin entfällt (Priester behält ihn), `divine_wrath` (wird Hammer des Himmels). Monster-Skills (`poison_bite`, `poison_cloud`, `bandit_taunt`, `bear_blood_drink`, `spear_thrust`) bleiben unverändert.

## Skillpunkte (entschieden)

- **1 Skillpunkt alle 2 Level** (heute 1 alle 3, `Hero.LEVELS_PER_SKILL_POINT` von 3 auf 2): Lv 40 = 20 Punkte, Lv 100 = 50 Punkte. Ein Baum hat ca. 30–35 Stufen, alle drei zusammen ca. 95. Ein Held kann also höchstens 1,5 Bäume ausbauen und muss sich **spezialisieren**. Die Gruppe ergibt sich daraus, wie man die 3 Helden aufteilt.
- **Freischalten über Punkte im Baum statt über das Helden-Level** (Spalte „Pkt“). Wer alles in einen Baum steckt, kommt mit Lv 40 an den Ultimativ-Skill (19 Punkte im Baum, der 20. Punkt ist der Ultimativ-Skill selbst), wer mischt, später oder nie. Jeder Baum hat vor dem Ultimativ-Skill mindestens 20 Stufen, die Grenze ist also immer erreichbar.
- **Tränke (umgesetzt, Fundorte kommen später):** Trank des Wissens +1 Skillpunkt, Trank der Stärkung +1 Attributpunkt, Trank des Vergessens (alle Skills zurück), Trank der Wandlung (alle Attributpunkte zurück); `Hero.bonus_skill_points` / `bonus_attribute_points`. Damit lässt sich ein zweiter Baum weiter ausbauen.
- **Beschwörungen** (Elementare, Wolf) kommen zusätzlich zu den 3 Helden.

## Offene Fragen

- Die Bäume sind auf 20 Punkte (19 + Ultimativ-Skill) ausgelegt, aber jeder Baum hat mehr Stufen. Später könnte man pro Baum einen zweiten Ultimativ-Skill ab ca. 28 Punkten ergänzen.
