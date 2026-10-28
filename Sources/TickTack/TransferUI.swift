import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum ExportKind: String, CaseIterable {
    case project, csv, excel, pdf, allProjects
    var suffix: String { switch self { case .project, .allProjects: return "ticktack"; case .csv: return "csv"; case .excel: return "xlsx"; case .pdf: return "pdf" } }
    var title: String {
        switch self {
        case .project: return L("Projektdatei (.ticktack) …")
        case .allProjects: return L("Alle Projekte sichern …")
        case .csv: return L("CSV-Tabelle …")
        case .excel: return L("Excel-Tabelle (.xlsx) …")
        case .pdf: return L("PDF-Zeitnachweis …")
        }
    }
}

extension UTType {
    static let ticktackProject = UTType(exportedAs: "app.ticktack.project", conformingTo: .json)
}

struct TransferFile: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw TransferError.invalid("Ungültige TickTack-Datei.") }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

@MainActor final class ImportSession: ObservableObject, Identifiable {
    let id = UUID()
    let fileName: String
    var document: ProjectDocument?
    var sourceText: String?
    @Published var tables: [ImportTable] = [] { didSet { refreshPreview() } }
    @Published var tableIndex = 0 { didSet { refreshPreview() } }
    @Published private(set) var preview: [ImportRow] = []
    @Published var separator = ";"
    @Published var destination = "new"
    @Published var projectName: String
    @Published var accent: ProjectAccent = .teal
    @Published var skipInvalid = false
    @Published var error = ""
    var table: ImportTable { tables.indices.contains(tableIndex) ? tables[tableIndex] : ImportTable(name: "", rows: []) }

    init(url: URL) throws {
        fileName = url.lastPathComponent; projectName = url.deletingPathExtension().lastPathComponent
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= SpreadsheetZIP.limit else { throw TransferError.invalid("Die Datei ist zu groß (maximal 30 MB).") }
        let data = try Data(contentsOf: url)
        guard data.count <= SpreadsheetZIP.limit else { throw TransferError.invalid("Die Datei ist zu groß (maximal 30 MB).") }
        switch url.pathExtension.lowercased() {
        case "ticktack", "json": document = try ProjectDocument.decode(data)
        case "xlsx": tables = try Spreadsheet.tables(data)
        case "csv", "tsv", "txt":
            let text = try DelimitedText.text(from: data)
            sourceText = text; separator = String(DelimitedText.detect(text))
            try parseText()
        default: throw TransferError.invalid("Bitte eine TickTack-, CSV-, TSV- oder XLSX-Datei auswählen.")
        }
        refreshPreview()
    }
    func refreshPreview() { preview = table.preview }
    func parseText() throws {
        guard let text = sourceText, let delimiter = separator.first else { return }
        var table = ImportTable(name: fileName, rows: try DelimitedText.parse(text, separator: delimiter))
        guard !table.rows.isEmpty else { throw TransferError.invalid("Die Tabelle ist leer.") }
        table.suggestMapping(); tables = [table]; tableIndex = 0
    }
    func reparse() {
        do { try parseText(); error = "" } catch { self.error = error.localizedDescription }
    }
}

extension Tracker {
    func beginImport() {
        showFileImporter = true
    }
    func loadImport(url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do { importSession = try ImportSession(url: url) }
        catch { transferAlert(error) }
    }

    func importDocument(_ document: ProjectDocument) throws {
        try document.validate()
        var newProjects: [TimeProject] = [], newEntries: [Entry] = []
        for original in document.projects {
            var copy = original; copy.id = UUID().uuidString
            if (projects + newProjects).contains(where: { $0.name == copy.name }) { copy.name += L(" (Import)") }
            newProjects.append(copy)
            newEntries += document.entries.filter { $0.projectID == original.id }.map {
                var entry = $0; entry.id = UUID(); entry.projectID = copy.id; return entry
            }
        }
        projects += newProjects; entries += newEntries; persistProjects(); save()
        if let first = newProjects.first { activeProjectID = first.id }
    }

    func commitImport(_ session: ImportSession) {
        do {
            if let document = session.document { try importDocument(document) }
            else {
                let table = session.table, rows = table.preview
                guard session.error.isEmpty, table.mapping[.task] != nil, table.mapping[.hours] != nil,
                      rows.contains(where: { $0.entry != nil }), session.skipInvalid || rows.allSatisfy({ $0.issue == nil }) else { return }
                let destination: String
                if session.destination == "new" {
                    let name = session.projectName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let project = TimeProject(id: UUID().uuidString, name: name, accentName: session.accent.rawValue)
                    projects.append(project); persistProjects(); destination = project.id
                } else {
                    guard projects.contains(where: { $0.id == session.destination }) else { return }
                    destination = session.destination
                }
                entries += rows.compactMap(\.entry).map { original in
                    var entry = original; entry.projectID = destination; return entry
                }
                save(); activeProjectID = destination
            }
            importSession = nil
        } catch { session.error = error.localizedDescription }
    }

