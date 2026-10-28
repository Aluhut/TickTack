import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main struct TickTackApp: App {
    @StateObject private var tracker = Tracker()
    @Environment(\.openWindow) private var openWindow
    var body: some Scene {
        Window("TickTack", id: "main") {
            MainView(tracker: tracker)
                .onOpenURL { tracker.loadImport(url: $0) }
                .fileExporter(isPresented: $tracker.showFileExporter, document: tracker.exportDocument,
                              contentType: tracker.exportContentType, defaultFilename: tracker.exportName) { result in
                    if case .failure(let error) = result { tracker.transferAlert(error) }
                }
                .fileImporter(isPresented: $tracker.showFileImporter,
                              allowedContentTypes: [.ticktackProject] + ["json", "csv", "tsv", "txt", "xlsx"].compactMap { UTType(filenameExtension: $0) }) { result in
                    switch result {
                    case .success(let url): DispatchQueue.main.async { tracker.loadImport(url: url) }
                    case .failure(let error): tracker.transferAlert(error)
                    }
                }
                .environment(\.locale, AppLanguage.locale)
                .font(.system(size: tracker.interfaceFontSize))
                .controlSize(.large)
                .environment(\.defaultMinListRowHeight, 38)
                .tint(tracker.activeAccent)
                .alert(L("Projekt löschen?"), isPresented: $tracker.confirmProjectDeletion) {
                    Button(L("Abbrechen"), role: .cancel) { }
                    Button(L("Projekt löschen"), role: .destructive) { tracker.deleteActiveProject() }
                } message: {
                    Text(L("„%@“ und alle %d Einträge werden entfernt. Unter Datei/Ablage kannst du sie wiederherstellen.", tracker.activeProjectName, tracker.projectEntries.count))
                }
                .alert(L("Einträge löschen?"), isPresented: $tracker.confirmEntryDeletion) {
                    Button(L("Abbrechen"), role: .cancel) { }
                    Button(L("Löschen"), role: .destructive) { tracker.delete(tracker.selection) }
                } message: {
                    Text(L("%d ausgewählte Einträge werden entfernt. Unter Datei/Ablage kannst du sie wiederherstellen.", tracker.selection.count))
                }
                .sheet(item: $tracker.importSession) { session in
                    ImportPreview(tracker: tracker, session: session)
                }
                .sheet(isPresented: $tracker.showNewProject) { NewProjectSheet(tracker: tracker) }
        }.defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(after: .toolbar) {
                Button(L("Schrift vergrößern")) { tracker.interfaceFontSize = min(24, tracker.interfaceFontSize + 1) }.keyboardShortcut("+", modifiers: [.command])
                    .disabled(tracker.interfaceFontSize >= 24)
                Button(L("Schrift verkleinern")) { tracker.interfaceFontSize = max(16, tracker.interfaceFontSize - 1) }.keyboardShortcut("-", modifiers: [.command])
                    .disabled(tracker.interfaceFontSize <= 16)
            }
            CommandGroup(replacing: .newItem) {
                Button(L("Neues Projekt …"), action: tracker.beginNewProject).keyboardShortcut("n", modifiers: [.command])
                Button(L("Projekt löschen …")) { tracker.confirmProjectDeletion = true }.disabled(!tracker.canDeleteProject)
                Button(L("Ausgewählte Einträge löschen …")) { tracker.confirmEntryDeletion = true }.disabled(tracker.selection.isEmpty)
                Button(L("Zuletzt Gelöschtes wiederherstellen"), action: tracker.restoreLastDeletion).disabled(tracker.deletedItems.isEmpty)
                Divider()
                Button(L("Importieren …")) { openWindow(id: "main"); tracker.beginImport() }.keyboardShortcut("i", modifiers: [.command, .shift])
                Menu(L("Exportieren")) { ExportOptions(tracker: tracker) }
                Divider()
                Menu(L("Projektfarbe")) {
                    ForEach(ProjectAccent.allCases) { accent in
                        Button { tracker.setProjectAccent(accent) } label: {
                            Label(accent.title, systemImage: tracker.projects.first(where: { $0.id == tracker.activeProjectID })?.accentName == accent.rawValue ? "checkmark.circle.fill" : "circle.fill")
                        }
                    }
                }
            }
        }
        MenuBarExtra {
            MenuView(tracker: tracker).environment(\.locale, AppLanguage.locale).font(.system(size: tracker.interfaceFontSize)).controlSize(.large)
        } label: {
            Label(tracker.running ? duration(tracker.elapsed) : L("Zeit"), systemImage: tracker.paused ? "pause.circle" : tracker.running ? "record.circle" : "clock")
        }.menuBarExtraStyle(.window)
    }
}
