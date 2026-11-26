# DIALOGE.md – Smithy

> Wie die Figuren sprechen. Vor jedem neuen Dialog, Tipp oder Auftragstext hier nachsehen.
> Dialoge stehen in `data/content/story.json` (`dialogues`, Feld `speaker`), Figuren-Überblick in `docs/STORY.md`.
> **Spoiler:** Abschnitt „Geheimnisse“ enthält Wendungen, die der Spieler erst später erfährt. Bis dahin dürfen die Figuren nichts davon verraten, höchstens andeuten.

---

## Regeln für alle Texte

- **Keine Kapitel, keine Teile.** Weder in Dialogen noch im Auftragsbuch, in Tipps oder Titeln steht „Kapitel 6“, „Teil 2“, „Ende von …“. Das Ende eines Abschnitts zeigt die Welt über den Inhalt („Leg dich schlafen, morgen geht es weiter.“). Kapitel gibt es nur intern (Schritt-ids wie `chapter5_end`, Admin-Panel, `docs/STORY.md`).
- **Selbst erkunden lassen.** Weder Erzähler noch Tipps führen durch ein Gebiet: nicht sagen, wo darin Händler, Türen, Ausgänge oder Rätselteile stehen („Im Westen hat ein Goblin einen Stand“, „Im Osten drei leere Sockel“). Erlaubt: wohin die Aufgabe führt (Ziel der Quest, Weg zwischen Gebieten wie „Dorfplatz » Süden“), der erste Eindruck ohne Richtungen und wie etwas funktioniert (Steuerung, Kampf, Geräte).
- **Nichts Technisches im Dialog.** Figuren sagen „das Auftragsbuch“, nicht „die Quest“; keine Tastennamen, keine Prozentzahlen. Ausnahmen: Händler nennen Preise, Nina nennt ihre Provision.
- **Kurz.** Eine Sprechblase = 1–3 Sätze. Lieber mehrere Blasen als eine lange.
- **Keine Zeichen „→“ und „✓“** (fehlen in der Schrift). Wege mit „»“ schreiben: „Dorfplatz » Süden » Dorftor“.
- **Anrede:** Im Dorf duzen sich alle. Am Hof (Mohammad, Wachen) wird der Spieler geihrzt („Ihr“, „Euch“). Der König duzt den Spieler, Fremde in der Stadt siezen ihn zuerst.
- **Platzhalter:** `{name}` (Spielername), `{weekday}` usw. wie in `docs/CONTENT.md`.

---

## Die Welt (Erzähler)

Spricht in Tipps, Auftragsbuch-Texten, Item-Beschreibungen und Dialogzeilen ohne `speaker`.

- **Schlicht und streng.** Kurze Hauptsätze, sachlich, keine Witze, keine Gefühle, keine Ausrufezeichen.
- Sagt, **was passiert ist** und **was jetzt zu tun ist** – in dieser Reihenfolge.
- Spricht den Spieler mit „du“ an, ohne Wertung („Gut gemacht!“ sagt eine Figur, nicht die Welt).
- Beispiele: „Hagen gibt dir 800 Gold.“ · „Oma Hilde wartet vor deiner Schmiede.“ · „Ein Holztrog mit 4 Feldern fürs Gewächshaus.“

## Der Spieler

Ein intelligenter junger Mann – angelegt an **Spider-Man**: der nette Junge aus der Nachbarschaft, der zufällig ein Held ist.

