# Android: APK bauen und aufs Handy bringen

> Kurzanleitung für die Handy-Version. Was sich im Spiel auf dem Handy anders verhält (Tippen, Joystick, größere Fenster), steht in `docs/systeme/ui.md` unter `MobileUi`.

## 1. In einem Schritt

Handy per USB anschließen, dann im Projektordner (Git Bash):

```
bash assets/_reference/android/build_and_install.sh
```

Das Skript baut eine **Test-APK** (Preset „Android Test“, mit Admin-Panel und „Sofort“) aus dem Stand, der gerade im Ordner liegt (Branch und letzter Commit werden angezeigt), und installiert sie über die alte Version. Der Spielstand auf dem Handy bleibt erhalten. Dauer: rund 2 Minuten.

## 2. Was dafür auf dem PC liegt

| Was | Wo |
|---|---|
| Android-SDK (adb, build-tools, platforms) | `D:\AndroidDev\sdk` |
| Java (JDK 17) | `D:\AndroidDev\jdk-17.0.21+9` |
| Godot 4.7.2 (Konsolen-EXE für den Bau ohne Fenster) | `C:\Users\matri\Downloads\Godot_v4.7.2-stable_win64.exe\` |
| Export-Vorlagen für Android | `%APPDATA%\Godot\export_templates` |
| Debug-Schlüssel zum Signieren | `%APPDATA%\Godot\keystores\debug.keystore` |
| Fertige APK | `D:\Smithy\Smithy.apk` (außerhalb des Repos) |

Godot liest die beiden Pfade aus den Editoreinstellungen (Editor » Editoreinstellungen » Export » Android: „Android SDK Path“ und „Java SDK Path“; Datei `%APPDATA%\Godot\editor_settings-4.7.tres`). Umgebungsvariablen wie `ANDROID_HOME` reichen nicht.

## 3. Von Hand

```
# bauen (im Projektordner)
<Godot-Konsolen-EXE> --headless --path . --export-debug "Android" ../Smithy.apk
# Handy prüfen und installieren
D:/AndroidDev/sdk/platform-tools/adb.exe devices
D:/AndroidDev/sdk/platform-tools/adb.exe install -r D:/Smithy/Smithy.apk
```

Auf dem Handy muss einmal das USB-Debugging an sein: Einstellungen » Über das Telefon » 7× auf „Build-Nummer“ tippen, dann Einstellungen » System » Entwickleroptionen » USB-Debugging, und beim ersten Anschließen die Frage „USB-Debugging zulassen?“ bestätigen.

## 4. Wenn es nicht klappt

- **„Ungültiger Android-SDK-Pfad“ / „Ein gültiger Java-SDK-Pfad ist erforderlich“:** die beiden Pfade aus Abschnitt 2 in den Editoreinstellungen eintragen. Godot bricht dann ab, ohne die APK anzufassen: die alte Datei bleibt liegen und sieht aus wie eine neue. Deshalb immer auf die Uhrzeit der Datei achten (das Skript prüft das).
- **`adb devices` zeigt nichts oder „unauthorized“:** Kabel neu einstecken, auf dem Handy die Debugging-Frage bestätigen.
- **`INSTALL_FAILED_UPDATE_INCOMPATIBLE`:** auf dem Handy liegt eine Version mit anderem Schlüssel. Nur dann die App deinstallieren (der Spielstand auf dem Handy geht dabei verloren) und neu installieren.
- **Alte Grafik in der APK:** siehe Punkt 36 in `docs/FEHLERKLASSEN.md` (Import-Cache löschen).

## 5. Release für andere (APK und game.exe)

```
bash assets/_reference/android/build_release.sh
```

Baut `../Smithy.apk` (Preset „Android“: ohne Dev-Tools, Release, mit eigenem Schlüssel signiert) und `../game.exe` + `../game.pck` (Preset „Smithy“). Das Skript bricht ab, wenn das Preset „Android“ `dev_tools` hat oder der Schlüssel fehlt.

**Release-Schlüssel:** liegt nie im Repository. Bei Anton: `D:\SmithyRelease\smithy-release.keystore`, Alias `smithy`, Passwort in `SCHLUESSEL_PASSWORT.txt` daneben (das Skript liest es von dort). Anderswo: Umgebungsvariablen `SMITHY_KEYSTORE`, `SMITHY_KEYSTORE_PASSWORD` (und `SMITHY_KEYSTORE_ALIAS`). **Schlüssel sichern:** Updates einer weitergegebenen APK lassen sich nur mit genau diesem Schlüssel installieren.

- Eine Test-APK (Debug-Schlüssel) und eine Release-APK lassen sich nicht übereinander installieren (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`): einmal deinstallieren, der Spielstand auf dem Handy geht dabei verloren.
- Vor einem neuen Release `version/code` (um 1 erhöhen) und `version/name` im Preset „Android“ hochsetzen, sonst installiert Android kein Update.
- Paketname `com.am.smithy`, nur `arm64-v8a`.
- Bei Anton fehlten zunächst die Android-Vorlagen (nur Windows war installiert): aus `Godot_v4.7.2-stable_export_templates.tpz` die drei `android_*`-Dateien nach `%APPDATA%\Godot\export_templates\4.7.2.stable\` entpacken. Java dort: `C:/Users/Anton/.jdks/openjdk-19.0.2` (Editoreinstellung „Java SDK Path“), Android-SDK `%LOCALAPPDATA%\Android\Sdk`.
