#if SMOKE_TEST
import Foundation
class XCTestCase { }
func XCTAssertTrue(_ value: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(value(), "Expected true", file: file, line: line)
}
func XCTAssertFalse(_ value: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(!value(), "Expected false", file: file, line: line)
}
func XCTAssertNil<T>(_ value: @autoclosure () -> T?, file: StaticString = #file, line: UInt = #line) {
    precondition(value() == nil, "Expected nil", file: file, line: line)
}
func XCTAssertEqual<T: Equatable>(_ a: @autoclosure () -> T, _ b: @autoclosure () -> T, file: StaticString = #file, line: UInt = #line) {
    precondition(a() == b(), "Values differ", file: file, line: line)
}
#else
import XCTest
@testable import TickTack
#endif

final class TickTackTests: XCTestCase {
    func testLanguageFollowsPrimarySystemLanguage() {
        for language in ["de", "de-DE", "de-AT", "de_CH"] {
            XCTAssertTrue(Localization(preferredLanguages: [language]).isGerman)
        }
        for languages in [["en-US"], ["fr-FR", "de-DE"], ["ja-JP"], ["es"], []] {
            let localization = Localization(preferredLanguages: languages)
            XCTAssertFalse(localization.isGerman)
            XCTAssertEqual(localization.text("Neues Projekt"), "New project")
        }
        XCTAssertEqual(Localization(preferredLanguages: ["de"]).text("Neues Projekt"), "Neues Projekt")
    }

    func testDateRangesAndISODateValidation() {
        let legacy = Entry(date: Date(timeIntervalSinceReferenceDate: 0), task: "", period: "13.–19.10.2026", seconds: 0)
        let iso = Entry(date: Date(), task: "", period: "2026-10-13 – 2026-10-19", seconds: 0)
        XCTAssertEqual(legacy.chronologicalDate, AppLanguage.parseISODate("2026-10-19"))
        XCTAssertEqual(iso.chronologicalDate, legacy.chronologicalDate)
        XCTAssertNil(AppLanguage.parseISODate("2026-02-31"))
        XCTAssertNil(Entry(date: Date(timeIntervalSinceReferenceDate: 0), task: "", period: "", seconds: 0).chronologicalDate)
    }

    func testTimerPausesAndKeepsItsProject() async {
        await MainActor.run {
            withStore { store in
                var date = Date(timeIntervalSince1970: 1_700_000_000)
                let tracker = Tracker(defaults: store, now: { date }, startTimer: false)
                tracker.projects = [TimeProject(id: "a", name: "A"), TimeProject(id: "b", name: "B")]
                tracker.activeProjectID = "a"; tracker.task = "Design"
                tracker.start(); date.addTimeInterval(30); tracker.pause()
                date.addTimeInterval(60); tracker.tick()
                XCTAssertEqual(tracker.elapsed, 30)
                tracker.activeProjectID = "b"
                tracker.start(); date.addTimeInterval(15); tracker.stop()
                XCTAssertEqual(tracker.entries.count, 1)
                XCTAssertEqual(tracker.entries[0].seconds, 45)
                XCTAssertEqual(tracker.entries[0].projectID, "a")
                XCTAssertEqual(tracker.currentTotal(for: "a"), 45)
                XCTAssertEqual(tracker.currentTotal(for: "b"), 0)
                let reopened = Tracker(defaults: store, startTimer: false)
                XCTAssertEqual(reopened.entries[0].seconds, 45)
            }
        }
    }

