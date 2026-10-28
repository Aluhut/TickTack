import Foundation

enum TransferError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self { case .invalid(let message): return L(message) }
    }
}

/// A versioned, lossless document for saved projects. Active timers and preferences are not included.
struct ProjectDocument: Codable {
    var format = "TickTack"
    var version = 1
    var projects: [TimeProject]
    var entries: [Entry]

    func encoded() throws -> Data {
        try validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
    static func decode(_ data: Data) throws -> ProjectDocument {
        guard let document = try? JSONDecoder().decode(Self.self, from: data) else { throw TransferError.invalid("Ungültige TickTack-Datei.") }
        try document.validate()
        return document
    }
    func validate() throws {
        let ids = Set(projects.map(\.id))
        guard format == "TickTack", version == 1 else { throw TransferError.invalid("Unbekannte TickTack-Dateiversion.") }
        guard !projects.isEmpty, projects.count <= 10000, entries.count <= 100000,
              ids.count == projects.count, Set(entries.map(\.id)).count == entries.count,
              projects.allSatisfy({ !$0.id.isEmpty && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              entries.allSatisfy({ ids.contains($0.projectID ?? "") && $0.seconds.isFinite && $0.seconds >= 0 && $0.seconds <= 3_600_000_000 && $0.date.timeIntervalSince1970.isFinite })
        else { throw TransferError.invalid("Die Datei enthält ungültige Projekte oder Zeiten.") }
    }
}

enum ImportField: String, CaseIterable, Identifiable {
    case position = "Position", category = "Bereich", task = "Tätigkeit", scope = "Konkreter Umfang / Notizen", period = "Bearbeitungszeitraum", hours = "Stunden"
    var id: String { rawValue }
    var title: String { L(rawValue) }
    var aliases: [String] {
        switch self {
        case .position: return ["position", "nr", "nummer", "no", "number"]
        case .category: return ["bereich", "category", "kategorie"]
        case .task: return ["tätigkeit", "tatigkeit", "task", "activity", "aufgabe"]
        case .scope: return ["konkreterumfang", "konkreterumfangnotizen", "description", "descriptionnotes", "notes", "notizen", "beschreibung"]
        case .period: return ["bearbeitungszeitraum", "daterange", "date", "datum", "zeitraum"]
        case .hours: return ["aufwandh", "aufwandinstunden", "hours", "hour", "stunden", "timehours"]
        }
    }
}

struct ImportRow: Identifiable {
    let id: Int
    let entry: Entry?
    let issue: String?
    let values: [ImportField: String]
}

struct ImportTable {
    var name: String
    var rows: [[String]]
    var rowNumbers: [Int]? = nil
    var hasHeader = true
    var mapping: [ImportField: Int] = [:]
    var decimalComma = AppLanguage.localization.isGerman
    var headers: [String] {
        let count = rows.map(\.count).max() ?? 0
        return (0..<count).map { index in
            if hasHeader, let row = rows.first, index < row.count, !row[index].isEmpty { return "\(index + 1) · \(row[index])" }
            return L("Spalte %d", index + 1)
        }
    }
    mutating func suggestMapping() {
        mapping = [:]
        guard hasHeader, let row = rows.first else { return }
        for field in ImportField.allCases {
            if let index = row.firstIndex(where: { field.aliases.contains(Self.normalized($0)) }) { mapping[field] = index }
        }
        if let column = mapping[.hours] {
            let examples = rows.dropFirst().compactMap { $0.indices.contains(column) ? $0[column] : nil }
            if examples.contains(where: { $0.contains(",") }) { decimalComma = true }
            else if examples.contains(where: { $0.contains(".") }) { decimalComma = false }
        }
    }
    static func normalized(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }
    static func hours(_ value: String, decimalComma: Bool) -> Double? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // Grouping is deliberately unsupported: guessing 1,234 can silently change a time by 1000×.
        let pattern = decimalComma ? #"^\+?[0-9]+(?:,[0-9]+)?$"# : #"^\+?[0-9]+(?:\.[0-9]+)?$"#
        guard value.range(of: pattern, options: .regularExpression) != nil,
              let number = Double(value.replacingOccurrences(of: ",", with: ".")), number.isFinite,
              number >= 0, number <= 1_000_000 else { return nil }
        return number
    }
    var preview: [ImportRow] {
        let offset = hasHeader ? 1 : 0
        return rows.dropFirst(offset).enumerated().compactMap { index, row in
            guard row.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { return nil }
            func value(_ field: ImportField) -> String {
                guard let column = mapping[field], row.indices.contains(column) else { return "" }
                return row[column]
            }
            let sourceRow = rowNumbers.flatMap { $0.indices.contains(index + offset) ? $0[index + offset] : nil } ?? index + offset + 1
            let values = Dictionary(uniqueKeysWithValues: ImportField.allCases.map { ($0, value($0)) })
            if hasHeader, row.count > (rows.first?.count ?? 0) {
                return ImportRow(id: sourceRow, entry: nil, issue: L("Mehr Spalten als Überschriften"), values: values)
            }
            let task = value(.task)
            guard !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return ImportRow(id: sourceRow, entry: nil, issue: L("Tätigkeit fehlt"), values: values)
            }
            guard let hours = Self.hours(value(.hours), decimalComma: decimalComma) else {
                return ImportRow(id: sourceRow, entry: nil, issue: L("Ungültige Stunden"), values: values)
            }
            let period = value(.period)
            let entry = Entry(position: value(.position).isEmpty ? nil : value(.position),
                              date: AppLanguage.parseISODate(period) ?? Date(timeIntervalSinceReferenceDate: 0),
                              task: task, category: value(.category), scope: value(.scope), period: period, seconds: hours * 3600)
            return ImportRow(id: sourceRow, entry: entry, issue: nil, values: values)
        }
    }
}

enum DelimitedText {
    static func parse(_ text: String, separator: Character) throws -> [[String]] {
        let chars = Array(text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text)
        var rows: [[String]] = [], row: [String] = [], field = ""
        var quoted = false, closed = false, i = 0, fieldBytes = 0
        func endField() { row.append(field); field = ""; closed = false; fieldBytes = 0 }
        func endRow() { endField(); rows.append(row); row = [] }
        while i < chars.count {
            let ch = chars[i]
            if quoted {
                if ch == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" { field.append("\""); fieldBytes += 1; i += 1 }
                    else { quoted = false; closed = true }
                } else { field.append(ch); fieldBytes += ch.utf8.count }
            } else if ch == separator { endField() }
            else if ch == "\n" || ch == "\r" || ch == "\r\n" {
                endRow()
                if ch == "\r", i + 1 < chars.count, chars[i + 1] == "\n" { i += 1 }
            } else if ch == "\"", field.isEmpty, !closed { quoted = true }
            else {
                guard !closed, ch != "\"" else { throw TransferError.invalid("Ungültige Anführungszeichen in der Tabelle.") }
                field.append(ch); fieldBytes += ch.utf8.count
            }
            guard fieldBytes <= 1_000_000, row.count <= 256, rows.count <= 100000 else {
                throw TransferError.invalid("Die Tabelle ist zu groß.")
            }
            i += 1
        }
        guard !quoted else { throw TransferError.invalid("Eine Textzelle ist nicht vollständig geschlossen.") }
        if !field.isEmpty || !row.isEmpty || closed { endRow() }
        return rows
    }
    static func detect(_ text: String) -> Character {
        [Character(";"), Character(","), Character("\t")].max { a, b in
            func score(_ separator: Character) -> Int {
                guard let rows = try? parse(text, separator: separator) else { return 0 }
                let counts = rows.prefix(20).map(\.count).filter { $0 > 1 }
                return counts.count * 100 + (counts.min() ?? 0)
            }
            return score(a) < score(b)
        } ?? ";"
    }
    static func text(from data: Data) throws -> String {
        if let text = String(data: data, encoding: .utf8) { return text }
        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]), let text = String(data: data, encoding: .utf16) { return text }
        throw TransferError.invalid("Bitte die Tabelle als UTF-8-CSV oder Excel-Datei speichern.")
    }
}
