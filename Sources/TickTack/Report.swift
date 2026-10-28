import AppKit
import CoreGraphics

enum TimeReport {
    private struct Row {
        var lines: [[String]]
        var alternate: Bool
        var height: CGFloat { CGFloat(lines.map(\.count).max() ?? 1) * 16 + 16 }
    }
    static func pdf(project: TimeProject, entries: [Entry]) throws -> Data {
        let widths: [CGFloat] = [48, 88, 150, 244, 160, 88]
        let font = NSFont.systemFont(ofSize: 11.5)
        func wrapped(_ value: String, width: CGFloat) -> [String] {
            guard !value.isEmpty else { return [""] }
            let storage = NSTextStorage(string: value, attributes: [.font: font])
            let layout = NSLayoutManager(), container = NSTextContainer(size: NSSize(width: width - 12, height: .greatestFiniteMagnitude))
            container.lineFragmentPadding = 0
            layout.addTextContainer(container); storage.addLayoutManager(layout); layout.ensureLayout(for: container)
            var lines: [String] = []
            layout.enumerateLineFragments(forGlyphRange: layout.glyphRange(for: container)) { _, _, _, range, _ in
                let range = layout.characterRange(forGlyphRange: range, actualGlyphRange: nil)
                lines.append((value as NSString).substring(with: range).trimmingCharacters(in: .newlines))
            }
            return lines.isEmpty ? [""] : lines
        }
        var pages: [[Row]] = [[]], used: CGFloat = 0
        for (index, entry) in entries.enumerated() {
            let values = [entry.position ?? String(index + 1), entry.category, entry.task, entry.scope, entry.period, AppLanguage.csvHours(entry.seconds / 3600)]
            let lines = zip(values, widths).map { wrapped($0.0, width: $0.1) }
            let lineCount = lines.map(\.count).max() ?? 1
            var offset = 0
            while offset < lineCount {
                let capacity = Int((390 - used - 16) / 16)
                if capacity < 1 { pages.append([]); used = 0; continue }
                let count = min(capacity, lineCount - offset)
                let row = Row(lines: lines.map { Array($0.dropFirst(offset).prefix(count)) }, alternate: index % 2 == 1)
                pages[pages.count - 1].append(row); used += row.height; offset += count
                if offset < lineCount { pages.append([]); used = 0 }
            }
        }
        let data = NSMutableData()
        var media = CGRect(x: 0, y: 0, width: 842, height: 595)
        guard let consumer = CGDataConsumer(data: data), let context = CGContext(consumer: consumer, mediaBox: &media, [kCGPDFContextTitle: project.name + " · TickTack", kCGPDFContextCreator: "TickTack"] as CFDictionary) else {
            throw TransferError.invalid("PDF konnte nicht erstellt werden.")
        }
        let ink = NSColor(srgbRed: 0.08, green: 0.19, blue: 0.23, alpha: 1)
        func text(_ value: String, _ rect: CGRect, size: CGFloat = 11.5, bold: Bool = false, color: NSColor = .black) {
            (value as NSString).draw(in: rect, withAttributes: [.font: bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size), .foregroundColor: color])
        }
        let headers = [L("Position"), L("Bereich"), L("Tätigkeit"), L("Konkreter Umfang / Notizen"), L("Zeitraum"), L("Stunden")]
        for (pageIndex, page) in pages.enumerated() {
            context.beginPDFPage(nil)
            context.saveGState(); context.translateBy(x: 0, y: 595); context.scaleBy(x: 1, y: -1)
            NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
            NSColor.white.setFill(); media.fill()
            text("TickTack · " + L("Zeitnachweis"), CGRect(x: 32, y: 24, width: 500, height: 28), size: 20, bold: true, color: ink)
            text(project.name, CGRect(x: 32, y: 60, width: 525, height: 48), size: 17, bold: true, color: ink)
            text(L("Gesamtzeit dieses Projekts"), CGRect(x: 585, y: 24, width: 225, height: 20), size: 12, color: ink)
            text(duration(entries.reduce(0) { $0 + $1.seconds }), CGRect(x: 585, y: 48, width: 225, height: 36), size: 26, bold: true, color: ink)
            text(L("%d gespeicherte Einträge", entries.count), CGRect(x: 585, y: 88, width: 225, height: 20), size: 11, color: ink)
            ink.setFill(); CGRect(x: 32, y: 120, width: 778, height: 30).fill()
            var x: CGFloat = 32
            for (column, header) in headers.enumerated() {
                text(column == 0 ? "#" : header, CGRect(x: x + 6, y: 128, width: widths[column] - 12, height: 18), size: 10.5, bold: true, color: .white)
                x += widths[column]
            }
            var y: CGFloat = 150
            for row in page {
                if row.alternate { NSColor(srgbRed: 0.92, green: 0.96, blue: 0.97, alpha: 1).setFill(); CGRect(x: 32, y: y, width: 778, height: row.height).fill() }
                x = 32
                for (column, lines) in row.lines.enumerated() {
                    for (line, value) in lines.enumerated() { text(value, CGRect(x: x + 6, y: y + 8 + CGFloat(line) * 16, width: widths[column] - 12, height: 16)) }
                    x += widths[column]
                }
                y += row.height
            }
            text(L("Nur gespeicherte Einträge; ohne laufende Messung."), CGRect(x: 32, y: 561, width: 650, height: 20), size: 10, color: .darkGray)
            text(L("Seite %d / %d", pageIndex + 1, pages.count), CGRect(x: 716, y: 561, width: 94, height: 20), size: 10, color: .darkGray)
            NSGraphicsContext.restoreGraphicsState(); context.restoreGState(); context.endPDFPage()
        }
        context.closePDF()
        return data as Data
    }
}