    func exportData(_ kind: ExportKind) throws -> Data {
        if kind == .allProjects { return try ProjectDocument(projects: projects, entries: entries).encoded() }
        guard let project = projects.first(where: { $0.id == activeProjectID }) else { throw TransferError.invalid("Kein Projekt ausgewählt") }
        switch kind {
        case .project: return try ProjectDocument(projects: [project], entries: orderedEntries).encoded()
        case .csv: return Data(csvText().utf8)
        case .excel:
            guard orderedEntries.allSatisfy({ [$0.task, $0.category, $0.scope, $0.period, $0.position ?? ""].allSatisfy { $0.utf16.count <= 32767 } }) else {
                throw TransferError.invalid("Excel unterstützt höchstens 32.767 Zeichen je Zelle. Bitte eine TickTack-Datei verwenden.")
            }
            return Spreadsheet.export(project: project, entries: orderedEntries)
        case .pdf: return try TimeReport.pdf(project: project, entries: orderedEntries)
        case .allProjects: preconditionFailure("Handled above")
        }
    }

    func exportFile(_ kind: ExportKind) {
        let name = kind == .allProjects ? "TickTack-" + AppLanguage.dateString(Date()) : activeProjectName
        do {
            exportName = name.replacingOccurrences(of: "/", with: "-") + "." + kind.suffix
            exportContentType = kind.suffix == "ticktack" ? .ticktackProject : UTType(filenameExtension: kind.suffix) ?? .data
            exportDocument = TransferFile(data: try exportData(kind)); showFileExporter = true
        } catch { transferAlert(error) }
    }
    func transferAlert(_ error: Error) {
        let alert = NSAlert(); alert.messageText = L("Datei konnte nicht verarbeitet werden")
        alert.informativeText = error.localizedDescription; alert.runModal()
    }
}

struct ExportOptions: View {
    @ObservedObject var tracker: Tracker
    var body: some View {
        ForEach([ExportKind.project, .csv, .excel, .pdf], id: \.self) { kind in
            Button(kind.title) { tracker.exportFile(kind) }.disabled(!tracker.hasActiveProject)
        }
        Divider()
        Button(ExportKind.allProjects.title) { tracker.exportFile(.allProjects) }.disabled(tracker.projects.isEmpty)
    }
}

