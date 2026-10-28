import Foundation
import PDFKit
#if !SMOKE_TEST
import XCTest
@testable import TickTack
#endif

final class TransferTests: XCTestCase {
    private let project = TimeProject(id: "fictional", name: "Paper & Pixel", accentName: "Violett")
    private var sample: Entry {
        Entry(id: UUID(uuidString: "11D20EA8-BDF3-48E2-AD14-A882D1752EA7")!, projectID: "fictional", position: "007", date: Date(timeIntervalSince1970: 1_792_000_000),
              task: "Review \"navigation\"; together", category: "Design", scope: "First line\nSecond line & <details>", period: "2026-10-28", seconds: 3661.25)
    }
    func testDocumentRoundTripAndValidation() throws {
        let document = ProjectDocument(projects: [project], entries: [sample])
        let restored = try ProjectDocument.decode(document.encoded())
        XCTAssertEqual(restored.entries[0].id, document.entries[0].id)
        XCTAssertEqual(restored.entries[0].date, document.entries[0].date)
        XCTAssertEqual(restored.entries[0].seconds, 3661.25)
        XCTAssertEqual(restored.projects[0].accentName, "Violett")
        var invalid = document; invalid.version = 999
        rejects { _ = try invalid.encoded() }
        invalid = document; invalid.entries[0].projectID = "missing"
        rejects { _ = try invalid.encoded() }
        invalid = document; invalid.entries[0].seconds = -1
        rejects { _ = try invalid.encoded() }
        invalid = document; invalid.entries.append(invalid.entries[0])
        rejects { _ = try invalid.encoded() }
        rejects { _ = try ProjectDocument.decode(Data("{}".utf8)) }
    }
    func testCSVVariantsAndInvalidRows() throws {
        let csv = "\u{FEFF}Task;Hours;Description\r\n\"Review; \"\"menu\"\"\";1,5;\"first\nsecond\"\r\nMissing;;note\r\nBad;-2;\r\n"
        XCTAssertEqual(DelimitedText.detect(csv), ";")
        var table = ImportTable(name: "Sample", rows: try DelimitedText.parse(csv, separator: ";"))
        table.suggestMapping()
        XCTAssertTrue(table.decimalComma)
        XCTAssertEqual(table.preview.count, 3)
        XCTAssertEqual(table.preview[0].entry?.task, "Review; \"menu\"")
        XCTAssertEqual(table.preview[0].entry?.scope, "first\nsecond")
        XCTAssertEqual(table.preview[0].entry?.seconds, 5400)
        XCTAssertNil(table.preview[1].entry)
        XCTAssertNil(table.preview[2].entry)
        let commaRows = try DelimitedText.parse("Task,Hours\n\"hello, world\",1.5\n", separator: ",")
        XCTAssertEqual(commaRows[1], ["hello, world", "1.5"])
        XCTAssertEqual(DelimitedText.detect("Task\tHours\nReview\t2\n"), "\t")
        rejects { _ = try DelimitedText.parse("Task;Hours\n\"unfinished;1", separator: ";") }
        rejects { _ = try DelimitedText.parse("\"closed\"oops;1", separator: ";") }
        XCTAssertNil(ImportTable.hours("1,234.5", decimalComma: false))
        XCTAssertNil(ImportTable.hours("NaN", decimalComma: false))
        XCTAssertNil(ImportTable.hours("1e9", decimalComma: false))
        XCTAssertNil(ImportTable.hours("1000001", decimalComma: false))
        XCTAssertEqual(ImportTable.hours("0", decimalComma: true), 0)
        XCTAssertEqual(ImportTable.hours("1.5", decimalComma: false), 1.5)
    }
    func testExcelInteroperabilityAndRoundTrip() throws {
        let data = Spreadsheet.export(project: project, entries: [sample])
        let tables = try Spreadsheet.tables(data)
        XCTAssertEqual(tables.count, 2)
        let row = tables[0].preview[0].entry!
        XCTAssertEqual(row.task, sample.task)
        XCTAssertEqual(row.scope, sample.scope)
        XCTAssertEqual(row.position, "007")
        XCTAssertTrue(abs(row.seconds - sample.seconds) < 0.000001)
        let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/external.xlsx")
        let external = try Spreadsheet.tables(Data(contentsOf: path))[0]
        XCTAssertEqual(external.preview[0].entry?.task, "Review & revise")
        XCTAssertEqual(external.preview[0].entry?.seconds, 5400)
        XCTAssertEqual(external.preview[0].entry?.period, "2026-10-28")
        var tiny = sample; tiny.seconds = 0.001
        let small = try Spreadsheet.tables(Spreadsheet.export(project: project, entries: [tiny]))[0].preview[0].entry!
        XCTAssertTrue(abs(small.seconds - tiny.seconds) < 0.000001)
        var damaged = data; damaged[100] ^= 0xff
        rejects { _ = try Spreadsheet.tables(damaged) }
        rejects { _ = try Spreadsheet.tables(Data("not a zip".utf8)) }
        let xml = SpreadsheetZIP.write([("xl/workbook.xml", "<!DOCTYPE workbook [<!ENTITY a SYSTEM 'file:///etc/passwd'>]><workbook>&a;</workbook>"), ("xl/_rels/workbook.xml.rels", "<Relationships/>")])
        rejects { _ = try Spreadsheet.tables(xml) }
    }
    func testPDFPaginationAndLongNotes() throws {
        var entry = sample
        entry.scope = (1...100).map { "Line \($0): readable notes for the time report." }.joined(separator: "\n")
        let data = try TimeReport.pdf(project: project, entries: [entry, sample])
        let pdf = PDFDocument(data: data)!
        XCTAssertTrue(pdf.pageCount > 1)
        let text = pdf.string ?? ""
        XCTAssertTrue(text.contains("Line 1:"))
        XCTAssertTrue(text.contains("Line 100:"))
        XCTAssertTrue(text.contains("Paper & Pixel"))
        if let path = ProcessInfo.processInfo.environment["TICKTACK_TEST_EXPORTS"] {
            let url = URL(fileURLWithPath: path)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try data.write(to: url.appendingPathComponent("pagination.pdf"))
            try TimeReport.pdf(project: project, entries: [sample, sample, sample]).write(to: url.appendingPathComponent("report.pdf"))
            try Spreadsheet.export(project: project, entries: [sample, sample, sample]).write(to: url.appendingPathComponent("table.xlsx"))
            try ProjectDocument(projects: [project], entries: [sample]).encoded().write(to: url.appendingPathComponent("sample.ticktack"))
        }
    }
    func testImportsKeepExistingProjectsAndCSVPrecision() async throws {
        try await MainActor.run {
            let domain = "TickTack.TransferTests." + UUID().uuidString
            let store = UserDefaults(suiteName: domain)!
            defer { store.removePersistentDomain(forName: domain) }
            let tracker = Tracker(defaults: store, startTimer: false)
            tracker.projects = [project]; tracker.entries = [sample]; tracker.activeProjectID = project.id
            let csv = tracker.csvText()
            var table = ImportTable(name: "CSV", rows: try DelimitedText.parse(csv, separator: ";")); table.suggestMapping()
            XCTAssertTrue(abs(table.preview[0].entry!.seconds - sample.seconds) < 0.000001)
            tracker.start()
            try tracker.importDocument(ProjectDocument(projects: [project], entries: [sample]))
            XCTAssertEqual(tracker.projects.count, 2)
            XCTAssertEqual(tracker.entries.count, 2)
            XCTAssertEqual(tracker.entries[0].id, sample.id)
            XCTAssertTrue(tracker.entries[1].id != sample.id)
            XCTAssertTrue(tracker.entries[1].projectID != project.id)
            XCTAssertTrue(tracker.running)
            XCTAssertEqual(tracker.timerProjectIDForUI, project.id)
            let reopened = Tracker(defaults: store, startTimer: false)
            XCTAssertEqual(reopened.projects.count, 2)
            XCTAssertEqual(reopened.entries.count, 2)
        }
    }
    func testTableImportRequiresExplicitSkippingAndAppends() async throws {
        try await MainActor.run {
            let domain = "TickTack.TransferTests." + UUID().uuidString
            let store = UserDefaults(suiteName: domain)!
            defer { store.removePersistentDomain(forName: domain) }
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("sample.csv")
            try "Task;Hours\nValid;1.5\nInvalid;-2\n".write(to: url, atomically: true, encoding: .utf8)
            let session = try ImportSession(url: url)
            XCTAssertEqual(session.preview.count, 2)
            XCTAssertEqual(session.preview[1].values[.task], "Invalid")
            let tracker = Tracker(defaults: store, startTimer: false)
            tracker.projects = [project]; tracker.entries = [sample]; tracker.activeProjectID = project.id
            session.destination = project.id
            tracker.importSession = session; tracker.commitImport(session)
            XCTAssertEqual(tracker.entries.count, 1)
            XCTAssertTrue(tracker.importSession != nil)
            session.skipInvalid = true; tracker.commitImport(session)
            XCTAssertEqual(tracker.entries.count, 2)
            XCTAssertEqual(tracker.entries.last?.seconds, 5400)
            XCTAssertEqual(tracker.entries.first?.id, sample.id)
            XCTAssertEqual(tracker.projects.count, 1)
            XCTAssertNil(tracker.importSession)
            // A malformed comma-decimal CSV must not silently import its integer part.
            var malformed = ImportTable(name: "Malformed", rows: try DelimitedText.parse("Task,Hours\nReview,1,5", separator: ","))
            malformed.suggestMapping()
            XCTAssertNil(malformed.preview[0].entry)
        }
    }
}

private func rejects(_ body: () throws -> Void) {
    var rejected = false
    do { try body() } catch { rejected = true }
    XCTAssertTrue(rejected)
}