    func testProjectScopedDeletionRestoreAndEmptyRestart() async {
        await MainActor.run {
            withStore { store in
                let tracker = Tracker(defaults: store, startTimer: false)
                tracker.projects = [TimeProject(id: "a", name: "A"), TimeProject(id: "b", name: "B")]
                tracker.activeProjectID = "a"
                let a = Entry(projectID: "a", date: Date(), task: "A", seconds: 3600)
                let b = Entry(projectID: "b", date: Date(), task: "B", seconds: 7200)
                tracker.entries = [a,b]
                tracker.delete([a.id,b.id])
                XCTAssertEqual(tracker.entries.map(\.id), [b.id])
                tracker.restoreLastDeletion()
                XCTAssertEqual(tracker.entries.count, 2)
                tracker.start(); tracker.deleteActiveProject()
                XCTAssertEqual(tracker.projects.count, 2)
                tracker.stop(); tracker.deleteActiveProject()
                XCTAssertEqual(tracker.projects.count, 1)
                tracker.deleteActiveProject()
                let reopened = Tracker(defaults: store, startTimer: false)
                XCTAssertTrue(reopened.projects.isEmpty)
                XCTAssertTrue(reopened.entries.isEmpty)
                reopened.restoreLastDeletion()
                XCTAssertEqual(reopened.projects.count, 1)
                XCTAssertEqual(reopened.entries.first?.projectID, "b")
            }
        }
    }

    func testSortingExportAndEditingAreProjectScoped() async {
        await MainActor.run {
            withStore { store in
                let tracker = Tracker(defaults: store, startTimer: false)
                tracker.projects = [TimeProject(id: "a", name: "A"), TimeProject(id: "b", name: "B")]
                tracker.activeProjectID = "a"
                let older = Entry(projectID: "a", date: Date(), task: "Older", period: "2026-10-12", seconds: 3600)
                let newer = Entry(projectID: "a", date: Date(), task: "Newer", period: "2026-10-28", seconds: 7200)
                tracker.entries = [older, Entry(projectID: "b", date: Date(), task: "Private other project", seconds: 0), newer]
                XCTAssertEqual(tracker.orderedEntries.map(\.task), ["Newer", "Older"])
                tracker.sortOrder = .oldest
                XCTAssertEqual(tracker.orderedEntries.map(\.task), ["Older", "Newer"])
                tracker.textBinding(older, \.task).wrappedValue = "Quote \"and\"; newline\ncontinued"
                let csv = tracker.csvText()
                XCTAssertTrue(csv.contains("\"Quote \"\"and\"\"; newline\ncontinued\""))
                XCTAssertFalse(csv.contains("Private other project"))
                tracker.hoursBinding(newer).wrappedValue = -2
                XCTAssertEqual(tracker.entries.first { $0.id == newer.id }?.seconds, 7200)
                tracker.hoursBinding(newer).wrappedValue = 1.5
                XCTAssertEqual(tracker.currentTotal(for: "a"), 9000)
            }
        }
    }

    func testFreshInstallHasNoPersonalOrExampleData() async {
        await MainActor.run {
            withStore { store in
                let tracker = Tracker(defaults: store, startTimer: false)
                XCTAssertTrue(tracker.projects.isEmpty)
                XCTAssertTrue(tracker.entries.isEmpty)
                tracker.newProjectName = "Personal project"
                tracker.newProjectAccent = .purple
                tracker.createProject()
                let reopened = Tracker(defaults: store, startTimer: false)
                XCTAssertEqual(reopened.activeProjectName, "Personal project")
                XCTAssertEqual(reopened.projects.first?.accentName, ProjectAccent.purple.rawValue)
            }
        }
    }
}

@MainActor private func withStore(_ body: (UserDefaults) -> Void) {
    let domain = "TickTack.Tests." + UUID().uuidString
    let store = UserDefaults(suiteName: domain)!
    defer { store.removePersistentDomain(forName: domain) }
    body(store)
}

#if SMOKE_TEST
@main struct TestRunner {
    static func main() async {
        if let index = CommandLine.arguments.firstIndex(of: "-AppleLanguages"), CommandLine.arguments.indices.contains(index + 1) {
            let requested = CommandLine.arguments[index + 1]
            XCTAssertEqual(AppLanguage.localization.isGerman, requested == "(de)")
        }
        let tests = TickTackTests()
        tests.testLanguageFollowsPrimarySystemLanguage()
        tests.testDateRangesAndISODateValidation()
        await tests.testTimerPausesAndKeepsItsProject()
        await tests.testProjectScopedDeletionRestoreAndEmptyRestart()
        await tests.testSortingExportAndEditingAreProjectScoped()
        await tests.testFreshInstallHasNoPersonalOrExampleData()
        print("6 behavior checks passed")
    }
}
#endif
