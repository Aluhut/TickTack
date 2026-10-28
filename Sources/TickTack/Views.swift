import SwiftUI
import AppKit

func duration(_ seconds: Double) -> String {
    let s = Int(seconds)
    return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
}

struct TimerControl: View {
    let symbol: String
    let title: String
    let color: Color
    let enabled: Bool
    let action: () -> Void
    var size: CGFloat = 80
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(enabled ? Color.white : Color.primary.opacity(0.55))
                    .frame(width: size, height: size)
                    .background(enabled ? color : Color.primary.opacity(0.12), in: Circle())
                    .overlay(Circle().strokeBorder(color.opacity(enabled ? 0.5 : 0.18), lineWidth: 2))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
            .accessibilityLabel(title)
            .help(title)
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.primary.opacity(0.78))
        }.frame(width: size + 16)
    }
}

struct Controls: View {
    @ObservedObject var tracker: Tracker
    var compact = false
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TimerControl(symbol: "play.fill", title: tracker.paused ? L("Fortsetzen") : L("Start"), color: .green,
                         enabled: (tracker.running || tracker.hasActiveProject) && (!tracker.running || tracker.paused), action: tracker.start, size: compact ? 52 : 80)
            TimerControl(symbol: "pause.fill", title: L("Pause"), color: .orange,
                         enabled: tracker.running && !tracker.paused, action: tracker.pause, size: compact ? 52 : 80)
            TimerControl(symbol: "stop.fill", title: L("Stopp & sichern"), color: .red,
                         enabled: tracker.running, action: tracker.stop, size: compact ? 52 : 80)
        }
    }
}

struct DetailField: View {
    let title: String
    @Binding var text: String
    var multiline = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.primary.opacity(0.78))
            TextField(title, text: $text, axis: multiline ? .vertical : .horizontal)
                .lineLimit(multiline ? 3...12 : 1...1).textFieldStyle(.roundedBorder)
        }
    }
}

struct EntryInspector: View {
    @ObservedObject var tracker: Tracker
    var entry: Entry?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(entry == nil ? L("Neuer Eintrag") : L("Eintrag bearbeiten")).font(.title3.bold())
                    Spacer()
                    Button { tracker.showDraft = false; tracker.selection.removeAll() } label: { Image(systemName: "xmark") }.buttonStyle(.plain).help(L("Details schließen"))
                }
                Text(tracker.activeProjectName).font(.subheadline).foregroundStyle(Color.primary.opacity(0.78))
                Divider()
                if let entry {
                    DetailField(title: L("Position"), text: tracker.positionBinding(entry))
                    DetailField(title: L("Tätigkeit"), text: tracker.textBinding(entry, \.task), multiline: true)
                    DetailField(title: L("Bereich"), text: tracker.textBinding(entry, \.category))
                    DetailField(title: L("Konkreter Umfang / Notizen"), text: tracker.textBinding(entry, \.scope), multiline: true)
                    DetailField(title: L("Bearbeitungszeitraum"), text: tracker.textBinding(entry, \.period))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L("Aufwand in Stunden")).font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                        TextField(L("Stunden"), value: tracker.hoursBinding(entry), format: .number.precision(.fractionLength(0...4))).textFieldStyle(.roundedBorder)
                    }
                    Label(L("Änderungen werden automatisch gespeichert"), systemImage: "checkmark.circle").font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                } else {
                    DetailField(title: L("Tätigkeit"), text: $tracker.task, multiline: true)
                    DetailField(title: L("Bereich"), text: $tracker.category)
                    DetailField(title: L("Konkreter Umfang / Notizen"), text: $tracker.scope, multiline: true)
                    if tracker.running {
                        Label(tracker.paused ? L("Messung pausiert") : L("Messung läuft"), systemImage: "clock").foregroundStyle(.teal)
                        Text(L("Mit Stopp & sichern wird dieser Eintrag übernommen. Du kannst den Text jederzeit ergänzen.")).font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                    } else {
                        DetailField(title: L("Bearbeitungszeitraum"), text: $tracker.draftPeriod)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("Stunden für manuellen Eintrag")).font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                            TextField(L("Stunden"), value: $tracker.manualHours, format: .number.precision(.fractionLength(0...4))).textFieldStyle(.roundedBorder)
                        }
                        Button(L("Eintrag hinzufügen"), action: tracker.addManualEntry).buttonStyle(.borderedProminent)
                            .disabled(tracker.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !tracker.manualHours.isFinite || tracker.manualHours < 0 || tracker.manualHours > 1000000)
                        Text(L("Oder starte oben die Stoppuhr für diese Tätigkeit.")).font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                    }
                }
            }.padding(22)
        }.frame(width: 340).background(.background)
    }
}

