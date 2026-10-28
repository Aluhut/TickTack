# TickTack

Native Zeiterfassung für macOS ab Version 14: Projekte anlegen, Zeiten messen und alle Einträge übersichtlich bearbeiten. Ohne Konto und ohne Internetverbindung.

[English documentation](../README.md)

## Installieren

Die fertige App unter [Releases](https://github.com/Aluhut/TickTack/releases/latest) herunterladen: Apple Silicon für M1 und neuer, Intel für ältere Intel-Macs. ZIP entpacken und **TickTack.app** nach **Programme** ziehen.

Zum Selbstbauen das Repository über „Code → Download ZIP“ herunterladen und entpacken. Mit installierten Apple Command Line Tools im Projektordner ausführen:

```sh
./scripts/build.sh
open build/TickTack.app
```

Die fertige App aus `build/` nach „Programme“ ziehen. Bei Bedarf lassen sich die Apple Command Line Tools mit `xcode-select --install` installieren. Die App läuft auf Apple-Silicon- und Intel-Macs; das Bauskript verwendet standardmäßig die Architektur des eigenen Macs.

Heruntergeladene, nicht notarisierte Builds können eine ausdrückliche Freigabe durch macOS verlangen. Bitte Apples Hinweise beachten; Sicherheitseinstellungen müssen nicht abgeschaltet werden.

## Bedienung

- **Ablage → Neues Projekt …** (⌘N): Name und eine von sechs Akzentfarben wählen.
- **Neuer Eintrag**: Tätigkeit, Bereich und Notizen ergänzen. „Start“, „Pause“, „Fortsetzen“ und „Stopp & sichern“ steuern die Messung.
- Manuelle Zeiten in Dezimalstunden eingeben: **1,5 Stunden = 90 Minuten**.
- Eine Tabellenzeile auswählen, um rechts alle Details zu bearbeiten. Änderungen werden automatisch gespeichert.
- Mit ⌘ mehrere einzelne Zeilen, mit ⇧ einen zusammenhängenden Bereich auswählen. Über den Papierkorb oder das Ablage-Menü löschen.
- **Ablage → Projekt löschen …** entfernt das ausgewählte Projekt samt Einträgen. Eine zugehörige Messung vorher stoppen.
- **Ablage → Zuletzt Gelöschtes wiederherstellen** nimmt Löschvorgänge schrittweise zurück, auch nach einem Neustart.
- Die große Gesamtzeit zählt die laufende Messung mit. Der CSV-Export enthält nur gespeicherte Einträge des ausgewählten Projekts.
- Die Schriftgröße im Menü **Darstellung** anpassen. Die Einstellung bleibt gespeichert.

## Sprache und Daten

Ist die erste bevorzugte Systemsprache Deutsch, erscheint TickTack auf Deutsch. Für jede andere Systemsprache wird Englisch verwendet. Eigene Projektnamen, Tätigkeiten und Notizen werden nicht übersetzt. Neue Datumsangaben verwenden das eindeutige Format `JJJJ-MM-TT`.

Daten bleiben lokal in den macOS-App-Einstellungen. Es gibt keine Cloud-Synchronisierung und keinen vollständigen Backup-Import. Laufende Messungen und Entwürfe vor dem Beenden sichern; sie werden nach einem Absturz bisher nicht wiederhergestellt.

## Lizenz

Quellcode, Dokumentation und das eigene App-Logo stehen unter der [MIT-Lizenz](../LICENSE). Hinweise zu Apple-Systemkomponenten stehen in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
