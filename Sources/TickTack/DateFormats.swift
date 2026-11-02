import Foundation
import SwiftUI

enum DateOrder: String, Codable, CaseIterable, Identifiable {
    case german, iso, dayFirst, monthFirst
    var id: String { rawValue }
    var pattern: String {
        switch self { case .german: return "dd.MM.yyyy"; case .iso: return "yyyy-MM-dd"; case .dayFirst: return "dd/MM/yyyy"; case .monthFirst: return "MM/dd/yyyy" }
    }
    var title: String {
        switch self { case .german: return "31.12.2026"; case .iso: return "2026-12-31"; case .dayFirst: return "31/12/2026"; case .monthFirst: return "12/31/2026" }
    }
}

enum ClockStyle: String, Codable, CaseIterable, Identifiable {
    case twentyFour, twelve
    var id: String { rawValue }
    var title: String { self == .twentyFour ? "23:05" : "11:05 PM" }
}

enum DurationStyle: String, Codable, CaseIterable, Identifiable {
    case decimal, clock
    var id: String { rawValue }
    var title: String { self == .decimal ? L("Dezimalstunden (1,5 h)") : L("Stunden:Minuten:Sekunden (01:30:00)") }
    func text(_ seconds: Double, precise: Bool = false) -> String {
        if self == .decimal { return precise ? AppLanguage.transferHours(seconds / 3600) : AppLanguage.csvHours(seconds / 3600) }
        if !precise { return duration(seconds) }
        let rounded = (seconds * 1_000_000).rounded() / 1_000_000
        let whole = Int(rounded), fraction = rounded - Double(whole)
        let suffix = String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), fraction).dropFirst()
        return duration(Double(whole)) + (fraction > 0 ? String(suffix) : "")
    }
    func seconds(_ text: String, decimalComma: Bool) -> Double? {
        if self == .decimal { return ImportTable.hours(text, decimalComma: decimalComma).map { $0 * 3600 } }
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.range(of: #"^\d{1,10}:[0-5]\d:[0-5]\d(?:[.,]\d{1,6})?$"#, options: .regularExpression) != nil else { return nil }
        let parts = text.replacingOccurrences(of: ",", with: ".").split(separator: ":").compactMap { Double($0) }
        guard parts.count == 3 else { return nil }
        let seconds = parts[0] * 3600 + parts[1] * 60 + parts[2]
        return seconds <= 3_600_000_000 ? seconds : nil
    }
}

struct DisplayFormats: Codable, Equatable {
    var dateOrder: DateOrder = AppLanguage.localization.isGerman ? .german : .iso
    var clockStyle: ClockStyle = .twentyFour
    var showClock = false
    var totalStyle: DurationStyle = .clock
    var exportStyle: DurationStyle = .decimal

    func period(_ value: String, source: DateOrder? = nil) -> String {
        guard let period = ParsedPeriod.parse(value, source: source ?? dateOrder) else { return value }
        return period.parts.map { part in
            let formatter = ParsedPeriod.formatter(dateOrder.pattern + (showClock && part.hasClock ? (clockStyle == .twelve ? " hh:mm:ss a" : " HH:mm:ss") : ""))
            return formatter.string(from: part.date)
        }.joined(separator: " – ")
    }
    func total(_ seconds: Double) -> String { totalStyle.text(seconds) + (totalStyle == .decimal ? " h" : "") }
}

