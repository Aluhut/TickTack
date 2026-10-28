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
        let isoExpression = try! NSRegularExpression(pattern: #"\d{4}-\d{2}-\d{2}"#)
        let source = period as NSString
        if let match = isoExpression.matches(in: period, range: NSRange(location: 0, length: source.length)).last,
           let date = AppLanguage.parseISODate(source.substring(with: match.range)) { return date }
        let expression = try! NSRegularExpression(pattern: #"(\d{1,2})\.(\d{1,2})\.(\d{4})"#)
        let text = period as NSString
        guard let match = expression.matches(in: period, range: NSRange(location: 0, length: text.length)).last else {
            return date.timeIntervalSinceReferenceDate == 0 ? nil : date
        }
        let components = DateComponents(year: Int(text.substring(with: match.range(at: 3))), month: Int(text.substring(with: match.range(at: 2))), day: Int(text.substring(with: match.range(at: 1))))
        let calendar = Calendar(identifier: .gregorian)
        guard let parsed = calendar.date(from: components), calendar.dateComponents([.year, .month, .day], from: parsed) == components else { return nil }
        return parsed
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