- **Immer ein lockerer Spruch – um die Nervosität zu verdecken.** Je gefährlicher oder peinlicher die Lage (Lich, König, Miete, die erste Kundin), desto schneller kommt der Witz. Der Spieler soll merken: Der Spruch ist Schutz, nicht Arroganz.
- **Klugscheißer, cocky, witzig:** weiß viel über Metalle, Feuer und Technik und erklärt das auch ungefragt. Prahlt gern, nimmt sich dabei selbst nicht ganz ernst.
- **Ehrlich nervös:** stottert manchmal kurz, redet zu viel, korrigiert sich selbst („Ich meine … ja. Klar. Kein Problem. Großes Problem?“).
- **Großzügig und liebevoll, ein Held:** verschenkt Schuhe, passt auf Lotte auf, hilft, ohne zu fragen, was es bringt. Verantwortung nimmt er ernst, auch wenn er darüber Witze macht.
- **Bei Tod und Trauer** (Bruno, Oma Hilde) lässt er die Sprüche weg oder ein Spruch bleibt ihm im Hals stecken – das sind die Momente, in denen man ihn ohne Maske sieht.
- **Auswahl-Optionen** zeigen beide Seiten: ein lockerer Spruch und eine ehrliche, herzliche Antwort, ab und zu eine dritte, die ganz daneben ist. Keine Option darf ihn zum Feigling oder Fiesling machen.
- Beispiele (Stil): „Ein Lich. Natürlich. Warum auch nicht einfach Ratten.“ · „Ruhig bleiben, {name}. Du hast schon Kupfer geschmolzen. Das hier ist nur … ein bisschen größer.“ · „Behalt dein Gold. Kauf Lotte lieber was Warmes.“

---

## Völker – wie sie sprechen

Jedes Volk hat eigene Sprechzüge. Sie gelten für jede Figur dieses Volkes (auch Nebenfiguren und Händler), zusätzlich zu ihrer eigenen Art. Neue Figuren eines Volkes bekommen diese Züge von Anfang an.

- **Menschen:** keine gemeinsamen Züge, jede Figur hat ihre eigene Art (Dorf: duzen, Hof: ihrzen).
- **Echsenvolk** (Sahrim, Muhme Grisla): **zischt wie eine Schlange.** Das macht das Spiel von selbst: Figuren mit `"voice": "hiss"` (story.json `npcs`, bei Händlern das Feld `voice`) ziehen jedes S am Wortanfang und jedes ss/ß lang („Sssand“, „musss“, „Ssschatten“), auch auf Englisch. **Im Text daher kein S von Hand verlängern**, normal schreiben. Dazu: ruhig, gastfreundlich, Sonne, Schatten und Wasser sind heilig, Fremde heißen „Weichhaut“, Gruß „Möge dein Schatten kühl sein.“
- **Goblins:** **chaotisch, gierig, verschlagen, hibbelig und oft unfreiwillig komisch.** Kurze Sätze, die sich überschlagen, Wörter doppelt und dreifach („Halt-halt-halt!“, „Zeig, zeig, zeig!“), springen mitten im Satz zum Gold, zählen alles, geben Dingen Namen, handeln um jede Auskunft und haben immer ein „Meistens“ oder „Fast ohne Kleingedrucktes“ in der Hinterhand. Ausrufezeichen und GROSSBUCHSTABEN sind erlaubt (Ausnahme wie beim Ausrufer). Goldzahn ist der eitle, verschlagene Geizhals, seine Goblins sind hektisch, verfressen und ein bisschen dumm.
- **Elfen** (Sylvaris): gehoben, ruhig, alt. Ihrzen Menschen, nennen sie „Mensch“, „die Jungen“ oder „Kind der Sonne“, denken in Jahrhunderten und in Bildern von Wind, Bäumen und Sternen. Leiser Hochmut, trockener Humor über das Alter der anderen. Elfenkinder dürfen neugierig und albern sein.
- **Wasservolk** (Eisquell): knapp, hart, stolz. Bilder aus Strömung, Eis und Fischfang, das „Gesetz der Strömung“ gilt für alle. Fremde heißen „Südling“. Respekt gibt es für Taten, nicht für Worte.
- **Halbdämonen** (Finsterstadt): trocken, spöttisch, misstrauisch. Sie sind es gewohnt, gefürchtet zu werden, und machen schwarze Witze darüber. Fremde heißen „Mensch“. Wer ihr Vertrauen hat, bekommt es ganz.

---

## Figuren