struct ParsedPeriod {
    private final class Cached {
        let value: ParsedPeriod?
        init(_ value: ParsedPeriod?) { self.value = value }
    }
    private static let cache: NSCache<NSString, Cached> = {
        let cache = NSCache<NSString, Cached>(); cache.countLimit = 2048; return cache
    }()
    struct Part { var date: Date; var hasClock: Bool }
    var parts: [Part]
    var canonical: String {
        parts.map { Self.formatter($0.hasClock ? "yyyy-MM-dd HH:mm:ss" : "yyyy-MM-dd").string(from: $0.date) }.joined(separator: " – ")
    }
    static func formatter(_ pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = pattern; formatter.isLenient = false
        return formatter
    }
    static func parse(_ value: String, source: DateOrder) -> ParsedPeriod? {
        let key = (TimeZone.current.identifier + "|" + source.rawValue + "|" + value) as NSString
        if let cached = cache.object(forKey: key) { return cached.value }
        let result = parseUncached(value, source: source)
        cache.setObject(Cached(result), forKey: key)
        return result
    }
    private static func parseUncached(_ value: String, source: DateOrder) -> ParsedPeriod? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // Expand legacy ranges such as 13.–19.10.2026 without altering the stored original.
        let expression = try! NSRegularExpression(pattern: #"^(\d{1,2})\.\s*[–—-]\s*(\d{1,2})\.(\d{1,2})\.(\d{4})$"#)
        let ns = value as NSString
        if let match = expression.firstMatch(in: value, range: NSRange(location: 0, length: ns.length)) {
            func part(_ group: Int) -> String { ns.substring(with: match.range(at: group)) }
            return parse("\(part(1)).\(part(3)).\(part(4)) – \(part(2)).\(part(3)).\(part(4))", source: .german)
        }
        let separated = value.replacingOccurrences(of: #"\s+[—-]\s+|\s*[–]\s*"#, with: "|", options: .regularExpression).components(separatedBy: "|")
        guard (1...2).contains(separated.count) else { return nil }
        var parts: [Part] = []
        for text in separated {
            let text = text.trimmingCharacters(in: .whitespaces)
            let order: DateOrder = text.range(of: #"^\d{4}-"#, options: .regularExpression) != nil ? .iso : text.contains(".") && !text.contains("/") ? .german : source
            let datePattern = order == .german ? "d.M.yyyy" : order == .dayFirst ? "d/M/yyyy" : order == .monthFirst ? "M/d/yyyy" : order.pattern
            var found: Part?
            for suffix in ["", " HH:mm:ss", " HH:mm", " h:mm:ss a", " h:mm a", "'T'HH:mm:ss"] {
                let formatter = formatter(datePattern + suffix)
                guard let date = formatter.date(from: text) else { continue }
                // DateFormatter can accept trailing garbage; require the complete date shape as well.
                let dateShape = order == .iso ? #"\d{4}-\d{2}-\d{2}"# : order == .german ? #"\d{1,2}\.\d{1,2}\.\d{4}"# : #"\d{1,2}/\d{1,2}/\d{4}"#
                let timeShape = suffix.isEmpty ? "" : suffix.contains("a") ? #" \d{1,2}:\d{2}(?::\d{2})? [AP]M"# : #"[ T]\d{2}:\d{2}(?::\d{2})?"#
                guard text.range(of: "^" + dateShape + timeShape + "$", options: .regularExpression) != nil else { continue }
                found = Part(date: date, hasClock: !suffix.isEmpty); break
            }
            guard let found else { return nil }
            parts.append(found)
        }
        guard parts.count == 1 || parts[0].date <= parts[1].date else { return nil }
        return ParsedPeriod(parts: parts)
    }
}

struct FormatSettings: View {
    @ObservedObject var tracker: Tracker
    var body: some View {
        Form {
            Section(L("Datum und Uhrzeit")) {
                Picker(L("Datumsformat"), selection: $tracker.formats.dateOrder) { ForEach(DateOrder.allCases) { Text($0.title).tag($0) } }
                Toggle(L("Vorhandene Uhrzeiten beim Datum anzeigen"), isOn: $tracker.formats.showClock)
                Picker(L("Uhrzeitformat"), selection: $tracker.formats.clockStyle) { ForEach(ClockStyle.allCases) { Text($0.title).tag($0) } }
                Text(tracker.formats.period("2026-12-31 23:05:00", source: .iso)).font(.title3.monospacedDigit())
            }
            Section(L("Dauer")) {
                Picker(L("Stoppuhr und Gesamtzeit"), selection: $tracker.formats.totalStyle) { ForEach(DurationStyle.allCases) { Text($0.title).tag($0) } }
                Picker(L("Aufwand in CSV, Excel und PDF"), selection: $tracker.formats.exportStyle) { ForEach(DurationStyle.allCases) { Text($0.title).tag($0) } }
            }
            Text(L("Die Auswahl gilt sofort für Anzeige und Exporte. Originalangaben bleiben gespeichert. Freie Texte bleiben unverändert; beim Import kannst du das Quellformat wählen."))
                .font(.callout).foregroundStyle(.secondary)
        }.formStyle(.grouped).padding(16).frame(width: 620).font(.system(size: 17))
    }
}
