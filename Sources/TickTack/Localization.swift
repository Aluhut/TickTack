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
        "Datei → Neues Projekt …": "File → New project…"
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
    static func csvHours(_ hours: Double) -> String {
        String(format: "%.2f", locale: locale, hours)
    }
}

func L(_ german: String, _ arguments: CVarArg...) -> String {
    let value = AppLanguage.localization.text(german)
    return arguments.isEmpty ? value : String(format: value, locale: AppLanguage.locale, arguments: arguments)
}
