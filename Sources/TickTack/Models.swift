import SwiftUI
import AppKit

struct Entry: Identifiable, Codable {
    var id = UUID()
    var projectID: String? = nil
    var position: String? = nil
    var date: Date
    var task: String
    var category: String = ""
    var scope: String = ""
    var period: String = ""
    var seconds: Double
    var periodDateOrder: String? = nil
}

struct TimeProject: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var accentName: String? = nil
    var accent: Color { ProjectAccent(rawValue: accentName ?? "")?.color ?? .teal }
}

enum ProjectAccent: String, CaseIterable, Identifiable {
    case teal = "Türkis", blue = "Blau", purple = "Violett", pink = "Pink", orange = "Orange", green = "Grün"
    var id: String { rawValue }
    var title: String { L(rawValue) }
    var color: Color {
        switch self {
        case .teal: return .teal
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .orange: return .orange
        case .green: return .green
        }
    }
}

enum EntrySort: String, CaseIterable, Identifiable {
    case newest = "Datum · neueste zuerst"
    case oldest = "Datum · älteste zuerst"
    case task = "Tätigkeit · A–Z"
    case category = "Bereich · A–Z"
    case hoursDescending = "Stunden · höchste zuerst"
    case hoursAscending = "Stunden · niedrigste zuerst"
    case original = "Ursprüngliche Reihenfolge"
    var id: String { rawValue }
    var title: String { L(rawValue) }
}

extension Entry {
    var chronologicalDate: Date? {
        if let parsed = ParsedPeriod.parse(period, source: DateOrder(rawValue: periodDateOrder ?? "") ?? .german) { return parsed.parts.last?.date }
        return date.timeIntervalSinceReferenceDate == 0 ? nil : date
    }
}

struct DeletedItems: Codable {
    var project: TimeProject?
    var entries: [Entry]
}


func duration(_ seconds: Double) -> String {
    let s = Int(seconds)
    return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
}