struct ImportPreview: View {
    @ObservedObject var tracker: Tracker
    @ObservedObject var session: ImportSession
    private var rows: [ImportRow] { session.preview }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("Import prüfen")).font(.title2.bold())
            Text(session.fileName).foregroundStyle(.secondary).lineLimit(1)
            if let document = session.document {
                Text(L("Die Projekte werden als neue Kopien hinzugefügt. Vorhandene Daten bleiben erhalten."))
                Table(document.projects) {
                    TableColumn(L("Projektname")) { project in Text(project.name) }
                    TableColumn(L("Einträge")) { project in Text(String(document.entries.filter { $0.projectID == project.id }.count)) }
                    TableColumn(L("Gesamtzeit des Projekts")) { project in Text(duration(document.entries.filter { $0.projectID == project.id }.reduce(0) { $0 + $1.seconds })) }
                }.alternatingRowBackgrounds(.enabled)
                Text(L("%d Projekte · %d Einträge", document.projects.count, document.entries.count)).font(.headline)
            } else {
                tableOptions
                let preview = rows
                let valid = preview.filter { $0.entry != nil }
                let invalid = preview.count - valid.count
                Table(Array(preview.prefix(500))) {
                    TableColumn(L("Zeile")) { row in Text(String(row.id)) }.width(45)
                    TableColumn(L("Tätigkeit")) { row in Text(row.values[.task] ?? "—").lineLimit(2) }
                    TableColumn(L("Bereich")) { row in Text(row.values[.category] ?? "").lineLimit(2) }
                    TableColumn(L("Notizen")) { row in Text(row.values[.scope] ?? "").lineLimit(2).help(row.values[.scope] ?? "") }
                    TableColumn(L("Zeitraum")) { row in Text(row.values[.period] ?? "").lineLimit(2) }
                    TableColumn(L("Stunden")) { row in Text(row.entry.map { AppLanguage.csvHours($0.seconds / 3600) } ?? row.values[.hours] ?? "—") }.width(85)
                    TableColumn(L("Prüfung")) { row in
                        Label(row.issue ?? L("Bereit"), systemImage: row.issue == nil ? "checkmark.circle" : "exclamationmark.triangle")
                            .foregroundStyle(row.issue == nil ? Color.secondary : Color.orange).font(.system(size: 13))
                    }.width(150)
                }.alternatingRowBackgrounds(.enabled)
                HStack {
                    Text(L("%d gültig · %d fehlerhaft", valid.count, invalid)).font(.headline)
                    Spacer()
                    Text(L("Gesamt: %@ h", AppLanguage.csvHours(valid.reduce(0) { $0 + ($1.entry?.seconds ?? 0) } / 3600))).font(.headline)
                }
                if preview.count > 500 { Text(L("Vorschau: erste 500 Zeilen. Importiert werden alle gültigen Zeilen.")).font(.subheadline) }
                if invalid > 0 { Toggle(L("Fehlerhafte Zeilen ausdrücklich überspringen"), isOn: $session.skipInvalid) }
                destination
            }
            if !session.error.isEmpty { Text(session.error).foregroundStyle(.red) }
            HStack {
                Text(L("Es wird nichts überschrieben.")).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Button(L("Abbrechen")) { tracker.importSession = nil }.keyboardShortcut(.cancelAction)
                Button(L("Importieren")) { tracker.commitImport(session) }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(!canImport)
            }
        }.padding(24).frame(minWidth: 920, idealWidth: 1000, minHeight: 660, idealHeight: 760)
    }
    private var canImport: Bool {
        if session.document != nil { return true }
        let table = session.table, rows = rows
        return session.error.isEmpty && table.mapping[.task] != nil && table.mapping[.hours] != nil && rows.contains { $0.entry != nil } &&
            (session.skipInvalid || rows.allSatisfy { $0.issue == nil }) &&
            (session.destination != "new" || !session.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    private var tableOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                if session.tables.count > 1 {
                    Picker(L("Tabelle"), selection: $session.tableIndex) {
                        ForEach(session.tables.indices, id: \.self) { Text(session.tables[$0].name).tag($0) }
                    }.frame(maxWidth: 250)
                }
                if session.sourceText != nil {
                    Picker(L("Trennzeichen"), selection: $session.separator) {
                        Text(L("Semikolon")).tag(";"); Text(L("Komma")).tag(","); Text(L("Tabulator")).tag("\t")
                    }.frame(maxWidth: 260).onChange(of: session.separator) { _, _ in session.reparse() }
                }
                if !session.tables.isEmpty {
                    Toggle(L("Erste Zeile enthält Überschriften"), isOn: $session.tables[session.tableIndex].hasHeader)
                        .onChange(of: session.table.hasHeader) { _, _ in session.tables[session.tableIndex].suggestMapping() }
                }
            }
            if !session.tables.isEmpty {
                HStack {
                    Text(L("Dezimalzeichen"))
                    Picker(L("Dezimalzeichen"), selection: $session.tables[session.tableIndex].decimalComma) {
                        Text(L("Komma (1,5)")).tag(true); Text(L("Punkt (1.5)")).tag(false)
                    }.labelsHidden().frame(width: 180)
                    Text(L("Stunden als Dezimalzahl, ohne Tausendertrennzeichen.")).font(.subheadline).foregroundStyle(.secondary)
                }
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                    ForEach(0..<2) { group in
                        GridRow {
                            ForEach(Array(ImportField.allCases[(group * 3)..<(group * 3 + 3)])) { field in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(field.title + ([ImportField.task, .hours].contains(field) ? " *" : "")).font(.subheadline)
                                    Picker(field.title, selection: Binding(get: { session.table.mapping[field] ?? -1 }, set: { session.tables[session.tableIndex].mapping[field] = $0 < 0 ? nil : $0 })) {
                                        Text(L("Nicht zuordnen")).tag(-1)
                                        ForEach(Array(session.table.headers.enumerated()), id: \.offset) { index, header in Text(header).tag(index) }
                                    }.labelsHidden().frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private var destination: some View {
        HStack(spacing: 12) {
            Picker(L("Ziel"), selection: $session.destination) {
                Text(L("Neues Projekt")).tag("new")
                ForEach(tracker.projects) { Text($0.name).tag($0.id) }
            }.frame(width: 280)
            if session.destination == "new" {
                TextField(L("Projektname"), text: $session.projectName).textFieldStyle(.roundedBorder)
                Picker(L("Akzentfarbe"), selection: $session.accent) {
                    ForEach(ProjectAccent.allCases) { Text($0.title).tag($0) }
                }.frame(width: 185)
            }
        }
    }
}
