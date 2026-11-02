import Foundation
#if !SMOKE_TEST
import XCTest
@testable import TickTack
#endif

final class FormatTests: XCTestCase {
    func testExistingDatesRangesAndTextAreDisplayedConsistently() {
        let german = DisplayFormats(dateOrder: .german)
        XCTAssertEqual(german.period("2026-11-02"), "02.11.2026")
        XCTAssertEqual(german.period("2.11.2026"), "02.11.2026")
        XCTAssertEqual(german.period("13.–19.10.2026"), "13.10.2026 – 19.10.2026")
        XCTAssertEqual(german.period("Datum ergänzen"), "Datum ergänzen")
        XCTAssertEqual(german.period("Notiz vom 2026-11-02"), "Notiz vom 2026-11-02")
        XCTAssertNil(ParsedPeriod.parse("2026-02-31", source: .iso))
        XCTAssertNil(ParsedPeriod.parse("2026-11-02 extra", source: .iso))
        XCTAssertNil(ParsedPeriod.parse("2026-11-03 – 2026-11-02", source: .iso))
        let day = ParsedPeriod.parse("04/05/2026", source: .dayFirst)!
        let month = ParsedPeriod.parse("04/05/2026", source: .monthFirst)!
        XCTAssertEqual(day.canonical, "2026-05-04")
        XCTAssertEqual(month.canonical, "2026-04-05")
    }
    func testTimeAndDurationConversions() {
        var formats = DisplayFormats(dateOrder: .german, clockStyle: .twelve, showClock: true)
        XCTAssertEqual(formats.period("2026-11-02 23:05:06"), "02.11.2026 11:05:06 PM")
        formats.showClock = false
        XCTAssertEqual(formats.period("2026-11-02 23:05:06"), "02.11.2026")
        XCTAssertEqual(ParsedPeriod.parse("11/02/2026 11:05:06 PM", source: .monthFirst)?.canonical, "2026-11-02 23:05:06")
        XCTAssertEqual(DurationStyle.clock.seconds("25:01:02.125", decimalComma: false), 90062.125)
        XCTAssertEqual(DurationStyle.clock.text(90062.125, precise: true), "25:01:02.125000")
        XCTAssertNil(DurationStyle.clock.seconds("01:60:00", decimalComma: false))
        XCTAssertNil(DurationStyle.clock.seconds("-01:30:00", decimalComma: false))
        XCTAssertEqual(DurationStyle.decimal.seconds("1,5", decimalComma: true), 5400)
    }
    func testSettingsDoNotRewriteSavedRecordsAndTransfersUseFormats() async throws {
        try await MainActor.run {
            let domain = "TickTack.FormatTests." + UUID().uuidString
            let store = UserDefaults(suiteName: domain)!
            defer { store.removePersistentDomain(forName: domain) }
            let tracker = Tracker(defaults: store, startTimer: false)
            tracker.projects = [TimeProject(id: "a", name: "Fictional")]; tracker.activeProjectID = "a"
            let entry = Entry(projectID: "a", date: Date(), task: "Test", period: "2026-11-02 23:05:06", seconds: 5400.125)
            tracker.entries = [entry]; tracker.save(); tracker.persistProjects()
            let original = store.data(forKey: "TickTack.entries.v1")
            tracker.formats = DisplayFormats(dateOrder: .german, clockStyle: .twelve, showClock: true, exportStyle: .clock)
            XCTAssertEqual(tracker.displayedPeriod(entry), "02.11.2026 11:05:06 PM")
            XCTAssertEqual(store.data(forKey: "TickTack.entries.v1"), original)
            XCTAssertTrue(tracker.csvText().contains("02.11.2026 11:05:06 PM"))
            XCTAssertTrue(tracker.csvText().contains("01:30:00.125000"))
            let reopened = Tracker(defaults: store, startTimer: false)
            XCTAssertEqual(reopened.formats, tracker.formats)
            XCTAssertEqual(reopened.entries[0].period, entry.period)
            let xlsx = try Spreadsheet.tables(tracker.exportData(.excel))[0]
            XCTAssertEqual(xlsx.preview[0].entry?.seconds, 5400.125)
            XCTAssertEqual(xlsx.preview[0].entry?.period, entry.period)
            var csv = ImportTable(name: "Export", rows: try DelimitedText.parse(tracker.csvText(), separator: ";"))
            csv.dateOrder = .german; csv.suggestMapping()
            XCTAssertEqual(csv.preview[0].entry?.period, entry.period)
            XCTAssertEqual(csv.preview[0].entry?.seconds, 5400.125)
            tracker.formats.dateOrder = .monthFirst
            tracker.periodBinding(entry).wrappedValue = "04/05/2026"
            tracker.formats.dateOrder = .german
            XCTAssertEqual(tracker.displayedPeriod(tracker.entries[0]), "05.04.2026")
            XCTAssertEqual(tracker.entries[0].chronologicalDate, AppLanguage.parseISODate("2026-04-05"))
        }
    }
}