### Bruno (`bruno`)
- **Immer besoffen.** Lallt, hickst (`*hicks*`), verliert den Faden, prahlt mit alten Heldentaten, die vielleicht nie passiert sind.
- Unter dem Suff ein echter Held mit großem Herz – das zeigt sich in wenigen nüchternen Momenten („Ich bin heute ausnahmsweise nüchtern. Ausgerechnet heute.“).
- Nennt den Spieler „Schmied“ (nie beim Namen).
- **Beim Überfall** ausnahmsweise nüchtern: fängt den Feuerball des Lichs ab, der dem Spieler galt, macht trotzdem noch einen Witz über Bierkrüge und dankt dem Spieler zum Schluss für das Schwert. Andere Figuren erinnern sich an ihn so: „Er hätte weglaufen können. Ist er aber nicht.“

### Oma Hilde (`landlady`)
- Resolute alte Vermieterin, nennt den Spieler „Kindchen“. Geizig bei der Miete, sonst warmherzig, übertreibt gern („Ooooh!“, „Drei Monate!“).

### Lotte (`niece`)
- Lieb und frech, ein Kind. Kurze, aufgeregte Sätze, wiederholt Wörter („Danke, danke, danke!“). Nach dem Überfall leiser und ängstlicher.

### Gustav (`miner`)
- Alter Bergmann, brummig, praktisch. Klagt über seinen Rücken, denkt in Arbeit und Material, gibt nüchterne Ratschläge.

### Nina (`nina`)
- Geschäftsfrau, freundlich und flott. Redet über Geld ohne Scham, nennt Oma Hilde „die Hexe“. Gibt Tipps, wo man was findet.

### Hedwig (`guild_master`)
- Rothaarige Gildenmeisterin, direkt und laut. Befehle mit Ausrufezeichen, keine Umwege.

### Meister Aurelius (`magician`)
- Alter, weiser Zauberer (ein Elf, früher Hofzauberer). Ruhig, etwas umständlich, erzählt gern Legenden. Nennt den Spieler „junger Freund“ / „junger Schmied“. Klagt über seine Knie, schuldet dem König seit Jahren ein Feuerwerk.
- Wird er ernst (Lich, Steine, Elfen), lässt er die Umwege weg und spricht kurz und klar.

### Bürgermeister Wendelin (`mayor`)
- Schämt sich, dass er sich beim Überfall versteckt hat. Spricht feierlich, in Sinnsprüchen („Ein Dorf ist mehr als seine Häuser, Schmied.“).

### Baumeister Konrad (`builder`)
- Gesprächig und anpackend. Denkt in Material und Terminen („Morgen früh steht es.“), erzählt nebenbei Klatsch.

### Wachmann Otto (`raid_guard`)
- Ernst, knapp, sachlich. Überbringt schlechte Nachrichten ohne Schnörkel.

### Berta und Fritz (`gossip_a`, `gossip_b`)
- Dorftratsch. Flüstern, übertreiben, wechseln abrupt das Thema, wenn jemand zuhört („Schönes Wetter heute, nicht wahr?“).

### Holger (`woodcutter_market`)
- Einfacher, ehrlicher Holzfäller. Verspricht viel („Ehrenwort!“), freut sich laut.

### Hagen (`warrior_hagen`)
- Erfahrener Krieger, kritisch und anspruchsvoll. Lob ist bei ihm selten und knapp („Gleichgewicht, Härte, Schliff. Alles stimmt.“).

### Kutscher Jupp (`coachman`)
- Älterer Dorfkutscher, gemütlich und trocken. Redet lieber über sein Pferd Liese als über sich ("Strenger als der ganze Dorfrat."). Hält sich an die Regeln des Bürgermeisters.

### Mohammad (`envoy`)
- Höflicher Gesandter des Königs. Hofsprache, ihrzt den Spieler, sehr förmlich.

### Thora (`capital_guild_master`)
- Abgebrühte Gildenmeisterin von Leonheim, trocken und spöttisch, auch über den König.