struct MainView: View {
    @ObservedObject var tracker: Tracker
    private var visibleEntries: [Entry] {
        let query = tracker.search.trimmingCharacters(in: .whitespacesAndNewlines)
        return tracker.orderedEntries.filter { query.isEmpty || [$0.task, $0.category, $0.scope, $0.period].contains { $0.localizedCaseInsensitiveContains(query) } }
    }
    private var selectedEntry: Entry? { tracker.projectEntries.first { tracker.selection.contains($0.id) } }
    var body: some View {
        NavigationSplitView {
            List {
                Section(L("PROJEKTE")) {
                    if tracker.projects.isEmpty {
                        Button(L("Erstes Projekt anlegen"), action: tracker.beginNewProject)
                    }
                    ForEach(tracker.projects) { project in
                        Button {
                            tracker.activeProjectID = project.id
                        } label: {
                            HStack {
                                Label(project.name, systemImage: "folder.fill").lineLimit(2)
                                Spacer()
                                Circle().fill(project.accent).frame(width: 8, height: 8)
                                if project.id == tracker.activeProjectID { Image(systemName: "checkmark").font(.system(size: 14)) }
                            }.foregroundStyle(project.id == tracker.activeProjectID ? project.accent : Color.primary)
                        }.buttonStyle(.plain).padding(.vertical, 5)
                    }
                }
            }.listStyle(.sidebar).navigationSplitViewColumnWidth(190)
        } detail: {
            VStack(spacing: 0) {
                HStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(tracker.paused ? L("Pausiert · ") + tracker.timerProjectName : tracker.running ? L("Messung läuft · ") + tracker.timerProjectName : L("Bereit zum Start"), systemImage: "clock").font(.system(size: 14, weight: .medium)).foregroundStyle(.teal)
                        Button {
                            if tracker.running { tracker.activeProjectID = tracker.timerProjectIDForUI }
                            tracker.selection.removeAll(); tracker.showDraft = true
                        } label: {
                            HStack {
                                Text(tracker.task.isEmpty ? L("Tätigkeit beschreiben") : tracker.task).lineLimit(1)
                                Image(systemName: "pencil").font(.system(size: 14))
                            }
                        }.buttonStyle(.plain).help(L("Aktuelle Tätigkeit bearbeiten"))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Text(duration(tracker.elapsed)).font(.system(size: 30, weight: .light, design: .rounded)).monospacedDigit()
                    Controls(tracker: tracker, compact: true)
                }.padding(20).background(.regularMaterial)
                Divider()
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tracker.activeProjectName).font(.title2.bold())
                                Text(L("%d gespeicherte Einträge", tracker.projectEntries.count)).font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                            }
                            Spacer()
                            Button(action: tracker.newEntry) { Label(L("Neuer Eintrag"), systemImage: "plus") }.buttonStyle(.borderedProminent).disabled(!tracker.hasActiveProject)
                        }
                        HStack(spacing: 18) {
                            Image(systemName: "clock.fill").font(.system(size: 28)).foregroundStyle(tracker.activeAccent)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(L("Gesamtzeit dieses Projekts")).font(.system(size: 16, weight: .semibold))
                                Text(tracker.activeProjectHasMeasurement ? (tracker.paused ? L("Inklusive pausierter Messung") : L("Inklusive laufender Messung")) : L("Alle gespeicherten Einträge"))
                                    .font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                            }
                            Spacer(minLength: 12)
                            Text(duration(tracker.activeProjectTotal))
                                .font(.system(size: 38, weight: .semibold, design: .rounded)).monospacedDigit()
                                .accessibilityLabel(L("Gesamtzeit dieses Projekts"))
                                .accessibilityValue(duration(tracker.activeProjectTotal))
                        }.padding(20)
                            .background(tracker.activeAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(tracker.activeAccent.opacity(0.4), lineWidth: 1))
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundStyle(Color.primary.opacity(0.78))
                            TextField(L("Einträge durchsuchen"), text: $tracker.search).textFieldStyle(.plain)
                            if !tracker.search.isEmpty { Button { tracker.search = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain) }
                        }.padding(9).background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        HStack {
                            Text(L("%d Einträge", visibleEntries.count)).font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                            Spacer()
                            Picker(L("Sortierung"), selection: $tracker.sortOrder) {
                                ForEach(EntrySort.allCases) { order in Text(order.title).tag(order) }
                            }.pickerStyle(.menu).fixedSize()
                            .help(L("Bei Zeiträumen zählt das Enddatum. Einträge ohne Datum stehen am Ende."))
                        }
                        Table(visibleEntries, selection: $tracker.selection) {
                            TableColumn(L("Tätigkeit")) { (entry: Entry) in
                                TextField(L("Tätigkeit"), text: tracker.textBinding(entry, \.task)).textFieldStyle(.plain).padding(.vertical, 8)
                            }.width(min: 180, ideal: 300)
                            TableColumn(L("Bereich")) { (entry: Entry) in
                                TextField(L("Bereich"), text: tracker.textBinding(entry, \.category)).textFieldStyle(.plain).padding(.vertical, 8)
                            }.width(min: 110, ideal: 160)
                            TableColumn(L("Zeitraum")) { (entry: Entry) in
                                TextField(L("Zeitraum"), text: tracker.textBinding(entry, \.period)).textFieldStyle(.plain).padding(.vertical, 8)
                            }.width(130)
                            TableColumn(L("Stunden")) { (entry: Entry) in
                                TextField(L("Stunden"), value: tracker.hoursBinding(entry), format: .number.precision(.fractionLength(0...4))).textFieldStyle(.plain).monospacedDigit().padding(.vertical, 8)
                            }.width(75)
                        }.overlay {
                            if visibleEntries.isEmpty {
                                ContentUnavailableView(tracker.search.isEmpty ? L("Noch keine Einträge") : L("Keine Treffer"), systemImage: "clock", description: Text(tracker.search.isEmpty ? L("Lege einen Eintrag an oder starte die Stoppuhr.") : L("Versuche einen anderen Suchbegriff.")))
                            }
                        }
                        HStack {
                            Text(L("Zeile auswählen für alle Details")).font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.78))
                            Spacer()
                            Button(L("Details")) { tracker.showDraft = false }.disabled(tracker.selection.isEmpty)
                            Button(role: .destructive) { tracker.confirmEntryDeletion = true } label: { Image(systemName: "trash") }.disabled(tracker.selection.isEmpty).help(L("Ausgewählte Einträge löschen"))
                        }
                    }.padding(22).frame(maxWidth: .infinity, maxHeight: .infinity)
                    if tracker.showDraft || selectedEntry != nil {
                        Divider()
                        EntryInspector(tracker: tracker, entry: tracker.showDraft ? nil : selectedEntry)
                    }
                }
            }.frame(minWidth: 760, minHeight: 580)
            .navigationTitle("TickTack")
            .toolbar {
                Button(action: tracker.export) { Label(L("CSV exportieren"), systemImage: "square.and.arrow.up") }.disabled(tracker.projectEntries.isEmpty)
            }
            .onChange(of: tracker.selection) { _, selection in
                if !selection.isEmpty { tracker.showDraft = false }
            }
        }
    }
}

