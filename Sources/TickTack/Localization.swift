import Foundation

/// Only a German primary language selects German; every other language uses English.
struct Localization {
    let isGerman: Bool
    init(preferredLanguages: [String]) {
        let first = preferredLanguages.first?.lowercased().replacingOccurrences(of: "_", with: "-") ?? "en"
        isGerman = first == "de" || first.hasPrefix("de-")
    }
    var locale: Locale { Locale(identifier: isGerman ? "de_DE" : "en_US") }
    func text(_ german: String) -> String { isGerman ? german : Self.english[german] ?? german }
    static let english: [String: String] = [
        "Türkis": "Teal",
        "Blau": "Blue",
        "Violett": "Purple",
        "Grün": "Green",
        "Datum · neueste zuerst": "Date · newest first",
        "Datum · älteste zuerst": "Date · oldest first",
        "Tätigkeit · A–Z": "Task · A–Z",
        "Bereich · A–Z": "Category · A–Z",
        "Stunden · höchste zuerst": "Hours · highest first",
        "Stunden · niedrigste zuerst": "Hours · lowest first",
        "Ursprüngliche Reihenfolge": "Original order",
        "Kein Projekt ausgewählt": "No project selected",
        "Importiertes Projekt": "Imported project",
        "Neue Tätigkeit": "New task",
        "Position": "Position",
        "Bereich": "Category",
        "Tätigkeit": "Task",
        "Konkreter Umfang / Notizen": "Description / notes",
        "Bearbeitungszeitraum": "Date or date range",
        "Aufwand in Stunden": "Time in hours",
        "Stunden": "Hours",
        "Zeitraum": "Date range",
        "Fortsetzen": "Resume",
        "Start": "Start",
        "Pause": "Pause",
        "Stopp & sichern": "Stop & save",
        "Neuer Eintrag": "New entry",
        "Eintrag bearbeiten": "Edit entry",
        "Details schließen": "Close details",
        "Änderungen werden automatisch gespeichert": "Changes are saved automatically",
        "Messung pausiert": "Timer paused",
        "Messung läuft": "Timer running",
        "Mit Stopp & sichern wird dieser Eintrag übernommen. Du kannst den Text jederzeit ergänzen.": "Stop & save adds this entry to your project. You can edit the text at any time.",
        "Stunden für manuellen Eintrag": "Hours for manual entry",
        "Eintrag hinzufügen": "Add entry",
        "Oder starte oben die Stoppuhr für diese Tätigkeit.": "Or start the timer above for this task.",
        "Pausiert · ": "Paused · ",
        "Messung läuft · ": "Timer running · ",
        "Bereit zum Start": "Ready to start",
        "Tätigkeit beschreiben": "Describe your task",
        "Aktuelle Tätigkeit bearbeiten": "Edit current task",
        "%d gespeicherte Einträge": "%d saved entries",
        "Gesamtzeit dieses Projekts": "Total project time",
        "Inklusive pausierter Messung": "Includes paused timer",
        "Inklusive laufender Messung": "Includes running timer",
        "Alle gespeicherten Einträge": "All saved entries",
        "Einträge durchsuchen": "Search entries",
        "%d Einträge": "%d entries",
        "Sortierung": "Sort by",
        "Bei Zeiträumen zählt das Enddatum. Einträge ohne Datum stehen am Ende.": "Date ranges are sorted by their end date. Entries without dates appear last.",
        "Noch keine Einträge": "No entries yet",
        "Keine Treffer": "No results",
        "Lege einen Eintrag an oder starte die Stoppuhr.": "Add an entry or start the timer.",
        "Versuche einen anderen Suchbegriff.": "Try a different search.",
        "Zeile auswählen für alle Details": "Select a row to see all details",
        "Details": "Details",
        "Ausgewählte Einträge löschen": "Delete selected entries",
        "CSV exportieren": "Export CSV",
        "Projekt: ": "Project: ",
        "Pausiert": "Paused",
        "Gesamtzeit des Projekts": "Total project time",
        "Zeitnachweise öffnen": "Open time entries",
        "Beenden": "Quit",
        "Projekt löschen?": "Delete project?",
        "Abbrechen": "Cancel",
        "Projekt löschen": "Delete project",
        "„%@“ und alle %d Einträge werden entfernt. Unter Datei/Ablage kannst du sie wiederherstellen.": "“%@” and its %d entries will be removed. You can restore them from the File menu.",
        "Einträge löschen?": "Delete entries?",
        "Löschen": "Delete",
        "%d ausgewählte Einträge werden entfernt. Unter Datei/Ablage kannst du sie wiederherstellen.": "%d selected entries will be removed. You can restore them from the File menu.",
        "Neues Projekt": "New project",
        "Projektname": "Project name",
        "Akzentfarbe": "Accent color",
        "Projekt erstellen": "Create project",
        "Schrift vergrößern": "Increase text size",
        "Schrift verkleinern": "Decrease text size",
        "Neues Projekt …": "New project…",
        "Projekt löschen …": "Delete project…",
        "Ausgewählte Einträge löschen …": "Delete selected entries…",
        "Zuletzt Gelöschtes wiederherstellen": "Restore last deletion",
        "Projektfarbe": "Project color",
        "PROJEKTE": "PROJECTS",
        "Zeit": "Time",
        "-Zeiten.csv": "-Times.csv",
        "Export fehlgeschlagen": "Export failed",
        "Position;Bereich;Tätigkeit;Konkreter Umfang;Bearbeitungszeitraum;Aufwand (h)": "Position;Category;Task;Description;Date range;Hours",
        "Erstes Projekt anlegen": "Create your first project",
        "Datei → Neues Projekt …": "File → New project…",
        "Unbekannte TickTack-Dateiversion.": "Unknown TickTack document version.",
        "Die Datei enthält ungültige Projekte oder Zeiten.": "The file contains invalid projects or times.",
        "Spalte %d": "Column %d",
        "Tätigkeit fehlt": "Missing task",
        "Ungültige Stunden": "Invalid hours",
        "Ungültige Anführungszeichen in der Tabelle.": "Invalid quotation marks in the table.",
        "Die Tabelle ist zu groß.": "The table is too large.",
        "Eine Textzelle ist nicht vollständig geschlossen.": "A quoted text cell is not closed.",
        "Bitte die Tabelle als UTF-8-CSV oder Excel-Datei speichern.": "Please save the table as UTF-8 CSV or an Excel file.",
        "Beschädigte Excel-Datei.": "Damaged Excel file.",
        "Beschädigte oder zu große Excel-Datei.": "Damaged or oversized Excel file.",
        "Die Excel-Datei enthält zu viele Bestandteile.": "The Excel file contains too many parts.",
        "Verschlüsselte oder zu große Excel-Dateien werden nicht unterstützt.": "Encrypted or oversized Excel files are not supported.",
        "Nicht unterstütztes XML in der Excel-Datei.": "Unsupported XML in the Excel file.",
        "Beschädigtes XML in der Excel-Datei.": "Damaged XML in the Excel file.",
        "Unvollständige Excel-Datei.": "Incomplete Excel file.",
        "Tabelle": "Worksheet",
        "Keine lesbare Tabelle gefunden.": "No readable worksheet found.",
        "Nur gespeicherte Einträge; ohne laufende Messung.": "Saved entries only; excludes the current timer.",
        "Einträge": "Entries",
        "Übersicht": "Overview",
        "PDF konnte nicht erstellt werden.": "Could not create the PDF.",
        "Zeitnachweis": "Time report",
        "Seite %d / %d": "Page %d / %d",
        "Projektdatei (.ticktack) …": "Project file (.ticktack)…",
        "Alle Projekte sichern …": "Save all projects…",
        "CSV-Tabelle …": "CSV table…",
        "Excel-Tabelle (.xlsx) …": "Excel table (.xlsx)…",
        "PDF-Zeitnachweis …": "PDF time report…",
        "Die Datei ist zu groß (maximal 30 MB).": "The file is too large (maximum 30 MB).",
        "Bitte eine TickTack-, CSV-, TSV- oder XLSX-Datei auswählen.": "Please select a TickTack, CSV, TSV, or XLSX file.",
        "Die Tabelle ist leer.": "The table is empty.",
        "Datei importieren": "Import file",
        " (Import)": " (import)",
        "Datei konnte nicht verarbeitet werden": "Could not process the file",
        "Import prüfen": "Review import",
        "Die Projekte werden als neue Kopien hinzugefügt. Vorhandene Daten bleiben erhalten.": "Projects will be added as new copies. Existing data is kept.",
        "%d Projekte · %d Einträge": "%d projects · %d entries",
        "Zeile": "Row",
        "Prüfung": "Check",
        "Bereit": "Ready",
        "%d gültig · %d fehlerhaft": "%d valid · %d invalid",
        "Gesamt: %@ h": "Total: %@ h",
        "Vorschau: erste 500 Zeilen. Importiert werden alle gültigen Zeilen.": "Preview: first 500 rows. All valid rows will be imported.",
        "Fehlerhafte Zeilen ausdrücklich überspringen": "Explicitly skip invalid rows",
        "Es wird nichts überschrieben.": "Nothing will be overwritten.",
        "Importieren": "Import",
        "Trennzeichen": "Delimiter",
        "Semikolon": "Semicolon",
        "Komma": "Comma",
        "Tabulator": "Tab",
        "Erste Zeile enthält Überschriften": "First row contains headers",
        "Dezimalzeichen": "Decimal separator",
        "Komma (1,5)": "Comma (1,5)",
        "Punkt (1.5)": "Dot (1.5)",
        "Stunden als Dezimalzahl, ohne Tausendertrennzeichen.": "Decimal hours, without thousands separators.",
        "Nicht zuordnen": "Do not map",
        "Ziel": "Destination",
        "Importieren …": "Import…",
        "Exportieren": "Export",
        "Ungültige TickTack-Datei.": "Invalid TickTack file.",
        "Notizen": "Notes",
        "Mehr Spalten als Überschriften": "More columns than headers",
        "Excel unterstützt höchstens 32.767 Zeichen je Zelle. Bitte eine TickTack-Datei verwenden.": "Excel supports at most 32,767 characters per cell. Please use a TickTack file."
    ]
}

enum AppLanguage {
    static let localization = Localization(preferredLanguages: Locale.preferredLanguages)
    static var locale: Locale { localization.locale }
    static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    static func parseISODate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: value), formatter.string(from: date) == value else { return nil }
        return date
    }
    static func transferHours(_ hours: Double) -> String {
        String(format: "%.10f", locale: locale, hours)
    }
    static func csvHours(_ hours: Double) -> String {
        String(format: "%.2f", locale: locale, hours)
    }
}

func L(_ german: String, _ arguments: CVarArg...) -> String {
    let value = AppLanguage.localization.text(german)
    return arguments.isEmpty ? value : String(format: value, locale: AppLanguage.locale, arguments: arguments)
}