### Varrik (`gutter_boss`)
- Anführer der Krähenbande. Drohend, sarkastisch, schiebt die Schuld auf „die Jungs“.

### Der Lich (`lich`)
- Selten zu hören. Pathetisch, alt, voller Gier und Verachtung („Jahrhunderte!“). Spürt beim Überfall „etwas Altes“ am Spieler (seine Magie, siehe Frühlingsfest) und verachtet Brunos Opfer („Wie rührend.“).
- In Sylvaris (Teil 3): kennt Elarion seit tausend Jahren, war einmal ein Mensch mit Namen, dem der Dämonenlord die Ewigkeit versprach („Namen. Fleisch. Atem. Dinge, die vergehen.“). Zählt seine Steine („Zwei.“). Erkennt das blaue Licht des Spielers („Er hatte es auch“) und deutet an, dass der legendäre Schmied irgendwo schmiedet. Verrät, dass ihm jemand den Weg gezeigt hat („euer Freund“) – mehr nicht.

### König Albrecht (`king`)
- **Nach außen:** gütiger alter König. Warm, väterlich, ein bisschen Humor („Zu Lebzeiten.“), duzt den Spieler, nennt ihn „mein Schmied“.
- **Bis zur Enthüllung wirklich sympathisch:** Er hat für alles einen guten, menschlichen Grund. Er bittet statt zu handeln („Darf ein alter König dich um einen Gefallen bitten?“), denkt an Lotte, sorgt sich um den Spieler („Ein Kristall ist kein Menschenleben wert.“), schickt Baumaterial ins Dorf, will das Schmiedeturnier wieder ausrichten. Wenn er etwas will, begründet er es vernünftig (den Feuerkristall: „Deine Schmiede haben die Untoten schon einmal ausgeräumt.“).
- **Keine offensichtlichen Andeutungen:** kein Greifen nach Kristallen, keine zu langen Pausen, kein „vorerst“. Erlaubt ist höchstens eine kleine Sache pro Teil, die erst beim zweiten Durchspielen auffällt (z. B. dass er Morwalds Schlüssel jetzt selbst am Gürtel trägt).
- **Falsche Fährten zeigen auf Lake:** Varrik fragt, wohin Lake nachts geht; Ignar spottet über „Ritter in glänzender Rüstung“; Lake selbst wirkt fanatisch und kalt. Das passt, weil Lake später wirklich zum dunklen Ritter wird.
- Siehe „Geheimnisse“.

---

## Geplante Figuren (noch nicht im Spiel)

### Lake des Licht (`lake`, rechte Hand des Königs, seit Teil 2, Kapitel 6 im Spiel)
- **Komplett verblendet vom König:** Für ihn ist der König heilig, jedes Wort ein Gebot. Spricht wie ein Fanatiker: „Der König sieht alles.“, „Wer am König zweifelt, zweifelt am Licht.“
- Stolz, ernst, ohne Humor. Hält den Spieler für nützlich, aber unwürdig.
- **„Star Wars für Arme“:** Lake tötet den Lich, der König lacht danach böse. Später trägt Lake eine schwarze Rüstung (Anspielung auf den Sturz in die Flammen) und ein Lichtschwert. Die Anspielungen dürfen deutlich sein, aber nie Zitate oder Namen aus Star Wars.

### Der Goblinkönig: Goldzahn der Prächtige (`goblin_king`, seit Teil 2, Kapitel 7 im Spiel)
- **Goblin** (siehe „Völker“): verschlagen, eitel, wird hektisch, sobald es um Gold geht.
- **Besessen von Gold und Reichtum.** Herrscht über die Goblins im Lavaberg und sitzt (bildlich und gern auch wörtlich) auf seinem Schatz.
- Alles hat einen Preis, jedes Gespräch wird zum Handel. Er zählt mit, unterbricht sich, um Münzen zu streicheln, und misstraut jedem, der ihm etwas schenken will („Geschenkt? Nichts ist geschenkt. Was willst du?“).
- Gierig, eitel, kleinlich: nennt sein Gold beim Namen, schätzt den Wert von allem, was der Spieler trägt, und lässt sich mit Glänzendem fast alles abkaufen – nur nicht sein Gold.
- Seine Goblins sind für ihn Arbeiter, die zu viel essen. Lob gibt es nur in Gold, und das gibt er ungern her.