struct MenuView: View {
    @ObservedObject var tracker: Tracker
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TickTack").font(.headline)
            Text(L("Projekt: ") + (tracker.running ? tracker.timerProjectName : tracker.activeProjectName)).font(.subheadline).foregroundStyle(Color.primary.opacity(0.78))
            Text(duration(tracker.elapsed)).font(.system(size: 30, design: .rounded)).monospacedDigit()
            Text(tracker.paused ? L("Pausiert") : tracker.running ? tracker.task : L("Bereit zum Start")).foregroundStyle(Color.primary.opacity(0.78)).lineLimit(2)
            Controls(tracker: tracker)
            Divider()
            VStack(alignment: .leading, spacing: 5) {
                Text(L("Gesamtzeit des Projekts")).font(.system(size: 14, weight: .medium))
                Text(duration(tracker.currentTotal(for: tracker.running ? tracker.timerProjectIDForUI : tracker.activeProjectID)))
                    .font(.system(size: 26, weight: .semibold, design: .rounded)).monospacedDigit()
            }
            Divider()
            Button(L("Zeitnachweise öffnen")) { openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true) }
            Button(L("Beenden")) { if tracker.running { tracker.stop() }; NSApplication.shared.terminate(nil) }
        }.padding(18).frame(width: 360)
    }
}

