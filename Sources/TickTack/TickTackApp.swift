import SwiftUI
import AppKit

@main struct TickTackApp: App {
    @StateObject private var tracker = Tracker()
    var body: some Scene {
        WindowGroup("TickTack", id: "main") {
            MainView(tracker: tracker)
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
                .sheet(isPresented: $tracker.showNewProject) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(L("Neues Projekt")).font(.title2.bold())
                        TextField(L("Projektname"), text: $tracker.newProjectName).textFieldStyle(.roundedBorder).onSubmit { tracker.createProject() }
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L("Akzentfarbe")).font(.subheadline)
                            HStack(spacing: 12) {
                                ForEach(ProjectAccent.allCases) { accent in
                                    Button { tracker.newProjectAccent = accent } label: {
                                        Circle().fill(accent.color).frame(width: 36, height: 36)
                                            .overlay { if tracker.newProjectAccent == accent { Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)).foregroundStyle(.white) } }
                                            .padding(3).overlay(Circle().stroke(tracker.newProjectAccent == accent ? accent.color : .clear, lineWidth: 2))
                                    }.buttonStyle(.plain).help(accent.title).accessibilityLabel(accent.title).accessibilityAddTraits(tracker.newProjectAccent == accent ? .isSelected : [])
                                }
                            }
                        }
                        HStack {
                            Spacer()
                            Button(L("Abbrechen")) { tracker.showNewProject = false }.keyboardShortcut(.cancelAction)
                            Button(L("Projekt erstellen"), action: tracker.createProject).buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                                .disabled(tracker.newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }.padding(26).frame(width: 380)
                }
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