### Kahn (`kahn`, Eisquell, seit Teil 4 im Spiel)
- Anführer des Wasservolks in Eisquell, ein Fischmensch – angelegt an **Dschingis Khan**.
- **Überlebenskünstler mit eisernem Willen:** Als Junge wurde sein Vater ermordet und sein Schwarm von rivalisierenden Stämmen verstoßen; er wuchs in Armut und Gefahr auf. Er spricht davon ohne Selbstmitleid, als Lehre.
- **Pragmatisch und klug:** denkt in Macht, Treue und Nutzen. Beurteilt Leute nach Leistung, nicht nach Herkunft – auch den Spieler: „Mir ist gleich, woher du kommst. Zeig mir, was deine Hände können.“
- **Hart:** Wer sich ihm widersetzt, den bricht er. Drohungen spricht er ruhig aus, und er meint sie.
- **Weitsichtig und gerecht:** schützt den Handel auf dem Wasser, duldet jeden Glauben, und in seinem Dorf gilt ein strenges Gesetz für alle („Das Gesetz der Strömung“) – auch für ihn selbst. Gefangene macht er nicht zu Sklaven, Raub unter seinem Volk bestraft er schwer.
- Sprache: knapp, ruhig, bestimmt, ab und zu ein Bild aus Wasser und Strömung („Der Fluss fragt den Stein nicht, ob er weichen will.“). Duzt jeden.
- Teil 4: hält die Gruppe aus Leonheim für Schwächlinge („Ein König, der Felle schicken lässt.“) und redet erst nach seinem Heldenturnier mit ihnen. Stolz auf seinen Sohn auch nach dessen Niederlage („Ein Sieg schmeichelt nur den Ohren und lehrt dich wenig.“). Gibt den Wasserkristall her, den Eiskristall nicht. Elarion über ihn: „Kahn lässt jeden hinein. Er lässt nur nicht jeden wieder hinaus.“

### Subar (`kahn_right_hand`) und Torgai (`kahn_son`)
- **Subar:** Kahns rechte Hand, alter narbiger Krieger mit Harpune. Trocken, misstrauisch, wenig Worte, unbeeindruckt von Kronen („Hier bist du ein alter Mann mit Bart. Mehr nicht.“). Nennt Fremde „Südling“.
- **Torgai:** Kahns Sohn, junger Krieger, stolz und ungeduldig, will seinem Vater gefallen; fair, kein Fiesling, will Revanche.
- **Ausrufer der Arena (`arena_crier`):** laut, theatralisch, Ausrufezeichen erlaubt (eine Ausnahme), Bilder von Flut und Salz.

### Der Älteste Elarion (`elf_elder`, Sylvaris, seit Teil 3 im Spiel)
- Herr der Elfen im Wald – angelegt an **Elrond** (Herr der Ringe). Name: **Elarion**, die Jungen nennen ihn „den Ältesten“.
- **Zeitlos:** weder alt noch jung, mit dunklem Haar, silbernem Diadem und grauen Augen, in denen ein Licht wie Sternenlicht liegt. Ehrwürdig wie ein König vieler Winter, doch stark wie ein erfahrener Krieger.
- Hat viel gesehen, Freude und Leid. Erinnert sich an die Zeit des Dämonenlords und des ersten Helden, als wäre es gestern gewesen, und spricht davon ruhig, mit leiser Trauer.
- **Würdevoll und gehoben:** lange, ruhige Sätze, altmodische Worte, nie laut. Ihrzt den Spieler („Ihr“), nennt Menschen „die Jungen“ oder „Kinder der Sonne“.
- Zurückhaltend gegenüber Menschen, aber gerecht: Er hilft, wenn der Spieler sich als würdig erweist, und gibt eher Rat als Befehle („Nicht jede Klinge ist zum Schlagen gemacht. Manche schmiedet man, um sie nie ziehen zu müssen.“).
- Trockener Humor über das Alter der anderen: Faelan ist „jung, kaum vierhundert“, der König „so jung“.
- Weiß, warum es die Kristallkarte gibt (Siegel alle tausend Jahre schwach, jedes Volk ein Stück) und erzählt es erst nach dem Verlust des Windkristalls.

