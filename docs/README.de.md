<p align="center"><img src="../Assets/AppIcon.png" width="96" alt="TickTack — eine Uhr mit verblassender Spur"></p>
<h1 align="center">TickTack</h1>
<p align="center"><strong>Ein klarer Blick auf deine Zeit.</strong><br>Native Zeiterfassung für deinen Mac — ohne Konto und ohne Abo.</p>
<p align="center"><a href="https://github.com/Aluhut/TickTack/releases/latest">TickTack herunterladen</a> · <a href="../README.md">English</a> · <a href="FIRST_LAUNCH.md#deutsch">Hilfe beim ersten Start</a></p>

![TickTack im dunklen Modus mit dem erfundenen Projekt Studio North, seinen Einträgen und der aktuellen Gesamtzeit](screenshots/overview-dark.jpg)
<p align="center"><sub>Alle abgebildeten Projekte und Einträge sind frei erfundene Beispieldaten. Die Screenshots zeigen die englische Oberfläche.</sub></p>

## Die Zeit im Blick. Den Kopf bei der Arbeit.

Starte eine Messung und arbeite weiter. Die großen Knöpfe für Start, Pause und Stopp findest du auch im Menüleistenfenster. Die Gesamtzeit zählt deine laufende Messung sofort mit.

In der Tabelle bleibt alles übersichtlich. Ein Klick auf eine Zeile öffnet rechts die vollständigen Angaben: Tätigkeit, Bereich, Notizen, Zeitraum und Stunden. Änderungen werden automatisch gespeichert. Bereits erledigte Arbeit kannst du auch manuell eintragen.

![Bearbeitung eines erfundenen Eintrags im hellen Modus](screenshots/entry-details-light.jpg)

### Jedes Projekt bekommt seinen Platz

Wähle einen Namen und eine von sechs Akzentfarben. Jedes Projekt hat eigene Einträge, eine eigene Gesamtzeit und eigene Exportmöglichkeiten. Du kannst suchen, anders sortieren und mehrere Einträge gleichzeitig löschen. Gelöschte Daten lassen sich wiederherstellen.

![Neues Projekt mit frei gewähltem Namen und violetter Akzentfarbe](screenshots/new-project-dark.jpg)

### Gut lesbar und ganz lokal

Die Grundschrift startet bei 17 Punkten. Im Menü **Darstellung** kannst du sie zwischen 16 und 24 Punkten anpassen. Höhere Zeilen und beschriftete Knöpfe erleichtern die Bedienung. Ist die erste bevorzugte Systemsprache Deutsch, erscheint TickTack auf Deutsch; für jede andere Systemsprache wird Englisch verwendet. Eigene Texte werden nicht übersetzt.

Im Menü **Ablage → Importieren …** kannst du TickTack-Dateien sowie CSV- und Excel-Tabellen mit Vorschau übernehmen. **Ablage → Exportieren** bietet Projektdateien, CSV, gestaltete Excel-Tabellen und PDF-Zeitnachweise. Excel und PDF behalten abwechselnde Zeilenfarben. Mit **Alle Projekte sichern …** speicherst du Projekte samt Einträgen und Farben in einer Datei. Beim Import werden vorhandene Daten nicht überschrieben.

Deine Daten bleiben auf deinem Mac. Es gibt keine Konten, Werbung oder Nutzungsanalyse.

## Installieren

Voraussetzung: **macOS 14 (Sonoma) oder neuer**.

- **[Apple Silicon — M1 und neuer](https://github.com/Aluhut/TickTack/releases/download/v0.10.0/TickTack-0.10.0-macOS-arm64.zip)**
- **[Intel-Macs](https://github.com/Aluhut/TickTack/releases/download/v0.10.0/TickTack-0.10.0-macOS-x86_64.zip)**

ZIP entpacken, **TickTack.app** nach **Programme** ziehen und dort öffnen. Die Downloads sind nicht von Apple notarisiert. Wird der erste Start blockiert, hilft die [Schritt-für-Schritt-Anleitung zu Gatekeeper](FIRST_LAUNCH.md#deutsch).

## Dein erster Eintrag

1. **Ablage → Neues Projekt …** (⌘N): Namen und Farbe wählen.
2. **Neuer Eintrag**: Tätigkeit, Bereich und Notizen ergänzen.
3. **Start**, bei Bedarf **Pause**, abschließend **Stopp & sichern**.

Für manuelle Einträge Dezimalstunden verwenden: **1,5 Stunden = 90 Minuten**. Mit ⌘ mehrere einzelne Zeilen, mit ⇧ einen zusammenhängenden Bereich auswählen. Der Papierkorb entfernt die Auswahl nach einer Bestätigung. Im Ablage-Menü kannst du Projekte löschen und Löschvorgänge wiederherstellen.

## Noch wichtig

**Laufende Messungen vor dem Beenden oder Aktualisieren sichern.** Aktive Timer und Entwürfe werden nach einem Absturz bisher nicht wiederhergestellt. Der Menüleisten-Befehl „Beenden“ sichert die aktuelle Messung; normales Beenden kann ungesicherte Zeit verlieren.

Es gibt keine Cloud-Synchronisierung oder automatischen Backups. TickTack-Dateien lassen sich manuell sichern und als neue Projektkopien importieren. Laufende Messungen, Entwürfe, Einstellungen und Löschverlauf gehören nicht zum Dateiexport. CSV, Excel und PDF enthalten gespeicherte Einträge des ausgewählten Projekts. Neue Installationen starten ohne Beispieldaten.

## Selbst bauen und mitmachen

Mit installierten Apple Command Line Tools im Projektordner ausführen:

```sh
./scripts/test.sh
./scripts/build.sh
open build/TickTack.app
```

Die Werkzeuge lassen sich bei Bedarf mit `xcode-select --install` installieren. [Entwicklerdokumentation](DEVELOPMENT.md), [Bedienungsanleitung](USER_GUIDE.md) und [Hinweise zum Mitmachen](../CONTRIBUTING.md) findest du im Repository.

Quellcode, Dokumentation, das eigene App-Logo und diese Screenshots stehen unter der **[MIT-Lizenz](../LICENSE)**. Apple-Systemkomponenten behalten ihre eigenen Lizenzbedingungen: [Hinweise zu Drittanbietern](../THIRD_PARTY_NOTICES.md).
