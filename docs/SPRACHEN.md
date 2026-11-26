# Sprachen

Wie in Smithy: Der deutsche Text ist der Schlüssel. Jede andere Sprache ist eine Datei `locale/<code>.po`. Fehlt eine Übersetzung, erscheint der deutsche Text. Sprachen: Deutsch, Englisch, Spanisch, Französisch, Portugiesisch (Brasilien), Russisch, Japanisch, Chinesisch, Persisch. Ohne gewählte Sprache startet das Spiel in der Systemsprache, sonst auf Englisch; beim ersten Start kommt die Flaggen-Auswahl, später über Einstellungen › Sprache.

**Ablauf bei neuen Texten:**

1. Text auf Deutsch schreiben (in `.tscn` als `text`, im Code über `Language.translate("…")`, in `data/*.json` als `name`/`desc`).
2. In `assets/_reference/i18n/translations.json` eintragen: `"Deutscher Text": {"en": "…", "es": "…", "fr": "…", "pt": "…", "ru": "…", "ja": "…", "zh": "…", "fa": "…"}`.
3. `py assets/_reference/i18n/build_po.py` schreibt alle `.po` neu und meldet jeden fehlenden Text. Fertig erst bei „0 problems“.

Schriften: Micro 5 (Pixel, nur lateinisch), dazu Tiny5 (Kyrillisch), Fusion Pixel (Chinesisch/Japanisch) und Vazirmatn (Persisch) als Rückfall (`Language.FALLBACK_FONTS`).