### Fenn (`elf_inventor`, Sylvaris, Flugfeld, seit 2026-10-30)
- Fennoriel Sternwind vom dritten Ast, nennt sich nur **Fenn**. Mit 212 Jahren für Elfen ein Kind („der Junge“). Will eine **Flugmaschine** bauen (Flügel aus Blättern, Propeller aus Federn); bisher ist alles abgestürzt oder hat gebrannt. Mit dem Spieler baut er sie in der Nebenquest „Fenns Flugmaschine“ fertig und nennt sie „Sternwind“; danach fliegt er ihn herum.
- **Das Gegenteil der anderen Elfen:** laut, hastig, ungeduldig, duzt jeden, kurze Sätze, Ausrufezeichen erlaubt, springt von Idee zu Idee, bewundert Menschen („Ihr habt keine Zeit, also denkt ihr schneller“) und ihr Werkzeug. Warten findet er Zeitverschwendung („Der Wind ist langsam“).
- **Spricht immer in der dritten Person von sich** („Fenn braucht Metall“, „Fenns Lebenstraum“, „Glaubt Fenn.“), nie „ich“, „mich“, „mein“. Auch auf Englisch („Fenn needs metal“). Neue Fenn-Zeilen genauso schreiben.
- Die anderen Elfen dulden ihn, mögen ihn aber nicht: höflich-kühl, mit trockenem Spott (**Laubhüter Caladen**, `elf_grumbler`, steht am Flugfeld: „Der Wald duldet auch die Eichhörnchen …“). Fenn weiß das und versteckt seine Pläne vor ihnen.

### Hauptmann Faelan (`faelan`, Sylvaris)
- Rechte Hand des Ältesten, Hauptmann der Windwache. Stolz, kühl, nennt den Spieler „Mensch“, nach dem Angriff auch „Schmied“.
- Hält Sylvaris für uneinnehmbar, bis er es besser weiß. Lob kommt widerwillig und knapp („Gutes Gleichgewicht.“).
- Misstraut den Menschen, vor allem Lake („Allein. Wie praktisch.“). Am Ende von Teil 3 respektiert er den Spieler („Das vergesse ich nicht.“).

### Das Echsenvolk von Sahrim (seit 2026-10-28 auch Rashid und Ulrich; `lizard_elder`, `lizard_kesh`, `lizard_mira`, `lizard_brakk`, `treasure_hunter`, seit 2026-10-27)
- Ruhig und gastfreundlich, zischt wie eine Schlange (macht `Voice` von selbst, siehe „Völker“; im Text kein S von Hand verlängern). Nennt Fremde freundlich-spöttisch „Weichhaut“, duzt alle. Sonne, Schatten und Wasser sind heilig; Gruß: „Möge dein Schatten kühl sein.“
- **Die alte Ishra:** Älteste, langsam und weise, kennt Aurelius („ein alter Elf mit Sternenmantel“), spricht von den Gewittern der tiefen Wüste.
- **Zahir:** Schatzsucher, prahlt („der unerschrockenste Schatzsucher dieser Wüste“), gibt zu, dass er sich hundertmal verlaufen hat. Jeden Tag ein anderer Hinweis.
- **Brakk:** alter Torwächter, grimmig, kurz angebunden. **Kesh** (Wasserträger) und **Mira** (Weberin) freundlich.
- **Fürst Ssarok (`desert_lord`, seit Teil 4):** Anführer des Echsenvolks, immer mit zwei Speerkriegern. Ruhig, scharfsinnig, weiß über die Welt Bescheid (Heer vor dem Elfenwald, Feuer- und Windkristall). Glaubt, dass jemand hinter dem Lich steht („Ein Toter will nichts mehr. Wer nichts will, sammelt nicht.“), stellt Fragen, nennt aber nie einen Namen („Dann weiß es einer von denen. Oder alle. Oder keiner.“).
- **Echsenwachen (`desert_guard`):** grimmig, misstrauisch gegenüber Fremden mit Echsen-Kompass.

