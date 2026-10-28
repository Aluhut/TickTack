import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor final class Tracker: NSObject, ObservableObject {
    @Published var importSession: ImportSession?
    @Published var showFileImporter = false
    @Published var showFileExporter = false
    @Published var exportDocument: TransferFile?
    var exportContentType = UTType.data
    var exportName = "TickTack"
    @Published var projects: [TimeProject] = []
    @Published var activeProjectID = "" {
        didSet { selection.removeAll(); showDraft = false; search = ""; defaults.set(activeProjectID, forKey: "TickTack.activeProject") }
    }
    @Published var interfaceFontSize: Double = 17 {
        didSet { defaults.set(interfaceFontSize, forKey: "TickTack.fontSize") }
    }
    @Published var confirmProjectDeletion = false
    @Published var confirmEntryDeletion = false
    @Published var deletedItems: [DeletedItems] = []
    var hasActiveProject: Bool { projects.contains { $0.id == activeProjectID } }
    var canDeleteProject: Bool { hasActiveProject && !(running && timerProjectID == activeProjectID) }
    @Published var showNewProject = false
    @Published var newProjectName = ""
    @Published var newProjectAccent: ProjectAccent = .teal
    var activeAccent: Color { projects.first { $0.id == activeProjectID }?.accent ?? .teal }
    func setProjectAccent(_ accent: ProjectAccent) {
        guard let index = projects.firstIndex(where: { $0.id == activeProjectID }) else { return }
        projects[index].accentName = accent.rawValue
        persistProjects()
    }
    func persistProjects() {
        if let data = try? JSONEncoder().encode(projects) { defaults.set(data, forKey: "TickTack.projects") }
    }
    private var timerProjectID: String?
    var activeProjectName: String { projects.first { $0.id == activeProjectID }?.name ?? L("Kein Projekt ausgewählt") }
    var timerProjectIDForUI: String { timerProjectID ?? activeProjectID }
    var timerProjectName: String { projects.first { $0.id == (timerProjectID ?? activeProjectID) }?.name ?? activeProjectName }
    var projectEntries: [Entry] { entries.filter { ($0.projectID ?? "legacy") == activeProjectID } }
    func currentTotal(for projectID: String) -> Double {
        let saved = entries.filter { ($0.projectID ?? "legacy") == projectID }.reduce(0) { $0 + $1.seconds }
        return saved + (running && timerProjectID == projectID ? elapsed : 0)
    }
    var activeProjectTotal: Double { currentTotal(for: activeProjectID) }
    var activeProjectHasMeasurement: Bool { running && timerProjectID == activeProjectID }

    func beginNewProject() { newProjectName = ""; newProjectAccent = .teal; showNewProject = true }
    func createProject() {
        let name = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let project = TimeProject(id: UUID().uuidString, name: name, accentName: newProjectAccent.rawValue)
        projects.append(project)
        if let data = try? JSONEncoder().encode(projects) { defaults.set(data, forKey: "TickTack.projects") }
        activeProjectID = project.id; showNewProject = false
        if !running { task = ""; category = ""; scope = "" }
    }
    @Published var sortOrder: EntrySort = .newest {
        didSet { defaults.set(sortOrder.rawValue, forKey: "TickTack.sortOrder") }
    }
    @Published var search = ""
    @Published var showDraft = false
    @Published var manualHours = 0.0
    @Published var draftPeriod = AppLanguage.dateString(Date())
    @Published var selection = Set<UUID>()
    @Published var entries: [Entry] = []
    @Published var category = ""
    @Published var scope = ""
    @Published var task = ""
    @Published var running = false
    @Published var paused = false
    @Published var elapsed: Double = 0
    private var segment: Date?
    private var accumulated: Double = 0
    private var timer: Timer?
    private let key = "TickTack.entries.v1"
    private let defaults: UserDefaults
    private let now: () -> Date
    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init, startTimer: Bool = true) {
        self.defaults = defaults
        self.now = now
        super.init()
        if defaults.data(forKey: key) == nil,
           let legacyKey = Bundle.main.object(forInfoDictionaryKey: "TickTackLegacyEntriesKey") as? String,
           let legacyData = defaults.data(forKey: legacyKey) { defaults.set(legacyData, forKey: key) }
        if let data = defaults.data(forKey: "TickTack.projects"), let saved = try? JSONDecoder().decode([TimeProject].self, from: data) { projects = saved }
        if let data = defaults.data(forKey: "TickTack.deletedItems"), let saved = try? JSONDecoder().decode([DeletedItems].self, from: data) { deletedItems = saved }
        if let savedID = defaults.string(forKey: "TickTack.activeProject"), projects.contains(where: { $0.id == savedID }) { activeProjectID = savedID }
        if let data = defaults.data(forKey: key), let saved = try? JSONDecoder().decode([Entry].self, from: data) { entries = saved }
        if !projects.contains(where: { $0.id == activeProjectID }) { activeProjectID = projects.first?.id ?? "" }
        if !entries.isEmpty && projects.isEmpty {
            projects = [TimeProject(id: "legacy", name: L("Importiertes Projekt"))]
            activeProjectID = "legacy"; persistProjects()
        }
        if entries.contains(where: { $0.projectID == nil }), let firstProject = projects.first {
            for index in entries.indices where entries[index].projectID == nil { entries[index].projectID = firstProject.id }
            save()
        }
        let font = defaults.double(forKey: "TickTack.fontSize")
        interfaceFontSize = font >= 16 ? min(font, 24) : 17
        sortOrder = EntrySort(rawValue: defaults.string(forKey: "TickTack.sortOrder") ?? "") ?? .newest
        guard startTimer else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }
    func tick() { elapsed = accumulated + (segment.map { max(0, now().timeIntervalSince($0)) } ?? 0) }
    func start() {
        guard (!running || paused), running || hasActiveProject else { return }
        if !running { timerProjectID = activeProjectID }
        running = true; paused = false; segment = now(); tick()
    }
    func pause() {
        guard running && !paused else { return }
        tick(); accumulated = elapsed; segment = nil; paused = true
    }
    func stop() {
        guard running else { return }; tick()
        if elapsed > 0 {
            entries.insert(Entry(projectID: timerProjectID ?? activeProjectID, date: now(), task: task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? L("Neue Tätigkeit") : task, category: category, scope: scope, period: AppLanguage.dateString(now()), seconds: elapsed), at: 0)
            save()
            selection = [entries[0].id]; showDraft = false
        }
        running = false; paused = false; segment = nil; accumulated = 0; elapsed = 0; timerProjectID = nil
    }
    var orderedEntries: [Entry] {
        projectEntries.enumerated().sorted { left, right in
            let a = left.element, b = right.element
            switch sortOrder {
            case .newest, .oldest:
                let ad = a.chronologicalDate, bd = b.chronologicalDate
                if ad == nil && bd != nil { return false }
                if ad != nil && bd == nil { return true }
                if let ad, let bd, ad != bd { return sortOrder == .newest ? ad > bd : ad < bd }
                if a.date != b.date { return sortOrder == .newest ? a.date > b.date : a.date < b.date }
            case .task:
                let comparison = a.task.localizedStandardCompare(b.task)
                if comparison != .orderedSame { return comparison == .orderedAscending }
            case .category:
                let comparison = a.category.localizedStandardCompare(b.category)
                if comparison != .orderedSame { return comparison == .orderedAscending }
            case .hoursDescending:
                if a.seconds != b.seconds { return a.seconds > b.seconds }
            case .hoursAscending:
                if a.seconds != b.seconds { return a.seconds < b.seconds }
            case .original:
                // Imported rows retain their original order; newly inserted rows follow them.
                let ai = Int(a.position ?? "") ?? (a.date.timeIntervalSinceReferenceDate == 0 ? left.offset + 1 : Int.max)
                let bi = Int(b.position ?? "") ?? (b.date.timeIntervalSinceReferenceDate == 0 ? right.offset + 1 : Int.max)
                if ai != bi { return ai < bi }
                if a.date != b.date { return a.date < b.date }
            }
            return left.offset < right.offset
        }.map(\.element)
    }
    func newEntry() {
        if running { activeProjectID = timerProjectID ?? activeProjectID }
        selection.removeAll(); showDraft = true
        if !running { task = ""; category = ""; scope = ""; manualHours = 0; draftPeriod = AppLanguage.dateString(Date()) }
    }
    func addManualEntry() {
        guard hasActiveProject, !running, !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              manualHours.isFinite, manualHours >= 0, manualHours <= 1000000 else { return }
        let entry = Entry(projectID: activeProjectID, date: now(), task: task, category: category, scope: scope, period: draftPeriod, seconds: manualHours * 3600)
        entries.insert(entry, at: 0); save(); selection = [entry.id]; showDraft = false
    }
    func textBinding(_ entry: Entry, _ path: WritableKeyPath<Entry, String>) -> Binding<String> {
        Binding(get: { self.entries.first(where: { $0.id == entry.id })?[keyPath: path] ?? "" }, set: { value in
            guard let index = self.entries.firstIndex(where: { $0.id == entry.id }) else { return }
            self.entries[index][keyPath: path] = value
            self.save()
        })
    }
    func positionBinding(_ entry: Entry) -> Binding<String> {
        Binding(get: {
            guard let index = self.entries.firstIndex(where: { $0.id == entry.id }) else { return "" }
            return self.entries[index].position ?? String(index + 1)
        }, set: { value in
            guard let index = self.entries.firstIndex(where: { $0.id == entry.id }) else { return }
            self.entries[index].position = value; self.save()
        })
    }
    func hoursBinding(_ entry: Entry) -> Binding<Double> {
        Binding(get: { (self.entries.first(where: { $0.id == entry.id })?.seconds ?? 0) / 3600 }, set: { hours in
            guard hours.isFinite, hours >= 0, hours <= 1000000,
                  let index = self.entries.firstIndex(where: { $0.id == entry.id }) else { return }
            self.entries[index].seconds = hours * 3600; self.save()
        })
    }
    func save() { if let data = try? JSONEncoder().encode(entries) { defaults.set(data, forKey: key) } }
    func persistDeletedItems() {
        if let data = try? JSONEncoder().encode(deletedItems) { defaults.set(data, forKey: "TickTack.deletedItems") }
    }
    func delete(_ ids: Set<UUID>) {
        let removed = projectEntries.filter { ids.contains($0.id) }
        guard !removed.isEmpty else { return }
        deletedItems.append(DeletedItems(project: nil, entries: removed)); persistDeletedItems()
        let removedIDs = Set(removed.map(\.id))
        entries.removeAll { removedIDs.contains($0.id) }; selection.removeAll(); save()
    }
    func deleteActiveProject() {
        guard canDeleteProject, let project = projects.first(where: { $0.id == activeProjectID }) else { return }
        deletedItems.append(DeletedItems(project: project, entries: projectEntries)); persistDeletedItems()
        entries.removeAll { ($0.projectID ?? "legacy") == project.id }
        projects.removeAll { $0.id == project.id }
        activeProjectID = projects.first?.id ?? ""
        persistProjects(); save()
        if projects.isEmpty { task = ""; category = ""; scope = "" }
    }
    func restoreLastDeletion() {
        guard let removed = deletedItems.last else { return }
        if let project = removed.project, !projects.contains(where: { $0.id == project.id }) { projects.append(project) }
        let restoredEntries = removed.entries.map { item -> Entry in
            var entry = item
            if entry.projectID == nil { entry.projectID = removed.project?.id ?? projects.first?.id ?? "legacy" }
            return entry
        }
        let existingIDs = Set(entries.map(\.id))
        entries.append(contentsOf: restoredEntries.filter { !existingIDs.contains($0.id) })
        if let project = removed.project { activeProjectID = project.id }
        else if let entry = restoredEntries.first { activeProjectID = entry.projectID ?? "legacy"; selection = Set(removed.entries.map(\.id)) }
        persistProjects(); save()
        deletedItems.removeLast(); persistDeletedItems()
    }
    func csvText() -> String {
        func quote(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        let rows = orderedEntries.enumerated().map { index, entry in
            [quote(entry.position ?? String(index + 1)), quote(entry.category), quote(entry.task), quote(entry.scope), quote(entry.period), quote(AppLanguage.transferHours(entry.seconds / 3600))].joined(separator: ";")
        }
        return "\u{FEFF}" + L("Position;Bereich;Tätigkeit;Konkreter Umfang;Bearbeitungszeitraum;Aufwand (h)") + "\n" + rows.joined(separator: "\n")
    }
}