### Muhme Grisla (`swamp_witch`, seit Teil 5)
- Uralte Echse mit krummem Hut, Ssaroks Großtante, lebt im Sumpf am Ostweg. Wird „Hexe“ genannt und korrigiert jedes Mal: „Hechse!“ Kichert („Hihihi“), liebt eklige Zutaten, nennt den Spieler „Schmiedchen“. Freche Großmutter, aber unheimlich klug, wenn es ernst wird.

### Hauptmann Bertold (`leon_captain`, seit Teil 5)
- Alter Hauptmann der Soldaten von Leonheim, praktisch, loyal, müde. Ihrzt den Spieler („Meister Schmied“), nennt Lake „Lord Lake“.

### Meister Halvard (`halvard`, seit Teil 7)
- Der legendäre Schmied. Alt, abgemagert nach zwanzig Jahren in der Kerkerschmiede, aber ruhig und trocken. Nennt den Spieler „Junge“, erinnert sich an ihn als Kind an der Werkstatttür. Denkt in Takt und Handwerk („Ein guter Schmied baut nie etwas, das er nicht wieder zerlegen kann.“). Bitter nur, wenn es um den König geht.

### Nyra (`nyra`, vorher `hooded`, seit Teil 7)
- Halbdämonin, rechtmäßige Fürstin der Finsterstadt, gibt sich bis zur Enthüllung als „Verräterin“. Schnell, schlagfertig, spöttisch gegenüber dem Spieler („Und du siehst auf deinem dümmer aus. Knapp.“), ernst, wenn es um ihr Volk geht. Duzt alle. Trägt Halvards Eisenpferd immer in der Tasche.

### Corvin (`corvin`)
- Alter Diener von Nyras Familie. Wenige Worte, trocken, misstrauisch gegenüber Fremden, nennt Nyra „Hoheit“, sobald sie es zeigt.

### Ulrich (`first_customer`)
- Der erste Kunde aus dem Dorf, jetzt kleiner Händler mit Kamel und Karawane zwischen Norden und Wüste. Freundlich, etwas umständlich, dankbar; siezt den Spieler („Sie“), sein Kupferschwert hat ihm das Leben gerettet.
- Lacht „Schaha! Schaha!“. Kannte Oma Hilde gut und mochte sie trotz (oder wegen) ihrer Gier.
- **Echsenmensch** (seit 2026-10-28, zischt wie alle Echsen). Dass er siezt, ist seine eigene Höflichkeit als Händler; sein Volk duzt sonst jeden.

---

### Ignar, der Glutdrache (`dragon`)
- Alt, träge, gelangweilt und spöttisch. Will nur auf seinem Gold schlafen. Nennt den Spieler „kleiner Schmied“, „kleine Maus“ oder „Made“ und hält ihn für eine schwache kleine Kreatur. Geweckt brüllt er zuerst in Großbuchstaben („WELCHE KLEINE MADE wagt es, MICH …“), danach spricht er wieder ruhig und herablassend.
- Weiß mehr, als er sagt: deutet an, dass nicht nur der Lich die Steine sammelt („Ich habe nicht vom Lich gesprochen.“).
- Gönnt niemandem etwas: Besiegt, erwacht er ein letztes Mal und reißt die Goblinburg mit sich und dem Gold in die Lava („Kein Goblin bekommt davon etwas zurück.“).

## Geheimnisse (Spoiler)

- **Seit Teil 5 enthüllt:** Im Thronsaal der Finsterburg zeigt der König sein wahres Gesicht; ab da darf jede Figur offen über ihn sprechen. Er bleibt höflich und väterlich, und gerade das macht ihn unheimlich. Lake (dunkler Ritter) spricht danach kalt und knapp („Ja, mein König.“).
- **Der König ist der Hauptbösewicht.** Im Geheimen sammelt er die Kristalle (heiligen Steine). Den Feuerkristall hat ihm der Spieler am Ende von Teil 2 selbst gebracht, den Lichtkristall hat er aus Leonheim, den Kristall der Erde aus dem Dorf (über den Lich), den Dunkelkristall aus der Finsterburg, wo er heimlich ebenfalls herrscht. Er hat den legendären Schmied entführt und hält ihn gefangen.
- **Der legendäre Schmied** hat in der Gefangenschaft den Schlüssel für den Dämonenlord schon neu geschmiedet (er hat dieselbe Magie wie der Spieler).
- **Lake des Licht** ahnt nichts, er dient dem König blind.
- **Wer hat den Lich zum Windkristall geführt?** (Vorschlag, Teil 3) Der König: Aurelius hat zuerst ihm berichtet, wo die Elfen den Stein hüten. Die falsche Fährte zeigt auf Lake, der in der Nacht allein an der Ostbrücke war. Der einzige kleine Hinweis auf den König in Teil 3: Elarion gibt sein Kartenstück dem Spieler, nicht ihm („Er? Natürlich. Eine weise Wahl.“).
- **Das Siegel** wird alle tausend Jahre schwach; dann müssen die neun Steine zurück in den Schlüssel. Wer sie alle hat, kann das Tor stattdessen öffnen. Der König lässt sich zum Schein vom Lich „entführen“; mit einer Rede bringt er Lake dazu, den Lich zu töten. Danach wird Lake zum bösen dunklen Ritter, und der König zeigt sein wahres Gesicht.
- **Die Entführung des Königs (Teil 4):** Der König hat sich vom Lich zum Schein „entführen“ lassen, samt Feuer- und Wasserkristall, nachdem der Spieler zum Blitzkristall aufgebrochen war. Das Lösegeld („Der König gegen den Blitz“) soll ihm den fünften Stein bringen. Einziger kleiner Hinweis: Er hatte Lake in dieser Nacht selbst zur Stadtmauer geschickt. Ssaroks Frage („Wer wusste, wo die Elfen ihren Stein hüten?“) zählt den König unter anderen auf, ohne dass jemand ihn verdächtigt.
- **Seit Teil 8 ist alles erzählt:** Die Geheimnisse unten gelten nicht mehr als Spoiler-Sperre. Was am Ende wahr ist (Seelenphiole, viertes Kartenstück, manipulierte Fassung, Motiv des Königs): `docs/STORY_PLAN_6-8.md`, Abschnitt 1.
- **Seit Teil 6 bekannt:** das blaue Licht heißt **Siegelglut** (Aurelius), der legendäre Schmied heißt **Meister Halvard** und lebt unter der Finsterburg (Flüstern des Lichs), Aurelius hat seine Magie verloren. Weitere Wahrheiten (Fassung, Seelenphiole, viertes Kartenstück, Motiv des Königs, Finsterstadt): `docs/STORY_PLAN_6-8.md`, Abschnitt 1.
- Gesamtplan bis zum Ende: `docs/STORY.md`, Abschnitt „Geplant“, und `docs/STORY_PLAN_6-8.md`.

## Offene Fragen

- Arbeitete der Lich für den König (Kern des Lebensbaums gestohlen), oder war er ein Rivale, den der König benutzt?
- Wie hieß der Lich, als er noch lebte? (Elarion kennt den Namen.)
